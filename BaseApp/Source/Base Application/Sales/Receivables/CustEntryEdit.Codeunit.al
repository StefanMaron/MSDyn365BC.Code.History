namespace Microsoft.Sales.Receivables;

using Microsoft.Finance.Consolidation;
using Microsoft.Sales.Document;

codeunit 103 "Cust. Entry-Edit"
{
    Permissions = TableData "Cust. Ledger Entry" = m,
                  TableData "Detailed Cust. Ledg. Entry" = m;
    TableNo = "Cust. Ledger Entry";

    trigger OnRun()
    var
        LedgEntryTrackChanges: Codeunit "Ledg. Entry-Track Changes";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, CustLedgEntry, DtldCustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        CustLedgEntry := Rec;
        CustLedgEntry.LockTable();
        CustLedgEntry.Find();

        if LogFieldChanged(CustLedgEntry, Rec) then
            BindSubscription(LedgEntryTrackChanges);

        CustLedgEntry."On Hold" := Rec."On Hold";
        if CustLedgEntry.Open then begin
            CustLedgEntry."Due Date" := Rec."Due Date";
            DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
            DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
            DtldCustLedgEntry.ModifyAll("Initial Entry Due Date", Rec."Due Date");
            CustLedgEntry."Pmt. Discount Date" := Rec."Pmt. Discount Date";
            CustLedgEntry."Applies-to ID" := Rec."Applies-to ID";
            CustLedgEntry.Validate("Payment Method Code", Rec."Payment Method Code");
            CustLedgEntry.Validate("Payment Reference", Rec."Payment Reference");
            CustLedgEntry.Validate("Remaining Pmt. Disc. Possible", Rec."Remaining Pmt. Disc. Possible");
            CustLedgEntry."Pmt. Disc. Tolerance Date" := Rec."Pmt. Disc. Tolerance Date";
            CustLedgEntry.Validate("Max. Payment Tolerance", Rec."Max. Payment Tolerance");
            CustLedgEntry.Validate("Accepted Payment Tolerance", Rec."Accepted Payment Tolerance");
            CustLedgEntry.Validate("Accepted Pmt. Disc. Tolerance", Rec."Accepted Pmt. Disc. Tolerance");
            CustLedgEntry.Validate("Amount to Apply", Rec."Amount to Apply");
            CustLedgEntry.Validate("Applying Entry", Rec."Applying Entry");
            CustLedgEntry.Validate("Applies-to Ext. Doc. No.", Rec."Applies-to Ext. Doc. No.");
            CustLedgEntry.Validate("Message to Recipient", Rec."Message to Recipient");
            CustLedgEntry.Validate("Recipient Bank Account", Rec."Recipient Bank Account");
            CustLedgEntry."Direct Debit Mandate ID" := Rec."Direct Debit Mandate ID";
        end;
        CustLedgEntry.Description := Rec.Description;
        CustLedgEntry.Validate("Exported to Payment File", Rec."Exported to Payment File");
        OnBeforeCustLedgEntryModify(CustLedgEntry, Rec);
        CustLedgEntry.TestField("Entry No.", Rec."Entry No.");
        CustLedgEntry.Modify();
        OnRunOnAfterCustLedgEntryModify(Rec, CustLedgEntry);
        Rec := CustLedgEntry;
    end;

    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NotIdenticalErr: Label '%1 and %2 must be identical or %1 must be Blank.', Comment = '%1 and %2 = document nos.';
        BASManagement: Codeunit "BAS Management";

    procedure SetOnHold(var CustLedgEntry: Record "Cust. Ledger Entry"; NewOnHold: Code[3])
    var
        LedgEntryTrackChanges: Codeunit "Ledg. Entry-Track Changes";
        xOnHold: Code[3];
    begin
        BindSubscription(LedgEntryTrackChanges);

        xOnHold := CustLedgEntry."On Hold";
        CustLedgEntry."On Hold" := NewOnHold;
        if xOnHold <> CustLedgEntry."On Hold" then
            CustLedgEntry.Modify();
    end;

    local procedure LogFieldChanged(CurrCustLedgerEntry: Record "Cust. Ledger Entry"; NewCustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        Changed: Boolean;
    begin
        Changed :=
            (CurrCustLedgerEntry.Description <> NewCustLedgerEntry.Description) or
            (CurrCustLedgerEntry."Due Date" <> NewCustLedgerEntry."Due Date") or
            (CurrCustLedgerEntry."Payment Method Code" <> NewCustLedgerEntry."Payment Method Code") or
            (CurrCustLedgerEntry."Payment Reference" <> NewCustLedgerEntry."Payment Reference") or
            (CurrCustLedgerEntry."Message to Recipient" <> NewCustLedgerEntry."Message to Recipient") or
            (CurrCustLedgerEntry."Recipient Bank Account" <> NewCustLedgerEntry."Recipient Bank Account") or
            (CurrCustLedgerEntry."On Hold" <> NewCustLedgerEntry."On Hold");
        OnAfterLogFieldChanged(CurrCustLedgerEntry, NewCustLedgerEntry, Changed);
        exit(Changed);
    end;

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
            CustLedgEntry.Reset();
            CustLedgEntry.SetCurrentKey("Customer No.", Positive, "Applies-to Doc. Type", "Applies-to Doc. No.", "Due Date");
            CustLedgEntry.SetRange("Customer No.", "Bill-to Customer No.");
            if "Applies-to Doc. No." <> '' then begin
                CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                if CustLedgEntry.FindFirst() then;
                CustLedgEntry.SetRange("Document Type");
                CustLedgEntry.SetRange("Document No.");
            end else
                if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " then begin
                    CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                    if CustLedgEntry.FindFirst() then;
                    CustLedgEntry.SetRange("Document Type");
                end else
                    if Amount <> 0 then begin
                        CustLedgEntry.SetRange(Positive, Amount < 0);
                        if CustLedgEntry.FindFirst() then;
                        CustLedgEntry.SetRange(Positive);
                        CustLedgEntry.SetFilter("Document Type", '<>%1', CustLedgEntry."Document Type"::Payment);
                    end;

            ApplyCustEntries.SetSales(CurrentSalesHeader, CustLedgEntry, FieldNo("Applies-to Doc. No."));
            ApplyCustEntries.LookupMode(true);
            if ApplyCustEntries.RunModal() = ACTION::LookupOK then begin
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
                OnBeforeModifyCustLedgEntry(CurrentSalesHeader, CustLedgEntry);
                CustLedgEntry.Modify();
            end;
        end;
        Clear(ApplyCustEntries);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var CustLedgerEntryRec: Record "Cust. Ledger Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterCustLedgEntryModify(var CustLedgerEntryRec: Record "Cust. Ledger Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLogFieldChanged(CurrCustLedgerEntry: Record "Cust. Ledger Entry"; NewCustLedgerEntry: Record "Cust. Ledger Entry"; var Changed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyCustLedgEntry(var CurrentSalesHeader: Record "Sales Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

