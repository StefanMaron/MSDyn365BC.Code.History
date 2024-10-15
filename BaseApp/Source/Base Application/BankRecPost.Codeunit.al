codeunit 10120 "Bank Rec.-Post"
{
    Permissions = TableData "Bank Account" = rm,
                  TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rm,
                  TableData "Bank Rec. Header" = rmd,
                  TableData "Bank Rec. Line" = rmd,
                  TableData "Bank Comment Line" = rimd,
                  TableData "Posted Bank Rec. Header" = rimd,
                  TableData "Posted Bank Rec. Line" = rimd;
    TableNo = "Bank Rec. Header";

    trigger OnRun()
    begin
        ClearAll;

        BankRecHeader := Rec;
        with BankRecHeader do begin
            TestField("Statement Date");
            TestField("Statement No.");
            TestField("Bank Account No.");

            CalculateBankRecHeaderBalance(BankRecHeader);
            CheckBankRecDifference(BankRecHeader);

            CalcFields("Total Adjustments", "Total Balanced Adjustments");
            if ("Total Adjustments" - "Total Balanced Adjustments") <> 0 then
                Error(Text008);

            OpenProcessingDialog();

            Window.Update(1, "Bank Account No.");
            Window.Update(2, "Statement No.");

            GLSetup.Get();

            BankRecLine.LockTable();
            PostedBankRecLine.LockTable();

            SourceCodeSetup.Get();

            SetRange("Date Filter", "Statement Date");
            CalcFields("G/L Balance (LCY)");
            CalculateBankRecHeaderBalance(BankRecHeader);

            PostedBankRecHeader.Init();
            PostedBankRecHeader.TransferFields(BankRecHeader, true);
            PostedBankRecHeader."G/L Balance (LCY)" := "G/L Balance (LCY)";
            PostedBankRecHeader.Insert();
            OnRunOnAftertPostedBankRecHeaderInsert(PostedBankRecHeader, BankRecHeader);

            BankRecCommentLine.SetCurrentKey("Table Name",
              "Bank Account No.",
              "No.");
            BankRecCommentLine.SetRange("Table Name", BankRecCommentLine."Table Name"::"Bank Rec.");
            BankRecCommentLine.SetRange("Bank Account No.", "Bank Account No.");
            BankRecCommentLine.SetRange("No.", "Statement No.");
            if BankRecCommentLine.Find('-') then
                repeat
                    Window.Update(3, BankRecCommentLine."Line No.");

                    PostedBankRecCommentLine.Init();
                    PostedBankRecCommentLine.TransferFields(BankRecCommentLine, true);
                    PostedBankRecCommentLine."Table Name" := PostedBankRecCommentLine."Table Name"::"Posted Bank Rec.";
                    PostedBankRecCommentLine.Insert();
                until BankRecCommentLine.Next() = 0;
            BankRecCommentLine.DeleteAll();

            BankRecLine.Reset();
            BankRecLine.SetCurrentKey("Bank Account No.",
              "Statement No.");
            BankRecLine.SetRange("Bank Account No.", "Bank Account No.");
            BankRecLine.SetRange("Statement No.", "Statement No.");
            if BankRecLine.Find('-') then
                repeat
                    Window.Update(BankRecLine."Record Type" + 4, BankRecLine."Line No.");
                    if BankRecLine."Record Type" = BankRecLine."Record Type"::Adjustment then
                        if (GLSetup."Bank Rec. Adj. Doc. Nos." <> '') and
                           (BankRecLine."Document No." <> NoSeriesMgt.GetNextNo(GLSetup."Bank Rec. Adj. Doc. Nos.",
                              "Posting Date", false))
                        then
                            NoSeriesMgt.TestManual(GLSetup."Bank Rec. Adj. Doc. Nos.");

                    if BankRecLine."Record Type" = BankRecLine."Record Type"::Adjustment then
                        PostAdjustmentToGL(BankRecLine)
                    else
                        if BankRecLine.Cleared then
                            UpdateLedgers(BankRecLine, SetStatus::Posted)
                        else
                            UpdateLedgers(BankRecLine, SetStatus::Open);

                    PostedBankRecLine.Init();
                    PostedBankRecLine.TransferFields(BankRecLine, true);
                    PostedBankRecLine.Insert();
                until BankRecLine.Next() = 0;

            OnRunOnBeforeBankRecLineDeleteAll(BankRecLine);
            BankRecLine.DeleteAll();
            BankRecSubLine.Reset();
            BankRecSubLine.SetRange("Bank Account No.", "Bank Account No.");
            BankRecSubLine.SetRange("Statement No.", "Statement No.");
            BankRecSubLine.DeleteAll();

            BankAccount.Get("Bank Account No.");
            BankAccount."Last Statement No." := "Statement No.";
            BankAccount."Balance Last Statement" := "Statement Balance";
            OnRunOnBeforeBankAccountModify(BankAccount, BankRecHeader, PostedBankRecHeader);
            BankAccount.Modify();

            Delete;

            Commit();
            Window.Close;
        end;
        if GLSetup."Bank Rec. Adj. Doc. Nos." <> '' then
            NoSeriesMgt.SaveNoSeries;
        Rec := BankRecHeader;
        UpdateAnalysisView.UpdateAll(0, true);
    end;

    var
        SetStatus: Option Open,Cleared,Posted;
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        BankRecCommentLine: Record "Bank Comment Line";
        BankRecSubLine: Record "Bank Rec. Sub-line";
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
        PostedBankRecLine: Record "Posted Bank Rec. Line";
        PostedBankRecCommentLine: Record "Bank Comment Line";
        GLSetup: Record "General Ledger Setup";
        SourceCodeSetup: Record "Source Code Setup";
        BankAccount: Record "Bank Account";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        Window: Dialog;
        Text001: Label 'Posting Bank Account  #1#################### \\';
        Text002: Label 'Statement             #2#################### \';
        Text003: Label 'Comment               #3########## \';
        Text004: Label 'Check                 #4########## \';
        Text005: Label 'Deposit               #5########## \';
        Text006: Label 'Adjustment            #6########## \';
        Text007: Label 'Difference must be zero before the statement can be posted.';
        Text008: Label 'Balance of adjustments must be zero before posting.';
        NoSeriesMgt: Codeunit NoSeriesManagement;

    local procedure CalculateBankRecHeaderBalance(var BankRecHeader: Record "Bank Rec. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateBankRecHeaderBalance(BankRecHeader, IsHandled);
        if IsHandled then
            exit;

        BankRecHeader.CalculateBalance();
    end;

    local procedure CheckBankRecDifference(var BankRecHeader: Record "Bank Rec. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBankRecDifference(BankRecHeader, IsHandled);
        if IsHandled then
            exit;

        with BankRecHeader do
            if Round(("G/L Balance" +
                ("Positive Adjustments" - "Negative Bal. Adjustments") +
                ("Negative Adjustments" - "Positive Bal. Adjustments")) -
               (("Statement Balance" + "Outstanding Deposits") - "Outstanding Checks"), 0.01) <> 0
            then
                Error(Text007);
    end;

    local procedure OpenProcessingDialog()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenProcessingDialog(Window, IsHandled);
        if IsHandled then
            exit;

        Window.Open(Text001 +
          Text002 +
          Text003 +
          Text004 +
          Text005 +
          Text006);
    end;

    procedure UpdateLedgers(BankRecLine3: Record "Bank Rec. Line"; UseStatus: Option Open,Cleared,Posted)
    var
        BankLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankRecSubLine: Record "Bank Rec. Sub-line";
        CheckLedgerEntry2: Record "Check Ledger Entry";
    begin
        if (BankRecLine3."Bank Ledger Entry No." <> 0) and (BankRecLine3."Check Ledger Entry No." = 0) then
            UpdateBankLedger(
              BankRecLine3."Bank Ledger Entry No.", UseStatus,
              BankRecLine3."Statement No.", BankRecLine3."Line No.");
        if BankRecLine3."Check Ledger Entry No." <> 0 then
            if CheckLedgerEntry.Get(BankRecLine3."Check Ledger Entry No.") then begin
                if UseStatus = UseStatus::Posted then
                    CheckLedgerEntry.Open := false;
                case UseStatus of
                    UseStatus::Open:
                        CheckLedgerEntry."Statement Status" := CheckLedgerEntry."Statement Status"::Open;
                    UseStatus::Cleared:
                        CheckLedgerEntry."Statement Status" := CheckLedgerEntry."Statement Status"::"Check Entry Applied";
                    UseStatus::Posted:
                        CheckLedgerEntry."Statement Status" := CheckLedgerEntry."Statement Status"::Closed;
                end;
                if CheckLedgerEntry."Statement Status" = CheckLedgerEntry."Statement Status"::Open then begin
                    CheckLedgerEntry."Statement No." := '';
                    CheckLedgerEntry."Statement Line No." := 0;
                end else begin
                    CheckLedgerEntry."Statement No." := BankRecLine3."Statement No.";
                    CheckLedgerEntry."Statement Line No." := BankRecLine3."Line No.";
                end;
                CheckLedgerEntry.Modify();
                if (CheckLedgerEntry."Check Type" = CheckLedgerEntry."Check Type"::"Total Check") or
                   (UseStatus <> UseStatus::Posted)
                then
                    UpdateBankLedger(
                      BankRecLine3."Bank Ledger Entry No.", UseStatus,
                      BankRecLine3."Statement No.", BankRecLine3."Line No.")
                else begin
                    CheckLedgerEntry2.Reset();
                    CheckLedgerEntry2.SetCurrentKey("Bank Account Ledger Entry No.");
                    CheckLedgerEntry2.SetRange("Bank Account Ledger Entry No.", CheckLedgerEntry."Bank Account Ledger Entry No.");
                    CheckLedgerEntry2.SetFilter("Statement Status", '<>%1', CheckLedgerEntry."Statement Status"::Closed);
                    if CheckLedgerEntry2.Find('-') then begin
                        if BankLedgerEntry.Get(CheckLedgerEntry2."Bank Account Ledger Entry No.") then begin
                            BankLedgerEntry."Remaining Amount" := 0;
                            repeat
                                BankLedgerEntry."Remaining Amount" :=
                                  BankLedgerEntry."Remaining Amount" - CheckLedgerEntry2.Amount;
                            until CheckLedgerEntry2.Next() = 0;
                            BankLedgerEntry.Modify();
                        end;
                    end else
                        UpdateBankLedger(
                          BankRecLine3."Bank Ledger Entry No.", UseStatus,
                          BankRecLine3."Statement No.", BankRecLine3."Line No.");
                end;
            end;
        if BankRecLine3."Collapse Status" = BankRecLine3."Collapse Status"::"Collapsed Deposit" then begin
            BankRecSubLine.SetRange("Bank Account No.", BankRecLine3."Bank Account No.");
            BankRecSubLine.SetRange("Statement No.", BankRecLine3."Statement No.");
            BankRecSubLine.SetRange("Bank Rec. Line No.", BankRecLine3."Line No.");
            if BankRecSubLine.Find('-') then
                repeat
                    UpdateBankLedger(
                      BankRecSubLine."Bank Ledger Entry No.", UseStatus,
                      BankRecLine3."Statement No.", BankRecLine3."Line No.");
                until BankRecSubLine.Next() = 0;
        end;
    end;

    local procedure UpdateBankLedger(BankLedgerEntryNo: Integer; UseStatus: Option Open,Cleared,Posted; StatementNo: Code[20]; StatementLineNo: Integer)
    var
        BankLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if BankLedgerEntry.Get(BankLedgerEntryNo) then begin
            if UseStatus = UseStatus::Posted then begin
                BankLedgerEntry.Open := false;
                BankLedgerEntry."Remaining Amount" := 0;
            end;
            case UseStatus of
                UseStatus::Open:
                    BankLedgerEntry."Statement Status" := BankLedgerEntry."Statement Status"::Open;
                UseStatus::Cleared:
                    BankLedgerEntry."Statement Status" := BankLedgerEntry."Statement Status"::"Bank Acc. Entry Applied";
                UseStatus::Posted:
                    BankLedgerEntry."Statement Status" := BankLedgerEntry."Statement Status"::Closed;
            end;
            if BankLedgerEntry."Statement Status" = BankLedgerEntry."Statement Status"::Open then begin
                BankLedgerEntry."Statement No." := '';
                BankLedgerEntry."Statement Line No." := 0;
            end else begin
                BankLedgerEntry."Statement No." := StatementNo;
                BankLedgerEntry."Statement Line No." := StatementLineNo;
            end;
            OnBeforeBankLedgerEntryModify(BankLedgerEntry, UseStatus, StatementNo, StatementLineNo);
            BankLedgerEntry.Modify();
        end;
    end;

    local procedure PostAdjustmentToGL(BankRecLine2: Record "Bank Rec. Line")
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostAdjustmentToGL(BankRecLine2, BankRecHeader, BankRecLine, IsHandled);
        if IsHandled then
            exit;

        with BankRecLine2 do
            if Amount <> 0 then begin
                GenJnlLine.Init();
                GenJnlLine."Posting Date" := "Posting Date";
                GenJnlLine."Document Date" := "Posting Date";
                GenJnlLine.Description := Description;
                GenJnlLine."Account Type" := "Account Type";
                GenJnlLine."Account No." := "Account No.";
                GenJnlLine."Bal. Account Type" := "Bal. Account Type";
                GenJnlLine."Bal. Account No." := "Bal. Account No.";
                GenJnlLine."Document Type" := "Document Type";
                GenJnlLine."Document No." := "Document No.";
                GenJnlLine."External Document No." := "External Document No.";
                GenJnlLine."Currency Code" := "Currency Code";
                GenJnlLine."Currency Factor" := "Currency Factor";
                GenJnlLine."Source Currency Code" := "Currency Code";
                GenJnlLine."Source Currency Amount" := Amount;
                if "Currency Code" = '' then
                    GenJnlLine."Currency Factor" := 1
                else
                    GenJnlLine."Currency Factor" := "Currency Factor";
                GenJnlLine.Validate(Amount, Amount);
                GenJnlLine."Source Type" := "Account Type";
                GenJnlLine."Source No." := "Account No.";
                GenJnlLine."Source Code" := SourceCodeSetup."Bank Rec. Adjustment";
                GenJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := "Dimension Set ID";

                OnPostAdjustmentToGLOnBeforeGenJnlPostLineRunWithCheck(GenJnlLine, BankRecLine2);
                GenJnlPostLine.RunWithCheck(GenJnlLine);

                GLEntry.FindLast;
                if GLEntry."Bal. Account Type" = GLEntry."Bal. Account Type"::"Bank Account" then
                    "Bank Ledger Entry No." := GLEntry."Entry No." - 1
                else
                    "Bank Ledger Entry No." := GLEntry."Entry No.";
                "Check Ledger Entry No." := 0;
                Modify;
                UpdateLedgers(BankRecLine2, SetStatus::Posted);
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBankLedgerEntryModify(var BankAccLedgerEntry: Record "Bank Account Ledger Entry"; UseStatus: Option Open,Cleared,Posted; StatementNo: Code[20]; StatementLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateBankRecHeaderBalance(var BankRecHeader: Record "Bank Rec. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBankRecDifference(var BankRecHeader: Record "Bank Rec. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenProcessingDialog(var Window: Dialog; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostAdjustmentToGL(var BankRecLine2: Record "Bank Rec. Line"; var BankRecHeader: Record "Bank Rec. Header"; var BankRecLine: Record "Bank Rec. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeBankAccountModify(var BankAccount: Record "Bank Account"; BankRecHeader: Record "Bank Rec. Header"; var PostedBankRecHeader: Record "Posted Bank Rec. Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdjustmentToGLOnBeforeGenJnlPostLineRunWithCheck(var GenJnlLine: Record "Gen. Journal Line"; BankRecLine: Record "Bank Rec. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeBankRecLineDeleteAll(var BankRecLine: Record "Bank Rec. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAftertPostedBankRecHeaderInsert(var PostedBankRecHeader: Record "Posted Bank Rec. Header"; var BankRecHeader: Record "Bank Rec. Header")
    begin
    end;
}

