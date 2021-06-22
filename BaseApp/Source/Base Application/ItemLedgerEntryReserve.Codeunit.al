codeunit 99000841 "Item Ledger Entry-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        FilterReservEntry.SetSourceFilter(DATABASE::"Item Ledger Entry", 0, '', ItemLedgEntry."Entry No.", false);
        FilterReservEntry.SetSourceFilter('', 0);
    end;

    procedure Caption(ItemLedgEntry: Record "Item Ledger Entry") CaptionText: Text
    begin
        CaptionText := ItemLedgEntry.GetSourceCaption;
    end;

    local procedure DrillDownTotalQuantity(SourceRecRef: RecordRef; EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal)
    var
        PurchLine: Record "Purchase Line";
        CreatePick: Codeunit "Create Pick";
        AvailableItemLedgEntries: Page "Available - Item Ledg. Entries";
    begin
        Clear(AvailableItemLedgEntries);
        case ReservEntry."Source Type" of
            DATABASE::"Sales Line",
            DATABASE::"Prod. Order Component",
            DATABASE::"Transfer Line":
                begin
                    AvailableItemLedgEntries.SetSource(SourceRecRef, ReservEntry, ReservEntry."Source Subtype");
                    if Location."Bin Mandatory" or Location."Require Pick" then
                        AvailableItemLedgEntries.SetTotalAvailQty(
                            EntrySummary."Total Available Quantity" +
                            CreatePick.CheckOutBound(
                            ReservEntry."Source Type", ReservEntry."Source Subtype",
                            ReservEntry."Source ID", ReservEntry."Source Ref. No.",
                            ReservEntry."Source Prod. Order Line"))
                    else
                        AvailableItemLedgEntries.SetTotalAvailQty(EntrySummary."Total Available Quantity");
                    AvailableItemLedgEntries.SetMaxQtyToReserve(MaxQtyToReserve);
                    AvailableItemLedgEntries.RunModal;
                end;
            DATABASE::"Purchase Line":
                begin
                    AvailableItemLedgEntries.SetSource(SourceRecRef, ReservEntry, ReservEntry."Source Subtype");
                    SourceRecRef.SetTable(PurchLine);
                    if Location."Bin Mandatory" or Location."Require Pick" and
                        (PurchLine."Document Type" = PurchLine."Document Type"::"Return Order")
                    then
                        AvailableItemLedgEntries.SetTotalAvailQty(
                            EntrySummary."Total Available Quantity" +
                            CreatePick.CheckOutBound(
                            ReservEntry."Source Type", ReservEntry."Source Subtype",
                            ReservEntry."Source ID", ReservEntry."Source Ref. No.",
                            ReservEntry."Source Prod. Order Line"))
                    else
                        AvailableItemLedgEntries.SetTotalAvailQty(EntrySummary."Total Available Quantity");
                    AvailableItemLedgEntries.RunModal;
                end;
            DATABASE::"Requisition Line",
            DATABASE::"Planning Component",
            DATABASE::"Prod. Order Line":
                begin
                    AvailableItemLedgEntries.SetSource(SourceRecRef, ReservEntry, ReservEntry."Source Subtype");
                    AvailableItemLedgEntries.SetTotalAvailQty(EntrySummary."Total Available Quantity");
                    AvailableItemLedgEntries.SetMaxQtyToReserve(MaxQtyToReserve);
                    AvailableItemLedgEntries.RunModal;
                end;
            DATABASE::"Service Line",
            DATABASE::"Job Planning Line",
            DATABASE::"Assembly Header",
            DATABASE::"Assembly Line":
                begin
                    AvailableItemLedgEntries.SetSource(SourceRecRef, ReservEntry, ReservEntry."Source Subtype");
                    AvailableItemLedgEntries.SetTotalAvailQty(EntrySummary."Total Available Quantity");
                    AvailableItemLedgEntries.SetMaxQtyToReserve(MaxQtyToReserve);
                    AvailableItemLedgEntries.RunModal;
                end;
            else
                OnDrillDownTotalQuantityElseCase(SourceRecRef, EntrySummary, ReservEntry, Location, MaxQtyToReserve);
        end;
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = 32); // DATABASE::"Item Ledger Entry"
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if ReservEntrySummary."Entry No." = 1 then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Item Ledger Entry");
            FilterReservEntry.SetRange("Source Subtype", 0);
            FilterReservEntry.SetRange("Expected Receipt Date");
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if FromEntrySummary."Entry No." = 1 then
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Item Ledger Entry") and (FilterReservEntry."Source Subtype" = 0);
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnDrillDownTotalQuantity', '', false, false)]
    local procedure OnDrillDownTotalQuantity(SourceRecRef: RecordRef; EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal)
    begin
        if EntrySummary."Entry No." = 1 then
            DrillDownTotalQuantity(SourceRecRef, EntrySummary, ReservEntry, Location, MaxQtyToReserve);

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceRefNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if MatchThisTable(SourceType) then begin
            ItemLedgEntry.Reset();
            ItemLedgEntry.SetRange("Entry No.", SourceRefNo);
            PAGE.RunModal(0, ItemLedgEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceRefNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if MatchThisTable(SourceType) then begin
            ItemLedgEntry.Reset();
            ItemLedgEntry.SetRange("Entry No.", SourceRefNo);
            PAGE.Run(0, ItemLedgEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ItemLedgerEntry);
            ItemLedgerEntry.SetReservationFilters(ReservEntry);
            CaptionText := ItemLedgerEntry.GetSourceCaption;
        end;
    end;

    local procedure GetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Get(ReservEntry."Source Ref. No.");
        SourceRecRef.GetTable(ItemLedgEntry);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ItemLedgEntry."Remaining Quantity");
            ReturnOption::"Gross Qty. (Base)":
                exit(ItemLedgEntry.Quantity);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownTotalQuantityElseCase(SourceRecRef: RecordRef; EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal)
    begin
    end;
}

