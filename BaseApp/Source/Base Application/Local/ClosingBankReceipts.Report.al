report 12171 "Closing Bank Receipts"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Closing Bank Receipts';
    Permissions = TableData "Cust. Ledger Entry" = imd;
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(CustEntry1; "Cust. Ledger Entry")
        {
            DataItemTableView = SORTING("Due Date", "Customer No.", "Bank Receipt", "Bank Receipt Temp. No.", "Customer Bill No.") ORDER(Ascending) WHERE("Document Type" = CONST(Payment), Open = CONST(true), "Bank Receipt" = CONST(true));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Customer No.", "Due Date";
            dataitem(CustEntry2; "Cust. Ledger Entry")
            {
                DataItemLink = "Document Type" = FIELD("Document Type to Close"), "Document No." = FIELD("Document No. to Close"), "Document Occurrence" = FIELD("Document Occurrence to Close"), "Customer No." = FIELD("Customer No.");
                DataItemTableView = SORTING("Document Type", "Document No.", "Document Occurrence", "Customer No.") ORDER(Ascending) WHERE(Open = CONST(true), "Bank Receipt Issued" = CONST(true), "Customer Bill No." = FILTER(<> ''));

                trigger OnAfterGetRecord()
                var
                    ApplyUnapplyParameters: Record "Apply Unapply Parameters";
                    ApplyCustomerEntries: Page "Apply Customer Entries";
                    DocumentNo: Code[20];
                begin
                    CustLedgEntry.SetFilter("Entry No.", '%1|%2', CustEntry1."Entry No.", "Entry No.");
                    CustLedgEntry.ModifyAll("Applies-to ID", '');
                    CustEntrySetApplId.SetApplId(CustLedgEntry, CustEntry1, Format("Entry No."));

                    Commit();

                    Clear(CustEntryApplyPostedEntries);
                    CustEntryApplyPostedEntries.SetCheckDim(CheckDim);
                    CustLedgEntry.Get(CustEntry1."Entry No.");
                    DocumentNo := CustLedgEntry."Document No.";
                    if Confirmation then begin
                        if not Confirm(Text1130000, false, "Document Type", "Document No.") then
                            exit;
                        ApplyCustomerEntries.AskForDocNoAndApplnDate(DocumentNo, ClosePerDay);
                    end;
                    ApplyUnapplyParameters."Document No." := DocumentNo;
                    ApplyUnapplyParameters."Posting Date" := ClosePerDay;
                    CustEntryApplyPostedEntries.Apply(CustLedgEntry, ApplyUnapplyParameters);
                    if Confirmation then
                        Message(Text012);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Due Date" > ClosePerDay then
                    CurrReport.Skip();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(RiskPeriod; RiskPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Receipts Risk Period';
                        ToolTip = 'Specifies the bank receipts risk period.';

                        trigger OnValidate()
                        begin
                            DoCalcDate();
                        end;
                    }
                    field(ConfirmPerApplication; Confirmation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Confirm per Application';
                        ToolTip = 'Specifies the confirm per application.';
                    }
                    field(WorkDate; WorkDate())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Today';
                        Editable = false;
                        ToolTip = 'Specifies if the report is for today.';
                    }
                    field(ClosingDateForBankReceipts; ClosePerDay)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closingdate for Bank Receipts';
                        Editable = false;
                        ToolTip = 'Specifies the closing date.';
                    }
                    field(CheckDim; CheckDim)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Do Not Check Dimensions';
                        ToolTip = 'Specifies if you do not want to check the dimensions.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        SalesSetup.Get();
        Clear(NULL);
        RiskPeriod := SalesSetup."Bank Receipts Risk Period";
        if RiskPeriod = NULL then
            Error(Text1033,
              SalesSetup.FieldCaption("Bank Receipts Risk Period"), SalesSetup.TableCaption());
        DoCalcDate();
    end;

    trigger OnPostReport()
    begin
        if not Confirmation then
            Window.Close();
    end;

    trigger OnPreReport()
    begin
        if not Confirmation then
            Window.Open(Text1034);
    end;

    var
        Text1033: Label 'Please specify %1 in %2 before running this report.';
        Text1034: Label 'Posting application...';
        SalesSetup: Record "Sales & Receivables Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustEntrySetApplId: Codeunit "Cust. Entry-SetAppl.ID";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        Window: Dialog;
        RiskPeriod: DateFormula;
        ClosePerDay: Date;
        Confirmation: Boolean;
        NULL: DateFormula;
        CheckDim: Boolean;
        Text1130000: Label 'Do you want to post the application of %1 %2?';
        Text012: Label 'The application was successfully posted.';

    [Scope('OnPrem')]
    procedure DoCalcDate()
    var
        RiskPeriod2: DateFormula;
    begin
        Evaluate(RiskPeriod2, '-' + Format(RiskPeriod));
        ClosePerDay := CalcDate(RiskPeriod2, WorkDate());
    end;
}

