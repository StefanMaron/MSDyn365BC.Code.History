codeunit 6501 "Item Tracking Data Collection"
{
    Permissions = TableData "Item Entry Relation" = rd,
                  TableData "Value Entry Relation" = rd;

    trigger OnRun()
    begin
    end;

    var
        Text004: Label 'Counting records...';
        TempGlobalReservEntry: Record "Reservation Entry" temporary;
        TempGlobalAdjustEntry: Record "Reservation Entry" temporary;
        TempGlobalEntrySummary: Record "Entry Summary" temporary;
        TempGlobalChangedEntrySummary: Record "Entry Summary" temporary;
        CurrItemTrackingCode: Record "Item Tracking Code";
        TempGlobalTrackingSpec: Record "Tracking Specification" temporary;
        CurrBinCode: Code[20];
        LastSummaryEntryNo: Integer;
        LastReservEntryNo: Integer;
        FullGlobalDataSetExists: Boolean;
        AvailabilityWarningsMsg: Label 'The data used for availability calculation has been updated.\There are availability warnings on one or more lines.';
        NoAvailabilityWarningsMsg: Label 'The data used for availability calculation has been updated.\There are no availability warnings.';
        Text009: Label '%1 List';
        Text010: Label '%1 %2 - Availability';
        Text011: Label 'Item Tracking - Select Entries';
        PartialGlobalDataSetExists: Boolean;
        SkipLot: Boolean;
        Text013: Label 'Neutralize consumption/output';
        LotNoBySNNotFoundErr: Label 'A lot number could not be found for serial number %1.', Comment = '%1 - serial number.';

    procedure AssistEditTrackingNo(var TempTrackingSpecification: Record "Tracking Specification" temporary; SearchForSupply: Boolean; CurrentSignFactor: Integer; LookupMode: Enum "Item Tracking Type"; MaxQuantity: Decimal)
    var
        ItemTrackingSummaryForm: Page "Item Tracking Summary";
        Window: Dialog;
        AvailableQty: Decimal;
        AdjustmentQty: Decimal;
        QtyOnLine: Decimal;
        QtyHandledOnLine: Decimal;
        NewQtyOnLine: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeAssistEditTrackingNo(TempTrackingSpecification, SearchForSupply, CurrentSignFactor, LookupMode, MaxQuantity);

        Window.Open(Text004);

        IsHandled := false;
        OnAssistEditTrackingNoOnBeforeRetrieveLookupData(TempTrackingSpecification, TempGlobalEntrySummary, FullGlobalDataSetExists, IsHandled);
        if not FullGlobalDataSetExists then
            RetrieveLookupData(TempTrackingSpecification, true);

        TempGlobalReservEntry.Reset();
        TempGlobalEntrySummary.Reset();

        // Select the proper key on form
        TempGlobalEntrySummary.SetCurrentKey("Expiration Date");
        TempGlobalEntrySummary.SetFilter("Expiration Date", '<>%1', 0D);
        if TempGlobalEntrySummary.IsEmpty then
            TempGlobalEntrySummary.SetCurrentKey("Lot No.", "Serial No.");
        TempGlobalEntrySummary.SetRange("Expiration Date");
        ItemTrackingSummaryForm.SetTableView(TempGlobalEntrySummary);

        TempGlobalEntrySummary.SetCurrentKey("Lot No.", "Serial No.");
        case LookupMode of
            LookupMode::"Serial No.":
                begin
                    if TempTrackingSpecification."Lot No." <> '' then
                        TempGlobalEntrySummary.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
                    TempGlobalEntrySummary.SetRange("Serial No.", TempTrackingSpecification."Serial No.");
                    if TempGlobalEntrySummary.FindFirst then
                        ItemTrackingSummaryForm.SetRecord(TempGlobalEntrySummary);
                    TempGlobalEntrySummary.SetFilter("Serial No.", '<>%1', '');
                    TempGlobalEntrySummary.SetFilter("Table ID", '<>%1', 0);
                    ItemTrackingSummaryForm.Caption := StrSubstNo(Text009, TempGlobalReservEntry.FieldCaption("Serial No."));
                end;
            LookupMode::"Lot No.":
                begin
                    if TempTrackingSpecification."Serial No." <> '' then
                        TempGlobalEntrySummary.SetRange("Serial No.", TempTrackingSpecification."Serial No.")
                    else
                        TempGlobalEntrySummary.SetRange("Serial No.", '');
                    TempGlobalEntrySummary.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
                    if TempGlobalEntrySummary.FindFirst then
                        ItemTrackingSummaryForm.SetRecord(TempGlobalEntrySummary);
                    TempGlobalEntrySummary.SetFilter("Lot No.", '<>%1', '');
                    ItemTrackingSummaryForm.Caption := StrSubstNo(Text009, TempGlobalEntrySummary.FieldCaption("Lot No."));
                end;
        end;

        ItemTrackingSummaryForm.SetCurrentBinAndItemTrkgCode(CurrBinCode, CurrItemTrackingCode);
        OnAssistEditTrackingNoOnBeforeSetSources(TempTrackingSpecification, TempGlobalEntrySummary, MaxQuantity);
        ItemTrackingSummaryForm.SetSources(TempGlobalReservEntry, TempGlobalEntrySummary);
        ItemTrackingSummaryForm.LookupMode(SearchForSupply);
        ItemTrackingSummaryForm.SetSelectionMode(false);

        Window.Close;
        if ItemTrackingSummaryForm.RunModal = ACTION::LookupOK then begin
            ItemTrackingSummaryForm.GetRecord(TempGlobalEntrySummary);

            if TempGlobalEntrySummary."Bin Active" then
                AvailableQty := MinValueAbs(TempGlobalEntrySummary."Bin Content", TempGlobalEntrySummary."Total Available Quantity")
            else
                AvailableQty := TempGlobalEntrySummary."Total Available Quantity";
            QtyHandledOnLine := TempTrackingSpecification."Quantity Handled (Base)";
            QtyOnLine := TempTrackingSpecification."Quantity (Base)" - QtyHandledOnLine;

            if CurrentSignFactor > 0 then begin
                AvailableQty := -AvailableQty;
                QtyHandledOnLine := -QtyHandledOnLine;
                QtyOnLine := -QtyOnLine;
            end;

            if MaxQuantity < 0 then begin
                AdjustmentQty := MaxQuantity;
                if AvailableQty < 0 then
                    if AdjustmentQty > AvailableQty then
                        AdjustmentQty := AvailableQty;
                if QtyOnLine + AdjustmentQty < 0 then
                    AdjustmentQty := -QtyOnLine;
            end else begin
                AdjustmentQty := AvailableQty;
                if AvailableQty < 0 then begin
                    if QtyOnLine + AdjustmentQty < 0 then
                        AdjustmentQty := -QtyOnLine;
                end else
                    AdjustmentQty := MinValueAbs(MaxQuantity, AvailableQty);
            end;
            if LookupMode = LookupMode::"Serial No." then
                TempTrackingSpecification.Validate("Serial No.", TempGlobalEntrySummary."Serial No.");
            TempTrackingSpecification.Validate("Lot No.", TempGlobalEntrySummary."Lot No.");

            TransferExpDateFromSummary(TempTrackingSpecification, TempGlobalEntrySummary);
            if TempTrackingSpecification.IsReclass then begin
                TempTrackingSpecification."New Serial No." := TempTrackingSpecification."Serial No.";
                TempTrackingSpecification."New Lot No." := TempTrackingSpecification."Lot No.";
            end;

            NewQtyOnLine := QtyOnLine + AdjustmentQty + QtyHandledOnLine;
            if TempTrackingSpecification."Serial No." <> '' then
                if Abs(NewQtyOnLine) > 1 then
                    NewQtyOnLine := NewQtyOnLine / Abs(NewQtyOnLine); // Set to a signed value of 1.

            TempTrackingSpecification.Validate("Quantity (Base)", NewQtyOnLine);

            OnAfterAssistEditTrackingNo(TempTrackingSpecification, TempGlobalEntrySummary);
        end;
    end;

    procedure SelectMultipleTrackingNo(var TempTrackingSpecification: Record "Tracking Specification" temporary; MaxQuantity: Decimal; CurrentSignFactor: Integer)
    var
        TempEntrySummary: Record "Entry Summary" temporary;
        ItemTrackingSummaryForm: Page "Item Tracking Summary";
        Window: Dialog;
    begin
        Clear(ItemTrackingSummaryForm);
        Window.Open(Text004);
        if not FullGlobalDataSetExists then
            RetrieveLookupData(TempTrackingSpecification, true);

        TempGlobalReservEntry.Reset();
        TempGlobalEntrySummary.Reset();

        // Swap sign if negative supply lines
        if CurrentSignFactor > 0 then
            MaxQuantity := -MaxQuantity;

        // Select the proper key
        TempGlobalEntrySummary.SetCurrentKey("Expiration Date");
        TempGlobalEntrySummary.SetFilter("Expiration Date", '<>%1', 0D);
        if TempGlobalEntrySummary.IsEmpty then
            TempGlobalEntrySummary.SetCurrentKey("Lot No.", "Serial No.");
        TempGlobalEntrySummary.SetRange("Expiration Date");

        // Initialize form
        ItemTrackingSummaryForm.Caption := Text011;
        ItemTrackingSummaryForm.SetTableView(TempGlobalEntrySummary);
        TempGlobalEntrySummary.SetFilter("Table ID", '<>%1', 0); // Filter out summations
        OnSelectMultipleTrackingNoOnBeforeSetSources(TempTrackingSpecification, TempGlobalEntrySummary, MaxQuantity);
        ItemTrackingSummaryForm.SetSources(TempGlobalReservEntry, TempGlobalEntrySummary);
        ItemTrackingSummaryForm.SetSelectionMode(MaxQuantity <> 0);
        ItemTrackingSummaryForm.LookupMode(true);
        ItemTrackingSummaryForm.SetMaxQuantity(MaxQuantity);
        ItemTrackingSummaryForm.SetCurrentBinAndItemTrkgCode(CurrBinCode, CurrItemTrackingCode);

        // Run preselection on form
        ItemTrackingSummaryForm.AutoSelectTrackingNo;

        Window.Close;

        if not (ItemTrackingSummaryForm.RunModal = ACTION::LookupOK) then
            exit;
        ItemTrackingSummaryForm.GetSelected(TempEntrySummary);
        if TempEntrySummary.IsEmpty then
            exit;

        // Swap sign on the selected entries if parent is a negative supply line
        if CurrentSignFactor > 0 then // Negative supply lines
            if TempEntrySummary.Find('-') then
                repeat
                    TempEntrySummary."Selected Quantity" := -TempEntrySummary."Selected Quantity";
                    TempEntrySummary.Modify();
                until TempEntrySummary.Next = 0;

        // Modify the item tracking lines with the selected quantities
        AddSelectedTrackingToDataSet(TempEntrySummary, TempTrackingSpecification, CurrentSignFactor);
    end;

    procedure LookupTrackingAvailability(var TempTrackingSpecification: Record "Tracking Specification" temporary; LookupMode: Enum "Item Tracking Type")
    var
        ItemTrackingSummaryForm: Page "Item Tracking Summary";
        Window: Dialog;
    begin
        case LookupMode of
            LookupMode::"Serial No.":
                if TempTrackingSpecification."Serial No." = '' then
                    exit;
            LookupMode::"Lot No.":
                if TempTrackingSpecification."Lot No." = '' then
                    exit;
        end;

        Clear(ItemTrackingSummaryForm);
        Window.Open(Text004);
        TempGlobalChangedEntrySummary.Reset();

        if not (PartialGlobalDataSetExists or FullGlobalDataSetExists) then
            RetrieveLookupData(TempTrackingSpecification, true);

        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetCurrentKey("Lot No.", "Serial No.");

        TempGlobalReservEntry.Reset();

        case LookupMode of
            LookupMode::"Serial No.":
                begin
                    TempGlobalEntrySummary.SetRange("Serial No.", TempTrackingSpecification."Serial No.");
                    TempGlobalEntrySummary.SetFilter("Table ID", '<>%1', 0); // Filter out summations
                    TempGlobalReservEntry.SetRange("Serial No.", TempTrackingSpecification."Serial No.");
                    ItemTrackingSummaryForm.Caption := StrSubstNo(
                        Text010, TempTrackingSpecification.FieldCaption("Serial No."), TempTrackingSpecification."Serial No.");
                end;
            LookupMode::"Lot No.":
                begin
                    TempGlobalEntrySummary.SetRange("Serial No.", '');
                    TempGlobalEntrySummary.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
                    TempGlobalReservEntry.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
                    ItemTrackingSummaryForm.Caption := StrSubstNo(
                        Text010, TempTrackingSpecification.FieldCaption("Lot No."), TempTrackingSpecification."Lot No.");
                end;
        end;

        ItemTrackingSummaryForm.SetSources(TempGlobalReservEntry, TempGlobalEntrySummary);
        ItemTrackingSummaryForm.SetCurrentBinAndItemTrkgCode(CurrBinCode, CurrItemTrackingCode);
        ItemTrackingSummaryForm.LookupMode(false);
        ItemTrackingSummaryForm.SetSelectionMode(false);
        Window.Close;
        ItemTrackingSummaryForm.RunModal;
    end;

    procedure RetrieveLookupData(var TempTrackingSpecification: Record "Tracking Specification" temporary; FullDataSet: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ReservEntry: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        xTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        LastSummaryEntryNo := 0;
        LastReservEntryNo := 0;
        xTrackingSpecification := TempTrackingSpecification;
        TempGlobalReservEntry.Reset();
        TempGlobalReservEntry.DeleteAll();
        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.DeleteAll();

        ReservEntry.Reset();
        LastReservEntryNo := ReservEntry.GetLastEntryNo();
        ReservEntry.SetCurrentKey(
          "Item No.", "Variant Code", "Location Code", "Item Tracking", "Reservation Status", "Lot No.", "Serial No.");
        ReservEntry.SetRange("Item No.", TempTrackingSpecification."Item No.");
        ReservEntry.SetRange("Variant Code", TempTrackingSpecification."Variant Code");
        ReservEntry.SetRange("Location Code", TempTrackingSpecification."Location Code");
        ReservEntry.SetFilter("Item Tracking", '<>%1', ReservEntry."Item Tracking"::None);
        if ReservEntry.FindSet then
            repeat
                TempReservEntry := ReservEntry;
                if CanIncludeReservEntryToTrackingSpec(TempReservEntry) then
                    TempReservEntry.Insert();
            until ReservEntry.Next = 0;

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", "Location Code", "Item Tracking",
          "Lot No.", "Serial No.");
        ItemLedgEntry.SetRange("Item No.", TempTrackingSpecification."Item No.");
        ItemLedgEntry.SetRange("Variant Code", TempTrackingSpecification."Variant Code");
        ItemLedgEntry.SetRange(Open, true);
        ItemLedgEntry.SetRange("Location Code", TempTrackingSpecification."Location Code");

        OnRetrieveLookupDataOnBeforeTransferToTempRec(TempTrackingSpecification, TempReservEntry, ItemLedgEntry, FullDataSet);

        if FullDataSet then begin
            TransferReservEntryToTempRec(TempReservEntry, TempTrackingSpecification);
            TransferItemLedgToTempRec(ItemLedgEntry, TempTrackingSpecification);
        end else begin
            if TempTrackingSpecification.FindSet then
                repeat
                    ItemLedgEntry.ClearTrackingFilter;
                    TempReservEntry.ClearTrackingFilter;

                    if TempTrackingSpecification."Lot No." <> '' then begin
                        ItemLedgEntry.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
                        TempReservEntry.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
                        TransferReservEntryToTempRec(TempReservEntry, TempTrackingSpecification);
                        TransferItemLedgToTempRec(ItemLedgEntry, TempTrackingSpecification);
                    end;

                    if TempTrackingSpecification."Serial No." <> '' then begin
                        ItemLedgEntry.SetTrackingFilterFromSpec(TempTrackingSpecification);
                        TempReservEntry.SetTrackingFilterFromSpec(TempTrackingSpecification);
                        TransferReservEntryToTempRec(TempReservEntry, TempTrackingSpecification);
                        TransferItemLedgToTempRec(ItemLedgEntry, TempTrackingSpecification);
                    end;
                until TempTrackingSpecification.Next = 0;
        end;

        TempGlobalEntrySummary.Reset();
        UpdateCurrentPendingQty;
        TempTrackingSpecification := xTrackingSpecification;

        PartialGlobalDataSetExists := true;
        FullGlobalDataSetExists := FullDataSet;
        AdjustForDoubleEntries;

        OnAfterRetrieveLookupData(TempTrackingSpecification, FullDataSet, TempGlobalReservEntry, TempGlobalEntrySummary);
    end;

    local procedure TransferItemLedgToTempRec(var ItemLedgEntry: Record "Item Ledger Entry"; var TrackingSpecification: Record "Tracking Specification" temporary)
    var
        IsHandled: Boolean;
    begin
        if ItemLedgEntry.FindSet then
            repeat
                if ItemLedgEntry.TrackingExists and
                   not TempGlobalReservEntry.Get(-ItemLedgEntry."Entry No.", ItemLedgEntry.Positive)
                then begin
                    TempGlobalReservEntry.Init();
                    TempGlobalReservEntry."Entry No." := -ItemLedgEntry."Entry No.";
                    TempGlobalReservEntry."Reservation Status" := TempGlobalReservEntry."Reservation Status"::Surplus;
                    TempGlobalReservEntry.Positive := ItemLedgEntry.Positive;
                    TempGlobalReservEntry."Item No." := ItemLedgEntry."Item No.";
                    TempGlobalReservEntry."Variant Code" := ItemLedgEntry."Variant Code";
                    TempGlobalReservEntry."Location Code" := ItemLedgEntry."Location Code";
                    TempGlobalReservEntry."Quantity (Base)" := ItemLedgEntry."Remaining Quantity";
                    TempGlobalReservEntry."Source Type" := DATABASE::"Item Ledger Entry";
                    TempGlobalReservEntry."Source Ref. No." := ItemLedgEntry."Entry No.";
                    TempGlobalReservEntry.CopyTrackingFromItemLedgEntry(ItemLedgEntry);

                    if TempGlobalReservEntry.Positive then begin
                        TempGlobalReservEntry."Warranty Date" := ItemLedgEntry."Warranty Date";
                        TempGlobalReservEntry."Expiration Date" := ItemLedgEntry."Expiration Date";
                        TempGlobalReservEntry."Expected Receipt Date" := 0D
                    end else
                        TempGlobalReservEntry."Shipment Date" := DMY2Date(31, 12, 9999);

                    IsHandled := false;
                    OnTransferItemLedgToTempRecOnBeforeInsert(TempGlobalReservEntry, ItemLedgEntry, TrackingSpecification, IsHandled);
                    if not IsHandled then begin
                        TempGlobalReservEntry.Insert();
                        CreateEntrySummary(TrackingSpecification, TempGlobalReservEntry);
                    end;
                end;
            until ItemLedgEntry.Next = 0;
    end;

    local procedure TransferReservEntryToTempRec(var TempReservEntry: Record "Reservation Entry" temporary; var TrackingSpecification: Record "Tracking Specification" temporary)
    var
        IsHandled: Boolean;
    begin
        if TempReservEntry.FindSet then
            repeat
                if not TempGlobalReservEntry.Get(TempReservEntry."Entry No.", TempReservEntry.Positive) then begin
                    TempGlobalReservEntry := TempReservEntry;
                    TempGlobalReservEntry."Transferred from Entry No." := 0;
                    IsHandled := false;
                    OnAfterTransferReservEntryToTempRec(TempGlobalReservEntry, TempReservEntry, TrackingSpecification, IsHandled);
                    if not IsHandled then begin
                        TempGlobalReservEntry.Insert();
                        CreateEntrySummary(TrackingSpecification, TempGlobalReservEntry);
                    end;
                end;
            until TempReservEntry.Next = 0;
    end;

    local procedure CreateEntrySummary(TrackingSpecification: Record "Tracking Specification" temporary; TempReservEntry: Record "Reservation Entry" temporary)
    var
        LookupMode: Enum "Item Tracking Type";
    begin
        CreateEntrySummary2(TrackingSpecification, LookupMode::"Serial No.", TempReservEntry);
        CreateEntrySummary2(TrackingSpecification, LookupMode::"Lot No.", TempReservEntry);

        OnAfterCreateEntrySummary(TrackingSpecification, TempGlobalEntrySummary);
    end;

    local procedure CreateEntrySummary2(TrackingSpecification: Record "Tracking Specification" temporary; LookupMode: Enum "Item Tracking Type"; TempReservEntry: Record "Reservation Entry" temporary)
    var
        DoInsert: Boolean;
    begin
        OnBeforeCreateEntrySummary2(TempGlobalEntrySummary, TempReservEntry, TrackingSpecification);

        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetCurrentKey("Lot No.", "Serial No.");

        // Set filters
        case LookupMode of
            LookupMode::"Serial No.":
                begin
                    if TempReservEntry."Serial No." = '' then
                        exit;
                    TempGlobalEntrySummary.SetTrackingFilterFromReservEntry(TempReservEntry);
                end;
            LookupMode::"Lot No.":
                begin
                    TempGlobalEntrySummary.SetTrackingFilter('', TempReservEntry."Lot No.");
                    if TempReservEntry."Serial No." <> '' then
                        TempGlobalEntrySummary.SetRange("Table ID", 0)
                    else
                        TempGlobalEntrySummary.SetFilter("Table ID", '<>%1', 0);
                end;
        end;

        // If no summary exists, create new record
        if not TempGlobalEntrySummary.FindFirst then begin
            TempGlobalEntrySummary.Init();
            TempGlobalEntrySummary."Entry No." := LastSummaryEntryNo + 1;
            LastSummaryEntryNo := TempGlobalEntrySummary."Entry No.";

            if (LookupMode = LookupMode::"Lot No.") and (TempReservEntry."Serial No." <> '') then
                TempGlobalEntrySummary."Table ID" := 0 // Mark as summation
            else
                TempGlobalEntrySummary."Table ID" := TempReservEntry."Source Type";
            if LookupMode = LookupMode::"Serial No." then
                TempGlobalEntrySummary."Serial No." := TempReservEntry."Serial No."
            else
                TempGlobalEntrySummary."Serial No." := '';
            TempGlobalEntrySummary."Lot No." := TempReservEntry."Lot No.";
            TempGlobalEntrySummary."Bin Active" := CurrBinCode <> '';
            OnBeforeUpdateBinContent(TempGlobalEntrySummary, TempReservEntry);
            UpdateBinContent(TempGlobalEntrySummary);

            // If consumption/output fill in double entry value here:
            TempGlobalEntrySummary."Double-entry Adjustment" :=
              MaxDoubleEntryAdjustQty(TrackingSpecification, TempGlobalEntrySummary);

            DoInsert := true;
        end;

        // Sum up values
        if TempReservEntry.Positive then begin
            TempGlobalEntrySummary."Warranty Date" := TempReservEntry."Warranty Date";
            TempGlobalEntrySummary."Expiration Date" := TempReservEntry."Expiration Date";
            if TempReservEntry."Entry No." < 0 then // The record represents an Item ledger entry
                TempGlobalEntrySummary."Total Quantity" += TempReservEntry."Quantity (Base)";
            if TempReservEntry."Reservation Status" = TempReservEntry."Reservation Status"::Reservation then
                TempGlobalEntrySummary."Total Reserved Quantity" += TempReservEntry."Quantity (Base)";
        end else begin
            TempGlobalEntrySummary."Total Requested Quantity" -= TempReservEntry."Quantity (Base)";
            if TempReservEntry.HasSamePointerWithSpec(TrackingSpecification) then begin
                if TempReservEntry."Reservation Status" = TempReservEntry."Reservation Status"::Reservation then
                    TempGlobalEntrySummary."Current Reserved Quantity" -= TempReservEntry."Quantity (Base)";
                if TempReservEntry."Entry No." > 0 then // The record represents a reservation entry
                    TempGlobalEntrySummary."Current Requested Quantity" -= TempReservEntry."Quantity (Base)";
            end;
        end;

        // Update available quantity on the record
        TempGlobalEntrySummary.UpdateAvailable;
        if DoInsert then
            TempGlobalEntrySummary.Insert
        else
            TempGlobalEntrySummary.Modify();

        OnAfterCreateEntrySummary2(TempGlobalEntrySummary, TempReservEntry);
    end;

    local procedure MinValueAbs(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Abs(Value1) < Abs(Value2) then
            exit(Value1);

        exit(Value2);
    end;

    procedure AddSelectedTrackingToDataSet(var TempEntrySummary: Record "Entry Summary" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary; CurrentSignFactor: Integer)
    var
        TrackingSpecification2: Record "Tracking Specification";
        LastEntryNo: Integer;
        ChangeType: Option Insert,Modify,Delete;
    begin
        TempEntrySummary.Reset();
        TempEntrySummary.SetFilter("Selected Quantity", '<>%1', 0);
        if TempEntrySummary.IsEmpty then
            exit;

        // To save general and pointer information
        TrackingSpecification2.Init();
        TrackingSpecification2."Item No." := TempTrackingSpecification."Item No.";
        TrackingSpecification2."Location Code" := TempTrackingSpecification."Location Code";
        TrackingSpecification2."Source Type" := TempTrackingSpecification."Source Type";
        TrackingSpecification2."Source Subtype" := TempTrackingSpecification."Source Subtype";
        TrackingSpecification2."Source ID" := TempTrackingSpecification."Source ID";
        TrackingSpecification2."Source Batch Name" := TempTrackingSpecification."Source Batch Name";
        TrackingSpecification2."Source Prod. Order Line" := TempTrackingSpecification."Source Prod. Order Line";
        TrackingSpecification2."Source Ref. No." := TempTrackingSpecification."Source Ref. No.";
        TrackingSpecification2.Positive := TempTrackingSpecification.Positive;
        TrackingSpecification2."Qty. per Unit of Measure" := TempTrackingSpecification."Qty. per Unit of Measure";
        TrackingSpecification2."Variant Code" := TempTrackingSpecification."Variant Code";

        OnAddSelectedTrackingToDataSetOnAfterInitTrackingSpecification2(TrackingSpecification2, TempTrackingSpecification);

        TempTrackingSpecification.Reset();
        LastEntryNo := TempTrackingSpecification.GetLastEntryNo();

        TempEntrySummary.FindFirst;
        repeat
            TempTrackingSpecification.SetTrackingFilterFromEntrySummary(TempEntrySummary);
            if TempTrackingSpecification.FindFirst then begin
                TempTrackingSpecification.Validate("Quantity (Base)",
                  TempTrackingSpecification."Quantity (Base)" + TempEntrySummary."Selected Quantity");
                TempTrackingSpecification."Buffer Status" := TempTrackingSpecification."Buffer Status"::MODIFY;
                TransferExpDateFromSummary(TempTrackingSpecification, TempEntrySummary);
                TempTrackingSpecification.Modify();
                UpdateTrackingDataSetWithChange(TempTrackingSpecification, true, CurrentSignFactor, ChangeType::Modify);
            end else begin
                TempTrackingSpecification := TrackingSpecification2;
                TempTrackingSpecification."Entry No." := LastEntryNo + 1;
                LastEntryNo := TempTrackingSpecification."Entry No.";
                TempTrackingSpecification.CopyTrackingFromEntrySummary(TempEntrySummary);
                TempTrackingSpecification."Buffer Status" := TempTrackingSpecification."Buffer Status"::INSERT;
                TransferExpDateFromSummary(TempTrackingSpecification, TempEntrySummary);
                if TempTrackingSpecification.IsReclass then begin
                    TempTrackingSpecification."New Serial No." := TempTrackingSpecification."Serial No.";
                    TempTrackingSpecification."New Lot No." := TempTrackingSpecification."Lot No.";
                end;
                TempTrackingSpecification.Validate("Quantity (Base)", TempEntrySummary."Selected Quantity");
                OnBeforeTempTrackingSpecificationInsert(TempTrackingSpecification, TempEntrySummary);
                TempTrackingSpecification.Insert();
                UpdateTrackingDataSetWithChange(TempTrackingSpecification, true, CurrentSignFactor, ChangeType::Insert);
            end;
        until TempEntrySummary.Next = 0;

        TempTrackingSpecification.Reset();
    end;

    procedure TrackingAvailable(TempTrackingSpecification: Record "Tracking Specification" temporary; LookupMode: Enum "Item Tracking Type"): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeTrackingAvailable(TempTrackingSpecification, IsHandled);
        if IsHandled then
            exit(Result);

        CurrItemTrackingCode.TestField(Code);
        case LookupMode of
            LookupMode::"Serial No.":
                if (TempTrackingSpecification."Serial No." = '') or (not CurrItemTrackingCode."SN Specific Tracking") then
                    exit(true);
            LookupMode::"Lot No.":
                if (TempTrackingSpecification."Lot No." = '') or (not CurrItemTrackingCode."Lot Specific Tracking") then
                    exit(true);
        end;

        if not (PartialGlobalDataSetExists or FullGlobalDataSetExists) then
            RetrieveLookupData(TempTrackingSpecification, true);

        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetCurrentKey("Lot No.", "Serial No.");
        TempGlobalEntrySummary.SetTrackingFilterFromSpec(TempTrackingSpecification);
        TempGlobalEntrySummary.CalcSums("Total Available Quantity");
        if CheckJobInPurchLine(TempTrackingSpecification) then
            exit(TempGlobalEntrySummary.FindFirst);
        exit(TempGlobalEntrySummary."Total Available Quantity" >= 0);
    end;

    procedure UpdateTrackingDataSetWithChange(var TempTrackingSpecificationChanged: Record "Tracking Specification" temporary; LineIsDemand: Boolean; CurrentSignFactor: Integer; ChangeType: Option Insert,Modify,Delete)
    var
        LastEntryNo: Integer;
    begin
        if not TempTrackingSpecificationChanged.TrackingExists then
            exit;

        LastEntryNo := UpdateTrackingGlobalChangeRec(TempTrackingSpecificationChanged, LineIsDemand, CurrentSignFactor, ChangeType);
        TempGlobalChangedEntrySummary.Get(LastEntryNo);
        UpdateTempSummaryWithChange(TempGlobalChangedEntrySummary);
    end;

    local procedure UpdateTrackingGlobalChangeRec(var TempTrackingSpecificationChanged: Record "Tracking Specification" temporary; LineIsDemand: Boolean; CurrentSignFactor: Integer; ChangeType: Option Insert,Modify,Delete): Integer
    var
        NewQuantity: Decimal;
        LastEntryNo: Integer;
    begin
        if (ChangeType = ChangeType::Delete) or not LineIsDemand then
            NewQuantity := 0
        else
            NewQuantity := TempTrackingSpecificationChanged."Quantity (Base)" - TempTrackingSpecificationChanged."Quantity Handled (Base)";

        if CurrentSignFactor > 0 then // Negative supply lines
            NewQuantity := -NewQuantity;

        TempGlobalChangedEntrySummary.Reset();
        TempGlobalChangedEntrySummary.SetCurrentKey("Lot No.", "Serial No.");
        TempGlobalChangedEntrySummary.SetTrackingFilterFromSpec(TempTrackingSpecificationChanged);
        if not TempGlobalChangedEntrySummary.FindFirst then begin
            TempGlobalChangedEntrySummary.Reset();
            LastEntryNo := TempGlobalChangedEntrySummary.GetLastEntryNo();
            TempGlobalChangedEntrySummary.Init();
            TempGlobalChangedEntrySummary."Entry No." := LastEntryNo + 1;
            TempGlobalChangedEntrySummary.CopyTrackingFromSpec(TempTrackingSpecificationChanged);
            TempGlobalChangedEntrySummary."Current Pending Quantity" := NewQuantity;
            if TempTrackingSpecificationChanged."Serial No." <> '' then
                TempGlobalChangedEntrySummary."Table ID" := DATABASE::"Tracking Specification"; // Not a summary line
            OnBeforeTempGlobalChangedEntrySummaryInsert(TempGlobalChangedEntrySummary, TempTrackingSpecificationChanged);
            TempGlobalChangedEntrySummary.Insert();
            PartialGlobalDataSetExists := false; // The partial data set does not cover the new line
        end else
            if LineIsDemand then begin
                TempGlobalChangedEntrySummary."Current Pending Quantity" := NewQuantity;
                TempGlobalChangedEntrySummary.Modify();
            end;
        exit(TempGlobalChangedEntrySummary."Entry No.");
    end;

    local procedure UpdateCurrentPendingQty()
    var
        TempLastGlobalEntrySummary: Record "Entry Summary" temporary;
    begin
        TempGlobalChangedEntrySummary.Reset();
        TempGlobalChangedEntrySummary.SetCurrentKey("Lot No.", "Serial No.");
        if TempGlobalChangedEntrySummary.FindSet then
            repeat
                if TempGlobalChangedEntrySummary."Lot No." <> '' then begin
                    // only last record with Lot Number updates Summary
                    if TempGlobalChangedEntrySummary."Lot No." <> TempLastGlobalEntrySummary."Lot No." then
                        FindLastGlobalEntrySummary(TempGlobalChangedEntrySummary, TempLastGlobalEntrySummary);
                    SkipLot := not (TempGlobalChangedEntrySummary."Entry No." = TempLastGlobalEntrySummary."Entry No.");
                end;
                UpdateTempSummaryWithChange(TempGlobalChangedEntrySummary);
            until TempGlobalChangedEntrySummary.Next = 0;
    end;

    local procedure UpdateTempSummaryWithChange(var ChangedEntrySummary: Record "Entry Summary" temporary)
    var
        LastEntryNo: Integer;
        SumOfSNPendingQuantity: Decimal;
        SumOfSNRequestedQuantity: Decimal;
    begin
        TempGlobalEntrySummary.Reset();
        LastEntryNo := TempGlobalEntrySummary.GetLastEntryNo();

        TempGlobalEntrySummary.SetCurrentKey("Lot No.", "Serial No.");
        if ChangedEntrySummary."Serial No." <> '' then begin
            TempGlobalEntrySummary.SetTrackingFilterFromEntrySummary(ChangedEntrySummary);
            if TempGlobalEntrySummary.FindFirst then begin
                TempGlobalEntrySummary."Current Pending Quantity" := ChangedEntrySummary."Current Pending Quantity" -
                  TempGlobalEntrySummary."Current Requested Quantity";
                TempGlobalEntrySummary.UpdateAvailable;
                TempGlobalEntrySummary.Modify();
            end else begin
                TempGlobalEntrySummary := ChangedEntrySummary;
                TempGlobalEntrySummary."Entry No." := LastEntryNo + 1;
                LastEntryNo := TempGlobalEntrySummary."Entry No.";
                TempGlobalEntrySummary."Bin Active" := CurrBinCode <> '';
                UpdateBinContent(TempGlobalEntrySummary);
                TempGlobalEntrySummary.UpdateAvailable;
                TempGlobalEntrySummary.Insert();
            end;

            if (ChangedEntrySummary."Lot No." <> '') and not SkipLot then begin
                TempGlobalEntrySummary.SetFilter("Serial No.", '<>%1', '');
                TempGlobalEntrySummary.SetRange("Lot No.", ChangedEntrySummary."Lot No.");
                TempGlobalEntrySummary.CalcSums("Current Pending Quantity", "Current Requested Quantity");
                SumOfSNPendingQuantity := TempGlobalEntrySummary."Current Pending Quantity";
                SumOfSNRequestedQuantity := TempGlobalEntrySummary."Current Requested Quantity";
            end;
        end;

        if (ChangedEntrySummary."Lot No." <> '') and not SkipLot then begin
            TempGlobalEntrySummary.SetTrackingFilter('', ChangedEntrySummary."Lot No.");

            if ChangedEntrySummary."Serial No." <> '' then
                TempGlobalEntrySummary.SetRange("Table ID", 0)
            else
                TempGlobalEntrySummary.SetFilter("Table ID", '<>%1', 0);

            if TempGlobalEntrySummary.FindFirst then begin
                if ChangedEntrySummary."Serial No." <> '' then begin
                    TempGlobalEntrySummary."Current Pending Quantity" := SumOfSNPendingQuantity;
                    TempGlobalEntrySummary."Current Requested Quantity" := SumOfSNRequestedQuantity;
                end else
                    TempGlobalEntrySummary."Current Pending Quantity" := ChangedEntrySummary."Current Pending Quantity" -
                      TempGlobalEntrySummary."Current Requested Quantity";

                TempGlobalEntrySummary.UpdateAvailable;
                TempGlobalEntrySummary.Modify();
            end else begin
                TempGlobalEntrySummary := ChangedEntrySummary;
                TempGlobalEntrySummary."Entry No." := LastEntryNo + 1;
                TempGlobalEntrySummary."Serial No." := '';
                if ChangedEntrySummary."Serial No." <> '' then // Mark as summation
                    TempGlobalEntrySummary."Table ID" := 0
                else
                    TempGlobalEntrySummary."Table ID" := DATABASE::"Tracking Specification";
                TempGlobalEntrySummary."Bin Active" := CurrBinCode <> '';
                UpdateBinContent(TempGlobalEntrySummary);
                TempGlobalEntrySummary.UpdateAvailable;
                TempGlobalEntrySummary.Insert();
            end;
        end;
    end;

    procedure RefreshTrackingAvailability(var TempTrackingSpecification: Record "Tracking Specification" temporary; ShowMessage: Boolean) AvailabilityOK: Boolean
    var
        TrackingSpecification2: Record "Tracking Specification";
        LookupMode: Enum "Item Tracking Type";
        PreviousLotNo: Code[50];
    begin
        AvailabilityOK := true;
        if TempTrackingSpecification.Positive then
            exit;

        TrackingSpecification2.Copy(TempTrackingSpecification);
        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.IsEmpty then begin
            TempTrackingSpecification.Copy(TrackingSpecification2);
            exit;
        end;

        FullGlobalDataSetExists := false;
        PartialGlobalDataSetExists := false;
        RetrieveLookupData(TempTrackingSpecification, false);

        TempTrackingSpecification.SetCurrentKey("Lot No.", "Serial No.");
        TempTrackingSpecification.Find('-');
        LookupMode := LookupMode::"Serial No.";
        repeat
            if TempTrackingSpecification."Lot No." <> PreviousLotNo then begin
                PreviousLotNo := TempTrackingSpecification."Lot No.";
                LookupMode := LookupMode::"Lot No.";

                if not TrackingAvailable(TempTrackingSpecification, LookupMode) then
                    AvailabilityOK := false;

                LookupMode := LookupMode::"Serial No.";
            end;

            if not TrackingAvailable(TempTrackingSpecification, LookupMode) then
                AvailabilityOK := false;
        until TempTrackingSpecification.Next = 0;

        if ShowMessage then
            if AvailabilityOK then
                Message(NoAvailabilityWarningsMsg)
            else
                Message(AvailabilityWarningsMsg);

        TempTrackingSpecification.Copy(TrackingSpecification2);
    end;

    procedure SetCurrentBinAndItemTrkgCode(BinCode: Code[20]; ItemTrackingCode: Record "Item Tracking Code")
    var
        xBinCode: Code[20];
    begin
        xBinCode := CurrBinCode;
        CurrBinCode := BinCode;
        CurrItemTrackingCode := ItemTrackingCode;

        if xBinCode <> BinCode then
            if PartialGlobalDataSetExists then
                RefreshBinContent(TempGlobalEntrySummary);
    end;

    local procedure UpdateBinContent(var TempEntrySummary: Record "Entry Summary" temporary)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        if CurrBinCode = '' then
            exit;
        CurrItemTrackingCode.TestField(Code);
        WarehouseEntry.Reset();
        WarehouseEntry.SetCurrentKey(
          "Item No.", "Bin Code", "Location Code", "Variant Code",
          "Unit of Measure Code", "Lot No.", "Serial No.");
        WarehouseEntry.SetRange("Item No.", TempGlobalReservEntry."Item No.");
        WarehouseEntry.SetRange("Bin Code", CurrBinCode);
        WarehouseEntry.SetRange("Location Code", TempGlobalReservEntry."Location Code");
        WarehouseEntry.SetRange("Variant Code", TempGlobalReservEntry."Variant Code");
        if CurrItemTrackingCode."SN Warehouse Tracking" then
            if TempEntrySummary."Serial No." <> '' then
                WarehouseEntry.SetRange("Serial No.", TempEntrySummary."Serial No.");
        if CurrItemTrackingCode."Lot Warehouse Tracking" then
            if TempEntrySummary."Lot No." <> '' then
                WarehouseEntry.SetRange("Lot No.", TempEntrySummary."Lot No.");
        WarehouseEntry.CalcSums("Qty. (Base)");

        TempEntrySummary."Bin Content" := WarehouseEntry."Qty. (Base)";
    end;

    local procedure RefreshBinContent(var TempEntrySummary: Record "Entry Summary" temporary)
    begin
        TempEntrySummary.Reset();
        if TempEntrySummary.FindSet then
            repeat
                if CurrBinCode <> '' then
                    UpdateBinContent(TempEntrySummary)
                else
                    TempEntrySummary."Bin Content" := 0;
                TempEntrySummary.Modify();
            until TempEntrySummary.Next = 0;
    end;

    local procedure TransferExpDateFromSummary(var TrackingSpecification: Record "Tracking Specification" temporary; var TempEntrySummary: Record "Entry Summary" temporary)
    begin
        // Handle Expiration Date
        if TempEntrySummary."Total Quantity" <> 0 then begin
            TrackingSpecification."Buffer Status2" := TrackingSpecification."Buffer Status2"::"ExpDate blocked";
            TrackingSpecification."Expiration Date" := TempEntrySummary."Expiration Date";
            if TrackingSpecification.IsReclass then
                TrackingSpecification."New Expiration Date" := TrackingSpecification."Expiration Date"
            else
                TrackingSpecification."New Expiration Date" := 0D;
        end else begin
            TrackingSpecification."Buffer Status2" := 0;
            TrackingSpecification."Expiration Date" := 0D;
            TrackingSpecification."New Expiration Date" := 0D;
        end;

        OnAfterTransferExpDateFromSummary(TrackingSpecification, TempEntrySummary);
    end;

    local procedure AdjustForDoubleEntries()
    begin
        TempGlobalAdjustEntry.Reset();
        TempGlobalAdjustEntry.DeleteAll();

        TempGlobalTrackingSpec.Reset();
        TempGlobalTrackingSpec.DeleteAll();

        // Check if there is any need to investigate:
        TempGlobalReservEntry.Reset();
        TempGlobalReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name");
        TempGlobalReservEntry.SetRange("Reservation Status", TempGlobalReservEntry."Reservation Status"::Prospect);
        TempGlobalReservEntry.SetRange("Source Type", DATABASE::"Item Journal Line");
        TempGlobalReservEntry.SetRange("Source Subtype", 5, 6); // Consumption, Output
        if TempGlobalReservEntry.IsEmpty then  // No journal lines with consumption or output exist
            exit;

        TempGlobalReservEntry.Reset();
        TempGlobalReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name");
        TempGlobalReservEntry.SetRange("Source Type", DATABASE::"Prod. Order Line");
        TempGlobalReservEntry.SetRange("Source Subtype", 3); // Released order
        if TempGlobalReservEntry.FindSet then
            repeat
                // Sum up per prod. order line per lot/sn
                SumUpTempTrkgSpec(TempGlobalTrackingSpec, TempGlobalReservEntry);
            until TempGlobalReservEntry.Next = 0;

        TempGlobalReservEntry.Reset();
        TempGlobalReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name");
        TempGlobalReservEntry.SetRange("Source Type", DATABASE::"Prod. Order Component");
        TempGlobalReservEntry.SetRange("Source Subtype", 3); // Released order
        if TempGlobalReservEntry.FindSet then
            repeat
                // Sum up per prod. order component per lot/sn
                SumUpTempTrkgSpec(TempGlobalTrackingSpec, TempGlobalReservEntry);
            until TempGlobalReservEntry.Next = 0;

        TempGlobalReservEntry.Reset();
        TempGlobalReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name");
        TempGlobalReservEntry.SetRange("Reservation Status", TempGlobalReservEntry."Reservation Status"::Prospect);
        TempGlobalReservEntry.SetRange("Source Type", DATABASE::"Item Journal Line");
        TempGlobalReservEntry.SetRange("Source Subtype", 5, 6); // Consumption, Output

        if TempGlobalReservEntry.FindSet then
            repeat
                // Sum up per Component line per lot/sn
                RelateJnlLineToTempTrkgSpec(TempGlobalReservEntry, TempGlobalTrackingSpec);
            until TempGlobalReservEntry.Next = 0;

        InsertAdjustmentEntries;
    end;

    local procedure SumUpTempTrkgSpec(var TempTrackingSpecification: Record "Tracking Specification" temporary; ReservEntry: Record "Reservation Entry")
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        TempTrackingSpecification.SetSourceFilter(
          ReservEntry."Source Type", ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.", false);
        TempTrackingSpecification.SetSourceFilter(ReservEntry."Source Batch Name", ReservEntry."Source Prod. Order Line");
        TempTrackingSpecification.SetTrackingFilterFromReservEntry(ReservEntry);
        if TempTrackingSpecification.FindFirst then begin
            TempTrackingSpecification."Quantity (Base)" += ReservEntry."Quantity (Base)";
            OnBeforeTempTrackingSpecificationModify(TempTrackingSpecification, ReservEntry);
            TempTrackingSpecification.Modify();
        end else begin
            ItemTrackingMgt.CreateTrackingSpecification(ReservEntry, TempTrackingSpecification);
            if not ReservEntry.Positive then               // To avoid inserting existing entry when both sides of the reservation
                TempTrackingSpecification."Entry No." *= -1; // are handled.
            TempTrackingSpecification.Insert();
        end;
    end;

    local procedure RelateJnlLineToTempTrkgSpec(var ReservEntry: Record "Reservation Entry"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        ItemJnlLine: Record "Item Journal Line";
        RemainingQty: Decimal;
        AdjustQty: Decimal;
        QtyOnJnlLine: Decimal;
    begin
        // Pre-check
        ReservEntry.TestField("Reservation Status", ReservEntry."Reservation Status"::Prospect);
        ReservEntry.TestField("Source Type", DATABASE::"Item Journal Line");
        if not (ReservEntry."Source Subtype" in [5, 6]) then
            ReservEntry.FieldError("Source Subtype");

        if not ItemJnlLine.Get(ReservEntry."Source ID",
             ReservEntry."Source Batch Name", ReservEntry."Source Ref. No.")
        then
            exit;

        if (ItemJnlLine."Order Type" <> ItemJnlLine."Order Type"::Production) or
           (ItemJnlLine."Order No." = '') or
           (ItemJnlLine."Order Line No." = 0)
        then
            exit;

        // Buffer fields are used as follows:
        // "Buffer Value1" : Summed up quantity on journal line(s)
        // "Buffer Value2" : Adjustment needed to neutralize double entries

        if FindRelatedParentTrkgSpec(ItemJnlLine, TempTrackingSpecification,
             ReservEntry."Serial No.", ReservEntry."Lot No.")
        then begin
            RemainingQty := TempTrackingSpecification."Quantity (Base)" + TempTrackingSpecification."Buffer Value2";
            QtyOnJnlLine := ReservEntry."Quantity (Base)";
            ReservEntry."Transferred from Entry No." := Abs(TempTrackingSpecification."Entry No.");
            ReservEntry.Modify();

            if (RemainingQty <> 0) and (RemainingQty * QtyOnJnlLine > 0) then begin
                if Abs(QtyOnJnlLine) <= Abs(RemainingQty) then
                    AdjustQty := -QtyOnJnlLine
                else
                    AdjustQty := -RemainingQty;
            end;

            TempTrackingSpecification."Buffer Value1" += QtyOnJnlLine;
            TempTrackingSpecification."Buffer Value2" += AdjustQty;
            TempTrackingSpecification.Modify();
            AddToAdjustmentEntryDataSet(ReservEntry, AdjustQty);
        end;
    end;

    local procedure FindRelatedParentTrkgSpec(ItemJnlLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; SerialNo: Code[50]; LotNo: Code[50]): Boolean
    begin
        ItemJnlLine.TestField("Order Type", ItemJnlLine."Order Type"::Production);
        TempTrackingSpecification.Reset();
        case ItemJnlLine."Entry Type" of
            ItemJnlLine."Entry Type"::Consumption:
                begin
                    if ItemJnlLine."Prod. Order Comp. Line No." = 0 then
                        exit;
                    TempTrackingSpecification.SetSourceFilter(
                      DATABASE::"Prod. Order Component", 3, ItemJnlLine."Order No.", ItemJnlLine."Prod. Order Comp. Line No.", false);
                    TempTrackingSpecification.SetSourceFilter('', ItemJnlLine."Order Line No.");
                end;
            ItemJnlLine."Entry Type"::Output:
                begin
                    TempTrackingSpecification.SetSourceFilter(DATABASE::"Prod. Order Line", 3, ItemJnlLine."Order No.", -1, false);
                    TempTrackingSpecification.SetSourceFilter('', ItemJnlLine."Order Line No.");
                end;
        end;
        TempTrackingSpecification.SetTrackingFilter(SerialNo, LotNo);
        exit(TempTrackingSpecification.FindFirst);
    end;

    local procedure AddToAdjustmentEntryDataSet(var ReservEntry: Record "Reservation Entry"; AdjustQty: Decimal)
    begin
        if AdjustQty = 0 then
            exit;

        TempGlobalAdjustEntry := ReservEntry;
        TempGlobalAdjustEntry."Source Type" := -ReservEntry."Source Type";
        TempGlobalAdjustEntry.Description := CopyStr(Text013, 1, MaxStrLen(TempGlobalAdjustEntry.Description));
        TempGlobalAdjustEntry."Quantity (Base)" := AdjustQty;
        TempGlobalAdjustEntry."Entry No." += LastReservEntryNo; // Use last entry no as offset to avoid inserting existing entry
        TempGlobalAdjustEntry.Insert();
    end;

    local procedure InsertAdjustmentEntries()
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        TempGlobalAdjustEntry.Reset();
        if not TempGlobalAdjustEntry.FindSet then
            exit;

        TempTrackingSpecification.Init();
        TempTrackingSpecification.Insert();
        repeat
            CreateEntrySummary(TempTrackingSpecification, TempGlobalAdjustEntry); // TrackingSpecification is a dummy record
            TempGlobalReservEntry := TempGlobalAdjustEntry;
            TempGlobalReservEntry.Insert();
        until TempGlobalAdjustEntry.Next = 0;
    end;

    local procedure MaxDoubleEntryAdjustQty(var TempItemTrackLineChanged: Record "Tracking Specification" temporary; var ChangedEntrySummary: Record "Entry Summary" temporary): Decimal
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        if not (TempItemTrackLineChanged."Source Type" = DATABASE::"Item Journal Line") then
            exit;

        if not (TempItemTrackLineChanged."Source Subtype" in [5, 6]) then
            exit;

        if not ItemJnlLine.Get(TempItemTrackLineChanged."Source ID",
             TempItemTrackLineChanged."Source Batch Name", TempItemTrackLineChanged."Source Ref. No.")
        then
            exit;

        TempGlobalTrackingSpec.Reset();

        if FindRelatedParentTrkgSpec(ItemJnlLine, TempGlobalTrackingSpec,
             ChangedEntrySummary."Serial No.", ChangedEntrySummary."Lot No.")
        then
            exit(-TempGlobalTrackingSpec."Quantity (Base)" - TempGlobalTrackingSpec."Buffer Value2");
    end;

    procedure CurrentDataSetMatches(ItemNo: Code[20]; VariantCode: Code[20]; LocationCode: Code[10]): Boolean
    begin
        exit(
          (TempGlobalReservEntry."Item No." = ItemNo) and
          (TempGlobalReservEntry."Variant Code" = VariantCode) and
          (TempGlobalReservEntry."Location Code" = LocationCode));
    end;

    local procedure CheckJobInPurchLine(TrackingSpecification: Record "Tracking Specification"): Boolean
    var
        PurchLine: Record "Purchase Line";
    begin
        with TrackingSpecification do
            if ("Source Type" = DATABASE::"Purchase Line") and ("Source Subtype" = "Source Subtype"::"3") then begin
                PurchLine.Reset();
                PurchLine.SetRange("Document Type", "Source Subtype");
                PurchLine.SetRange("Document No.", "Source ID");
                PurchLine.SetRange("Line No.", "Source Ref. No.");
                if PurchLine.FindFirst then
                    exit(PurchLine."Job No." <> '');
            end;
    end;

    procedure FindLotNoBySN(TrackingSpecification: Record "Tracking Specification"): Code[50]
    var
        LotNo: Code[50];
    begin
        if FindLotNoBySNSilent(LotNo, TrackingSpecification) then
            exit(LotNo);

        Error(LotNoBySNNotFoundErr, TrackingSpecification."Serial No.");
    end;

    procedure FindLotNoBySNSilent(var LotNo: Code[50]; TrackingSpecification: Record "Tracking Specification"): Boolean
    begin
        Clear(LotNo);
        if not (PartialGlobalDataSetExists or FullGlobalDataSetExists) then
            RetrieveLookupData(TrackingSpecification, true);

        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetCurrentKey("Lot No.", "Serial No.");
        TempGlobalEntrySummary.SetRange("Serial No.", TrackingSpecification."Serial No.");
        TempGlobalEntrySummary.SetFilter("Lot No.", '<>%1', '');
        if not TempGlobalEntrySummary.FindFirst then
            exit(false);

        LotNo := TempGlobalEntrySummary."Lot No.";
        exit(true);
    end;

    procedure GetAvailableLotQty(TrackingSpecification: Record "Tracking Specification"): Decimal
    begin
        if TrackingSpecification."Lot No." = '' then
            exit(0);

        if not (PartialGlobalDataSetExists or FullGlobalDataSetExists) then
            RetrieveLookupData(TrackingSpecification, true);

        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetCurrentKey("Lot No.", "Serial No.");
        TempGlobalEntrySummary.SetRange("Lot No.", TrackingSpecification."Lot No.");
        TempGlobalEntrySummary.CalcSums("Total Available Quantity");
        exit(TempGlobalEntrySummary."Total Available Quantity");
    end;

    procedure SetSkipLot(SkipLot2: Boolean)
    begin
        // only last record with Lot Number updates Summary.
        SkipLot := SkipLot2;
    end;

    local procedure FindLastGlobalEntrySummary(var GlobalChangedEntrySummary: Record "Entry Summary"; var LastGlobalEntrySummary: Record "Entry Summary")
    var
        TempGlobalChangedEntrySummary2: Record "Entry Summary" temporary;
    begin
        TempGlobalChangedEntrySummary2 := GlobalChangedEntrySummary;
        GlobalChangedEntrySummary.SetRange("Lot No.", GlobalChangedEntrySummary."Lot No.");
        if GlobalChangedEntrySummary.FindLast then
            LastGlobalEntrySummary := GlobalChangedEntrySummary;
        GlobalChangedEntrySummary.Copy(TempGlobalChangedEntrySummary2);
    end;

    local procedure CanIncludeReservEntryToTrackingSpec(TempReservEntry: Record "Reservation Entry" temporary): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        with TempReservEntry do
            if ("Reservation Status" = "Reservation Status"::Prospect) and
               ("Source Type" = DATABASE::"Sales Line") and
               ("Source Subtype" = 2)
            then begin
                SalesLine.Get("Source Subtype", "Source ID", "Source Ref. No.");
                if SalesLine."Shipment No." <> '' then
                    exit(false);
            end;

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEditTrackingNo(var TempTrackingSpecification: Record "Tracking Specification" temporary; var SearchForSupply: Boolean; CurrentSignFactor: Integer; LookupMode: Enum "Item Tracking Type"; MaxQuantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssistEditTrackingNo(var TrackingSpecification: Record "Tracking Specification"; var TempGlobalEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditTrackingNoOnBeforeRetrieveLookupData(var TrackingSpecification: Record "Tracking Specification"; var TempGlobalEntrySummary: Record "Entry Summary" temporary; var FullGlobalDataSetExists: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateEntrySummary(TrackingSpecification: Record "Tracking Specification"; var TempGlobalEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateEntrySummary2(var TempGlobalEntrySummary: Record "Entry Summary" temporary; var TempGlobalReservEntry: Record "Reservation Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRetrieveLookupData(var TrackingSpecification: Record "Tracking Specification"; FullDataSet: Boolean; var TempGlobalReservEntry: Record "Reservation Entry" temporary; var TempGlobalEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferExpDateFromSummary(var TrackingSpecification: Record "Tracking Specification"; var TempEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferReservEntryToTempRec(var GlobalReservEntry: Record "Reservation Entry"; ReservEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditTrackingNoOnBeforeSetSources(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempGlobalEntrySummary: Record "Entry Summary" temporary; var MaxQuantity: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateEntrySummary2(var TempGlobalEntrySummary: Record "Entry Summary" temporary; var TempReservationEntry: Record "Reservation Entry" temporary; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempTrackingSpecificationInsert(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempTrackingSpecificationModify(var TempTrackingSpecification: Record "Tracking Specification" temporary; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempGlobalChangedEntrySummaryInsert(var TempGlobalChangedEntrySummary: Record "Entry Summary" temporary; var TempTrackingSpecificationChanged: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTrackingAvailable(var TempTrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBinContent(var TempEntrySummary: Record "Entry Summary" temporary; var TempReservationEntry: Record "Reservation Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveLookupDataOnBeforeTransferToTempRec(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempReservationEntry: Record "Reservation Entry" temporary; ItemLedgerEntry: Record "Item Ledger Entry"; var FullDataSet: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectMultipleTrackingNoOnBeforeSetSources(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempGlobalEntrySummary: Record "Entry Summary" temporary; var MaxQuantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferItemLedgToTempRecOnBeforeInsert(var TempGlobalReservEntry: Record "Reservation Entry" temporary; ItemLedgerEntry: Record "Item Ledger Entry"; TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddSelectedTrackingToDataSetOnAfterInitTrackingSpecification2(var TrackingSpecification: Record "Tracking Specification"; TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;
}

