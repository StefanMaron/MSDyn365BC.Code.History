codeunit 113 "Vend. Entry-Edit"
{
    Permissions = TableData "Vendor Ledger Entry" = m,
                  TableData "Detailed Vendor Ledg. Entry" = m;
    TableNo = "Vendor Ledger Entry";

    trigger OnRun()
    begin
        VendLedgEntry := Rec;
        VendLedgEntry.LockTable;
        VendLedgEntry.Find;
        VendLedgEntry."On Hold" := "On Hold";
        if VendLedgEntry.Open then begin
            VendLedgEntry."Due Date" := "Due Date";
            DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
            DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
            DtldVendLedgEntry.ModifyAll("Initial Entry Due Date", "Due Date");
            VendLedgEntry."Pmt. Discount Date" := "Pmt. Discount Date";
            VendLedgEntry."Applies-to ID" := "Applies-to ID";
            VendLedgEntry.Validate("Payment Method Code", "Payment Method Code");
            VendLedgEntry."Vendor VAT Invoice No." := "Vendor VAT Invoice No.";
            VendLedgEntry."Vendor VAT Invoice Date" := "Vendor VAT Invoice Date";
            VendLedgEntry."Vendor VAT Invoice Rcvd Date" := "Vendor VAT Invoice Rcvd Date";
            VendLedgEntry."Vendor Receipts No." := "Vendor Receipts No.";
            VendLedgEntry."Vendor Receipts Date" := "Vendor Receipts Date";
            VendLedgEntry.Description := Description;
            VendLedgEntry.Validate("Remaining Pmt. Disc. Possible", "Remaining Pmt. Disc. Possible");
            VendLedgEntry."Pmt. Disc. Tolerance Date" := "Pmt. Disc. Tolerance Date";
            VendLedgEntry.Validate("Max. Payment Tolerance", "Max. Payment Tolerance");
            VendLedgEntry.Validate("Accepted Payment Tolerance", "Accepted Payment Tolerance");
            VendLedgEntry.Validate("Accepted Pmt. Disc. Tolerance", "Accepted Pmt. Disc. Tolerance");
            VendLedgEntry.Validate("Amount to Apply", "Amount to Apply");
            VendLedgEntry.Validate("Applying Entry", "Applying Entry");
            VendLedgEntry.Validate("Applies-to Ext. Doc. No.", "Applies-to Ext. Doc. No.");
            VendLedgEntry.Validate("Message to Recipient", "Message to Recipient");
        end;
        VendLedgEntry.Validate("VAT Entry Type", "VAT Entry Type");
        VendLedgEntry.Validate("Exported to Payment File", "Exported to Payment File");
        VendLedgEntry.Validate("Creditor No.", "Creditor No.");
        VendLedgEntry.Validate("Payment Reference", "Payment Reference");
        OnBeforeVendLedgEntryModify(VendLedgEntry, Rec);
        VendLedgEntry.TestField("Entry No.", "Entry No.");
        VendLedgEntry.Modify;
        Rec := VendLedgEntry;
    end;

    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";

    [Scope('OnPrem')]
    procedure UpdateVATInvoiceData(var VendLedgEntry: Record "Vendor Ledger Entry"; InvoiceNo: Code[30]; InvoiceDate: Date; InvoiceRcvdDate: Date)
    begin
        with VendLedgEntry do begin
            "Vendor VAT Invoice No." := InvoiceNo;
            "Vendor VAT Invoice Rcvd Date" := 0D;
            Validate("Vendor VAT Invoice Date", InvoiceDate);
            Validate("Vendor VAT Invoice Rcvd Date", InvoiceRcvdDate);
            Modify;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendLedgEntryModify(var VendLedgEntry: Record "Vendor Ledger Entry"; FromVendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;
}

