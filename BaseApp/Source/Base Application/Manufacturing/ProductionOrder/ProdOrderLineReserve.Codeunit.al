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
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservMgt: Codeunit "Reservation Management";
        Blocked: Boolean;
        Text006: Label 'The %1 %2 %3 has item tracking. Do you want to delete it anyway?';
        Text007: Label 'The %1 %2 %3 has components with item tracking. Do you want to delete it anyway?';
        Text008: Label 'The %1 %2 %3 and its components have item tracking. Do you want to delete them anyway?';
        Text010: Label 'Firm Planned %1';
        Text011: Label 'Released %1';

    procedure CreateReservation(var ProdOrderLine: Record "Prod. Order Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text004);

        ProdOrderLine.TestField("Item No.");
        ProdOrderLine.TestField("Due Date");

        ProdOrderLine.CalcFields("Reserved Qty. (Base)");
        if Abs(ProdOrderLine."Remaining Qty. (Base)") < Abs(ProdOrderLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000,
              Abs(ProdOrderLine."Remaining Qty. (Base)") - Abs(ProdOrderLine."Reserved Qty. (Base)"));

        ProdOrderLine.TestField("Location Code", FromTrackingSpecification."Location Code");
        ProdOrderLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");

        if QuantityBase < 0 then
            ShipmentDate := ProdOrderLine."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ProdOrderLine."Due Date";
        end;

        if ProdOrderLine."Planning Flexibility" <> ProdOrderLine."Planning Flexibility"::Unlimited then
            CreateReservEntry.SetPlanningFlexibility(ProdOrderLine."Planning Flexibility");

        CreateReservEntry.CreateReservEntryFor(
            DATABASE::"Prod. Order Line", ProdOrderLine.Status.AsInteger(),
            ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
            ProdOrderLine."Qty. per Unit of Measure", Quantity, QuantityBase, ForReservEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
            ProdOrderLine."Item No.", ProdOrderLine."Variant Code", ProdOrderLine."Location Code",
            Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure Caption(ProdOrderLine: Record "Prod. Order Line") CaptionText: Text
    begin
        CaptionText := ProdOrderLine.GetSourceCaption();
    end;

    procedure FindReservEntry(ProdOrderLine: Record "Prod. Order Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.InitSortingAndFilters(false);
        ProdOrderLine.SetReservationFilters(ReservEntry);
        exit(ReservEntry.FindLast());
    end;

    procedure VerifyChange(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderLine: Record "Prod. Order Line";
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
            if (NewProdOrderLine."Item No." <> OldProdOrderLine."Item No.") or NewProdOrderLine.ReservEntryExist() then begin
                if NewProdOrderLine."Item No." <> OldProdOrderLine."Item No." then begin
                    ReservMgt.SetReservSource(OldProdOrderLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetReservSource(NewProdOrderLine);
                end else begin
                    ReservMgt.SetReservSource(NewProdOrderLine);
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
            ReservMgt.SetReservSource(NewProdOrderLine);
            if "Qty. per Unit of Measure" <> OldProdOrderLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure();
            ReservMgt.DeleteReservEntries(false, "Remaining Qty. (Base)");
            ReservMgt.ClearSurplus();
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

        OldReservEntry.Lock();

        NewProdOrderLine.TestItemFields(OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code");

        OldReservEntry.TransferReservations(
            OldReservEntry, OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code",
            TransferAll, TransferQty, NewProdOrderLine."Qty. per Unit of Measure",
            DATABASE::"Prod. Order Line", NewProdOrderLine.Status.AsInteger(), NewProdOrderLine."Prod. Order No.", '', NewProdOrderLine."Line No.", 0);
    end;

    procedure TransferPOLineToItemJnlLine(var OldProdOrderLine: Record "Prod. Order Line"; var NewItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal)
    var
        OldReservEntry: Record "Reservation Entry";
        ItemTrackingFilterIsSet: Boolean;
        EndLoop: Boolean;
        IsHandled: Boolean;
    begin
        if not FindReservEntry(OldProdOrderLine, OldReservEntry) then
            exit;

        OldReservEntry.Lock();
        OnTransferPOLineToItemJnlLineOnBeforeHandleItemTrackingOutput(OldProdOrderLine, NewItemJnlLine, OldReservEntry, IsHandled);
        if IsHandled then
            exit;

        // Handle Item Tracking on output:
        Clear(CreateReservEntry);
        SetTrackingFilterFromItemJnlLine(OldReservEntry, NewItemJnlLine, ItemTrackingFilterIsSet);

        IsHandled := false;
        OnTransferPOLineToItemJnlLineOnBeforeTestItemJnlLineFields(NewItemJnlLine, OldProdOrderLine, IsHandled);
        if not IsHandled then
            NewItemJnlLine.TestItemFields(OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ReservEngineMgt.InitRecordSet(OldReservEntry) then
            repeat
                SetNewTrackingFromItemJnlLine(CreateReservEntry, NewItemJnlLine, OldReservEntry);
                OldReservEntry.TestItemFields(OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code");

                TransferPOLineToItemJnlLineReservEntry(OldProdOrderLine, NewItemJnlLine, OldReservEntry, TransferQty);

                if ReservEngineMgt.NEXTRecord(OldReservEntry) = 0 then
                    if ItemTrackingFilterIsSet then begin
                        OldReservEntry.ClearTrackingFilter();
                        ItemTrackingFilterIsSet := false;
                        EndLoop := not ReservEngineMgt.InitRecordSet(OldReservEntry);
                    end else
                        EndLoop := true;

            until EndLoop or (TransferQty = 0);
    end;


    local procedure SetNewTrackingFromItemJnlLine(var CreateReservEntry: Codeunit "Create Reserv. Entry"; var NewItemJnlLine: Record "Item Journal Line"; OldReservEntry: Record "Reservation Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetNewTrackingFromItemJnlLine(CreateReservEntry, NewItemJnlLine, OldReservEntry, IsHandled);
        if IsHandled then
            exit;

        if NewItemJnlLine.TrackingExists() then
            CreateReservEntry.SetNewTrackingFromItemJnlLine(NewItemJnlLine);
    end;

    local procedure SetTrackingFilterFromItemJnlLine(var OldReservEntry: Record "Reservation Entry"; var NewItemJnlLine: Record "Item Journal Line"; var ItemTrackingFilterIsSet: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetTrackingFilterFromItemJnlLine(OldReservEntry, NewItemJnlLine, ItemTrackingFilterIsSet, IsHandled);
        if IsHandled then
            exit;

        if NewItemJnlLine."Entry Type" = NewItemJnlLine."Entry Type"::Output then
            if NewItemJnlLine.TrackingExists() then begin
                // Try to match against Item Tracking on the prod. order line:
                OldReservEntry.SetTrackingFilterFromItemJnlLine(NewItemJnlLine);
                if OldReservEntry.IsEmpty() then
                    OldReservEntry.ClearTrackingFilter()
                else
                    ItemTrackingFilterIsSet := true;
            end;
    end;

    local procedure TransferPOLineToItemJnlLineReservEntry(ProdOrderLine: Record "Prod. Order Line"; ItemJnlLine: Record "Item Journal Line"; OldReservEntry: Record "Reservation Entry"; var TransferQty: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferPOLineToItemJnlLineReservEntry(OldReservEntry, ProdOrderLine, ItemJnlLine, TransferQty, IsHandled);
        if IsHandled then
            exit;

        TransferQty :=
            CreateReservEntry.TransferReservEntry(
                DATABASE::"Item Journal Line",
                ItemJnlLine."Entry Type".AsInteger(), ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 0,
                ItemJnlLine."Line No.", ItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);
    end;

    procedure DeleteLineConfirm(var ProdOrderLine: Record "Prod. Order Line"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ConfirmMessage: Text[250];
        HasItemTracking: Option "None",Line,Components,"Line and Components";
    begin
        ProdOrderLine.SetReservationFilters(ReservEntry);

        with ReservEntry do begin
            SetFilter("Item Tracking", '<> %1', "Item Tracking"::None);
            if not IsEmpty() then
                HasItemTracking := HasItemTracking::Line;

            SetRange("Source Type", DATABASE::"Prod. Order Component");
            SetFilter("Source Ref. No.", ' > %1', 0);
            if not IsEmpty() then
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

            if not Confirm(ConfirmMessage, false, ProdOrderLine.Status, ProdOrderLine.TableCaption(), ProdOrderLine."Line No.") then
                exit(false);

            SetFilter("Source Type", '%1|%2', DATABASE::"Prod. Order Line", DATABASE::"Prod. Order Component");
            SetRange("Source Ref. No.");
            if FindSet() then
                repeat
                    ReservEntry2 := ReservEntry;
                    ReservEntry2.ClearItemTrackingFields();
                    ReservEntry2.Modify();
                    OnDeleteLineConfirmOnAfterReservEntry2Modify(ReservEntry);
                until Next() = 0;
        end;

        exit(true);
    end;

    procedure DeleteLine(var ProdOrderLine: Record "Prod. Order Line")
    begin
        if Blocked then
            exit;

        with ProdOrderLine do begin
            ReservMgt.SetReservSource(ProdOrderLine);
            ReservMgt.DeleteReservEntries(true, 0);
            OnDeleteLineOnAfterDeleteReservEntries(ProdOrderLine);
            ReservMgt.ClearActionMessageReferences();
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
                PlanningAssignment.ChkAssignOne("Item No.", "Variant Code", "Location Code", WorkDate());
        end;
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var ProdOrderLine: Record "Prod. Order Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingDocManagement: Codeunit "Item Tracking Doc. Management";
        ItemTrackingLines: Page "Item Tracking Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCallItemTracking(ProdOrderLine, IsHandled);
        if not IsHandled then
            if ProdOrderLine.Status = ProdOrderLine.Status::Finished then
                ItemTrackingDocManagement.ShowItemTrackingForProdOrderComp(
                    DATABASE::"Prod. Order Line", ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", 0)
            else begin
                ProdOrderLine.TestField("Item No.");
                TrackingSpecification.InitFromProdOrderLine(ProdOrderLine);
                ItemTrackingLines.SetSourceSpec(TrackingSpecification, ProdOrderLine."Due Date");
                ItemTrackingLines.SetInbound(ProdOrderLine.IsInbound());
                OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(ProdOrderLine, ItemTrackingLines);
                ItemTrackingLines.RunModal();
            end;

        OnAfterCallItemTracking(ProdOrderLine);
    end;

    procedure UpdateItemTrackingAfterPosting(ProdOrderLine: Record "Prod. Order Line")
    var
        ReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // Used for updating Quantity to Handle after posting;
        ReservEntry.SetSourceFilter(DATABASE::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", -1, true);
        ReservEntry.SetSourceFilter('', ProdOrderLine."Line No.");
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservEntry);
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ProdOrderLine);
            ProdOrderLine.Find();
            QtyPerUOM := ProdOrderLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        SourceRecRef.SetTable(ProdOrderLine);
        ProdOrderLine.TestField("Due Date");

        ProdOrderLine.SetReservationEntry(ReservEntry);

        CaptionText := ProdOrderLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit("Reservation Summary Type"::"Simulated Production Order".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in ["Reservation Summary Type"::"Simulated Production Order".AsInteger(),
                         "Reservation Summary Type"::"Planned Production Order".AsInteger(),
                         "Reservation Summary Type"::"Firm Planned Production Order".AsInteger(),
                         "Reservation Summary Type"::"Released Production Order".AsInteger()]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = 5406); // DATABASE::"Prod. Order Line"
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
        AvailableProdOrderLines: page "Available - Prod. Order Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailableProdOrderLines);
            AvailableProdOrderLines.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
            AvailableProdOrderLines.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailableProdOrderLines.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Prod. Order Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Prod. Order Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(ProdOrderLine);
            CreateReservation(ProdOrderLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        ProdOrder: Record "Production Order";
    begin
        if MatchThisTable(SourceType) then begin
            ProdOrder.Reset();
            ProdOrder.SetRange(Status, SourceSubtype);
            ProdOrder.SetRange("No.", SourceID);
            case SourceSubtype of
                0:
                    PAGE.RunModal(PAGE::"Simulated Production Order", ProdOrder);
                1:
                    PAGE.RunModal(PAGE::"Planned Production Order", ProdOrder);
                2:
                    PAGE.RunModal(PAGE::"Firm Planned Prod. Order", ProdOrder);
                3:
                    PAGE.RunModal(PAGE::"Released Production Order", ProdOrder);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceProdOrderLine: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if MatchThisTable(SourceType) then begin
            ProdOrderLine.Reset();
            ProdOrderLine.SetRange(Status, SourceSubtype);
            ProdOrderLine.SetRange("Prod. Order No.", SourceID);
            ProdOrderLine.SetRange("Line No.", SourceProdOrderLine);
            PAGE.Run(0, ProdOrderLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ProdOrderLine);
            ProdOrderLine.SetReservationFilters(ReservEntry);
            CaptionText := ProdOrderLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(ProdOrderLine);
            ProdOrderLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Prod. Order Line");
        SourceRecRef.GetTable(ProdOrderLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ProdOrderLine."Remaining Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ProdOrderLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; Status: Enum "Production Order Status"; Positive: Boolean; var TotalQuantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        AvailabilityFilter: Text;
    begin
        if not ProdOrderLine.ReadPermission then
            exit;

        AvailabilityFilter := CalcReservEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        ProdOrderLine.FilterLinesForReservation(CalcReservEntry, Status.AsInteger(), AvailabilityFilter, Positive);
        if ProdOrderLine.FindSet() then
            repeat
                ProdOrderLine.CalcFields("Reserved Qty. (Base)");
                TempEntrySummary."Total Reserved Quantity" += ProdOrderLine."Reserved Qty. (Base)";
                TotalQuantity += ProdOrderLine."Remaining Qty. (Base)";
            until ProdOrderLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        with TempEntrySummary do
            if (TotalQuantity > 0) = Positive then begin
                "Table ID" := DATABASE::"Prod. Order Line";
                if Status = ProdOrderLine.Status::"Firm Planned" then
                    "Summary Type" := CopyStr(StrSubstNo(Text010, ProdOrderLine.TableCaption()), 1, MaxStrLen("Summary Type"))
                else
                    "Summary Type" := CopyStr(StrSubstNo(Text011, ProdOrderLine.TableCaption()), 1, MaxStrLen("Summary Type"));
                "Total Quantity" := TotalQuantity;
                "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                if not Insert() then
                    Modify();
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in ["Reservation Summary Type"::"Firm Planned Production Order".AsInteger(),
                                           "Reservation Summary Type"::"Released Production Order".AsInteger()] then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, "Production Order Status".FromInteger(ReservSummEntry."Entry No." - 61), Positive, TotalQuantity);
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
    local procedure OnBeforeSetTrackingFilterFromItemJnlLine(OldReservEntry: Record "Reservation Entry"; var NewItemJnlLine: Record "Item Journal Line"; var ItemTrackingFilterIsSet: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetNewTrackingFromItemJnlLine(var CreateReservEntry: Codeunit "Create Reserv. Entry"; var NewItemJnlLine: Record "Item Journal Line"; OldReservEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferPOLineToItemJnlLineReservEntry(OldReservEntry: Record "Reservation Entry"; ProdOrderLine: Record "Prod. Order Line"; ItemJnlLine: Record "Item Journal Line"; var TransferQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteLineOnAfterDeleteReservEntries(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPOLineToItemJnlLineOnBeforeHandleItemTrackingOutput(var OldProdOrderLine: Record "Prod. Order Line"; var NewItemJnlLine: Record "Item Journal Line"; var OldReservEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPOLineToItemJnlLineOnBeforeTestItemJnlLineFields(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewProdOrderLine: Record "Prod. Order Line"; OldProdOrderLine: Record "Prod. Order Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(var ProdOrderLine: Record "Prod. Order Line"; var ItemTrackingLines: Page "Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteLineConfirmOnAfterReservEntry2Modify(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallItemTracking(var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;
}

