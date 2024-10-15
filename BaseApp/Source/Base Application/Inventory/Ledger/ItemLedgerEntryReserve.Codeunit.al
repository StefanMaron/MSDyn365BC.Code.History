namespace Microsoft.Inventory.Ledger;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Warehouse.Activity;

codeunit 99000841 "Item Ledger Entry-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    procedure FilterReservFor(var FilterReservationEntry: Record "Reservation Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        FilterReservFor(FilterReservationEntry, ItemLedgerEntry."Entry No.", false);
    end;

    procedure FilterReservFor(var FilterReservationEntry: Record "Reservation Entry"; ItemLedgerEntryNo: Integer; SourceKey: Boolean)
    begin
        FilterReservationEntry.SetSourceFilter(Database::"Item Ledger Entry", 0, '', ItemLedgerEntryNo, SourceKey);
        FilterReservationEntry.SetSourceFilter('', 0);
    end;

    procedure Caption(ItemLedgerEntry: Record "Item Ledger Entry") CaptionText: Text
    begin
        CaptionText := ItemLedgerEntry.GetSourceCaption();
    end;

    local procedure DrillDownTotalQuantity(SourceRecordRef: RecordRef; EntrySummary: Record "Entry Summary"; ReservationEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        CreatePick: Codeunit "Create Pick";
        AvailableItemLedgEntries: Page "Available - Item Ledg. Entries";
    begin
        Clear(AvailableItemLedgEntries);
        case ReservationEntry."Source Type" of
            Database::"Sales Line",
            Database::"Prod. Order Component",
            Database::"Transfer Line":
                begin
                    AvailableItemLedgEntries.SetSource(SourceRecordRef, ReservationEntry, ReservationEntry.GetTransferDirection());
                    if Location."Bin Mandatory" or Location."Require Pick" then
                        AvailableItemLedgEntries.SetTotalAvailQty(
                            EntrySummary."Total Available Quantity" +
                            CreatePick.CheckOutBound(
                            ReservationEntry."Source Type", ReservationEntry."Source Subtype",
                            ReservationEntry."Source ID", ReservationEntry."Source Ref. No.",
                            ReservationEntry."Source Prod. Order Line"))
                    else
                        AvailableItemLedgEntries.SetTotalAvailQty(EntrySummary."Total Available Quantity");
                    AvailableItemLedgEntries.SetMaxQtyToReserve(MaxQtyToReserve);
                    AvailableItemLedgEntries.RunModal();
                end;
            Database::"Purchase Line":
                begin
                    AvailableItemLedgEntries.SetSource(SourceRecordRef, ReservationEntry, ReservationEntry.GetTransferDirection());
                    SourceRecordRef.SetTable(PurchaseLine);
                    if Location."Bin Mandatory" or Location."Require Pick" and
                        (PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Return Order")
                    then
                        AvailableItemLedgEntries.SetTotalAvailQty(
                            EntrySummary."Total Available Quantity" +
                            CreatePick.CheckOutBound(
                            ReservationEntry."Source Type", ReservationEntry."Source Subtype",
                            ReservationEntry."Source ID", ReservationEntry."Source Ref. No.",
                            ReservationEntry."Source Prod. Order Line"))
                    else
                        AvailableItemLedgEntries.SetTotalAvailQty(EntrySummary."Total Available Quantity");
                    AvailableItemLedgEntries.RunModal();
                end;
            Database::"Requisition Line",
            Database::"Planning Component",
            Database::"Prod. Order Line":
                begin
                    AvailableItemLedgEntries.SetSource(SourceRecordRef, ReservationEntry, ReservationEntry.GetTransferDirection());
                    AvailableItemLedgEntries.SetTotalAvailQty(EntrySummary."Total Available Quantity");
                    AvailableItemLedgEntries.SetMaxQtyToReserve(MaxQtyToReserve);
                    AvailableItemLedgEntries.RunModal();
                end;
            Database::"Service Line",
            Database::"Job Planning Line",
            Database::"Assembly Header",
            Database::"Assembly Line":
                begin
                    AvailableItemLedgEntries.SetSource(SourceRecordRef, ReservationEntry, ReservationEntry.GetTransferDirection());
                    AvailableItemLedgEntries.SetTotalAvailQty(EntrySummary."Total Available Quantity");
                    AvailableItemLedgEntries.SetMaxQtyToReserve(MaxQtyToReserve);
                    AvailableItemLedgEntries.RunModal();
                end;
            else
                OnDrillDownTotalQuantityElseCase(SourceRecordRef, EntrySummary, ReservationEntry, Location, MaxQtyToReserve);
        end;
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"Item Ledger Entry");
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
            CaptionText := ItemLedgerEntry.GetSourceCaption();
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Get(ReservationEntry."Source Ref. No.");
        SourceRecordRef.GetTable(ItemLedgerEntry);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ItemLedgerEntry."Remaining Quantity");
            ReturnOption::"Gross Qty. (Base)":
                exit(ItemLedgerEntry.Quantity);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Entry No.", ReservationEntry."Source Ref. No.");
        PAGE.RunModal(Page::"Item Ledger Entries", ItemLedgerEntry);
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

