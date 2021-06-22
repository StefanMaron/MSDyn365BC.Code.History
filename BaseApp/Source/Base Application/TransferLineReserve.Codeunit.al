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
        Text006: Label 'Outbound,Inbound';
        FromTrackingSpecification: Record "Tracking Specification";
        ReservMgt: Codeunit "Reservation Management";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        Direction: Enum "Transfer Direction";
        Blocked: Boolean;
        DeleteItemTracking: Boolean;

    procedure CreateReservation(var TransLine: Record "Transfer Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry"; Direction: Enum "Transfer Direction")
    var
        ShipmentDate: Date;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text000);

        TransLine.TestField("Item No.");
        TransLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");

        case Direction of
            Direction::Outbound:
                begin
                    TransLine.TestField("Shipment Date");
                    TransLine.TestField("Transfer-from Code", FromTrackingSpecification."Location Code");
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
                    TransLine.TestField("Transfer-to Code", FromTrackingSpecification."Location Code");
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
          Quantity, QuantityBase, ForReservEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          TransLine."Item No.", TransLine."Variant Code", FromTrackingSpecification."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    [Obsolete('Replaced by CreateReservation(TransferLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry, Direction)','16.0')]
    procedure CreateReservation(var TransLine: Record "Transfer Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50]; Direction: Enum "Transfer Direction")
    var
        ForReservEntry: Record "Reservation Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservation(TransLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry, Direction);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    [Obsolete('Replaced by TransLine.SetReservationFilters(FilterReservEntry, Direction)','16.0')]
    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; TransLine: Record "Transfer Line"; Direction: Enum "Transfer Direction")
    begin
        TransLine.SetReservationFilters(FilterReservEntry, Direction);
    end;

    procedure Caption(TransLine: Record "Transfer Line") CaptionText: Text
    begin
        CaptionText := TransLine.GetSourceCaption;
    end;

    procedure FindReservEntry(TransLine: Record "Transfer Line"; var ReservEntry: Record "Reservation Entry"; Direction: Enum "Transfer Direction"): Boolean
    begin
        ReservEntry.InitSortingAndFilters(false);
        TransLine.SetReservationFilters(ReservEntry, Direction);
        exit(ReservEntry.FindLast);
    end;

    procedure FindInboundReservEntry(TransLine: Record "Transfer Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    var
        DerivedTransferLine: Record "Transfer Line";
    begin
        ReservEntry.InitSortingAndFilters(false);

        DerivedTransferLine.SetRange("Document No.", TransLine."Document No.");
        DerivedTransferLine.SetRange("Derived From Line No.", TransLine."Line No.");
        if not DerivedTransferLine.IsEmpty then begin
            ReservEntry.SetSourceFilter(DATABASE::"Transfer Line", Direction::Inbound, TransLine."Document No.", -1, false);
            ReservEntry.SetSourceFilter('', TransLine."Line No.");
        end else
            TransLine.SetReservationFilters(ReservEntry, Direction::Inbound);
        exit(ReservEntry.FindLast);
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
            AutoTracking(OldTransLine, NewTransLine, TempReservEntry, Direction::Outbound);
            AssignForPlanning(NewTransLine, Direction::Outbound);
            if (NewTransLine."Item No." <> OldTransLine."Item No.") or
               (NewTransLine."Variant Code" <> OldTransLine."Variant Code") or
               (NewTransLine."Transfer-to Code" <> OldTransLine."Transfer-to Code")
            then
                AssignForPlanning(OldTransLine, Direction::Outbound);
        end;

        if HasErrorInbnd then begin
            AutoTracking(OldTransLine, NewTransLine, TempReservEntry, Direction::Inbound);
            AssignForPlanning(NewTransLine, Direction::Inbound);
            if (NewTransLine."Item No." <> OldTransLine."Item No.") or
               (NewTransLine."Variant Code" <> OldTransLine."Variant Code") or
               (NewTransLine."Transfer-from Code" <> OldTransLine."Transfer-from Code")
            then
                AssignForPlanning(OldTransLine, Direction::Inbound);
        end;
    end;

    procedure VerifyQuantity(var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line")
    var
        TransLine: Record "Transfer Line";
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
                ReservMgt.SetReservSource(NewTransLine, Direction);
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
        if FindReservEntry(TransLine, ReservEntry, Direction::Outbound) then
            ReservEntry.ModifyAll("Planning Flexibility", TransLine."Planning Flexibility");
        if FindReservEntry(TransLine, ReservEntry, Direction::Inbound) then
            ReservEntry.ModifyAll("Planning Flexibility", TransLine."Planning Flexibility");
    end;

    procedure TransferTransferToItemJnlLine(var TransLine: Record "Transfer Line"; var ItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal; Direction: Enum "Transfer Direction")
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
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        QtyToHandleBase: Decimal;
    begin
        if TransferQty = 0 then
            exit;
        if not FindReservEntry(TransLine, OldReservEntry, Direction::Outbound) then
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
                ItemTrackingMgt.GetWhseItemTrkgSetup(TransLine."Item No.", WhseItemTrackingSetup);

                WarehouseEntry.SetSourceFilter(
                  OldReservEntry."Source Type", OldReservEntry."Source Subtype",
                  OldReservEntry."Source ID", OldReservEntry."Source Ref. No.", false);
                WarehouseEntry.SetRange("Whse. Document Type", WarehouseEntry."Whse. Document Type"::Shipment);
                WarehouseEntry.SetRange("Whse. Document No.", WhseShptLine."No.");
                WarehouseEntry.SetRange("Whse. Document Line No.", WhseShptLine."Line No.");
                WarehouseEntry.SetRange("Bin Code", WhseShptHeader."Bin Code");
                if WhseItemTrackingSetup."Serial No. Required" then
                    WarehouseEntry.SetRange("Serial No.", OldReservEntry."Serial No.");
                if WhseItemTrackingSetup."Lot No. Required" then
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

    procedure TransferTransferToTransfer(var OldTransLine: Record "Transfer Line"; var NewTransLine: Record "Transfer Line"; TransferQty: Decimal; Direction: Enum "Transfer Direction"; var TrackingSpecification: Record "Tracking Specification")
    var
        OldReservEntry: Record "Reservation Entry";
        ReservStatus: Enum "Reservation Status";
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

        for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
            if TransferQty = 0 then
                exit;
            OldReservEntry.SetRange("Reservation Status", ReservStatus);
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
            if not ReservEntryExist then
                exit(true);

            ReservMgt.SetReservSource(TransLine, Direction::Outbound);
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
            ReservMgt.SetReservSource(TransLine, Direction::Outbound);
            if DeleteItemTracking then
                ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            CalcFields("Reserved Qty. Outbnd. (Base)");

            ReservMgt.SetReservSource(TransLine, Direction::Inbound);
            if DeleteItemTracking then
                ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            CalcFields("Reserved Qty. Inbnd. (Base)");
        end;
    end;

    local procedure AssignForPlanning(var TransLine: Record "Transfer Line"; Direction: Enum "Transfer Direction")
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

    procedure CallItemTracking(var TransLine: Record "Transfer Line"; Direction: Enum "Transfer Direction")
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

    procedure CallItemTracking(var TransLine: Record "Transfer Line"; Direction: Enum "Transfer Direction"; SecondSourceQuantityArray: array[3] of Decimal)
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

    procedure UpdateItemTrackingAfterPosting(TransHeader: Record "Transfer Header"; Direction: Enum "Transfer Direction")
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
        case FromTrackingSpecification."Source Type" of
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
        ProdOrderComponent.Get(
            FromTrackingSpecification."Source Subtype", FromTrackingSpecification."Source ID",
            FromTrackingSpecification."Source Prod. Order Line", FromTrackingSpecification."Source Ref. No.");
        exit(ProdOrderComponent."Due Date");
    end;

    local procedure GetInboundReservEntryShipmentDateBySalesLine(): Date
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(
            FromTrackingSpecification."Source Subtype", FromTrackingSpecification."Source ID",
            FromTrackingSpecification."Source Ref. No.");
        exit(SalesLine."Shipment Date");
    end;

    local procedure GetInboundReservEntryShipmentDateByPurchaseLine(): Date
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Get(
            FromTrackingSpecification."Source Subtype", FromTrackingSpecification."Source ID",
            FromTrackingSpecification."Source Ref. No.");
        exit(PurchaseLine."Expected Receipt Date");
    end;

    local procedure GetInboundReservEntryShipmentDateByTransferLine(): Date
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.Get(
            FromTrackingSpecification."Source ID", FromTrackingSpecification."Source Ref. No.");
        exit(TransferLine."Shipment Date");
    end;

    local procedure GetInboundReservEntryShipmentDateByServiceLine(): Date
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.Get(
            FromTrackingSpecification."Source Subtype", FromTrackingSpecification."Source ID",
            FromTrackingSpecification."Source Ref. No.");
        exit(ServiceLine."Needed by Date");
    end;

    local procedure GetInboundReservEntryShipmentDateByJobPlanningLine(): Date
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange(Status, FromTrackingSpecification."Source Subtype");
        JobPlanningLine.SetRange("Job No.", FromTrackingSpecification."Source ID");
        JobPlanningLine.SetRange("Job Contract Entry No.", FromTrackingSpecification."Source Ref. No.");
        JobPlanningLine.FindFirst;
        exit(JobPlanningLine."Planning Date");
    end;

    local procedure AutoTracking(OldTransLine: Record "Transfer Line"; NewTransLine: Record "Transfer Line"; var TempReservEntry: Record "Reservation Entry" temporary; Direction: Enum "Transfer Direction")
    begin
        if (NewTransLine."Item No." <> OldTransLine."Item No.") or FindReservEntry(NewTransLine, TempReservEntry, Direction::Outbound) then begin
            if NewTransLine."Item No." <> OldTransLine."Item No." then begin
                ReservMgt.SetReservSource(OldTransLine, Direction);
                ReservMgt.DeleteReservEntries(true, 0);
                ReservMgt.SetReservSource(NewTransLine, Direction);
            end else begin
                ReservMgt.SetReservSource(NewTransLine, Direction);
                ReservMgt.DeleteReservEntries(true, 0);
            end;
            ReservMgt.AutoTrack(NewTransLine."Outstanding Qty. (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; ReservEntry: Record "Reservation Entry")
    var
        TransferLine: Record "Transfer Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(TransferLine);
            TransferLine.Find;
            QtyPerUOM := TransferLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, ReservEntry."Source Subtype");
        end;
    end;

    local procedure SetReservSourceFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text; Direction: Enum "Transfer Direction")
    var
        TransLine: Record "Transfer Line";
    begin
        SourceRecRef.SetTable(TransLine);
        ClearAll;
        SourceRecRef.GetTable(TransLine);

        TransLine.SetReservationEntry(ReservEntry, Direction);

        CaptionText := TransLine.GetSourceCaption;
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(101);
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [101, 102]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = 5741); // DATABASE::"Transfer Line"
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnSetReservSource', '', false, false)]
    local procedure OnSetReservSource(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text; Direction: Integer)
    begin
        if MatchThisTable(SourceRecRef.Number) then
            SetReservSourceFor(SourceRecRef, ReservEntry, CaptionText, Direction);
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnDrillDownTotalQuantity', '', false, false)]
    local procedure OnDrillDownTotalQuantity(SourceRecRef: RecordRef; ReservEntry: Record "Reservation Entry"; EntrySummary: Record "Entry Summary"; Location: Record Location; MaxQtyToReserve: Decimal)
    var
        AvailableTransferLines: page "Available - Transfer Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailableTransferLines);
            AvailableTransferLines.SetSource(SourceRecRef, ReservEntry, ReservEntry."Source Subtype");
            AvailableTransferLines.RunModal;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Transfer Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Transfer Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(TransferLine);
            CreateReservation(TransferLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry, ForReservEntry."Source Subtype");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure MyProcedure(SourceType: Integer; SourceID: Code[20])
    var
        TransHeader: Record "Transfer Header";
    begin
        if MatchThisTable(SourceType) then begin
            TransHeader.Reset();
            TransHeader.SetRange("No.", SourceID);
            PAGE.RunModal(PAGE::"Transfer Order", TransHeader);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; Direction: Integer; var CaptionText: Text)
    var
        TransferLine: Record "Transfer Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(TransferLine);
            TransferLine.SetReservationFilters(ReservEntry, Direction);
            CaptionText := TransferLine.GetSourceCaption;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(TransferLine);
            TransferLine.GetRemainingQty(RemainingQty, RemainingQtyBase, ReservEntry."Source Subtype");
        end;
    end;

    local procedure GetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        TransLine: Record "Transfer Line";
    begin
        TransLine.Get(ReservEntry."Source ID", ReservEntry."Source Ref. No.");
        SourceRecRef.GetTable(TransLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(TransLine."Outstanding Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(TransLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; Direction: Option; Positive: Boolean; var TotalQuantity: Decimal)
    var
        TransLine: Record "Transfer Line";
        AvailabilityFilter: Text;
    begin
        if not TransLine.ReadPermission then
            exit;

        AvailabilityFilter := CalcReservEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        case Direction of
            0: // Outbound
                TransLine.FilterOutboundLinesForReservation(CalcReservEntry, AvailabilityFilter, Positive);
            1: // Inbound
                TransLine.FilterInboundLinesForReservation(CalcReservEntry, AvailabilityFilter, Positive);
        end;
        if TransLine.FindSet then
            repeat
                case Direction of
                    0:
                        begin
                            TransLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                            TempEntrySummary."Total Reserved Quantity" -= TransLine."Reserved Qty. Outbnd. (Base)";
                            TotalQuantity -= TransLine."Outstanding Qty. (Base)";
                        end;
                    1:
                        begin
                            TransLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                            TempEntrySummary."Total Reserved Quantity" += TransLine."Reserved Qty. Inbnd. (Base)";
                            TotalQuantity += TransLine."Outstanding Qty. (Base)";
                        end;
                end;
            until TransLine.Next = 0;

        if TotalQuantity = 0 then
            exit;

        with TempEntrySummary do
            if (TotalQuantity > 0) = Positive then begin
                "Table ID" := DATABASE::"Transfer Line";
                "Summary Type" :=
                    CopyStr(
                    StrSubstNo('%1, %2', TransLine.TableCaption, SelectStr(Direction + 1, Text006)),
                    1, MaxStrLen("Summary Type"));
                "Total Quantity" := TotalQuantity;
                "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                if not Insert() then
                    Modify;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [101, 102] then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, ReservSummEntry."Entry No." - 101, Positive, TotalQuantity);
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
    local procedure OnTransferTransferToItemJnlLineTransferFields(var ReservationEntry: Record "Reservation Entry"; var TransferLine: Record "Transfer Line"; var ItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal; Direction: Enum "Transfer Direction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewTransLine: Record "Transfer Line"; OldTransLine: Record "Transfer Line"; var HasErrorInbnd: Boolean; var HasErrorOutbnd: Boolean; var ShowErrorInbnd: Boolean; var ShowErrorOutbnd: Boolean)
    begin
    end;
}

