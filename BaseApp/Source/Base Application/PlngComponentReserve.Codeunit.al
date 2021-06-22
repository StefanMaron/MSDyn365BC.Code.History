codeunit 99000840 "Plng. Component-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Action Message Entry" = rd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Reserved quantity cannot be greater than %1.';
        Text002: Label 'must be filled in when a quantity is reserved';
        Text003: Label 'must not be changed when a quantity is reserved';
        Text004: Label 'Codeunit is not initialized correctly.';
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservMgt: Codeunit "Reservation Management";
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

    procedure CreateReservation(PlanningComponent: Record "Planning Component"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ShipmentDate: Date;
    begin
        if SetFromType = 0 then
            Error(Text004);

        PlanningComponent.TestField("Item No.");
        PlanningComponent.TestField("Due Date");

        if Abs(PlanningComponent."Net Quantity (Base)") < Abs(PlanningComponent."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(PlanningComponent."Net Quantity (Base)") - Abs(PlanningComponent."Reserved Qty. (Base)"));

        PlanningComponent.TestField("Location Code", SetFromLocationCode);
        PlanningComponent.TestField("Variant Code", SetFromVariantCode);

        if QuantityBase > 0 then
            ShipmentDate := PlanningComponent."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := PlanningComponent."Due Date";
        end;

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Planning Component", 0,
          PlanningComponent."Worksheet Template Name", PlanningComponent."Worksheet Batch Name",
          PlanningComponent."Worksheet Line No.", PlanningComponent."Line No.",
          PlanningComponent."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForSerialNo, ForLotNo);
        CreateReservEntry.CreateReservEntryFrom(
          SetFromType, SetFromSubtype, SetFromID, SetFromBatchName, SetFromProdOrderLine, SetFromRefNo,
          SetFromQtyPerUOM, SetFromSerialNo, SetFromLotNo);
        CreateReservEntry.CreateReservEntry(
          PlanningComponent."Item No.", PlanningComponent."Variant Code", PlanningComponent."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate);

        SetFromType := 0;
    end;

    local procedure CreateBindingReservation(PlanningComponent: Record "Planning Component"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    begin
        CreateReservation(PlanningComponent, Description, ExpectedReceiptDate, Quantity, QuantityBase, '', '');
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

    procedure SetBinding(Binding: Option " ","Order-to-Order")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; PlanningComponent: Record "Planning Component")
    begin
        FilterReservEntry.SetSourceFilter(
          DATABASE::"Planning Component", 0, PlanningComponent."Worksheet Template Name", PlanningComponent."Line No.", false);
        FilterReservEntry.SetSourceFilter(PlanningComponent."Worksheet Batch Name", PlanningComponent."Worksheet Line No.");
    end;

    procedure Caption(PlanningComponent: Record "Planning Component") CaptionText: Text
    var
        ReqLine: Record "Requisition Line";
    begin
        ReqLine.Get(
          PlanningComponent."Worksheet Template Name",
          PlanningComponent."Worksheet Batch Name",
          PlanningComponent."Worksheet Line No.");
        CaptionText :=
          StrSubstNo('%1 %2 %3 %4',
            PlanningComponent."Worksheet Template Name",
            PlanningComponent."Worksheet Batch Name",
            ReqLine.Type,
            ReqLine."No.");
    end;

    procedure FindReservEntry(PlanningComponent: Record "Planning Component"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, PlanningComponent);
        exit(ReservEntry.FindLast);
    end;

    procedure VerifyChange(var NewPlanningComponent: Record "Planning Component"; var OldPlanningComponent: Record "Planning Component")
    var
        PlanningComponent: Record "Planning Component";
        TempReservEntry: Record "Reservation Entry";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if Blocked then
            exit;
        if NewPlanningComponent."Line No." = 0 then
            if not PlanningComponent.Get(
                 NewPlanningComponent."Worksheet Template Name",
                 NewPlanningComponent."Worksheet Batch Name",
                 NewPlanningComponent."Worksheet Line No.",
                 NewPlanningComponent."Line No.")
            then
                exit;

        NewPlanningComponent.CalcFields("Reserved Qty. (Base)");
        ShowError := NewPlanningComponent."Reserved Qty. (Base)" <> 0;

        if NewPlanningComponent."Due Date" = 0D then
            if ShowError then
                NewPlanningComponent.FieldError("Due Date", Text002);
        HasError := true;
        if NewPlanningComponent."Item No." <> OldPlanningComponent."Item No." then
            if ShowError then
                NewPlanningComponent.FieldError("Item No.", Text003);
        HasError := true;
        if NewPlanningComponent."Location Code" <> OldPlanningComponent."Location Code" then
            if ShowError then
                NewPlanningComponent.FieldError("Location Code", Text003);
        HasError := true;
        if (NewPlanningComponent."Bin Code" <> OldPlanningComponent."Bin Code") and
           (not ReservMgt.CalcIsAvailTrackedQtyInBin(
              NewPlanningComponent."Item No.", NewPlanningComponent."Bin Code",
              NewPlanningComponent."Location Code", NewPlanningComponent."Variant Code",
              DATABASE::"Planning Component", 0,
              NewPlanningComponent."Worksheet Template Name",
              NewPlanningComponent."Worksheet Batch Name", NewPlanningComponent."Worksheet Line No.",
              NewPlanningComponent."Line No."))
        then begin
            if ShowError then
                NewPlanningComponent.FieldError("Bin Code", Text003);
            HasError := true;
        end;
        if NewPlanningComponent."Variant Code" <> OldPlanningComponent."Variant Code" then
            if ShowError then
                NewPlanningComponent.FieldError("Variant Code", Text003);
        HasError := true;
        if NewPlanningComponent."Line No." <> OldPlanningComponent."Line No." then
            HasError := true;

        OnVerifyChangeOnBeforeHasError(NewPlanningComponent, OldPlanningComponent, HasError, ShowError);

        if HasError then
            if (NewPlanningComponent."Item No." <> OldPlanningComponent."Item No.") or
               FindReservEntry(NewPlanningComponent, TempReservEntry)
            then begin
                if NewPlanningComponent."Item No." <> OldPlanningComponent."Item No." then begin
                    ReservMgt.SetPlanningComponent(OldPlanningComponent);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetPlanningComponent(NewPlanningComponent);
                end else begin
                    ReservMgt.SetPlanningComponent(NewPlanningComponent);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewPlanningComponent."Net Quantity (Base)");
            end;

        if HasError or (NewPlanningComponent."Due Date" <> OldPlanningComponent."Due Date") then begin
            AssignForPlanning(NewPlanningComponent);
            if (NewPlanningComponent."Item No." <> OldPlanningComponent."Item No.") or
               (NewPlanningComponent."Variant Code" <> OldPlanningComponent."Variant Code") or
               (NewPlanningComponent."Location Code" <> OldPlanningComponent."Location Code")
            then
                AssignForPlanning(OldPlanningComponent);
        end;
    end;

    procedure VerifyQuantity(var NewPlanningComponent: Record "Planning Component"; var OldPlanningComponent: Record "Planning Component")
    var
        PlanningComponent: Record "Planning Component";
    begin
        if Blocked then
            exit;

        with NewPlanningComponent do begin
            if "Line No." = OldPlanningComponent."Line No." then
                if "Net Quantity (Base)" = OldPlanningComponent."Net Quantity (Base)" then
                    exit;
            if "Line No." = 0 then
                if not PlanningComponent.Get(
                     "Worksheet Template Name",
                     "Worksheet Batch Name",
                     "Worksheet Line No.",
                     "Line No.")
                then
                    exit;
            ReservMgt.SetPlanningComponent(NewPlanningComponent);
            if "Qty. per Unit of Measure" <> OldPlanningComponent."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            if "Net Quantity (Base)" * OldPlanningComponent."Net Quantity (Base)" < 0 then
                ReservMgt.DeleteReservEntries(true, 0)
            else
                ReservMgt.DeleteReservEntries(false, "Net Quantity (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Net Quantity (Base)");
            AssignForPlanning(NewPlanningComponent);
        end;
    end;

    procedure TransferPlanningCompToPOComp(var OldPlanningComponent: Record "Planning Component"; var NewProdOrderComp: Record "Prod. Order Component"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(OldPlanningComponent, OldReservEntry) then
            exit;

        NewProdOrderComp.TestItemFields(
          OldPlanningComponent."Item No.", OldPlanningComponent."Variant Code", OldPlanningComponent."Location Code");

        TransferReservations(
          OldPlanningComponent, OldReservEntry, TransferAll, TransferQty, NewProdOrderComp."Qty. per Unit of Measure",
          DATABASE::"Prod. Order Component", NewProdOrderComp.Status, NewProdOrderComp."Prod. Order No.",
          '', NewProdOrderComp."Prod. Order Line No.", NewProdOrderComp."Line No.");
    end;

    procedure TransferPlanningCompToAsmLine(var OldPlanningComponent: Record "Planning Component"; var NewAsmLine: Record "Assembly Line"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(OldPlanningComponent, OldReservEntry) then
            exit;

        NewAsmLine.TestItemFields(
          OldPlanningComponent."Item No.", OldPlanningComponent."Variant Code", OldPlanningComponent."Location Code");

        TransferReservations(
          OldPlanningComponent, OldReservEntry, TransferAll, TransferQty, NewAsmLine."Qty. per Unit of Measure",
          DATABASE::"Assembly Line", NewAsmLine."Document Type", NewAsmLine."Document No.",
          '', 0, NewAsmLine."Line No.");
    end;

    local procedure TransferReservations(var OldPlanningComponent: Record "Planning Component"; var OldReservEntry: Record "Reservation Entry"; TransferAll: Boolean; TransferQty: Decimal; QtyPerUOM: Decimal; SrcType: Integer; SrcSubtype: Option; SrcID: Code[20]; SrcBatchName: Code[10]; SrcProdOrderLine: Integer; SrcRefNo: Integer)
    var
        NewReservEntry: Record "Reservation Entry";
        Status: Option Reservation,Tracking,Surplus,Prospect;
    begin
        OldReservEntry.Lock;

        if TransferAll then begin
            OldReservEntry.FindSet;
            OldReservEntry.TestField("Qty. per Unit of Measure", QtyPerUOM);

            repeat
                OldReservEntry.TestItemFields(
                  OldPlanningComponent."Item No.", OldPlanningComponent."Variant Code", OldPlanningComponent."Location Code");

                NewReservEntry := OldReservEntry;
                NewReservEntry.SetSource(SrcType, SrcSubtype, SrcID, SrcRefNo, SrcBatchName, SrcProdOrderLine);
                NewReservEntry.Modify;
            until OldReservEntry.Next = 0;
        end else
            for Status := Status::Reservation to Status::Prospect do begin
                if TransferQty = 0 then
                    exit;
                OldReservEntry.SetRange("Reservation Status", Status);

                if OldReservEntry.FindSet then
                    repeat
                        OldReservEntry.TestItemFields(
                          OldPlanningComponent."Item No.", OldPlanningComponent."Variant Code", OldPlanningComponent."Location Code");

                        TransferQty :=
                          CreateReservEntry.TransferReservEntry(
                            SrcType, SrcSubtype, SrcID, SrcBatchName, SrcProdOrderLine, SrcRefNo, QtyPerUOM, OldReservEntry, TransferQty);
                    until (OldReservEntry.Next = 0) or (TransferQty = 0);
            end;
    end;

    procedure DeleteLine(var PlanningComponent: Record "Planning Component")
    begin
        if Blocked then
            exit;

        with PlanningComponent do begin
            ReservMgt.SetPlanningComponent(PlanningComponent);
            ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            CalcFields("Reserved Qty. (Base)");
            AssignForPlanning(PlanningComponent);
        end;
    end;

    procedure UpdateDerivedTracking(var PlanningComponent: Record "Planning Component")
    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ActionMessageEntry: Record "Action Message Entry";
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        ActionMessageEntry.SetCurrentKey("Reservation Entry");

        with ReservEntry do begin
            SetFilter("Shipment Date", '<>%1', PlanningComponent."Due Date");
            case PlanningComponent."Ref. Order Type" of
                PlanningComponent."Ref. Order Type"::"Prod. Order":
                    SetSourceFilter(
                      DATABASE::"Prod. Order Component", PlanningComponent."Ref. Order Status",
                      PlanningComponent."Ref. Order No.", PlanningComponent."Line No.", false);
                PlanningComponent."Ref. Order Type"::Assembly:
                    SetSourceFilter(
                      DATABASE::"Assembly Line", PlanningComponent."Ref. Order Status",
                      PlanningComponent."Ref. Order No.", PlanningComponent."Line No.", false);
            end;
            SetRange("Source Prod. Order Line", PlanningComponent."Ref. Order Line No.");
            if FindSet then
                repeat
                    ReservEntry2 := ReservEntry;
                    ReservEntry2."Shipment Date" := PlanningComponent."Due Date";
                    ReservEntry2.Modify;
                    if ReservEntry2.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive) then begin
                        ReservEntry2."Shipment Date" := PlanningComponent."Due Date";
                        ReservEntry2.Modify;
                    end;
                    ActionMessageEntry.SetRange("Reservation Entry", "Entry No.");
                    ActionMessageEntry.DeleteAll;
                until Next = 0;
        end;
    end;

    local procedure AssignForPlanning(var PlanningComponent: Record "Planning Component")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        with PlanningComponent do
            if "Item No." <> '' then
                PlanningAssignment.ChkAssignOne("Item No.", "Variant Code", "Location Code", "Due Date");
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var PlanningComponent: Record "Planning Component")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromProdPlanningComp(PlanningComponent);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, PlanningComponent."Due Date");
        ItemTrackingLines.RunModal;

        OnAfterCallItemTracking(PlanningComponent);
    end;

    procedure BindToRequisition(PlanningComp: Record "Planning Component"; ReqLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Requisition Line", 0,
          ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name", 0, ReqLine."Line No.",
          ReqLine."Variant Code", ReqLine."Location Code", ReqLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(PlanningComp, ReqLine.Description, ReqLine."Ending Date", ReservQty, ReservQtyBase);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCallItemTracking(var PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewPlanningComponent: Record "Planning Component"; OldPlanningComponent: Record "Planning Component"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;
}

