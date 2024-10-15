#if not CLEAN19
page 9094 "Vendor Statistics FactBox"
{
    Caption = 'Vendor Statistics';
    PageType = CardPart;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
                Caption = 'Vendor No.';
                ToolTip = 'Specifies the number of the vendor. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field("Balance (LCY)"; Rec."Balance (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the total value of your completed purchases from the vendor in the current fiscal year. It is calculated from amounts excluding VAT on all completed purchase invoices and credit memos.';

                trigger OnDrillDown()
                var
                    VendLedgEntry: Record "Vendor Ledger Entry";
                    DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                begin
                    DtldVendLedgEntry.SetRange("Vendor No.", "No.");
                    CopyFilter("Global Dimension 1 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 1");
                    CopyFilter("Global Dimension 2 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 2");
                    CopyFilter("Currency Filter", DtldVendLedgEntry."Currency Code");
                    VendLedgEntry.DrillDownOnEntries(DtldVendLedgEntry);
                end;
            }
            field(BalanceAsCustomer; BalanceAsCustomer)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance (LCY) As Customer';
                Editable = false;
                Enabled = BalanceAsCustomerEnabled;
                ToolTip = 'Specifies the amount that this customer owes you. This is relevant when the customer is also a vendor. The amount is the result of netting their payable and receivable balances.';

                trigger OnDrillDown()
                var
                    DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                    CustLedgerEntry: Record "Cust. Ledger Entry";
                begin
                    if LinkedCustomerNo = '' then
                        exit;
                    DetailedCustLedgEntry.SetRange("Customer No.", LinkedCustomerNo);
                    Rec.CopyFilter("Global Dimension 1 Filter", DetailedCustLedgEntry."Initial Entry Global Dim. 1");
                    Rec.CopyFilter("Global Dimension 2 Filter", DetailedCustLedgEntry."Initial Entry Global Dim. 2");
                    Rec.CopyFilter("Currency Filter", DetailedCustLedgEntry."Currency Code");
                    CustLedgerEntry.DrillDownOnEntries(DetailedCustLedgEntry);
                end;
            }
            field("Outstanding Orders (LCY)"; Rec."Outstanding Orders (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sum of outstanding orders (in LCY) to this vendor.';
            }
            field("Amt. Rcd. Not Invoiced (LCY)"; Rec."Amt. Rcd. Not Invoiced (LCY)")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Amt. Rcd. Not Invd. (LCY)';
                ToolTip = 'Specifies the total invoice amount (in LCY) for the items you have received but not yet been invoiced for.';
            }
            field("Outstanding Invoices (LCY)"; Rec."Outstanding Invoices (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sum of the vendor''s outstanding purchase invoices in LCY.';
            }
            field(TotalAmountLCY; TotalAmountLCY)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Total (LCY)';
                ToolTip = 'Specifies the payment amount that you owe the vendor for completed purchases plus purchases that are still ongoing.';
            }
            field("Balance Due (LCY)"; OverDueBalance)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Format(StrSubstNo(Text000, Format(WorkDate())));
                Caption = 'Balance Due (LCY)';

                trigger OnDrillDown()
                var
                    VendLedgEntry: Record "Vendor Ledger Entry";
                    DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                begin
                    DtldVendLedgEntry.SetFilter("Vendor No.", "No.");
                    CopyFilter("Global Dimension 1 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 1");
                    CopyFilter("Global Dimension 2 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 2");
                    CopyFilter("Currency Filter", DtldVendLedgEntry."Currency Code");
                    VendLedgEntry.DrillDownOnOverdueEntries(DtldVendLedgEntry);
                end;
            }
            field(GetInvoicedPrepmtAmountLCY; InvoicedPrepmtAmountLCY)
            {
                ApplicationArea = Prepayments;
                Caption = 'Invoiced Prepayment Amount (LCY)';
                ToolTip = 'Specifies your payments to the vendor, based on invoiced prepayments.';
            }
            field("Payments (LCY)"; Rec."Payments (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sum of payments paid to the vendor.';
                trigger OnDrillDown()
                var
                    VendorLedgerEntry: Record "Vendor Ledger Entry";
                    VendorLedgerEntries: Page "Vendor Ledger Entries";
                begin
                    Clear(VendorLedgerEntries);
                    SetFilterLastPaymentDateEntry(VendorLedgerEntry);
                    if VendorLedgerEntry.FindLast() then
                        VendorLedgerEntries.SetRecord(VendorLedgerEntry);
                    VendorLedgerEntries.SetTableView(VendorLedgerEntry);
                    VendorLedgerEntries.Run();
                end;
            }
            field("Refunds (LCY)"; Rec."Refunds (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sum of refunds paid to the vendor.';
                trigger OnDrillDown()
                var
                    VendorLedgerEntry: Record "Vendor Ledger Entry";
                    VendorLedgerEntries: Page "Vendor Ledger Entries";
                begin
                    Clear(VendorLedgerEntries);
                    SetFilterRefundEntry(VendorLedgerEntry);
                    if VendorLedgerEntry.FindLast() then
                        VendorLedgerEntries.SetRecord(VendorLedgerEntry);
                    VendorLedgerEntries.SetTableView(VendorLedgerEntry);
                    VendorLedgerEntries.Run();
                end;
            }
            field(LastPaymentDate; LastPaymentDate)
            {
                AccessByPermission = TableData "Vendor Ledger Entry" = R;
                ApplicationArea = Basic, Suite;
                Caption = 'Last Payment Date';
                ToolTip = 'Specifies the posting date of the last payment paid to the vendor.';

                trigger OnDrillDown()
                var
                    VendorLedgerEntry: Record "Vendor Ledger Entry";
                    VendorLedgerEntries: Page "Vendor Ledger Entries";
                begin
                    Clear(VendorLedgerEntries);
                    SetFilterLastPaymentDateEntry(VendorLedgerEntry);
                    if VendorLedgerEntry.FindLast() then
                        VendorLedgerEntries.SetRecord(VendorLedgerEntry);
                    VendorLedgerEntries.SetTableView(VendorLedgerEntry);
                    VendorLedgerEntries.Run();
                end;
            }
            field("Pay-to No. of Open. Adv. L."; Rec."Pay-to No. of Open. Adv. L.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Adv. Letters - Opened (Obsolete)';
                DrillDownPageID = "Purchase Adv. Letters";
                ToolTip = 'Specifies the number of advance letter with status = opened.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                ObsoleteTag = '19.0';
            }
            field("Pay-to No. of P.Pay. Adv. L."; Rec."Pay-to No. of P.Pay. Adv. L.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Adv. Letters - Pend. Pay. (Obsolete)';
                DrillDownPageID = "Purchase Adv. Letters";
                ToolTip = 'Specifies the number of advance letter with status = pending payment.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                ObsoleteTag = '19.0';
            }
            field("Pay-to No. of P.Inv. Adv. L."; Rec."Pay-to No. of P.Inv. Adv. L.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Adv. Letters - Pend. Inv. (Obsolete)';
                DrillDownPageID = "Purchase Adv. Letters";
                ToolTip = 'Specifies the number of advance letter with status = pending invoice.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                ObsoleteTag = '19.0';
            }
            field("Pay-to No. of P.F.Inv. Adv. L."; Rec."Pay-to No. of P.F.Inv. Adv. L.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Adv. Letters - Pend. Fin. Inv. (Obsolete)';
                DrillDownPageID = "Purchase Adv. Letters";
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

    trigger OnOpenPage()
    begin
        SetAutoCalcFields("Balance (LCY)", "Outstanding Orders (LCY)", "Amt. Rcd. Not Invoiced (LCY)", "Outstanding Invoices (LCY)");
    end;

    trigger OnAfterGetRecord()
    var
        VendorNo: Code[20];
        VendorNoFilter: Text;
    begin
        TotalAmountLCY := "Balance (LCY)" + "Outstanding Orders (LCY)" + "Amt. Rcd. Not Invoiced (LCY)" + "Outstanding Invoices (LCY)";

        // Get the vendor number and set the current vendor number
        FilterGroup(4);
        VendorNoFilter := GetFilter("No.");
        if (VendorNoFilter = '') then begin
            FilterGroup(0);
            VendorNoFilter := GetFilter("No.");
        end;

        VendorNo := CopyStr(VendorNoFilter, 1, MaxStrLen(VendorNo));
        if VendorNo <> CurrVendorNo then begin
            CurrVendorNo := VendorNo;
            CalculateFieldValues(CurrVendorNo);
        end;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        TotalAmountLCY := 0;

        exit(Find(Which));
    end;

    var
        Text000: Label 'Overdue Amounts (LCY) as of %1';
        TaskIdCalculateCue: Integer;
        CurrVendorNo: Code[20];
        LinkedCustomerNo: Code[20];
        BalanceAsCustomerEnabled: Boolean;

    protected var
        TotalAmountLCY: Decimal;
        LastPaymentDate: Date;
        InvoicedPrepmtAmountLCY: Decimal;
        OverdueBalance: Decimal;
        BalanceAsCustomer: Decimal;

    procedure CalculateFieldValues(VendorNo: Code[20])
    var
        CalculateVendorStats: Codeunit "Calculate Vendor Stats.";
        Args: Dictionary of [Text, Text];
    begin
        if (TaskIdCalculateCue <> 0) then
            CurrPage.CancelBackgroundTask(TaskIdCalculateCue);

        Clear(LastPaymentDate);
        Clear(OverdueBalance);
        Clear(InvoicedPrepmtAmountLCY);
        Clear(LinkedCustomerNo);
        Clear(BalanceAsCustomer);
        Clear(BalanceAsCustomerEnabled);

        if VendorNo = '' then
            exit;

        Args.Add(CalculateVendorStats.GetVendorNoLabel(), VendorNo);
        CurrPage.EnqueueBackgroundTask(TaskIdCalculateCue, Codeunit::"Calculate Vendor Stats.", Args);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        CalculateVendorStats: Codeunit "Calculate Vendor Stats.";
        DictionaryValue: Text;
    begin
        if (TaskId = TaskIdCalculateCue) then begin
            if Results.Count() = 0 then
                exit;

            if TryGetDictionaryValueFromKey(Results, CalculateVendorStats.GetLastPaymentDateLabel(), DictionaryValue) then
                Evaluate(LastPaymentDate, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CalculateVendorStats.GetOverdueBalanceLabel(), DictionaryValue) then
                Evaluate(OverdueBalance, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CalculateVendorStats.GetInvoicedPrepmtAmountLCYLabel(), DictionaryValue) then
                Evaluate(InvoicedPrepmtAmountLCY, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CalculateVendorStats.GetLinkedCustomerNoLabel(), DictionaryValue) then
                LinkedCustomerNo := CopyStr(DictionaryValue, 1, MaxStrLen(LinkedCustomerNo));
            BalanceAsCustomerEnabled := LinkedCustomerNo <> '';
            if BalanceAsCustomerEnabled then
                if TryGetDictionaryValueFromKey(Results, CalculateVendorStats.GetBalanceAsCustomerLabel(), DictionaryValue) then
                    Evaluate(BalanceAsCustomer, DictionaryValue);
        end;
    end;

    [TryFunction]
    local procedure TryGetDictionaryValueFromKey(var DictionaryToLookIn: Dictionary of [Text, Text]; KeyToSearchFor: Text; var ReturnValue: Text)
    begin
        ReturnValue := DictionaryToLookIn.Get(KeyToSearchFor);
    end;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Vendor Card", Rec);
    end;

    local procedure SetFilterLastPaymentDateEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date", "Currency Code");
        VendorLedgerEntry.SetRange("Vendor No.", "No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.SetRange(Reversed, false);
    end;

    local procedure SetFilterRefundEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date", "Currency Code");
        VendorLedgerEntry.SetRange("Vendor No.", "No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Refund);
        VendorLedgerEntry.SetRange(Reversed, false);
    end;
}

#endif