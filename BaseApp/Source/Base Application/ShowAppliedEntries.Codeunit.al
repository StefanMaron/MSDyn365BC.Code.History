codeunit 5801 "Show Applied Entries"
{
    Permissions = TableData "Item Ledger Entry" = rim,
                  TableData "Item Application Entry" = r;
    TableNo = "Item Ledger Entry";

    trigger OnRun()
    begin
        TempItemEntry.DeleteAll();
        FindAppliedEntry(Rec);
        PAGE.RunModal(PAGE::"Applied Item Entries", TempItemEntry);
    end;

    var
        TempItemEntry: Record "Item Ledger Entry" temporary;

    local procedure FindAppliedEntry(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        with ItemLedgEntry do
            if Positive then begin
                ItemApplnEntry.Reset();
                ItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Outbound Item Entry No.", "Cost Application");
                ItemApplnEntry.SetRange("Inbound Item Entry No.", "Entry No.");
                ItemApplnEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
                ItemApplnEntry.SetRange("Cost Application", true);
                OnFindAppliedEntryOnAfterSetFilters(ItemApplnEntry, ItemLedgEntry);
                if ItemApplnEntry.Find('-') then
                    repeat
                        InsertTempEntry(ItemApplnEntry."Outbound Item Entry No.", ItemApplnEntry.Quantity);
                    until ItemApplnEntry.Next = 0;
            end else begin
                ItemApplnEntry.Reset();
                ItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application");
                ItemApplnEntry.SetRange("Outbound Item Entry No.", "Entry No.");
                ItemApplnEntry.SetRange("Item Ledger Entry No.", "Entry No.");
                ItemApplnEntry.SetRange("Cost Application", true);
                OnFindAppliedEntryOnAfterSetFilters(ItemApplnEntry, ItemLedgEntry);
                if ItemApplnEntry.Find('-') then
                    repeat
                        InsertTempEntry(ItemApplnEntry."Inbound Item Entry No.", -ItemApplnEntry.Quantity);
                    until ItemApplnEntry.Next = 0;
            end;
    end;

    local procedure InsertTempEntry(EntryNo: Integer; AppliedQty: Decimal)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        IsHandled: Boolean;
    begin
        ItemLedgEntry.Get(EntryNo);

        IsHandled := false;
        OnBeforeInsertTempEntry(ItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if AppliedQty * ItemLedgEntry.Quantity < 0 then
            exit;

        if not TempItemEntry.Get(EntryNo) then begin
            TempItemEntry.Init();
            TempItemEntry := ItemLedgEntry;
            TempItemEntry.Quantity := AppliedQty;
            TempItemEntry.Insert();
        end else begin
            TempItemEntry.Quantity := TempItemEntry.Quantity + AppliedQty;
            TempItemEntry.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempEntry(ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindAppliedEntryOnAfterSetFilters(var ItemApplicationEntry: Record "Item Application Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;
}

