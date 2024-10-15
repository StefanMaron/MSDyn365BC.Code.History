codeunit 7314 "Warehouse Availability Mgt."
{

    trigger OnRun()
    begin
    end;

#if not CLEAN17
    [Obsolete('Replaced by CalcLineReservedQtyOnInvt with parameter WhseItemTrackingSetup.', '17.0')]
    procedure CalcLineReservedQtyOnInvt(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; HandleResPickAndShipQty: Boolean; SerialNo: Code[50]; LotNo: Code[50]; CDNo: Code[30]; var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
    begin
        WhseItemTrackingSetup."Serial No." := SerialNo;
        WhseItemTrackingSetup."Lot No." := LotNo;
        WhseItemTrackingSetup."Package No." := CDNo;
        exit(
            CalcLineReservedQtyOnInvt(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, HandleResPickAndShipQty,
            WhseItemTrackingSetup, WarehouseActivityLine));
    end;
#endif

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
        if SourceType = DATABASE::"Prod. Order Component" then begin
            ReservEntry.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceSubLineNo, true);
            ReservEntry.SetSourceFilter('', SourceLineNo);
        end else
            ReservEntry.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, true);
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        if ReservEntry.Find('-') then
            repeat
                ReservEntry2.SetRange("Entry No.", ReservEntry."Entry No.");
                ReservEntry2.SetRange(Positive, true);
                ReservEntry2.SetRange("Source Type", DATABASE::"Item Ledger Entry");
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
        ReservEntry: Record "Reservation Entry";
        TempReservEntryBuffer: Record "Reservation Entry Buffer" temporary;
        ReservMgt: Codeunit "Reservation Management";
        ResPickShipQty: Decimal;
        QtyPicked: Decimal;
        QtyToPick: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcReservQtyOnPicksShipsWithItemTracking(LocationCode, ItemNo, VariantCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

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
                if ReservMgt.ReservEntryPositiveTypeIsItemLedgerEntry(ReservEntry."Entry No.") then begin
                    TransferFields(ReservEntry);
                    if Find then begin
                        "Quantity (Base)" += ReservEntry."Quantity (Base)";
                        Modify();
                    end else
                        Insert();
                end;
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

            // exclude quantity on dedicated bins
            QtyOnDedicatedBins := CalcQtyOnDedicatedBins(Location.Code, "No.", VariantCode);
            if (QtyOnDedicatedBins > 0) and Location."Require Receive" and Location."Require Put-away" then
                QtyReceivedNotAvail -= CalcQtyAssignedToPutAway(Location.Code, "No.", VariantCode, true);

            ReservedQtyOnInventory := "Reserved Qty. on Inventory";
            OnAfterCalcReservedQtyOnInventory(Item, ReservedQtyOnInventory, Location);

            QtyPicked := "Qty. Picked";
            OnAfterCalcQtyPicked(Item, QtyPicked, Location);

            // The reserved qty might exceed the qty available in warehouse and thereby
            // having reserved from the qty not yet put-away
            if (Inventory - QtyReceivedNotAvail - QtyAssgndtoPick - QtyPicked + QtyShipped - QtyOnDedicatedBins) <
               (Abs(ReservedQtyOnInventory) - QtyReservedOnPickShip)
            then
                exit(0);

            SubTotal :=
              Inventory - QtyReceivedNotAvail - QtyAssgndtoPick -
              Abs(ReservedQtyOnInventory) - QtyPicked + QtyShipped;

            exit(SubTotal);
        end;
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
        with PostedWhseRcptLine do begin
            SetCurrentKey("Item No.", "Location Code", "Variant Code");
            SetRange("Item No.", ItemNo);
            SetRange("Location Code", LocationCode);
            SetRange("Variant Code", VariantCode);
            CalcSums("Qty. (Base)", "Qty. Put Away (Base)");
            QtyRcvdNotAvailable := "Qty. (Base)" - "Qty. Put Away (Base)";

            WarehouseEntry.SetRange("Location Code", LocationCode);
            if (QtyRcvdNotAvailable > 0) and not WarehouseEntry.IsEmpty() then begin
                FindSet();
                repeat
                    TempBin."Location Code" := "Location Code";
                    TempBin.Code := "Bin Code";
                    if TempBin.Insert() then;
                until Next() = 0;

                if TempBin.FindSet() then
                    repeat
                        QtyAvailToPutAway +=
                            CalcQtyOnBin(TempBin."Location Code", TempBin.Code, "Item No.", "Variant Code", DummyItemTrackingSetup);
                    until TempBin.Next() = 0;

                if QtyAvailToPutAway < QtyRcvdNotAvailable then
                    QtyRcvdNotAvailable := QtyAvailToPutAway;
            end;

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
            OnCalcQtyAssgndtoPickOnAfterSetFilters(WhseActivLine, Location, ItemNo, VariantCode, BinTypeFilter);
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
            SetTrackingFilterFromWhseItemTrackingLineIfNotBlank(WhseItemTrackingLine);
            CalcSums("Qty. Outstanding (Base)");
            exit("Qty. Outstanding (Base)");
        end;
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

#if not CLEAN17
    [Obsolete('Replaced by CalcQtyOnDedicatedBins with parameters WhseItemTrackingSetup.', '17.0')]
    procedure CalcQtyOnDedicatedBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; CDNo: Code[30]): Decimal
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
    begin
        WhseItemTrackingSetup."Serial No." := SerialNo;
        WhseItemTrackingSetup."Lot No." := LotNo;
        WhseItemTrackingSetup."Package No." := CDNo;
        exit(CalcQtyOnDedicatedBins(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup));
    end;
