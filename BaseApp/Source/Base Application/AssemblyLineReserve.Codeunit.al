codeunit 926 "Assembly Line-Reserve"
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

    procedure CreateReservation(AssemblyLine: Record "Assembly Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ShipmentDate: Date;
    begin
        if SetFromType = 0 then
            Error(Text001);

        AssemblyLine.TestField(Type, AssemblyLine.Type::Item);
        AssemblyLine.TestField("No.");
        AssemblyLine.TestField("Due Date");

        AssemblyLine.CalcFields("Reserved Qty. (Base)");
        if Abs(AssemblyLine."Remaining Quantity (Base)") < Abs(AssemblyLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(AssemblyLine."Remaining Quantity (Base)") - Abs(AssemblyLine."Reserved Qty. (Base)"));

        AssemblyLine.TestField("Variant Code", SetFromVariantCode);
        AssemblyLine.TestField("Location Code", SetFromLocationCode);

        if QuantityBase * SignFactor(AssemblyLine) < 0 then
            ShipmentDate := AssemblyLine."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := AssemblyLine."Due Date";
        end;

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Assembly Line", AssemblyLine."Document Type",
          AssemblyLine."Document No.", '', 0, AssemblyLine."Line No.", AssemblyLine."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForSerialNo, ForLotNo);
        CreateReservEntry.CreateReservEntryFrom(
          SetFromType, SetFromSubtype, SetFromID, SetFromBatchName, SetFromProdOrderLine, SetFromRefNo,
          SetFromQtyPerUOM, SetFromSerialNo, SetFromLotNo);
        CreateReservEntry.CreateReservEntry(
          AssemblyLine."No.", AssemblyLine."Variant Code", AssemblyLine."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate);

        SetFromType := 0;
    end;

    local procedure CreateBindingReservation(AssemblyLine: Record "Assembly Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    begin
        CreateReservation(AssemblyLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, '', '');
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

    local procedure SignFactor(AssemblyLine: Record "Assembly Line"): Integer
    begin
        if AssemblyLine."Document Type" in [2, 3, 5] then
            Error(Text001);

        exit(-1);
    end;

    procedure SetBinding(Binding: Option " ","Order-to-Order")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; AssemblyLine: Record "Assembly Line")
    begin
        FilterReservEntry.SetRange("Source Type", DATABASE::"Assembly Line");
        FilterReservEntry.SetRange("Source Subtype", AssemblyLine."Document Type");
        FilterReservEntry.SetRange("Source ID", AssemblyLine."Document No.");
        FilterReservEntry.SetRange("Source Batch Name", '');
        FilterReservEntry.SetRange("Source Prod. Order Line", 0);
        FilterReservEntry.SetRange("Source Ref. No.", AssemblyLine."Line No.");
    end;

    procedure FindReservEntry(AssemblyLine: Record "Assembly Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, AssemblyLine);
        exit(ReservEntry.FindLast);
    end;

    local procedure AssignForPlanning(var AssemblyLine: Record "Assembly Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        with AssemblyLine do begin
            if "Document Type" <> "Document Type"::Order then
                exit;

            if Type <> Type::Item then
                exit;

            if "No." <> '' then
                PlanningAssignment.ChkAssignOne("No.", "Variant Code", "Location Code", WorkDate);
        end;
    end;

    procedure ReservEntryExist(AssemblyLine: Record "Assembly Line"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, AssemblyLine);
        exit(not ReservEntry.IsEmpty);
    end;

    procedure DeleteLine(var AssemblyLine: Record "Assembly Line")
    begin
        with AssemblyLine do begin
            ReservMgt.SetAssemblyLine(AssemblyLine);
            if DeleteItemTracking then
                ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            ReservMgt.ClearActionMessageReferences;
            CalcFields("Reserved Qty. (Base)");
            AssignForPlanning(AssemblyLine);
        end;
    end;

    procedure SetDeleteItemTracking(AllowDirectDeletion: Boolean)
    begin
        DeleteItemTracking := AllowDirectDeletion;
    end;

    procedure VerifyChange(var NewAssemblyLine: Record "Assembly Line"; var OldAssemblyLine: Record "Assembly Line")
    var
        AssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if (NewAssemblyLine.Type <> NewAssemblyLine.Type::Item) and (OldAssemblyLine.Type <> OldAssemblyLine.Type::Item) then
            exit;

        if NewAssemblyLine."Line No." = 0 then
            if not AssemblyLine.Get(NewAssemblyLine."Document Type", NewAssemblyLine."Document No.", NewAssemblyLine."Line No.") then
                exit;

        NewAssemblyLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewAssemblyLine."Reserved Qty. (Base)" <> 0;

        if NewAssemblyLine."Due Date" = 0D then begin
            if ShowError then
                NewAssemblyLine.FieldError("Due Date", Text002);
            HasError := true;
        end;

        if NewAssemblyLine.Type <> OldAssemblyLine.Type then begin
            if ShowError then
                NewAssemblyLine.FieldError(Type, Text003);
            HasError := true;
        end;

        if NewAssemblyLine."No." <> OldAssemblyLine."No." then begin
            if ShowError then
                NewAssemblyLine.FieldError("No.", Text003);
            HasError := true;
        end;

        if NewAssemblyLine."Location Code" <> OldAssemblyLine."Location Code" then begin
            if ShowError then
                NewAssemblyLine.FieldError("Location Code", Text003);
            HasError := true;
        end;

        OnVerifyChangeOnBeforeHasError(NewAssemblyLine, OldAssemblyLine, HasError, ShowError);

        if (NewAssemblyLine.Type = NewAssemblyLine.Type::Item) and (OldAssemblyLine.Type = OldAssemblyLine.Type::Item) and
           (NewAssemblyLine."Bin Code" <> OldAssemblyLine."Bin Code")
        then
            if not ReservMgt.CalcIsAvailTrackedQtyInBin(
                 NewAssemblyLine."No.", NewAssemblyLine."Bin Code",
                 NewAssemblyLine."Location Code", NewAssemblyLine."Variant Code",
                 DATABASE::"Assembly Line", NewAssemblyLine."Document Type",
                 NewAssemblyLine."Document No.", '', 0, NewAssemblyLine."Line No.")
            then begin
                if ShowError then
                    NewAssemblyLine.FieldError("Bin Code", Text003);
                HasError := true;
            end;

        if NewAssemblyLine."Variant Code" <> OldAssemblyLine."Variant Code" then begin
            if ShowError then
                NewAssemblyLine.FieldError("Variant Code", Text003);
            HasError := true;
        end;

        if NewAssemblyLine."Line No." <> OldAssemblyLine."Line No." then
            HasError := true;

        if HasError then
            if (NewAssemblyLine."No." <> OldAssemblyLine."No.") or
               FindReservEntry(NewAssemblyLine, ReservEntry)
            then begin
                if NewAssemblyLine."No." <> OldAssemblyLine."No." then begin
                    ReservMgt.SetAssemblyLine(OldAssemblyLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetAssemblyLine(NewAssemblyLine);
                end else begin
                    ReservMgt.SetAssemblyLine(NewAssemblyLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewAssemblyLine."Remaining Quantity (Base)");
            end;

        if HasError or (NewAssemblyLine."Due Date" <> OldAssemblyLine."Due Date") then begin
            AssignForPlanning(NewAssemblyLine);
            if (NewAssemblyLine."No." <> OldAssemblyLine."No.") or
               (NewAssemblyLine."Variant Code" <> OldAssemblyLine."Variant Code") or
               (NewAssemblyLine."Location Code" <> OldAssemblyLine."Location Code")
            then
                AssignForPlanning(OldAssemblyLine);
        end;
    end;

    procedure VerifyQuantity(var NewAssemblyLine: Record "Assembly Line"; var OldAssemblyLine: Record "Assembly Line")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        with NewAssemblyLine do begin
            if Type <> Type::Item then
                exit;
            if "Line No." = OldAssemblyLine."Line No." then
                if "Remaining Quantity (Base)" = OldAssemblyLine."Remaining Quantity (Base)" then
                    exit;
            if "Line No." = 0 then
                if not AssemblyLine.Get("Document Type", "Document No.", "Line No.") then
                    exit;

            ReservMgt.SetAssemblyLine(NewAssemblyLine);
            if "Qty. per Unit of Measure" <> OldAssemblyLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            ReservMgt.DeleteReservEntries(false, "Remaining Quantity (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Remaining Quantity (Base)");
            AssignForPlanning(NewAssemblyLine);
        end;
    end;

    procedure Caption(AssemblyLine: Record "Assembly Line") CaptionText: Text
    begin
        CaptionText :=
          StrSubstNo('%1 %2 %3', AssemblyLine."Document Type", AssemblyLine."Document No.", AssemblyLine."Line No.");
    end;

    procedure CallItemTracking(var AssemblyLine: Record "Assembly Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromAsmLine(AssemblyLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, AssemblyLine."Due Date");
        ItemTrackingLines.SetInbound(AssemblyLine.IsInbound);
        ItemTrackingLines.RunModal;
    end;

    procedure DeleteLineConfirm(var AssemblyLine: Record "Assembly Line"): Boolean
    begin
        with AssemblyLine do begin
            if not ReservEntryExist(AssemblyLine) then
                exit(true);

            ReservMgt.SetAssemblyLine(AssemblyLine);
            if ReservMgt.DeleteItemTrackingConfirm then
                DeleteItemTracking := true;
        end;

        exit(DeleteItemTracking);
    end;

    procedure UpdateItemTrackingAfterPosting(AssemblyLine: Record "Assembly Line")
    var
        ReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        ReservEntry.SetRange("Source Type", DATABASE::"Assembly Line");
        ReservEntry.SetRange("Source Subtype", AssemblyLine."Document Type");
        ReservEntry.SetRange("Source ID", AssemblyLine."Document No.");
        ReservEntry.SetRange("Source Batch Name", '');
        ReservEntry.SetRange("Source Prod. Order Line", 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservEntry);
    end;

    procedure TransferAsmLineToItemJnlLine(var AssemblyLine: Record "Assembly Line"; var ItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal; CheckApplFromItemEntry: Boolean): Decimal
    var
        OldReservEntry: Record "Reservation Entry";
    begin
        if TransferQty = 0 then
            exit;
        if not FindReservEntry(AssemblyLine, OldReservEntry) then
            exit(TransferQty);

        ItemJnlLine.TestField("Item No.", AssemblyLine."No.");
        ItemJnlLine.TestField("Variant Code", AssemblyLine."Variant Code");
        ItemJnlLine.TestField("Location Code", AssemblyLine."Location Code");

        OldReservEntry.Lock;

        if ReservEngineMgt.InitRecordSet(OldReservEntry) then begin
            repeat
                OldReservEntry.TestField("Item No.", AssemblyLine."No.");
                OldReservEntry.TestField("Variant Code", AssemblyLine."Variant Code");
                OldReservEntry.TestField("Location Code", AssemblyLine."Location Code");

                if CheckApplFromItemEntry then begin
                    OldReservEntry.TestField("Appl.-from Item Entry");
                    CreateReservEntry.SetApplyFromEntryNo(OldReservEntry."Appl.-from Item Entry");
                end;

                TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Item Journal Line",
                    ItemJnlLine."Entry Type", ItemJnlLine."Journal Template Name",
                    ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.",
                    ItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

            until (ReservEngineMgt.NEXTRecord(OldReservEntry) = 0) or (TransferQty = 0);
            CheckApplFromItemEntry := false;
        end;
        exit(TransferQty);
    end;

    procedure TransferAsmLineToAsmLine(var OldAssemblyLine: Record "Assembly Line"; var NewAssemblyLine: Record "Assembly Line"; TransferQty: Decimal)
    var
        OldReservEntry: Record "Reservation Entry";
        Status: Option Reservation,Tracking,Surplus,Prospect;
    begin
        if TransferQty = 0 then
            exit;

        if not FindReservEntry(OldAssemblyLine, OldReservEntry) then
            exit;

        OldReservEntry.Lock;

        NewAssemblyLine.TestField("No.", OldAssemblyLine."No.");
        NewAssemblyLine.TestField("Variant Code", OldAssemblyLine."Variant Code");
        NewAssemblyLine.TestField("Location Code", OldAssemblyLine."Location Code");

        for Status := Status::Reservation to Status::Prospect do begin
            OldReservEntry.SetRange("Reservation Status", Status);
            if OldReservEntry.FindSet then
                repeat
                    OldReservEntry.TestField("Item No.", OldAssemblyLine."No.");
                    OldReservEntry.TestField("Variant Code", OldAssemblyLine."Variant Code");
                    OldReservEntry.TestField("Location Code", OldAssemblyLine."Location Code");

                    TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Assembly Line",
                        NewAssemblyLine."Document Type", NewAssemblyLine."Document No.", '', 0,
                        NewAssemblyLine."Line No.", NewAssemblyLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

                until (OldReservEntry.Next = 0) or (TransferQty = 0);
        end;
    end;

    procedure BindToPurchase(AsmLine: Record "Assembly Line"; PurchLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", '', 0, PurchLine."Line No.",
          PurchLine."Variant Code", PurchLine."Location Code", PurchLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(AsmLine, PurchLine.Description, PurchLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToProdOrder(AsmLine: Record "Assembly Line"; ProdOrderLine: Record "Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Prod. Order Line", ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
          ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(AsmLine, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToAssembly(AsmLine: Record "Assembly Line"; AsmHeader: Record "Assembly Header"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Assembly Header", AsmHeader."Document Type", AsmHeader."No.", '', 0, 0,
          AsmHeader."Variant Code", AsmHeader."Location Code", AsmHeader."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(AsmLine, AsmHeader.Description, AsmHeader."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToTransfer(AsmLine: Record "Assembly Line"; TransLine: Record "Transfer Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Transfer Line", 1, TransLine."Document No.", '', 0, TransLine."Line No.",
          TransLine."Variant Code", TransLine."Transfer-to Code", TransLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(AsmLine, TransLine.Description, TransLine."Receipt Date", ReservQty, ReservQtyBase);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewAssemblyLine: Record "Assembly Line"; OldAssemblyLine: Record "Assembly Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;
}

