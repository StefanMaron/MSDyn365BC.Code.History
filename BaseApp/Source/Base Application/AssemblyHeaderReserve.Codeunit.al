codeunit 925 "Assembly Header-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        SetFromType: Integer;
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
        Text000: Label 'Reserved quantity cannot be greater than %1.';
        Text001: Label 'Codeunit is not initialized correctly.';
        DeleteItemTracking: Boolean;
        Text002: Label 'must be filled in when a quantity is reserved', Comment = 'starts with "Due Date"';
        Text003: Label 'must not be changed when a quantity is reserved', Comment = 'starts with some field name';

    procedure CreateReservation(var AssemblyHeader: Record "Assembly Header"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ShipmentDate: Date;
    begin
        if SetFromType = 0 then
            Error(Text001);

        AssemblyHeader.TestField("Item No.");
        AssemblyHeader.TestField("Due Date");

        AssemblyHeader.CalcFields("Reserved Qty. (Base)");
        if Abs(AssemblyHeader."Remaining Quantity (Base)") < Abs(AssemblyHeader."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(AssemblyHeader."Remaining Quantity (Base)") - Abs(AssemblyHeader."Reserved Qty. (Base)"));

        AssemblyHeader.TestField("Variant Code", SetFromVariantCode);
        AssemblyHeader.TestField("Location Code", SetFromLocationCode);

        if QuantityBase * SignFactor(AssemblyHeader) < 0 then
            ShipmentDate := AssemblyHeader."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := AssemblyHeader."Due Date";
        end;

        if AssemblyHeader."Planning Flexibility" <> AssemblyHeader."Planning Flexibility"::Unlimited then
            CreateReservEntry.SetPlanningFlexibility(AssemblyHeader."Planning Flexibility");

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Assembly Header", AssemblyHeader."Document Type",
          AssemblyHeader."No.", '', 0, 0, AssemblyHeader."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForSerialNo, ForLotNo);
        CreateReservEntry.CreateReservEntryFrom(
          SetFromType, SetFromSubtype, SetFromID, SetFromBatchName, SetFromProdOrderLine, SetFromRefNo,
          SetFromQtyPerUOM, SetFromSerialNo, SetFromLotNo);
        CreateReservEntry.CreateReservEntry(
          AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate);

        SetFromType := 0;
    end;

    procedure CreateReservation(var AssemblyHeader: Record "Assembly Header"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    begin
        CreateReservation(AssemblyHeader, Description, ExpectedReceiptDate, Quantity, QuantityBase, '', '');
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

    local procedure SignFactor(AssemblyHeader: Record "Assembly Header"): Integer
    begin
        if AssemblyHeader."Document Type" in [2, 3, 5] then
            Error(Text001);

        exit(1);
    end;

    procedure SetBinding(Binding: Option " ","Order-to-Order")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure SetDisallowCancellation(DisallowCancellation: Boolean)
    begin
        CreateReservEntry.SetDisallowCancellation(DisallowCancellation);
    end;

    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; AssemblyHeader: Record "Assembly Header")
    begin
        FilterReservEntry.SetSourceFilter(DATABASE::"Assembly Header", AssemblyHeader."Document Type", AssemblyHeader."No.", 0, false);
        FilterReservEntry.SetSourceFilter('', 0);
    end;

    procedure FindReservEntry(AssemblyHeader: Record "Assembly Header"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, AssemblyHeader);
        exit(ReservEntry.FindLast);
    end;

    local procedure AssignForPlanning(var AssemblyHeader: Record "Assembly Header")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        with AssemblyHeader do begin
            if "Document Type" <> "Document Type"::Order then
                exit;

            if "Item No." <> '' then
                PlanningAssignment.ChkAssignOne("Item No.", "Variant Code", "Location Code", WorkDate);
        end;
    end;

    procedure UpdatePlanningFlexibility(var AssemblyHeader: Record "Assembly Header")
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if FindReservEntry(AssemblyHeader, ReservEntry) then
            ReservEntry.ModifyAll("Planning Flexibility", AssemblyHeader."Planning Flexibility");
    end;

    procedure ReservEntryExist(AssemblyHeader: Record "Assembly Header"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, AssemblyHeader);
        exit(not ReservEntry.IsEmpty);
    end;

    procedure DeleteLine(var AssemblyHeader: Record "Assembly Header")
    begin
        with AssemblyHeader do begin
            ReservMgt.SetAssemblyHeader(AssemblyHeader);
            if DeleteItemTracking then
                ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            ReservMgt.ClearActionMessageReferences;
            CalcFields("Reserved Qty. (Base)");
            AssignForPlanning(AssemblyHeader);
        end;
    end;

    procedure VerifyChange(var NewAssemblyHeader: Record "Assembly Header"; var OldAssemblyHeader: Record "Assembly Header")
    var
        ReservEntry: Record "Reservation Entry";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        NewAssemblyHeader.CalcFields("Reserved Qty. (Base)");
        ShowError := NewAssemblyHeader."Reserved Qty. (Base)" <> 0;

        if NewAssemblyHeader."Due Date" = 0D then begin
            if ShowError then
                NewAssemblyHeader.FieldError("Due Date", Text002);
            HasError := true;
        end;

        if NewAssemblyHeader."Item No." <> OldAssemblyHeader."Item No." then begin
            if ShowError then
                NewAssemblyHeader.FieldError("Item No.", Text003);
            HasError := true;
        end;

        if NewAssemblyHeader."Location Code" <> OldAssemblyHeader."Location Code" then begin
            if ShowError then
                NewAssemblyHeader.FieldError("Location Code", Text003);
            HasError := true;
        end;

        if NewAssemblyHeader."Variant Code" <> OldAssemblyHeader."Variant Code" then begin
            if ShowError then
                NewAssemblyHeader.FieldError("Variant Code", Text003);
            HasError := true;
        end;

        OnVerifyChangeOnBeforeHasError(NewAssemblyHeader, OldAssemblyHeader, HasError, ShowError);

        if HasError then
            if (NewAssemblyHeader."Item No." <> OldAssemblyHeader."Item No.") or
               FindReservEntry(NewAssemblyHeader, ReservEntry)
            then begin
                if NewAssemblyHeader."Item No." <> OldAssemblyHeader."Item No." then begin
                    ReservMgt.SetAssemblyHeader(OldAssemblyHeader);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetAssemblyHeader(NewAssemblyHeader);
                end else begin
                    ReservMgt.SetAssemblyHeader(NewAssemblyHeader);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewAssemblyHeader."Remaining Quantity (Base)");
            end;

        if HasError or (NewAssemblyHeader."Due Date" <> OldAssemblyHeader."Due Date") then begin
            AssignForPlanning(NewAssemblyHeader);
            if (NewAssemblyHeader."Item No." <> OldAssemblyHeader."Item No.") or
               (NewAssemblyHeader."Variant Code" <> OldAssemblyHeader."Variant Code") or
               (NewAssemblyHeader."Location Code" <> OldAssemblyHeader."Location Code")
            then
                AssignForPlanning(OldAssemblyHeader);
        end;
    end;

    procedure VerifyQuantity(var NewAssemblyHeader: Record "Assembly Header"; var OldAssemblyHeader: Record "Assembly Header")
    begin
        with NewAssemblyHeader do begin
            if "Quantity (Base)" = OldAssemblyHeader."Quantity (Base)" then
                exit;

            ReservMgt.SetAssemblyHeader(NewAssemblyHeader);
            if "Qty. per Unit of Measure" <> OldAssemblyHeader."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            ReservMgt.DeleteReservEntries(false, "Remaining Quantity (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Remaining Quantity (Base)");
            AssignForPlanning(NewAssemblyHeader);
        end;
    end;

    procedure Caption(AssemblyHeader: Record "Assembly Header") CaptionText: Text
    begin
        CaptionText :=
          StrSubstNo('%1 %2', AssemblyHeader."Document Type", AssemblyHeader."No.");
    end;

    procedure CallItemTracking(var AssemblyHeader: Record "Assembly Header")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromAsmHeader(AssemblyHeader);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, AssemblyHeader."Due Date");
        ItemTrackingLines.SetInbound(AssemblyHeader.IsInbound);
        ItemTrackingLines.RunModal;
    end;

    procedure DeleteLineConfirm(var AssemblyHeader: Record "Assembly Header"): Boolean
    begin
        with AssemblyHeader do begin
            if not ReservEntryExist(AssemblyHeader) then
                exit(true);

            ReservMgt.SetAssemblyHeader(AssemblyHeader);
            if ReservMgt.DeleteItemTrackingConfirm then
                DeleteItemTracking := true;
        end;

        exit(DeleteItemTracking);
    end;

    procedure UpdateItemTrackingAfterPosting(AssemblyHeader: Record "Assembly Header")
    var
        ReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        ReservEntry.SetSourceFilter(
          DATABASE::"Assembly Header", AssemblyHeader."Document Type", AssemblyHeader."No.", -1, false);
        ReservEntry.SetSourceFilter('', 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservEntry);
    end;

    procedure TransferAsmHeaderToItemJnlLine(var AssemblyHeader: Record "Assembly Header"; var ItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal; CheckApplToItemEntry: Boolean): Decimal
    var
        OldReservEntry: Record "Reservation Entry";
        OldReservEntry2: Record "Reservation Entry";
    begin
        if TransferQty = 0 then
            exit;
        if not FindReservEntry(AssemblyHeader, OldReservEntry) then
            exit(TransferQty);
        AssemblyHeader.CalcFields("Assemble to Order");

        ItemJnlLine.TestItemFields(AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code");

        OldReservEntry.Lock;

        if ReservEngineMgt.InitRecordSet(OldReservEntry) then begin
            repeat
                OldReservEntry.TestItemFields(AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code");
                if CheckApplToItemEntry and
                   (OldReservEntry."Reservation Status" = OldReservEntry."Reservation Status"::Reservation)
                then begin
                    OldReservEntry2.Get(OldReservEntry."Entry No.", not OldReservEntry.Positive);
                    OldReservEntry2.TestField("Source Type", DATABASE::"Item Ledger Entry");
                end;

                if AssemblyHeader."Assemble to Order" and
                   (OldReservEntry.Binding = OldReservEntry.Binding::"Order-to-Order")
                then begin
                    OldReservEntry2.Get(OldReservEntry."Entry No.", not OldReservEntry.Positive);
                    if Abs(OldReservEntry2."Qty. to Handle (Base)") < Abs(OldReservEntry."Qty. to Handle (Base)") then begin
                        OldReservEntry."Qty. to Handle (Base)" := Abs(OldReservEntry2."Qty. to Handle (Base)");
                        OldReservEntry."Qty. to Invoice (Base)" := Abs(OldReservEntry2."Qty. to Invoice (Base)");
                    end;
                end;

                TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Item Journal Line",
                    ItemJnlLine."Entry Type", ItemJnlLine."Journal Template Name",
                    ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.",
                    ItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

            until (ReservEngineMgt.NEXTRecord(OldReservEntry) = 0) or (TransferQty = 0);
            CheckApplToItemEntry := false;
        end;
        exit(TransferQty);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewAssemblyHeader: Record "Assembly Header"; OldAssemblyHeader: Record "Assembly Header"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;
}

