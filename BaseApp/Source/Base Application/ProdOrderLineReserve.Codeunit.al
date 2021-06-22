codeunit 99000837 "Prod. Order Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Action Message Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Reserved quantity cannot be greater than %1';
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
        Text006: Label 'The %1 %2 %3 has item tracking. Do you want to delete it anyway?';
        Text007: Label 'The %1 %2 %3 has components with item tracking. Do you want to delete it anyway?';
        Text008: Label 'The %1 %2 %3 and its components have item tracking. Do you want to delete them anyway?';

    procedure CreateReservation(var ProdOrderLine: Record "Prod. Order Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ShipmentDate: Date;
    begin
        if SetFromType = 0 then
            Error(Text004);

        ProdOrderLine.TestField("Item No.");
        ProdOrderLine.TestField("Due Date");

        ProdOrderLine.CalcFields("Reserved Qty. (Base)");
        if Abs(ProdOrderLine."Remaining Qty. (Base)") < Abs(ProdOrderLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(ProdOrderLine."Remaining Qty. (Base)") - Abs(ProdOrderLine."Reserved Qty. (Base)"));

        ProdOrderLine.TestField("Location Code", SetFromLocationCode);
        ProdOrderLine.TestField("Variant Code", SetFromVariantCode);

        if QuantityBase < 0 then
            ShipmentDate := ProdOrderLine."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ProdOrderLine."Due Date";
        end;

        if ProdOrderLine."Planning Flexibility" <> ProdOrderLine."Planning Flexibility"::Unlimited then
            CreateReservEntry.SetPlanningFlexibility(ProdOrderLine."Planning Flexibility");

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Prod. Order Line", ProdOrderLine.Status,
          ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
          ProdOrderLine."Qty. per Unit of Measure", Quantity, QuantityBase, ForSerialNo, ForLotNo);
        CreateReservEntry.CreateReservEntryFrom(
          SetFromType, SetFromSubtype, SetFromID, SetFromBatchName, SetFromProdOrderLine, SetFromRefNo,
          SetFromQtyPerUOM, SetFromSerialNo, SetFromLotNo);
        CreateReservEntry.CreateReservEntry(
          ProdOrderLine."Item No.", ProdOrderLine."Variant Code", ProdOrderLine."Location Code",
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

    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; ProdOrderLine: Record "Prod. Order Line")
    begin
        FilterReservEntry.SetSourceFilter(DATABASE::"Prod. Order Line", ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", 0, false);
        FilterReservEntry.SetSourceFilter('', ProdOrderLine."Line No.");
    end;

    procedure Caption(ProdOrderLine: Record "Prod. Order Line") CaptionText: Text
    begin
        CaptionText :=
          StrSubstNo('%1 %2 %3 %4',
            ProdOrderLine.Status, ProdOrderLine.TableCaption, ProdOrderLine."Prod. Order No.", ProdOrderLine."Item No.");
    end;

    procedure FindReservEntry(ProdOrderLine: Record "Prod. Order Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, ProdOrderLine);
        exit(ReservEntry.FindLast);
    end;

    procedure VerifyChange(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderLine: Record "Prod. Order Line";
        TempReservEntry: Record "Reservation Entry";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if NewProdOrderLine.Status = NewProdOrderLine.Status::Finished then
            exit;
        if Blocked then
            exit;
        if NewProdOrderLine."Line No." = 0 then
            if not ProdOrderLine.Get(
                 NewProdOrderLine.Status,
                 NewProdOrderLine."Prod. Order No.",
                 NewProdOrderLine."Line No.")
            then
                exit;

        NewProdOrderLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewProdOrderLine."Reserved Qty. (Base)" <> 0;

        if NewProdOrderLine."Due Date" = 0D then
            if ShowError then
                NewProdOrderLine.FieldError("Due Date", Text002)
            else
                HasError := true;

        if NewProdOrderLine."Item No." <> OldProdOrderLine."Item No." then
            if ShowError then
                NewProdOrderLine.FieldError("Item No.", Text003)
            else
                HasError := true;
        if NewProdOrderLine."Location Code" <> OldProdOrderLine."Location Code" then
            if ShowError then
                NewProdOrderLine.FieldError("Location Code", Text003)
            else
                HasError := true;
        if NewProdOrderLine."Variant Code" <> OldProdOrderLine."Variant Code" then
            if ShowError then
                NewProdOrderLine.FieldError("Variant Code", Text003)
            else
                HasError := true;
        if NewProdOrderLine."Line No." <> OldProdOrderLine."Line No." then
            HasError := true;

        OnVerifyChangeOnBeforeHasError(NewProdOrderLine, OldProdOrderLine, HasError, ShowError);

        if HasError then
            if (NewProdOrderLine."Item No." <> OldProdOrderLine."Item No.") or
               FindReservEntry(NewProdOrderLine, TempReservEntry)
            then begin
                if NewProdOrderLine."Item No." <> OldProdOrderLine."Item No." then begin
                    ReservMgt.SetProdOrderLine(OldProdOrderLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetProdOrderLine(NewProdOrderLine);
                end else begin
                    ReservMgt.SetProdOrderLine(NewProdOrderLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewProdOrderLine."Remaining Qty. (Base)");
            end;

        if HasError or (NewProdOrderLine."Due Date" <> OldProdOrderLine."Due Date")
        then begin
            AssignForPlanning(NewProdOrderLine);
            if (NewProdOrderLine."Item No." <> OldProdOrderLine."Item No.") or
               (NewProdOrderLine."Variant Code" <> OldProdOrderLine."Variant Code") or
               (NewProdOrderLine."Location Code" <> OldProdOrderLine."Location Code")
            then
                AssignForPlanning(OldProdOrderLine);
        end;
    end;

    procedure VerifyQuantity(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if Blocked then
            exit;

        with NewProdOrderLine do begin
            if Status = Status::Finished then
                exit;
            if "Line No." = OldProdOrderLine."Line No." then
                if "Quantity (Base)" = OldProdOrderLine."Quantity (Base)" then
                    exit;
            if "Line No." = 0 then
                if not ProdOrderLine.Get(Status, "Prod. Order No.", "Line No.") then
                    exit;
            ReservMgt.SetProdOrderLine(NewProdOrderLine);
            if "Qty. per Unit of Measure" <> OldProdOrderLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            ReservMgt.DeleteReservEntries(false, "Remaining Qty. (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Remaining Qty. (Base)");
            AssignForPlanning(NewProdOrderLine);
        end;
    end;

    procedure UpdatePlanningFlexibility(var ProdOrderLine: Record "Prod. Order Line")
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if FindReservEntry(ProdOrderLine, ReservEntry) then
            ReservEntry.ModifyAll("Planning Flexibility", ProdOrderLine."Planning Flexibility");
    end;

    procedure TransferPOLineToPOLine(var OldProdOrderLine: Record "Prod. Order Line"; var NewProdOrderLine: Record "Prod. Order Line"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservEntry: Record "Reservation Entry";
    begin
        OnBeforeTransferPOLineToPOLine(OldProdOrderLine, NewProdOrderLine);

        if not FindReservEntry(OldProdOrderLine, OldReservEntry) then
            exit;

        OldReservEntry.Lock;

        NewProdOrderLine.TestItemFields(OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code");

        OldReservEntry.TransferReservations(
          OldReservEntry, OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code",
          TransferAll, TransferQty, NewProdOrderLine."Qty. per Unit of Measure",
          DATABASE::"Prod. Order Line", NewProdOrderLine.Status, NewProdOrderLine."Prod. Order No.", '', NewProdOrderLine."Line No.", 0);
    end;

    procedure TransferPOLineToItemJnlLine(var OldProdOrderLine: Record "Prod. Order Line"; var NewItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal)
    var
        OldReservEntry: Record "Reservation Entry";
        ItemTrackingFilterIsSet: Boolean;
        EndLoop: Boolean;
    begin
        if not FindReservEntry(OldProdOrderLine, OldReservEntry) then
            exit;

        OldReservEntry.Lock;

        // Handle Item Tracking on output:
        Clear(CreateReservEntry);
        if NewItemJnlLine."Entry Type" = NewItemJnlLine."Entry Type"::Output then
            if NewItemJnlLine.TrackingExists then begin
                // Try to match against Item Tracking on the prod. order line:
                OldReservEntry.SetTrackingFilterFromItemJnlLine(NewItemJnlLine);
                if OldReservEntry.IsEmpty then
                    OldReservEntry.ClearTrackingFilter
                else
                    ItemTrackingFilterIsSet := true;
            end;

        NewItemJnlLine.TestItemFields(OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ReservEngineMgt.InitRecordSet(OldReservEntry) then
            repeat
                if NewItemJnlLine.TrackingExists then
                    CreateReservEntry.SetNewSerialLotNo(NewItemJnlLine."Serial No.", NewItemJnlLine."Lot No.");
                OldReservEntry.TestItemFields(OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code");

                TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Item Journal Line",
                    NewItemJnlLine."Entry Type", NewItemJnlLine."Journal Template Name", NewItemJnlLine."Journal Batch Name", 0,
                    NewItemJnlLine."Line No.", NewItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

                if ReservEngineMgt.NEXTRecord(OldReservEntry) = 0 then
                    if ItemTrackingFilterIsSet then begin
                        OldReservEntry.ClearTrackingFilter;
                        ItemTrackingFilterIsSet := false;
                        EndLoop := not ReservEngineMgt.InitRecordSet(OldReservEntry);
                    end else
                        EndLoop := true;

            until EndLoop or (TransferQty = 0);
    end;

    procedure DeleteLineConfirm(var ProdOrderLine: Record "Prod. Order Line"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ConfirmMessage: Text[250];
        HasItemTracking: Option "None",Line,Components,"Line and Components";
    begin
        with ReservEntry do begin
            FilterReservFor(ReservEntry, ProdOrderLine);
            SetFilter("Item Tracking", '<> %1', "Item Tracking"::None);
            if not IsEmpty then
                HasItemTracking := HasItemTracking::Line;

            SetRange("Source Type", DATABASE::"Prod. Order Component");
            SetFilter("Source Ref. No.", ' > %1', 0);
            if not IsEmpty then
                if HasItemTracking = HasItemTracking::Line then
                    HasItemTracking := HasItemTracking::"Line and Components"
                else
                    HasItemTracking := HasItemTracking::Components;

            if HasItemTracking = HasItemTracking::None then
                exit(true);

            case HasItemTracking of
                HasItemTracking::Line:
                    ConfirmMessage := Text006;
                HasItemTracking::Components:
                    ConfirmMessage := Text007;
                HasItemTracking::"Line and Components":
                    ConfirmMessage := Text008;
            end;

            if not Confirm(ConfirmMessage, false, ProdOrderLine.Status, ProdOrderLine.TableCaption, ProdOrderLine."Line No.") then
                exit(false);

            SetFilter("Source Type", '%1|%2', DATABASE::"Prod. Order Line", DATABASE::"Prod. Order Component");
            SetRange("Source Ref. No.");
            if FindSet then
                repeat
                    ReservEntry2 := ReservEntry;
                    ReservEntry2.ClearItemTrackingFields;
                    ReservEntry2.Modify;
                until Next = 0;
        end;

        exit(true);
    end;

    procedure DeleteLine(var ProdOrderLine: Record "Prod. Order Line")
    begin
        if Blocked then
            exit;

        with ProdOrderLine do begin
            ReservMgt.SetProdOrderLine(ProdOrderLine);
            ReservMgt.DeleteReservEntries(true, 0);
            OnDeleteLineOnAfterDeleteReservEntries(ProdOrderLine);
            ReservMgt.ClearActionMessageReferences;
            CalcFields("Reserved Qty. (Base)");
            AssignForPlanning(ProdOrderLine);
        end;
    end;

    procedure AssignForPlanning(var ProdOrderLine: Record "Prod. Order Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        with ProdOrderLine do begin
            if Status = Status::Simulated then
                exit;
            if "Item No." <> '' then
                PlanningAssignment.ChkAssignOne("Item No.", "Variant Code", "Location Code", WorkDate);
        end;
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var ProdOrderLine: Record "Prod. Order Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        if ProdOrderLine.Status = ProdOrderLine.Status::Finished then
            ItemTrackingDocMgt.ShowItemTrackingForProdOrderComp(DATABASE::"Prod. Order Line",
              ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", 0)
        else begin
            ProdOrderLine.TestField("Item No.");
            TrackingSpecification.InitFromProdOrderLine(ProdOrderLine);
            ItemTrackingLines.SetSourceSpec(TrackingSpecification, ProdOrderLine."Due Date");
            ItemTrackingLines.SetInbound(ProdOrderLine.IsInbound);
            ItemTrackingLines.RunModal;
        end;

        OnAfterCallItemTracking(ProdOrderLine);
    end;

    procedure UpdateItemTrackingAfterPosting(ProdOrderLine: Record "Prod. Order Line")
    var
        ReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // Used for updating Quantity to Handle after posting;
        ReservEntry.SetSourceFilter(DATABASE::"Prod. Order Line", ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", -1, true);
        ReservEntry.SetSourceFilter('', ProdOrderLine."Line No.");
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCallItemTracking(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferPOLineToPOLine(var OldProdOrderLine: Record "Prod. Order Line"; var NewProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteLineOnAfterDeleteReservEntries(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewProdOrderLine: Record "Prod. Order Line"; OldProdOrderLine: Record "Prod. Order Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;
}

