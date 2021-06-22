codeunit 99000836 "Transfer Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Planning Assignment" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Codeunit is not initialized correctly.';
        Text001: Label 'Reserved quantity cannot be greater than %1';
        Text002: Label 'must be filled in when a quantity is reserved';
        Text003: Label 'must not be changed when a quantity is reserved';
        ReservMgt: Codeunit "Reservation Management";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        Blocked: Boolean;
        SetFromType: Option " ",Sales,"Requisition Line",Purchase,"Item Journal","BOM Journal","Item Ledger Entry",Service,Job;
        SetFromSubtype: Integer;
        SetFromID: Code[20];
        SetFromBatchName: Code[10];
        SetFromProdOrderLine: Integer;
        SetFromRefNo: Integer;
        SetFromVariantCode: Code[10];
        SetFromLocationCode: Code[10];
        SetFromSerialNo: Code[50];
        SetFromLotNo: Code[50];
        SetFromQtyPerUOM: Decimal;
        DeleteItemTracking: Boolean;

    procedure CreateReservation(var TransLine: Record "Transfer Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50]; Direction: Option Outbound,Inbound)
    var
        ShipmentDate: Date;
    begin
        if SetFromType = 0 then
            Error(Text000);

        TransLine.TestField("Item No.");
        TransLine.TestField("Variant Code", SetFromVariantCode);

        case Direction of
            Direction::Outbound:
                begin
                    TransLine.TestField("Shipment Date");
                    TransLine.TestField("Transfer-from Code", SetFromLocationCode);
                    TransLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                    if Abs(TransLine."Outstanding Qty. (Base)") <
                       Abs(TransLine."Reserved Qty. Outbnd. (Base)") + QuantityBase
                    then
                        Error(
                          Text001,
                          Abs(TransLine."Outstanding Qty. (Base)") - Abs(TransLine."Reserved Qty. Outbnd. (Base)"));
                    ShipmentDate := TransLine."Shipment Date";
                end;
            Direction::Inbound:
                begin
                    TransLine.TestField("Receipt Date");
                    TransLine.TestField("Transfer-to Code", SetFromLocationCode);
                    TransLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                    if Abs(TransLine."Outstanding Qty. (Base)") <
                       Abs(TransLine."Reserved Qty. Inbnd. (Base)") + QuantityBase
                    then
                        Error(
                          Text001,
                          Abs(TransLine."Outstanding Qty. (Base)") - Abs(TransLine."Reserved Qty. Inbnd. (Base)"));
                    ExpectedReceiptDate := TransLine."Receipt Date";
                    ShipmentDate := GetInboundReservEntryShipmentDate;
                end;
        end;
        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Transfer Line",
          Direction, TransLine."Document No.", '',
          TransLine."Derived From Line No.", TransLine."Line No.", TransLine."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForSerialNo, ForLotNo);
        CreateReservEntry.CreateReservEntryFrom(
          SetFromType, SetFromSubtype, SetFromID, SetFromBatchName, SetFromProdOrderLine, SetFromRefNo,
          SetFromQtyPerUOM, SetFromSerialNo, SetFromLotNo);
        CreateReservEntry.CreateReservEntry(
          TransLine."Item No.", TransLine."Variant Code", SetFromLocationCode,
          Description, ExpectedReceiptDate, ShipmentDate);

        SetFromType := 0;
    end;

    procedure CreateReservationSetFrom(TrackingSpecificationFrom: Record "Tracking Specification")
    begin
        with TrackingSpecificationFrom do begin
            SetFromType := "Source Type";
            SetFromSubtype := "Source Subtype";
            SetFromID := "Source ID";
            SetFromBatchName := "Source Batch Name";
            SetFromProdOrderLine := "Source Prod. Order Line";
            SetFromRefNo := "Source Ref. No.";
            SetFromVariantCode := "Variant Code";
            SetFromLocationCode := "Location Code";
            SetFromSerialNo := "Serial No.";
            SetFromLotNo := "Lot No.";
            SetFromQtyPerUOM := "Qty. per Unit of Measure";
        end;
    end;

    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; TransLine: Record "Transfer Line"; Direction: Option Outbound,Inbound)
    begin
        FilterReservEntry.SetSourceFilter(DATABASE::"Transfer Line", Direction, TransLine."Document No.", TransLine."Line No.", false);
        FilterReservEntry.SetSourceFilter('', TransLine."Derived From Line No.");
    end;

    procedure Caption(TransLine: Record "Transfer Line") CaptionText: Text
    begin
        CaptionText :=
          StrSubstNo(
            '%1 %2 %3', TransLine."Document No.", TransLine."Line No.",
            TransLine."Item No.");
    end;

    procedure FindReservEntry(TransLine: Record "Transfer Line"; var ReservEntry: Record "Reservation Entry"; Direction: Option Outbound,Inbound): Boolean
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, TransLine, Direction);
        exit(ReservEntry.FindLast);
    end;

    procedure FindInboundReservEntry(TransLine: Record "Transfer Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    var
        DerivedTransferLine: Record "Transfer Line";
        Direction: Option Outbound,Inbound;
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);

        DerivedTransferLine.SetRange("Document No.", TransLine."Document No.");
        DerivedTransferLine.SetRange("Derived From Line No.", TransLine."Line No.");
        if not DerivedTransferLine.IsEmpty then begin
            ReservEntry.SetSourceFilter(DATABASE::"Transfer Line", Direction::Inbound, TransLine."Document No.", -1, false);
            ReservEntry.SetSourceFilter('', TransLine."Line No.");
        end else
            FilterReservFor(ReservEntry, TransLine, Direction::Inbound);
        exit(ReservEntry.FindLast);
    end;

    local procedure ReservEntryExist(TransLine: Record "Transfer Line"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, TransLine, 0);
        ReservEntry.SetRange("Source Subtype"); // Ignore direction
        exit(not ReservEntry.IsEmpty);
    end;

    procedure VerifyChange(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line")
    var
        TransLine: Record "Transfer Line";
        TempReservEntry: Record "Reservation Entry";
        ShowErrorInbnd: Boolean;
        ShowErrorOutbnd: Boolean;
        HasErrorInbnd: Boolean;
        HasErrorOutbnd: Boolean;
    begin
        if Blocked then
            exit;
        if NewTransLine."Line No." = 0 then
            if not TransLine.Get(NewTransLine."Document No.", NewTransLine."Line No.") then
                exit;

        NewTransLine.CalcFields("Reserved Qty. Inbnd. (Base)");
        NewTransLine.CalcFields("Reserved Qty. Outbnd. (Base)");

        ShowErrorInbnd := (NewTransLine."Reserved Qty. Inbnd. (Base)" <> 0);
        ShowErrorOutbnd := (NewTransLine."Reserved Qty. Outbnd. (Base)" <> 0);

        if NewTransLine."Shipment Date" = 0D then
            if ShowErrorOutbnd then
                NewTransLine.FieldError("Shipment Date", Text002)
            else
                HasErrorOutbnd := true;

        if NewTransLine."Receipt Date" = 0D then
            if ShowErrorInbnd then
                NewTransLine.FieldError("Receipt Date", Text002)
            else
                HasErrorInbnd := true;

        if NewTransLine."Item No." <> OldTransLine."Item No." then
            if ShowErrorInbnd or ShowErrorOutbnd then
                NewTransLine.FieldError("Item No.", Text003)
            else begin
                HasErrorInbnd := true;
                HasErrorOutbnd := true;
            end;

        if NewTransLine."Transfer-from Code" <> OldTransLine."Transfer-from Code" then
            if ShowErrorOutbnd then
                NewTransLine.FieldError("Transfer-from Code", Text003)
            else
                HasErrorOutbnd := true;

        if NewTransLine."Transfer-to Code" <> OldTransLine."Transfer-to Code" then
            if ShowErrorInbnd then
                NewTransLine.FieldError("Transfer-to Code", Text003)
            else
                HasErrorInbnd := true;

        if (NewTransLine."Transfer-from Bin Code" <> OldTransLine."Transfer-from Bin Code") and
           (not ReservMgt.CalcIsAvailTrackedQtyInBin(
              NewTransLine."Item No.", NewTransLine."Transfer-from Bin Code",
              NewTransLine."Transfer-from Code", NewTransLine."Variant Code",
              DATABASE::"Transfer Line", 0,
              NewTransLine."Document No.", '', NewTransLine."Derived From Line No.",
              NewTransLine."Line No."))
        then begin
            if ShowErrorOutbnd then
                NewTransLine.FieldError("Transfer-from Bin Code", Text003);
            HasErrorOutbnd := true;
        end;

        if (NewTransLine."Transfer-To Bin Code" <> OldTransLine."Transfer-To Bin Code") and
           (not ReservMgt.CalcIsAvailTrackedQtyInBin(
              NewTransLine."Item No.", NewTransLine."Transfer-To Bin Code",
              NewTransLine."Transfer-to Code", NewTransLine."Variant Code",
              DATABASE::"Transfer Line", 1,
              NewTransLine."Document No.", '', NewTransLine."Derived From Line No.",
              NewTransLine."Line No."))
        then begin
            if ShowErrorInbnd then
                NewTransLine.FieldError("Transfer-To Bin Code", Text003);
            HasErrorInbnd := true;
        end;

        if NewTransLine."Variant Code" <> OldTransLine."Variant Code" then
            if ShowErrorInbnd or ShowErrorOutbnd then
                NewTransLine.FieldError("Variant Code", Text003)
            else begin
                HasErrorInbnd := true;
                HasErrorOutbnd := true;
            end;

        if NewTransLine."Line No." <> OldTransLine."Line No." then begin
            HasErrorInbnd := true;
            HasErrorOutbnd := true;
        end;

        OnVerifyChangeOnBeforeHasError(NewTransLine, OldTransLine, HasErrorInbnd, HasErrorOutbnd, ShowErrorInbnd, ShowErrorOutbnd);

        if HasErrorOutbnd then begin
            AutoTracking(OldTransLine, NewTransLine, TempReservEntry, 0);
            AssignForPlanning(NewTransLine, 0);
            if (NewTransLine."Item No." <> OldTransLine."Item No.") or
               (NewTransLine."Variant Code" <> OldTransLine."Variant Code") or
               (NewTransLine."Transfer-to Code" <> OldTransLine."Transfer-to Code")
            then
                AssignForPlanning(OldTransLine, 0);
        end;

        if HasErrorInbnd then begin
            AutoTracking(OldTransLine, NewTransLine, TempReservEntry, 1);
            AssignForPlanning(NewTransLine, 1);
            if (NewTransLine."Item No." <> OldTransLine."Item No.") or
               (NewTransLine."Variant Code" <> OldTransLine."Variant Code") or
               (NewTransLine."Transfer-from Code" <> OldTransLine."Transfer-from Code")
            then
                AssignForPlanning(OldTransLine, 1);
        end;
    end;

    procedure VerifyQuantity(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line")
    var
        TransLine: Record "Transfer Line";
        Direction: Option Outbound,Inbound;
    begin
        OnBeforeVerifyReserved(NewTransLine, OldTransLine);

        if Blocked then
            exit;

        with NewTransLine do begin
            if "Line No." = OldTransLine."Line No." then
                if "Quantity (Base)" = OldTransLine."Quantity (Base)" then
                    exit;
            if "Line No." = 0 then
                if not TransLine.Get("Document No.", "Line No.") then
                    exit;
            for Direction := Direction::Outbound to Direction::Inbound do begin
                ReservMgt.SetTransferLine(NewTransLine, Direction);
                if "Qty. per Unit of Measure" <> OldTransLine."Qty. per Unit of Measure" then
                    ReservMgt.ModifyUnitOfMeasure;
                ReservMgt.DeleteReservEntries(false, "Outstanding Qty. (Base)");
                ReservMgt.ClearSurplus;
                ReservMgt.AutoTrack("Outstanding Qty. (Base)");
                AssignForPlanning(NewTransLine, Direction);
            end;
        end;
    end;

    procedure UpdatePlanningFlexibility(var TransLine: Record "Transfer Line")
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if FindReservEntry(TransLine, ReservEntry, 0) then
            ReservEntry.ModifyAll("Planning Flexibility", TransLine."Planning Flexibility");
        if FindReservEntry(TransLine, ReservEntry, 1) then
            ReservEntry.ModifyAll("Planning Flexibility", TransLine."Planning Flexibility");
    end;

    procedure TransferTransferToItemJnlLine(var TransLine: Record "Transfer Line"; var ItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal; Direction: Option Outbound,Inbound)
    var
        OldReservEntry: Record "Reservation Entry";
        TransferLocation: Code[10];
    begin
        if not FindReservEntry(TransLine, OldReservEntry, Direction) then
            exit;

        OldReservEntry.Lock;

        case Direction of
            Direction::Outbound:
                begin
                    TransferLocation := TransLine."Transfer-from Code";
                    ItemJnlLine.TestField("Location Code", TransferLocation);
                end;
            Direction::Inbound:
                begin
                    TransferLocation := TransLine."Transfer-to Code";
                    ItemJnlLine.TestField("New Location Code", TransferLocation);
                end;
        end;

        ItemJnlLine.TestField("Item No.", TransLine."Item No.");
        ItemJnlLine.TestField("Variant Code", TransLine."Variant Code");

        if TransferQty = 0 then
            exit;
        if ReservEngineMgt.InitRecordSet(OldReservEntry) then
            repeat
                OldReservEntry.TestItemFields(TransLine."Item No.", TransLine."Variant Code", TransferLocation);
                OldReservEntry."New Serial No." := OldReservEntry."Serial No.";
                OldReservEntry."New Lot No." := OldReservEntry."Lot No.";

                OnTransferTransferToItemJnlLineTransferFields(OldReservEntry, TransLine, ItemJnlLine, TransferQty, Direction);

                TransferQty :=
                  CreateReservEntry.TransferReservEntry(DATABASE::"Item Journal Line",
                    ItemJnlLine."Entry Type", ItemJnlLine."Journal Template Name",
                    ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.",
                    ItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

            until (ReservEngineMgt.NEXTRecord(OldReservEntry) = 0) or (TransferQty = 0);
    end;

    procedure TransferWhseShipmentToItemJnlLine(var TransLine: Record "Transfer Line"; var ItemJnlLine: Record "Item Journal Line"; var WhseShptHeader: Record "Warehouse Shipment Header"; TransferQty: Decimal)
    var
        OldReservEntry: Record "Reservation Entry";
        WhseShptLine: Record "Warehouse Shipment Line";
        WarehouseEntry: Record "Warehouse Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseSNRequired: Boolean;
        WhseLNRequired: Boolean;
        QtyToHandleBase: Decimal;
    begin
        if TransferQty = 0 then
            exit;
        if not FindReservEntry(TransLine, OldReservEntry, 0) then
            exit;

        ItemJnlLine.TestField("Location Code", TransLine."Transfer-from Code");
        ItemJnlLine.TestField("Item No.", TransLine."Item No.");
        ItemJnlLine.TestField("Variant Code", TransLine."Variant Code");

        WhseShptLine.GetWhseShptLine(
          WhseShptHeader."No.", DATABASE::"Transfer Line", 0, TransLine."Document No.", TransLine."Line No.");

        OldReservEntry.Lock;
        if ReservEngineMgt.InitRecordSet(OldReservEntry) then
            repeat
                OldReservEntry.TestItemFields(TransLine."Item No.", TransLine."Variant Code", TransLine."Transfer-from Code");
                ItemTrackingMgt.CheckWhseItemTrkgSetup(TransLine."Item No.", WhseSNRequired, WhseLNRequired, false);

                WarehouseEntry.SetSourceFilter(
                  OldReservEntry."Source Type", OldReservEntry."Source Subtype",
                  OldReservEntry."Source ID", OldReservEntry."Source Ref. No.", false);
                WarehouseEntry.SetRange("Whse. Document Type", WarehouseEntry."Whse. Document Type"::Shipment);
                WarehouseEntry.SetRange("Whse. Document No.", WhseShptLine."No.");
                WarehouseEntry.SetRange("Whse. Document Line No.", WhseShptLine."Line No.");
                WarehouseEntry.SetRange("Bin Code", WhseShptHeader."Bin Code");
                if WhseSNRequired then
                    WarehouseEntry.SetRange("Serial No.", OldReservEntry."Serial No.");
                if WhseLNRequired then
                    WarehouseEntry.SetRange("Lot No.", OldReservEntry."Lot No.");
                WarehouseEntry.CalcSums("Qty. (Base)");
                QtyToHandleBase := -WarehouseEntry."Qty. (Base)";
                if Abs(QtyToHandleBase) > Abs(OldReservEntry."Qty. to Handle (Base)") then
                    QtyToHandleBase := OldReservEntry."Qty. to Handle (Base)";

                if QtyToHandleBase < 0 then begin
                    OldReservEntry."New Serial No." := OldReservEntry."Serial No.";
                    OldReservEntry."New Lot No." := OldReservEntry."Lot No.";
                    OldReservEntry."Qty. to Handle (Base)" := QtyToHandleBase;
                    OldReservEntry."Qty. to Invoice (Base)" := QtyToHandleBase;

                    TransferQty :=
                      CreateReservEntry.TransferReservEntry(
                        DATABASE::"Item Journal Line",
                        ItemJnlLine."Entry Type", ItemJnlLine."Journal Template Name",
                        ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.",
                        ItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);
                end;
            until (ReservEngineMgt.NEXTRecord(OldReservEntry) = 0) or (TransferQty = 0);
    end;

    procedure TransferTransferToTransfer(var OldTransLine: Record "Transfer Line"; var NewTransLine: Record "Transfer Line"; TransferQty: Decimal; Direction: Option Outbound,Inbound; var TrackingSpecification: Record "Tracking Specification")
    var
        OldReservEntry: Record "Reservation Entry";
        Status: Option Reservation,Tracking,Surplus,Prospect;
        TransferLocation: Code[10];
    begin
        // Used when derived Transfer Lines are created during posting of shipment.
        if not FindReservEntry(OldTransLine, OldReservEntry, Direction) then
            exit;

        OldReservEntry.SetTrackingFilterFromSpec(TrackingSpecification);
        if OldReservEntry.IsEmpty then
            exit;

        OldReservEntry.Lock;

        case Direction of
            Direction::Outbound:
                begin
                    TransferLocation := OldTransLine."Transfer-from Code";
                    NewTransLine.TestField("Transfer-from Code", TransferLocation);
                end;
            Direction::Inbound:
                begin
                    TransferLocation := OldTransLine."Transfer-to Code";
                    NewTransLine.TestField("Transfer-to Code", TransferLocation);
                end;
        end;

        NewTransLine.TestField("Item No.", OldTransLine."Item No.");
        NewTransLine.TestField("Variant Code", OldTransLine."Variant Code");

        for Status := Status::Reservation to Status::Prospect do begin
            if TransferQty = 0 then
                exit;
            OldReservEntry.SetRange("Reservation Status", Status);
            if OldReservEntry.FindSet then
                repeat
                    OldReservEntry.TestItemFields(OldTransLine."Item No.", OldTransLine."Variant Code", TransferLocation);

                    TransferQty :=
                      CreateReservEntry.TransferReservEntry(DATABASE::"Transfer Line",
                        Direction, NewTransLine."Document No.", '', NewTransLine."Derived From Line No.",
                        NewTransLine."Line No.", NewTransLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

                until (OldReservEntry.Next = 0) or (TransferQty = 0);
        end;
    end;

    procedure DeleteLineConfirm(var TransLine: Record "Transfer Line"): Boolean
    begin
        with TransLine do begin
            if not ReservEntryExist(TransLine) then
                exit(true);

            ReservMgt.SetTransferLine(TransLine, 0);
            if ReservMgt.DeleteItemTrackingConfirm then
                DeleteItemTracking := true;
        end;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var TransLine: Record "Transfer Line")
    begin
        if Blocked then
            exit;

        with TransLine do begin
            ReservMgt.SetTransferLine(TransLine, 0);
            if DeleteItemTracking then
                ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            CalcFields("Reserved Qty. Outbnd. (Base)");

            ReservMgt.SetTransferLine(TransLine, 1);
            if DeleteItemTracking then
                ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            CalcFields("Reserved Qty. Inbnd. (Base)");
        end;
    end;

    local procedure AssignForPlanning(var TransLine: Record "Transfer Line"; Direction: Option Outbound,Inbound)
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if TransLine."Item No." <> '' then
            with TransLine do
                case Direction of
                    Direction::Outbound:
                        PlanningAssignment.ChkAssignOne("Item No.", "Variant Code", "Transfer-to Code", "Shipment Date");
                    Direction::Inbound:
                        PlanningAssignment.ChkAssignOne("Item No.", "Variant Code", "Transfer-from Code", "Receipt Date");
                end;
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var TransLine: Record "Transfer Line"; Direction: Option Outbound,Inbound)
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
        AvalabilityDate: Date;
    begin
        TrackingSpecification.InitFromTransLine(TransLine, AvalabilityDate, Direction);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, AvalabilityDate);
        ItemTrackingLines.SetInbound(TransLine.IsInbound);
        ItemTrackingLines.RunModal;
        OnAfterCallItemTracking(TransLine);
    end;

    procedure CallItemTracking(var TransLine: Record "Transfer Line"; Direction: Option Outbound,Inbound; SecondSourceQuantityArray: array[3] of Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
        AvailabilityDate: Date;
    begin
        TrackingSpecification.InitFromTransLine(TransLine, AvailabilityDate, Direction);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, AvailabilityDate);
        ItemTrackingLines.SetSecondSourceQuantity(SecondSourceQuantityArray);
        ItemTrackingLines.RunModal;
        OnAfterCallItemTracking(TransLine);
    end;

    procedure UpdateItemTrackingAfterPosting(TransHeader: Record "Transfer Header"; Direction: Option Outbound,Inbound)
    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // Used for updating Quantity to Handle after posting;
        ReservEntry.SetSourceFilter(DATABASE::"Transfer Line", Direction, TransHeader."No.", -1, true);
        ReservEntry.SetRange("Source Batch Name", '');
        if Direction = Direction::Outbound then
            ReservEntry.SetRange("Source Prod. Order Line", 0)
        else
            ReservEntry.SetFilter("Source Prod. Order Line", '<>%1', 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservEntry);
        if Direction = Direction::Outbound then begin
            ReservEntry2.Copy(ReservEntry);
            ReservEntry2.SetRange("Source Subtype", Direction::Inbound);
            ReservEntry2.SetTrackingFilterFromReservEntry(ReservEntry);
            CreateReservEntry.UpdateItemTrackingAfterPosting(ReservEntry2);
        end;
    end;

    procedure RegisterBinContentItemTracking(var TransferLine: Record "Transfer Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        SourceTrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
        FormRunMode: Option ,Reclass,"Combined Ship/Rcpt","Drop Shipment",Transfer;
        Direction: Option Outbound,Inbound;
    begin
        if not TempTrackingSpecification.FindSet then
            exit;
        SourceTrackingSpecification.InitFromTransLine(TransferLine, TransferLine."Shipment Date", Direction::Outbound);

        Clear(ItemTrackingLines);
        ItemTrackingLines.SetFormRunMode(FormRunMode::Transfer);
        ItemTrackingLines.SetSourceSpec(SourceTrackingSpecification, TransferLine."Shipment Date");
        ItemTrackingLines.RegisterItemTrackingLines(
          SourceTrackingSpecification, TransferLine."Shipment Date", TempTrackingSpecification);
    end;

    local procedure GetInboundReservEntryShipmentDate() InboundReservEntryShipmentDate: Date
    begin
        case SetFromType of
            DATABASE::"Sales Line":
                InboundReservEntryShipmentDate := GetInboundReservEntryShipmentDateBySalesLine;
            DATABASE::"Purchase Line":
                InboundReservEntryShipmentDate := GetInboundReservEntryShipmentDateByPurchaseLine;
            DATABASE::"Transfer Line":
                InboundReservEntryShipmentDate := GetInboundReservEntryShipmentDateByTransferLine;
            DATABASE::"Service Line":
                InboundReservEntryShipmentDate := GetInboundReservEntryShipmentDateByServiceLine;
            DATABASE::"Job Planning Line":
                InboundReservEntryShipmentDate := GetInboundReservEntryShipmentDateByJobPlanningLine;
            DATABASE::"Prod. Order Component":
                InboundReservEntryShipmentDate := GetInboundReservEntryShipmentDateByProdOrderComponent;
        end;
    end;

    local procedure GetInboundReservEntryShipmentDateByProdOrderComponent(): Date
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.Get(SetFromSubtype, SetFromID, SetFromProdOrderLine, SetFromRefNo);
        exit(ProdOrderComponent."Due Date");
    end;

    local procedure GetInboundReservEntryShipmentDateBySalesLine(): Date
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(SetFromSubtype, SetFromID, SetFromRefNo);
        exit(SalesLine."Shipment Date");
    end;

    local procedure GetInboundReservEntryShipmentDateByPurchaseLine(): Date
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Get(SetFromSubtype, SetFromID, SetFromRefNo);
        exit(PurchaseLine."Expected Receipt Date");
    end;

    local procedure GetInboundReservEntryShipmentDateByTransferLine(): Date
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.Get(SetFromID, SetFromRefNo);
        exit(TransferLine."Shipment Date");
    end;

    local procedure GetInboundReservEntryShipmentDateByServiceLine(): Date
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.Get(SetFromSubtype, SetFromID, SetFromRefNo);
        exit(ServiceLine."Needed by Date");
    end;

    local procedure GetInboundReservEntryShipmentDateByJobPlanningLine(): Date
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange(Status, SetFromSubtype);
        JobPlanningLine.SetRange("Job No.", SetFromID);
        JobPlanningLine.SetRange("Job Contract Entry No.", SetFromRefNo);
        JobPlanningLine.FindFirst;
        exit(JobPlanningLine."Planning Date");
    end;

    local procedure AutoTracking(OldTransLine: Record "Transfer Line"; NewTransLine: Record "Transfer Line"; var TempReservEntry: Record "Reservation Entry" temporary; Direction: Option)
    begin
        if (NewTransLine."Item No." <> OldTransLine."Item No.") or FindReservEntry(NewTransLine, TempReservEntry, 0) then begin
            if NewTransLine."Item No." <> OldTransLine."Item No." then begin
                ReservMgt.SetTransferLine(OldTransLine, Direction);
                ReservMgt.DeleteReservEntries(true, 0);
                ReservMgt.SetTransferLine(NewTransLine, Direction);
            end else begin
                ReservMgt.SetTransferLine(NewTransLine, Direction);
                ReservMgt.DeleteReservEntries(true, 0);
            end;
            ReservMgt.AutoTrack(NewTransLine."Outstanding Qty. (Base)");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCallItemTracking(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyReserved(var NewTransferLine: Record "Transfer Line"; OldfTransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferTransferToItemJnlLineTransferFields(var ReservationEntry: Record "Reservation Entry"; var TransferLine: Record "Transfer Line"; var ItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal; Direction: Option Outbound,Inbound)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewTransLine: Record "Transfer Line"; OldTransLine: Record "Transfer Line"; var HasErrorInbnd: Boolean; var HasErrorOutbnd: Boolean; var ShowErrorInbnd: Boolean; var ShowErrorOutbnd: Boolean)
    begin
    end;
}

