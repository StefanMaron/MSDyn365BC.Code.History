codeunit 7326 "Whse. Item Tracking FEFO"
{

    trigger OnRun()
    begin
    end;

    var
        TempGlobalEntrySummary: Record "Entry Summary" temporary;
        SourceReservationEntry: Record "Reservation Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        LastSummaryEntryNo: Integer;
        StrictExpirationPosting: Boolean;
        HasExpiredItems: Boolean;
        ExpiredItemsForPickMsg: Label '\\Some items were not included in the pick due to their expiration date.';
        CalledFromMovementWksh: Boolean;

    procedure CreateEntrySummaryFEFO(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; UseExpDates: Boolean)
    begin
        InitEntrySummaryFEFO();
        LastSummaryEntryNo := 0;
        StrictExpirationPosting := ItemTrackingMgt.StrictExpirationPosting(ItemNo);

        SummarizeInventoryFEFO(Location, ItemNo, VariantCode, UseExpDates);
        if UseExpDates then
            SummarizeAdjustmentBinFEFO(Location, ItemNo, VariantCode);

        OnAfterCreateEntrySummaryFEFO(TempGlobalEntrySummary);
    end;

    local procedure SummarizeInventoryFEFO(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; HasExpirationDate: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
        IsHandled: Boolean;
        NonReservedQtyLotSN: Decimal;
    begin
        IsHandled := false;
        OnBeforeSummarizeInventoryFEFO(Location, ItemNo, VariantCode, HasExpirationDate, IsHandled,
            TempGlobalEntrySummary, StrictExpirationPosting, LastSummaryEntryNo, HasExpiredItems);
        if IsHandled then
            exit;

        with ItemLedgEntry do begin
            Reset();
            SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Lot No.", "Serial No.");
            SetRange("Item No.", ItemNo);
            SetRange(Open, true);
            SetRange("Variant Code", VariantCode);
            SetRange(Positive, true);
            if HasExpirationDate then
                SetFilter("Expiration Date", '<>%1', 0D)
            else
                SetRange("Expiration Date", 0D);
            SetRange("Location Code", Location.Code);
            OnSummarizeInventoryFEFOOnAfterItemLedgEntrySetFilters(ItemLedgEntry, ItemNo, HasExpirationDate);
            if IsEmpty() then
                exit;

            FindSet();
            repeat
                NonReservedQtyLotSN := 0;
                SetTrackingFilterFromItemLedgEntry(ItemLedgEntry);
                ItemTrackingSetup.CopyTrackingFromItemLedgerEntry(ItemLedgEntry);
                FindSet();
                if not IsItemTrackingBlocked("Item No.", "Variant Code", ItemTrackingSetup) then begin
                    repeat
                        NonReservedQtyLotSN += "Remaining Quantity";
                        if not CalledFromMovementWksh then
                            NonReservedQtyLotSN -= CalcReservedFromILEWithItemTracking(ItemLedgEntry);
                    until Next() = 0;

                    if NonReservedQtyLotSN - CalcNonRegisteredQtyOutstanding(
                        "Item No.", "Variant Code", "Location Code", ItemTrackingSetup, HasExpirationDate) > 0
                    then begin
                        OnSummarizeInventoryFEFOOnBeforeInsertEntrySummaryFEFO(TempGlobalEntrySummary, ItemLedgEntry);
                        InsertEntrySummaryFEFO(ItemTrackingSetup, "Expiration Date");
                    end;
                end else
                    FindLast();

                ClearTrackingFilter();
            until Next() = 0;
        end;
    end;

    local procedure CalcReservedFromILEWithItemTracking(ItemLedgerEntry: Record "Item Ledger Entry") ReservedQty: Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        OppositeReservationEntry: Record "Reservation Entry";
        ItemLedgerEntryReserve: Codeunit "Item Ledger Entry-Reserve";
    begin
        ReservedQty := 0;

        ItemLedgerEntryReserve.FilterReservFor(ReservationEntry, ItemLedgerEntry);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        if ReservationEntry.FindSet() then
            repeat
                OppositeReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
                if (OppositeReservationEntry."Entry No." <> SourceReservationEntry."Entry No.") and
                   (OppositeReservationEntry."Item Tracking" <> OppositeReservationEntry."Item Tracking"::None)
                then
                    ReservedQty += ReservationEntry."Quantity (Base)";
            until ReservationEntry.Next() = 0;
    end;

    local procedure CalcNonRegisteredQtyOutstanding(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; HasExpirationDate: Boolean): Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        with WarehouseActivityLine do begin
            if CalledFromMovementWksh then
                SetRange("Activity Type", "Activity Type"::Movement)
            else
                SetRange("Activity Type", "Activity Type"::Pick);
            SetRange("Action Type", "Action Type"::Take);
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetRange("Location Code", LocationCode);
            SetTrackingFilterFromItemTrackingSetup(WhseItemTrackingSetup);
            if HasExpirationDate then
                SetFilter("Expiration Date", '<>%1', 0D)
            else
                SetRange("Expiration Date", 0D);
            CalcSums("Qty. Outstanding (Base)");
            exit("Qty. Outstanding (Base)");
        end;
    end;

    local procedure SummarizeAdjustmentBinFEFO(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10])
    var
        WhseEntry: Record "Warehouse Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
        ExpirationDate: Date;
        EntriesExist: Boolean;
    begin
        if Location."Adjustment Bin Code" = '' then
            exit;

        WhseEntry.Reset();
        WhseEntry.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.");
        WhseEntry.SetRange("Item No.", ItemNo);
        WhseEntry.SetRange("Bin Code", Location."Adjustment Bin Code");
        WhseEntry.SetRange("Location Code", Location.Code);
        WhseEntry.SetRange("Variant Code", VariantCode);
        if WhseEntry.IsEmpty() then
            exit;

        if WhseEntry.FindSet() then
            repeat
                ItemTrackingSetup.CopyTrackingFromWhseEntry(WhseEntry);
                if not EntrySummaryFEFOExists(ItemTrackingSetup) then
                    if CalcAvailQtyOnWarehouse(WhseEntry) <> 0 then
                        if not IsItemTrackingBlocked(WhseEntry."Item No.", WhseEntry."Variant Code", ItemTrackingSetup) then begin
                            ExpirationDate :=
                                ItemTrackingMgt.WhseExistingExpirationDate(
                                    WhseEntry."Item No.", WhseEntry."Variant Code", Location, ItemTrackingSetup, EntriesExist);

                            if not EntriesExist then
                                ExpirationDate := 0D;

                            OnSummarizeAdjustmentBinFEFOOnBeforeInsertEntrySummaryFEFO(TempGlobalEntrySummary, WhseEntry, ItemTrackingSetup, Location);
                            InsertEntrySummaryFEFO(ItemTrackingSetup, ExpirationDate);
                        end;
            until WhseEntry.Next() = 0;
    end;

    local procedure InitEntrySummaryFEFO()
    begin
        TempGlobalEntrySummary.DeleteAll();
        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetTrackingKey();
    end;

    procedure InsertEntrySummaryFEFO(ItemTrackingSetup: Record "Item Tracking Setup"; ExpirationDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertEntrySummaryFEFOProcedure(ItemTrackingSetup, TempGlobalEntrySummary, LastSummaryEntryNo, StrictExpirationPosting, ExpirationDate, HasExpiredItems, IsHandled);
        if IsHandled then
            exit;

        if (not StrictExpirationPosting) or (ExpirationDate >= WorkDate()) then begin
            TempGlobalEntrySummary.Init();
            TempGlobalEntrySummary."Entry No." := LastSummaryEntryNo + 1;
            TempGlobalEntrySummary.CopyTrackingFromItemTrackingSetup(ItemTrackingSetup);
            TempGlobalEntrySummary."Expiration Date" := ExpirationDate;
            OnBeforeInsertEntrySummaryFEFO(TempGlobalEntrySummary);
            TempGlobalEntrySummary.Insert();
            LastSummaryEntryNo := TempGlobalEntrySummary."Entry No.";
        end else
            HasExpiredItems := true;
    end;

    procedure EntrySummaryFEFOExists(ItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    begin
        TempGlobalEntrySummary.SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup);
        OnEntrySummaryFEFOExistsOnAfterSetFilters(TempGlobalEntrySummary);
        exit(TempGlobalEntrySummary.FindSet());
    end;

    procedure FindFirstEntrySummaryFEFO(var EntrySummary: Record "Entry Summary"): Boolean
    var
        IsFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        IsFound := false;
        OnBeforeFindFirstEntrySummaryFEFO(TempGlobalEntrySummary, IsFound, IsHandled);
        if IsHandled then begin
            if IsFound then
                EntrySummary := TempGlobalEntrySummary;
            exit(IsFound);
        end;

        with TempGlobalEntrySummary do begin
            Reset();
            SetCurrentKey("Expiration Date");

            if not Find('-') then
                exit(false);

            EntrySummary := TempGlobalEntrySummary;
            exit(true);
        end;
    end;

    procedure FindNextEntrySummaryFEFO(var EntrySummary: Record "Entry Summary"): Boolean
    begin
        with TempGlobalEntrySummary do begin
            if Next() = 0 then
                exit(false);

            EntrySummary := TempGlobalEntrySummary;
            exit(true);
        end;
    end;

    procedure GetHasExpiredItems(): Boolean
    begin
        exit(HasExpiredItems);
    end;

    procedure GetResultMessageForExpiredItem(): Text[100]
    begin
        if HasExpiredItems then
            exit(ExpiredItemsForPickMsg);

        exit('');
    end;

    procedure SetSource(SourceType2: Integer; SourceSubType2: Integer; SourceNo2: Code[20]; SourceLineNo2: Integer; SourceSubLineNo2: Integer)
    var
        CreatePick: Codeunit "Create Pick";
    begin
        OnBeforeSetSource(SourceType2, SourceSubType2, SourceNo2, SourceLineNo2, SourceSubLineNo2);

        SourceReservationEntry.Reset();
        CreatePick.SetFiltersOnReservEntry(
          SourceReservationEntry, SourceType2, SourceSubType2, SourceNo2, SourceLineNo2, SourceSubLineNo2);
    end;

    procedure SetCalledFromMovementWksh(NewCalledFromMovementWksh: Boolean)
    begin
        CalledFromMovementWksh := NewCalledFromMovementWksh;
    end;

    local procedure CalcAvailQtyOnWarehouse(var WhseEntry: Record "Warehouse Entry"): Decimal
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.CopyFilters(WhseEntry);
        WarehouseEntry.SetTrackingFilterFromWhseEntry(WhseEntry);
        WarehouseEntry.CalcSums(Quantity);
        exit(WarehouseEntry.Quantity);
    end;

    local procedure IsItemTrackingBlocked(ItemNo: Code[20]; VariantCode: Code[10]; ItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        LotNoInformation: Record "Lot No. Information";
        SerialNoInformation: Record "Serial No. Information";
        IsBlocked: Boolean;
    begin
        if ItemTrackingSetup."Lot No." <> '' then
            if LotNoInformation.Get(ItemNo, VariantCode, ItemTrackingSetup."Lot No.") then
                if LotNoInformation.Blocked then
                    exit(true);
        if ItemTrackingSetup."Serial No." <> '' then
            if SerialNoInformation.Get(ItemNo, VariantCode, ItemTrackingSetup."Serial No.") then
                if SerialNoInformation.Blocked then
                    exit(true);

        IsBlocked := false;
        OnAfterIsItemTrackingBlocked(SourceReservationEntry, ItemNo, VariantCode, ItemTrackingSetup."Lot No.", IsBlocked, ItemTrackingSetup);

        exit(IsBlocked);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateEntrySummaryFEFO(var TempEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsItemTrackingBlocked(var ReservEntry: Record "Reservation Entry"; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; var IsBlocked: Boolean; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindFirstEntrySummaryFEFO(var TempGlobalEntrySummary: Record "Entry Summary" temporary; var IsFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertEntrySummaryFEFO(var TempGlobalEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertEntrySummaryFEFOProcedure(ItemTrackingSetup: Record "Item Tracking Setup"; var TempGlobalEntrySummary: Record "Entry Summary" temporary; var LastSummaryEntryNo: Integer; StrictExpirationPosting: Boolean; ExpirationDate: Date; var HasExpiredItems: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSource(SourceType2: Integer; SourceSubType2: Integer; SourceNo2: Code[20]; SourceLineNo2: Integer; SourceSubLineNo2: Integer)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeSummarizeInventoryFEFO(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; HasExpirationDate: Boolean; var IsHandled: Boolean; var TempGlobalEntrySummary: Record "Entry Summary"; var StrictExpirationPosting: Boolean; var LastSummaryEntryNo: Integer; var HasExpiredItems: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEntrySummaryFEFOExistsOnAfterSetFilters(var TempGlobalEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSummarizeAdjustmentBinFEFOOnBeforeInsertEntrySummaryFEFO(var TempGlobalEntrySummary: Record "Entry Summary" temporary; WarehouseEntry: Record "Warehouse Entry"; var ItemTrackingSetup: Record "Item Tracking Setup"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSummarizeInventoryFEFOOnBeforeInsertEntrySummaryFEFO(var TempGlobalEntrySummary: Record "Entry Summary" temporary; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSummarizeInventoryFEFOOnAfterItemLedgEntrySetFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; HasExpirationDate: Boolean)
    begin
    end;
}

