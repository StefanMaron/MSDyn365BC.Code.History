codeunit 12452 "Item Doc. Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Codeunit is not initialized correctly.';
        Text001: Label 'Reserved quantity cannot be greater than %1.';
        Text002: Label 'must be filled in when a quantity is reserved';
        Text003: Label 'must not be changed when a quantity is reserved';
        ReservMgt: Codeunit "Reservation Management";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        Blocked: Boolean;
        SetFromType: Option " ",Sales,"Requisition Line",Purchase,"Item Journal","BOM Journal","Item Ledger Entry";
        SetFromSubtype: Integer;
        SetFromID: Code[20];
        SetFromBatchName: Code[10];
        SetFromProdOrderLine: Integer;
        SetFromRefNo: Integer;
        SetFromVariantCode: Code[10];
        SetFromLocationCode: Code[10];
        SetFromSerialNo: Code[50];
        SetFromLotNo: Code[50];
        SetFromCDNo: Code[30];
        SetFromQtyPerUOM: Decimal;

    [Scope('OnPrem')]
    procedure CreateReservation(var ItemDocLine: Record "Item Document Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50]; ForCDNo: Code[30])
    var
        ShipmentDate: Date;
    begin
        if SetFromType = 0 then
            Error(Text000);

        ItemDocLine.TestField("Item No.");
        ItemDocLine.TestField("Variant Code", SetFromVariantCode);

        case ItemDocLine."Document Type" of
            1: // Shipment
                begin
                    ItemDocLine.TestField("Document Date");
                    ItemDocLine.TestField("Location Code", SetFromLocationCode);
                    ItemDocLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                    if Abs(ItemDocLine."Quantity (Base)") <
                       Abs(ItemDocLine."Reserved Qty. Outbnd. (Base)") + Quantity
                    then
                        Error(
                          Text001,
                          Abs(ItemDocLine."Quantity (Base)") - Abs(ItemDocLine."Reserved Qty. Outbnd. (Base)"));
                    ShipmentDate := ItemDocLine."Document Date";
                end;
            0: // Receipt
                begin
                    ItemDocLine.TestField("Document Date");
                    ItemDocLine.TestField("Location Code", SetFromLocationCode);
                    ItemDocLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                    if Abs(ItemDocLine."Quantity (Base)") <
                       Abs(ItemDocLine."Reserved Qty. Inbnd. (Base)") + Quantity
                    then
                        Error(
                          Text001,
                          Abs(ItemDocLine."Quantity (Base)") - Abs(ItemDocLine."Reserved Qty. Inbnd. (Base)"));
                    ExpectedReceiptDate := ItemDocLine."Document Date";
                end;
        end;

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Item Document Line",
          ItemDocLine."Document Type", ItemDocLine."Document No.", '',
          0, ItemDocLine."Line No.", ItemDocLine."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForSerialNo, ForLotNo, ForCDNo);
        CreateReservEntry.CreateReservEntryFrom(
          SetFromType, SetFromSubtype, SetFromID, SetFromBatchName, SetFromProdOrderLine, SetFromRefNo,
          SetFromQtyPerUOM, SetFromSerialNo, SetFromLotNo, SetFromCDNo);
        CreateReservEntry.CreateReservEntry(
          ItemDocLine."Item No.", ItemDocLine."Variant Code", SetFromLocationCode,
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        SetFromType := 0;
    end;

    [Scope('OnPrem')]
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
            SetFromCDNo := "CD No.";
            SetFromQtyPerUOM := "Qty. per Unit of Measure";
        end;
    end;

    [Scope('OnPrem')]
    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; ItemDocLine: Record "Item Document Line")
    begin
        FilterReservEntry.SetRange("Source Type", DATABASE::"Item Document Line");
        FilterReservEntry.SetRange("Source Subtype", ItemDocLine."Document Type");
        FilterReservEntry.SetRange("Source ID", ItemDocLine."Document No.");
        FilterReservEntry.SetRange("Source Batch Name", '');
        FilterReservEntry.SetRange("Source Prod. Order Line", 0);
        FilterReservEntry.SetRange("Source Ref. No.", ItemDocLine."Line No.");
    end;

    [Scope('OnPrem')]
    procedure Caption(ItemDocLine: Record "Item Document Line") CaptionText: Text
    begin
        CaptionText :=
          StrSubstNo(
            '%1 %2 %3', ItemDocLine."Document No.", ItemDocLine."Line No.",
            ItemDocLine."Item No.");
    end;

    [Scope('OnPrem')]
    procedure FindReservEntry(ItemDocLine: Record "Item Document Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, ItemDocLine);
        exit(ReservEntry.Find('+'));
    end;

    [Scope('OnPrem')]
    procedure VerifyChange(var NewItemDocLine: Record "Item Document Line"; var OldItemDocLine: Record "Item Document Line")
    var
        ItemDocLine: Record "Item Document Line";
        TempReservEntry: Record "Reservation Entry";
        ShowErrorInbnd: Boolean;
        ShowErrorOutbnd: Boolean;
        HasErrorInbnd: Boolean;
        HasErrorOutbnd: Boolean;
    begin
        if Blocked then
            exit;
        if NewItemDocLine."Line No." = 0 then
            if not ItemDocLine.Get(NewItemDocLine."Document Type", NewItemDocLine."Document No.", NewItemDocLine."Line No.") then
                exit;

        NewItemDocLine.CalcFields("Reserved Qty. Inbnd. (Base)");
        NewItemDocLine.CalcFields("Reserved Qty. Outbnd. (Base)");

        ShowErrorInbnd := (NewItemDocLine."Reserved Qty. Inbnd. (Base)" <> 0);
        ShowErrorOutbnd := (NewItemDocLine."Reserved Qty. Outbnd. (Base)" <> 0);

        if NewItemDocLine."Document Type" in
           [NewItemDocLine."Document Type"::Receipt, 2]
        then begin
            if NewItemDocLine."Document Date" = 0D then
                if ShowErrorOutbnd then
                    NewItemDocLine.FieldError("Document Date", Text002);

            HasErrorOutbnd := true;
        end;

        if NewItemDocLine."Document Type" in
           [NewItemDocLine."Document Type"::Shipment, 2]
        then begin
            if NewItemDocLine."Document Date" = 0D then
                if ShowErrorOutbnd then
                    NewItemDocLine.FieldError("Document Date", Text002);

            HasErrorOutbnd := true;
        end;

        if NewItemDocLine."Item No." <> OldItemDocLine."Item No." then begin
            if ShowErrorInbnd or ShowErrorOutbnd then
                NewItemDocLine.FieldError("Item No.", Text003);

            HasErrorInbnd := true;
            HasErrorOutbnd := true;
        end;

        if NewItemDocLine."Location Code" <> OldItemDocLine."Location Code" then begin
            if ShowErrorOutbnd then
                NewItemDocLine.FieldError("Location Code", Text003);

            HasErrorOutbnd := true;
        end;

        if NewItemDocLine."Bin Code" <> OldItemDocLine."Bin Code" then begin
            if ShowErrorOutbnd then
                NewItemDocLine.FieldError("Bin Code", Text003);

            HasErrorOutbnd := true;
        end;

        if NewItemDocLine."Variant Code" <> OldItemDocLine."Variant Code" then begin
            if ShowErrorInbnd or ShowErrorOutbnd then
                NewItemDocLine.FieldError("Variant Code", Text003);

            HasErrorInbnd := true;
            HasErrorOutbnd := true;
        end;

        if NewItemDocLine."Line No." <> OldItemDocLine."Line No." then begin
            HasErrorInbnd := true;
            HasErrorOutbnd := true;
        end;

        if HasErrorOutbnd then begin
            if (NewItemDocLine."Item No." <> OldItemDocLine."Item No.") or
               FindReservEntry(NewItemDocLine, TempReservEntry)
            then begin
                if NewItemDocLine."Item No." <> OldItemDocLine."Item No." then begin
                    ReservMgt.SetItemDocLine(OldItemDocLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetItemDocLine(NewItemDocLine);
                end else begin
                    ReservMgt.SetItemDocLine(NewItemDocLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewItemDocLine."Quantity (Base)");
            end;
            AssignForPlanning(NewItemDocLine);
            if (NewItemDocLine."Item No." <> OldItemDocLine."Item No.") or
               (NewItemDocLine."Variant Code" <> OldItemDocLine."Variant Code")
            then
                AssignForPlanning(OldItemDocLine);
        end;

        if HasErrorInbnd then begin
            if (NewItemDocLine."Item No." <> OldItemDocLine."Item No.") or
               FindReservEntry(NewItemDocLine, TempReservEntry)
            then begin
                if NewItemDocLine."Item No." <> OldItemDocLine."Item No." then begin
                    ReservMgt.SetItemDocLine(OldItemDocLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetItemDocLine(NewItemDocLine);
                end else begin
                    ReservMgt.SetItemDocLine(NewItemDocLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewItemDocLine."Quantity (Base)");
            end;
            AssignForPlanning(NewItemDocLine);
            if (NewItemDocLine."Item No." <> OldItemDocLine."Item No.") or
               (NewItemDocLine."Variant Code" <> OldItemDocLine."Variant Code") or
               (NewItemDocLine."Location Code" <> OldItemDocLine."Location Code")
            then
                AssignForPlanning(OldItemDocLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyQuantity(var NewItemDocLine: Record "Item Document Line"; var OldItemDocLine: Record "Item Document Line")
    var
        ItemDocLine: Record "Item Document Line";
    begin
        if Blocked then
            exit;

        with NewItemDocLine do begin
            if "Line No." = OldItemDocLine."Line No." then
                if "Quantity (Base)" = OldItemDocLine."Quantity (Base)" then
                    exit;
            if "Line No." = 0 then
                if not ItemDocLine.Get("Document Type", "Document No.", "Line No.") then
                    exit;
            ReservMgt.SetItemDocLine(NewItemDocLine);
            if "Qty. per Unit of Measure" <> OldItemDocLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            ReservMgt.DeleteReservEntries(false, "Quantity (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Quantity (Base)");
            AssignForPlanning(NewItemDocLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure TransferItemDocToItemJnlLine(var ItemDocLine: Record "Item Document Line"; var ItemJnlLine: Record "Item Journal Line"; ReceiptQty: Decimal)
    var
        OldReservEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(ItemDocLine, OldReservEntry) then
            exit;

        OldReservEntry.Lock;

        ItemJnlLine.TestField("Location Code", ItemDocLine."Location Code");
        ItemJnlLine.TestField("Item No.", ItemDocLine."Item No.");
        ItemJnlLine.TestField("Variant Code", ItemDocLine."Variant Code");

        if ReceiptQty = 0 then
            exit;

        if ReservEngineMgt.InitRecordSet(OldReservEntry) then
            repeat
                OldReservEntry.TestField("Item No.", ItemDocLine."Item No.");
                OldReservEntry.TestField("Variant Code", ItemDocLine."Variant Code");
                OldReservEntry.TestField("Location Code", ItemDocLine."Location Code");
                if ItemJnlLine."Red Storno" then
                    OldReservEntry.Validate("Quantity (Base)", -OldReservEntry."Quantity (Base)");
                ReceiptQty :=
                  CreateReservEntry.TransferReservEntry(
                    DATABASE::"Item Journal Line",
                    ItemJnlLine."Entry Type", ItemJnlLine."Journal Template Name",
                    ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.",
                    ItemJnlLine."Qty. per Unit of Measure", OldReservEntry,
                    ReceiptQty * ItemJnlLine."Qty. per Unit of Measure"); // qty base

            until (ReservEngineMgt.NEXTRecord(OldReservEntry) = 0) or (ReceiptQty = 0);
    end;

    [Scope('OnPrem')]
    procedure RenameLine(var NewItemDocLine: Record "Item Document Line"; var OldItemDocLine: Record "Item Document Line")
    begin
        ReservEngineMgt.RenamePointer(DATABASE::"Item Document Line",
          0,
          OldItemDocLine."Document No.",
          '',
          0,
          OldItemDocLine."Line No.",
          0,
          NewItemDocLine."Document No.",
          '',
          0,
          NewItemDocLine."Line No.");
    end;

    [Scope('OnPrem')]
    procedure DeleteLine(var ItemDocLine: Record "Item Document Line")
    var
        ItemDocHeader: Record "Item Document Header";
        RedStorno: Boolean;
    begin
        if Blocked then
            exit;

        with ItemDocLine do begin
            ItemDocHeader.Get("Document Type", "Document No.");
            RedStorno := ItemDocHeader.Correction;
            case "Document Type" of
                "Document Type"::Receipt:
                    begin
                        ReservMgt.SetItemDocLine(ItemDocLine);
                        if RedStorno then
                            ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
                        ReservMgt.DeleteReservEntries(true, 0);
                        CalcFields("Reserved Qty. Outbnd. (Base)");
                    end;
                "Document Type"::Shipment:
                    begin
                        ReservMgt.SetItemDocLine(ItemDocLine);
                        if RedStorno then
                            ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
                        ReservMgt.DeleteReservEntries(true, 0);
                        CalcFields("Reserved Qty. Inbnd. (Base)");
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure AssignForPlanning(var ItemDocLine: Record "Item Document Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if ItemDocLine."Item No." <> '' then
            PlanningAssignment.ChkAssignOne(
              ItemDocLine."Item No.",
              ItemDocLine."Variant Code",
              ItemDocLine."Location Code",
              ItemDocLine."Document Date");
    end;

    [Scope('OnPrem')]
    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    [Scope('OnPrem')]
    procedure CallItemTracking(var ItemDocLine: Record "Item Document Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromItemDocLine(ItemDocLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ItemDocLine."Document Date");
        ItemTrackingLines.RunModal;
    end;

    [Scope('OnPrem')]
    procedure CallItemTracking2(var ItemDocLine: Record "Item Document Line"; var SecondSourceQuantityArray: array[3] of Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromItemDocLine(ItemDocLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ItemDocLine."Document Date");
        ItemTrackingLines.SetSecondSourceQuantity(SecondSourceQuantityArray);
        ItemTrackingLines.RunModal;
    end;

    [Scope('OnPrem')]
    procedure InitBinContentItemTracking(var ItemDocLine: Record "Item Document Line"; SerialNo: Code[20]; LotNo: Code[20]; CDNo: Code[30]; QtyOnBin: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification" temporary;
        ReservEntry: Record "Reservation Entry";
    begin
        TrackingSpecification.InitFromItemDocLine(ItemDocLine);
        TrackingSpecification."Serial No." := SerialNo;
        TrackingSpecification."New Serial No." := SerialNo;
        TrackingSpecification."Lot No." := LotNo;
        TrackingSpecification."New Lot No." := LotNo;
        TrackingSpecification."CD No." := CDNo;
        TrackingSpecification."Quantity Handled (Base)" := 0;
        TrackingSpecification.Validate("Quantity (Base)", QtyOnBin);
        ReservEntry.TransferFields(TrackingSpecification);
        ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Surplus;
        ReservEntry.Positive := ReservEntry."Quantity (Base)" > 0;
    end;
}

