namespace Microsoft.Inventory.Tracking;

using Microsoft.Sales.Document;
using Microsoft.Sales.Customer;
using Microsoft.Inventory.Item;

codeunit 99000839 "Sales Get Demand To Reserve"
{
    var
        SalesTok: Label 'Sales';
        SourceDocTok: Label '%1 %2 %3', Locked = true;

    // Reservation Worksheet

    [EventSubscriber(ObjectType::Table, Database::"Reservation Wksh. Line", 'OnIsOutdated', '', false, false)]
    local procedure OnIsOutdated(ReservationWkshLine: Record "Reservation Wksh. Line"; var Outdated: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Sales Line":
                begin
                    if not SalesLine.Get(ReservationWkshLine."Record ID") then
                        Outdated := true;
                    if not SalesLine.IsInventoriableItem() or
                       (ReservationWkshLine."Item No." <> SalesLine."No.") or
                       (ReservationWkshLine."Variant Code" <> SalesLine."Variant Code") or
                       (ReservationWkshLine."Location Code" <> SalesLine."Location Code") or
                       (ReservationWkshLine."Unit of Measure Code" <> SalesLine."Unit of Measure Code")
                    then
                        Outdated := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Wksh. Log Factbox", 'OnShowDocument', '', false, false)]
    local procedure OnShowDocument(var ReservationWorksheetLog: Record "Reservation Worksheet Log"; var IsHandled: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        if SalesLine.Get(ReservationWorksheetLog."Record ID") then begin
            SalesLine.SetRecFilter();
            Page.Run(0, SalesLine);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnBeforeCreateSourceDocumentText', '', false, false)]
    local procedure OnBeforeCreateSourceDocumentText(var ReservationWkshLine: Record "Reservation Wksh. Line"; var LineText: Text[100])
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Sales Line":
                LineText :=
                  StrSubstNo(
                    SourceDocTok, SalesTok,
                    Enum::"Sales Document Type".FromInteger(ReservationWkshLine."Source Subtype"), ReservationWkshLine."Source ID");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLine', '', false, false)]
    local procedure OnGetSourceDocumentLine(var ReservationWkshLine: Record "Reservation Wksh. Line"; var RecordVariant: Variant; var MaxQtyToReserve: Decimal; var MaxQtyToReserveBase: Decimal; var AvailabilityDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Sales Line":
                begin
                    SalesLine.Get(ReservationWkshLine."Record ID");
                    RecordVariant := SalesLine;
                    SalesLine.GetRemainingQty(MaxQtyToReserve, MaxQtyToReserveBase);
                    AvailabilityDate := SalesLine."Shipment Date";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLineQuantities', '', false, false)]
    local procedure OnGetSourceDocumentLineQuantities(var ReservationWkshLine: Record "Reservation Wksh. Line"; var OutstandingQty: Decimal; var ReservedQty: Decimal; var ReservedFromStockQty: Decimal)
    var
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Sales Line":
                begin
                    SalesLine.SetLoadFields("Outstanding Quantity");
                    SalesLine.Get(ReservationWkshLine."Record ID");
                    SalesLine.CalcFields("Reserved Quantity");
                    OutstandingQty := SalesLine."Outstanding Quantity";
                    ReservedQty := SalesLine."Reserved Quantity";
                    ReservedFromStockQty := SalesLineReserve.GetReservedQtyFromInventory(SalesLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowSourceDocument', '', false, false)]
    local procedure OnShowSourceDocument(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        SalesLine: Record "Sales Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Sales Line":
                if SalesLine.Get(ReservationWkshLine."Record ID") then begin
                    SalesLine.SetRecFilter();
                    Page.Run(0, SalesLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowReservationEntries', '', false, false)]
    local procedure OnShowReservationEntries(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        SalesLine: Record "Sales Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Sales Line":
                begin
                    SalesLine.Get(ReservationWkshLine."Record ID");
                    SalesLine.ShowReservationEntries(false);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowStatistics', '', false, false)]
    local procedure OnShowStatistics(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Sales Line":
                begin
                    SalesHeader.SetLoadFields("Document Type", "No.");
                    SalesHeader.Get(ReservationWkshLine."Source Subtype", ReservationWkshLine."Source ID");
                    SalesHeader.ShowDocumentStatisticsPage();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Get Demand To Reserve", 'OnGetDemand', '', false, false)]
    local procedure OnGetDemand(var FilterItem: Record Item; DemandType: Enum "Reservation Demand Type"; VariantFilterFromBatch: Text; LocationFilterFromBatch: Text; ReservedFromStock: Enum "Reservation From Stock"; var ReservationWkshBatch: Record "Reservation Wksh. Batch"; DateFilter: Text; ItemFilterFromBatch: Text)
    var
        Customer: Record Customer;
        ReservationWkshLine: Record "Reservation Wksh. Line";
        SalesHeader: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        RemainingQty, RemainingQtyBase : Decimal;
        AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase : Decimal;
        LineNo: Integer;
    begin
        GetDemand(
            TempSalesLine, FilterItem, ReservationWkshBatch, DemandType,
            DateFilter, VariantFilterFromBatch, LocationFilterFromBatch, ItemFilterFromBatch, ReservedFromStock);
        if TempSalesLine.IsEmpty() then
            exit;

        ReservationWkshLine.SetCurrentKey("Journal Batch Name", "Source Type");
        ReservationWkshLine.SetRange("Journal Batch Name", ReservationWkshBatch.Name);
        ReservationWkshLine.SetRange("Source Type", Database::"Sales Line");
        if ReservationWkshLine.FindSet(true) then
            repeat
                if ReservationWkshLine.IsOutdated() or TempSalesLine.Get(ReservationWkshLine."Record ID") then
                    ReservationWkshLine.Delete(true);
            until ReservationWkshLine.Next() = 0;

        ReservationWkshLine."Journal Batch Name" := ReservationWkshBatch.Name;
        LineNo := ReservationWkshLine.GetLastLineNo();

        TempSalesLine.FindSet();
        repeat
            LineNo += 10000;
            ReservationWkshLine.Init();
            ReservationWkshLine."Journal Batch Name" := ReservationWkshBatch.Name;
            ReservationWkshLine."Line No." := LineNo;
            ReservationWkshLine."Source Type" := Database::"Sales Line";
            ReservationWkshLine."Source Subtype" := TempSalesLine."Document Type".AsInteger();
            ReservationWkshLine."Source ID" := TempSalesLine."Document No.";
            ReservationWkshLine."Source Ref. No." := TempSalesLine."Line No.";
            ReservationWkshLine."Record ID" := TempSalesLine.RecordId;
            ReservationWkshLine."Item No." := TempSalesLine."No.";
            ReservationWkshLine."Variant Code" := TempSalesLine."Variant Code";
            ReservationWkshLine."Location Code" := TempSalesLine."Location Code";
            ReservationWkshLine.Description := TempSalesLine.Description;
            ReservationWkshLine."Description 2" := TempSalesLine."Description 2";

            SalesHeader.Get(TempSalesLine."Document Type", TempSalesLine."Document No.");
            ReservationWkshLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
            ReservationWkshLine."Sell-to Customer Name" := SalesHeader."Sell-to Customer Name";
            Customer.SetLoadFields(Priority);
            if Customer.Get(ReservationWkshLine."Sell-to Customer No.") then
                ReservationWkshLine.Priority := Customer.Priority;

            ReservationWkshLine."Demand Date" := TempSalesLine."Shipment Date";
            ReservationWkshLine."Unit of Measure Code" := TempSalesLine."Unit of Measure Code";
            ReservationWkshLine."Qty. per Unit of Measure" := TempSalesLine."Qty. per Unit of Measure";

            TempSalesLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
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
        until TempSalesLine.Next() = 0;
    end;

    local procedure GetDemand(var TempSalesLine: Record "Sales Line" temporary; var FilterItem: Record Item; var ReservationWkshBatch: Record "Reservation Wksh. Batch"; DemandType: Enum "Reservation Demand Type"; DateFilter: Text; VariantFilterFromBatch: Text; LocationFilterFromBatch: Text; ItemFilterFromBatch: Text; ReservedFromStock: Enum "Reservation From Stock")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
#if not CLEAN25
        GetDemandToReserve: Report "Get Demand To Reserve";
#endif
        SkipItem: Boolean;
        IsHandled: Boolean;
    begin
        if not (DemandType in [Enum::"Reservation Demand Type"::All, Enum::"Reservation Demand Type"::"Sales Orders"]) then
            exit;

        SalesLine.Reset();
        SalesLine.SetCurrentKey("Document Type", "Document No.", "Line No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Drop Shipment", false);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("Outstanding Qty. (Base)", '<>%1', 0);

        SalesLine.SetFilter("No.", FilterItem.GetFilter("No."));
        SalesLine.SetFilter("Variant Code", FilterItem.GetFilter("Variant Filter"));
        SalesLine.SetFilter("Location Code", FilterItem.GetFilter("Location Filter"));
        SalesLine.SetFilter("Shipment Date", FilterItem.GetFilter("Date Filter"));
        SalesLine.SetFilter(Reserve, '<>%1', SalesLine.Reserve::Never);

        SalesLine.FilterGroup(2);
        if DateFilter <> '' then
            SalesLine.SetFilter("Shipment Date", DateFilter);
        if VariantFilterFromBatch <> '' then
            SalesLine.SetFilter("Variant Code", VariantFilterFromBatch);
        if LocationFilterFromBatch <> '' then
            SalesLine.SetFilter("Location Code", LocationFilterFromBatch);
        SalesLine.FilterGroup(0);

        if SalesLine.FindSet() then
            repeat
                if not SalesLine.IsInventoriableItem() then
                    SkipItem := true;

                if (not SkipItem) then
                    if not SalesLine.CheckIfSalesLineMeetsReservedFromStockSetting(Abs(SalesLine."Outstanding Qty. (Base)"), ReservedFromStock) then
                        SkipItem := true;

                if (not SkipItem) and (ItemFilterFromBatch <> '') then begin
                    Item.SetView(ReservationWkshBatch.GetItemFilterBlobAsViewFilters());
                    Item.FilterGroup(2);
                    Item.SetRange("No.", SalesLine."No.");
                    Item.FilterGroup(0);
                    if Item.IsEmpty() then
                        SkipItem := true;
                end;

                if not SkipItem then begin
                    IsHandled := false;
                    OnGetDemandOnBeforeSetTempSalesLine(SalesLine, IsHandled);
#if not CLEAN25
                    GetDemandToReserve.RunOnSalesOrderLineOnAfterGetRecordOnBeforeSetTempSalesLine(SalesLine, IsHandled);
#endif
                    if not IsHandled then begin
                        TempSalesLine := SalesLine;
                        TempSalesLine.Insert();
                    end;
                end;
            until SalesLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDemandOnBeforeSetTempSalesLine(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;
}