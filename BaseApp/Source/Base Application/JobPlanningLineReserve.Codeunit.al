codeunit 1032 "Job Planning Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Planning Assignment" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Reserved quantity cannot be greater than %1.';
        Text002: Label 'must be filled in when a quantity is reserved', Comment = 'starts with "Planning Date"';
        Text004: Label 'must not be changed when a quantity is reserved', Comment = 'starts with some field name';
        Text005: Label 'Codeunit is not initialized correctly.';
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservMgt: Codeunit "Reservation Management";
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

    procedure CreateReservation(JobPlanningLine: Record "Job Planning Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        PlanningDate: Date;
        SignFactor: Integer;
    begin
        if SetFromType = 0 then
            Error(Text005);

        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.TestField("No.");
        JobPlanningLine.TestField("Planning Date");

        JobPlanningLine.CalcFields("Reserved Qty. (Base)");
        CheckReservedQtyBase(JobPlanningLine, QuantityBase);

        JobPlanningLine.TestField("Variant Code", SetFromVariantCode);
        JobPlanningLine.TestField("Location Code", SetFromLocationCode);

        SignFactor := -1;

        if QuantityBase * SignFactor < 0 then
            PlanningDate := JobPlanningLine."Planning Date"
        else begin
            PlanningDate := ExpectedReceiptDate;
            ExpectedReceiptDate := JobPlanningLine."Planning Date";
        end;

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Job Planning Line", JobPlanningLine.Status,
          JobPlanningLine."Job No.", '', 0, JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForSerialNo, ForLotNo);
        CreateReservEntry.CreateReservEntryFrom(
          SetFromType, SetFromSubtype, SetFromID, SetFromBatchName, SetFromProdOrderLine, SetFromRefNo,
          SetFromQtyPerUOM, SetFromSerialNo, SetFromLotNo);
        CreateReservEntry.CreateReservEntry(
          JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Location Code",
          Description, ExpectedReceiptDate, PlanningDate);

        SetFromType := 0;
    end;

    local procedure CreateBindingReservation(JobPlanningLine: Record "Job Planning Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    begin
        CreateReservation(JobPlanningLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, '', '');
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

    local procedure CheckReservedQtyBase(JobPlanningLine: Record "Job Planning Line"; QuantityBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReservedQtyBase(JobPlanningLine, IsHandled);
        if IsHandled then
            exit;

        if Abs(JobPlanningLine."Remaining Qty. (Base)") < Abs(JobPlanningLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(JobPlanningLine."Remaining Qty. (Base)") - Abs(JobPlanningLine."Reserved Qty. (Base)"));
    end;

    procedure SetBinding(Binding: Option " ","Order-to-Order")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; JobPlanningLine: Record "Job Planning Line")
    begin
        FilterReservEntry.SetSourceFilter(
          DATABASE::"Job Planning Line", JobPlanningLine.Status, JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", false);
        FilterReservEntry.SetSourceFilter('', 0);
    end;

    procedure ReservQuantity(JobPlanningLine: Record "Job Planning Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
        case JobPlanningLine.Status of
            JobPlanningLine.Status::Planning,
            JobPlanningLine.Status::Quote,
            JobPlanningLine.Status::Order,
            JobPlanningLine.Status::Completed:
                begin
                    QtyToReserve := JobPlanningLine."Remaining Qty.";
                    QtyToReserveBase := JobPlanningLine."Remaining Qty. (Base)";
                end;
        end;

        OnAfterReservQuantity(JobPlanningLine, QtyToReserve, QtyToReserveBase);
    end;

    procedure Caption(JobPlanningLine: Record "Job Planning Line") CaptionText: Text
    begin
        CaptionText :=
          StrSubstNo('%1 %2 %3', JobPlanningLine.Status, JobPlanningLine."Job No.", JobPlanningLine."No.");
    end;

    procedure FindReservEntry(JobPlanningLine: Record "Job Planning Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, JobPlanningLine);
        exit(ReservEntry.FindLast);
    end;

    procedure VerifyChange(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        ReservEntry: Record "Reservation Entry";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if (NewJobPlanningLine.Type <> NewJobPlanningLine.Type::Item) and (OldJobPlanningLine.Type <> OldJobPlanningLine.Type::Item) then
            exit;
        if NewJobPlanningLine."Job Contract Entry No." = 0 then
            if not JobPlanningLine.Get(
                 NewJobPlanningLine."Job No.",
                 NewJobPlanningLine."Job Task No.",
                 NewJobPlanningLine."Line No.")
            then
                exit;

        NewJobPlanningLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewJobPlanningLine."Reserved Qty. (Base)" <> 0;

        if NewJobPlanningLine."Usage Link" <> OldJobPlanningLine."Usage Link" then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Usage Link", Text004);
            HasError := true;
        end;

        if (NewJobPlanningLine."Planning Date" = 0D) and (OldJobPlanningLine."Planning Date" <> 0D) then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Planning Date", Text002);
            HasError := true;
        end;

        if NewJobPlanningLine."No." <> OldJobPlanningLine."No." then begin
            if ShowError then
                NewJobPlanningLine.FieldError("No.", Text004);
            HasError := true;
        end;

        if NewJobPlanningLine."Variant Code" <> OldJobPlanningLine."Variant Code" then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Variant Code", Text004);
            HasError := true;
        end;

        if NewJobPlanningLine."Location Code" <> OldJobPlanningLine."Location Code" then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Location Code", Text004);
            HasError := true;
        end;

        if NewJobPlanningLine."Bin Code" <> OldJobPlanningLine."Bin Code" then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Bin Code", Text004);
            HasError := true;
        end;

        if NewJobPlanningLine."Line No." <> OldJobPlanningLine."Line No." then
            HasError := true;

        if NewJobPlanningLine.Type <> OldJobPlanningLine.Type then begin
            if ShowError then
                NewJobPlanningLine.FieldError(Type, Text004);
            HasError := true;
        end;

        if HasError then
            if (NewJobPlanningLine."No." <> OldJobPlanningLine."No.") or
               FindReservEntry(NewJobPlanningLine, ReservEntry)
            then begin
                if (NewJobPlanningLine."No." <> OldJobPlanningLine."No.") or (NewJobPlanningLine.Type <> OldJobPlanningLine.Type) then begin
                    ReservMgt.SetJobPlanningLine(OldJobPlanningLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetJobPlanningLine(NewJobPlanningLine);
                end else begin
                    ReservMgt.SetJobPlanningLine(NewJobPlanningLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewJobPlanningLine."Remaining Qty. (Base)");
            end;

        if HasError or (NewJobPlanningLine."Planning Date" <> OldJobPlanningLine."Planning Date")
        then begin
            AssignForPlanning(NewJobPlanningLine);
            if (NewJobPlanningLine."No." <> OldJobPlanningLine."No.") or
               (NewJobPlanningLine."Variant Code" <> OldJobPlanningLine."Variant Code") or
               (NewJobPlanningLine."Location Code" <> OldJobPlanningLine."Location Code")
            then
                AssignForPlanning(OldJobPlanningLine);
        end;
    end;

    procedure VerifyQuantity(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        with NewJobPlanningLine do begin
            if Type <> Type::Item then
                exit;
            if Status = OldJobPlanningLine.Status then
                if "Line No." = OldJobPlanningLine."Line No." then
                    if "Quantity (Base)" = OldJobPlanningLine."Quantity (Base)" then
                        exit;
            if "Line No." = 0 then
                if not JobPlanningLine.Get("Job No.", "Job Task No.", "Line No.") then
                    exit;
            ReservMgt.SetJobPlanningLine(NewJobPlanningLine);
            if "Qty. per Unit of Measure" <> OldJobPlanningLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            if "Remaining Qty. (Base)" * OldJobPlanningLine."Remaining Qty. (Base)" < 0 then
                ReservMgt.DeleteReservEntries(true, 0)
            else
                ReservMgt.DeleteReservEntries(false, "Remaining Qty. (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Remaining Qty. (Base)");
            AssignForPlanning(NewJobPlanningLine);
        end;
    end;

    procedure TransferJobLineToItemJnlLine(var JobPlanningLine: Record "Job Planning Line"; var NewItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal): Decimal
    var
        OldReservEntry: Record "Reservation Entry";
        ItemTrackingFilterIsSet: Boolean;
        EndLoop: Boolean;
        TrackedQty: Decimal;
        UnTrackedQty: Decimal;
        xTransferQty: Decimal;
    begin
        if not FindReservEntry(JobPlanningLine, OldReservEntry) then
            exit(TransferQty);

        // Store initial values
        OldReservEntry.CalcSums("Quantity (Base)");
        TrackedQty := -OldReservEntry."Quantity (Base)";
        xTransferQty := TransferQty;

        OldReservEntry.Lock;

        // Handle Item Tracking on job planning line:
        Clear(CreateReservEntry);
        if NewItemJnlLine."Entry Type" = NewItemJnlLine."Entry Type"::"Negative Adjmt." then
            if NewItemJnlLine.TrackingExists then begin
                CreateReservEntry.SetNewSerialLotNo(NewItemJnlLine."Serial No.", NewItemJnlLine."Lot No.");
                // Try to match against Item Tracking on the job planning line:
                OldReservEntry.SetTrackingFilterFromItemJnlLine(NewItemJnlLine);
                if OldReservEntry.IsEmpty then
                    OldReservEntry.ClearTrackingFilter
                else
                    ItemTrackingFilterIsSet := true;
            end;

        NewItemJnlLine.TestItemFields(JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ReservEngineMgt.InitRecordSet(OldReservEntry, NewItemJnlLine."Serial No.", NewItemJnlLine."Lot No.") then
            repeat
                OldReservEntry.TestItemFields(JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Location Code");

                TransferQty :=
                  CreateReservEntry.TransferReservEntry(DATABASE::"Item Journal Line",
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

        // Handle remaining transfer quantity
        if TransferQty <> 0 then begin
            TrackedQty -= (xTransferQty - TransferQty);
            UnTrackedQty := JobPlanningLine."Remaining Qty. (Base)" - TrackedQty;
            if TransferQty > UnTrackedQty then begin
                ReservMgt.SetJobPlanningLine(JobPlanningLine);
                ReservMgt.DeleteReservEntries(false, JobPlanningLine."Remaining Qty. (Base)");
            end;
        end;
        exit(TransferQty);
    end;

    procedure DeleteLine(var JobPlanningLine: Record "Job Planning Line")
    begin
        with JobPlanningLine do begin
            ReservMgt.SetJobPlanningLine(JobPlanningLine);
            ReservMgt.DeleteReservEntries(true, 0);
            CalcFields("Reserved Qty. (Base)");
            AssignForPlanning(JobPlanningLine);
        end;
    end;

    local procedure AssignForPlanning(var JobPlanningLine: Record "Job Planning Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        with JobPlanningLine do begin
            if Status <> Status::Order then
                exit;
            if Type <> Type::Item then
                exit;
            if "No." <> '' then
                PlanningAssignment.ChkAssignOne("No.", "Variant Code", "Location Code", "Planning Date");
        end;
    end;

    procedure BindToPurchase(JobPlanningLine: Record "Job Planning Line"; PurchLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", '', 0, PurchLine."Line No.",
          PurchLine."Variant Code", PurchLine."Location Code", PurchLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(JobPlanningLine, PurchLine.Description, PurchLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToRequisition(JobPlanningLine: Record "Job Planning Line"; ReqLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Requisition Line",
          0, ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name", 0, ReqLine."Line No.",
          ReqLine."Variant Code", ReqLine."Location Code", ReqLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(JobPlanningLine, ReqLine.Description, ReqLine."Due Date", ReservQty, ReservQtyBase);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReservQuantity(JobPlanningLine: Record "Job Planning Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReservedQtyBase(JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;
}

