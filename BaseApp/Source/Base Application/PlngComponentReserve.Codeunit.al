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
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservMgt: Codeunit "Reservation Management";
        Blocked: Boolean;

    procedure CreateReservation(PlanningComponent: Record "Planning Component"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text004);

        PlanningComponent.TestField("Item No.");
        PlanningComponent.TestField("Due Date");

        if Abs(PlanningComponent."Net Quantity (Base)") < Abs(PlanningComponent."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(PlanningComponent."Net Quantity (Base)") - Abs(PlanningComponent."Reserved Qty. (Base)"));

        PlanningComponent.TestField("Location Code", FromTrackingSpecification."Location Code");
        PlanningComponent.TestField("Variant Code", FromTrackingSpecification."Variant Code");

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
          Quantity, QuantityBase, ForReservEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          PlanningComponent."Item No.", PlanningComponent."Variant Code", PlanningComponent."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    [Obsolete('Replaced by CreateReservation(PlanningComponent, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry)','16.0')]
    procedure CreateReservation(PlanningComponent: Record "Planning Component"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ForReservEntry: Record "Reservation Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservation(PlanningComponent, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry);
    end;

    local procedure CreateBindingReservation(PlanningComponent: Record "Planning Component"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservEntry: Record "Reservation Entry";
    begin
        CreateReservation(PlanningComponent, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure SetBinding(Binding: Option " ","Order-to-Order")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    [Obsolete('Replaced by PlanningComponent.SetReservationFilters(FilterReservEntry)','16.0')]
    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; PlanningComponent: Record "Planning Component")
    begin
        PlanningComponent.SetReservationFilters(FilterReservEntry);
    end;

    procedure Caption(PlanningComponent: Record "Planning Component") CaptionText: Text
    var
        ReqLine: Record "Requisition Line";
    begin
        CaptionText := PlanningComponent.GetSourceCaption;
    end;

    procedure FindReservEntry(PlanningComponent: Record "Planning Component"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.InitSortingAndFilters(false);
        PlanningComponent.SetReservationFilters(ReservEntry);
        exit(ReservEntry.FindLast);
    end;

    procedure VerifyChange(var NewPlanningComponent: Record "Planning Component"; var OldPlanningComponent: Record "Planning Component")
    var
        PlanningComponent: Record "Planning Component";
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
            if (NewPlanningComponent."Item No." <> OldPlanningComponent."Item No.") or NewPlanningComponent.ReservEntryExist() then begin
                if NewPlanningComponent."Item No." <> OldPlanningComponent."Item No." then begin
                    ReservMgt.SetReservSource(OldPlanningComponent);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetReservSource(NewPlanningComponent);
                end else begin
                    ReservMgt.SetReservSource(NewPlanningComponent);
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
            ReservMgt.SetReservSource(NewPlanningComponent);
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
        ReservStatus: Enum "Reservation Status";
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
                NewReservEntry.Modify();
            until OldReservEntry.Next = 0;
        end else
            for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
                if TransferQty = 0 then
                    exit;
                OldReservEntry.SetRange("Reservation Status", ReservStatus);

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
            ReservMgt.SetReservSource(PlanningComponent);
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
        ReservEntry.InitSortingAndFilters(false);
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
                    ReservEntry2.Modify();
                    if ReservEntry2.Get(ReservEntry2."Entry No.", not ReservEntry2.Positive) then begin
                        ReservEntry2."Shipment Date" := PlanningComponent."Due Date";
                        ReservEntry2.Modify();
                    end;
                    ActionMessageEntry.SetRange("Reservation Entry", "Entry No.");
                    ActionMessageEntry.DeleteAll();
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

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        PlanningComponent: Record "Planning Component";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(PlanningComponent);
            PlanningComponent.Find;
            QtyPerUOM := PlanningComponent.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        PlanningComponent: Record "Planning Component";
    begin
        SourceRecRef.SetTable(PlanningComponent);
        PlanningComponent.TestField("Due Date");

        PlanningComponent.SetReservationEntry(ReservEntry);

        CaptionText := PlanningComponent.GetSourceCaption;
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo = 91);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = 99000829); // DATABASE::"Planning Component"
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
        AvailPlanningComponents: page "Avail. - Planning Components";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailPlanningComponents);
            AvailPlanningComponents.SetSource(SourceRecRef, ReservEntry, ReservEntry."Source Subtype");
            AvailPlanningComponents.RunModal;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Planning Component");
            FilterReservEntry.SetRange("Source Subtype", 0);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then begin
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Planning Component") and
                (FilterReservEntry."Source Subtype" = 0);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        PlanningComponent: Record "Planning Component";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(PlanningComponent);
            CreateReservation(PlanningComponent, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    var
        ReqLine: Record "Requisition Line";
    begin
        if MatchThisTable(SourceType) then begin
            ReqLine.Reset();
            ReqLine.SetRange("Worksheet Template Name", SourceID);
            ReqLine.SetRange("Journal Batch Name", SourceBatchName);
            ReqLine.SetRange("Line No.", SourceProdOrderLine);
            PAGE.RunModal(PAGE::"Requisition Lines", ReqLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer)
    var
        PlanningComponent: Record "Planning Component";
    begin
        if MatchThisTable(SourceType) then begin
            PlanningComponent.Reset();
            PlanningComponent.SetRange("Worksheet Template Name", SourceID);
            PlanningComponent.SetRange("Worksheet Batch Name", SourceBatchName);
            PlanningComponent.SetRange("Worksheet Line No.", SourceProdOrderLine);
            PlanningComponent.SetRange("Line No.", SourceRefNo);
            PAGE.Run(0, PlanningComponent);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        PlanningComponent: Record "Planning Component";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(PlanningComponent);
            PlanningComponent.SetReservationFilters(ReservEntry);
            CaptionText := PlanningComponent.GetSourceCaption;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        PlanningComponent: Record "Planning Component";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(PlanningComponent);
            PlanningComponent.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.Get(
          ReservEntry."Source ID", ReservEntry."Source Batch Name",
          ReservEntry."Source Prod. Order Line", ReservEntry."Source Ref. No.");
        SourceRecRef.GetTable(PlanningComponent);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(PlanningComponent."Net Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(PlanningComponent."Expected Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
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

