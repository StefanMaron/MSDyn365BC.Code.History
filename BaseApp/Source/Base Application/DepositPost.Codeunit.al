codeunit 10140 "Deposit-Post"
{
    Permissions = TableData "Cust. Ledger Entry" = r,
                  TableData "Vendor Ledger Entry" = r,
                  TableData "Bank Account Ledger Entry" = r,
                  TableData "Posted Deposit Header" = rim,
                  TableData "Posted Deposit Line" = rim;
    TableNo = "Deposit Header";

    trigger OnRun()
    var
        GLEntry: Record "G/L Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccount: Record "Bank Account";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        TotalAmountLCY: Decimal;
        NextLineNo: Integer;
        CurrLineNo: Integer;
    begin
        OnBeforeDepositPost(Rec);

        // Check deposit
        TestField("Posting Date");
        TestField("Total Deposit Amount");
        TestField("Document Date");
        TestField("Bank Account No.");
        BankAccount.Get("Bank Account No.");
        BankAccount.TestField(Blocked, false);
        CalcFields("Total Deposit Lines");
        if "Total Deposit Lines" <> "Total Deposit Amount" then
            Error(Text000, FieldCaption("Total Deposit Amount"), FieldCaption("Total Deposit Lines"));

        OnAfterCheckDeposit(Rec);

        if "Currency Code" = '' then
            Currency.InitRoundingPrecision
        else begin
            Currency.Get("Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;

        SourceCodeSetup.Get();
        GenJnlTemplate.Get("Journal Template Name");

        NextLineNo := 0;
        TotalAmountLCY := 0;
        CurrLineNo := 0;
        Window.Open(
          StrSubstNo(Text001, "No.") +
          Text004 +
          Text002 +
          Text003);

        Window.Update(4, Text005);

        PostedDepositHeader.LockTable();
        PostedDepositLine.LockTable();
        LockTable();
        GenJnlLine.LockTable();

        InsertPostedDepositHeader(Rec);

        GenJnlLine.Reset();
        GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if GenJnlLine.Find('-') then
            repeat
                NextLineNo := NextLineNo + 1;
                Window.Update(2, NextLineNo);

                InsertPostedDepositLine(Rec, GenJnlLine, NextLineNo);

                if GenJnlTemplate."Force Doc. Balance" then
                    AddBalancingAccount(GenJnlLine, Rec)
                else
                    GenJnlLine."Bal. Account No." := '';
                GenJnlCheckLine.RunCheck(GenJnlLine);
            until GenJnlLine.Next() = 0;

        CopyBankComments(Rec);

        // Post to General, and other, Ledgers
        Window.Update(4, Text006);
        GenJnlLine.Reset();
        GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if GenJnlLine.Find('-') then
            repeat
                CurrLineNo := CurrLineNo + 1;
                Window.Update(2, CurrLineNo);
                Window.Update(3, Round(CurrLineNo / NextLineNo * 10000, 1));
                if GenJnlTemplate."Force Doc. Balance" then
                    AddBalancingAccount(GenJnlLine, Rec)
                else begin
                    TotalAmountLCY += GenJnlLine."Amount (LCY)";
                    GenJnlLine."Bal. Account No." := '';
                end;
                GenJnlLine."Source Code" := SourceCodeSetup.Deposits;
                GenJnlLine."Source Type" := GenJnlLine."Source Type"::"Bank Account";
                GenJnlLine."Source No." := "Bank Account No.";
                GenJnlLine."Source Currency Code" := "Currency Code";
                GenJnlLine."Source Currency Amount" := GenJnlLine.Amount;
                OnBeforePostGenJnlLine(GenJnlLine, Rec, GenJnlPostLine);
                GenJnlPostLine.RunWithoutCheck(GenJnlLine);

                PostedDepositLine.Get("No.", CurrLineNo);
                case GenJnlLine."Account Type" of
                    GenJnlLine."Account Type"::"G/L Account",
                    GenJnlLine."Account Type"::"Bank Account":
                        begin
                            GLEntry.FindLast;
                            PostedDepositLine."Entry No." := GLEntry."Entry No.";
                            if GenJnlTemplate."Force Doc. Balance" and (GenJnlLine.Amount * GLEntry.Amount < 0) then
                                PostedDepositLine."Entry No." := PostedDepositLine."Entry No." - 1;
                        end;
                    GenJnlLine."Account Type"::Customer:
                        begin
                            CustLedgEntry.FindLast;
                            PostedDepositLine."Entry No." := CustLedgEntry."Entry No.";
                        end;
                    GenJnlLine."Account Type"::Vendor:
                        begin
                            VendLedgEntry.FindLast;
                            PostedDepositLine."Entry No." := VendLedgEntry."Entry No.";
                        end;
                end;
                if GenJnlTemplate."Force Doc. Balance" then begin
                    BankAccountLedgerEntry.FindLast;
                    PostedDepositLine."Bank Account Ledger Entry No." := BankAccountLedgerEntry."Entry No.";
                    if (GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Bank Account") and
                       (GenJnlLine.Amount * BankAccountLedgerEntry.Amount > 0)
                    then
                        PostedDepositLine."Entry No." := PostedDepositLine."Entry No." - 1;
                end;
                OnBeforePostedDepositLineModify(PostedDepositLine, GenJnlLine);
                PostedDepositLine.Modify();
            until GenJnlLine.Next() = 0;

        Window.Update(4, Text007);
        if not GenJnlTemplate."Force Doc. Balance" then begin
            PostBalancingEntry(Rec, TotalAmountLCY);
            OnRunOnAfterPostBalancingEntry(GenJnlLine);

            BankAccountLedgerEntry.FindLast;
            PostedDepositLine.Reset();
            PostedDepositLine.SetRange("Deposit No.", "No.");
            if PostedDepositLine.FindSet(true) then
                repeat
                    PostedDepositLine."Bank Account Ledger Entry No." := BankAccountLedgerEntry."Entry No.";
                    PostedDepositLine.Modify();
                until PostedDepositLine.Next() = 0;
        end;

        Window.Update(4, Text008);
        DeleteBankComments(Rec);

        GenJnlLine.Reset();
        GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        OnRunOnBeforeGenJnlLineDeleteAll(Rec, PostedDepositLine, GenJnlLine);
        GenJnlLine.DeleteAll();
        GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        if IncStr("Journal Batch Name") <> '' then begin
            GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
            GenJnlBatch.Delete();
            GenJnlBatch.Name := IncStr("Journal Batch Name");
            if GenJnlBatch.Insert() then;
        end;

        Delete;
        Commit();

        UpdateAnalysisView.UpdateAll(0, true);

        OnAfterDepositPost(Rec, PostedDepositHeader);
    end;

    var
        PostedDepositHeader: Record "Posted Deposit Header";
        PostedDepositLine: Record "Posted Deposit Line";
        SourceCodeSetup: Record "Source Code Setup";
        Currency: Record Currency;
        Window: Dialog;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Text000: Label 'The %1 must match the %2.';
        Text001: Label 'Posting Deposit No. %1...\\';
        Text002: Label 'Deposit Line  #2########\';
        Text003: Label '@3@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
        Text004: Label 'Status        #4###################\';
        Text005: Label 'Moving Deposit to History';
        Text006: Label 'Posting Lines to Ledgers';
        Text007: Label 'Posting Bank Entry';
        Text008: Label 'Removing Deposit Entry';

    local procedure AddBalancingAccount(var GenJnlLine: Record "Gen. Journal Line"; DepositHeader: Record "Deposit Header")
    begin
        with GenJnlLine do begin
            "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
            "Bal. Account No." := DepositHeader."Bank Account No.";
            "Balance (LCY)" := 0;
        end;
    end;

    local procedure CopyBankComments(DepositHeader: Record "Deposit Header")
    var
        BankCommentLine: Record "Bank Comment Line";
        BankCommentLine2: Record "Bank Comment Line";
    begin
        BankCommentLine.Reset();
        BankCommentLine.SetRange("Table Name", BankCommentLine."Table Name"::Deposit);
        BankCommentLine.SetRange("Bank Account No.", DepositHeader."Bank Account No.");
        BankCommentLine.SetRange("No.", DepositHeader."No.");
        if BankCommentLine.FindSet then
            repeat
                BankCommentLine2 := BankCommentLine;
                BankCommentLine2."Table Name" := BankCommentLine2."Table Name"::"Posted Deposit";
                BankCommentLine2.Insert();
            until BankCommentLine.Next() = 0;
    end;

    local procedure DeleteBankComments(DepositHeader: Record "Deposit Header")
    var
        BankCommentLine: Record "Bank Comment Line";
    begin
        BankCommentLine.Reset();
        BankCommentLine.SetRange("Table Name", BankCommentLine."Table Name"::Deposit);
        BankCommentLine.SetRange("Bank Account No.", DepositHeader."Bank Account No.");
        BankCommentLine.SetRange("No.", DepositHeader."No.");
        BankCommentLine.DeleteAll();
    end;

    local procedure InsertPostedDepositHeader(var DepositHeader: Record "Deposit Header")
    var
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        PostedDepositHeader.Reset();
        PostedDepositHeader.TransferFields(DepositHeader, true);
        PostedDepositHeader."No. Printed" := 0;
        OnBeforePostedDepositHeaderInsert(PostedDepositHeader, DepositHeader);
        PostedDepositHeader.Insert();
        RecordLinkManagement.CopyLinks(DepositHeader, PostedDepositHeader);
    end;

    local procedure InsertPostedDepositLine(DepositHeader: Record "Deposit Header"; GenJnlLine: Record "Gen. Journal Line"; LineNo: Integer)
    begin
        with PostedDepositLine do begin
            "Deposit No." := DepositHeader."No.";
            "Line No." := LineNo;
            "Account Type" := GenJnlLine."Account Type";
            "Account No." := GenJnlLine."Account No.";
            "Document Date" := GenJnlLine."Document Date";
            "Document Type" := GenJnlLine."Document Type";
            "Document No." := GenJnlLine."Document No.";
            Description := GenJnlLine.Description;
            "Currency Code" := GenJnlLine."Currency Code";
            Amount := -GenJnlLine.Amount;
            "Posting Group" := GenJnlLine."Posting Group";
            "Shortcut Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
            "Dimension Set ID" := GenJnlLine."Dimension Set ID";
            "Posting Date" := DepositHeader."Posting Date";
            OnBeforePostedDepositLineInsert(PostedDepositLine, GenJnlLine);
            Insert;
        end;
    end;

    local procedure PostBalancingEntry(DepositHeader: Record "Deposit Header"; TotalAmountLCY: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        with GenJnlLine do begin
            Init;
            "Account Type" := "Account Type"::"Bank Account";
            "Account No." := DepositHeader."Bank Account No.";
            "Posting Date" := DepositHeader."Posting Date";
            "Document No." := DepositHeader."No.";
            "Currency Code" := DepositHeader."Currency Code";
            "Currency Factor" := DepositHeader."Currency Factor";
            "Posting Group" := DepositHeader."Bank Acc. Posting Group";
            "Shortcut Dimension 1 Code" := DepositHeader."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := DepositHeader."Shortcut Dimension 2 Code";
            "Dimension Set ID" := DepositHeader."Dimension Set ID";
            "Source Code" := SourceCodeSetup.Deposits;
            "Reason Code" := DepositHeader."Reason Code";
            "Document Date" := DepositHeader."Document Date";
            "External Document No." := DepositHeader."No.";
            "Source Type" := "Source Type"::"Bank Account";
            "Source No." := DepositHeader."Bank Account No.";
            "Source Currency Code" := DepositHeader."Currency Code";
            Description := DepositHeader."Posting Description";
            Amount := DepositHeader."Total Deposit Amount";
            "Source Currency Amount" := DepositHeader."Total Deposit Amount";
            Validate(Amount);
            "Amount (LCY)" := -TotalAmountLCY;
            OnBeforePostBalancingEntry(GenJnlLine, DepositHeader, GenJnlPostLine);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnAfterPostBalancingEntry(GenJnlLine);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDeposit(DepositHeader: Record "Deposit Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDepositPost(DepositHeader: Record "Deposit Header"; var PostedDepositHeader: Record "Posted Deposit Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDepositPost(var DepositHeader: Record "Deposit Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; DepositHeader: Record "Deposit Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; DepositHeader: Record "Deposit Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedDepositHeaderInsert(var PostedDepositHeader: Record "Posted Deposit Header"; DepositHeader: Record "Deposit Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedDepositLineInsert(var PostedDepositLine: Record "Posted Deposit Line"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedDepositLineModify(var PostedDepositLine: Record "Posted Deposit Line"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterPostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeGenJnlLineDeleteAll(var DepositHeader: Record "Deposit Header"; var PostedDepositLine: Record "Posted Deposit Line"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;
}

