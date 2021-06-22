codeunit 7314 "Warehouse Availability Mgt."
{

    trigger OnRun()
    begin
    end;

    procedure CalcLineReservedQtyOnInvt(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; HandleResPickAndShipQty: Boolean; SerialNo: Code[50]; LotNo: Code[50]; var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ReservQtyonInvt: Decimal;
        PickQty: Decimal;
    begin
        // Returns the reserved quantity against ILE for the demand line
        if SourceType = DATABASE::"Prod. Order Component" then begin
            ReservEntry.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceSubLineNo, true);
            ReservEntry.SetSourceFilter('', SourceLineNo);
        end else
            ReservEntry.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, true);
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        if ReservEntry."Serial No." <> '' then
            ReservEntry.SetRange("Serial No.", SerialNo);
        if ReservEntry."Lot No." <> '' then
            ReservEntry.SetRange("Lot No.", LotNo);
        if ReservEntry.Find('-') then
            repeat
                ReservEntry2.SetRange("Entry No.", ReservEntry."Entry No.");
                ReservEntry2.SetRange(Positive, true);
                ReservEntry2.SetRange("Source Type", DATABASE::"Item Ledger Entry");
                ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
                if SerialNo <> '' then
                    ReservEntry2.SetRange("Serial No.", SerialNo);
                if LotNo <> '' then
                    ReservEntry2.SetRange("Lot No.", LotNo);
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

        exit(ReservQtyonInvt);
    end;

    procedure CalcReservQtyOnPicksShips(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        exit(CalcReservQtyOnPicksShipsWithItemTracking(
            WarehouseActivityLine, TempTrackingSpecification, LocationCode, ItemNo, VariantCode));
    end;

    procedure CalcReservQtyOnPicksShipsWithItemTracking(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TrackingSpecification: Record "Tracking Specification"; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        ReservEntry: Record "Reservation Entry";
        TempReservEntryBuffer: Record "Reservation Entry Buffer" temporary;
        ResPickShipQty: Decimal;
        QtyPicked: Decimal;
        QtyToPick: Decimal;
    begin
        // Returns the reserved part of the sum of outstanding quantity on pick lines and
        // quantity on shipment lines picked but not yet shipped for a given item
        ReservEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Reservation Status");
        ReservEntry.SetRange("Item No.", ItemNo);
        ReservEntry.SetRange("Variant Code", VariantCode);
        ReservEntry.SetRange("Location Code", LocationCode);
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.SetRange(Positive, false);
        ReservEntry.SetTrackingFilterFromSpecIfNotBlank(TrackingSpecification);
        if not ReservEntry.FindSet() then
            exit(0);

        with TempReservEntryBuffer do begin
            repeat
                TransferFields(ReservEntry);
                if Find then begin
                    "Quantity (Base)" += ReservEntry."Quantity (Base)";
                    Modify();
                end else
                    Insert();
            until ReservEntry.Next() = 0;

            if FindSet then
                repeat
                    QtyPicked :=
                      CalcQtyRegisteredPick(
                        LocationCode, "Source Type", "Source Subtype", "Source ID", "Source Ref. No.", "Source Prod. Order Line");
                    QtyToPick :=
                      CalcQtyOutstandingPick(
                        "Source Type", "Source Subtype", "Source ID", "Source Ref. No.", "Source Prod. Order Line", WarehouseActivityLine);
                    if -"Quantity (Base)" > QtyPicked + QtyToPick then
                        ResPickShipQty += (QtyPicked + QtyToPick)
                    else
                        ResPickShipQty += -"Quantity (Base)";
                until Next() = 0;

            exit(ResPickShipQty);
        end;
    end;

    procedure CalcLineReservQtyOnPicksShips(SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer; SourceProdOrderLine: Integer; ReservedQtyBase: Decimal; var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    var
        PickedNotYetShippedQty: Decimal;
        OutstandingQtyOnPickLines: Decimal;
    begin
        // Returns the reserved part of the sum of outstanding quantity on pick lines and
        // quantity on shipment lines picked but not yet shipped for a given demand line
        if SourceType = DATABASE::"Prod. Order Component" then
            PickedNotYetShippedQty := CalcQtyPickedOnProdOrderComponentLine(SourceSubType, SourceID, SourceProdOrderLine, SourceRefNo)
        else
            PickedNotYetShippedQty := CalcQtyPickedOnWhseShipmentLine(SourceType, SourceSubType, SourceID, SourceRefNo);

        OutstandingQtyOnPickLines :=
          CalcQtyOutstandingPick(SourceType, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLine, WarehouseActivityLine);

        if -ReservedQtyBase > (PickedNotYetShippedQty + OutstandingQtyOnPickLines) then
            exit(PickedNotYetShippedQty + OutstandingQtyOnPickLines);

        exit(-ReservedQtyBase);
    end;

    procedure CalcInvtAvailQty(Item: Record Item; Location: Record Location; VariantCode: Code[10]; var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    var
        QtyReceivedNotAvail: Decimal;
        QtyAssgndtoPick: Decimal;
        QtyShipped: Decimal;
        QtyReservedOnPickShip: Decimal;
        QtyOnDedicatedBins: Decimal;
        ReservedQtyOnInventory: Decimal;
        SubTotal: Decimal;
    begin
        // Returns the available quantity to pick for pick/ship/receipt/put-away
        // locations without directed put-away and pick
        with Item do begin
            SetRange("Location Filter", Location.Code);
            SetRange("Variant Filter", VariantCode);
            if Location."Require Shipment" then
                CalcFields(Inventory, "Reserved Qty. on Inventory", "Qty. Picked")
            else
                CalcFields(Inventory, "Reserved Qty. on Inventory");

            if Location."Require Receive" and Location."Require Put-away" then
                QtyReceivedNotAvail := CalcQtyRcvdNotAvailable(Location.Code, "No.", VariantCode);

            QtyAssgndtoPick := CalcQtyAssgndtoPick(Location, "No.", VariantCode, '');

            if Location.RequireShipment(Location.Code) then
                QtyShipped := CalcQtyShipped(Location, "No.", VariantCode);
            QtyReservedOnPickShip := CalcReservQtyOnPicksShips(Location.Code, "No.", VariantCode, WarehouseActivityLine);
            QtyOnDedicatedBins := CalcQtyOnDedicatedBins(Location.Code, "No.", VariantCode, '', '');

            ReservedQtyOnInventory := "Reserved Qty. on Inventory";
            OnAfterCalcReservedQtyOnInventory(Item, ReservedQtyOnInventory, Location);

            // The reserved qty might exceed the qty available in warehouse and thereby
            // having reserved from the qty not yet put-away
            if (Inventory - QtyReceivedNotAvail - QtyAssgndtoPick - "Qty. Picked" + QtyShipped - QtyOnDedicatedBins) <
               (Abs(ReservedQtyOnInventory) - QtyReservedOnPickShip)
            then
                exit(0);

            SubTotal :=
              Inventory - QtyReceivedNotAvail - QtyAssgndtoPick -
              Abs(ReservedQtyOnInventory) - "Qty. Picked" + QtyShipped;

            exit(SubTotal);
        end;
    end;

    local procedure CalcQtyRcvdNotAvailable(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        QtyRcvdNotAvailable: Decimal;
    begin
        // Returns the quantity received but not yet put-away for a given item
        // for pick/ship/receipt/put-away locations without directed put-away and pick
        with PostedWhseRcptLine do begin
            SetCurrentKey("Item No.", "Location Code", "Variant Code");
            SetRange("Item No.", ItemNo);
            SetRange("Location Code", LocationCode);
            SetRange("Variant Code", VariantCode);
            CalcSums("Qty. (Base)", "Qty. Put Away (Base)");
            QtyRcvdNotAvailable := "Qty. (Base)" - "Qty. Put Away (Base)";
            OnAfterCalcQtyRcvdNotAvailable(PostedWhseRcptLine, LocationCode, ItemNo, VariantCode, QtyRcvdNotAvailable);
            exit(QtyRcvdNotAvailable);
        end;
    end;

    procedure CalcQtyAssgndtoPick(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; BinTypeFilter: Text[250]): Decimal
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        // Returns the outstanding quantity on pick lines for a given item
        // for a pick location without directed put-away and pick
        with WhseActivLine do begin
            SetCurrentKey(
              "Item No.", "Location Code", "Activity Type", "Bin Type Code",
              "Unit of Measure Code", "Variant Code", "Breakbulk No.");
            SetRange("Item No.", ItemNo);
            SetRange("Location Code", Location.Code);
            SetRange("Variant Code", VariantCode);
            SetRange("Bin Type Code", BinTypeFilter);
            if Location."Bin Mandatory" then
                SetRange("Action Type", "Action Type"::Take)
            else begin
                SetRange("Action Type", "Action Type"::" ");
                SetRange("Breakbulk No.", 0);
            end;
            if Location."Require Shipment" then
                SetRange("Activity Type", "Activity Type"::Pick)
            else begin
                SetRange("Activity Type", "Activity Type"::"Invt. Pick");
                SetRange("Assemble to Order", false);
            end;
            CalcSums("Qty. Outstanding (Base)");
            exit("Qty. Outstanding (Base)");
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcQtyAssignedToMove(WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line"): Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        with WarehouseActivityLine do begin
            SetCurrentKey(
              "Item No.", "Location Code", "Activity Type", "Bin Type Code", "Unit of Measure Code", "Variant Code", "Breakbulk No.",
              "Action Type");
            SetRange("Item No.", WhseWorksheetLine."Item No.");
            SetRange("Location Code", WhseWorksheetLine."Location Code");
            SetRange("Activity Type", "Activity Type"::Movement);
            SetRange("Variant Code", WhseWorksheetLine."Variant Code");
            SetRange("Action Type", "Action Type"::Take);
            SetRange("Bin Code", WhseWorksheetLine."From Bin Code");
            if WhseItemTrackingLine."Lot No." <> '' then
                SetRange("Lot No.", WhseItemTrackingLine."Lot No.");
            if WhseItemTrackingLine."Serial No." <> '' then
                SetRange("Serial No.", WhseItemTrackingLine."Serial No.");
            CalcSums("Qty. Outstanding (Base)");
            exit("Qty. Outstanding (Base)");
        end;
    end;

    procedure CalcQtyAssgndOnWksh(DefWhseWkshLine: Record "Whse. Worksheet Line"; RespectUOMCode: Boolean; ExcludeLine: Boolean): Decimal
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        with WhseWkshLine do begin
            SetCurrentKey(
              "Item No.", "Location Code", "Worksheet Template Name", "Variant Code", "Unit of Measure Code");
            SetRange("Item No.", DefWhseWkshLine."Item No.");
            SetRange("Location Code", DefWhseWkshLine."Location Code");
            SetRange("Worksheet Template Name", DefWhseWkshLine."Worksheet Template Name");
            SetRange("Variant Code", DefWhseWkshLine."Variant Code");
            if RespectUOMCode then
                SetRange("Unit of Measure Code", DefWhseWkshLine."Unit of Measure Code");
            CalcSums("Qty. to Handle (Base)");
            if ExcludeLine and DefWhseWkshLine.Find then
                "Qty. to Handle (Base)" := "Qty. to Handle (Base)" - DefWhseWkshLine."Qty. to Handle (Base)";
            exit("Qty. to Handle (Base)");
        end;
    end;

    local procedure CalcQtyShipped(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        with WhseShptLine do begin
            SetCurrentKey("Item No.", "Location Code", "Variant Code", "Due Date");
            SetRange("Item No.", ItemNo);
            SetRange("Location Code", Location.Code);
            SetRange("Variant Code", VariantCode);
            CalcSums("Qty. Shipped (Base)");
            exit("Qty. Shipped (Base)");
        end;
    end;

    procedure CalcQtyOnDedicatedBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        WhseEntry.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code",
          "Unit of Measure Code", "Lot No.", "Serial No.", "Entry Type");
        WhseEntry.SetRange("Item No.", ItemNo);
        WhseEntry.SetRange("Location Code", LocationCode);
        WhseEntry.SetRange("Variant Code", VariantCode);
        WhseEntry.SetRange(Dedicated, true);
        if LotNo <> '' then
            WhseEntry.SetRange("Lot No.", LotNo);
        if SerialNo <> '' then
            WhseEntry.SetRange("Serial No.", SerialNo);
        WhseEntry.CalcSums(WhseEntry."Qty. (Base)");
        exit(WhseEntry."Qty. (Base)");
    end;

    [Obsolete('Replaced by CalcLineReservedQtyOnInvt with WhseItemTrackingSetup parameter.','16.0')]
    procedure CalcQtyOnBin(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]): Decimal
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
    begin
        WhseItemTrackingSetup."Serial No." := SerialNo;
        WhseItemTrackingSetup."Lot No." := LotNo;
        exit(CalcQtyOnBin(LocationCode, BinCode, ItemNo, VariantCode, WhseItemTrackingSetup));
    end;

    procedure CalcQtyOnBin(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        if BinCode = '' then
            exit(0);

        with WhseEntry do begin
            SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code",
              "Unit of Measure Code", "Lot No.", "Serial No.", "Entry Type");
            SetRange("Item No.", ItemNo);
            SetRange("Bin Code", BinCode);
            SetRange("Location Code", LocationCode);
            SetRange("Variant Code", VariantCode);
            SetTrackingFilterFromItemTrackingSetupIfNotBlank(WhseItemTrackingSetup);
            CalcSums("Qty. (Base)");
            exit("Qty. (Base)");
        end;
    end;

    procedure CalcQtyOnBlockedITOrOnBlockedOutbndBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; LNRequired: Boolean; SNRequired: Boolean) QtyBlocked: Decimal
    var
        BinContent: Record "Bin Content";
    begin
        with BinContent do begin
            SetCurrentKey("Location Code", "Item No.", "Variant Code");
            SetRange("Location Code", LocationCode);
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            if LotNo <> '' then
                if LNRequired then
                    SetRange("Lot No. Filter", LotNo);
            if SerialNo <> '' then
                if SNRequired then
                    SetRange("Serial No. Filter", SerialNo);
            if FindSet then
                repeat
                    if "Block Movement" in ["Block Movement"::All, "Block Movement"::Outbound] then begin
                        CalcFields("Quantity (Base)");
                        QtyBlocked += "Quantity (Base)";
                    end else
                        QtyBlocked += CalcQtyWithBlockedItemTracking();
                until Next() = 0;
        end;
    end;

    procedure CalcQtyOnOutboundBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; ExcludeDedicatedBinContent: Boolean) QtyOnOutboundBins: Decimal
    var
        WhseEntry: Record "Warehouse Entry";
        WhseShptLine: Record "Warehouse Shipment Line";
        Location: Record Location;
        CreatePick: Codeunit "Create Pick";
    begin
        // Directed put-away and pick
        Location.Get(LocationCode);

        WhseItemTrackingSetup."Serial No. Required" := true;
        WhseItemTrackingSetup."Lot No. Required" := true;

        if Location."Directed Put-away and Pick" then begin
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
        end else
            if Location."Require Pick" then
                if Location."Bin Mandatory" and WhseItemTrackingSetup.TrackingExists() then begin
                    WhseEntry.SetCalculationFilters(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, false);
                    WhseEntry.SetRange("Whse. Document Type", WhseEntry."Whse. Document Type"::Shipment);
                    WhseEntry.SetRange("Reference Document", WhseEntry."Reference Document"::Pick);
                    WhseEntry.SetFilter("Qty. (Base)", '>%1', 0);
                    QtyOnOutboundBins := CalcResidualPickedQty(WhseEntry);
                end else begin
                    WhseShptLine.SetRange("Item No.", ItemNo);
                    WhseShptLine.SetRange("Location Code", LocationCode);
                    WhseShptLine.SetRange("Variant Code", VariantCode);
                    WhseShptLine.CalcSums("Qty. Picked (Base)", "Qty. Shipped (Base)");
                    QtyOnOutboundBins := WhseShptLine."Qty. Picked (Base)" - WhseShptLine."Qty. Shipped (Base)";
                end;
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

    local procedure CalcQtyPickedOnProdOrderComponentLine(SourceSubtype: Option; SourceID: Code[20]; SourceProdOrderLineNo: Integer; SourceRefNo: Integer): Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        with ProdOrderComponent do begin
            SetRange(Status, SourceSubtype);
            SetRange("Prod. Order No.", SourceID);
            SetRange("Prod. Order Line No.", SourceProdOrderLineNo);
            SetRange("Line No.", SourceRefNo);
            if FindFirst() then
                exit("Qty. Picked (Base)");
        end;

        exit(0);
    end;

    local procedure CalcQtyPickedOnWhseShipmentLine(SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer): Decimal
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin
        with WhseShipmentLine do begin
            SetSourceFilter(SourceType, SourceSubType, SourceID, SourceRefNo, false);
            CalcSums("Qty. Picked (Base)", "Qty. Shipped (Base)");
            exit("Qty. Picked (Base)" - "Qty. Shipped (Base)");
        end;
    end;

    procedure CalcRegisteredAndOutstandingPickQty(ReservationEntry: Record "Reservation Entry"; var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    begin
        with ReservationEntry do
            exit(
              CalcQtyRegisteredPick(
                "Location Code", "Source Type", "Source Subtype", "Source ID", "Source Ref. No.", "Source Prod. Order Line") +
              CalcQtyOutstandingPick(
                "Source Type", "Source Subtype", "Source ID", "Source Ref. No.", "Source Prod. Order Line", WarehouseActivityLine));
    end;

    local procedure CalcQtyRegisteredPick(LocationCode: Code[10]; SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer; SourceProdOrderLine: Integer): Decimal
    var
        Location: Record Location;
    begin
        if SourceType = DATABASE::"Prod. Order Component" then
            exit(CalcQtyPickedOnProdOrderComponentLine(SourceSubType, SourceID, SourceProdOrderLine, SourceRefNo));

        if Location.RequireShipment(LocationCode) then
            exit(CalcQtyPickedOnWhseShipmentLine(SourceType, SourceSubType, SourceID, SourceRefNo));

        exit(0);
    end;

    local procedure CalcQtyOutstandingPick(SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer; SourceProdOrderLine: Integer; var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        if SourceType = DATABASE::"Prod. Order Component" then
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcReservedQtyOnInventory(var Item: Record Item; var ReservedQtyOnInventory: Decimal; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyRcvdNotAvailable(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; var QtyRcvdNotAvailable: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyOutstandingPickOnAfterSetFilters(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer; SourceProdOrderLine: Integer)
    begin
    end;
}

