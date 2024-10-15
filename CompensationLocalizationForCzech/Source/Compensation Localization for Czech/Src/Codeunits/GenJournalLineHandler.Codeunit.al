codeunit 31274 "Gen. Journal Line Handler CZC"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterClearCustVendApplnEntry', '', false, false)]
    local procedure ClearOnHoldOnAfterClearCustVendApplnEntry(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if not GenJournalLine."Compensation CZC" then
            exit;

        case AccType of
            AccType::Customer:
                if xGenJournalLine."Applies-to ID" = '' then
                    if xGenJournalLine."Applies-to Doc. No." <> '' then begin
                        CustLedgerEntry.SetCurrentKey("Document No.");
                        CustLedgerEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
                        CustLedgerEntry.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
                        CustLedgerEntry.SetRange("Customer No.", AccNo);
                        CustLedgerEntry.SetRange(Open, true);
                        if CustLedgerEntry.FindFirst() then begin
                            CustLedgerEntry."On Hold" := '';
                            Codeunit.Run(Codeunit::"Cust. Entry-Edit", CustLedgerEntry);
                        end;
                    end;
            AccType::Vendor:
                if xGenJournalLine."Applies-to ID" = '' then
                    if xGenJournalLine."Applies-to Doc. No." <> '' then begin
                        VendorLedgerEntry.SetCurrentKey("Document No.");
                        VendorLedgerEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
                        VendorLedgerEntry.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
                        VendorLedgerEntry.SetRange("Vendor No.", AccNo);
                        VendorLedgerEntry.SetRange(Open, true);
                        if VendorLedgerEntry.FindFirst() then begin
                            VendorLedgerEntry."On Hold" := '';
                            Codeunit.Run(Codeunit::"Vend. Entry-Edit", VendorLedgerEntry);
                        end;
                    end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterOldCustLedgEntryModify', '', false, false)]
    local procedure ClearOnHoldOnAfterOldCustLedgEntryModify(var CustLedgEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Compensation CZC" then
            CustLedgEntry."On Hold" := '';
        CustLedgEntry.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterOldVendLedgEntryModify', '', false, false)]
    local procedure ClearOnHoldOnAfterOldVendLedgEntryModify(var VendLedgEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Compensation CZC" then
            VendLedgEntry."On Hold" := '';
        VendLedgEntry.Modify();
    end;
}
