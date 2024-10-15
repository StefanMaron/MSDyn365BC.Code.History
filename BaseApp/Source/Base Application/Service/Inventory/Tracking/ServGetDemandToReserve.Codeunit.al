namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Service.Document;

codeunit 6485 "Serv. Get Demand To Reserve"
{
    var
        ServiceTok: Label 'Service';
        SourceDocTok: Label '%1 %2 %3', Locked = true;

    // Reservation Worksheet

    [EventSubscriber(ObjectType::Table, Database::"Reservation Wksh. Line", 'OnIsOutdated', '', false, false)]
    local procedure OnIsOutdated(ReservationWkshLine: Record "Reservation Wksh. Line"; var Outdated: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Service Line":
                begin
                    if not ServiceLine.Get(ReservationWkshLine."Record ID") then
                        Outdated := true;
                    if not ServiceLine.IsInventoriableItem() or
                       (ReservationWkshLine."Item No." <> ServiceLine."No.") or
                       (ReservationWkshLine."Variant Code" <> ServiceLine."Variant Code") or
                       (ReservationWkshLine."Location Code" <> ServiceLine."Location Code") or
                       (ReservationWkshLine."Unit of Measure Code" <> ServiceLine."Unit of Measure Code")
                    then
                        Outdated := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Wksh. Log Factbox", 'OnShowDocument', '', false, false)]
    local procedure OnShowDocument(var ReservationWorksheetLog: Record "Reservation Worksheet Log"; var IsHandled: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        if ServiceLine.Get(ReservationWorksheetLog."Record ID") then begin
            ServiceLine.SetRecFilter();
            Page.Run(0, ServiceLine);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnBeforeCreateSourceDocumentText', '', false, false)]
    local procedure OnBeforeCreateSourceDocumentText(var ReservationWkshLine: Record "Reservation Wksh. Line"; var LineText: Text[100])
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Service Line":
                LineText :=
                  StrSubstNo(
                    SourceDocTok, ServiceTok,
                    Enum::"Service Document Type".FromInteger(ReservationWkshLine."Source Subtype"), ReservationWkshLine."Source ID");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLine', '', false, false)]
    local procedure OnGetSourceDocumentLine(var ReservationWkshLine: Record "Reservation Wksh. Line"; var RecordVariant: Variant; var MaxQtyToReserve: Decimal; var MaxQtyToReserveBase: Decimal; var AvailabilityDate: Date)
    var
        ServiceLine: Record "Service Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Service Line":
                begin
                    ServiceLine.Get(ReservationWkshLine."Record ID");
                    RecordVariant := ServiceLine;
                    ServiceLine.GetRemainingQty(MaxQtyToReserve, MaxQtyToReserveBase);
                    AvailabilityDate := ServiceLine."Needed by Date";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLineQuantities', '', false, false)]
    local procedure OnGetSourceDocumentLineQuantities(var ReservationWkshLine: Record "Reservation Wksh. Line"; var OutstandingQty: Decimal; var ReservedQty: Decimal; var ReservedFromStockQty: Decimal)
    var
        ServiceLine: Record "Service Line";
        ServiceLineReserve: Codeunit "Service Line-Reserve";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Service Line":
                begin
                    ServiceLine.SetLoadFields("Outstanding Quantity");
                    ServiceLine.Get(ReservationWkshLine."Record ID");
                    ServiceLine.CalcFields("Reserved Quantity");
                    OutstandingQty := ServiceLine."Outstanding Quantity";
                    ReservedQty := ServiceLine."Reserved Quantity";
                    ReservedFromStockQty := ServiceLineReserve.GetReservedQtyFromInventory(ServiceLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowSourceDocument', '', false, false)]
    local procedure OnShowSourceDocument(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ServiceLine: Record "Service Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Service Line":
                if ServiceLine.Get(ReservationWkshLine."Record ID") then begin
                    ServiceLine.SetRecFilter();
                    Page.Run(0, ServiceLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowReservationEntries', '', false, false)]
    local procedure OnShowReservationEntries(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ServiceLine: Record "Service Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Service Line":
                begin
                    ServiceLine.Get(ReservationWkshLine."Record ID");
                    ServiceLine.ShowReservationEntries(false);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowStatistics', '', false, false)]
    local procedure OnShowStatistics(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ServiceHeader: Record "Service Header";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Service Line":
                begin
                    ServiceHeader.SetLoadFields("Document Type", "No.");
                    ServiceHeader.Get(ReservationWkshLine."Source Subtype", ReservationWkshLine."Source ID");
                    ServiceHeader.OpenOrderStatistics();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Get Demand To Reserve", 'OnGetDemand', '', false, false)]
    local procedure OnGetDemand(var FilterItem: Record Item; DemandType: Enum "Reservation Demand Type"; VariantFilterFromBatch: Text; LocationFilterFromBatch: Text; ReservedFromStock: Enum "Reservation From Stock"; var ReservationWkshBatch: Record "Reservation Wksh. Batch"; DateFilter: Text; ItemFilterFromBatch: Text)
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
        TempServiceLine: Record "Service Line" temporary;
        ServiceHeader: Record "Service Header";
        Customer: Record Microsoft.Sales.Customer.Customer;
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        RemainingQty, RemainingQtyBase : Decimal;
        AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase : Decimal;
        LineNo: Integer;
    begin
        GetDemand(
            TempServiceLine, FilterItem, ReservationWkshBatch, DemandType,
            DateFilter, VariantFilterFromBatch, LocationFilterFromBatch, ItemFilterFromBatch, ReservedFromStock);
        if TempServiceLine.IsEmpty() then
            exit;

        ReservationWkshLine.SetCurrentKey("Journal Batch Name", "Source Type");
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWkshLine.SetRange("Source Type", Database::"Service Line");
        if ReservationWkshLine.FindSet(true) then
            repeat
                if ReservationWkshLine.IsOutdated() or TempServiceLine.Get(ReservationWkshLine."Record ID") then
                    ReservationWkshLine.Delete(true);
            until ReservationWkshLine.Next() = 0;

        ReservationWkshLine."Journal Batch Name" := ReservationWkshBatch.Name;
        LineNo := ReservationWkshLine.GetLastLineNo();

        TempServiceLine.FindSet();
        repeat
            LineNo += 10000;
            ReservationWkshLine.Init();
            ReservationWkshLine."Journal Batch Name" := ReservationWkshBatch.Name;
            ReservationWkshLine."Line No." := LineNo;
            ReservationWkshLine."Source Type" := Database::"Service Line";
            ReservationWkshLine."Source Subtype" := TempServiceLine."Document Type".AsInteger();
            ReservationWkshLine."Source ID" := TempServiceLine."Document No.";
            ReservationWkshLine."Source Ref. No." := TempServiceLine."Line No.";
            ReservationWkshLine."Record ID" := TempServiceLine.RecordId;
            ReservationWkshLine."Item No." := TempServiceLine."No.";
            ReservationWkshLine."Variant Code" := TempServiceLine."Variant Code";
            ReservationWkshLine."Location Code" := TempServiceLine."Location Code";
            ReservationWkshLine.Description := TempServiceLine.Description;
            ReservationWkshLine."Description 2" := TempServiceLine."Description 2";

            ServiceHeader.Get(TempServiceLine."Document Type", TempServiceLine."Document No.");
            ReservationWkshLine."Sell-to Customer No." := ServiceHeader."Customer No.";
            ReservationWkshLine."Sell-to Customer Name" := ServiceHeader.Name;
            Customer.SetLoadFields(Priority);
            if Customer.Get(ReservationWkshLine."Sell-to Customer No.") then
                ReservationWkshLine.Priority := Customer.Priority;

            ReservationWkshLine."Demand Date" := TempServiceLine."Needed by Date";
            ReservationWkshLine."Unit of Measure Code" := TempServiceLine."Unit of Measure Code";
            ReservationWkshLine."Qty. per Unit of Measure" := TempServiceLine."Qty. per Unit of Measure";

            TempServiceLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
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
        until TempServiceLine.Next() = 0;

        TempServiceLine.DeleteAll();
    end;

    local procedure GetDemand(var TempServiceLine: Record "Service Line" temporary; var FilterItem: Record Item; var ReservationWkshBatch: Record "Reservation Wksh. Batch"; DemandType: Enum "Reservation Demand Type"; DateFilter: Text; VariantFilterFromBatch: Text; LocationFilterFromBatch: Text; ItemFilterFromBatch: Text; ReservedFromStock: Enum "Reservation From Stock")
    var
        Item: Record Item;
        ServiceLine: Record Microsoft.Service.Document."Service Line";
#if not CLEAN25
        GetDemandToReserve: Report "Get Demand To Reserve";
#endif
        SkipItem: Boolean;
        IsHandled: Boolean;
    begin
        if not (DemandType in [Enum::"Reservation Demand Type"::All, Enum::"Reservation Demand Type"::"Service Orders"]) then
            exit;

        ServiceLine.Reset();
        ServiceLine.SetCurrentKey("Document Type", "Document No.", "Line No.");
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetFilter("Outstanding Qty. (Base)", '<>%1', 0);

        ServiceLine.SetFilter("No.", FilterItem.GetFilter("No."));
        ServiceLine.SetFilter("Variant Code", FilterItem.GetFilter("Variant Filter"));
        ServiceLine.SetFilter("Location Code", FilterItem.GetFilter("Location Filter"));
        ServiceLine.SetFilter("Needed by Date", FilterItem.GetFilter("Date Filter"));
        ServiceLine.SetFilter(Reserve, '<>%1', ServiceLine.Reserve::Never);

        ServiceLine.FilterGroup(2);
        if DateFilter <> '' then
            ServiceLine.SetFilter("Needed by Date", DateFilter);
        if VariantFilterFromBatch <> '' then
            ServiceLine.SetFilter("Variant Code", VariantFilterFromBatch);
        if LocationFilterFromBatch <> '' then
            ServiceLine.SetFilter("Location Code", LocationFilterFromBatch);
        ServiceLine.FilterGroup(0);

        if ServiceLine.FindSet() then
            repeat
                if not ServiceLine.IsInventoriableItem() then
                    SkipItem := true;

                if (not SkipItem) then
                    if not ServiceLine.CheckIfServiceLineMeetsReservedFromStockSetting(Abs(ServiceLine."Outstanding Qty. (Base)"), ReservedFromStock) then
                        SkipItem := true;

                if (not SkipItem) and (ItemFilterFromBatch <> '') then begin
                    Item.SetView(ReservationWkshBatch.GetItemFilterBlobAsViewFilters());
                    Item.FilterGroup(2);
                    Item.SetRange("No.", ServiceLine."No.");
                    Item.FilterGroup(0);
                    if Item.IsEmpty() then
                        SkipItem := true;
                end;

                if not SkipItem then begin
                    IsHandled := false;
                    OnGetDemandOnBeforeSetTempServiceLine(ServiceLine, IsHandled);
#if not CLEAN25
                    GetDemandToReserve.RunOnServiceOrderLineOnAfterGetRecordOnBeforeSetTempServiceLine(ServiceLine, IsHandled);
#endif
                    if not IsHandled then begin
                        TempServiceLine := ServiceLine;
                        TempServiceLine.Insert();
                    end;
                end;
            until ServiceLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDemandOnBeforeSetTempServiceLine(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;
}