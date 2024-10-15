codeunit 103 "Cust. Entry-Edit"
{
    Permissions = TableData "Cust. Ledger Entry" = m,
                  TableData "Detailed Cust. Ledg. Entry" = m;
    TableNo = "Cust. Ledger Entry";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, CustLedgEntry, DtldCustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        CustLedgEntry := Rec;
        CustLedgEntry.LockTable();
        CustLedgEntry.Find;
        CustLedgEntry."On Hold" := Rec."On Hold";
        if CustLedgEntry.Open then begin
            CustLedgEntry."Due Date" := Rec."Due Date";
            DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
            DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
            DtldCustLedgEntry.ModifyAll("Initial Entry Due Date", Rec."Due Date");
            DtldCustLedgEntry.ModifyAll("Bank Receipt", Rec."Bank Receipt");
            CustLedgEntry."Pmt. Discount Date" := Rec."Pmt. Discount Date";
            CustLedgEntry."Applies-to ID" := Rec."Applies-to ID";
            CustLedgEntry."Bank Receipt" := "Bank Receipt";
            CustLedgEntry."Payment Method Code" := Rec."Payment Method Code";
            CustLedgEntry."Allow Issue" := Rec."Allow Issue";
            CustLedgEntry.Validate("Remaining Pmt. Disc. Possible", Rec."Remaining Pmt. Disc. Possible");
            CustLedgEntry."Pmt. Disc. Tolerance Date" := Rec."Pmt. Disc. Tolerance Date";
            if CustLedgEntry."Max. Payment Tolerance" <> Rec."Max. Payment Tolerance" then
                CustLedgEntry.Validate("Max. Payment Tolerance", Rec."Max. Payment Tolerance");
            if CustLedgEntry."Accepted Payment Tolerance" <> Rec."Accepted Payment Tolerance" then
                CustLedgEntry.Validate("Accepted Payment Tolerance", Rec."Accepted Payment Tolerance");
            if CustLedgEntry."Accepted Pmt. Disc. Tolerance" <> Rec."Accepted Pmt. Disc. Tolerance" then
                CustLedgEntry.Validate("Accepted Pmt. Disc. Tolerance", Rec."Accepted Pmt. Disc. Tolerance");
            if CustLedgEntry."Amount to Apply" <> Rec."Amount to Apply" then
                CustLedgEntry.Validate("Amount to Apply", Rec."Amount to Apply");
            if CustLedgEntry."Applying Entry" <> Rec."Applying Entry" then
                CustLedgEntry.Validate("Applying Entry", Rec."Applying Entry");
            if CustLedgEntry."Applies-to Ext. Doc. No." <> Rec."Applies-to Ext. Doc. No." then
                CustLedgEntry.Validate("Applies-to Ext. Doc. No.", Rec."Applies-to Ext. Doc. No.");
            if CustLedgEntry."Message to Recipient" <> Rec."Message to Recipient" then
                CustLedgEntry.Validate("Message to Recipient", Rec."Message to Recipient");
            if CustLedgEntry."Recipient Bank Account" <> Rec."Recipient Bank Account" then
                CustLedgEntry.Validate("Recipient Bank Account", Rec."Recipient Bank Account");
            CustLedgEntry."Direct Debit Mandate ID" := Rec."Direct Debit Mandate ID";
        end;
        CustLedgEntry.Validate("Exported to Payment File", Rec."Exported to Payment File");
        CustLedgEntry."Paid Int. Arrears Amount" := Rec."Paid Int. Arrears Amount";
        OnBeforeCustLedgEntryModify(CustLedgEntry, Rec);
        CustLedgEntry.TestField("Entry No.", Rec."Entry No.");
        CustLedgEntry.Modify();
        OnRunOnAfterCustLedgEntryModify(Rec, CustLedgEntry);
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
    local procedure OnBeforeOnRun(var CustLedgerEntryRec: Record "Cust. Ledger Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterCustLedgEntryModify(var CustLedgerEntryRec: Record "Cust. Ledger Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

