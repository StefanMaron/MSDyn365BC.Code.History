#pragma warning disable AS0074
#if not CLEAN21
report 10406 "Bank Rec. Process Lines"
{
    Caption = 'Bank Rec. Process Lines';
    Permissions = TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rm;
    ProcessingOnly = true;
    ObsoleteReason = 'Deprecated in favor of W1 Bank Reconciliation';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#pragma warning restore AS0074

    dataset
    {
        dataitem("Bank Rec. Header"; "Bank Rec. Header")
        {
            DataItemTableView = SORTING("Bank Account No.", "Statement No.");
            MaxIteration = 1;
            dataitem("Bank Rec. Line"; "Bank Rec. Line")
            {
                DataItemLink = "Bank Account No." = FIELD("Bank Account No."), "Statement No." = FIELD("Statement No.");
                DataItemTableView = SORTING("Bank Account No.", "Statement No.", "Record Type", "Line No.");
                MaxIteration = 0;
                RequestFilterFields = "Posting Date", "Document Type", "Document No.";
            }
            dataitem(RunProcesses; "Integer")
            {
                DataItemTableView = SORTING(Number);
                MaxIteration = 1;

                trigger OnAfterGetRecord()
                begin
                    if DoSuggestLines then
                        SuggestLines();

                    if DoMarkLines then
                        MarkLines();

                    if DoAdjLines then
                        RecordAdjustmentLines();

                    if DoClearLines then
                        ClearLines();
                end;
            }

            trigger OnPreDataItem()
            begin
                SetRange("Bank Account No.", DoBankAcct);
                SetRange("Statement No.", DoStatementNo);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(RecordTypeToProcess; RecordTypeToProcess)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Record type to process';
                        OptionCaption = 'Checks,Deposits,Both';
                        ToolTip = 'Specifies the type of bank reconciliation records to process: Checks, Deposits, or Both.';
                    }
                    field(MarkAsCleared; MarkCleared)
                    {
                        ApplicationArea = All;
                        Caption = 'Mark lines as cleared';
                        ToolTip = 'Specifies is cleared bank reconciliation lines are marked as cleared. In that case, you must select Process in the Record type to process field.';
                        Visible = MarkAsClearedVisible;
                    }
                    field(ReplaceLines; ReplaceExisting)
                    {
                        ApplicationArea = All;
                        Caption = 'Replace existing lines';
                        ToolTip = 'Specifies if identical existing bank account reconciliation lines are replaced. ';
                        Visible = ReplaceLinesVisible;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            MarkAsClearedVisible := true;
            ReplaceLinesVisible := true;
        end;

        trigger OnOpenPage()
        begin
            ReplaceLinesVisible := DoSuggestLines;
            MarkAsClearedVisible := DoMarkLines;
        end;
    }

    labels
    {
    }

    var
        DoSuggestLines: Boolean;
        DoMarkLines: Boolean;
        DoAdjLines: Boolean;
        DoClearLines: Boolean;
        ReplaceExisting: Boolean;
        MarkCleared: Boolean;
        RecordTypeToProcess: Option Checks,Deposits,Both;
        LastLineNo: Integer;
        AdjAmount: Decimal;
        DoBankAcct: Code[20];
        DoStatementNo: Code[20];
        GLSetup: Record "General Ledger Setup";
        BankRecLine: Record "Bank Rec. Line";
        Window: Dialog;
        Text001: Label 'Processing bank account  #1####################\\';
        Text002: Label 'Reading bank ledger entries       #2##########\';
        Text003: Label 'Reading check ledger entries      #3##########\';
        Text004: Label '                      Statement  #2####################\';
        Text005: Label '                  Marking lines  #3####################';
        Text006: Label '              Processing lines  #3####################';
        Text007: Label '                  Clearing lines  #3####################';
        Text008: Label 'Collapsing Deposit Lines...';
        [InDataSet]
        ReplaceLinesVisible: Boolean;
        [InDataSet]
        MarkAsClearedVisible: Boolean;

    procedure SetDoSuggestLines(UseDo: Boolean; UseBankAcct: Code[20]; UseStatementNo: Code[20])
    begin
        DoSuggestLines := UseDo;
        DoBankAcct := UseBankAcct;
        DoStatementNo := UseStatementNo;
    end;

    procedure SetDoMarkLines(UseDo: Boolean; UseBankAcct: Code[20]; UseStatementNo: Code[20])
    begin
        DoMarkLines := UseDo;
        DoBankAcct := UseBankAcct;
        DoStatementNo := UseStatementNo;
    end;

    procedure SetDoAdjLines(UseDo: Boolean; UseBankAcct: Code[20]; UseStatementNo: Code[20])
    begin
        DoAdjLines := UseDo;
        DoBankAcct := UseBankAcct;
        DoStatementNo := UseStatementNo;
    end;

    procedure SetDoClearLines(UseDo: Boolean; UseBankAcct: Code[20]; UseStatementNo: Code[20])
    begin
        DoClearLines := UseDo;
        DoBankAcct := UseBankAcct;
        DoStatementNo := UseStatementNo;
    end;

    procedure SuggestLines()
    var
        RecordType: Option Check,Deposit,Adjustment;
        BankLedger: Record "Bank Account Ledger Entry";
        CheckLedger: Record "Check Ledger Entry";
        BankRecLine2: Record "Bank Rec. Line";
    begin
        Window.Open(Text001 + Text002 + Text003);
        Window.Update(1, "Bank Rec. Header"."Bank Account No.");

        if ReplaceExisting then begin
            BankRecLine.SetCurrentKey("Bank Account No.", "Statement No.");
            BankRecLine.SetRange("Bank Account No.", "Bank Rec. Header"."Bank Account No.");
            BankRecLine.SetRange("Statement No.", "Bank Rec. Header"."Statement No.");
            if RecordTypeToProcess <> RecordTypeToProcess::Both then
                BankRecLine.SetRange("Record Type", RecordTypeToProcess);
            BankRecLine.DeleteAll(true);
            BankRecLine.Reset();
        end;

        with BankLedger do begin
            SetCurrentKey("Bank Account No.", "Posting Date", "Statement Status");
            SetRange("Bank Account No.", "Bank Rec. Header"."Bank Account No.");
            SetRange("Statement Status", "Statement Status"::Open);
            if "Bank Rec. Line".GetFilter("Posting Date") = '' then
                SetRange("Posting Date", 0D, "Bank Rec. Header"."Statement Date")
            else
                "Bank Rec. Line".CopyFilter("Posting Date", "Posting Date");
            "Bank Rec. Line".CopyFilter("Document Type", "Document Type");
            "Bank Rec. Line".CopyFilter("Document No.", "Document No.");
            "Bank Rec. Line".CopyFilter("External Document No.", "External Document No.");
            if Find('-') then
                repeat
                    Window.Update(2, "Entry No.");
                    CheckLedger.SetCurrentKey("Bank Account Ledger Entry No.");
                    CheckLedger.SetRange("Bank Account Ledger Entry No.", "Entry No.");
                    CheckLedger.SetRange("Statement Status", "Statement Status"::Open);
                    if CheckLedger.Find('-') then begin
                        repeat
                            Window.Update(3, CheckLedger."Entry No.");
                            if RecordTypeToProcess in [RecordTypeToProcess::Both, RecordTypeToProcess::Checks] then
                                WriteLine("Bank Rec. Header",
                                  BankRecLine,
                                  ReplaceExisting,
                                  RecordType::Check,
                                  CheckLedger."Document Type",
                                  CheckLedger."Check No.",
                                  CheckLedger.Description,
                                  CheckLedger.Amount,
                                  CheckLedger."External Document No.",
                                  "Entry No.",
                                  CheckLedger."Entry No.",
                                  CheckLedger."Posting Date",
                                  "Global Dimension 1 Code",
                                  "Global Dimension 2 Code",
                                  "Dimension Set ID");

                        until CheckLedger.Next() = 0;
                    end else begin
                        if RecordTypeToProcess in [RecordTypeToProcess::Both, RecordTypeToProcess::Deposits] then
                            WriteLine("Bank Rec. Header",
                              BankRecLine,
                              ReplaceExisting,
                              RecordType::Deposit,
                              "Document Type",
                              "Document No.",
                              Description,
                              Amount,
                              "External Document No.",
                              "Entry No.",
                              0,
                              "Posting Date",
                              "Global Dimension 1 Code",
                              "Global Dimension 2 Code",
                              "Dimension Set ID");
                    end;
                until Next() = 0;
        end;
        Window.Close();
        if RecordTypeToProcess in [RecordTypeToProcess::Both, RecordTypeToProcess::Deposits] then begin
            Window.Open(Text008);
            with BankRecLine do begin
                Reset();
                SetCurrentKey("Bank Account No.", "Statement No.", "Record Type");
                SetRange("Bank Account No.", "Bank Rec. Header"."Bank Account No.");
                SetRange("Statement No.", "Bank Rec. Header"."Statement No.");
                SetRange("Record Type", "Record Type"::Deposit);
                SetRange("Collapse Status", "Collapse Status"::"Expanded Deposit Line");
                if Find('-') then
                    repeat
                        BankRecLine2 := BankRecLine;
                        CollapseLines(BankRecLine2);
                    until Next() = 0;
                Reset();
            end;
            Window.Close();
        end;
    end;

    procedure MarkLines()
    begin
        Window.Open(Text001 + Text004 + Text005);
        Window.Update(1, "Bank Rec. Header"."Bank Account No.");
        Window.Update(2, "Bank Rec. Header"."Statement No.");

        BankRecLine.CopyFilters("Bank Rec. Line");
        if RecordTypeToProcess = RecordTypeToProcess::Both then
            BankRecLine.SetRange("Record Type", BankRecLine."Record Type"::Check,
              BankRecLine."Record Type"::Deposit)
        else
            if RecordTypeToProcess = RecordTypeToProcess::Checks then
                BankRecLine.SetRange("Record Type", BankRecLine."Record Type"::Check)
            else
                BankRecLine.SetRange("Record Type", BankRecLine."Record Type"::Deposit);

        if BankRecLine.Find('-') then
            repeat
                BankRecLine.Validate(Cleared, MarkCleared);
                BankRecLine.Modify();
                Window.Update(3, BankRecLine."Line No.");
            until BankRecLine.Next() = 0;

        Window.Close();
    end;

    procedure RecordAdjustmentLines()
    var
        UseRecordType: Option Check,Deposit,Adjustment;
        NewBankRecLine: Record "Bank Rec. Line";
    begin
        Window.Open(Text001 + Text004 + Text006);
        Window.Update(1, "Bank Rec. Header"."Bank Account No.");
        Window.Update(2, "Bank Rec. Header"."Statement No.");

        GLSetup.Get();

        with BankRecLine do begin
            Reset();
            SetCurrentKey("Bank Account No.",
              "Statement No.",
              "Record Type",
              Cleared);
            SetRange("Bank Account No.", "Bank Rec. Header"."Bank Account No.");
            SetRange("Statement No.", "Bank Rec. Header"."Statement No.");
            if RecordTypeToProcess <> RecordTypeToProcess::Both then
                SetRange("Record Type", RecordTypeToProcess);
            SetRange(Cleared, true);

            if Find('-') then
                repeat
                    Window.Update(3, "Line No.");
                    if "Record Type" = "Record Type"::Check then
                        AdjAmount := -("Cleared Amount" - Amount)
                    else
                        AdjAmount := "Cleared Amount" - Amount;
                    if AdjAmount <> 0 then begin
                        WriteAdjLine("Bank Rec. Header",
                          NewBankRecLine,
                          UseRecordType::Adjustment,
                          "Document Type",
                          "Document No.",
                          Description,
                          AdjAmount,
                          "External Document No.",
                          "Record Type",
                          "Dimension Set ID");
                        Modify();
                    end;
                until Next() = 0;
        end;
        Window.Close();
    end;

    procedure ClearLines()
    begin
        Window.Open(Text001 + Text004 + Text007);
        Window.Update(1, "Bank Rec. Header"."Bank Account No.");
        Window.Update(2, "Bank Rec. Header"."Statement No.");

        BankRecLine.CopyFilters("Bank Rec. Line");
        if RecordTypeToProcess = RecordTypeToProcess::Both then
            BankRecLine.SetRange("Record Type", BankRecLine."Record Type"::Check,
              BankRecLine."Record Type"::Deposit)
        else
            if RecordTypeToProcess = RecordTypeToProcess::Checks then
                BankRecLine.SetRange("Record Type", BankRecLine."Record Type"::Check)
            else
                BankRecLine.SetRange("Record Type", BankRecLine."Record Type"::Deposit);

        if BankRecLine.Find('-') then
            repeat
                BankRecLine.Delete(true);
                Window.Update(3, BankRecLine."Line No.");
            until BankRecLine.Next() = 0;

        Window.Close();
    end;

    local procedure WriteLine(BankRecHdr2: Record "Bank Rec. Header"; var BankRecLine2: Record "Bank Rec. Line"; UseReplaceExisting: Boolean; UseRecordType: Option Check,Deposit,Adjustment; UseDocumentType: Enum "Gen. Journal Document Type"; UseDocumentNo: Code[20]; UseDescription: Text[100]; UseAmount: Decimal; UseExtDocNo: Code[35]; UseBankLedgerEntryNo: Integer; UseCheckLedgerEntryNo: Integer; UsePostingDate: Date; UseDimCode1: Code[20]; UseDimCode2: Code[20]; UseDimSetID: Integer)
    var
        Ok: Boolean;
    begin
        if (RecordTypeToProcess = RecordTypeToProcess::Both) or
           (UseRecordType = RecordTypeToProcess)
        then
            with BankRecHdr2 do begin
                BankRecLine2.SetCurrentKey("Bank Account No.", "Statement No.");
                BankRecLine2.SetRange("Bank Account No.", "Bank Account No.");
                BankRecLine2.SetRange("Statement No.", "Statement No.");
                if BankRecLine2.Find('+') then
                    LastLineNo := BankRecLine2."Line No."
                else
                    LastLineNo := 0;
                BankRecLine2.Reset();

                BankRecLine2.Init();
                BankRecLine2."Bank Account No." := "Bank Account No.";
                BankRecLine2."Statement No." := "Statement No.";
                BankRecLine2."Record Type" := UseRecordType;
                BankRecLine2."Posting Date" := UsePostingDate;
                BankRecLine2."Document Type" := UseDocumentType;
                BankRecLine2."Document No." := UseDocumentNo;
                BankRecLine2.Description := UseDescription;
                BankRecLine2.Amount := UseAmount;
                BankRecLine2.Validate("Currency Code", "Currency Code");
                BankRecLine2."External Document No." := UseExtDocNo;
                BankRecLine2."Bank Ledger Entry No." := UseBankLedgerEntryNo;
                BankRecLine2."Check Ledger Entry No." := UseCheckLedgerEntryNo;
                BankRecLine2."Shortcut Dimension 1 Code" := UseDimCode1;
                BankRecLine2."Shortcut Dimension 2 Code" := UseDimCode2;
                BankRecLine2."Dimension Set ID" := UseDimSetID;
                if (UseRecordType = UseRecordType::Deposit) and (UseExtDocNo <> '') then
                    BankRecLine2."Collapse Status" := BankRecLine2."Collapse Status"::"Expanded Deposit Line";

                if UseReplaceExisting then
                    InsertLine(BankRecLine2)
                else begin
                    BankRecLine2.SetCurrentKey("Bank Account No.",
                      "Statement No.",
                      "Posting Date",
                      "Document Type",
                      "Document No.",
                      "External Document No.");
                    BankRecLine2.SetRange("Bank Account No.", "Bank Account No.");
                    BankRecLine2.SetRange("Statement No.", "Statement No.");
                    BankRecLine2.SetRange("Bank Ledger Entry No.", UseBankLedgerEntryNo);
                    BankRecLine2.SetRange("Check Ledger Entry No.", UseCheckLedgerEntryNo);
                    Ok := BankRecLine2.Find('-');
                    if Ok then begin
                        BankRecLine2.Description := UseDescription;
                        BankRecLine2.Amount := UseAmount;
                        BankRecLine2.Validate("Currency Code", "Currency Code");
                        BankRecLine2.Modify();
                    end else
                        InsertLine(BankRecLine2);
                end;

                OnAfterWriteLine(BankRecHdr2, BankRecLine2);
            end;
    end;

    local procedure InsertLine(var BankRecLine3: Record "Bank Rec. Line")
    var
        Ok: Boolean;
    begin
        repeat
            LastLineNo := LastLineNo + 10000;
            BankRecLine3."Line No." := LastLineNo;
            Ok := BankRecLine3.Insert(true);
        until Ok
    end;

    local procedure WriteAdjLine(BankRecHdr2: Record "Bank Rec. Header"; var BankRecLine2: Record "Bank Rec. Line"; UseRecordType: Option Check,Deposit,Adjustment; UseDocumentType: Enum "Gen. Journal Document Type"; UseDocumentNo: Code[20]; UseDescription: Text[100]; UseAmount: Decimal; UseExtDocNo: Code[35]; UseSourceType: Option Check,Deposit,Adjustment; DimSetID: Integer)
    var
        Ok: Boolean;
        WorkDocumentNo: Code[20];
        NoSeriesMgmnt: Codeunit NoSeriesManagement;
    begin
        with BankRecHdr2 do begin
            if BankRecLine2.Find('+') then
                LastLineNo := BankRecLine2."Line No."
            else
                LastLineNo := 0;

            NoSeriesMgmnt.InitSeries(GLSetup."Bank Rec. Adj. Doc. Nos.", '', "Statement Date", WorkDocumentNo,
              BankRecLine2."Adj. No. Series");

            BankRecLine2.Init();
            BankRecLine2."Bank Account No." := "Bank Account No.";
            BankRecLine2."Statement No." := "Statement No.";
            BankRecLine2."Record Type" := UseRecordType;
            BankRecLine2."Posting Date" := "Statement Date";
            BankRecLine2."Document Type" := UseDocumentType;
            BankRecLine2."Document No." := WorkDocumentNo;
            BankRecLine2."Dimension Set ID" := DimSetID;
            BankRecLine2.Description := CopyStr(StrSubstNo('Adjustment to %1', UseDescription), 1, 50);
            BankRecLine2.Cleared := true;
            BankRecLine2.Amount := UseAmount;
            BankRecLine2."Cleared Amount" := BankRecLine2.Amount;
            BankRecLine2.Validate("Currency Code", "Currency Code");
            BankRecLine2."External Document No." := UseExtDocNo;
            BankRecLine2."Account Type" := BankRecLine2."Account Type"::"Bank Account";
            BankRecLine2."Account No." := "Bank Account No.";
            BankRecLine2."Adj. Source Record ID" := UseSourceType;
            BankRecLine2."Adj. Source Document No." := UseDocumentNo;

            repeat
                LastLineNo := LastLineNo + 10000;
                BankRecLine2."Line No." := LastLineNo;
                Ok := BankRecLine2.Insert();
            until Ok
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWriteLine(BankRecHdr2: Record "Bank Rec. Header"; var BankRecLine2: Record "Bank Rec. Line")
    begin
    end;
}

#endif