namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;

codeunit 99000837 "Prod. Order Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Action Message Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservationManagement: Codeunit "Reservation Management";
        Blocked: Boolean;

        Text000: Label 'Reserved quantity cannot be greater than %1';
        Text002: Label 'must be filled in when a quantity is reserved';
        Text003: Label 'must not be changed when a quantity is reserved';
        Text004: Label 'Codeunit is not initialized correctly.';
        Text006: Label 'The %1 %2 %3 has item tracking. Do you want to delete it anyway?';
        Text007: Label 'The %1 %2 %3 has components with item tracking. Do you want to delete it anyway?';
        Text008: Label 'The %1 %2 %3 and its components have item tracking. Do you want to delete them anyway?';
        Text010: Label 'Firm Planned %1';
        Text011: Label 'Released %1';

    procedure CreateReservation(var ProdOrderLine: Record "Prod. Order Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "Reservation Entry")
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
            Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(),
            ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
            ProdOrderLine."Qty. per Unit of Measure", Quantity, QuantityBase, ForReservationEntry);
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

    procedure FindReservEntry(ProdOrderLine: Record "Prod. Order Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        ProdOrderLine.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
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
                    ReservationManagement.SetReservSource(OldProdOrderLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewProdOrderLine);
                end else begin
                    ReservationManagement.SetReservSource(NewProdOrderLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewProdOrderLine."Remaining Qty. (Base)");
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

        if NewProdOrderLine.Status = NewProdOrderLine.Status::Finished then
            exit;
        if NewProdOrderLine."Line No." = OldProdOrderLine."Line No." then
            if NewProdOrderLine."Quantity (Base)" = OldProdOrderLine."Quantity (Base)" then
                exit;
        if NewProdOrderLine."Line No." = 0 then
            if not ProdOrderLine.Get(NewProdOrderLine.Status, NewProdOrderLine."Prod. Order No.", NewProdOrderLine."Line No.") then
                exit;
        ReservationManagement.SetReservSource(NewProdOrderLine);
        if NewProdOrderLine."Qty. per Unit of Measure" <> OldProdOrderLine."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        ReservationManagement.DeleteReservEntries(false, NewProdOrderLine."Remaining Qty. (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewProdOrderLine."Remaining Qty. (Base)");
        AssignForPlanning(NewProdOrderLine);
    end;

    procedure UpdatePlanningFlexibility(var ProdOrderLine: Record "Prod. Order Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if FindReservEntry(ProdOrderLine, ReservationEntry) then
            ReservationEntry.ModifyAll("Planning Flexibility", ProdOrderLine."Planning Flexibility");
    end;

    procedure TransferPOLineToPOLine(var OldProdOrderLine: Record "Prod. Order Line"; var NewProdOrderLine: Record "Prod. Order Line"; TransferQty: Decimal; TransferAll: Boolean)
    var
        OldReservationEntry: Record "Reservation Entry";
    begin
        OnBeforeTransferPOLineToPOLine(OldProdOrderLine, NewProdOrderLine);

        if not FindReservEntry(OldProdOrderLine, OldReservationEntry) then
            exit;

        OldReservationEntry.Lock();

        NewProdOrderLine.TestItemFields(OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code");

        OldReservationEntry.TransferReservations(
            OldReservationEntry, OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code",
            TransferAll, TransferQty, NewProdOrderLine."Qty. per Unit of Measure",
            Database::"Prod. Order Line", NewProdOrderLine.Status.AsInteger(), NewProdOrderLine."Prod. Order No.", '', NewProdOrderLine."Line No.", 0);
    end;

    procedure TransferPOLineToItemJnlLine(var OldProdOrderLine: Record "Prod. Order Line"; var NewItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal)
    var
        OldReservationEntry: Record "Reservation Entry";
        ItemTrackingFilterIsSet: Boolean;
        EndLoop: Boolean;
        IsHandled: Boolean;
    begin
        if not FindReservEntry(OldProdOrderLine, OldReservationEntry) then
            exit;

        OnTransferPOLineToItemJnlLineOnBeforeHandleItemTrackingOutput(OldProdOrderLine, NewItemJournalLine, OldReservationEntry, IsHandled);
        if IsHandled then
            exit;

        // Handle Item Tracking on output:
        Clear(CreateReservEntry);
        SetTrackingFilterFromItemJnlLine(OldReservationEntry, NewItemJournalLine, ItemTrackingFilterIsSet);

        IsHandled := false;
        OnTransferPOLineToItemJnlLineOnBeforeTestItemJnlLineFields(NewItemJournalLine, OldProdOrderLine, IsHandled);
        if not IsHandled then
            NewItemJournalLine.TestItemFields(OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ReservationEngineMgt.InitRecordSet(OldReservationEntry) then
            repeat
                SetNewTrackingFromItemJnlLine(NewItemJournalLine, OldReservationEntry);
                OldReservationEntry.TestItemFields(OldProdOrderLine."Item No.", OldProdOrderLine."Variant Code", OldProdOrderLine."Location Code");

                TransferPOLineToItemJnlLineReservEntry(OldProdOrderLine, NewItemJournalLine, OldReservationEntry, TransferQty);

                EndLoop := TransferQty = 0;
                if not EndLoop then
                    if ReservationEngineMgt.NEXTRecord(OldReservationEntry) = 0 then
                        if ItemTrackingFilterIsSet then begin
                            OldReservationEntry.ClearTrackingFilter();
                            ItemTrackingFilterIsSet := false;
                            EndLoop := not ReservationEngineMgt.InitRecordSet(OldReservationEntry);
                        end else
                            EndLoop := true;
            until EndLoop;
    end;


    local procedure SetNewTrackingFromItemJnlLine(var NewItemJournalLine: Record "Item Journal Line"; OldReservationEntry: Record "Reservation Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetNewTrackingFromItemJnlLine(CreateReservEntry, NewItemJournalLine, OldReservationEntry, IsHandled);
        if IsHandled then
            exit;

        if NewItemJournalLine.TrackingExists() then
            CreateReservEntry.SetNewTrackingFromItemJnlLine(NewItemJournalLine);
    end;

    local procedure SetTrackingFilterFromItemJnlLine(var OldReservationEntry: Record "Reservation Entry"; var NewItemJournalLine: Record "Item Journal Line"; var ItemTrackingFilterIsSet: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetTrackingFilterFromItemJnlLine(OldReservationEntry, NewItemJournalLine, ItemTrackingFilterIsSet, IsHandled);
        if IsHandled then
            exit;

        if NewItemJournalLine."Entry Type" = NewItemJournalLine."Entry Type"::Output then
            if NewItemJournalLine.TrackingExists() then begin
                // Try to match against Item Tracking on the prod. order line:
                OldReservationEntry.SetTrackingFilterFromItemJnlLine(NewItemJournalLine);
                if OldReservationEntry.IsEmpty() then
                    OldReservationEntry.ClearTrackingFilter()
                else
                    ItemTrackingFilterIsSet := true;
            end;
    end;

    local procedure TransferPOLineToItemJnlLineReservEntry(ProdOrderLine: Record "Prod. Order Line"; ItemJournalLine: Record "Item Journal Line"; OldReservationEntry: Record "Reservation Entry"; var TransferQty: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferPOLineToItemJnlLineReservEntry(OldReservationEntry, ProdOrderLine, ItemJournalLine, TransferQty, IsHandled);
        if IsHandled then
            exit;

        TransferQty :=
            CreateReservEntry.TransferReservEntry(
                DATABASE::"Item Journal Line",
                ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", 0,
                ItemJournalLine."Line No.", ItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);
    end;

    procedure DeleteLineConfirm(var ProdOrderLine: Record "Prod. Order Line"): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
        ReservationEntry2: Record "Reservation Entry";
        ConfirmMessage: Text[250];
        HasItemTracking: Option "None",Line,Components,"Line and Components";
    begin
        ProdOrderLine.SetReservationFilters(ReservationEntry);

        ReservationEntry.SetFilter("Item Tracking", '<> %1', ReservationEntry."Item Tracking"::None);
        if not ReservationEntry.IsEmpty() then
            HasItemTracking := HasItemTracking::Line;

        ReservationEntry.SetRange("Source Type", Database::"Prod. Order Component");
        ReservationEntry.SetFilter("Source Ref. No.", ' > %1', 0);
        if not ReservationEntry.IsEmpty() then
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

        ReservationEntry.SetFilter(ReservationEntry."Source Type", '%1|%2', Database::"Prod. Order Line", Database::"Prod. Order Component");
        ReservationEntry.SetRange(ReservationEntry."Source Ref. No.");
        if ReservationEntry.FindSet() then
            repeat
                ReservationEntry2 := ReservationEntry;
                ReservationEntry2.ClearItemTrackingFields();
                ReservationEntry2.Modify();
                OnDeleteLineConfirmOnAfterReservEntry2Modify(ReservationEntry);
            until ReservationEntry.Next() = 0;

        exit(true);
    end;

    procedure DeleteLine(var ProdOrderLine: Record "Prod. Order Line")
    begin
        if Blocked then
            exit;

        ReservationManagement.SetReservSource(ProdOrderLine);
        ReservationManagement.DeleteReservEntries(true, 0);
        OnDeleteLineOnAfterDeleteReservEntries(ProdOrderLine);
        ReservationManagement.ClearActionMessageReferences();
        ProdOrderLine.CalcFields(ProdOrderLine."Reserved Qty. (Base)");
        AssignForPlanning(ProdOrderLine);
    end;

    procedure AssignForPlanning(var ProdOrderLine: Record "Prod. Order Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if ProdOrderLine.Status = ProdOrderLine.Status::Simulated then
            exit;
        if ProdOrderLine."Item No." <> '' then
            PlanningAssignment.ChkAssignOne(ProdOrderLine."Item No.", ProdOrderLine."Variant Code", ProdOrderLine."Location Code", WorkDate());
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
                    Database::"Prod. Order Line", ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", 0)
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
        ReservationEntry: Record "Reservation Entry";
    begin
        // Used for updating Quantity to Handle after posting;
        ReservationEntry.SetSourceFilter(Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", -1, true);
        ReservationEntry.SetSourceFilter('', ProdOrderLine."Line No.");
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservationEntry);
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

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        SourceRecordRef.SetTable(ProdOrderLine);
        ProdOrderLine.TestField("Due Date");

        ProdOrderLine.SetReservationEntry(ReservationEntry);

        CaptionText := ProdOrderLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(Enum::"Reservation Summary Type"::"Simulated Production Order".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [Enum::"Reservation Summary Type"::"Simulated Production Order".AsInteger(),
                         Enum::"Reservation Summary Type"::"Planned Production Order".AsInteger(),
                         Enum::"Reservation Summary Type"::"Firm Planned Production Order".AsInteger(),
                         Enum::"Reservation Summary Type"::"Released Production Order".AsInteger()]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"Prod. Order Line");
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
            FilterReservEntry.SetRange("Source Type", Database::"Prod. Order Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"Prod. Order Line") and
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

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Prod. Order Line");
        SourceRecordRef.GetTable(ProdOrderLine);
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

    local procedure UpdateStatistics(ReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; Status: Enum "Production Order Status"; Positive: Boolean; var TotalQuantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        AvailabilityFilter: Text;
    begin
        if not ProdOrderLine.ReadPermission then
            exit;

        AvailabilityFilter := ReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        ProdOrderLine.FilterLinesForReservation(ReservationEntry, Status.AsInteger(), AvailabilityFilter, Positive);
        if ProdOrderLine.FindSet() then
            repeat
                ProdOrderLine.CalcFields("Reserved Qty. (Base)");
                TempEntrySummary."Total Reserved Quantity" += ProdOrderLine."Reserved Qty. (Base)";
                TotalQuantity += ProdOrderLine."Remaining Qty. (Base)";
            until ProdOrderLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (TotalQuantity > 0) = Positive then begin
            TempEntrySummary."Table ID" := Database::"Prod. Order Line";
            if Status = ProdOrderLine.Status::"Firm Planned" then
                TempEntrySummary."Summary Type" := CopyStr(StrSubstNo(Text010, ProdOrderLine.TableCaption()), 1, MaxStrLen(TempEntrySummary."Summary Type"))
            else
                TempEntrySummary."Summary Type" := CopyStr(StrSubstNo(Text011, ProdOrderLine.TableCaption()), 1, MaxStrLen(TempEntrySummary."Summary Type"));
            TempEntrySummary."Total Quantity" := TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [Enum::"Reservation Summary Type"::"Firm Planned Production Order".AsInteger(),
                                           Enum::"Reservation Summary Type"::"Released Production Order".AsInteger()] then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, Enum::"Production Order Status".FromInteger(ReservSummEntry."Entry No." - 61), Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Reset();
        ProdOrderLine.SetRange(Status, ReservationEntry."Source Subtype");
        ProdOrderLine.SetRange("Prod. Order No.", ReservationEntry."Source ID");
        ProdOrderLine.SetRange("Line No.", ReservationEntry."Source Prod. Order Line");
        PAGE.RunModal(Page::"Prod. Order Line List", ProdOrderLine);
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

