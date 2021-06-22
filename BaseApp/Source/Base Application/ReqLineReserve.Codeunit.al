codeunit 99000833 "Req. Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Action Message Entry" = rmd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Reserved quantity cannot be greater than %1';
        Text002: Label 'must be filled in when a quantity is reserved';
        Text003: Label 'must not be filled in when a quantity is reserved';
        Text004: Label 'must not be changed when a quantity is reserved';
        Text005: Label 'Codeunit is not initialized correctly.';
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservMgt: Codeunit "Reservation Management";
        Blocked: Boolean;

    procedure CreateReservation(var ReqLine: Record "Requisition Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text005);

        ReqLine.TestField(Type, ReqLine.Type::Item);
        ReqLine.TestField("No.");
        ReqLine.TestField("Due Date");
        ReqLine.CalcFields("Reserved Qty. (Base)");
        if Abs(ReqLine."Quantity (Base)") < Abs(ReqLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(ReqLine."Quantity (Base)") - Abs(ReqLine."Reserved Qty. (Base)"));

        ReqLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        ReqLine.TestField("Location Code", FromTrackingSpecification."Location Code");

        if QuantityBase < 0 then
            ShipmentDate := ReqLine."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ReqLine."Due Date";
        end;

        if ReqLine."Planning Flexibility" <> ReqLine."Planning Flexibility"::Unlimited then
            CreateReservEntry.SetPlanningFlexibility(ReqLine."Planning Flexibility");

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Requisition Line", 0,
          ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name", 0, ReqLine."Line No.",
          ReqLine."Qty. per Unit of Measure", Quantity, QuantityBase, ForReservEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          ReqLine."No.", ReqLine."Variant Code", ReqLine."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    [Obsolete('Replaced by CreateReservation(ReqLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry)','16.0')]
    procedure CreateReservation(var ReqLine: Record "Requisition Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ForReservEntry: Record "Reservation Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservation(ReqLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    [Obsolete('Replaced by ReqLine.SetReservationFilters(FilterReservEntry)','16.0')]
    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; ReqLine: Record "Requisition Line")
    begin
        ReqLine.SetReservationFilters(FilterReservEntry);
    end;

    procedure Caption(ReqLine: Record "Requisition Line") CaptionText: Text
    begin
        CaptionText := ReqLine.GetSourceCaption;
    end;

    procedure FindReservEntry(ReqLine: Record "Requisition Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.InitSortingAndFilters(false);
        ReqLine.SetReservationFilters(ReservEntry);
        exit(ReservEntry.FindLast);
    end;

    procedure VerifyChange(var NewReqLine: Record "Requisition Line"; var OldReqLine: Record "Requisition Line")
    var
        ReqLine: Record "Requisition Line";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if (NewReqLine.Type <> NewReqLine.Type::Item) and (OldReqLine.Type <> OldReqLine.Type::Item) then
            exit;
        if Blocked then
            exit;
        if NewReqLine."Line No." = 0 then
            if not ReqLine.Get(NewReqLine."Worksheet Template Name", NewReqLine."Journal Batch Name", NewReqLine."Line No.")
            then
                exit;

        NewReqLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewReqLine."Reserved Qty. (Base)" <> 0;

        if NewReqLine."Due Date" = 0D then
            if ShowError then
                NewReqLine.FieldError("Due Date", Text002)
            else
                HasError := true;

        if NewReqLine."Sales Order No." <> '' then
            if ShowError then
                NewReqLine.FieldError("Sales Order No.", Text003)
            else
                HasError := true;

        if NewReqLine."Sales Order Line No." <> 0 then
            if ShowError then
                NewReqLine.FieldError("Sales Order Line No.", Text003)
            else
                HasError := true;

        if NewReqLine."Sell-to Customer No." <> '' then
            if ShowError then
                NewReqLine.FieldError("Sell-to Customer No.", Text003)
            else
                HasError := true;

        if NewReqLine."Variant Code" <> OldReqLine."Variant Code" then
            if ShowError then
                NewReqLine.FieldError("Variant Code", Text004)
            else
                HasError := true;

        if NewReqLine."No." <> OldReqLine."No." then
            if ShowError then
                NewReqLine.FieldError("No.", Text004)
            else
                HasError := true;

        if NewReqLine."Location Code" <> OldReqLine."Location Code" then
            if ShowError then
                NewReqLine.FieldError("Location Code", Text004)
            else
                HasError := true;

        VerifyBinInReqLine(NewReqLine, OldReqLine, HasError);

        OnVerifyChangeOnBeforeHasError(NewReqLine, OldReqLine, HasError, ShowError);

        if HasError then
            if (NewReqLine."No." <> OldReqLine."No.") or NewReqLine.ReservEntryExist() then begin
                if NewReqLine."No." <> OldReqLine."No." then begin
                    ReservMgt.SetReservSource(OldReqLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetReservSource(NewReqLine);
                end else begin
                    ReservMgt.SetReservSource(NewReqLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewReqLine."Quantity (Base)");
            end;

        if HasError or (NewReqLine."Due Date" <> OldReqLine."Due Date") then begin
            AssignForPlanning(NewReqLine);
            if (NewReqLine."No." <> OldReqLine."No.") or
               (NewReqLine."Variant Code" <> OldReqLine."Variant Code") or
               (NewReqLine."Location Code" <> OldReqLine."Location Code")
            then
                AssignForPlanning(OldReqLine);
        end;
    end;

    procedure VerifyQuantity(var NewReqLine: Record "Requisition Line"; var OldReqLine: Record "Requisition Line")
    var
        ReqLine: Record "Requisition Line";
    begin
        if Blocked then
            exit;

        with NewReqLine do begin
            if "Line No." = OldReqLine."Line No." then
                if "Quantity (Base)" = OldReqLine."Quantity (Base)" then
                    exit;
            if "Line No." = 0 then
                if not ReqLine.Get("Worksheet Template Name", "Journal Batch Name", "Line No.") then
                    exit;
            ReservMgt.SetReservSource(NewReqLine);
            if "Qty. per Unit of Measure" <> OldReqLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            if "Quantity (Base)" * OldReqLine."Quantity (Base)" < 0 then
                ReservMgt.DeleteReservEntries(true, 0)
            else
                ReservMgt.DeleteReservEntries(false, "Quantity (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Quantity (Base)");
            AssignForPlanning(NewReqLine);
        end;
    end;

    procedure UpdatePlanningFlexibility(var ReqLine: Record "Requisition Line")
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if FindReservEntry(ReqLine, ReservEntry) then
            ReservEntry.ModifyAll("Planning Flexibility", ReqLine."Planning Flexibility");
    end;

    procedure TransferReqLineToReqLine(var OldReqLine: Record "Requisition Line"; var NewReqLine: Record "Requisition Line"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservEntry: Record "Reservation Entry";
        NewReservEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(OldReqLine, OldReservEntry) then
            exit;

        OldReservEntry.Lock;

        NewReqLine.TestField("No.", OldReqLine."No.");
        NewReqLine.TestField("Variant Code", OldReqLine."Variant Code");
        NewReqLine.TestField("Location Code", OldReqLine."Location Code");

        OnTransferReqLineToReqLineOnBeforeTransfer(OldReservEntry, OldReqLine, NewReqLine);

        if TransferAll then begin
            OldReservEntry.SetRange("Source Subtype", 0);
            OldReservEntry.TransferReservations(
              OldReservEntry, OldReqLine."No.", OldReqLine."Variant Code", OldReqLine."Location Code",
              TransferAll, TransferQty, NewReqLine."Qty. per Unit of Measure",
              DATABASE::"Requisition Line", 0, NewReqLine."Worksheet Template Name", NewReqLine."Journal Batch Name", 0, NewReqLine."Line No.");

            if OldReqLine."Ref. Order Type" <> OldReqLine."Ref. Order Type"::Transfer then
                exit;

            if NewReqLine."Order Promising ID" <> '' then begin
                OldReservEntry.SetSourceFilter(
                  DATABASE::"Sales Line", NewReqLine."Order Promising Line No.", NewReqLine."Order Promising ID",
                  NewReqLine."Order Promising Line ID", false);
                OldReservEntry.SetRange("Source Batch Name", '');
            end;
            OldReservEntry.SetRange("Source Subtype", 1);
            if OldReservEntry.FindSet() then begin
                OldReservEntry.TestField("Qty. per Unit of Measure", NewReqLine."Qty. per Unit of Measure");
                repeat
                    OldReservEntry.TestField("Item No.", OldReqLine."No.");
                    OldReservEntry.TestField("Variant Code", OldReqLine."Variant Code");
                    if NewReqLine."Order Promising ID" = '' then
                        OldReservEntry.TestField("Location Code", OldReqLine."Transfer-from Code");

                    NewReservEntry := OldReservEntry;
                    NewReservEntry."Source ID" := NewReqLine."Worksheet Template Name";
                    NewReservEntry."Source Batch Name" := NewReqLine."Journal Batch Name";
                    NewReservEntry."Source Prod. Order Line" := 0;
                    NewReservEntry."Source Ref. No." := NewReqLine."Line No.";

                    NewReservEntry.UpdateActionMessageEntries(OldReservEntry);
                until OldReservEntry.Next() = 0;
            end;
        end else
            OldReservEntry.TransferReservations(
              OldReservEntry, OldReqLine."No.", OldReqLine."Variant Code", OldReqLine."Location Code",
              TransferAll, TransferQty, NewReqLine."Qty. per Unit of Measure",
              DATABASE::"Requisition Line", 0, NewReqLine."Worksheet Template Name", NewReqLine."Journal Batch Name", 0, NewReqLine."Line No.");
    end;

    procedure TransferReqLineToPurchLine(var OldReqLine: Record "Requisition Line"; var PurchLine: Record "Purchase Line"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(OldReqLine, OldReservEntry) then
            exit;

        PurchLine.TestField("No.", OldReqLine."No.");
        PurchLine.TestField("Variant Code", OldReqLine."Variant Code");
        PurchLine.TestField("Location Code", OldReqLine."Location Code");

        OnTransferReqLineToPurchLineOnBeforeTransfer(OldReservEntry, OldReqLine, PurchLine);

        OldReservEntry.TransferReservations(
          OldReservEntry, OldReqLine."No.", OldReqLine."Variant Code", OldReqLine."Location Code",
          TransferAll, TransferQty, PurchLine."Qty. per Unit of Measure",
          DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", '', 0, PurchLine."Line No.");
    end;

    procedure TransferPlanningLineToPOLine(var OldReqLine: Record "Requisition Line"; var NewProdOrderLine: Record "Prod. Order Line"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(OldReqLine, OldReservEntry) then
            exit;

        NewProdOrderLine.TestField("Item No.", OldReqLine."No.");
        NewProdOrderLine.TestField("Variant Code", OldReqLine."Variant Code");
        NewProdOrderLine.TestField("Location Code", OldReqLine."Location Code");

        OnTransferReqLineToPOLineOnBeforeTransfer(OldReservEntry, OldReqLine, NewProdOrderLine);

        OldReservEntry.TransferReservations(
            OldReservEntry, OldReqLine."No.", OldReqLine."Variant Code", OldReqLine."Location Code",
            TransferAll, TransferQty, NewProdOrderLine."Qty. per Unit of Measure",
            DATABASE::"Prod. Order Line", NewProdOrderLine.Status, NewProdOrderLine."Prod. Order No.", '', NewProdOrderLine."Line No.", 0);
    end;

    procedure TransferPlanningLineToAsmHdr(var OldReqLine: Record "Requisition Line"; var NewAsmHeader: Record "Assembly Header"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(OldReqLine, OldReservEntry) then
            exit;

        NewAsmHeader.TestField("Item No.", OldReqLine."No.");
        NewAsmHeader.TestField("Variant Code", OldReqLine."Variant Code");
        NewAsmHeader.TestField("Location Code", OldReqLine."Location Code");

        OnTransferReqLineToAsmHdrOnBeforeTransfer(OldReservEntry, OldReqLine, NewAsmHeader);

        OldReservEntry.TransferReservations(
            OldReservEntry, OldReqLine."No.", OldReqLine."Variant Code", OldReqLine."Location Code",
            TransferAll, TransferQty, NewAsmHeader."Qty. per Unit of Measure",
            DATABASE::"Assembly Header", NewAsmHeader."Document Type", NewAsmHeader."No.", '', 0, 0);
    end;

    procedure TransferReqLineToTransLine(var ReqLine: Record "Requisition Line"; var TransLine: Record "Transfer Line"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservEntry: Record "Reservation Entry";
        NewReservEntry: Record "Reservation Entry";
        OrigTransferQty: Decimal;
        ReservStatus: Enum "Reservation Status";
        Direction: Enum "Transfer Direction";
        Subtype: Enum "Transfer Direction";
    begin
        if not FindReservEntry(ReqLine, OldReservEntry) then
            exit;

        OldReservEntry.Lock;

        TransLine.TestField("Item No.", ReqLine."No.");
        TransLine.TestField("Variant Code", ReqLine."Variant Code");
        TransLine.TestField("Transfer-to Code", ReqLine."Location Code");
        TransLine.TestField("Transfer-from Code", ReqLine."Transfer-from Code");

        if TransferAll then begin
            OldReservEntry.FindSet;
            OldReservEntry.TestField("Qty. per Unit of Measure", TransLine."Qty. per Unit of Measure");

            repeat
                Direction := 1 - OldReservEntry."Source Subtype"; // Swap 0/1 (outbound/inbound)
                if (Direction = Direction::Inbound) or (OldReservEntry."Source Type" <> DATABASE::"Transfer Line") then
                    OldReservEntry.TestItemFields(ReqLine."No.", ReqLine."Variant Code", ReqLine."Location Code")
                else
                    OldReservEntry.TestItemFields(ReqLine."No.", ReqLine."Variant Code", ReqLine."Transfer-from Code");

                NewReservEntry := OldReservEntry;
                if Direction = Direction::Inbound then
                    NewReservEntry.SetSource(
                      DATABASE::"Transfer Line", 1, TransLine."Document No.", TransLine."Line No.", '', TransLine."Derived From Line No.")
                else
                    NewReservEntry.SetSource(
                      DATABASE::"Transfer Line", 0, TransLine."Document No.", TransLine."Line No.", '', TransLine."Derived From Line No.");

                NewReservEntry.UpdateActionMessageEntries(OldReservEntry);
            until (OldReservEntry.Next() = 0);
        end else begin
            OrigTransferQty := TransferQty;

            for Subtype := Subtype::Outbound to Subtype::Inbound do begin
                OldReservEntry.SetRange("Source Subtype", Subtype);
                TransferQty := OrigTransferQty;
                if TransferQty = 0 then
                    exit;

                for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
                    OldReservEntry.SetRange("Reservation Status", ReservStatus);

                    if OldReservEntry.FindSet() then
                        repeat
                            Direction := 1 - OldReservEntry."Source Subtype";  // Swap 0/1 (outbound/inbound)
                            OldReservEntry.TestField("Item No.", ReqLine."No.");
                            OldReservEntry.TestField("Variant Code", ReqLine."Variant Code");
                            if Direction = Direction::Inbound then
                                OldReservEntry.TestField("Location Code", ReqLine."Location Code")
                            else
                                OldReservEntry.TestField("Location Code", ReqLine."Transfer-from Code");

                            TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Transfer Line",
                                Direction, TransLine."Document No.", '', TransLine."Derived From Line No.",
                                TransLine."Line No.", TransLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

                        until (OldReservEntry.Next() = 0) or (TransferQty = 0);
                end;
            end;
        end;
    end;

    local procedure AssignForPlanning(var ReqLine: Record "Requisition Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        with ReqLine do begin
            if Type <> Type::Item then
                exit;
            if "No." <> '' then
                PlanningAssignment.ChkAssignOne("No.", "Variant Code", "Location Code", WorkDate);
        end;
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure DeleteLine(var ReqLine: Record "Requisition Line")
    var
        ProdOrderComp: Record "Prod. Order Component";
        CalcReservEntry4: Record "Reservation Entry";
        QtyTracked: Decimal;
    begin
        if Blocked then
            exit;

        with ReqLine do begin
            ReservMgt.SetReservSource(ReqLine);
            ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            CalcFields("Reserved Qty. (Base)");
            AssignForPlanning(ReqLine);

            // Retracking of components:
            if ("Action Message" = "Action Message"::Cancel) and
               ("Planning Line Origin" = "Planning Line Origin"::Planning) and
               ("Ref. Order Type" = "Ref. Order Type"::"Prod. Order")
            then begin
                ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.");
                ProdOrderComp.SetRange(Status, "Ref. Order Status");
                ProdOrderComp.SetRange("Prod. Order No.", "Ref. Order No.");
                ProdOrderComp.SetRange("Prod. Order Line No.", "Ref. Line No.");
                if ProdOrderComp.FindSet() then
                    repeat
                        ProdOrderComp.CalcFields("Reserved Qty. (Base)");
                        QtyTracked := ProdOrderComp."Reserved Qty. (Base)";
                        CalcReservEntry4.Reset();
                        CalcReservEntry4.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
                        ProdOrderComp.SetReservationFilters(CalcReservEntry4);
                        CalcReservEntry4.SetFilter("Reservation Status", '<>%1', CalcReservEntry4."Reservation Status"::Reservation);
                        if CalcReservEntry4.FindSet() then
                            repeat
                                QtyTracked := QtyTracked - CalcReservEntry4."Quantity (Base)";
                            until CalcReservEntry4.Next() = 0;
                        ReservMgt.SetReservSource(ProdOrderComp);
                        ReservMgt.DeleteReservEntries(QtyTracked = 0, QtyTracked);
                        ReservMgt.AutoTrack(ProdOrderComp."Remaining Qty. (Base)");
                    until ProdOrderComp.Next() = 0;
            end
        end;
    end;

    procedure UpdateDerivedTracking(var ReqLine: Record "Requisition Line")
    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ActionMessageEntry: Record "Action Message Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        ActionMessageEntry.SetCurrentKey("Reservation Entry");

        with ReservEntry do begin
            SetFilter("Expected Receipt Date", '<>%1', ReqLine."Due Date");
            case ReqLine."Ref. Order Type" of
                ReqLine."Ref. Order Type"::Purchase:
                    SetSourceFilter(DATABASE::"Purchase Line", 1, ReqLine."Ref. Order No.", ReqLine."Ref. Line No.", true);
                ReqLine."Ref. Order Type"::"Prod. Order":
                    begin
                        SetSourceFilter(DATABASE::"Prod. Order Line", ReqLine."Ref. Order Status", ReqLine."Ref. Order No.", -1, true);
                        SetRange("Source Prod. Order Line", ReqLine."Ref. Line No.");
                    end;
                ReqLine."Ref. Order Type"::Transfer:
                    SetSourceFilter(DATABASE::"Transfer Line", 1, ReqLine."Ref. Order No.", ReqLine."Ref. Line No.", true);
                ReqLine."Ref. Order Type"::Assembly:
                    SetSourceFilter(DATABASE::"Assembly Header", 1, ReqLine."Ref. Order No.", 0, true);
            end;

            if FindSet() then
                repeat
                    ReservEntry2 := ReservEntry;
                    ReservEntry2."Expected Receipt Date" := ReqLine."Due Date";
                    ReservEntry2.Modify();
                    if ReservEntry2.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive) then begin
                        ReservEntry2."Expected Receipt Date" := ReqLine."Due Date";
                        ReservEntry2.Modify();
                    end;
                    ActionMessageEntry.SetRange("Reservation Entry", "Entry No.");
                    ActionMessageEntry.DeleteAll();
                until Next() = 0;
        end;
    end;

    procedure CallItemTracking(var ReqLine: Record "Requisition Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromReqLine(ReqLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ReqLine."Due Date");
        ItemTrackingLines.RunModal;
    end;

    local procedure VerifyBinInReqLine(var NewReqLine: Record "Requisition Line"; var OldReqLine: Record "Requisition Line"; var HasError: Boolean)
    begin
        if (NewReqLine.Type = NewReqLine.Type::Item) and (OldReqLine.Type = OldReqLine.Type::Item) then
            if (NewReqLine."Bin Code" <> OldReqLine."Bin Code") and
               (not ReservMgt.CalcIsAvailTrackedQtyInBin(
                  NewReqLine."No.", NewReqLine."Bin Code",
                  NewReqLine."Location Code", NewReqLine."Variant Code",
                  DATABASE::"Requisition Line", 0,
                  NewReqLine."Worksheet Template Name", NewReqLine."Journal Batch Name", 0,
                  NewReqLine."Line No."))
            then
                HasError := true;

        if NewReqLine."Line No." <> OldReqLine."Line No." then
            HasError := true;
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        ReqLine: Record "Requisition Line";
    begin
        if SourceRecRef.Number = Database::"Requisition Line" then begin
            SourceRecRef.SetTable(ReqLine);
            ReqLine.Find;
            QtyPerUOM := ReqLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ReqLine: Record "Requisition Line";
    begin
        SourceRecRef.SetTable(ReqLine);
        ReqLine.TestField("Sales Order No.", '');
        ReqLine.TestField("Sales Order Line No.", 0);
        ReqLine.TestField("Sell-to Customer No.", '');
        ReqLine.TestField(Type, ReqLine.Type::Item);
        ReqLine.TestField("Due Date");

        ReqLine.SetReservationEntry(ReservEntry);

        CaptionText := ReqLine.GetSourceCaption;
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo = 21);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = 246); // DATABASE::"Requisition Line"
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnSetReservSource', '', false, false)]
    local procedure OnSetReservSource(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    begin
        if MatchThisTable(SourceRecRef.Number) then
            SetReservSourceFor(SourceRecRef, ReservEntry, CaptionText);
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnDrillDownTotalQuantity', '', false, false)]
    local procedure OnDrillDownTotalQuantity(SourceRecRef: RecordRef; ReservEntry: Record "Reservation Entry"; EntrySummary: Record "Entry Summary"; Location: Record Location; MaxQtyToReserve: Decimal)
    var
        AvailableRequisitionLines: page "Available - Requisition Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailableRequisitionLines);
            AvailableRequisitionLines.SetSource(SourceRecRef, ReservEntry, ReservEntry."Source Subtype");
            AvailableRequisitionLines.RunModal;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Requisition Line");
            FilterReservEntry.SetRange("Source Subtype", 0);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then begin
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Requisition Line") and
                (FilterReservEntry."Source Subtype" = 0);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        ReqLine: Record "Requisition Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(ReqLine);
            CreateReservation(ReqLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceRefNo: Integer)
    var
        ReqLine: Record "Requisition Line";
    begin
        if MatchThisTable(SourceType) then begin
            ReqLine.Reset();
            ReqLine.SetRange("Worksheet Template Name", SourceID);
            ReqLine.SetRange("Journal Batch Name", SourceBatchName);
            ReqLine.SetRange("Line No.", SourceRefNo);
            PAGE.RunModal(PAGE::"Requisition Lines", ReqLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceRefNo: Integer)
    var
        ReqLine: Record "Requisition Line";
    begin
        if MatchThisTable(SourceType) then begin
            ReqLine.Reset();
            ReqLine.SetRange("Worksheet Template Name", SourceID);
            ReqLine.SetRange("Journal Batch Name", SourceBatchName);
            ReqLine.SetRange("Line No.", SourceRefNo);
            PAGE.Run(PAGE::"Requisition Lines", ReqLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ReqLine: Record "Requisition Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ReqLine);
            ReqLine.SetReservationFilters(ReservEntry);
            CaptionText := ReqLine.GetSourceCaption;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        ReqLine: Record "Requisition Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(ReqLine);
            ReqLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ReqLine: Record "Requisition Line";
    begin
        ReqLine.Get(ReservEntry."Source ID", ReservEntry."Source Batch Name", ReservEntry."Source Ref. No.");
        SourceRecRef.GetTable(ReqLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ReqLine."Net Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ReqLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferReqLineToAsmHdrOnBeforeTransfer(var OldReservEntry: Record "Reservation Entry"; var OldReqLine: Record "Requisition Line"; var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferReqLineToPurchLineOnBeforeTransfer(var OldReservEntry: Record "Reservation Entry"; var OldReqLine: Record "Requisition Line"; var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferReqLineToPOLineOnBeforeTransfer(var OldReservEntry: Record "Reservation Entry"; var OldReqLine: Record "Requisition Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferReqLineToReqLineOnBeforeTransfer(var OldReservEntry: Record "Reservation Entry"; var OldReqLine: Record "Requisition Line"; var NewReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewReqLine: Record "Requisition Line"; OldReqLine: Record "Requisition Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;
}

