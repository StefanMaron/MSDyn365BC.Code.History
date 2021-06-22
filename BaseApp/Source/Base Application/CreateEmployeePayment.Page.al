page 1191 "Create Employee Payment"
{
    Caption = 'Create Employee Payment';
    PageType = StandardDialog;
    SaveValues = true;

    layout
    {
        area(content)
        {
            group(Control6)
            {
                ShowCaption = false;
                field("Batch Name"; JournalBatchName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Batch Name';
                    ShowMandatory = true;
                    TableRelation = "Gen. Journal Batch".Name WHERE("Template Type" = CONST(Payments),
                                                                     Recurring = CONST(false));
                    ToolTip = 'Specifies the name of the journal batch.';

                    trigger OnValidate()
                    var
                        GenJournalBatch: Record "Gen. Journal Batch";
                    begin
                        SetJournalTemplate;
                        if JournalTemplateName <> '' then begin
                            GenJournalBatch.Get(JournalTemplateName, JournalBatchName);
                            SetNextNo(GenJournalBatch."No. Series");
                        end;
                    end;
                }
                field("Posting Date"; PostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ShowMandatory = true;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Starting Document No."; NextDocNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Document No.';
                    ShowMandatory = true;
                    ToolTip = 'Specifies a document number for the journal line.';

                    trigger OnValidate()
                    begin
                        if NextDocNo <> '' then
                            if IncStr(NextDocNo) = '' then
                                Error(StartingDocumentNoErr);
                    end;
                }
                field("Bank Account"; BalAccountNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account';
                    TableRelation = "Bank Account";
                    ToolTip = 'Specifies the bank account to which a balancing entry for the journal line will be posted.';
                }
                field("Payment Type"; BankPaymentType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Type';
                    ToolTip = 'Specifies the code for the payment type to be used for the entry on the payment journal line.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SetJournalTemplate;
        if GenJournalBatch.Get(JournalTemplateName, JournalBatchName) then
            SetNextNo(GenJournalBatch."No. Series")
        else
            Clear(JournalBatchName);
        PostingDate := WorkDate;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::OK then begin
            if JournalBatchName = '' then
                Error(BatchNumberNotFilledErr);
            if Format(PostingDate) = '' then
                Error(PostingDateNotFilledErr);
            if NextDocNo = '' then
                Error(SpecifyStartingDocNumErr);
        end;
    end;

    var
        TempEmplPaymentBuffer: Record "Employee Payment Buffer" temporary;
        PostingDate: Date;
        BalAccountNo: Code[20];
        NextDocNo: Code[20];
        JournalBatchName: Code[10];
        JournalTemplateName: Code[10];
        BankPaymentType: Enum "Bank Payment Type";
        StartingDocumentNoErr: Label 'Starting Document No.';
        BatchNumberNotFilledErr: Label 'You must fill the Batch Name field.';
        PostingDateNotFilledErr: Label 'You must fill the Posting Date field.';
        SpecifyStartingDocNumErr: Label 'In the Starting Document No. field, specify the first document number to be used.';

    procedure GetPostingDate(): Date
    begin
        exit(PostingDate);
    end;

    procedure GetBankAccount(): Text
    begin
        exit(Format(BalAccountNo));
    end;

    procedure GetBankPaymentType(): Integer
    begin
        exit(BankPaymentType);
    end;

    procedure GetBatchNumber(): Code[10]
    begin
        exit(JournalBatchName);
    end;

    procedure MakeGenJnlLines(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        TempEmplPaymentBuffer.Reset();
        TempEmplPaymentBuffer.DeleteAll();

        CopyEmployeeLedgerEntriesToTempEmplPaymentBuffer(EmployeeLedgerEntry);
        CopyTempEmpPaymentBuffersToGenJnlLines;
    end;

    local procedure CopyEmployeeLedgerEntriesToTempEmplPaymentBuffer(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    var
        PaymentAmt: Decimal;
    begin
        if EmployeeLedgerEntry.Find('-') then
            repeat
                EmployeeLedgerEntry.CalcFields("Remaining Amount");
                if (EmployeeLedgerEntry."Applies-to ID" = '') and (EmployeeLedgerEntry."Remaining Amount" < 0) then begin
                    TempEmplPaymentBuffer."Employee No." := EmployeeLedgerEntry."Employee No.";
                    TempEmplPaymentBuffer."Currency Code" := EmployeeLedgerEntry."Currency Code";
                    TempEmplPaymentBuffer."Payment Method Code" := EmployeeLedgerEntry."Payment Method Code";
                    TempEmplPaymentBuffer."Creditor No." := EmployeeLedgerEntry."Creditor No.";
                    TempEmplPaymentBuffer."Payment Reference" := EmployeeLedgerEntry."Payment Reference";
                    TempEmplPaymentBuffer."Exported to Payment File" := EmployeeLedgerEntry."Exported to Payment File";
                    TempEmplPaymentBuffer."Dimension Entry No." := 0;
                    TempEmplPaymentBuffer."Global Dimension 1 Code" := '';
                    TempEmplPaymentBuffer."Global Dimension 2 Code" := '';
                    TempEmplPaymentBuffer."Dimension Set ID" := 0;
                    TempEmplPaymentBuffer."Employee Ledg. Entry No." := EmployeeLedgerEntry."Entry No.";
                    TempEmplPaymentBuffer."Employee Ledg. Entry Doc. Type" := EmployeeLedgerEntry."Document Type";

                    PaymentAmt := -EmployeeLedgerEntry."Remaining Amount";

                    TempEmplPaymentBuffer.Reset();
                    TempEmplPaymentBuffer.SetRange("Employee No.", EmployeeLedgerEntry."Employee No.");
                    if TempEmplPaymentBuffer.Find('-') then begin
                        TempEmplPaymentBuffer.Amount := TempEmplPaymentBuffer.Amount + PaymentAmt;
                        TempEmplPaymentBuffer.Modify();
                    end else begin
                        TempEmplPaymentBuffer."Document No." := NextDocNo;
                        NextDocNo := IncStr(NextDocNo);
                        TempEmplPaymentBuffer.Amount := PaymentAmt;
                        TempEmplPaymentBuffer.Insert();
                    end;
                    EmployeeLedgerEntry."Applies-to ID" := TempEmplPaymentBuffer."Document No.";
                    EmployeeLedgerEntry."Amount to Apply" := EmployeeLedgerEntry."Remaining Amount";
                    CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", EmployeeLedgerEntry);
                end;
            until EmployeeLedgerEntry.Next = 0;
    end;

    local procedure CopyTempEmpPaymentBuffersToGenJnlLines()
    var
        CompanyInformation: Record "Company Information";
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        Employee: Record Employee;
        BalAccType: Option "G/L Account",Customer,Vendor,"Bank Account";
        LastLineNo: Integer;
    begin
        GenJnlLine.LockTable();
        GenJournalTemplate.Get(JournalTemplateName);
        GenJournalBatch.Get(JournalTemplateName, JournalBatchName);
        GenJnlLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJnlLine.SetRange("Journal Batch Name", JournalBatchName);
        if GenJnlLine.FindLast then begin
            LastLineNo := GenJnlLine."Line No.";
            GenJnlLine.Init();
        end;

        TempEmplPaymentBuffer.Reset();
        TempEmplPaymentBuffer.SetCurrentKey("Document No.");
        TempEmplPaymentBuffer.SetFilter(
          "Employee Ledg. Entry Doc. Type", '<>%1&<>%2', TempEmplPaymentBuffer."Employee Ledg. Entry Doc. Type"::Refund,
          TempEmplPaymentBuffer."Employee Ledg. Entry Doc. Type"::Payment);
        if TempEmplPaymentBuffer.FindSet then
            repeat
                with GenJnlLine do begin
                    Init;
                    Validate("Journal Template Name", JournalTemplateName);
                    Validate("Journal Batch Name", JournalBatchName);
                    LastLineNo := LastLineNo + 10000;
                    "Line No." := LastLineNo;
                    "Document Type" := "Document Type"::Payment;
                    "Posting No. Series" := GenJournalBatch."Posting No. Series";
                    "Document No." := TempEmplPaymentBuffer."Document No.";
                    "Account Type" := "Account Type"::Employee;
                    SetHideValidation(true);
                    Validate("Posting Date", PostingDate);
                    Validate("Account No.", TempEmplPaymentBuffer."Employee No.");

                    Employee.Get(TempEmplPaymentBuffer."Employee No.");

                    "Bal. Account Type" := BalAccType::"Bank Account";
                    Validate("Bal. Account No.", BalAccountNo);
                    Validate("Currency Code", TempEmplPaymentBuffer."Currency Code");

                    CompanyInformation.Get();
                    "Message to Recipient" := CompanyInformation.Name;

                    "Bank Payment Type" := BankPaymentType;
                    "Applies-to ID" := "Document No.";
                    Description := CopyStr(Employee.FullName, 1, MaxStrLen(Description));
                    "Source Line No." := TempEmplPaymentBuffer."Employee Ledg. Entry No.";
                    "Shortcut Dimension 1 Code" := TempEmplPaymentBuffer."Global Dimension 1 Code";
                    "Shortcut Dimension 2 Code" := TempEmplPaymentBuffer."Global Dimension 2 Code";
                    "Dimension Set ID" := TempEmplPaymentBuffer."Dimension Set ID";
                    "Source Code" := GenJournalTemplate."Source Code";
                    "Reason Code" := GenJournalBatch."Reason Code";
                    Validate(Amount, TempEmplPaymentBuffer.Amount);
                    "Applies-to Doc. Type" := TempEmplPaymentBuffer."Employee Ledg. Entry Doc. Type";
                    "Applies-to Doc. No." := TempEmplPaymentBuffer."Employee Ledg. Entry Doc. No.";
                    Validate("Payment Method Code", TempEmplPaymentBuffer."Payment Method Code");
                    "Creditor No." := CopyStr(TempEmplPaymentBuffer."Creditor No.", 1, MaxStrLen("Creditor No."));
                    "Payment Reference" := CopyStr(TempEmplPaymentBuffer."Payment Reference", 1, MaxStrLen("Payment Reference"));
                    "Exported to Payment File" := TempEmplPaymentBuffer."Exported to Payment File";
                    "Applies-to Ext. Doc. No." := TempEmplPaymentBuffer."Applies-to Ext. Doc. No.";

                    UpdateDimensions(GenJnlLine, TempEmplPaymentBuffer);
                    Insert;
                end;
            until TempEmplPaymentBuffer.Next = 0;
    end;

    local procedure UpdateDimensions(var GenJnlLine: Record "Gen. Journal Line"; TempEmplPaymentBuffer: Record "Employee Payment Buffer" temporary)
    var
        DimBuf: Record "Dimension Buffer";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimVal: Record "Dimension Value";
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        NewDimensionID: Integer;
        DimSetIDArr: array[10] of Integer;
    begin
        with GenJnlLine do begin
            NewDimensionID := "Dimension Set ID";

            DimBuf.Reset();
            DimBuf.DeleteAll();
            DimBufMgt.GetDimensions(TempEmplPaymentBuffer."Dimension Entry No.", DimBuf);
            if DimBuf.FindSet then
                repeat
                    DimVal.Get(DimBuf."Dimension Code", DimBuf."Dimension Value Code");
                    TempDimSetEntry."Dimension Code" := DimBuf."Dimension Code";
                    TempDimSetEntry."Dimension Value Code" := DimBuf."Dimension Value Code";
                    TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
                    TempDimSetEntry.Insert();
                until DimBuf.Next = 0;
            NewDimensionID := DimMgt.GetDimensionSetID(TempDimSetEntry);
            "Dimension Set ID" := NewDimensionID;

            CreateDim(
              DimMgt.TypeToTableID1("Account Type"), "Account No.",
              DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
              DATABASE::Job, "Job No.",
              DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
              DATABASE::Campaign, "Campaign No.");
            if NewDimensionID <> "Dimension Set ID" then begin
                DimSetIDArr[1] := "Dimension Set ID";
                DimSetIDArr[2] := NewDimensionID;
                "Dimension Set ID" :=
                  DimMgt.GetCombinedDimensionSetID(DimSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;

            DimMgt.GetDimensionSet(TempDimSetEntry, "Dimension Set ID");
            DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code",
              "Shortcut Dimension 2 Code");
        end;
    end;

    local procedure SetJournalTemplate()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Reset();
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.SetRange(Recurring, false);
        if GenJournalTemplate.FindFirst then
            JournalTemplateName := GenJournalTemplate.Name;
    end;

    local procedure SetNextNo(GenJournalBatchNoSeries: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        if GenJournalBatchNoSeries = '' then
            NextDocNo := ''
        else begin
            GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
            GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
            if GenJournalLine.FindLast then
                NextDocNo := IncStr(GenJournalLine."Document No.")
            else
                NextDocNo := NoSeriesMgt.GetNextNo(GenJournalBatchNoSeries, PostingDate, false);
            Clear(NoSeriesMgt);
        end;
    end;
}

