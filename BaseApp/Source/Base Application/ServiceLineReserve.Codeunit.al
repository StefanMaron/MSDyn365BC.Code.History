codeunit 99000842 "Service Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Codeunit is not initialized correctly.';
        Text001: Label 'Reserved quantity cannot be greater than %1';
        Text002: Label 'must be filled in when a quantity is reserved';
        Text003: Label 'must not be changed when a quantity is reserved';
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservMgt: Codeunit "Reservation Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UOMMgt: Codeunit "Unit of Measure Management";
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
        Text004: Label 'must not be filled in when a quantity is reserved';

    procedure CreateReservation(ServiceLine: Record "Service Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ShipmentDate: Date;
    begin
        if SetFromType = 0 then
            Error(Text000);

        ServiceLine.TestField(Type, ServiceLine.Type::Item);
        ServiceLine.TestField("No.");
        ServiceLine.TestField("Needed by Date");
        ServiceLine.CalcFields("Reserved Qty. (Base)");
        if Abs(ServiceLine."Outstanding Qty. (Base)") < Abs(ServiceLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text001,
              Abs(ServiceLine."Outstanding Qty. (Base)") - Abs(ServiceLine."Reserved Qty. (Base)"));

        ServiceLine.TestField("Variant Code", SetFromVariantCode);
        ServiceLine.TestField("Location Code", SetFromLocationCode);

        if QuantityBase > 0 then
            ShipmentDate := ServiceLine."Needed by Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ServiceLine."Needed by Date";
        end;

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Service Line", ServiceLine."Document Type",
          ServiceLine."Document No.", '', 0, ServiceLine."Line No.",
          ServiceLine."Qty. per Unit of Measure", Quantity, QuantityBase, ForSerialNo, ForLotNo);
        CreateReservEntry.CreateReservEntryFrom(
          SetFromType, SetFromSubtype, SetFromID, SetFromBatchName, SetFromProdOrderLine, SetFromRefNo,
          SetFromQtyPerUOM, SetFromSerialNo, SetFromLotNo);
        CreateReservEntry.CreateReservEntry(
          ServiceLine."No.", ServiceLine."Variant Code", ServiceLine."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate);

        SetFromType := 0;
    end;

    local procedure CreateBindingReservation(ServiceLine: Record "Service Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    begin
        CreateReservation(ServiceLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, '', '');
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

    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; ServiceLine: Record "Service Line")
    begin
        FilterReservEntry.SetSourceFilter(
          DATABASE::"Service Line", ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.", false);
        FilterReservEntry.SetSourceFilter('', 0);
    end;

    procedure Caption(ServiceLine: Record "Service Line") CaptionText: Text
    begin
        CaptionText :=
          StrSubstNo('%1 %2 %3', ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."No.");
    end;

    procedure FindReservEntry(ServiceLine: Record "Service Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, ServiceLine);
        exit(ReservEntry.FindLast);
    end;

    local procedure ReservEntryExist(ServLine: Record "Service Line"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, ServLine);
        exit(not ReservEntry.IsEmpty);
    end;

    procedure ReservQuantity(ServLine: Record "Service Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
        case ServLine."Document Type" of
            ServLine."Document Type"::Quote,
            ServLine."Document Type"::Order,
            ServLine."Document Type"::Invoice:
                begin
                    QtyToReserve := ServLine."Outstanding Quantity";
                    QtyToReserveBase := ServLine."Outstanding Qty. (Base)";
                end;
            ServLine."Document Type"::"Credit Memo":
                begin
                    QtyToReserve := -ServLine."Outstanding Quantity";
                    QtyToReserveBase := -ServLine."Outstanding Qty. (Base)"
                end;
        end;
    end;

    procedure VerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line")
    var
        ServiceLine: Record "Service Line";
        TempReservEntry: Record "Reservation Entry";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if (NewServiceLine.Type <> NewServiceLine.Type::Item) and (OldServiceLine.Type <> OldServiceLine.Type::Item) then
            exit;

        if NewServiceLine."Line No." = 0 then
            if not ServiceLine.Get(NewServiceLine."Document Type", NewServiceLine."Document No.", NewServiceLine."Line No.") then
                exit;

        NewServiceLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewServiceLine."Reserved Qty. (Base)" <> 0;

        if NewServiceLine.Type <> OldServiceLine.Type then
            if ShowError then
                NewServiceLine.FieldError(Type, Text003)
            else
                HasError := true;

        if NewServiceLine."No." <> OldServiceLine."No." then
            if ShowError then
                NewServiceLine.FieldError("No.", Text003)
            else
                HasError := true;

        if (NewServiceLine."Needed by Date" = 0D) and (OldServiceLine."Needed by Date" <> 0D) then
            if ShowError then
                NewServiceLine.FieldError("Needed by Date", Text002)
            else
                HasError := true;

        if NewServiceLine."Variant Code" <> OldServiceLine."Variant Code" then
            if ShowError then
                NewServiceLine.FieldError("Variant Code", Text003)
            else
                HasError := true;

        if NewServiceLine."Location Code" <> OldServiceLine."Location Code" then
            if ShowError then
                NewServiceLine.FieldError("Location Code", Text003)
            else
                HasError := true;

        if (NewServiceLine.Type = NewServiceLine.Type::Item) and (OldServiceLine.Type = OldServiceLine.Type::Item) then
            if (NewServiceLine."Bin Code" <> OldServiceLine."Bin Code") and
               (not ReservMgt.CalcIsAvailTrackedQtyInBin(
                  NewServiceLine."No.", NewServiceLine."Bin Code",
                  NewServiceLine."Location Code", NewServiceLine."Variant Code",
                  DATABASE::"Service Line", NewServiceLine."Document Type",
                  NewServiceLine."Document No.", '', 0, NewServiceLine."Line No."))
            then begin
                if ShowError then
                    NewServiceLine.FieldError("Bin Code", Text004);
                HasError := true;
            end;

        if NewServiceLine."Line No." <> OldServiceLine."Line No." then
            HasError := true;

        OnVerifyChangeOnBeforeHasError(NewServiceLine, OldServiceLine, HasError, ShowError);

        if HasError then
            if (NewServiceLine."No." <> OldServiceLine."No.") or
               FindReservEntry(NewServiceLine, TempReservEntry)
            then begin
                if NewServiceLine."No." <> OldServiceLine."No." then begin
                    ReservMgt.SetServLine(OldServiceLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetServLine(NewServiceLine);
                end else begin
                    ReservMgt.SetServLine(NewServiceLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewServiceLine."Outstanding Qty. (Base)");
            end;

        if HasError or (NewServiceLine."Needed by Date" <> OldServiceLine."Needed by Date")
        then begin
            AssignForPlanning(NewServiceLine);
            if (NewServiceLine."No." <> OldServiceLine."No.") or
               (NewServiceLine."Variant Code" <> OldServiceLine."Variant Code") or
               (NewServiceLine."Location Code" <> OldServiceLine."Location Code")
            then
                AssignForPlanning(OldServiceLine);
        end;
    end;

    procedure VerifyQuantity(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line")
    var
        ServiceLine: Record "Service Line";
    begin
        with NewServiceLine do begin
            if not ("Document Type" in
                    ["Document Type"::Quote, "Document Type"::Order])
            then
                if "Shipment No." = '' then
                    exit;

            if Type <> Type::Item then
                exit;
            if "Line No." = OldServiceLine."Line No." then
                if "Quantity (Base)" = OldServiceLine."Quantity (Base)" then
                    exit;
            if "Line No." = 0 then
                if not ServiceLine.Get("Document Type", "Document No.", "Line No.") then
                    exit;
            ReservMgt.SetServLine(NewServiceLine);
            if "Qty. per Unit of Measure" <> OldServiceLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            if "Outstanding Qty. (Base)" * OldServiceLine."Outstanding Qty. (Base)" < 0 then
                ReservMgt.DeleteReservEntries(false, 0)
            else
                ReservMgt.DeleteReservEntries(false, "Outstanding Qty. (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Outstanding Qty. (Base)");
            AssignForPlanning(NewServiceLine);
        end;
    end;

    local procedure AssignForPlanning(var ServiceLine: Record "Service Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        with ServiceLine do begin
            if "Document Type" <> "Document Type"::Order then
                exit;
            if Type <> Type::Item then
                exit;
            if "No." <> '' then
                PlanningAssignment.ChkAssignOne("No.", "Variant Code", "Location Code", "Needed by Date");
        end;
    end;

    procedure DeleteLineConfirm(var ServLine: Record "Service Line"): Boolean
    begin
        with ServLine do begin
            if not ReservEntryExist(ServLine) then
                exit(true);

            ReservMgt.SetServLine(ServLine);
            if ReservMgt.DeleteItemTrackingConfirm then
                DeleteItemTracking := true;
        end;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var ServLine: Record "Service Line")
    begin
        with ServLine do begin
            ReservMgt.SetServLine(ServLine);
            if DeleteItemTracking then
                ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            DeleteInvoiceSpecFromLine(ServLine);
            CalcFields("Reserved Qty. (Base)");
        end;
    end;

    procedure CallItemTracking(var ServiceLine: Record "Service Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromServLine(ServiceLine, false);
        if ((ServiceLine."Document Type" = ServiceLine."Document Type"::Invoice) and
            (ServiceLine."Shipment No." <> ''))
        then
            ItemTrackingLines.SetFormRunMode(2); // Combined shipment/receipt
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ServiceLine."Needed by Date");
        ItemTrackingLines.SetInbound(ServiceLine.IsInbound);
        ItemTrackingLines.RunModal;
    end;

    procedure TransServLineToServLine(var OldServLine: Record "Service Line"; var NewServLine: Record "Service Line"; TransferQty: Decimal)
    var
        OldReservEntry: Record "Reservation Entry";
        Status: Option Reservation,Tracking,Surplus,Prospect;
    begin
        if not FindReservEntry(OldServLine, OldReservEntry) then
            exit;

        OldReservEntry.Lock;

        NewServLine.TestItemFields(OldServLine."No.", OldServLine."Variant Code", OldServLine."Location Code");

        for Status := Status::Reservation to Status::Prospect do begin
            if TransferQty = 0 then
                exit;
            OldReservEntry.SetRange("Reservation Status", Status);
            if OldReservEntry.FindSet then
                repeat
                    OldReservEntry.TestItemFields(OldServLine."No.", OldServLine."Variant Code", OldServLine."Location Code");

                    TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Service Line",
                        NewServLine."Document Type", NewServLine."Document No.", '', 0,
                        NewServLine."Line No.", NewServLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

                until (OldReservEntry.Next = 0) or (TransferQty = 0);
        end;
    end;

    procedure RetrieveInvoiceSpecification(var ServLine: Record "Service Line"; var TempInvoicingSpecification: Record "Tracking Specification" temporary; Consume: Boolean) OK: Boolean
    var
        SourceSpecification: Record "Tracking Specification";
    begin
        Clear(TempInvoicingSpecification);
        if ServLine.Type <> ServLine.Type::Item then
            exit;
        if ((ServLine."Document Type" = ServLine."Document Type"::Invoice) and
            (ServLine."Shipment No." <> ''))
        then
            OK := RetrieveInvoiceSpecification2(ServLine, TempInvoicingSpecification)
        else begin
            SourceSpecification.InitFromServLine(ServLine, Consume);
            OK := ItemTrackingMgt.RetrieveInvoiceSpecWithService(SourceSpecification, TempInvoicingSpecification, Consume);
        end;
    end;

    local procedure RetrieveInvoiceSpecification2(var ServLine: Record "Service Line"; var TempInvoicingSpecification: Record "Tracking Specification" temporary) OK: Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
    begin
        // Used for combined shipment:
        if ServLine.Type <> ServLine.Type::Item then
            exit;
        if not FindReservEntry(ServLine, ReservEntry) then
            exit;
        ReservEntry.FindSet;
        repeat
            ReservEntry.TestField("Reservation Status", ReservEntry."Reservation Status"::Prospect);
            ReservEntry.TestField("Item Ledger Entry No.");
            TrackingSpecification.Get(ReservEntry."Item Ledger Entry No.");
            TempInvoicingSpecification := TrackingSpecification;
            TempInvoicingSpecification."Qty. to Invoice (Base)" :=
              ReservEntry."Qty. to Invoice (Base)";
            TempInvoicingSpecification."Qty. to Invoice" :=
              Round(ReservEntry."Qty. to Invoice (Base)" / ReservEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
            TempInvoicingSpecification."Buffer Status" := TempInvoicingSpecification."Buffer Status"::MODIFY;
            TempInvoicingSpecification.Insert;
            ReservEntry.Delete;
        until ReservEntry.Next = 0;

        OK := TempInvoicingSpecification.FindFirst;
    end;

    procedure DeleteInvoiceSpecFromHeader(ServHeader: Record "Service Header")
    begin
        ItemTrackingMgt.DeleteInvoiceSpecFromHeader(
          DATABASE::"Service Line", ServHeader."Document Type", ServHeader."No.");
    end;

    local procedure DeleteInvoiceSpecFromLine(ServLine: Record "Service Line")
    begin
        ItemTrackingMgt.DeleteInvoiceSpecFromLine(
          DATABASE::"Service Line", ServLine."Document Type", ServLine."Document No.", ServLine."Line No.");
    end;

    procedure TransServLineToItemJnlLine(var ServLine: Record "Service Line"; var ItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal; var CheckApplFromItemEntry: Boolean): Decimal
    var
        OldReservEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(ServLine, OldReservEntry) then
            exit(TransferQty);

        OldReservEntry.Lock;

        ItemJnlLine.TestItemFields(ServLine."No.", ServLine."Variant Code", ServLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ItemJnlLine."Invoiced Quantity" <> 0 then
            CreateReservEntry.SetUseQtyToInvoice(true);

        if ReservEngineMgt.InitRecordSet(OldReservEntry) then begin
            repeat
                OldReservEntry.TestItemFields(ServLine."No.", ServLine."Variant Code", ServLine."Location Code");

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

    procedure UpdateItemTrackingAfterPosting(ServHeader: Record "Service Header")
    var
        ReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservEntry.SetSourceFilter(DATABASE::"Service Line", ServHeader."Document Type", ServHeader."No.", -1, true);
        ReservEntry.SetSourceFilter('', 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservEntry);
    end;

    procedure BindToPurchase(ServiceLine: Record "Service Line"; PurchLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Purchase Line",
          PurchLine."Document Type", PurchLine."Document No.", '', 0, PurchLine."Line No.",
          PurchLine."Variant Code", PurchLine."Location Code", PurchLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(ServiceLine, PurchLine.Description, PurchLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToRequisition(ServiceLine: Record "Service Line"; ReqLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
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
        CreateBindingReservation(ServiceLine, ReqLine.Description, ReqLine."Due Date", ReservQty, ReservQtyBase);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewServiceLine: Record "Service Line"; OldServiceLine: Record "Service Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;
}

