codeunit 99000844 "Job Jnl. Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text002: Label 'must be filled in when a quantity is reserved.';
        Text004: Label 'must not be changed when a quantity is reserved.';
        ReservMgt: Codeunit "Reservation Management";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        DeleteItemTracking: Boolean;

    local procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; JobJnlLine: Record "Job Journal Line")
    begin
        FilterReservEntry.SetSourceFilter(
          DATABASE::"Job Journal Line", JobJnlLine."Entry Type", JobJnlLine."Journal Template Name", JobJnlLine."Line No.", false);
        FilterReservEntry.SetSourceFilter(JobJnlLine."Journal Batch Name", 0);
    end;

    local procedure FindReservEntry(JobJnlLine: Record "Job Journal Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, JobJnlLine);
        exit(ReservEntry.Find('+'));
    end;

    local procedure ReservEntryExist(JobJnlLine: Record "Job Journal Line"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, false);
        FilterReservFor(ReservEntry, JobJnlLine);
        ReservEntry.ClearTrackingFilter;
        exit(not ReservEntry.IsEmpty);
    end;

    procedure VerifyChange(var NewJobJnlLine: Record "Job Journal Line"; var OldJobJnlLine: Record "Job Journal Line")
    var
        JobJnlLine: Record "Job Journal Line";
        TempReservEntry: Record "Reservation Entry";
        ShowError: Boolean;
        HasError: Boolean;
        PointerChanged: Boolean;
    begin
        if NewJobJnlLine."Line No." = 0 then
            if not JobJnlLine.Get(
                 NewJobJnlLine."Journal Template Name",
                 NewJobJnlLine."Journal Batch Name",
                 NewJobJnlLine."Line No.")
            then
                exit;

        NewJobJnlLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewJobJnlLine."Reserved Qty. (Base)" <> 0;

        if NewJobJnlLine."Posting Date" = 0D then
            if not ShowError then
                HasError := true
            else
                NewJobJnlLine.FieldError("Posting Date", Text002);

        if NewJobJnlLine."Job No." <> OldJobJnlLine."Job No." then
            if not ShowError then
                HasError := true
            else
                NewJobJnlLine.FieldError("Job No.", Text004);

        if NewJobJnlLine."Entry Type" <> OldJobJnlLine."Entry Type" then
            if not ShowError then
                HasError := true
            else
                NewJobJnlLine.FieldError("Entry Type", Text004);

        if NewJobJnlLine."Location Code" <> OldJobJnlLine."Location Code" then
            if not ShowError then
                HasError := true
            else
                NewJobJnlLine.FieldError("Location Code", Text004);

        if (NewJobJnlLine.Type = NewJobJnlLine.Type::Item) and (OldJobJnlLine.Type = OldJobJnlLine.Type::Item) then
            if (NewJobJnlLine."Bin Code" <> OldJobJnlLine."Bin Code") and
               (not ReservMgt.CalcIsAvailTrackedQtyInBin(
                  NewJobJnlLine."No.", NewJobJnlLine."Bin Code",
                  NewJobJnlLine."Location Code", NewJobJnlLine."Variant Code",
                  DATABASE::"Job Journal Line", NewJobJnlLine."Entry Type",
                  NewJobJnlLine."Journal Template Name", NewJobJnlLine."Journal Batch Name", 0, NewJobJnlLine."Line No."))
            then begin
                if ShowError then
                    NewJobJnlLine.FieldError("Bin Code", Text004);
                HasError := true;
            end;

        if NewJobJnlLine."Variant Code" <> OldJobJnlLine."Variant Code" then
            if not ShowError then
                HasError := true
            else
                NewJobJnlLine.FieldError("Variant Code", Text004);

        if NewJobJnlLine."Line No." <> OldJobJnlLine."Line No." then
            HasError := true;

        if NewJobJnlLine."No." <> OldJobJnlLine."No." then
            HasError := true;

        OnVerifyChangeOnBeforeHasError(NewJobJnlLine, OldJobJnlLine, HasError, ShowError);

        if HasError then begin
            FindReservEntry(NewJobJnlLine, TempReservEntry);
            TempReservEntry.ClearTrackingFilter;

            PointerChanged := (NewJobJnlLine."Job No." <> OldJobJnlLine."Job No.") or
              (NewJobJnlLine."Entry Type" <> OldJobJnlLine."Entry Type") or
              (NewJobJnlLine."No." <> OldJobJnlLine."No.");

            if PointerChanged or
               (not TempReservEntry.IsEmpty)
            then begin
                if PointerChanged then begin
                    ReservMgt.SetJobJnlLine(OldJobJnlLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetJobJnlLine(NewJobJnlLine);
                end else begin
                    ReservMgt.SetJobJnlLine(NewJobJnlLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewJobJnlLine."Quantity (Base)");
            end;
        end;
    end;

    procedure VerifyQuantity(var NewJobJnlLine: Record "Job Journal Line"; var OldJobJnlLine: Record "Job Journal Line")
    var
        JobJnlLine: Record "Job Journal Line";
    begin
        with NewJobJnlLine do begin
            if "Line No." = OldJobJnlLine."Line No." then
                if "Quantity (Base)" = OldJobJnlLine."Quantity (Base)" then
                    exit;
            if "Line No." = 0 then
                if not JobJnlLine.Get("Journal Template Name", "Journal Batch Name", "Line No.") then
                    exit;
            ReservMgt.SetJobJnlLine(NewJobJnlLine);
            if "Qty. per Unit of Measure" <> OldJobJnlLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            if "Quantity (Base)" * OldJobJnlLine."Quantity (Base)" < 0 then
                ReservMgt.DeleteReservEntries(true, 0)
            else
                ReservMgt.DeleteReservEntries(false, "Quantity (Base)");
        end;
    end;

    procedure RenameLine(var NewJobJnlLine: Record "Job Journal Line"; var OldJobJnlLine: Record "Job Journal Line")
    begin
        ReservEngineMgt.RenamePointer(DATABASE::"Job Journal Line",
          OldJobJnlLine."Entry Type",
          OldJobJnlLine."Journal Template Name",
          OldJobJnlLine."Journal Batch Name",
          0,
          OldJobJnlLine."Line No.",
          NewJobJnlLine."Entry Type",
          NewJobJnlLine."Journal Template Name",
          NewJobJnlLine."Journal Batch Name",
          0,
          NewJobJnlLine."Line No.");
    end;

    procedure DeleteLineConfirm(var JobJnlLine: Record "Job Journal Line"): Boolean
    begin
        with JobJnlLine do begin
            if not ReservEntryExist(JobJnlLine) then
                exit(true);

            ReservMgt.SetJobJnlLine(JobJnlLine);
            if ReservMgt.DeleteItemTrackingConfirm then
                DeleteItemTracking := true;
        end;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var JobJnlLine: Record "Job Journal Line")
    begin
        with JobJnlLine do
            if Type = Type::Item then begin
                ReservMgt.SetJobJnlLine(JobJnlLine);
                if DeleteItemTracking then
                    ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
                ReservMgt.DeleteReservEntries(true, 0);
            end;
    end;

    procedure CallItemTracking(var JobJnlLine: Record "Job Journal Line"; IsReclass: Boolean)
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        TrackingSpecification.InitFromJobJnlLine(JobJnlLine);
        if IsReclass then
            ItemTrackingLines.SetFormRunMode(1);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, JobJnlLine."Posting Date");
        ItemTrackingLines.SetInbound(JobJnlLine.IsInbound);
        ItemTrackingLines.RunModal;
    end;

    procedure TransJobJnlLineToItemJnlLine(var JobJnlLine: Record "Job Journal Line"; var ItemJnlLine: Record "Item Journal Line"; TransferQty: Decimal): Decimal
    var
        OldReservEntry: Record "Reservation Entry";
    begin
        if not FindReservEntry(JobJnlLine, OldReservEntry) then
            exit(TransferQty);
        OldReservEntry.Lock;
        // Handle Item Tracking on drop shipment:
        Clear(CreateReservEntry);

        ItemJnlLine.TestItemFields(JobJnlLine."No.", JobJnlLine."Variant Code", JobJnlLine."Location Code");

        if TransferQty = 0 then
            exit;

        if ReservEngineMgt.InitRecordSet(OldReservEntry) then
            repeat
                OldReservEntry.TestItemFields(JobJnlLine."No.", JobJnlLine."Variant Code", JobJnlLine."Location Code");

                TransferQty := CreateReservEntry.TransferReservEntry(DATABASE::"Item Journal Line",
                    ItemJnlLine."Entry Type", ItemJnlLine."Journal Template Name",
                    ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.",
                    ItemJnlLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

            until (ReservEngineMgt.NEXTRecord(OldReservEntry) = 0) or (TransferQty = 0);

        exit(TransferQty);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewJobJnlLine: Record "Job Journal Line"; OldJobJnlLine: Record "Job Journal Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;
}

