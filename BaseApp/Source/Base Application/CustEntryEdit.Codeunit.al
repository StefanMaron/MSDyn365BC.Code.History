codeunit 103 "Cust. Entry-Edit"
{
    Permissions = TableData "Cust. Ledger Entry" = m,
                  TableData "Detailed Cust. Ledg. Entry" = m;
    TableNo = "Cust. Ledger Entry";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec, CustLedgEntry, DtldCustLedgEntry);

        CustLedgEntry := Rec;
        CustLedgEntry.LockTable();
        CustLedgEntry.Find;
        CustLedgEntry."On Hold" := "On Hold";
        if CustLedgEntry.Open then begin
            CustLedgEntry."Due Date" := "Due Date";
            DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
            DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
            DtldCustLedgEntry.ModifyAll("Initial Entry Due Date", "Due Date");
            CustLedgEntry."Pmt. Discount Date" := "Pmt. Discount Date";
            CustLedgEntry."Applies-to ID" := "Applies-to ID";
            CustLedgEntry.Validate("Payment Method Code", "Payment Method Code");
            CustLedgEntry.Validate("Remaining Pmt. Disc. Possible", "Remaining Pmt. Disc. Possible");
            CustLedgEntry."Pmt. Disc. Tolerance Date" := "Pmt. Disc. Tolerance Date";
            CustLedgEntry.Validate("Max. Payment Tolerance", "Max. Payment Tolerance");
            CustLedgEntry.Validate("Accepted Payment Tolerance", "Accepted Payment Tolerance");
            CustLedgEntry.Validate("Accepted Pmt. Disc. Tolerance", "Accepted Pmt. Disc. Tolerance");
            CustLedgEntry.Validate("Amount to Apply", "Amount to Apply");
            CustLedgEntry.Validate("Applying Entry", "Applying Entry");
            CustLedgEntry.Validate("Applies-to Ext. Doc. No.", "Applies-to Ext. Doc. No.");
            CustLedgEntry.Validate("Message to Recipient", "Message to Recipient");
            CustLedgEntry."Direct Debit Mandate ID" := "Direct Debit Mandate ID";
        end;
        CustLedgEntry.Validate("Exported to Payment File", "Exported to Payment File");
        OnBeforeCustLedgEntryModify(CustLedgEntry, Rec);
        CustLedgEntry.TestField("Entry No.", "Entry No.");
        CustLedgEntry.Modify();
        Rec := CustLedgEntry;
    end;

    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustLedgEntryModify(var CustLedgEntry: Record "Cust. Ledger Entry"; FromCustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var CustLedgerEntryRec: Record "Cust. Ledger Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;
}

