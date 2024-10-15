codeunit 103 "Cust. Entry-Edit"
{
    Permissions = TableData "Cust. Ledger Entry" = m,
                  TableData "Detailed Cust. Ledg. Entry" = m;
    TableNo = "Cust. Ledger Entry";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec, CustLedgEntry, DtldCustLedgEntry);

        CustLedgEntry := Rec;
        CustLedgEntry.LockTable;
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
        CustLedgEntry.Modify;
        Rec := CustLedgEntry;
    end;

    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NotIdenticalErr: Label '%1 and %2 must be identical or %1 must be Blank.', Comment = '%1 and %2 = document nos.';
        BASManagement: Codeunit "BAS Management";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustLedgEntryModify(var CustLedgEntry: Record "Cust. Ledger Entry"; FromCustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    procedure LookupAdjmtAppliesTo(var CurrentSalesHeader: Record "Sales Header")
    var
        ApplyCustEntries: Page "Apply Customer Entries";
    begin
        Clear(ApplyCustEntries);
        with CurrentSalesHeader do begin
            CalcFields(Amount);
            CustLedgEntry.Reset;
            CustLedgEntry.SetCurrentKey("Customer No.", Positive, "Applies-to Doc. Type", "Applies-to Doc. No.", "Due Date");
            CustLedgEntry.SetRange("Customer No.", "Bill-to Customer No.");
            if "Applies-to Doc. No." <> '' then begin
                CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                if CustLedgEntry.FindFirst then;
                CustLedgEntry.SetRange("Document Type");
                CustLedgEntry.SetRange("Document No.");
            end else
                if "Applies-to Doc. Type" <> 0 then begin
                    CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                    if CustLedgEntry.FindFirst then;
                    CustLedgEntry.SetRange("Document Type");
                end else
                    if Amount <> 0 then begin
                        CustLedgEntry.SetRange(Positive, Amount < 0);
                        if CustLedgEntry.FindFirst then;
                        CustLedgEntry.SetRange(Positive);
                        CustLedgEntry.SetFilter("Document Type", '<>%1', CustLedgEntry."Document Type"::Payment);
                    end;

            ApplyCustEntries.SetSales(CurrentSalesHeader, CustLedgEntry, FieldNo("Applies-to Doc. No."));
            ApplyCustEntries.LookupMode(true);
            if ApplyCustEntries.RunModal = ACTION::LookupOK then begin
                ApplyCustEntries.GetCustLedgEntry(CustLedgEntry);
                "Adjustment Applies-to" := CustLedgEntry."Document No.";
                if ("Applies-to Doc. No." <> "Adjustment Applies-to") and
                   ("Applies-to Doc. No." <> '')
                then
                    Error(
                      NotIdenticalErr,
                      FieldName("Applies-to Doc. No."), FieldName("Adjustment Applies-to"));
                "Applies-to Doc. Type" := CustLedgEntry."Document Type";
                "BAS Adjustment" := BASManagement.CheckBASPeriod("Document Date", CustLedgEntry."Document Date");

                if "Applies-to Doc. No." = '' then
                    CustLedgEntry."Amount to Apply" := 0;
                CustLedgEntry.Modify;
            end;
        end;
        Clear(ApplyCustEntries);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var CustLedgerEntryRec: Record "Cust. Ledger Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;
}

