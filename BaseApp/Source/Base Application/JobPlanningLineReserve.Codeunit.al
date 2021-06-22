codeunit 1032 "Job Planning Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Planning Assignment" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Reserved quantity cannot be greater than %1.';
        Text002: Label 'must be filled in when a quantity is reserved', Comment = 'starts with "Planning Date"';
        Text004: Label 'must not be changed when a quantity is reserved', Comment = 'starts with some field name';
        Text005: Label 'Codeunit is not initialized correctly.';
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservMgt: Codeunit "Reservation Management";

    procedure CreateReservation(JobPlanningLine: Record "Job Planning Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        PlanningDate: Date;
        SignFactor: Integer;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text005);

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
          DATABASE::"Job Planning Line", JobPlanningLine.Status,
          JobPlanningLine."Job No.", '', 0, JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForReservEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Location Code",
          Description, ExpectedReceiptDate, PlanningDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    [Obsolete('Replaced by CreateReservation(JobPlanningLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry)','16.0')]
    procedure CreateReservation(JobPlanningLine: Record "Job Planning Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ForReservEntry: Record "Reservation Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservation(JobPlanningLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry);
    end;

    local procedure CreateBindingReservation(JobPlanningLine: Record "Job Planning Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        DummyReservEntry: Record "Reservation Entry";
    begin
        CreateReservation(JobPlanningLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, DummyReservEntry);
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
              Text000,
              Abs(JobPlanningLine."Remaining Qty. (Base)") - Abs(JobPlanningLine."Reserved Qty. (Base)"));
    end;

    procedure SetBinding(Binding: Option " ","Order-to-Order")
    begin
        CreateReservEntry.SetBinding(Binding);
    end;

    [Obsolete('Replaced by JobPlanningLine.SetReservationFilters(FilterReservEntry)','16.0')]
    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; JobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine.SetReservationFilters(FilterReservEntry);
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
        CaptionText := JobPlanningLine.GetSourceCaption;
    end;

    procedure FindReservEntry(JobPlanningLine: Record "Job Planning Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.InitSortingAndFilters(false);
        JobPlanningLine.SetReservationFilters(ReservEntry);
        exit(ReservEntry.FindLast);
    end;

    procedure VerifyChange(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        ReservEntry: Record "Reservation Entry";
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
                NewJobPlanningLine.FieldError("Usage Link", Text004);
            HasError := true;
        end;

        if (NewJobPlanningLine."Planning Date" = 0D) and (OldJobPlanningLine."Planning Date" <> 0D) then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Planning Date", Text002);
            HasError := true;
        end;

        if NewJobPlanningLine."No." <> OldJobPlanningLine."No." then begin
            if ShowError then
                NewJobPlanningLine.FieldError("No.", Text004);
            HasError := true;
        end;

        if NewJobPlanningLine."Variant Code" <> OldJobPlanningLine."Variant Code" then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Variant Code", Text004);
            HasError := true;
        end;

        if NewJobPlanningLine."Location Code" <> OldJobPlanningLine."Location Code" then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Location Code", Text004);
            HasError := true;
        end;

        if NewJobPlanningLine."Bin Code" <> OldJobPlanningLine."Bin Code" then begin
            if ShowError then
                NewJobPlanningLine.FieldError("Bin Code", Text004);
            HasError := true;
        end;

        if NewJobPlanningLine."Line No." <> OldJobPlanningLine."Line No." then
            HasError := true;

        if NewJobPlanningLine.Type <> OldJobPlanningLine.Type then begin
            if ShowError then
                NewJobPlanningLine.FieldError(Type, Text004);
            HasError := true;
        end;

        if HasError then
            if (NewJobPlanningLine."No." <> OldJobPlanningLine."No.") or
               FindReservEntry(NewJobPlanningLine, ReservEntry)
            then begin
                if (NewJobPlanningLine."No." <> OldJobPlanningLine."No.") or (NewJobPlanningLine.Type <> OldJobPlanningLine.Type) then begin
                    ReservMgt.SetReservSource(OldJobPlanningLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetReservSource(NewJobPlanningLine);
                end else begin
                    ReservMgt.SetReservSource(NewJobPlanningLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewJobPlanningLine."Remaining Qty. (Base)");
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

    procedure VerifyQuantity(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        with NewJobPlanningLine do begin
            if Type <> Type::Item then
                exit;
            if Status = OldJobPlanningLine.Status then
                if "Line No." = OldJobPlanningLine."Line No." then
                    if "Quantity (Base)" = OldJobPlanningLine."Quantity (Base)" then
                        exit;
            if "Line No." = 0 then
                if not JobPlanningLine.Get("Job No.", "Job Task No.", "Line No.") then
                    exit;
            ReservMgt.SetReservSource(NewJobPlanningLine);
            if "Qty. per Unit of Measure" <> OldJobPlanningLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            if "Remaining Qty. (Base)" * OldJobPlanningLine."Remaining Qty. (Base)" < 0 then
                ReservMgt.DeleteReservEntries(true, 0)
            else
                ReservMgt.DeleteReservEntries(false, "Remaining Qty. (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Remaining Qty. (Base)");
            AssignForPlanning(NewJobPlanningLine);
        end;
    end;

    procedure TransferJobLineToItemJnlLine(var JobPlanningLine: Record "Job Planning Line"; var NewItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal): Decimal
    var
        OldReservEntry: Record "Reservation Entry";
        ItemTrackingFilterIsSet: Boolean;
        EndLoop: Boolean;
        TrackedQty: Decimal;
        UnTrackedQty: Decimal;
        xTransferQty: Decimal;
    begin
        if not FindReservEntry(JobPlanningLine, OldReservEntry) then
            exit(TransferQty);

        // Store initial values
        OldReservEntry.CalcSums("Quantity (Base)");
        TrackedQty := -OldReservEntry."Quantity (Base)";
        xTransferQty := TransferQty;

        OldReservEntry.Lock;

        // Handle Item Tracking on job planning line:
        Clear(CreateReservEntry);
        if NewItemJnlLine."Entry Type" = NewItemJnlLine."Entry Type"::"Negative Adjmt." then
            if NewItemJnlLine.TrackingExists then begin
                CreateReservEntry.SetNewTrackingFromItemJnlLine(NewItemJnlLine);
                // Try to match against Item Tracking on the job planning line:
                OldReservEntry.SetTrackingFilterFromItemJnlLine(NewItemJnlLine);
                if OldReservEntry.IsEmpty then
                    OldReservEntry.ClearTrackingFilter
                else
                    ItemTrackingFilterIsSet := true;
            end;

        NewItemJnlLine.TestItemFields(JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ReservEngineMgt.InitRecordSet(OldReservEntry, NewItemJnlLine."Serial No.", NewItemJnlLine."Lot No.") then
            repeat
                OldReservEntry.TestItemFields(JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Location Code");

                TransferQty :=
                  CreateReservEntry.TransferReservEntry(DATABASE::"Item Journal Line",
                    NewItemJnlLine."Entry Type", NewItemJnlLine."Journal Template Name", NewItemJnlLine."Journal Batch Name", 0,
                    NewItemJnlLine."Line No.", NewItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

                if ReservEngineMgt.NEXTRecord(OldReservEntry) = 0 then
                    if ItemTrackingFilterIsSet then begin
                        OldReservEntry.ClearTrackingFilter;
                        ItemTrackingFilterIsSet := false;
                        EndLoop := not ReservEngineMgt.InitRecordSet(OldReservEntry);
                    end else
                        EndLoop := true;
            until EndLoop or (TransferQty = 0);

        // Handle remaining transfer quantity
        if TransferQty <> 0 then begin
            TrackedQty -= (xTransferQty - TransferQty);
            UnTrackedQty := JobPlanningLine."Remaining Qty. (Base)" - TrackedQty;
            if TransferQty > UnTrackedQty then begin
                ReservMgt.SetReservSource(JobPlanningLine);
                ReservMgt.DeleteReservEntries(false, JobPlanningLine."Remaining Qty. (Base)");
            end;
        end;
        exit(TransferQty);
    end;

    procedure DeleteLine(var JobPlanningLine: Record "Job Planning Line")
    begin
        with JobPlanningLine do begin
            ReservMgt.SetReservSource(JobPlanningLine);
            ReservMgt.DeleteReservEntries(true, 0);
            CalcFields("Reserved Qty. (Base)");
            AssignForPlanning(JobPlanningLine);
        end;
    end;

    local procedure AssignForPlanning(var JobPlanningLine: Record "Job Planning Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        with JobPlanningLine do begin
            if Status <> Status::Order then
                exit;
            if Type <> Type::Item then
                exit;
            if "No." <> '' then
                PlanningAssignment.ChkAssignOne("No.", "Variant Code", "Location Code", "Planning Date");
        end;
    end;

    procedure BindToPurchase(JobPlanningLine: Record "Job Planning Line"; PurchLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        SetBinding(ReservationEntry.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", '', 0, PurchLine."Line No.",
          PurchLine."Variant Code", PurchLine."Location Code", PurchLine."Qty. per Unit of Measure");
        CreateReservationSetFrom(TrackingSpecification);
        CreateBindingReservation(JobPlanningLine, PurchLine.Description, PurchLine."Expected Receipt Date", ReservQty, ReservQtyBase);
    end;

    procedure BindToRequisition(JobPlanningLine: Record "Job Planning Line"; ReqLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
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
        CreateBindingReservation(JobPlanningLine, ReqLine.Description, ReqLine."Due Date", ReservQty, ReservQtyBase);
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(JobPlanningLine);
            JobPlanningLine.Find;
            if JobPlanningLine.UpdatePlanned then begin
                JobPlanningLine.Modify(true);
                Commit();
            end;
            QtyPerUOM := JobPlanningLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        SourceRecRef.SetTable(JobPlanningLine);
        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.TestField("Planning Date");

        JobPlanningLine.SetReservationEntry(ReservEntry);

        CaptionText := JobPlanningLine.GetSourceCaption;
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(131);
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [131, 132, 133, 134]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = 1003); // DATABASE::"Job Planning Line"
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
            AvailableJobPlanningLines.SetSource(SourceRecRef, ReservEntry, ReservEntry."Source Subtype");
            AvailableJobPlanningLines.RunModal;
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
            CaptionText := JobPlanningLine.GetSourceCaption;
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

    local procedure GetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", ReservEntry."Source Ref. No.");
        JobPlanningLine.FindFirst;
        SourceRecRef.GetTable(JobPlanningLine);
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

    local procedure UpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; LineType: Option; Positive: Boolean; var TotalQuantity: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
        AvailabilityFilter: Text;
    begin
        if not JobPlanningLine.ReadPermission then
            exit;

        AvailabilityFilter := CalcReservEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        JobPlanningLine.FilterLinesForReservation(CalcReservEntry, LineType, AvailabilityFilter, Positive);
        if JobPlanningLine.FindSet then
            repeat
                JobPlanningLine.CalcFields("Reserved Qty. (Base)");
                TempEntrySummary."Total Reserved Quantity" -= JobPlanningLine."Reserved Qty. (Base)";
                TotalQuantity += JobPlanningLine."Remaining Qty. (Base)";
            until JobPlanningLine.Next = 0;

        if TotalQuantity = 0 then
            exit;

        with TempEntrySummary do
            if (TotalQuantity < 0) = Positive then begin
                "Table ID" := DATABASE::"Job Planning Line";
                "Summary Type" :=
                    CopyStr(
                    StrSubstNo('%1, %2', JobPlanningLine.TableCaption, JobPlanningLine.Status),
                    1, MaxStrLen("Summary Type"));
                "Total Quantity" := -TotalQuantity;
                "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                if not Insert() then
                    Modify;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." = 133 then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, ReservSummEntry."Entry No." - 131, Positive, TotalQuantity);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReservQuantity(JobPlanningLine: Record "Job Planning Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReservedQtyBase(JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean; var QuantityBase: Decimal)
    begin
    end;
}

