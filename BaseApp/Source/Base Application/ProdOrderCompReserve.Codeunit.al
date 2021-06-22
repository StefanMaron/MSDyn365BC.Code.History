codeunit 99000838 "Prod. Order Comp.-Reserve"
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
        DeleteItemTracking: Boolean;

    procedure CreateReservation(ProdOrderComp: Record "Prod. Order Component"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ShipmentDate: Date;
    begin
        if SetFromType = 0 then
            Error(Text004);

        ProdOrderComp.TestField("Item No.");
        ProdOrderComp.TestField("Due Date");
        ProdOrderComp.CalcFields("Reserved Qty. (Base)");
        if Abs(ProdOrderComp."Remaining Qty. (Base)") < Abs(ProdOrderComp."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(ProdOrderComp."Remaining Qty. (Base)") - Abs(ProdOrderComp."Reserved Qty. (Base)"));

        ProdOrderComp.TestField("Location Code", SetFromLocationCode);
        ProdOrderComp.TestField("Variant Code", SetFromVariantCode);
        if QuantityBase > 0 then
            ShipmentDate := ProdOrderComp."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ProdOrderComp."Due Date";
        end;

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Prod. Order Component", ProdOrderComp.Status,
          ProdOrderComp."Prod. Order No.", '', ProdOrderComp."Prod. Order Line No.",
          ProdOrderComp."Line No.", ProdOrderComp."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForSerialNo, ForLotNo);
        CreateReservEntry.CreateReservEntryFrom(
          SetFromType, SetFromSubtype, SetFromID, SetFromBatchName, SetFromProdOrderLine, SetFromRefNo,
          SetFromQtyPerUOM, SetFromSerialNo, SetFromLotNo);
        CreateReservEntry.CreateReservEntry(
          ProdOrderComp."Item No.", ProdOrderComp."Variant Code", ProdOrderComp."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate);

        SetFromType := 0;
    end;

    local procedure CreateBindingReservation(ProdOrderComp: Record "Prod. Order Component"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    begin
        CreateReservation(ProdOrderComp, Description, ExpectedReceiptDate, Quantity, QuantityBase, '', '');
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

    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; ProdOrderComp: Record "Prod. Order Component")
    begin
        FilterReservEntry.SetSourceFilter(
          DATABASE::"Prod. Order Component", ProdOrderComp.Status, ProdOrderComp."Prod. Order No.", ProdOrderComp."Line No.", false);
        FilterReservEntry.SetSourceFilter('', ProdOrderComp."Prod. Order Line No.");
    end;

    procedure Caption(ProdOrderComp: Record "Prod. Order Component") CaptionText: Text
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Get(
          ProdOrderComp.Status,
          ProdOrderComp."Prod. Order No.", ProdOrderComp."Prod. Order Line No.");
        CaptionText :=
          CopyStr(
            StrSubstNo('%1 %2 %3 %4 %5',
              ProdOrderComp.Status, ProdOrderComp.TableCaption,
              ProdOrderComp."Prod. Order No.", ProdOrderComp."Item No.", ProdOrderLine."Item No.")
            , 1, MaxStrLen(CaptionText));
    end;

    procedure FindReservEntry(ProdOrderComp: Record "Prod. Order Component"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, ProdOrderComp);
        if not ReservEntry.IsEmpty then
            exit(ReservEntry.FindLast);
    end;

    procedure VerifyChange(var NewProdOrderComp: Record "Prod. Order Component"; var OldProdOrderComp: Record "Prod. Order Component")
    var
        ProdOrderComp: Record "Prod. Order Component";
        TempReservEntry: Record "Reservation Entry";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if NewProdOrderComp.Status = NewProdOrderComp.Status::Finished then
            exit;
        if Blocked then
            exit;
        if NewProdOrderComp."Line No." = 0 then
            if not ProdOrderComp.Get(
                 NewProdOrderComp.Status,
                 NewProdOrderComp."Prod. Order No.",
                 NewProdOrderComp."Prod. Order Line No.",
                 NewProdOrderComp."Line No.")
            then
                exit;

        NewProdOrderComp.CalcFields("Reserved Qty. (Base)");
        ShowError := NewProdOrderComp."Reserved Qty. (Base)" <> 0;

        if NewProdOrderComp."Due Date" = 0D then
            if ShowError then
                NewProdOrderComp.FieldError("Due Date", Text002)
            else
                HasError := true;

        if NewProdOrderComp."Item No." <> OldProdOrderComp."Item No." then
            if ShowError then
                NewProdOrderComp.FieldError("Item No.", Text003)
            else
                HasError := true;
        if NewProdOrderComp."Location Code" <> OldProdOrderComp."Location Code" then
            if ShowError then
                NewProdOrderComp.FieldError("Location Code", Text003)
            else
                HasError := true;
        if (NewProdOrderComp."Bin Code" <> OldProdOrderComp."Bin Code") and
           (not ReservMgt.CalcIsAvailTrackedQtyInBin(
              NewProdOrderComp."Item No.", NewProdOrderComp."Bin Code",
              NewProdOrderComp."Location Code", NewProdOrderComp."Variant Code",
              DATABASE::"Prod. Order Component", NewProdOrderComp.Status,
              NewProdOrderComp."Prod. Order No.", '', NewProdOrderComp."Prod. Order Line No.",
              NewProdOrderComp."Line No."))
        then begin
            if ShowError then
                NewProdOrderComp.FieldError("Bin Code", Text003);
            HasError := true;
        end;
        if NewProdOrderComp."Variant Code" <> OldProdOrderComp."Variant Code" then
            if ShowError then
                NewProdOrderComp.FieldError("Variant Code", Text003)
            else
                HasError := true;
        if NewProdOrderComp."Line No." <> OldProdOrderComp."Line No." then
            HasError := true;

        OnVerifyChangeOnBeforeHasError(NewProdOrderComp, OldProdOrderComp, HasError, ShowError);

        if HasError then
            if (NewProdOrderComp."Item No." <> OldProdOrderComp."Item No.") or
               FindReservEntry(NewProdOrderComp, TempReservEntry)
            then begin
                if NewProdOrderComp."Item No." <> OldProdOrderComp."Item No." then begin
                    ReservMgt.SetProdOrderComponent(OldProdOrderComp);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetProdOrderComponent(NewProdOrderComp);
                end else begin
                    ReservMgt.SetProdOrderComponent(NewProdOrderComp);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewProdOrderComp."Remaining Qty. (Base)");
            end;

        if HasError or (NewProdOrderComp."Due Date" <> OldProdOrderComp."Due Date") then begin
            AssignForPlanning(NewProdOrderComp);
            if (NewProdOrderComp."Item No." <> OldProdOrderComp."Item No.") or
               (NewProdOrderComp."Variant Code" <> OldProdOrderComp."Variant Code") or
               (NewProdOrderComp."Location Code" <> OldProdOrderComp."Location Code")
            then
                AssignForPlanning(OldProdOrderComp);
        end;
    end;

    procedure VerifyQuantity(var NewProdOrderComp: Record "Prod. Order Component"; var OldProdOrderComp: Record "Prod. Order Component")
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if Blocked then
            exit;

        with NewProdOrderComp do begin
            if Status = Status::Finished then
                exit;
            if "Line No." = OldProdOrderComp."Line No." then
                if "Remaining Qty. (Base)" = OldProdOrderComp."Remaining Qty. (Base)" then
                    exit;
            if "Line No." = 0 then
                if not ProdOrderComp.Get(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.") then
                    exit;
            ReservMgt.SetProdOrderComponent(NewProdOrderComp);
            if "Qty. per Unit of Measure" <> OldProdOrderComp."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            if "Remaining Qty. (Base)" * OldProdOrderComp."Remaining Qty. (Base)" < 0 then
                ReservMgt.DeleteReservEntries(true, 0)
            else
                ReservMgt.DeleteReservEntries(false, "Remaining Qty. (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Remaining Qty. (Base)");
            AssignForPlanning(NewProdOrderComp);
        end;
    end;

    procedure TransferPOCompToPOComp(var OldProdOrderComp: Record "Prod. Order Component"; var NewProdOrderComp: Record "Prod. Order Component"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservEntry: Record "Reservation Entry";
    begin
        OnBeforeTransferPOCompToPOComp(OldProdOrderComp, NewProdOrderComp);

        if not FindReservEntry(OldProdOrderComp, OldReservEntry) then
            exit;

        OldReservEntry.Lock;

        NewProdOrderComp.TestItemFields(OldProdOrderComp."Item No.", OldProdOrderComp."Variant Code", OldProdOrderComp."Location Code");

        OldReservEntry.TransferReservations(
          OldReservEntry, OldProdOrderComp."Item No.", OldProdOrderComp."Variant Code", OldProdOrderComp."Location Code",
          TransferAll, TransferQty, NewProdOrderComp."Qty. per Unit of Measure",
          DATABASE::"Prod. Order Component", NewProdOrderComp.Status, NewProdOrderComp."Prod. Order No.", '',
          NewProdOrderComp."Prod. Order Line No.", NewProdOrderComp."Line No.");
    end;

    procedure TransferPOCompToItemJnlLine(var OldProdOrderComp: Record "Prod. Order Component"; var NewItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal)
    begin
        TransferPOCompToItemJnlLineCheckILE(OldProdOrderComp, NewItemJnlLine, TransferQty, false);
    end;

    procedure TransferPOCompToItemJnlLineCheckILE(var OldProdOrderComp: Record "Prod. Order Component"; var NewItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal; CheckApplFromItemEntry: Boolean)
    var
        OldReservEntry: Record "Reservation Entry";
        OppositeReservationEntry: Record "Reservation Entry";
        ItemTrackingFilterIsSet: Boolean;
        EndLoop: Boolean;
        TrackedQty: Decimal;
        UnTrackedQty: Decimal;
        xTransferQty: Decimal;
    begin
        if not FindReservEntry(OldProdOrderComp, OldReservEntry) then
            exit;

        if CheckApplFromItemEntry then
            if OppositeReservationEntry.Get(OldReservEntry."Entry No.", not OldReservEntry.Positive) then
                if OppositeReservationEntry."Source Type" <> DATABASE::"Item Ledger Entry" then
                    exit;

        // Store initial values
        OldReservEntry.CalcSums("Quantity (Base)");
        TrackedQty := -OldReservEntry."Quantity (Base)";
        xTransferQty := TransferQty;

        OldReservEntry.Lock;

        // Handle Item Tracking on consumption:
        Clear(CreateReservEntry);
        if NewItemJnlLine."Entry Type" = NewItemJnlLine."Entry Type"::Consumption then
            if NewItemJnlLine.TrackingExists then begin
                CreateReservEntry.SetNewSerialLotNo(NewItemJnlLine."Serial No.", NewItemJnlLine."Lot No.");
                // Try to match against Item Tracking on the prod. order line:
                OldReservEntry.SetTrackingFilterFromItemJnlLine(NewItemJnlLine);
                if OldReservEntry.IsEmpty then
                    OldReservEntry.ClearTrackingFilter
                else
                    ItemTrackingFilterIsSet := true;
            end;

        NewItemJnlLine.TestItemFields(OldProdOrderComp."Item No.", OldProdOrderComp."Variant Code", OldProdOrderComp."Location Code");

        if TransferQty = 0 then
            exit;

        if ReservEngineMgt.InitRecordSet(OldReservEntry, NewItemJnlLine."Serial No.", NewItemJnlLine."Lot No.") then
            repeat
                OldReservEntry.TestItemFields(OldProdOrderComp."Item No.", OldProdOrderComp."Variant Code", OldProdOrderComp."Location Code");

                TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Item Journal Line",
                    NewItemJnlLine."Entry Type", NewItemJnlLine."Journal Template Name", NewItemJnlLine."Journal Batch Name", 0,
                    NewItemJnlLine."Line No.", NewItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

                EndLoop := TransferQty = 0;
                if not EndLoop then
                    if ReservEngineMgt.NEXTRecord(OldReservEntry) = 0 then
                        if ItemTrackingFilterIsSet then begin
                            OldReservEntry.SetRange("Serial No.");
                            OldReservEntry.SetRange("Lot No.");
                            ItemTrackingFilterIsSet := false;
                            EndLoop := not ReservEngineMgt.InitRecordSet(OldReservEntry);
                        end else
                            EndLoop := true;
            until EndLoop;

        // Handle remaining transfer quantity
        if TransferQty <> 0 then begin
            TrackedQty -= (xTransferQty - TransferQty);
            UnTrackedQty := OldProdOrderComp."Remaining Qty. (Base)" - TrackedQty;
            if TransferQty > UnTrackedQty then begin
                ReservMgt.SetProdOrderComponent(OldProdOrderComp);
                ReservMgt.DeleteReservEntries(false, OldProdOrderComp."Remaining Qty. (Base)");
            end;
        end;
    end;

    procedure DeleteLineConfirm(var ProdOrderComp: Record "Prod. Order Component"): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        with ProdOrderComp do begin
            if not FindReservEntry(ProdOrderComp, ReservationEntry) then
                exit(true);

            ReservMgt.SetProdOrderComponent(ProdOrderComp);
            if ReservMgt.DeleteItemTrackingConfirm then
                DeleteItemTracking := true;
        end;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var ProdOrderComp: Record "Prod. Order Component")
    begin
        if Blocked then
            exit;

        with ProdOrderComp do begin
            Clear(ReservMgt);
            ReservMgt.SetProdOrderComponent(ProdOrderComp);
            if DeleteItemTracking then
                ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            OnDeleteLineOnAfterDeleteReservEntries(ProdOrderComp);
            CalcFields("Reserved Qty. (Base)");
            AssignForPlanning(ProdOrderComp);
        end;
    end;

    local procedure AssignForPlanning(var ProdOrderComp: Record "Prod. Order Component")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        with ProdOrderComp do begin
            if Status = Status::Simulated then
                exit;
            if "Item No." <> '' then
                PlanningAssignment.ChkAssignOne("Item No.", "Variant Code", "Location Code", "Due Date");
        end;
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var ProdOrderComp: Record "Prod. Order Component")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        if ProdOrderComp.Status = ProdOrderComp.Status::Finished then
            ItemTrackingDocMgt.ShowItemTrackingForProdOrderComp(DATABASE::"Prod. Order Component",
              ProdOrderComp."Prod. Order No.", ProdOrderComp."Prod. Order Line No.", ProdOrderComp."Line No.")
        else begin
            ProdOrderComp.TestField("Item No.");
            TrackingSpecification.InitFromProdOrderComp(ProdOrderComp);
            ItemTrackingLines.SetSourceSpec(TrackingSpecification, ProdOrderComp."Due Date");
            ItemTrackingLines.SetInbound(ProdOrderComp.IsInbound);
            ItemTrackingLines.RunModal;
        end;

        OnAfterCallItemTracking(ProdOrderComp);
    end;

    procedure UpdateItemTrackingAfterPosting(ProdOrderComponent: Record "Prod. Order Component")
    var
        ReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // Used for updating Quantity to Handle after posting;
        ReservEntry.SetSourceFilter(
          DATABASE::"Prod. Order Component", ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.",
          ProdOrderComponent."Line No.", true);
        ReservEntry.SetSourceFilter('', ProdOrderComponent."Prod. Order Line No.");
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservEntry);
    end;

    procedure BindToPurchase(ProdOrderComp: Record "Prod. Order Component"; PurchLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", '', 0, PurchLine."Line No.",
          PurchLine."Variant Code", PurchLine."Location Code", PurchLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComp, PurchLine.Description, PurchLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToProdOrder(ProdOrderComp: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Prod. Order Line", ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
          ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComp, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToRequisition(ProdOrderComp: Record "Prod. Order Component"; ReqLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
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
        CreateBindingReservation(ProdOrderComp, ReqLine.Description, ReqLine."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToAssembly(ProdOrderComp: Record "Prod. Order Component"; AsmHeader: Record "Assembly Header"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Assembly Header", AsmHeader."Document Type", AsmHeader."No.", '', 0, 0,
          AsmHeader."Variant Code", AsmHeader."Location Code", AsmHeader."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComp, AsmHeader.Description, AsmHeader."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToTransfer(ProdOrderComp: Record "Prod. Order Component"; TransLine: Record "Transfer Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Transfer Line", 1, TransLine."Document No.", '', 0, TransLine."Line No.",
          TransLine."Variant Code", TransLine."Transfer-to Code", TransLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ProdOrderComp, TransLine.Description, TransLine."Receipt Date", ReservQty, ReservQtyBase);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCallItemTracking(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferPOCompToPOComp(var OldProdOrderComp: Record "Prod. Order Component"; var NewProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteLineOnAfterDeleteReservEntries(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewProdOrderComp: Record "Prod. Order Component"; OldProdOrderComp: Record "Prod. Order Component"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;
}

