namespace Microsoft.Inventory.Planning;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;

codeunit 99000840 "Plng. Component-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Action Message Entry" = rd;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationManagement: Codeunit "Reservation Management";
        Blocked: Boolean;

        Text000: Label 'Reserved quantity cannot be greater than %1.';
        Text002: Label 'must be filled in when a quantity is reserved';
        Text003: Label 'must not be changed when a quantity is reserved';
        Text004: Label 'Codeunit is not initialized correctly.';

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
          Database::"Planning Component", 0,
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

    procedure CreateBindingReservation(PlanningComponent: Record "Planning Component"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservationEntry: Record "Reservation Entry";
    begin
        CreateReservation(PlanningComponent, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservationEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure SetBinding(Binding: Enum "Reservation Binding")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure Caption(PlanningComponent: Record "Planning Component") CaptionText: Text
    begin
        CaptionText := PlanningComponent.GetSourceCaption();
    end;

    procedure FindReservEntry(PlanningComponent: Record "Planning Component"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        PlanningComponent.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
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
           (not ReservationManagement.CalcIsAvailTrackedQtyInBin(
              NewPlanningComponent."Item No.", NewPlanningComponent."Bin Code",
              NewPlanningComponent."Location Code", NewPlanningComponent."Variant Code",
              Database::"Planning Component", 0,
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
                    ReservationManagement.SetReservSource(OldPlanningComponent);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewPlanningComponent);
                end else begin
                    ReservationManagement.SetReservSource(NewPlanningComponent);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewPlanningComponent."Net Quantity (Base)");
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

        if NewPlanningComponent."Line No." = OldPlanningComponent."Line No." then
            if NewPlanningComponent."Net Quantity (Base)" = OldPlanningComponent."Net Quantity (Base)" then
                exit;
        if NewPlanningComponent."Line No." = 0 then
            if not PlanningComponent.Get(
                    NewPlanningComponent."Worksheet Template Name",
                    NewPlanningComponent."Worksheet Batch Name",
                    NewPlanningComponent."Worksheet Line No.",
                    NewPlanningComponent."Line No.")
            then
                exit;
        ReservationManagement.SetReservSource(NewPlanningComponent);
        if NewPlanningComponent."Qty. per Unit of Measure" <> OldPlanningComponent."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        if NewPlanningComponent."Net Quantity (Base)" * OldPlanningComponent."Net Quantity (Base)" < 0 then
            ReservationManagement.DeleteReservEntries(true, 0)
        else
            ReservationManagement.DeleteReservEntries(false, NewPlanningComponent."Net Quantity (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewPlanningComponent."Net Quantity (Base)");
        AssignForPlanning(NewPlanningComponent);
    end;

    procedure TransferPlanningCompToPOComp(var OldPlanningComponent: Record "Planning Component"; var NewProdOrderComponent: Record "Prod. Order Component"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservationEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(OldPlanningComponent, OldReservationEntry) then
            exit;

        NewProdOrderComponent.TestItemFields(
          OldPlanningComponent."Item No.", OldPlanningComponent."Variant Code", OldPlanningComponent."Location Code");

        TransferReservations(
          OldPlanningComponent, OldReservationEntry, TransferAll, TransferQty, NewProdOrderComponent."Qty. per Unit of Measure",
          DATABASE::"Prod. Order Component", NewProdOrderComponent.Status, NewProdOrderComponent."Prod. Order No.",
          '', NewProdOrderComponent."Prod. Order Line No.", NewProdOrderComponent."Line No.");
    end;

    procedure TransferPlanningCompToAsmLine(var OldPlanningComponent: Record "Planning Component"; var NewAssemblyLine: Record "Assembly Line"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservationEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(OldPlanningComponent, OldReservationEntry) then
            exit;

        NewAssemblyLine.TestItemFields(
          OldPlanningComponent."Item No.", OldPlanningComponent."Variant Code", OldPlanningComponent."Location Code");

        TransferReservations(
          OldPlanningComponent, OldReservationEntry, TransferAll, TransferQty, NewAssemblyLine."Qty. per Unit of Measure",
          DATABASE::"Assembly Line", NewAssemblyLine."Document Type", NewAssemblyLine."Document No.",
          '', 0, NewAssemblyLine."Line No.");
    end;

    local procedure TransferReservations(var OldPlanningComponent: Record "Planning Component"; var OldReservationEntry: Record "Reservation Entry"; TransferAll: Boolean; TransferQty: Decimal; QtyPerUOM: Decimal; SrcType: Integer; SrcSubtype: Option; SrcID: Code[20]; SrcBatchName: Code[10]; SrcProdOrderLine: Integer; SrcRefNo: Integer)
    var
        NewReservationEntry: Record "Reservation Entry";
        ReservStatus: Enum "Reservation Status";
    begin
        OldReservationEntry.Lock();

        if TransferAll then begin
            OldReservationEntry.FindSet();
            OldReservationEntry.TestField("Qty. per Unit of Measure", QtyPerUOM);
            repeat
                OldReservationEntry.TestItemFields(
                  OldPlanningComponent."Item No.", OldPlanningComponent."Variant Code", OldPlanningComponent."Location Code");
                NewReservationEntry := OldReservationEntry;
                NewReservationEntry.SetSource(SrcType, SrcSubtype, SrcID, SrcRefNo, SrcBatchName, SrcProdOrderLine);
                NewReservationEntry.Modify();
            until OldReservationEntry.Next() = 0;
        end else
            for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
                if TransferQty = 0 then
                    exit;
                OldReservationEntry.SetRange("Reservation Status", ReservStatus);

                if OldReservationEntry.FindSet() then
                    repeat
                        OldReservationEntry.TestItemFields(
                          OldPlanningComponent."Item No.", OldPlanningComponent."Variant Code", OldPlanningComponent."Location Code");

                        TransferQty :=
                          CreateReservEntry.TransferReservEntry(
                            SrcType, SrcSubtype, SrcID, SrcBatchName, SrcProdOrderLine, SrcRefNo, QtyPerUOM, OldReservationEntry, TransferQty);
                    until (OldReservationEntry.Next() = 0) or (TransferQty = 0);
            end;
    end;

    procedure DeleteLine(var PlanningComponent: Record "Planning Component")
    begin
        if Blocked then
            exit;

        ReservationManagement.SetReservSource(PlanningComponent);
        ReservationManagement.SetItemTrackingHandling(1); // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        PlanningComponent.CalcFields("Reserved Qty. (Base)");
        AssignForPlanning(PlanningComponent);
    end;

    procedure UpdateDerivedTracking(var PlanningComponent: Record "Planning Component")
    var
        ReservationEntry: Record "Reservation Entry";
        ReservationEntry2: Record "Reservation Entry";
        ActionMessageEntry: Record "Action Message Entry";
    begin
        ReservationEntry.InitSortingAndFilters(false);
        ActionMessageEntry.SetCurrentKey("Reservation Entry");

        ReservationEntry.SetFilter("Shipment Date", '<>%1', PlanningComponent."Due Date");
        case PlanningComponent."Ref. Order Type" of
            PlanningComponent."Ref. Order Type"::"Prod. Order":
                ReservationEntry.SetSourceFilter(
                    DATABASE::"Prod. Order Component", PlanningComponent."Ref. Order Status".AsInteger(),
                    PlanningComponent."Ref. Order No.", PlanningComponent."Line No.", false);
            PlanningComponent."Ref. Order Type"::Assembly:
                ReservationEntry.SetSourceFilter(
                    DATABASE::"Assembly Line", PlanningComponent."Ref. Order Status".AsInteger(),
                    PlanningComponent."Ref. Order No.", PlanningComponent."Line No.", false);
        end;
        ReservationEntry.SetRange("Source Prod. Order Line", PlanningComponent."Ref. Order Line No.");
        if ReservationEntry.FindSet() then
            repeat
                ReservationEntry2 := ReservationEntry;
                ReservationEntry2."Shipment Date" := PlanningComponent."Due Date";
                ReservationEntry2.Modify();
                if ReservationEntry2.Get(ReservationEntry2."Entry No.", not ReservationEntry2.Positive) then begin
                    ReservationEntry2."Shipment Date" := PlanningComponent."Due Date";
                    ReservationEntry2.Modify();
                end;
                ActionMessageEntry.SetRange("Reservation Entry", ReservationEntry."Entry No.");
                ActionMessageEntry.DeleteAll();
            until ReservationEntry.Next() = 0;
    end;

    local procedure AssignForPlanning(var PlanningComponent: Record "Planning Component")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if PlanningComponent."Item No." <> '' then
            PlanningAssignment.ChkAssignOne(PlanningComponent."Item No.", PlanningComponent."Variant Code", PlanningComponent."Location Code", PlanningComponent."Due Date");
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
        ItemTrackingLines.RunModal();

        OnAfterCallItemTracking(PlanningComponent);
    end;

    procedure BindToRequisition(PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        if PlanningComponent."Location Code" <> RequisitionLine."Location Code" then
            exit;

        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Requisition Line", 0,
          RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", 0, RequisitionLine."Line No.",
          RequisitionLine."Variant Code", RequisitionLine."Location Code", RequisitionLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(PlanningComponent, RequisitionLine.Description, RequisitionLine."Ending Date", ReservQty, ReservQtyBase);
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        PlanningComponent: Record "Planning Component";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(PlanningComponent);
            PlanningComponent.Find();
            QtyPerUOM := PlanningComponent.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        PlanningComponent: Record "Planning Component";
    begin
        SourceRecordRef.SetTable(PlanningComponent);
        PlanningComponent.TestField("Due Date");

        PlanningComponent.SetReservationEntry(ReservationEntry);

        CaptionText := PlanningComponent.GetSourceCaption();
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo = 91);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"Planning Component");
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
            AvailPlanningComponents.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailPlanningComponents.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", Database::"Planning Component");
            FilterReservEntry.SetRange("Source Subtype", 0);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"Planning Component") and
                (FilterReservEntry."Source Subtype" = 0);
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
            CaptionText := PlanningComponent.GetSourceCaption();
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

