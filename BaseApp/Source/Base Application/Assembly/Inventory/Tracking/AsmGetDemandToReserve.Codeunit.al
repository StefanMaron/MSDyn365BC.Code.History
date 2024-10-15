namespace Microsoft.Inventory.Tracking;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;

codeunit 929 "Asm. Get Demand To Reserve"
{
    var
        AssemblyTok: Label 'Assembly';
        SourceDocTok: Label '%1 %2 %3', Locked = true;

    // Reservation Worksheet

    [EventSubscriber(ObjectType::Table, Database::"Reservation Wksh. Line", 'OnIsOutdated', '', false, false)]
    local procedure OnIsOutdated(ReservationWkshLine: Record "Reservation Wksh. Line"; var Outdated: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Assembly Line":
                begin
                    if not AssemblyLine.Get(ReservationWkshLine."Record ID") then
                        Outdated := true;
                    if not AssemblyLine.IsInventoriableItem() or
                       (ReservationWkshLine."Item No." <> AssemblyLine."No.") or
                       (ReservationWkshLine."Variant Code" <> AssemblyLine."Variant Code") or
                       (ReservationWkshLine."Location Code" <> AssemblyLine."Location Code") or
                       (ReservationWkshLine."Unit of Measure Code" <> AssemblyLine."Unit of Measure Code")
                    then
                        Outdated := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Wksh. Log Factbox", 'OnShowDocument', '', false, false)]
    local procedure OnShowDocument(var ReservationWorksheetLog: Record "Reservation Worksheet Log"; var IsHandled: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if AssemblyLine.Get(ReservationWorksheetLog."Record ID") then begin
            AssemblyLine.SetRecFilter();
            Page.Run(0, AssemblyLine);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnBeforeCreateSourceDocumentText', '', false, false)]
    local procedure OnBeforeCreateSourceDocumentText(var ReservationWkshLine: Record "Reservation Wksh. Line"; var LineText: Text[100])
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Assembly Line":
                LineText :=
                  StrSubstNo(
                    SourceDocTok, AssemblyTok,
                    Enum::"Assembly Document Type".FromInteger(ReservationWkshLine."Source Subtype"), ReservationWkshLine."Source ID");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLine', '', false, false)]
    local procedure OnGetSourceDocumentLine(var ReservationWkshLine: Record "Reservation Wksh. Line"; var RecordVariant: Variant; var MaxQtyToReserve: Decimal; var MaxQtyToReserveBase: Decimal; var AvailabilityDate: Date)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Assembly Line":
                begin
                    AssemblyLine.Get(ReservationWkshLine."Record ID");
                    RecordVariant := AssemblyLine;
                    AssemblyLine.GetRemainingQty(MaxQtyToReserve, MaxQtyToReserveBase);
                    AvailabilityDate := AssemblyLine."Due Date";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLineQuantities', '', false, false)]
    local procedure OnGetSourceDocumentLineQuantities(var ReservationWkshLine: Record "Reservation Wksh. Line"; var OutstandingQty: Decimal; var ReservedQty: Decimal; var ReservedFromStockQty: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Assembly Line":
                begin
                    AssemblyLine.SetLoadFields("Remaining Quantity");
                    AssemblyLine.Get(ReservationWkshLine."Record ID");
                    AssemblyLine.CalcFields("Reserved Quantity");
                    OutstandingQty := AssemblyLine."Remaining Quantity";
                    ReservedQty := AssemblyLine."Reserved Quantity";
                    ReservedFromStockQty := AssemblyLineReserve.GetReservedQtyFromInventory(AssemblyLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowSourceDocument', '', false, false)]
    local procedure OnShowSourceDocument(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Assembly Line":
                if AssemblyLine.Get(ReservationWkshLine."Record ID") then begin
                    AssemblyLine.SetRecFilter();
                    Page.Run(0, AssemblyLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowReservationEntries', '', false, false)]
    local procedure OnShowReservationEntries(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Assembly Line":
                begin
                    AssemblyLine.Get(ReservationWkshLine."Record ID");
                    AssemblyLine.ShowReservationEntries(false);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowStatistics', '', false, false)]
    local procedure OnShowStatistics(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Assembly Line":
                begin
                    AssemblyHeader.SetLoadFields("Document Type", "No.");
                    AssemblyHeader.Get(ReservationWkshLine."Source Subtype", ReservationWkshLine."Source ID");
                    AssemblyHeader.ShowStatistics();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Get Demand To Reserve", 'OnGetDemand', '', false, false)]
    local procedure OnGetDemand(var FilterItem: Record Item; DemandType: Enum "Reservation Demand Type"; VariantFilterFromBatch: Text; LocationFilterFromBatch: Text; ReservedFromStock: Enum "Reservation From Stock"; var ReservationWkshBatch: Record "Reservation Wksh. Batch"; DateFilter: Text; ItemFilterFromBatch: Text)
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        TempAssemblyLine: Record "Assembly Line" temporary;
        RemainingQty, RemainingQtyBase : Decimal;
        AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase : Decimal;
        LineNo: Integer;
    begin
        GetDemand(
            TempAssemblyLine, FilterItem, ReservationWkshBatch, DemandType,
            DateFilter, VariantFilterFromBatch, LocationFilterFromBatch, ItemFilterFromBatch, ReservedFromStock);
        if TempAssemblyLine.IsEmpty() then
            exit;

        ReservationWkshLine.SetCurrentKey("Journal Batch Name", "Source Type");
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWkshLine.SetRange("Source Type", Database::"Assembly Line");
        if ReservationWkshLine.FindSet(true) then
            repeat
                if ReservationWkshLine.IsOutdated() or TempAssemblyLine.Get(ReservationWkshLine."Record ID") then
                    ReservationWkshLine.Delete(true);
            until ReservationWkshLine.Next() = 0;

        ReservationWkshLine."Journal Batch Name" := ReservationWkshBatch.Name;
        LineNo := ReservationWkshLine.GetLastLineNo();

        TempAssemblyLine.FindSet();
        repeat
            LineNo += 10000;
            ReservationWkshLine.Init();
            ReservationWkshLine."Journal Batch Name" := ReservationWkshBatch.Name;
            ReservationWkshLine."Line No." := LineNo;
            ReservationWkshLine."Source Type" := Database::"Assembly Line";
            ReservationWkshLine."Source Subtype" := TempAssemblyLine."Document Type".AsInteger();
            ReservationWkshLine."Source ID" := TempAssemblyLine."Document No.";
            ReservationWkshLine."Source Ref. No." := TempAssemblyLine."Line No.";
            ReservationWkshLine."Record ID" := TempAssemblyLine.RecordId;
            ReservationWkshLine."Item No." := TempAssemblyLine."No.";
            ReservationWkshLine."Variant Code" := TempAssemblyLine."Variant Code";
            ReservationWkshLine."Location Code" := TempAssemblyLine."Location Code";
            ReservationWkshLine.Description := TempAssemblyLine.Description;
            ReservationWkshLine."Description 2" := TempAssemblyLine."Description 2";

            ReservationWkshLine."Demand Date" := TempAssemblyLine."Due Date";
            ReservationWkshLine."Unit of Measure Code" := TempAssemblyLine."Unit of Measure Code";
            ReservationWkshLine."Qty. per Unit of Measure" := TempAssemblyLine."Qty. per Unit of Measure";

            TempAssemblyLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
            ReservationWkshLine."Remaining Qty. to Reserve" := RemainingQty;
            ReservationWkshLine."Rem. Qty. to Reserve (Base)" := RemainingQtyBase;

            ReservationWorksheetMgt.GetAvailRemainingQtyOnItemLedgerEntry(
              AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase,
              ReservationWkshLine."Item No.", ReservationWkshLine."Variant Code", ReservationWkshLine."Location Code");

            ReservationWkshLine.Validate("Avail. Qty. to Reserve (Base)", AvailableQtyBase);
            ReservationWkshLine.Validate("Qty. in Stock (Base)", InventoryQtyBase);
            ReservationWkshLine.Validate("Qty. Reserv. in Stock (Base)", ReservedQtyBase);
            ReservationWkshLine.Validate("Qty. in Whse. Handling (Base)", WarehouseQtyBase);

            if (ReservationWkshLine."Remaining Qty. to Reserve" > 0) and
               (ReservationWkshLine."Available Qty. to Reserve" > 0)
            then
                ReservationWkshLine.Insert(true);
        until TempAssemblyLine.Next() = 0;
    end;

    local procedure GetDemand(var TempAssemblyLine: Record "Assembly Line" temporary; var FilterItem: Record Item; var ReservationWkshBatch: Record "Reservation Wksh. Batch"; DemandType: Enum "Reservation Demand Type"; DateFilter: Text; VariantFilterFromBatch: Text; LocationFilterFromBatch: Text; ItemFilterFromBatch: Text; ReservedFromStock: Enum "Reservation From Stock")
    var
        Item: Record Item;
        AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line";
#if not CLEAN25
        GetDemandToReserve: Report "Get Demand To Reserve";
#endif
        SkipItem: Boolean;
        IsHandled: Boolean;
    begin
        if not (DemandType in [Enum::"Reservation Demand Type"::All, Enum::"Reservation Demand Type"::"Assembly Components"]) then
            exit;

        AssemblyLine.Reset();
        AssemblyLine.SetCurrentKey("Document Type", "Document No.", "Line No.");
        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.SetFilter("Remaining Quantity (Base)", '<>%1', 0);

        AssemblyLine.SetFilter("No.", FilterItem.GetFilter("No."));
        AssemblyLine.SetFilter("Variant Code", FilterItem.GetFilter("Variant Filter"));
        AssemblyLine.SetFilter("Location Code", FilterItem.GetFilter("Location Filter"));
        AssemblyLine.SetFilter("Due Date", FilterItem.GetFilter("Date Filter"));
        AssemblyLine.SetFilter(Reserve, '<>%1', AssemblyLine.Reserve::Never);

        AssemblyLine.FilterGroup(2);
        if DateFilter <> '' then
            AssemblyLine.SetFilter("Due Date", DateFilter);
        if VariantFilterFromBatch <> '' then
            AssemblyLine.SetFilter("Variant Code", VariantFilterFromBatch);
        if LocationFilterFromBatch <> '' then
            AssemblyLine.SetFilter("Location Code", LocationFilterFromBatch);
        AssemblyLine.FilterGroup(0);

        if AssemblyLine.FindSet() then
            repeat
                if not AssemblyLine.IsInventoriableItem() then
                    SkipItem := true;

                if (not SkipItem) then
                    if not AssemblyLine.CheckIfAssemblyLineMeetsReservedFromStockSetting(AssemblyLine."Remaining Quantity (Base)", ReservedFromStock) then
                        SkipItem := true;

                if (not SkipItem) and (ItemFilterFromBatch <> '') then begin
                    Item.SetView(ReservationWkshBatch.GetItemFilterBlobAsViewFilters());
                    Item.FilterGroup(2);
                    Item.SetRange("No.", AssemblyLine."No.");
                    Item.FilterGroup(0);
                    if Item.IsEmpty() then
                        SkipItem := true;
                end;

                if not SkipItem then begin
                    IsHandled := false;
                    OnGetDemandOnBeforeSetTempAssemblyLine(AssemblyLine, IsHandled);
#if not CLEAN25
                    GetDemandToReserve.RunOnAssemblyLineOnAfterGetRecordOnBeforeSetTempAssemblyLine(AssemblyLine, IsHandled);
#endif
                    if not IsHandled then begin
                        TempAssemblyLine := AssemblyLine;
                        TempAssemblyLine.Insert();
                    end;
                end;
            until AssemblyLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDemandOnBeforeSetTempAssemblyLine(var AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;
}