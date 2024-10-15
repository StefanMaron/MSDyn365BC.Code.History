#if not CLEAN19
codeunit 111 "Vend. Entry-SetAppl.ID"
{
    Permissions = TableData "Vendor Ledger Entry" = imd;

    trigger OnRun()
    begin
    end;

    var
        VendEntryApplID: Code[50];

    procedure SetApplId(var VendLedgEntry: Record "Vendor Ledger Entry"; ApplyingVendLedgEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50])
    var
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
    begin
        VendLedgEntry.LockTable();
        if VendLedgEntry.FindSet() then begin
            // Make Applies-to ID
            if VendLedgEntry."Applies-to ID" <> '' then
                VendEntryApplID := ''
            else begin
                VendEntryApplID := AppliesToID;
                if VendEntryApplID = '' then begin
                    VendEntryApplID := UserId;
                    if VendEntryApplID = '' then
                        VendEntryApplID := '***';
                end;
            end;
            OnAfterSetVendEntryApplID(VendLedgEntry, ApplyingVendLedgEntry, VendEntryApplID);
            repeat
                TempVendLedgEntry := VendLedgEntry;
                TempVendLedgEntry.Insert();
            until VendLedgEntry.Next() = 0;
        end;

        if TempVendLedgEntry.FindSet() then
            repeat
                UpdateVendLedgerEntry(TempVendLedgEntry, ApplyingVendLedgEntry, AppliesToID);
            until TempVendLedgEntry.Next() = 0;
    end;

    local procedure UpdateVendLedgerEntry(var TempVendLedgEntry: Record "Vendor Ledger Entry" temporary; ApplyingVendLedgEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        LinkedNotUsedAmt: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateVendLedgerEntry(TempVendLedgEntry, ApplyingVendLedgEntry, AppliesToID, VendEntryApplID, IsHandled);
        if IsHandled then
            exit;

        VendorLedgerEntry.Copy(TempVendLedgEntry);
        VendorLedgerEntry.TestField(Open, true);
        VendorLedgerEntry.TestField("Prepayment Type", ApplyingVendLedgEntry."Prepayment Type");  // NAVCZ
        VendorLedgerEntry."Applies-to ID" := VendEntryApplID;
        if VendorLedgerEntry."Applies-to ID" = '' then begin
            VendorLedgerEntry."Accepted Pmt. Disc. Tolerance" := false;
            VendorLedgerEntry."Accepted Payment Tolerance" := 0;
        end;

        if ((VendorLedgerEntry."Amount to Apply" <> 0) and (VendEntryApplID = '')) or
           (VendEntryApplID = '')
        then
            VendorLedgerEntry."Amount to Apply" := 0
        else
            if VendorLedgerEntry."Amount to Apply" = 0 then begin
                VendorLedgerEntry.CalcFields("Remaining Amount");
                VendorLedgerEntry."Amount to Apply" := VendorLedgerEntry."Remaining Amount";

                // NAVCZ
                if VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::Payment then
                    if VendorLedgerEntry.Prepayment then begin
                        LinkedNotUsedAmt := VendorLedgerEntry.CalcLinkAdvAmount();
                        VendorLedgerEntry."Amount to Apply" := VendorLedgerEntry."Amount to Apply" + LinkedNotUsedAmt;
                    end;

                VendorLedgerEntry.TestAdvLink();
                // NAVCZ
            end;

        if VendorLedgerEntry."Entry No." = ApplyingVendLedgEntry."Entry No." then
            VendorLedgerEntry."Applying Entry" := ApplyingVendLedgEntry."Applying Entry";
        VendorLedgerEntry.Modify();

        OnAfterUpdateVendLedgerEntry(VendorLedgerEntry, TempVendLedgEntry, ApplyingVendLedgEntry, AppliesToID);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVendLedgerEntry(var TempVendLedgEntry: Record "Vendor Ledger Entry" temporary; ApplyingVendLedgEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50]; VendEntryApplID: Code[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetVendEntryApplID(VendLedgEntry: Record "Vendor Ledger Entry"; ApplyingVendLedgEntry: Record "Vendor Ledger Entry"; VendEntryApplID: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVendLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var TempVendLedgEntry: Record "Vendor Ledger Entry" temporary; ApplyingVendLedgEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50])
    begin
    end;
}

#endif