#endif

    procedure CalcQtyOnDedicatedBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        DummyItemTrackingSetup: Record "Item Tracking Setup";
    begin
        exit(CalcQtyOnDedicatedBins(LocationCode, ItemNo, VariantCode, DummyItemTrackingSetup));
    end;

    procedure CalcQtyOnDedicatedBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        WhseEntry.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code",
          "Unit of Measure Code", "Lot No.", "Serial No.", "Entry Type");
        WhseEntry.SetRange("Item No.", ItemNo);
        WhseEntry.SetRange("Location Code", LocationCode);
        WhseEntry.SetRange("Variant Code", VariantCode);
        WhseEntry.SetRange(Dedicated, true);
        WhseEntry.SetTrackingFilterFromItemTrackingSetupIfNotBlank(WhseItemTrackingSetup);
        WhseEntry.CalcSums(WhseEntry."Qty. (Base)");
        exit(WhseEntry."Qty. (Base)");
    end;

#if not CLEAN16
    [Obsolete('Replaced by CalcQtyOnBin with WhseItemTrackingSetup parameter.', '16.0')]
    procedure CalcQtyOnBin(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; CDNo: Code[30]): Decimal
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
    begin
        WhseItemTrackingSetup."Serial No." := SerialNo;
        WhseItemTrackingSetup."Lot No." := LotNo;
        WhseItemTrackingSetup."Package No." := CDNo;
        exit(CalcQtyOnBin(LocationCode, BinCode, ItemNo, VariantCode, WhseItemTrackingSetup));
    end;
#endif

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

#if not CLEAN17
    [Obsolete('Replaced by CalcQtyOnBlockedITOrOnBlockedOutbndBins with parameter WhseItemTrackingSetup', '17.0')]
    procedure CalcQtyOnBlockedITOrOnBlockedOutbndBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; CDNo: Code[30]; LNRequired: Boolean; SNRequired: Boolean; CDRequired: Boolean) QtyBlocked: Decimal
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
    begin
        WhseItemTrackingSetup."Serial No." := SerialNo;
        WhseItemTrackingSetup."Lot No." := LotNo;
        WhseItemTrackingSetup."Package No." := CDNo;
        WhseItemTrackingSetup."Serial No. Required" := SNRequired;
        WhseItemTrackingSetup."Lot No. Required" := LNRequired;
        WhseItemTrackingSetup."Package No. Required" := CDRequired;
        exit(CalcQtyOnBlockedITOrOnBlockedOutbndBins(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup));
    end;
