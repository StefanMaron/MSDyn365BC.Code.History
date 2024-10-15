#if not CLEAN19
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
            field(BalanceAsVendor; BalanceAsVendor)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance (LCY) As Vendor';
                Editable = false;
                Enabled = BalanceAsVendorEnabled;
                ToolTip = 'Specifies the amount that you owe this vendor. This is relevant when your vendor is also your customer. The amount is the result of netting their payable and receivable balances.';

                trigger OnDrillDown()
                var
                    DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                    VendLedgEntry: Record "Vendor Ledger Entry";
                begin
                    if LinkedVendorNo = '' then
                        exit;
                    DtldVendLedgEntry.SetRange("Vendor No.", LinkedVendorNo);
                    Rec.CopyFilter("Global Dimension 1 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 1");
                    Rec.CopyFilter("Global Dimension 2 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 2");
                    Rec.CopyFilter("Currency Filter", DtldVendLedgEntry."Currency Code");
                    VendLedgEntry.DrillDownOnEntries(DtldVendLedgEntry);
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
                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        CustomerLedgerEntries: Page "Customer Ledger Entries";
                    begin
                        Clear(CustomerLedgerEntries);
                        SetFilterLastPaymentDateEntry(CustLedgerEntry);
                        if CustLedgerEntry.FindLast() then
                            CustomerLedgerEntries.SetRecord(CustLedgerEntry);
                        CustomerLedgerEntries.SetTableView(CustLedgerEntry);
                        CustomerLedgerEntries.Run();
                    end;
                }
                field("Refunds (LCY)"; "Refunds (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of refunds received from the customer.';
                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        CustomerLedgerEntries: Page "Customer Ledger Entries";
                    begin
                        Clear(CustomerLedgerEntries);
                        SetFilterRefundEntry(CustLedgerEntry);
                        if CustLedgerEntry.FindLast() then
                            CustomerLedgerEntries.SetRecord(CustLedgerEntry);
                        CustomerLedgerEntries.SetTableView(CustLedgerEntry);
                        CustomerLedgerEntries.Run();
                    end;
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
                        if CustLedgerEntry.FindLast() then
                            CustomerLedgerEntries.SetRecord(CustLedgerEntry);
                        CustomerLedgerEntries.SetTableView(CustLedgerEntry);
                        CustomerLedgerEntries.Run();
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
                CaptionClass = Text000;
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
            field("Bill-To No. of Open. Adv. L."; "Bill-To No. of Open. Adv. L.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Adv. Letters - Opened (Obsolete)';
                DrillDownPageID = "Sales Adv. Letters";
                ToolTip = 'Specifies the number of advance letter with status = opened.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                ObsoleteTag = '19.0';
            }
            field("Bill-To No. of P.Pay. Adv. L."; "Bill-To No. of P.Pay. Adv. L.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Adv. Letters - Pend. Pay. (Obsolete)';
                DrillDownPageID = "Sales Adv. Letters";
                ToolTip = 'Specifies the number of advance letter with status = pending payment.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                ObsoleteTag = '19.0';
            }
            field("Bill-To No. of P.Inv. Adv. L."; "Bill-To No. of P.Inv. Adv. L.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Adv. Letters - Pend. Inv. (Obsolete)';
                DrillDownPageID = "Sales Adv. Letters";
                ToolTip = 'Specifies the number of advance letter with status = pending invoice.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                ObsoleteTag = '19.0';
            }
            field("Bill-To No. of P.F.Inv.Adv. L."; "Bill-To No. of P.F.Inv.Adv. L.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Adv. Letters - Pend. Fin. Inv. (Obsolete)';
                DrillDownPageID = "Sales Adv. Letters";
                ToolTip = 'Specifies the number of advance letter with status = pending final invoice.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                ObsoleteTag = '19.0';
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

        CustomerNo := CopyStr(CustomerNoFilter, 1, MaxStrLen(CustomerNo));
        if CustomerNo <> CurrCustomerNo then begin
            CurrCustomerNo := CustomerNo;
            CalculateFieldValues(CurrCustomerNo);
        end;
    end;

    var
        Text000: Label 'Overdue Amounts (LCY)';
        TaskIdCalculateCue: Integer;
        CurrCustomerNo: Code[20];
        LinkedVendorNo: Code[20];
        BalanceAsVendorEnabled: Boolean;

    protected var
        LastPaymentDate: Date;
        TotalAmountLCY: Decimal;
        OverdueBalance: Decimal;
        SalesLCY: Decimal;
        InvoicedPrepmtAmountLCY: Decimal;
        BalanceAsVendor: Decimal;

    procedure CalculateFieldValues(CustomerNo: Code[20])
    var
        CalculateCustomerStats: Codeunit "Calculate Customer Stats.";
        Args: Dictionary of [Text, Text];
    begin
        if (TaskIdCalculateCue <> 0) then
            CurrPage.CancelBackgroundTask(TaskIdCalculateCue);

        Clear(LastPaymentDate);
        Clear(TotalAmountLCY);
        Clear(OverdueBalance);
        Clear(SalesLCY);
        Clear(InvoicedPrepmtAmountLCY);
        Clear(BalanceAsVendor);
        Clear(LinkedVendorNo);
        Clear(BalanceAsVendorEnabled);

        if CustomerNo = '' then
            exit;

        Args.Add(CalculateCustomerStats.GetCustomerNoLabel(), CustomerNo);
        CurrPage.EnqueueBackgroundTask(TaskIdCalculateCue, Codeunit::"Calculate Customer Stats.", Args);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        CalculateCustomerStats: Codeunit "Calculate Customer Stats.";
        DictionaryValue: Text;
    begin
        if (TaskId = TaskIdCalculateCue) then begin
            if Results.Count() = 0 then
                exit;

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

            if TryGetDictionaryValueFromKey(Results, CalculateCustomerStats.GetLinkedVendorNoLabel(), DictionaryValue) then
                LinkedVendorNo := CopyStr(DictionaryValue, 1, MaxStrLen(LinkedVendorNo));
            BalanceAsVendorEnabled := LinkedVendorNo <> '';
            if BalanceAsVendorEnabled then
                if TryGetDictionaryValueFromKey(Results, CalculateCustomerStats.GetBalanceAsVendorLabel(), DictionaryValue) then
                    Evaluate(BalanceAsVendor, DictionaryValue);
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

    local procedure SetFilterLastPaymentDateEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date", "Currency Code");
        CustLedgerEntry.SetRange("Customer No.", "No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.SetRange(Reversed, false);
    end;

    local procedure SetFilterRefundEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date", "Currency Code");
        CustLedgerEntry.SetRange("Customer No.", "No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Refund);
        CustLedgerEntry.SetRange(Reversed, false);
    end;
}

#endif