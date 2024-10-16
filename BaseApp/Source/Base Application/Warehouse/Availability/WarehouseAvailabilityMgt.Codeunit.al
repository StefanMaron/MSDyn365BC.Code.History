namespace Microsoft.Warehouse.Availability;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Reflection;

codeunit 7314 "Warehouse Availability Mgt."
{

    trigger OnRun()
    begin
    end;

    procedure CalcLineReservedQtyOnInvt(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; HandleResPickAndShipQty: Boolean; var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    var
        DummyItemTrackingSetup: Record "Item Tracking Setup";
    begin
        exit(
            CalcLineReservedQtyOnInvt(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, HandleResPickAndShipQty,
            DummyItemTrackingSetup, WarehouseActivityLine));
    end;

    procedure CalcLineReservedQtyOnInvt(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; HandleResPickAndShipQty: Boolean; WhseItemTrackingSetup: Record "Item Tracking Setup"; var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ReservQtyonInvt: Decimal;
        PickQty: Decimal;
    begin
        // Returns the reserved quantity against ILE for the demand line
        case SourceType of
            Database::"Prod. Order Component":
                begin
                    ReservEntry.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceSubLineNo, true);
                    ReservEntry.SetSourceFilter('', SourceLineNo);
                end;
            Database::Job:
                begin
                    ReservEntry.SetSourceFilter(
                      Database::"Job Planning Line", "Job Planning Line Status"::Order.AsInteger(), SourceNo, SourceLineNo, true);
                    ReservEntry.SetSourceFilter('', 0);
                end;
            else
                ReservEntry.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, true);
        end;
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        if ReservEntry.Find('-') then
            repeat
                ReservEntry2.SetRange("Entry No.", ReservEntry."Entry No.");
                ReservEntry2.SetRange(Positive, true);
                ReservEntry2.SetRange("Source Type", Database::"Item Ledger Entry");
                ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
                ReservEntry2.SetTrackingFilterFromItemTrackingSetupIfNotBlank(WhseItemTrackingSetup);
                if ReservEntry2.Find('-') then
                    repeat
                        ReservQtyonInvt += ReservEntry2."Quantity (Base)";
                    until ReservEntry2.Next() = 0;
            until ReservEntry.Next() = 0;

        if HandleResPickAndShipQty then begin
            PickQty := CalcRegisteredAndOutstandingPickQty(ReservEntry, WarehouseActivityLine);
            if ReservQtyonInvt > PickQty then
                ReservQtyonInvt -= PickQty
            else
                ReservQtyonInvt := 0;
        end;

        OnAfterCalcLineReservedQtyOnInvt(ReservEntry, ReservQtyonInvt);
        exit(ReservQtyonInvt);
    end;

    procedure CalcReservQtyOnPicksShips(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        exit(CalcReservQtyOnPicksShipsWithItemTracking(
            WarehouseActivityLine, TempTrackingSpecification, LocationCode, ItemNo, VariantCode));
    end;

    procedure CalcReservQtyOnPicksShipsWithItemTracking(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TrackingSpecification: Record "Tracking Specification"; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]) Result: Decimal
    var
        TempReservEntryBuffer: Record "Reservation Entry Buffer" temporary;
        CalcRsvQtyOnPicksShipsWithIT: Query CalcRsvQtyOnPicksShipsWithIT;
        ResPickShipQty: Decimal;
        QtyPicked: Decimal;
        QtyToPick: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcReservQtyOnPicksShipsWithItemTracking(LocationCode, ItemNo, VariantCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        CalcRsvQtyOnPicksShipsWithIT.SetRange(Item_No_, ItemNo);
        CalcRsvQtyOnPicksShipsWithIT.SetRange(Variant_Code, VariantCode);
        CalcRsvQtyOnPicksShipsWithIT.SetRange(Location_Code, LocationCode);
        CalcRsvQtyOnPicksShipsWithIT.SetRange(Reservation_Status, "Reservation Status"::Reservation);
        CalcRsvQtyOnPicksShipsWithIT.SetRange(Positive, false);

        CalcRsvQtyOnPicksShipsWithIT.SetRange(Positive_2, true);
        CalcRsvQtyOnPicksShipsWithIT.SetRange(Source_Type_2, Database::"Item Ledger Entry");

        if TrackingSpecification."Serial No." <> '' then
            CalcRsvQtyOnPicksShipsWithIT.SetRange(Serial_No_, TrackingSpecification."Serial No.");
        if TrackingSpecification."Lot No." <> '' then
            CalcRsvQtyOnPicksShipsWithIT.SetRange(Lot_No_, TrackingSpecification."Lot No.");
        if TrackingSpecification."Package No." <> '' then
            CalcRsvQtyOnPicksShipsWithIT.SetRange(Package_No_, TrackingSpecification."Package No.");

        CalcRsvQtyOnPicksShipsWithIT.Open();

        while CalcRsvQtyOnPicksShipsWithIT.Read() do begin
            TempReservEntryBuffer."Quantity (Base)" := CalcRsvQtyOnPicksShipsWithIT.Quantity__Base_;
            TempReservEntryBuffer."Source Batch Name" := CalcRsvQtyOnPicksShipsWithIT.Source_Batch_Name;
            TempReservEntryBuffer."Source Type" := CalcRsvQtyOnPicksShipsWithIT.Source_Type;
            TempReservEntryBuffer."Source Subtype" := CalcRsvQtyOnPicksShipsWithIT.Source_Subtype;
            TempReservEntryBuffer."Source ID" := CalcRsvQtyOnPicksShipsWithIT.Source_ID;
            TempReservEntryBuffer."Source Prod. Order Line" := CalcRsvQtyOnPicksShipsWithIT.Source_Prod__Order_Line;
            TempReservEntryBuffer."Source Ref. No." := CalcRsvQtyOnPicksShipsWithIT.Source_Ref__No_;

            if TempReservEntryBuffer.Find() then begin
                TempReservEntryBuffer."Quantity (Base)" += CalcRsvQtyOnPicksShipsWithIT.Quantity__Base_;
                TempReservEntryBuffer.Modify();
            end else
                TempReservEntryBuffer.Insert();
        end;

        if TempReservEntryBuffer.FindSet() then
            repeat
                QtyPicked :=
                  CalcQtyRegisteredPick(
                    LocationCode, TempReservEntryBuffer."Source Type", TempReservEntryBuffer."Source Subtype", TempReservEntryBuffer."Source ID", TempReservEntryBuffer."Source Ref. No.", TempReservEntryBuffer."Source Prod. Order Line");
                QtyToPick :=
                  CalcQtyOutstandingPick(
                    TempReservEntryBuffer."Source Type", TempReservEntryBuffer."Source Subtype", TempReservEntryBuffer."Source ID", TempReservEntryBuffer."Source Ref. No.", TempReservEntryBuffer."Source Prod. Order Line", WarehouseActivityLine);
                if -TempReservEntryBuffer."Quantity (Base)" > QtyPicked + QtyToPick then
                    ResPickShipQty += (QtyPicked + QtyToPick)
                else
                    ResPickShipQty += -TempReservEntryBuffer."Quantity (Base)";
            until TempReservEntryBuffer.Next() = 0;
        exit(ResPickShipQty);
    end;

    procedure CalcLineReservQtyOnPicksShips(SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer; SourceProdOrderLine: Integer; ReservedQtyBase: Decimal; var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    var
        PickedNotYetShippedQty: Decimal;
        OutstandingQtyOnPickLines: Decimal;
    begin
        // Returns the reserved part of the sum of outstanding quantity on pick lines and
        // quantity on shipment lines picked but not yet shipped for a given demand line
        if SourceType = Database::"Prod. Order Component" then
            PickedNotYetShippedQty := CalcQtyPickedOnProdOrderComponentLine(SourceSubType, SourceID, SourceProdOrderLine, SourceRefNo)
        else
            PickedNotYetShippedQty := CalcQtyPickedOnWhseShipmentLine(SourceType, SourceSubType, SourceID, SourceRefNo);

        OutstandingQtyOnPickLines :=
          CalcQtyOutstandingPick(SourceType, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLine, WarehouseActivityLine);

        if -ReservedQtyBase > (PickedNotYetShippedQty + OutstandingQtyOnPickLines) then
            exit(PickedNotYetShippedQty + OutstandingQtyOnPickLines);

        exit(-ReservedQtyBase);
    end;

    procedure CalcInvtAvailQty(Item: Record Item; Location: Record Location; VariantCode: Code[10]; var WarehouseActivityLine: Record "Warehouse Activity Line") Result: Decimal
    var
        QtyReceivedNotAvail: Decimal;
        QtyAssgndtoPick: Decimal;
        QtyShipped: Decimal;
        QtyReservedOnPickShip: Decimal;
        QtyOnDedicatedBins: Decimal;
        ReservedQtyOnInventory: Decimal;
        SubTotal: Decimal;
        QtyPicked: Decimal;
        IsHandled: Boolean;
    begin
        // Returns the available quantity to pick for pick/ship/receipt/put-away
        // locations without directed put-away and pick
        IsHandled := false;
        OnBeforeCalcInvtAvailQty(Item, Location, VariantCode, WarehouseActivityLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Item.SetRange("Location Filter", Location.Code);
        Item.SetRange("Variant Filter", VariantCode);
        if Location."Require Shipment" then
            Item.CalcFields(Inventory, "Reserved Qty. on Inventory", "Qty. Picked")
        else
            Item.CalcFields(Inventory, "Reserved Qty. on Inventory");

        if Location."Require Receive" and Location."Require Put-away" then
            QtyReceivedNotAvail := CalcQtyRcvdNotAvailable(Location.Code, Item."No.", VariantCode);

        QtyAssgndtoPick := CalcQtyAssgndtoPick(Location, Item."No.", VariantCode, '');

        if Location.RequireShipment(Location.Code) then
            QtyShipped := CalcQtyShipped(Location, Item."No.", VariantCode);
        QtyReservedOnPickShip := CalcReservQtyOnPicksShips(Location.Code, Item."No.", VariantCode, WarehouseActivityLine);
        // exclude quantity on dedicated bins
        QtyOnDedicatedBins := CalcQtyOnDedicatedBins(Location.Code, Item."No.", VariantCode);
        if (QtyOnDedicatedBins > 0) and Location."Require Receive" and Location."Require Put-away" then
            QtyReceivedNotAvail -= CalcQtyAssignedToPutAway(Location.Code, Item."No.", VariantCode, true);

        ReservedQtyOnInventory := Item."Reserved Qty. on Inventory";
        OnAfterCalcReservedQtyOnInventory(Item, ReservedQtyOnInventory, Location);

        QtyPicked := Item."Qty. Picked";
        OnAfterCalcQtyPicked(Item, QtyPicked, Location);
        // The reserved qty might exceed the qty available in warehouse and thereby
        // having reserved from the qty not yet put-away
        if (Item.Inventory - QtyReceivedNotAvail - QtyAssgndtoPick - QtyPicked + QtyShipped - QtyOnDedicatedBins) <
           (Abs(ReservedQtyOnInventory) - QtyReservedOnPickShip)
        then
            exit(0);

        SubTotal :=
          Item.Inventory - QtyReceivedNotAvail - QtyAssgndtoPick -
          Abs(ReservedQtyOnInventory) - QtyPicked + QtyShipped;

        exit(SubTotal);
    end;

    local procedure CalcQtyRcvdNotAvailable(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        TempBin: Record Bin temporary;
        WarehouseEntry: Record "Warehouse Entry";
        DummyItemTrackingSetup: Record "Item Tracking Setup";
        QtyRcvdNotAvailable: Decimal;
        QtyAvailToPutAway: Decimal;
    begin
        // Returns the quantity received but not yet put-away for a given item
        // for pick/ship/receipt/put-away locations without directed put-away and pick
        // with consideration of actually available quantity to put-away in receive bins
        PostedWhseRcptLine.SetCurrentKey("Item No.", "Location Code", "Variant Code");
        PostedWhseRcptLine.SetRange("Item No.", ItemNo);
        PostedWhseRcptLine.SetRange("Location Code", LocationCode);
        PostedWhseRcptLine.SetRange("Variant Code", VariantCode);
        PostedWhseRcptLine.CalcSums("Qty. (Base)", "Qty. Put Away (Base)");
        QtyRcvdNotAvailable := PostedWhseRcptLine."Qty. (Base)" - PostedWhseRcptLine."Qty. Put Away (Base)";

        WarehouseEntry.SetRange("Location Code", LocationCode);
        if (QtyRcvdNotAvailable > 0) and not WarehouseEntry.IsEmpty() then begin
            PostedWhseRcptLine.FindSet();
            repeat
                TempBin."Location Code" := PostedWhseRcptLine."Location Code";
                TempBin.Code := PostedWhseRcptLine."Bin Code";
                if TempBin.Insert() then;
            until PostedWhseRcptLine.Next() = 0;

            if TempBin.FindSet() then
                repeat
                    QtyAvailToPutAway +=
                        CalcQtyOnBin(TempBin."Location Code", TempBin.Code, PostedWhseRcptLine."Item No.", PostedWhseRcptLine."Variant Code", DummyItemTrackingSetup);
                until TempBin.Next() = 0;

            if QtyAvailToPutAway < QtyRcvdNotAvailable then
                QtyRcvdNotAvailable := QtyAvailToPutAway;
        end;

        OnAfterCalcQtyRcvdNotAvailable(PostedWhseRcptLine, LocationCode, ItemNo, VariantCode, QtyRcvdNotAvailable);
        exit(QtyRcvdNotAvailable);
    end;

    procedure CalcQtyAssgndtoPick(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; BinTypeFilter: Text[250]): Decimal
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        // Returns the outstanding quantity on pick lines for a given item
        // for a pick location without directed put-away and pick
        WhseActivLine.SetCurrentKey(
            "Item No.", "Location Code", "Activity Type", "Bin Type Code",
            "Unit of Measure Code", "Variant Code", "Breakbulk No.");
        WhseActivLine.SetRange("Item No.", ItemNo);
        WhseActivLine.SetRange("Location Code", Location.Code);
        WhseActivLine.SetRange("Variant Code", VariantCode);
        WhseActivLine.SetRange("Bin Type Code", BinTypeFilter);
        if Location."Bin Mandatory" then
            WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Take)
        else begin
            WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::" ");
            WhseActivLine.SetRange("Breakbulk No.", 0);
        end;
        if Location."Require Shipment" then
            WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick)
        else begin
            WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Invt. Pick");
            WhseActivLine.SetRange("Assemble to Order", false);
        end;
        OnCalcQtyAssgndtoPickOnAfterSetFilters(WhseActivLine, Location, ItemNo, VariantCode, BinTypeFilter);
        WhseActivLine.CalcSums("Qty. Outstanding (Base)");
        exit(WhseActivLine."Qty. Outstanding (Base)");
    end;

    procedure CalcQtyAssignedToMove(WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line"): Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetCurrentKey(
            "Item No.", "Location Code", "Activity Type", "Bin Type Code", "Unit of Measure Code", "Variant Code", "Breakbulk No.",
            "Action Type");
        WarehouseActivityLine.SetRange("Item No.", WhseWorksheetLine."Item No.");
        WarehouseActivityLine.SetRange("Location Code", WhseWorksheetLine."Location Code");
        WarehouseActivityLine.SetRange("Activity Type", "Warehouse Activity Type"::Movement);
        WarehouseActivityLine.SetRange("Variant Code", WhseWorksheetLine."Variant Code");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Bin Code", WhseWorksheetLine."From Bin Code");
        WarehouseActivityLine.SetTrackingFilterFromWhseItemTrackingLineIfNotBlank(WhseItemTrackingLine);
        WarehouseActivityLine.CalcSums("Qty. Outstanding (Base)");
        exit(WarehouseActivityLine."Qty. Outstanding (Base)");
    end;

    local procedure CalcQtyAssignedToPutAway(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; DedicatedOnly: Boolean): Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetCurrentKey("Item No.", "Location Code");
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Variant Code", VariantCode);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type"::Receipt);
        WarehouseActivityLine.SetFilter(
          "Action Type", '%1|%2', WarehouseActivityLine."Action Type"::Take, WarehouseActivityLine."Action Type"::" ");
        if DedicatedOnly then
            WarehouseActivityLine.SetRange(Dedicated, true);
        WarehouseActivityLine.CalcSums("Qty. Outstanding (Base)");
        exit(WarehouseActivityLine."Qty. Outstanding (Base)");
    end;

    procedure CalcQtyAssgndOnWksh(DefWhseWkshLine: Record "Whse. Worksheet Line"; RespectUOMCode: Boolean; ExcludeLine: Boolean): Decimal
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        WhseWkshLine.SetCurrentKey(
              "Item No.", "Location Code", "Worksheet Template Name", "Variant Code", "Unit of Measure Code");
        WhseWkshLine.SetRange("Item No.", DefWhseWkshLine."Item No.");
        WhseWkshLine.SetRange("Location Code", DefWhseWkshLine."Location Code");
        WhseWkshLine.SetRange("Worksheet Template Name", DefWhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange("Variant Code", DefWhseWkshLine."Variant Code");
        if RespectUOMCode then
            WhseWkshLine.SetRange("Unit of Measure Code", DefWhseWkshLine."Unit of Measure Code");
        WhseWkshLine.CalcSums("Qty. to Handle (Base)");
        if ExcludeLine and DefWhseWkshLine.Find() then
            WhseWkshLine."Qty. to Handle (Base)" := WhseWkshLine."Qty. to Handle (Base)" - DefWhseWkshLine."Qty. to Handle (Base)";
        exit(WhseWkshLine."Qty. to Handle (Base)");
    end;

    local procedure CalcQtyShipped(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.SetCurrentKey("Item No.", "Location Code", "Variant Code", "Due Date");
        WhseShptLine.SetRange("Item No.", ItemNo);
        WhseShptLine.SetRange("Location Code", Location.Code);
        WhseShptLine.SetRange("Variant Code", VariantCode);
        WhseShptLine.CalcSums("Qty. Shipped (Base)");
        exit(WhseShptLine."Qty. Shipped (Base)");
    end;

    procedure CalcQtyOnDedicatedBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        DummyItemTrackingSetup: Record "Item Tracking Setup";
    begin
        exit(CalcQtyOnDedicatedBins(LocationCode, ItemNo, VariantCode, DummyItemTrackingSetup));
    end;

    procedure CalcQtyOnDedicatedBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
        QtyOnDedicatedBin: Decimal;
    begin
        WhseEntry.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code",
          "Unit of Measure Code", "Lot No.", "Serial No.", "Entry Type");
        WhseEntry.SetRange("Item No.", ItemNo);
        WhseEntry.SetRange("Location Code", LocationCode);
        WhseEntry.SetRange("Variant Code", VariantCode);
        WhseEntry.SetRange(Dedicated, true);
        WhseEntry.SetTrackingFilterFromItemTrackingSetupIfNotBlank(WhseItemTrackingSetup);
        WhseEntry.CalcSums(WhseEntry."Qty. (Base)");
        QtyOnDedicatedBin := WhseEntry."Qty. (Base)";

        OnAfterCalcQtyOnDedicatedBins(LocationCode, ItemNo, VariantCode, WhseEntry, WhseItemTrackingSetup, QtyOnDedicatedBin);
        exit(QtyOnDedicatedBin);
    end;

    procedure CalcQtyOnBin(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        if BinCode = '' then
            exit(0);

        WhseEntry.SetCurrentKey(
            "Item No.", "Bin Code", "Location Code", "Variant Code",
            "Unit of Measure Code", "Lot No.", "Serial No.", "Entry Type");
        WhseEntry.SetRange("Item No.", ItemNo);
        WhseEntry.SetRange("Bin Code", BinCode);
        WhseEntry.SetRange("Location Code", LocationCode);
        WhseEntry.SetRange("Variant Code", VariantCode);
        WhseEntry.SetTrackingFilterFromItemTrackingSetupIfNotBlank(WhseItemTrackingSetup);
        WhseEntry.CalcSums("Qty. (Base)");
        exit(WhseEntry."Qty. (Base)");
    end;

    procedure CalcQtyOnBlockedITOrOnBlockedOutbndBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup") QtyBlocked: Decimal
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetCurrentKey("Location Code", "Item No.", "Variant Code");
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        BinContent.SetTrackingFilterFromItemTrackingSetupifNotBlankIfRequired(WhseItemTrackingSetup);
        if BinContent.FindSet() then
            repeat
                if BinContent."Block Movement" in [BinContent."Block Movement"::All, BinContent."Block Movement"::Outbound] then begin
                    BinContent.CalcFields("Quantity (Base)");
                    QtyBlocked += BinContent."Quantity (Base)";
                end else
                    QtyBlocked += BinContent.CalcQtyWithBlockedItemTracking();
                OnCalcQtyOnBlockedITOrOnBlockedOutbndBinsOnBeforeNext(BinContent, WhseItemTrackingSetup, QtyBlocked);
            until BinContent.Next() = 0;

        OnAfterCalcQtyOnBlockedITOrOnBlockedOutbndBins(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, QtyBlocked);
    end;

    procedure CalcQtyOnOutboundBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; ExcludeDedicatedBinContent: Boolean) QtyOnOutboundBins: Decimal
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        Location: Record Location;
        TempBinContentBuffer: Record "Bin Content Buffer" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyOnOutboundBins(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, ExcludeDedicatedBinContent, IsHandled, QtyOnOutboundBins);
        if IsHandled then
            exit(QtyOnOutboundBins);

        Location.Get(LocationCode);
        if not Location."Require Pick" then
            exit(0);

        if Location."Directed Put-away and Pick" then
            QtyOnOutboundBins :=
                CalcQtyOnOutboundBinsOnDirectedPutAwayPickLocation(
                  LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, ExcludeDedicatedBinContent)
        else
            if Location."Bin Mandatory" and WhseItemTrackingSetup.TrackingExists() then begin
                GetOutboundBinsOnBasicWarehouseLocation(
                  TempBinContentBuffer, LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup);
                TempBinContentBuffer.CalcSums("Qty. Outstanding (Base)");
                QtyOnOutboundBins := TempBinContentBuffer."Qty. Outstanding (Base)";
            end else begin
                WhseShptLine.SetRange("Item No.", ItemNo);
                WhseShptLine.SetRange("Location Code", LocationCode);
                WhseShptLine.SetRange("Variant Code", VariantCode);
                WhseShptLine.CalcSums("Qty. Picked (Base)", "Qty. Shipped (Base)");
                QtyOnOutboundBins := WhseShptLine."Qty. Picked (Base)" - WhseShptLine."Qty. Shipped (Base)";
            end;
    end;

    local procedure CalcQtyOnOutboundBinsOnDirectedPutAwayPickLocation(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; ExcludeDedicatedBinContent: Boolean) QtyOnOutboundBins: Decimal
    var
        WhseEntry: Record "Warehouse Entry";
        Location: Record Location;
        CreatePick: Codeunit "Create Pick";
    begin
        Location.Get(LocationCode);
        if not Location."Directed Put-away and Pick" then
            exit(0);

        WhseEntry.SetCalculationFilters(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, ExcludeDedicatedBinContent);
        WhseEntry.SetFilter("Bin Type Code", CreatePick.GetBinTypeFilter(1)); // Shipping area
        WhseEntry.CalcSums("Qty. (Base)");
        QtyOnOutboundBins := WhseEntry."Qty. (Base)";
        if Location."Adjustment Bin Code" <> '' then begin
            WhseEntry.SetRange("Bin Type Code");
            WhseEntry.SetRange("Bin Code", Location."Adjustment Bin Code");
            WhseEntry.CalcSums("Qty. (Base)");
            QtyOnOutboundBins += WhseEntry."Qty. (Base)";
        end;
    end;

    procedure GetOutboundBinsOnBasicWarehouseLocation(var TempBinContentBuffer: Record "Bin Content Buffer" temporary; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        Location: Record Location;
        WarehouseEntry: Record "Warehouse Entry";
        QtyInBin: Decimal;
    begin
        TempBinContentBuffer.DeleteAll();

        Location.Get(LocationCode);
        if not Location."Bin Mandatory" then
            exit;
        if not Location."Require Pick" or Location."Directed Put-away and Pick" then
            exit;

        WhseItemTrackingSetup."Serial No. Required" := true;
        WhseItemTrackingSetup."Lot No. Required" := true;
        WhseItemTrackingSetup."Package No. Required" := true;

        WarehouseEntry.SetCalculationFilters(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, false);
        WarehouseEntry.SetRange("Whse. Document Type", WarehouseEntry."Whse. Document Type"::Shipment);
        WarehouseEntry.SetRange("Reference Document", WarehouseEntry."Reference Document"::Pick);
        WarehouseEntry.SetFilter("Qty. (Base)", '>%1', 0);
        if WarehouseEntry.FindSet() then
            repeat
                WarehouseEntry.SetRange("Bin Code", WarehouseEntry."Bin Code");
                QtyInBin := CalcQtyOnBin(LocationCode, WarehouseEntry."Bin Code", ItemNo, VariantCode, WhseItemTrackingSetup);
                if QtyInBin > 0 then begin
                    TempBinContentBuffer.Init();
                    TempBinContentBuffer."Location Code" := LocationCode;
                    TempBinContentBuffer."Bin Code" := WarehouseEntry."Bin Code";
                    TempBinContentBuffer."Item No." := ItemNo;
                    TempBinContentBuffer."Variant Code" := VariantCode;
                    TempBinContentBuffer."Qty. Outstanding (Base)" := QtyInBin;
                    TempBinContentBuffer.Insert();
                end;

                WarehouseEntry.FindLast();
                WarehouseEntry.SetRange("Bin Code");
            until WarehouseEntry.Next() = 0;

        if Location."Shipment Bin Code" <> '' then begin
            TempBinContentBuffer.SetRange("Bin Code", Location."Shipment Bin Code");
            if TempBinContentBuffer.IsEmpty() then begin
                QtyInBin := CalcQtyOnBin(LocationCode, Location."Shipment Bin Code", ItemNo, VariantCode, WhseItemTrackingSetup);
                if QtyInBin > 0 then begin
                    TempBinContentBuffer.Init();
                    TempBinContentBuffer."Location Code" := LocationCode;
                    TempBinContentBuffer."Bin Code" := Location."Shipment Bin Code";
                    TempBinContentBuffer."Item No." := ItemNo;
                    TempBinContentBuffer."Variant Code" := VariantCode;
                    TempBinContentBuffer."Qty. Outstanding (Base)" := QtyInBin;
                    TempBinContentBuffer.Insert();
                end;
            end;
        end;

        TempBinContentBuffer.Reset();

        OnAfterGetOutboundBinsOnBasicWarehouseLocation(Location, TempBinContentBuffer, LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup);
    end;

    procedure CalcQtyOnSpecialBinsOnLocation(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; var TempBinContentBufferExcluded: Record "Bin Content Buffer" temporary) QtyOnSpecialBins: Decimal
    var
        SpecialBins: List of [Code[20]];
        SpecialBin: Code[20];
    begin
        GetSpecialBins(SpecialBins, LocationCode);
        foreach SpecialBin in SpecialBins do begin
            TempBinContentBufferExcluded.SetRange("Location Code", LocationCode);
            TempBinContentBufferExcluded.SetRange("Bin Code", SpecialBin);
            if TempBinContentBufferExcluded.IsEmpty() then
                QtyOnSpecialBins +=
                    CalcQtyOnBin(LocationCode, SpecialBin, ItemNo, VariantCode, WhseItemTrackingSetup);
        end;
    end;

    local procedure GetSpecialBins(var SpecialBins: List of [Code[20]]; LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        if Location."To-Assembly Bin Code" <> '' then
            SpecialBins.Add(Location."To-Assembly Bin Code");
        if (Location."Open Shop Floor Bin Code" <> '') and not SpecialBins.Contains(Location."Open Shop Floor Bin Code") then
            SpecialBins.Add(Location."Open Shop Floor Bin Code");
        if (Location."To-Production Bin Code" <> '') and not SpecialBins.Contains(Location."To-Production Bin Code") then
            SpecialBins.Add(Location."To-Production Bin Code");

        OnAfterGetSpecialBins(Location, SpecialBins);
    end;

    procedure CalcResidualPickedQty(var WhseEntry: Record "Warehouse Entry") Result: Decimal
    var
        WhseEntry2: Record "Warehouse Entry";
    begin
        if WhseEntry.FindSet() then
            repeat
                WhseEntry.SetRange("Bin Code", WhseEntry."Bin Code");
                WhseEntry2.CopyFilters(WhseEntry);
                WhseEntry2.SetRange("Whse. Document Type");
                WhseEntry2.SetRange("Reference Document");
                WhseEntry2.SetRange("Qty. (Base)");
                WhseEntry2.CalcSums("Qty. (Base)");
                Result += WhseEntry2."Qty. (Base)";
                WhseEntry.FindLast();
                WhseEntry.SetRange("Bin Code");
            until WhseEntry.Next() = 0;
    end;

    procedure CalcQtyOnBlockedItemTracking(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        CalcQtyOnBlockedITOnSNQuery: Query "CalcQtyOnBlockedITOnSNQuery";
        CalcQtyOnBlockedITOnLNQuery: Query "CalcQtyOnBlockedITOnLNQuery";
        CalcQtyOnBlockedITOnPNQuery: Query "CalcQtyOnBlockedITOnPNQuery";
        LotsBlocked: List of [Code[50]];
        PackagesBlocked: List of [Code[50]];
        SNQtyBlocked: Decimal;
        LotQtyBlocked: Decimal;
        PackageQtyBlocked: Decimal;
        SNLotQtyBlocked: Decimal;
        SNPackageQtyBlocked: Decimal;
        LotPackageQtyBlocked: Decimal;
        QtyBlocked: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeCalcQtyOnBlockedItemTracking(LocationCode, ItemNo, VariantCode, QtyBlocked, IsHandled);
        if IsHandled then
            exit(QtyBlocked);

        //Calculating packages blocked
        CalcQtyOnBlockedITOnPNQuery.SetRange(Item_No_, ItemNo);
        CalcQtyOnBlockedITOnPNQuery.SetRange(Variant_Code, VariantCode);
        CalcQtyOnBlockedITOnPNQuery.SetRange(Blocked, true);

        CalcQtyOnBlockedITOnPNQuery.SetRange(ILE_Item_No_, ItemNo);
        CalcQtyOnBlockedITOnPNQuery.SetRange(ILE_Variant_Code, VariantCode);
        CalcQtyOnBlockedITOnPNQuery.SetRange(ILE_Location_Code, LocationCode);

        CalcQtyOnBlockedITOnPNQuery.Open();

        while CalcQtyOnBlockedITOnPNQuery.Read() do begin
            if (not PackagesBlocked.Contains(CalcQtyOnBlockedITOnPNQuery.Package_No_)) then
                PackagesBlocked.Add(CalcQtyOnBlockedITOnPNQuery.Package_No_);
            PackageQtyBlocked += CalcQtyOnBlockedITOnPNQuery.Quantity;
        end;

        //Calculating lots blocked
        CalcQtyOnBlockedITOnLNQuery.SetRange(Item_No_, ItemNo);
        CalcQtyOnBlockedITOnLNQuery.SetRange(Variant_Code, VariantCode);
        CalcQtyOnBlockedITOnLNQuery.SetRange(Blocked, true);

        CalcQtyOnBlockedITOnLNQuery.SetRange(ILE_Item_No_, ItemNo);
        CalcQtyOnBlockedITOnLNQuery.SetRange(ILE_Variant_Code, VariantCode);
        CalcQtyOnBlockedITOnLNQuery.SetRange(ILE_Location_Code, LocationCode);

        CalcQtyOnBlockedITOnLNQuery.Open();

        while CalcQtyOnBlockedITOnLNQuery.Read() do begin
            if (PackagesBlocked.Contains(CalcQtyOnBlockedITOnLNQuery.Package_No_)) then
                LotPackageQtyBlocked += CalcQtyOnBlockedITOnLNQuery.Quantity;

            if (not LotsBlocked.Contains(CalcQtyOnBlockedITOnLNQuery.Lot_No_)) then
                LotsBlocked.Add(CalcQtyOnBlockedITOnLNQuery.Lot_No_);
            LotQtyBlocked += CalcQtyOnBlockedITOnLNQuery.Quantity;
        end;

        //Calculating serial no blocked
        CalcQtyOnBlockedITOnSNQuery.SetRange(Item_No_, ItemNo);
        CalcQtyOnBlockedITOnSNQuery.SetRange(Variant_Code, VariantCode);
        CalcQtyOnBlockedITOnSNQuery.SetRange(Blocked, true);

        CalcQtyOnBlockedITOnSNQuery.SetRange(ILE_Item_No_, ItemNo);
        CalcQtyOnBlockedITOnSNQuery.SetRange(ILE_Variant_Code, VariantCode);
        CalcQtyOnBlockedITOnSNQuery.SetRange(ILE_Location_Code, LocationCode);

        CalcQtyOnBlockedITOnSNQuery.Open();

        while CalcQtyOnBlockedITOnSNQuery.Read() do begin
            if (LotsBlocked.Contains(CalcQtyOnBlockedITOnSNQuery.Lot_No_)) then
                SNLotQtyBlocked += CalcQtyOnBlockedITOnSNQuery.Quantity
            else
                if (PackagesBlocked.Contains(CalcQtyOnBlockedITOnSNQuery.Package_No_)) then
                    SNPackageQtyBlocked += CalcQtyOnBlockedITOnSNQuery.Quantity;

            SNQtyBlocked += CalcQtyOnBlockedITOnSNQuery.Quantity;
        end;

        QtyBlocked := SNQtyBlocked + LotQtyBlocked + PackageQtyBlocked - SNLotQtyBlocked - SNPackageQtyBlocked - LotPackageQtyBlocked;

        exit(QtyBlocked);
    end;

    local procedure CalcQtyPickedOnProdOrderComponentLine(SourceSubtype: Option; SourceID: Code[20]; SourceProdOrderLineNo: Integer; SourceRefNo: Integer): Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, SourceSubtype);
        ProdOrderComponent.SetRange("Prod. Order No.", SourceID);
        ProdOrderComponent.SetRange("Prod. Order Line No.", SourceProdOrderLineNo);
        ProdOrderComponent.SetRange("Line No.", SourceRefNo);
        if ProdOrderComponent.FindFirst() then
            exit(ProdOrderComponent."Qty. Picked (Base)");

        exit(0);
    end;

    local procedure CalcQtyPickedOnJobPlanningLine(SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer): Decimal
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange(Status, SourceSubtype);
        JobPlanningLine.SetRange("Job No.", SourceID);
        JobPlanningLine.SetRange("Job Contract Entry No.", SourceRefNo);
        if JobPlanningLine.FindFirst() then
            exit(JobPlanningLine."Qty. Picked (Base)");
    end;

    local procedure CalcQtyPickedOnAssemblyLine(SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer): Decimal
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetRange("Document Type", SourceSubtype);
        AssemblyLine.SetRange("Document No.", SourceID);
        AssemblyLine.SetRange("Line No.", SourceRefNo);
        if AssemblyLine.FindFirst() then
            exit(AssemblyLine."Qty. Picked (Base)");

        exit(0);
    end;

    local procedure CalcQtyPickedOnWhseShipmentLine(SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer): Decimal
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WhseShipmentLine.SetSourceFilter(SourceType, SourceSubType, SourceID, SourceRefNo, false);
        WhseShipmentLine.CalcSums("Qty. Picked (Base)", "Qty. Shipped (Base)");
        exit(WhseShipmentLine."Qty. Picked (Base)" - WhseShipmentLine."Qty. Shipped (Base)");
    end;

    local procedure CalcQtyPickedNotShipped(SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer): Decimal
    var
        WarehouseEntry: Record "Warehouse Entry";
        QtyPickedBase: Decimal;
        QtyShippedBase: Decimal;
    begin
        WarehouseEntry.Reset();
        WarehouseEntry.SetSourceFilter(SourceType, SourceSubType, SourceID, SourceRefNo, true);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Reference Document", WarehouseEntry."Reference Document"::Pick);
        WarehouseEntry.SetFilter(Quantity, '>%1', 0);
        WarehouseEntry.CalcSums("Qty. (Base)");
        QtyPickedBase := WarehouseEntry."Qty. (Base)";

        WarehouseEntry.Reset();
        WarehouseEntry.SetSourceFilter(SourceType, SourceSubType, SourceID, SourceRefNo, true);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::"Negative Adjmt.");
        WarehouseEntry.SetRange("Whse. Document Type", WarehouseEntry."Whse. Document Type"::Shipment);
        WarehouseEntry.CalcSums("Qty. (Base)");
        QtyShippedBase := -WarehouseEntry."Qty. (Base)";

        if QtyPickedBase > QtyShippedBase then
            exit(QtyPickedBase - QtyShippedBase);

        exit(0);
    end;

    procedure CalcRegisteredAndOutstandingPickQty(ReservationEntry: Record "Reservation Entry"; var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    begin
        exit(
            CalcQtyRegisteredPick(
                ReservationEntry."Location Code", ReservationEntry."Source Type", ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.", ReservationEntry."Source Prod. Order Line") +
            CalcQtyOutstandingPick(
                ReservationEntry."Source Type", ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.", ReservationEntry."Source Prod. Order Line", WarehouseActivityLine));
    end;

    local procedure CalcQtyRegisteredPick(LocationCode: Code[10]; SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer; SourceProdOrderLine: Integer): Decimal
    var
        Location: Record Location;
    begin
        if SourceType = Database::"Prod. Order Component" then
            exit(CalcQtyPickedOnProdOrderComponentLine(SourceSubType, SourceID, SourceProdOrderLine, SourceRefNo));

        if SourceType = Database::"Assembly Line" then
            exit(CalcQtyPickedOnAssemblyLine(SourceSubType, SourceID, SourceRefNo));

        if SourceType = Database::"Job Planning Line" then
            exit(CalcQtyPickedOnJobPlanningLine(SourceSubType, SourceID, SourceRefNo));

        if Location.RequireShipment(LocationCode) then begin
            if Location.Get(LocationCode) and Location."Bin Mandatory" then
                exit(CalcQtyPickedNotShipped(SourceType, SourceSubType, SourceID, SourceRefNo));
            exit(CalcQtyPickedOnWhseShipmentLine(SourceType, SourceSubType, SourceID, SourceRefNo));
        end;

        exit(0);
    end;

    procedure CalcQtyRegisteredPick(ReservationEntry: Record "Reservation Entry"): Decimal
    begin
        exit(
            CalcQtyRegisteredPick(
                ReservationEntry."Location Code", ReservationEntry."Source Type", ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.", ReservationEntry."Source Prod. Order Line"));
    end;

    local procedure CalcQtyOutstandingPick(SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer; SourceProdOrderLine: Integer; var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        if SourceType = Database::"Prod. Order Component" then
            WhseActivityLine.SetSourceFilter(SourceType, SourceSubType, SourceID, SourceProdOrderLine, SourceRefNo, true)
        else
            WhseActivityLine.SetSourceFilter(SourceType, SourceSubType, SourceID, SourceRefNo, -1, true);
        WhseActivityLine.SetFilter("Action Type", '%1|%2', WhseActivityLine."Action Type"::Take, WhseActivityLine."Action Type"::" ");
        OnCalcQtyOutstandingPickOnAfterSetFilters(WhseActivityLine, SourceType, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLine);

        WhseActivityLine.CalcSums("Qty. Outstanding (Base)");

        // For not yet committed warehouse activity lines
        WarehouseActivityLine.CopyFilters(WhseActivityLine);
        WarehouseActivityLine.CalcSums("Qty. Outstanding (Base)");

        exit(WhseActivityLine."Qty. Outstanding (Base)" + WarehouseActivityLine."Qty. Outstanding (Base)");
    end;

    procedure CalcQtyAvailToTakeOnWhseWorksheetLine(WhseWorksheetLine: Record "Whse. Worksheet Line") AvailQtyBase: Decimal
    var
        Location: Record Location;
        Item: Record Item;
        BinContent: Record "Bin Content";
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        TypeHelper: Codeunit "Type Helper";
        QtyReservedOnPickShip: Decimal;
        QtyReservedForCurrLine: Decimal;
    begin
        AvailQtyBase := 0;

        Location.GetLocationSetup(WhseWorksheetLine."Location Code", Location);
        if Location."Directed Put-away and Pick" then
            exit(0);

        if Item.Get(WhseWorksheetLine."Item No.") then;

        if Location."Bin Mandatory" then begin
            BinContent.SetRange("Location Code", WhseWorksheetLine."Location Code");
            BinContent.SetRange("Item No.", WhseWorksheetLine."Item No.");
            BinContent.SetRange("Variant Code", WhseWorksheetLine."Variant Code");
            if BinContent.FindSet() then
                repeat
                    AvailQtyBase += TypeHelper.Maximum(0, BinContent.CalcQtyAvailToPick(0));
                until BinContent.Next() = 0;

            Item.SetRange("Location Filter", WhseWorksheetLine."Location Code");
            Item.SetRange("Variant Filter", WhseWorksheetLine."Variant Code");
            Item.CalcFields("Reserved Qty. on Inventory");
            AvailQtyBase := AvailQtyBase - Item."Reserved Qty. on Inventory" - CalcQtyBasePickedNotShippedOnWarehouseShipmentLine(WhseWorksheetLine, Item);
        end else
            AvailQtyBase := CalcInvtAvailQty(Item, Location, WhseWorksheetLine."Variant Code", TempWhseActivLine);

        if Location."Require Pick" then
            QtyReservedOnPickShip := CalcReservQtyOnPicksShips(WhseWorksheetLine."Location Code", WhseWorksheetLine."Item No.", WhseWorksheetLine."Variant Code", TempWhseActivLine);

        QtyReservedForCurrLine :=
          Abs(
            CalcLineReservedQtyOnInvt(
              WhseWorksheetLine."Source Type", WhseWorksheetLine."Source Subtype", WhseWorksheetLine."Source No.", WhseWorksheetLine."Source Line No.", WhseWorksheetLine."Source Subline No.", true, TempWhseActivLine));

        AvailQtyBase := AvailQtyBase + QtyReservedOnPickShip + QtyReservedForCurrLine;
    end;

    local procedure CalcQtyBasePickedNotShippedOnWarehouseShipmentLine(WhseWorksheetLine: Record "Whse. Worksheet Line"; Item: Record Item): Decimal
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Item No.", Item."No.");
        WarehouseShipmentLine.SetRange("Location Code", WhseWorksheetLine."Location Code");
        if WhseWorksheetLine."Variant Code" <> '' then
            WarehouseShipmentLine.SetRange("Variant Code", WhseWorksheetLine."Variant Code");
        WarehouseShipmentLine.CalcSums("Qty. Picked (Base)", "Qty. Shipped (Base)");
        exit(WarehouseShipmentLine."Qty. Picked (Base)" - WarehouseShipmentLine."Qty. Shipped (Base)")
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyPicked(var Item: Record Item; var QtyPicked: Decimal; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcReservedQtyOnInventory(var Item: Record Item; var ReservedQtyOnInventory: Decimal; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyRcvdNotAvailable(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; var QtyRcvdNotAvailable: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyOnBlockedITOrOnBlockedOutbndBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; var QtyBlocked: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcReservQtyOnPicksShipsWithItemTracking(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyOutstandingPickOnAfterSetFilters(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer; SourceProdOrderLine: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvtAvailQty(Item: Record Item; Location: Record Location; VariantCode: Code[10]; var WarehouseActivityLine: Record "Warehouse Activity Line"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAssgndtoPickOnAfterSetFilters(var WhseActivLine: Record "Warehouse Activity Line"; Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; BinTypeFilter: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyOnBlockedItemTracking(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; var QtyBlocked: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineReservedQtyOnInvt(var ReservationEntry: Record "Reservation Entry"; var ReservQtyonInvt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyOnOutboundBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; ExcludeDedicatedBinContent: Boolean; var IsHandled: Boolean; var QtyOnOutboundBins: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetOutboundBinsOnBasicWarehouseLocation(Location: Record Location; var TempBinContentBuffer: Record "Bin Content Buffer" temporary; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSpecialBins(Location: Record Location; var SpecialBins: List of [Code[20]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyOnBlockedITOrOnBlockedOutbndBinsOnBeforeNext(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var QtyBlocked: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyOnDedicatedBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; var WarehouseEntry: Record "Warehouse Entry"; TempWhseItemTrackingSetup: Record "Item Tracking Setup" temporary; var QtyOnDedicatedBin: Decimal)
    begin
    end;
}

