codeunit 99000835 "Item Jnl. Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

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
        ReservMgt: Codeunit "Reservation Management";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        Blocked: Boolean;
        Text006: Label 'You cannot define item tracking on %1 %2';
        DeleteItemTracking: Boolean;

    procedure CreateReservation(var ItemJnlLine: Record "Item Journal Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text005);

        ItemJnlLine.TestField("Item No.");
        ItemJnlLine.TestField("Posting Date");
        ItemJnlLine.CalcFields("Reserved Qty. (Base)");
        if Abs(ItemJnlLine."Quantity (Base)") <
           Abs(ItemJnlLine."Reserved Qty. (Base)") + QuantityBase
        then
            Error(
              Text000,
              Abs(ItemJnlLine."Quantity (Base)") - Abs(ItemJnlLine."Reserved Qty. (Base)"));

        ItemJnlLine.TestField("Location Code", FromTrackingSpecification."Location Code");
        ItemJnlLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");

        if QuantityBase > 0 then
            ShipmentDate := ItemJnlLine."Posting Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ItemJnlLine."Posting Date";
        end;

        CreateReservEntry.CreateReservEntryFor(
          DATABASE::"Item Journal Line",
          ItemJnlLine."Entry Type", ItemJnlLine."Journal Template Name",
          ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.", ItemJnlLine."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForReservEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          ItemJnlLine."Item No.", ItemJnlLine."Variant Code", ItemJnlLine."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    [Obsolete('Replaced by CreateReservation(ItemJournalLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry)','16.0')]
    procedure CreateReservation(var ItemJnlLine: Record "Item Journal Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ForReservEntry: Record "Reservation Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservation(ItemJnlLine, Description, ExpectedReceiptDate, Quantity, QuantityBase, ForReservEntry);
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    [Obsolete('Replaced by ItemJnlLine.SetReservationFilters(FilterReservEntry)','16.0')]
    procedure FilterReservFor(var FilterReservEntry: Record "Reservation Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine.SetReservationFilters(FilterReservEntry);
    end;

    procedure Caption(ItemJnlLine: Record "Item Journal Line") CaptionText: Text
    begin
        CaptionText := ItemJnlLine.GetSourceCaption;
    end;

    procedure FindReservEntry(ItemJnlLine: Record "Item Journal Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.InitSortingAndFilters(false);
        ItemJnlLine.SetReservationFilters(ReservEntry);
        exit(ReservEntry.FindLast);
    end;

    procedure ReservEntryExist(ItemJnlLine: Record "Item Journal Line"): Boolean
    begin
        exit(ItemJnlLine.ReservEntryExist);
    end;

    procedure VerifyChange(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line")
    var
        ItemJnlLine: Record "Item Journal Line";
        TempReservEntry: Record "Reservation Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ShowError: Boolean;
        HasError: Boolean;
        PointerChanged: Boolean;
    begin
        if Blocked then
            exit;
        if NewItemJnlLine."Line No." = 0 then
            if not ItemJnlLine.Get(
                 NewItemJnlLine."Journal Template Name",
                 NewItemJnlLine."Journal Batch Name",
                 NewItemJnlLine."Line No.")
            then
                exit;

        NewItemJnlLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewItemJnlLine."Reserved Qty. (Base)" <> 0;

        if NewItemJnlLine."Posting Date" = 0D then
            if ShowError then
                NewItemJnlLine.FieldError("Posting Date", Text002)
            else
                HasError := true;

        if NewItemJnlLine."Drop Shipment" then
            if ShowError then
                NewItemJnlLine.FieldError("Drop Shipment", Text003)
            else
                HasError := true;

        if NewItemJnlLine."Item No." <> OldItemJnlLine."Item No." then
            if ShowError then
                NewItemJnlLine.FieldError("Item No.", Text004)
            else
                HasError := true;

        if NewItemJnlLine."Entry Type" <> OldItemJnlLine."Entry Type" then
            if ShowError then
                NewItemJnlLine.FieldError("Entry Type", Text004)
            else
                HasError := true;

        if (NewItemJnlLine."Entry Type" = NewItemJnlLine."Entry Type"::Transfer) and
           (NewItemJnlLine."Quantity (Base)" < 0)
        then begin
            if NewItemJnlLine."New Location Code" <> OldItemJnlLine."Location Code" then
                if ShowError then
                    NewItemJnlLine.FieldError("New Location Code", Text004)
                else
                    HasError := true;
            if NewItemJnlLine."New Bin Code" <> OldItemJnlLine."Bin Code" then begin
                if ItemTrackingMgt.GetWhseItemTrkgSetup(NewItemJnlLine."Item No.") then
                    if ShowError then
                        NewItemJnlLine.FieldError("New Bin Code", Text004)
                    else
                        HasError := true;
            end
        end else begin
            if NewItemJnlLine."Location Code" <> OldItemJnlLine."Location Code" then
                if ShowError then
                    NewItemJnlLine.FieldError("Location Code", Text004)
                else
                    HasError := true;
            if (NewItemJnlLine."Bin Code" <> OldItemJnlLine."Bin Code") and
               (not ReservMgt.CalcIsAvailTrackedQtyInBin(
                  NewItemJnlLine."Item No.", NewItemJnlLine."Bin Code",
                  NewItemJnlLine."Location Code", NewItemJnlLine."Variant Code",
                  DATABASE::"Item Journal Line", NewItemJnlLine."Entry Type",
                  NewItemJnlLine."Journal Template Name", NewItemJnlLine."Journal Batch Name",
                  0, NewItemJnlLine."Line No."))
            then begin
                if ShowError then
                    NewItemJnlLine.FieldError("Bin Code", Text004);
                HasError := true;
            end;
        end;
        if NewItemJnlLine."Variant Code" <> OldItemJnlLine."Variant Code" then
            if ShowError then
                NewItemJnlLine.FieldError("Variant Code", Text004)
            else
                HasError := true;
        if NewItemJnlLine."Line No." <> OldItemJnlLine."Line No." then
            HasError := true;

        OnVerifyChangeOnBeforeHasError(NewItemJnlLine, OldItemJnlLine, HasError, ShowError);

        if HasError then begin
            FindReservEntry(NewItemJnlLine, TempReservEntry);
            TempReservEntry.ClearTrackingFilter;

            PointerChanged := (NewItemJnlLine."Item No." <> OldItemJnlLine."Item No.") or
              (NewItemJnlLine."Entry Type" <> OldItemJnlLine."Entry Type");

            if PointerChanged or
               (not TempReservEntry.IsEmpty)
            then begin
                if PointerChanged then begin
                    ReservMgt.SetReservSource(OldItemJnlLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                    ReservMgt.SetReservSource(NewItemJnlLine);
                end else begin
                    ReservMgt.SetReservSource(NewItemJnlLine);
                    ReservMgt.DeleteReservEntries(true, 0);
                end;
                ReservMgt.AutoTrack(NewItemJnlLine."Quantity (Base)");
            end;
        end;
    end;

    procedure VerifyQuantity(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line")
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        OnBeforeVerifyQuantity(NewItemJnlLine, OldItemJnlLine);

        if Blocked then
            exit;

        with NewItemJnlLine do begin
            if "Line No." = OldItemJnlLine."Line No." then
                if "Quantity (Base)" = OldItemJnlLine."Quantity (Base)" then
                    exit;
            if "Line No." = 0 then
                if not ItemJnlLine.Get("Journal Template Name", "Journal Batch Name", "Line No.") then
                    exit;
            ReservMgt.SetReservSource(NewItemJnlLine);
            if "Qty. per Unit of Measure" <> OldItemJnlLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            if "Quantity (Base)" * OldItemJnlLine."Quantity (Base)" < 0 then
                ReservMgt.DeleteReservEntries(true, 0)
            else
                ReservMgt.DeleteReservEntries(false, "Quantity (Base)");
        end;
    end;

    procedure TransferItemJnlToItemLedgEntry(var ItemJnlLine: Record "Item Journal Line"; var ItemLedgEntry: Record "Item Ledger Entry"; TransferQty: Decimal; SkipInventory: Boolean): Boolean
    var
        OldReservEntry: Record "Reservation Entry";
        OldReservEntry2: Record "Reservation Entry";
        ReservStatus: Enum "Reservation Status";
        SkipThisRecord: Boolean;
        IsHandled: Boolean;
    begin
        if not FindReservEntry(ItemJnlLine, OldReservEntry) then
            exit(false);

        OldReservEntry.Lock;

        ItemLedgEntry.TestField("Item No.", ItemJnlLine."Item No.");
        ItemLedgEntry.TestField("Variant Code", ItemJnlLine."Variant Code");
        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer then begin
            ItemLedgEntry.TestField("Location Code", ItemJnlLine."New Location Code");
        end else
            ItemLedgEntry.TestField("Location Code", ItemJnlLine."Location Code");

        for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
            if TransferQty = 0 then
                exit(true);
            OldReservEntry.SetRange("Reservation Status", ReservStatus);

            if OldReservEntry.FindSet() then
                repeat
                    OldReservEntry.TestField("Item No.", ItemJnlLine."Item No.");
                    OnTransferItemJnlToItemLedgEntryOnBeforeTestVariantCode(OldReservEntry, ItemJnlLine, IsHandled);
                    OldReservEntry.TestField("Variant Code", ItemJnlLine."Variant Code");

                    if SkipInventory then
                        if ReservStatus < ReservStatus::Surplus then begin
                            OldReservEntry2.Get(OldReservEntry."Entry No.", not OldReservEntry.Positive);
                            SkipThisRecord := OldReservEntry2."Source Type" = DATABASE::"Item Ledger Entry";
                        end else
                            SkipThisRecord := false;

                    if not SkipThisRecord then begin
                        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer then begin
                            if ItemLedgEntry.Quantity < 0 then
                                OldReservEntry.TestField("Location Code", ItemJnlLine."Location Code");
                            CreateReservEntry.SetInbound(true);
                        end else
                            OldReservEntry.TestField("Location Code", ItemJnlLine."Location Code");

                        TransferQty :=
                          CreateReservEntry.TransferReservEntry(
                            DATABASE::"Item Ledger Entry", 0, '', '', 0,
                            ItemLedgEntry."Entry No.", ItemLedgEntry."Qty. per Unit of Measure",
                            OldReservEntry, TransferQty);
                    end else
                        if ReservStatus = ReservStatus::Tracking then begin
                            OldReservEntry2.Delete();
                            OldReservEntry.Delete();
                            ReservMgt.ModifyActionMessage(OldReservEntry."Entry No.", 0, true);
                        end;
                until (OldReservEntry.Next = 0) or (TransferQty = 0);
        end; // DO

        exit(true);
    end;

    procedure RenameLine(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line")
    begin
        ReservEngineMgt.RenamePointer(DATABASE::"Item Journal Line",
          OldItemJnlLine."Entry Type",
          OldItemJnlLine."Journal Template Name",
          OldItemJnlLine."Journal Batch Name",
          0,
          OldItemJnlLine."Line No.",
          NewItemJnlLine."Entry Type",
          NewItemJnlLine."Journal Template Name",
          NewItemJnlLine."Journal Batch Name",
          0,
          NewItemJnlLine."Line No.");
    end;

    procedure DeleteLineConfirm(var ItemJnlLine: Record "Item Journal Line"): Boolean
    begin
        with ItemJnlLine do begin
            if not ReservEntryExist then
                exit(true);

            ReservMgt.SetReservSource(ItemJnlLine);
            if ReservMgt.DeleteItemTrackingConfirm then
                DeleteItemTracking := true;
        end;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var ItemJnlLine: Record "Item Journal Line")
    begin
        if Blocked then
            exit;

        with ItemJnlLine do begin
            ReservMgt.SetReservSource(ItemJnlLine);
            if DeleteItemTracking then
                ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
            ReservMgt.DeleteReservEntries(true, 0);
            CalcFields("Reserved Qty. (Base)");
        end;
    end;

    procedure AssignForPlanning(var ItemJnlLine: Record "Item Journal Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if ItemJnlLine."Item No." <> '' then
            with ItemJnlLine do begin
                PlanningAssignment.ChkAssignOne("Item No.", "Variant Code", "Location Code", "Posting Date");
                if "Entry Type" = "Entry Type"::Transfer then
                    PlanningAssignment.ChkAssignOne("Item No.", "Variant Code", "New Location Code", "Posting Date");
            end;
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var ItemJnlLine: Record "Item Journal Line"; IsReclass: Boolean)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        ItemJnlLine.TestField("Item No.");
        if not ItemJnlLine.ItemPosting then begin
            ReservEntry.InitSortingAndFilters(false);
            ItemJnlLine.SetReservationFilters(ReservEntry);
            ReservEntry.ClearTrackingFilter;
            if ReservEntry.IsEmpty then
                Error(Text006, ItemJnlLine.FieldCaption("Operation No."), ItemJnlLine."Operation No.");
        end;
        TrackingSpecification.InitFromItemJnlLine(ItemJnlLine);
        if IsReclass then
            ItemTrackingLines.SetFormRunMode(1);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ItemJnlLine."Posting Date");
        ItemTrackingLines.SetInbound(ItemJnlLine.IsInbound);
        ItemTrackingLines.RunModal;
    end;

    procedure RegisterBinContentItemTracking(var ItemJournalLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        SourceTrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
        FormRunMode: Option ,Reclass,"Combined Ship/Rcpt","Drop Shipment",Transfer;
    begin
        if not TempTrackingSpecification.FindSet then
            exit;
        SourceTrackingSpecification.InitFromItemJnlLine(ItemJournalLine);

        Clear(ItemTrackingLines);
        ItemTrackingLines.SetFormRunMode(FormRunMode::Reclass);
        ItemTrackingLines.RegisterItemTrackingLines(
          SourceTrackingSpecification, ItemJournalLine."Posting Date", TempTrackingSpecification);
    end;

    local procedure SetReservSourceFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        SourceRecRef.SetTable(ItemJnlLine);
        ItemJnlLine.TestField("Drop Shipment", false);
        ItemJnlLine.TestField("Posting Date");

        ItemJnlLine.SetReservationEntry(ReservEntry);

        CaptionText := ItemJnlLine.GetSourceCaption;
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(41);
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [41, 42, 43, 44, 45]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = 83); // DATABASE::"Item Journal Line"
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnSetReservSource', '', false, false)]
    local procedure OnSetReservSource(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    begin
        if MatchThisTable(SourceRecRef.Number) then
            SetReservSourceFor(SourceRecRef, ReservEntry, CaptionText);
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Item Journal Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Item Journal Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(ItemJnlLine);
            CreateReservation(ItemJnlLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceRefNo: Integer)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        if MatchThisTable(SourceType) then begin
            ItemJnlLine.Reset();
            ItemJnlLine.SetRange("Journal Template Name", SourceID);
            ItemJnlLine.SetRange("Journal Batch Name", SourceBatchName);
            ItemJnlLine.SetRange("Line No.", SourceRefNo);
            ItemJnlLine.SetRange("Entry Type", SourceSubtype);
            PAGE.RunModal(PAGE::"Item Journal Lines", ItemJnlLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceRefNo: Integer)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        if MatchThisTable(SourceType) then begin
            ItemJnlLine.Reset();
            ItemJnlLine.SetRange("Journal Template Name", SourceID);
            ItemJnlLine.SetRange("Journal Batch Name", SourceBatchName);
            ItemJnlLine.SetRange("Line No.", SourceRefNo);
            ItemJnlLine.SetRange("Entry Type", SourceSubtype);
            PAGE.Run(PAGE::"Item Journal Lines", ItemJnlLine);
        end;
    end;

    local procedure GetSourceValue(ReservEntry: Record "Reservation Entry"; var SourceRecRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.Get(ReservEntry."Source ID", ReservEntry."Source Batch Name", ReservEntry."Source Ref. No.");
        SourceRecRef.GetTable(ItemJnlLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ItemJnlLine."Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ItemJnlLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyQuantity(var NewItemJournalLine: Record "Item Journal Line"; OldItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferItemJnlToItemLedgEntryOnBeforeTestVariantCode(var OldReservEntry: Record "Reservation Entry"; var ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyChangeOnBeforeHasError(NewItemJnlLine: Record "Item Journal Line"; OldItemJnlLine: Record "Item Journal Line"; var HasError: Boolean; var ShowError: Boolean)
    begin
    end;
}

