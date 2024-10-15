report 12176 "Suggest Customer Bills"
{
    Caption = 'Suggest Customer Bill';
    ProcessingOnly = true;

    dataset
    {
        dataitem(CustLedgEntry; "Cust. Ledger Entry")
        {
            RequestFilterFields = "Customer No.", "Due Date";

            trigger OnAfterGetRecord()
            var
                Customer: Record Customer;
            begin
                Customer.Get("Customer No.");
                if Customer."Privacy Blocked" then
                    CurrReport.Skip();
                if (Customer.Blocked in [Customer.Blocked::All]) or (Customer."Partner Type" <> PartnerType) then
                    CurrReport.Skip();
                CalcFields("Remaining Amount");

                if UseSameABI then begin
                    if "Recipient Bank Account" <> '' then begin
                        CustBankAcc.Get("Customer No.", "Recipient Bank Account");
                        if BankAcc.ABI = CustBankAcc.ABI then
                            CreateLine;
                    end;
                end else
                    CreateLine;

                if (MaxAmount > 0) and
                   (TotalPayments >= MaxAmount)
                then
                    CurrReport.Break();
            end;

            trigger OnPreDataItem()
            begin
                SetCurrentKey("Currency Code", Open, "Payment Method Code", "Document Type",
                  "Bank Receipts List No.", "Bank Receipt Issued", "Bank Receipt Temp. No.");

                SetRange(Open, true);
                SetRange("Payment Method Code", CustBillHeader."Payment Method Code");
                SetRange("Document Type", "Document Type"::Invoice);
                SetRange("Bank Receipts List No.", '');

                if AllowIssue then begin
                    SetRange("Bank Receipt Issued", true);
                    SetFilter("Bank Receipt Temp. No.", '<>%1', '');
                end else begin
                    SetRange("Bank Receipt Issued", false);
                    SetRange("Bank Receipt Temp. No.", '');
                end;

                CustomerBillLine.LockTable();
                CustomerBillLine.Reset();
                CustomerBillLine.SetRange("Customer Bill No.", CustBillHeader."No.");

                if not CustomerBillLine.FindLast then
                    NextLineNo := 10000
                else
                    NextLineNo := CustomerBillLine."Line No." + 10000;
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
                    field(MaxAmount; MaxAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatType = 1;
                        BlankZero = true;
                        Caption = 'Max Amount';
                        ToolTip = 'Specifies the maximum amount.';
                    }
                    field(UseSameABI; UseSameABI)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Same ABI Code';
                        ToolTip = 'Specifies if you want to use the same ABI code.';
                    }
                    field(PartnerType; PartnerType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Partner Type';
                        ToolTip = 'Specifies the partner type.';
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

    trigger OnPostReport()
    begin
        CustBillHeader."Partner Type" := PartnerType;
        CustBillHeader.Modify();
    end;

    trigger OnPreReport()
    begin
        BankAcc.Get(CustBillHeader."Bank Account No.");
    end;

    var
        CustBillHeader: Record "Customer Bill Header";
        CustomerBillLine: Record "Customer Bill Line";
        CustBankAcc: Record "Customer Bank Account";
        BankAcc: Record "Bank Account";
        NextLineNo: Integer;
        MaxAmount: Decimal;
        TotalPayments: Decimal;
        AllowIssue: Boolean;
        UseSameABI: Boolean;
        PartnerType: Option " ",Company,Person;

    [Scope('OnPrem')]
    procedure InitValues(var CustomerBillHeader: Record "Customer Bill Header"; OkIssue: Boolean)
    begin
        CustBillHeader := CustomerBillHeader;
        AllowIssue := OkIssue;
        PartnerType := CustomerBillHeader."Partner Type";
    end;

    [Scope('OnPrem')]
    procedure CreateLine()
    var
        LookupCustBillLine: Record "Customer Bill Line";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        LookupCustBillLine.SetCurrentKey("Customer Entry No.");
        LookupCustBillLine.SetRange("Customer Entry No.", CustLedgEntry."Entry No.");
        PaymentsCalc;

        if not LookupCustBillLine.FindFirst then
            if (MaxAmount = 0) or
               (TotalPayments + CustLedgEntry."Remaining Amount" <= MaxAmount)
            then begin
                CustomerBillLine.Init();
                CustomerBillLine."Customer Bill No." := CustBillHeader."No.";
                CustomerBillLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 10000;
                CustomerBillLine."Customer No." := CustLedgEntry."Customer No.";
                CustomerBillLine."Temporary Cust. Bill No." := CustLedgEntry."Bank Receipt Temp. No.";
                CustomerBillLine."Document Type" := CustLedgEntry."Document Type";
                CustomerBillLine."Document No." := CustLedgEntry."Document No.";
                CustomerBillLine."Document Occurrence" := CustLedgEntry."Document Occurrence";
                CustomerBillLine."Document Date" := CustLedgEntry."Document Date";
                CustomerBillLine.Amount := CustLedgEntry."Remaining Amount";
                CustomerBillLine."Due Date" := CustLedgEntry."Due Date";
                CustomerBillLine."Cumulative Bank Receipts" := CustLedgEntry."Cumulative Bank Receipts";
                if SEPADirectDebitMandate.Get(CustLedgEntry."Direct Debit Mandate ID") then
                    CustomerBillLine."Customer Bank Acc. No." := SEPADirectDebitMandate."Customer Bank Account Code"
                else
                    CustomerBillLine."Customer Bank Acc. No." := CustLedgEntry."Recipient Bank Account";
                CustomerBillLine."Customer Entry No." := CustLedgEntry."Entry No.";
                CustomerBillLine."Direct Debit Mandate ID" := CustLedgEntry."Direct Debit Mandate ID";
                CustomerBillLine.Insert();
                if MaxAmount > 0 then
                    PaymentsCalc;
            end;
    end;

    local procedure PaymentsCalc()
    begin
        CustBillHeader.CalcFields("Total Amount");
        TotalPayments := CustBillHeader."Total Amount";
    end;
}

