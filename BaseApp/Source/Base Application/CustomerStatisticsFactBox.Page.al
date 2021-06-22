page 9082 "Customer Statistics FactBox"
{
    Caption = 'Customer Statistics';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field("No."; "No.")
            {
                ApplicationArea = All;
                Caption = 'Customer No.';
                ToolTip = 'Specifies the number of the customer. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';
                Visible = ShowCustomerNo;

                trigger OnDrillDown()
                begin
                    ShowDetails;
                end;
            }
            field("Balance (LCY)"; "Balance (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the payment amount that the customer owes for completed sales. This value is also known as the customer''s balance.';

                trigger OnDrillDown()
                var
                    DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                    CustLedgEntry: Record "Cust. Ledger Entry";
                begin
                    DtldCustLedgEntry.SetRange("Customer No.", "No.");
                    CopyFilter("Global Dimension 1 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 1");
                    CopyFilter("Global Dimension 2 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 2");
                    CopyFilter("Currency Filter", DtldCustLedgEntry."Currency Code");
                    CustLedgEntry.DrillDownOnEntries(DtldCustLedgEntry);
                end;
            }
            group(Sales)
            {
                Caption = 'Sales';
                field("Outstanding Orders (LCY)"; "Outstanding Orders (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your expected sales income from the customer in LCY based on ongoing sales orders.';
                }
                field("Shipped Not Invoiced (LCY)"; "Shipped Not Invoiced (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Shipped Not Invd. (LCY)';
                    ToolTip = 'Specifies your expected sales income from the customer in LCY based on ongoing sales orders where items have been shipped.';
                }
                field("Outstanding Invoices (LCY)"; "Outstanding Invoices (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your expected sales income from the customer in LCY based on unpaid sales invoices.';
                }
            }
            group(Service)
            {
                Caption = 'Service';
                field("Outstanding Serv. Orders (LCY)"; "Outstanding Serv. Orders (LCY)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies your expected service income from the customer in LCY based on ongoing service orders.';
                }
                field("Serv Shipped Not Invoiced(LCY)"; "Serv Shipped Not Invoiced(LCY)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies your expected service income from the customer in LCY based on service orders that are shipped but not invoiced.';
                }
                field("Outstanding Serv.Invoices(LCY)"; "Outstanding Serv.Invoices(LCY)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies your expected service income from the customer in LCY based on unpaid service invoices.';
                }
            }
            group(Payments)
            {
                Caption = 'Payments';
                field("Payments (LCY)"; "Payments (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of payments received from the customer.';
                }
                field("Refunds (LCY)"; "Refunds (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of refunds received from the customer.';
                }
                field(LastPaymentReceiptDate; LastPaymentDate)
                {
                    AccessByPermission = TableData "Cust. Ledger Entry" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Payment Receipt Date';
                    ToolTip = 'Specifies the posting date of the last payment received from the customer.';

                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        CustomerLedgerEntries: Page "Customer Ledger Entries";
                    begin
                        Clear(CustomerLedgerEntries);
                        SetFilterLastPaymentDateEntry(CustLedgerEntry);
                        if CustLedgerEntry.FindLast then
                            CustomerLedgerEntries.SetRecord(CustLedgerEntry);
                        CustomerLedgerEntries.SetTableView(CustLedgerEntry);
                        CustomerLedgerEntries.Run;
                    end;
                }
            }
            field("Total (LCY)"; TotalAmountLCY)
            {
                AccessByPermission = TableData "Sales Line" = R;
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Total (LCY)';
                Importance = Promoted;
                Style = Strong;
                StyleExpr = TRUE;
                ToolTip = 'Specifies the payment amount that the customer owes for completed sales plus sales that are still ongoing.';
            }
            field("Credit Limit (LCY)"; "Credit Limit (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the maximum amount you allow the customer to exceed the payment balance before warnings are issued.';
            }
            field("Balance Due (LCY)"; OverdueBalance)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Format(StrSubstNo(Text000, Format(WorkDate)));
                Caption = 'Balance Due (LCY)';

                trigger OnDrillDown()
                var
                    DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                    CustLedgEntry: Record "Cust. Ledger Entry";
                begin
                    DtldCustLedgEntry.SetFilter("Customer No.", "No.");
                    CopyFilter("Global Dimension 1 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 1");
                    CopyFilter("Global Dimension 2 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 2");
                    CopyFilter("Currency Filter", DtldCustLedgEntry."Currency Code");
                    CustLedgEntry.DrillDownOnOverdueEntries(DtldCustLedgEntry);
                end;
            }
            field("Sales (LCY)"; SalesLCY)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Total Sales (LCY)';
                ToolTip = 'Specifies your total sales turnover with the customer in the current fiscal year. It is calculated from amounts excluding VAT on all completed and open sales invoices and credit memos.';

                trigger OnDrillDown()
                var
                    CustLedgEntry: Record "Cust. Ledger Entry";
                    AccountingPeriod: Record "Accounting Period";
                begin
                    CustLedgEntry.Reset();
                    CustLedgEntry.SetRange("Customer No.", "No.");
                    CustLedgEntry.SetRange(
                      "Posting Date", AccountingPeriod.GetFiscalYearStartDate(WorkDate), AccountingPeriod.GetFiscalYearEndDate(WorkDate));
                    PAGE.RunModal(PAGE::"Customer Ledger Entries", CustLedgEntry);
                end;
            }
            field(GetInvoicedPrepmtAmountLCY; InvoicedPrepmtAmountLCY)
            {
                AccessByPermission = TableData "Sales Line" = R;
                ApplicationArea = Prepayments;
                Caption = 'Invoiced Prepayment Amount (LCY)';
                ToolTip = 'Specifies your sales income from the customer, based on invoiced prepayments.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        CustomerNo: Code[20];
        CustomerNoFilter: Text;
    begin
        FilterGroup(4);
        // Get the customer number and set the current customer number
        CustomerNoFilter := GetFilter("No.");
        if (CustomerNoFilter = '') then begin
            FilterGroup(0);
            CustomerNoFilter := GetFilter("No.");
        end;

        if (CustomerNoFilter <> '') then begin
            CustomerNo := CopyStr(CustomerNoFilter, 1, MaxStrLen(CustomerNo));
            if CustomerNo <> CurrCustomerNo then begin
                CurrCustomerNo := CustomerNo;
                CalculateFieldValues(CurrCustomerNo);
            end;
        end;
    end;

    trigger OnInit()
    begin
        ShowCustomerNo := true;
    end;

    var
        Text000: Label 'Overdue Amounts (LCY) as of %1';
        ShowCustomerNo: Boolean;
        LastPaymentDate: Date;
        TotalAmountLCY: Decimal;
        OverdueBalance: Decimal;
        SalesLCY: Decimal;
        InvoicedPrepmtAmountLCY: Decimal;
        TaskIdCalculateCue: Integer;
        CurrCustomerNo: Code[20];

    procedure CalculateFieldValues(CustomerNo: Code[20])
    var
        CalculateCustomerStats: Codeunit "Calculate Customer Stats.";
        Args: Dictionary of [Text, Text];
    begin
        if (TaskIdCalculateCue <> 0) then
            CurrPage.CancelBackgroundTask(TaskIdCalculateCue);

        LastPaymentDate := WorkDate();
        TotalAmountLCY := 0.0;
        OverdueBalance := 0.0;
        SalesLCY := 0.0;
        InvoicedPrepmtAmountLCY := 0.0;

        Args.Add(CalculateCustomerStats.GetCustomerNoLabel(), CustomerNo);
        CurrPage.EnqueueBackgroundTask(TaskIdCalculateCue, Codeunit::"Calculate Customer Stats.", Args);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        CalculateCustomerStats: Codeunit "Calculate Customer Stats.";
        DictionaryValue: Text;
    begin
        if (TaskId = TaskIdCalculateCue) then begin
            if TryGetDictionaryValueFromKey(Results, CalculateCustomerStats.GetLastPaymentDateLabel(), DictionaryValue) then
                Evaluate(LastPaymentDate, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CalculateCustomerStats.GetTotalAmountLCYLabel(), DictionaryValue) then
                Evaluate(TotalAmountLCY, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CalculateCustomerStats.GetOverdueBalanceLabel(), DictionaryValue) then
                Evaluate(OverdueBalance, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CalculateCustomerStats.GetSalesLCYLabel(), DictionaryValue) then
                Evaluate(SalesLCY, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CalculateCustomerStats.GetInvoicedPrepmtAmountLCYLabel(), DictionaryValue) then
                Evaluate(InvoicedPrepmtAmountLCY, DictionaryValue);
        end;
    end;

    [TryFunction]
    local procedure TryGetDictionaryValueFromKey(var DictionaryToLookIn: Dictionary of [Text, Text]; KeyToSearchFor: Text; var ReturnValue: Text)
    begin
        ReturnValue := DictionaryToLookIn.Get(KeyToSearchFor);
    end;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Customer Card", Rec);
    end;

    procedure SetCustomerNoVisibility(Visible: Boolean)
    begin
        ShowCustomerNo := Visible;
    end;

    local procedure SetFilterLastPaymentDateEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date", "Currency Code");
        CustLedgerEntry.SetRange("Customer No.", "No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.SetRange(Reversed, false);
    end;
}

