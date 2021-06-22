page 9094 "Vendor Statistics FactBox"
{
    Caption = 'Vendor Statistics';
    PageType = CardPart;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            field("No."; "No.")
            {
                ApplicationArea = All;
                Caption = 'Vendor No.';
                ToolTip = 'Specifies the number of the vendor. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';
                Visible = ShowVendorNo;

                trigger OnDrillDown()
                begin
                    ShowDetails;
                end;
            }
            field("Balance (LCY)"; "Balance (LCY)")
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
            field("Outstanding Orders (LCY)"; "Outstanding Orders (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sum of outstanding orders (in LCY) to this vendor.';
            }
            field("Amt. Rcd. Not Invoiced (LCY)"; "Amt. Rcd. Not Invoiced (LCY)")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Amt. Rcd. Not Invd. (LCY)';
                ToolTip = 'Specifies the total invoice amount (in LCY) for the items you have received but not yet been invoiced for.';
            }
            field("Outstanding Invoices (LCY)"; "Outstanding Invoices (LCY)")
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
            field("Balance Due (LCY)"; CalcOverDueBalance)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Format(StrSubstNo(Text000, Format(WorkDate)));
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
            field(GetInvoicedPrepmtAmountLCY; GetInvoicedPrepmtAmountLCY)
            {
                ApplicationArea = Prepayments;
                Caption = 'Invoiced Prepayment Amount (LCY)';
                ToolTip = 'Specifies your payments to the vendor, based on invoiced prepayments.';
            }
            field("Payments (LCY)"; "Payments (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sum of payments paid to the vendor.';
            }
            field("Refunds (LCY)"; "Refunds (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sum of refunds paid to the vendor.';
            }
            field(LastPaymentDate; GetLastPaymentDate)
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
                    if VendorLedgerEntry.FindLast then
                        VendorLedgerEntries.SetRecord(VendorLedgerEntry);
                    VendorLedgerEntries.SetTableView(VendorLedgerEntry);
                    VendorLedgerEntries.Run;
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        FilterGroup(4);
        SetAutoCalcFields("Balance (LCY)", "Outstanding Orders (LCY)", "Amt. Rcd. Not Invoiced (LCY)", "Outstanding Invoices (LCY)");
        TotalAmountLCY := "Balance (LCY)" + "Outstanding Orders (LCY)" + "Amt. Rcd. Not Invoiced (LCY)" + "Outstanding Invoices (LCY)";
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        TotalAmountLCY := 0;

        exit(Find(Which));
    end;

    trigger OnInit()
    begin
        ShowVendorNo := true;
    end;

    var
        TotalAmountLCY: Decimal;
        Text000: Label 'Overdue Amounts (LCY) as of %1';
        ShowVendorNo: Boolean;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Vendor Card", Rec);
    end;

    procedure SetVendorNoVisibility(Visible: Boolean)
    begin
        ShowVendorNo := Visible;
    end;

    local procedure GetLastPaymentDate(): Date
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        SetFilterLastPaymentDateEntry(VendorLedgerEntry);
        if VendorLedgerEntry.FindLast then;
        exit(VendorLedgerEntry."Posting Date");
    end;

    local procedure SetFilterLastPaymentDateEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date", "Currency Code");
        VendorLedgerEntry.SetRange("Vendor No.", "No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.SetRange(Reversed, false);
    end;
}