#endif

    procedure CalcQtyOnBlockedITOrOnBlockedOutbndBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup") QtyBlocked: Decimal
    var
        BinContent: Record "Bin Content";
    begin
        with BinContent do begin
            SetCurrentKey("Location Code", "Item No.", "Variant Code");
            SetRange("Location Code", LocationCode);
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetTrackingFilterFromItemTrackingSetupifNotBlankIfRequired(WhseItemTrackingSetup);
            if FindSet() then
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
        WhseShptLine: Record "Warehouse Shipment Line";
        Location: Record Location;
        TempBinContentBuffer: Record "Bin Content Buffer" temporary;
    begin
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

        WhseItemTrackingSetup."Serial No. Required" := true;
        WhseItemTrackingSetup."Lot No. Required" := true;

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
        WhseEntry: Record "Warehouse Entry";
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

        WhseEntry.SetCalculationFilters(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, false);
        WhseEntry.SetRange("Whse. Document Type", WhseEntry."Whse. Document Type"::Shipment);
        WhseEntry.SetRange("Reference Document", WhseEntry."Reference Document"::Pick);
        WhseEntry.SetFilter("Qty. (Base)", '>%1', 0);
        if WhseEntry.FindSet() then
            repeat
                WhseEntry.SetRange("Bin Code", WhseEntry."Bin Code");
                QtyInBin := CalcQtyOnBin(LocationCode, WhseEntry."Bin Code", ItemNo, VariantCode, WhseItemTrackingSetup);
                if QtyInBin > 0 then begin
                    TempBinContentBuffer.Init();
                    TempBinContentBuffer."Location Code" := LocationCode;
                    TempBinContentBuffer."Bin Code" := WhseEntry."Bin Code";
                    TempBinContentBuffer."Item No." := ItemNo;
                    TempBinContentBuffer."Variant Code" := VariantCode;
                    TempBinContentBuffer."Qty. Outstanding (Base)" := QtyInBin;
                    TempBinContentBuffer.Insert();
                end;

                WhseEntry.FindLast();
                WhseEntry.SetRange("Bin Code");
            until WhseEntry.Next() = 0;
    end;

    procedure CalcQtyOnSpecialBinsOnLocation(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; var TempBinContentBufferExcluded: Record "Bin Content Buffer" temporary) QtyOnSpecialBins: Decimal
    var
        Location: Record Location;
        SpecialBins: List of [Code[20]];
        SpecialBin: Code[20];
    begin
        Location.Get(LocationCode);

        if Location."To-Assembly Bin Code" <> '' then
            SpecialBins.Add(Location."To-Assembly Bin Code");
        if (Location."Open Shop Floor Bin Code" <> '') and not SpecialBins.Contains(Location."Open Shop Floor Bin Code") then
            SpecialBins.Add(Location."Open Shop Floor Bin Code");
        if (Location."To-Production Bin Code" <> '') and not SpecialBins.Contains(Location."To-Production Bin Code") then
            SpecialBins.Add(Location."To-Production Bin Code");

        foreach SpecialBin in SpecialBins do begin
            TempBinContentBufferExcluded.SetRange("Location Code", LocationCode);
            TempBinContentBufferExcluded.SetRange("Bin Code", SpecialBin);
            if TempBinContentBufferExcluded.IsEmpty() then
                QtyOnSpecialBins +=
                    CalcQtyOnBin(LocationCode, SpecialBin, ItemNo, VariantCode, WhseItemTrackingSetup);
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

    local procedure CalcQtyPickedOnAssemblyLine(SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer): Decimal
    var
        AssemblyLine: Record "Assembly Line";
    begin
        with AssemblyLine do begin
            SetRange("Document Type", SourceSubtype);
            SetRange("Document No.", SourceID);
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

        if SourceType = DATABASE::"Assembly Line" then
            exit(CalcQtyPickedOnAssemblyLine(SourceSubType, SourceID, SourceRefNo));

        if Location.RequireShipment(LocationCode) then begin
            if Location.Get(LocationCode) and Location."Bin Mandatory" then
                exit(CalcQtyPickedNotShipped(SourceType, SourceSubType, SourceID, SourceRefNo));
            exit(CalcQtyPickedOnWhseShipmentLine(SourceType, SourceSubType, SourceID, SourceRefNo));
        end;

        exit(0);
    end;

    procedure CalcQtyRegisteredPick(ReservationEntry: Record "Reservation Entry"): Decimal
    begin
        with ReservationEntry do
            exit(
              CalcQtyRegisteredPick(
                "Location Code", "Source Type", "Source Subtype", "Source ID", "Source Ref. No.", "Source Prod. Order Line"));
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
}

