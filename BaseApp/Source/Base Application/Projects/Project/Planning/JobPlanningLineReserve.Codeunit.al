namespace Microsoft.Projects.Project.Planning;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Document;

codeunit 1032 "Job Planning Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Planning Assignment" = rimd;

    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservationManagement: Codeunit "Reservation Management";

        Text000Err: Label 'Reserved quantity cannot be greater than %1.', Comment = '%1 - qualtity';
        Text002Err: Label 'must be filled in when a quantity is reserved', Comment = 'starts with "Planning Date"';
        Text004Err: Label 'must not be changed when a quantity is reserved', Comment = 'starts with some field name';
        Text005Err: Label 'Codeunit is not initialized correctly.';
        InvalidLineTypeErr: Label 'must be %1 or %2', Comment = '%1 and %2 are line type options, fx. Budget or Billable';
        SummaryTypeTxt: Label '%1, %2', Locked = true;

    procedure CreateReservation(JobPlanningLine: Record "Job Planning Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        PlanningDate: Date;
        SignFactor: Integer;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text005Err);

        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.TestField("No.");
        JobPlanningLine.TestField("Planning Date");

        JobPlanningLine.CalcFields("Reserved Qty. (Base)");
        CheckReservedQtyBase(JobPlanningLine, QuantityBase);

        JobPlanningLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        JobPlanningLine.TestField("Location Code", FromTrackingSpecification."Location Code");

        SignFactor := -1;

        if QuantityBase * SignFactor < 0 then
            PlanningDate := JobPlanningLine."Planning Date"
        else begin
            PlanningDate := ExpectedReceiptDate;
            ExpectedReceiptDate := JobPlanningLine."Planning Date";
        end;

        CreateReservEntry.CreateReservEntryFor(
          Database::"Job Planning Line", JobPlanningLine.Status.AsInteger(),
          JobPlanningLine."Job No.", '', 0, JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForReservEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Location Code",
          Description, ExpectedReceiptDate, PlanningDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    procedure CreateBindingReservation(JobPlanningLine: Record "Job Planning Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservationEntry: Record "Reservation Entry";
    begin
        CreateReservation(JobPlanningLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservationEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    local procedure CheckReservedQtyBase(JobPlanningLine: Record "Job Planning Line"; QuantityBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReservedQtyBase(JobPlanningLine, IsHandled, QuantityBase);
        if IsHandled then
            exit;

        if Abs(JobPlanningLine."Remaining Qty. (Base)") < Abs(JobPlanningLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
              Text000Err,
              Abs(JobPlanningLine."Remaining Qty. (Base)") - Abs(JobPlanningLine."Reserved Qty. (Base)"));
    end;

    procedure SetBinding(Binding: Enum "Reservation Binding")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    procedure CallItemTracking(var JobPlanningLine: Record "Job Planning Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingDocManagement: Codeunit "Item Tracking Doc. Management";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        // Throw error if "Type" != "Item" or "Line Type" != "Budget" or "Budget and Billable"
        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        if not (JobPlanningLine."Line Type" in [Enum::"Job Planning Line Line Type"::"Both Budget and Billable", Enum::"Job Planning Line Line Type"::Budget]) then
            JobPlanningLine.FieldError("Line Type", StrSubstNo(InvalidLineTypeErr, Enum::"Job Planning Line Line Type"::Budget, Enum::"Job Planning Line Line Type"::"Both Budget and Billable"));

        if JobPlanningLine.Status = JobPlanningLine.Status::Completed then
            ItemTrackingDocManagement.ShowItemTrackingForJobPlanningLine(DATABASE::"Job Planning Line", JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.")
        else begin
            JobPlanningLine.TestField("No.");
            TrackingSpecification.InitFromJobPlanningLine(JobPlanningLine);
            ItemTrackingLines.SetSourceSpec(TrackingSpecification, JobPlanningLine."Planning Due Date");
            ItemTrackingLines.SetInbound(JobPlanningLine.IsInbound());
            ItemTrackingLines.RunModal();
        end;
    end;

    procedure ReservQuantity(JobPlanningLine: Record "Job Planning Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
        case JobPlanningLine.Status of
            JobPlanningLine.Status::Planning,
            JobPlanningLine.Status::Quote,
            JobPlanningLine.Status::Order,
            JobPlanningLine.Status::Completed:
                begin
                    QtyToReserve := JobPlanningLine."Remaining Qty.";
                    QtyToReserveBase := JobPlanningLine."Remaining Qty. (Base)";
                end;
        end;

        OnAfterReservQuantity(JobPlanningLine, QtyToReserve, QtyToReserveBase);
    end;

    procedure Caption(JobPlanningLine: Record "Job Planning Line") CaptionText: Text
    begin
        CaptionText := JobPlanningLine.GetSourceCaption();
    end;

    procedure FindReservEntry(JobPlanningLine: Record "Job Planning Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        JobPlanningLine.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
    end;

    procedure GetReservedQtyFromInventory(JobPlanningLine: Record "Job Planning Line"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        JobPlanningLine.SetReservationEntry(ReservationEntry);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure GetReservedQtyFromInventory(Job: Record Job): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    begin
        ReservationEntry.SetSource(Database::"Job Planning Line", Job.Status.AsInteger(), Job."No.", 0, '', 0);
        QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
        QtyReservedFromItemLedger.Open();
        if QtyReservedFromItemLedger.Read() then
            exit(QtyReservedFromItemLedger.Quantity__Base_);

        exit(0);
    end;

    procedure VerifyChange(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        ReservationEntry: Record "Reservation Entry";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if (NewJobPlanningLine.Type <> NewJobPlanningLine.Type::Item) and (OldJobPlanningLine.Type <> OldJobPlanningLine.Type::Item) then
            exit;
        if NewJobPlanningLine."Job Contract Entry No." = 0 then
            if not JobPlanningLine.Get(
                 NewJobPlanningLine."Job No.",
                 NewJobPlanningLine."Job Task No.",
                 NewJobPlanningLine."Line No.")
            then
                exit;

        NewJobPlanningLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewJobPlanningLine."Reserved Qty. (Base)" <> 0;

        if NewJobPlanningLine."Usage Link" <> OldJobPlanningLine."Usage Link" then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Usage Link", Text004Err);
            HasError := true;
        end;

        if (NewJobPlanningLine."Planning Date" = 0D) and (OldJobPlanningLine."Planning Date" <> 0D) then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Planning Date", Text002Err);
            HasError := true;
        end;

        if NewJobPlanningLine."No." <> OldJobPlanningLine."No." then begin
            if ShowError then
                NewJobPlanningLine.FieldError("No.", Text004Err);
            HasError := true;
        end;

        if NewJobPlanningLine."Variant Code" <> OldJobPlanningLine."Variant Code" then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Variant Code", Text004Err);
            HasError := true;
        end;

        if NewJobPlanningLine."Location Code" <> OldJobPlanningLine."Location Code" then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Location Code", Text004Err);
            HasError := true;
        end;

        if NewJobPlanningLine."Line No." <> OldJobPlanningLine."Line No." then
            HasError := true;

        if NewJobPlanningLine.Type <> OldJobPlanningLine.Type then begin
            if ShowError then
                NewJobPlanningLine.FieldError(Type, Text004Err);
            HasError := true;
        end;

        VerifyBinInJobPlanningLine(NewJobPlanningLine, OldJobPlanningLine, HasError);

        OnVerifyChangeOnBeforeHasErrorCheck(NewJobPlanningLine, OldJobPlanningLine, HasError, ShowError);

        if HasError then
            if (NewJobPlanningLine."No." <> OldJobPlanningLine."No.") or
               FindReservEntry(NewJobPlanningLine, ReservationEntry)
            then begin
                if (NewJobPlanningLine."No." <> OldJobPlanningLine."No.") or (NewJobPlanningLine.Type <> OldJobPlanningLine.Type) then begin
                    ReservationManagement.SetReservSource(OldJobPlanningLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewJobPlanningLine);
                end else begin
                    ReservationManagement.SetReservSource(NewJobPlanningLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewJobPlanningLine."Remaining Qty. (Base)");
            end;

        if HasError or (NewJobPlanningLine."Planning Date" <> OldJobPlanningLine."Planning Date")
        then begin
            AssignForPlanning(NewJobPlanningLine);
            if (NewJobPlanningLine."No." <> OldJobPlanningLine."No.") or
               (NewJobPlanningLine."Variant Code" <> OldJobPlanningLine."Variant Code") or
               (NewJobPlanningLine."Location Code" <> OldJobPlanningLine."Location Code")
            then
                AssignForPlanning(OldJobPlanningLine);
        end;
    end;

    local procedure VerifyBinInJobPlanningLine(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line"; var HasError: Boolean)
    begin
        if (NewJobPlanningLine.Type = NewJobPlanningLine.Type::Item) and (OldJobPlanningLine.Type = OldJobPlanningLine.Type::Item) then
            if (NewJobPlanningLine."Bin Code" <> OldJobPlanningLine."Bin Code") and
               (not ReservationManagement.CalcIsAvailTrackedQtyInBin(
                  NewJobPlanningLine."No.", NewJobPlanningLine."Bin Code",
                  NewJobPlanningLine."Location Code", NewJobPlanningLine."Variant Code",
                  DATABASE::"Job Planning Line", NewJobPlanningLine.Status.AsInteger(),
                  NewJobPlanningLine."Job No.", '', 0,
                  NewJobPlanningLine."Job Contract Entry No."))
            then
                HasError := true;
    end;

    procedure VerifyQuantity(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyQuantity(NewJobPlanningLine, OldJobPlanningLine, IsHandled);
        if IsHandled then
            exit;

        if NewJobPlanningLine.Type <> NewJobPlanningLine.Type::Item then
            exit;
        if NewJobPlanningLine.Status = OldJobPlanningLine.Status then
            if NewJobPlanningLine."Line No." = OldJobPlanningLine."Line No." then
                if NewJobPlanningLine."Quantity (Base)" = OldJobPlanningLine."Quantity (Base)" then
                    exit;
        if NewJobPlanningLine."Line No." = 0 then
            if not JobPlanningLine.Get(NewJobPlanningLine."Job No.", NewJobPlanningLine."Job Task No.", NewJobPlanningLine."Line No.") then
                exit;
        ReservationManagement.SetReservSource(NewJobPlanningLine);
        if NewJobPlanningLine."Qty. per Unit of Measure" <> OldJobPlanningLine."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        if NewJobPlanningLine."Remaining Qty. (Base)" * OldJobPlanningLine."Remaining Qty. (Base)" < 0 then
            ReservationManagement.DeleteReservEntries(true, 0)
        else
            ReservationManagement.DeleteReservEntries(false, NewJobPlanningLine."Remaining Qty. (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewJobPlanningLine."Remaining Qty. (Base)");
        AssignForPlanning(NewJobPlanningLine);
    end;

    procedure TransferJobLineToItemJnlLine(var JobPlanningLine: Record "Job Planning Line"; var NewItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal): Decimal
    var
        OldReservationEntry: Record "Reservation Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingFilterIsSet: Boolean;
        EndLoop: Boolean;
        TrackedQty: Decimal;
        UnTrackedQty: Decimal;
        xTransferQty: Decimal;
    begin
        if not FindReservEntry(JobPlanningLine, OldReservationEntry) then
            exit(TransferQty);

        // Store initial values
        OldReservationEntry.CalcSums("Quantity (Base)");
        TrackedQty := -OldReservationEntry."Quantity (Base)";
        xTransferQty := TransferQty;

        OldReservationEntry.Lock();

        // Handle Item Tracking on job planning line:
        Clear(CreateReservEntry);
        if NewItemJournalLine."Entry Type" = NewItemJournalLine."Entry Type"::"Negative Adjmt." then
            if NewItemJournalLine.TrackingExists() then begin
                // Try to match against Item Tracking on the job planning line:
                OldReservationEntry.SetTrackingFilterFromItemJnlLine(NewItemJournalLine);
                if OldReservationEntry.IsEmpty() then
                    OldReservationEntry.ClearTrackingFilter()
                else
                    ItemTrackingFilterIsSet := true;
            end;

        NewItemJournalLine.TestItemFields(JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Location Code");

        if TransferQty = 0 then
            exit;

        ItemTrackingSetup.CopyTrackingFromItemJnlLine(NewItemJournalLine);
        if ReservationEngineMgt.InitRecordSet(OldReservationEntry, ItemTrackingSetup) then
            repeat
                OldReservationEntry.TestItemFields(JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Location Code");

                if NewItemJournalLine."Entry Type" = NewItemJournalLine."Entry Type"::"Negative Adjmt." then
                    // Set the tracking for the item journal inside the loop as it is cleared within TransferReservEntry
                    CreateReservEntry.SetNewTrackingFromItemJnlLine(NewItemJournalLine);

                TransferQty :=
                  CreateReservEntry.TransferReservEntry(DATABASE::"Item Journal Line",
                    NewItemJournalLine."Entry Type".AsInteger(), NewItemJournalLine."Journal Template Name", NewItemJournalLine."Journal Batch Name", 0,
                    NewItemJournalLine."Line No.", NewItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

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

        // Handle remaining transfer quantity
        if TransferQty <> 0 then begin
            TrackedQty -= (xTransferQty - TransferQty);
            UnTrackedQty := JobPlanningLine."Remaining Qty. (Base)" - TrackedQty;
            if TransferQty > UnTrackedQty then begin
                ReservationManagement.SetReservSource(JobPlanningLine);
                ReservationManagement.DeleteReservEntries(false, JobPlanningLine."Remaining Qty. (Base)");
            end;
        end;
        exit(TransferQty);
    end;

    procedure DeleteLine(var JobPlanningLine: Record "Job Planning Line")
    begin
        DeleteLineInternal(JobPlanningLine, true);
    end;

    internal procedure DeleteLineInternal(var JobPlanningLine: Record "Job Planning Line"; ConfirmFirst: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationManagement.SetReservSource(JobPlanningLine);

        ReservationEntry.InitSortingAndFilters(false);
        JobPlanningLine.SetReservationFilters(ReservationEntry);
        if not ReservationEntry.IsEmpty() then
            if ConfirmFirst then begin
                if ReservationManagement.DeleteItemTrackingConfirm() then
                    ReservationManagement.SetItemTrackingHandling(1);
            end else
                ReservationManagement.SetItemTrackingHandling(1);
        ReservationManagement.DeleteReservEntries(true, 0);
        JobPlanningLine.CalcFields("Reserved Qty. (Base)");
        AssignForPlanning(JobPlanningLine);
    end;

    local procedure AssignForPlanning(var JobPlanningLine: Record "Job Planning Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if JobPlanningLine.Status <> JobPlanningLine.Status::Order then
            exit;
        if JobPlanningLine.Type <> JobPlanningLine.Type::Item then
            exit;
        if JobPlanningLine."No." <> '' then
            PlanningAssignment.ChkAssignOne(
                JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Location Code", JobPlanningLine."Planning Date");
    end;

    procedure BindToPurchase(JobPlanningLine: Record "Job Planning Line"; PurchaseLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.",
          PurchaseLine."Variant Code", PurchaseLine."Location Code", PurchaseLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(JobPlanningLine, PurchaseLine.Description, PurchaseLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToRequisition(JobPlanningLine: Record "Job Planning Line"; RequisitionLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Requisition Line",
          0, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", 0, RequisitionLine."Line No.",
          RequisitionLine."Variant Code", RequisitionLine."Location Code", RequisitionLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(JobPlanningLine, RequisitionLine.Description, RequisitionLine."Due Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToTransfer(JobPlanningLine: Record "Job Planning Line"; TransferLine: Record "Transfer Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Transfer Line", 1, TransferLine."Document No.", '', 0, TransferLine."Line No.",
          TransferLine."Variant Code", TransferLine."Transfer-to Code", TransferLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(JobPlanningLine, TransferLine.Description, TransferLine."Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToProdOrder(JobPlanningLine: Record "Job Planning Line"; ProdOrderLine: Record "Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBindToProdOrder(JobPlanningLine, ProdOrderLine, ReservQty, ReservQtyBase, IsHandled);
        if IsHandled then
            exit;

        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
          ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(JobPlanningLine, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToAssembly(JobPlanningLine: Record "Job Planning Line"; AssemblyHeader: Record "Assembly Header"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", '', 0, 0,
          AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(JobPlanningLine, AssemblyHeader.Description, AssemblyHeader."Due Date", ReservQty, ReservQtyBase);
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(JobPlanningLine);
            JobPlanningLine.Find();
            if JobPlanningLine.UpdatePlanned() then begin
                JobPlanningLine.Modify(true);
                Commit();
            end;
            QtyPerUOM := JobPlanningLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        SourceRecordRef.SetTable(JobPlanningLine);
        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.TestField("Planning Date");

        JobPlanningLine.SetReservationEntry(ReservationEntry);

        CaptionText := JobPlanningLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(Enum::"Reservation Summary Type"::"Job Planning Planned".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo = Enum::"Reservation Summary Type"::"Job Planning Order".AsInteger());
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit((TableID = database::"Job Planning Line") or (TableID = database::Job)); //for warehouse pick: DATABASE::Job
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
        AvailableJobPlanningLines: page "Available - Job Planning Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            Clear(AvailableJobPlanningLines);
            AvailableJobPlanningLines.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
            AvailableJobPlanningLines.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailableJobPlanningLines.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Job Planning Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Job Planning Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(JobPlanningLine);
            CreateReservation(JobPlanningLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceID: Code[20])
    var
        Job: Record Job;
    begin
        if MatchThisTable(SourceType) then begin
            Job.Reset();
            Job.SetRange("No.", SourceID);
            PAGE.RunModal(PAGE::"Job Card", Job)
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceRefNo: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if MatchThisTable(SourceType) then begin
            JobPlanningLine.Reset();
            JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
            JobPlanningLine.SetRange("Job Contract Entry No.", SourceRefNo);
            PAGE.Run(0, JobPlanningLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(JobPlanningLine);
            JobPlanningLine.SetReservationFilters(ReservEntry);
            CaptionText := JobPlanningLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(JobPlanningLine);
            JobPlanningLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", ReservationEntry."Source Ref. No.");
        JobPlanningLine.FindFirst();
        SourceRecordRef.GetTable(JobPlanningLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(JobPlanningLine."Remaining Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(JobPlanningLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(ReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; LineType: Option; Positive: Boolean; var TotalQuantity: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
        AvailabilityFilter: Text;
    begin
        if not JobPlanningLine.ReadPermission then
            exit;

        AvailabilityFilter := ReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        JobPlanningLine.FilterLinesForReservation(ReservationEntry, LineType, AvailabilityFilter, Positive);
        if JobPlanningLine.FindSet() then
            repeat
                JobPlanningLine.CalcFields("Reserved Qty. (Base)");
                TempEntrySummary."Total Reserved Quantity" -= JobPlanningLine."Reserved Qty. (Base)";
                TotalQuantity += JobPlanningLine."Remaining Qty. (Base)";
            until JobPlanningLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (TotalQuantity < 0) = Positive then begin
            TempEntrySummary."Table ID" := DATABASE::"Job Planning Line";
            TempEntrySummary."Summary Type" :=
                CopyStr(StrSubstNo(SummaryTypeTxt, JobPlanningLine.TableCaption(), JobPlanningLine.Status), 1, MaxStrLen(TempEntrySummary."Summary Type"));
            TempEntrySummary."Total Quantity" := -TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if MatchThisEntry(ReservSummEntry."Entry No.") then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, ReservSummEntry."Entry No." - 131, Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange(Status, ReservationEntry."Source Subtype");
        JobPlanningLine.SetRange("Job No.", ReservationEntry."Source ID");
        JobPlanningLine.SetRange("Job Contract Entry No.", ReservationEntry."Source Ref. No.");
        PAGE.RunModal(Page::"Job Planning Lines", JobPlanningLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReservQuantity(JobPlanningLine: Record "Job Planning Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReservedQtyBase(JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean; var QuantityBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyQuantity(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasErrorCheck(NewJobPlanningLine: Record "Job Planning Line"; OldJobPlanningLine: Record "Job Planning Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBindToProdOrder(JobPlanningLine: Record "Job Planning Line"; ProdOrderLine: Record "Prod. Order Line"; ReservQty: Decimal; ReservQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;
}

