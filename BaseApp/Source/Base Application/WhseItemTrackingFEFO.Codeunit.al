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
        SourceSet: Boolean;
        ExpiredItemsForPickMsg: Label '\\Some items were not included in the pick due to their expiration date.';
        CalledFromMovementWksh: Boolean;

    procedure CreateEntrySummaryFEFO(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; UseExpDates: Boolean)
    begin
        InitEntrySummaryFEFO;
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
        IsHandled: Boolean;
        NonReservedQtyLotSN: Decimal;
    begin
        IsHandled := false;
        OnBeforeSummarizeInventoryFEFO(Location, ItemNo, VariantCode, HasExpirationDate, IsHandled);
        if IsHandled then
            exit;

        with ItemLedgEntry do begin
            Reset;
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
            if IsEmpty then
                exit;

            FindSet;
            repeat
                NonReservedQtyLotSN := 0;
                SetRange("Lot No.", "Lot No.");
                SetRange("Serial No.", "Serial No.");
                FindSet;
                if not IsItemTrackingBlocked("Item No.", "Variant Code", "Lot No.", "Serial No.") then
                    repeat
                        CalcFields("Reserved Quantity");
                        NonReservedQtyLotSN += "Remaining Quantity" - ("Reserved Quantity" - CalcReservedToSource("Entry No."));
                    until Next = 0;

                if NonReservedQtyLotSN - CalcNonRegisteredQtyOutstanding(
                     "Item No.", "Variant Code", "Location Code", "Lot No.", "Serial No.", HasExpirationDate) > 0
                then begin
                    OnSummarizeInventoryFEFOOnBeforeInsertEntrySummaryFEFO(TempGlobalEntrySummary, ItemLedgEntry);
                    InsertEntrySummaryFEFO("Lot No.", "Serial No.", "Expiration Date");
                end;

                SetRange("Lot No.");
                SetRange("Serial No.");
            until Next = 0;
        end;
    end;

    local procedure CalcNonRegisteredQtyOutstanding(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; HasExpirationDate: Boolean): Decimal
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
            SetRange("Lot No.", LotNo);
            SetRange("Serial No.", SerialNo);
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
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ExpirationDate: Date;
        EntriesExist: Boolean;
    begin
        if Location."Adjustment Bin Code" = '' then
            exit;

        with WhseEntry do begin
            Reset;
            SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.");
            SetRange("Item No.", ItemNo);
            SetRange("Bin Code", Location."Adjustment Bin Code");
            SetRange("Location Code", Location.Code);
            SetRange("Variant Code", VariantCode);
            if IsEmpty then
                exit;

            if FindSet then
                repeat
                    if not EntrySummaryFEFOExists("Lot No.", "Serial No.") then
                        if CalcAvailQtyOnWarehouse(WhseEntry) <> 0 then
                            if not IsItemTrackingBlocked("Item No.", "Variant Code", "Lot No.", "Serial No.") then begin
                                ExpirationDate :=
                                  ItemTrackingMgt.WhseExistingExpirationDate(
                                    "Item No.", "Variant Code", Location, "Lot No.", "Serial No.", EntriesExist);

                                if not EntriesExist then
                                    ExpirationDate := 0D;

                                OnSummarizeAdjustmentBinFEFOOnBeforeInsertEntrySummaryFEFO(TempGlobalEntrySummary, WhseEntry);
                                InsertEntrySummaryFEFO("Lot No.", "Serial No.", ExpirationDate);
                            end;
                until Next = 0;
        end;
    end;

    local procedure InitEntrySummaryFEFO()
    begin
        with TempGlobalEntrySummary do begin
            DeleteAll();
            Reset;
            SetCurrentKey("Lot No.", "Serial No.");
        end;
    end;

    procedure InsertEntrySummaryFEFO(LotNo: Code[50]; SerialNo: Code[50]; ExpirationDate: Date)
    begin
        with TempGlobalEntrySummary do
            if (not StrictExpirationPosting) or (ExpirationDate >= WorkDate) then begin
                Init;
                "Entry No." := LastSummaryEntryNo + 1;
                "Serial No." := SerialNo;
                "Lot No." := LotNo;
                "Expiration Date" := ExpirationDate;
                OnBeforeInsertEntrySummaryFEFO(TempGlobalEntrySummary);
                Insert;
                LastSummaryEntryNo := "Entry No.";
            end else
                HasExpiredItems := true;
    end;

    procedure EntrySummaryFEFOExists(LotNo: Code[50]; SerialNo: Code[50]): Boolean
    begin
        with TempGlobalEntrySummary do begin
            SetTrackingFilter(SerialNo, LotNo);
            OnEntrySummaryFEFOExistsOnAfterSetFilters(TempGlobalEntrySummary);
            exit(FindSet);
        end;
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
            Reset;
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
            if Next = 0 then
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
        SourceSet := true;
    end;

    procedure SetCalledFromMovementWksh(NewCalledFromMovementWksh: Boolean)
    begin
        CalledFromMovementWksh := NewCalledFromMovementWksh;
    end;

    local procedure CalcReservedToSource(ILENo: Integer) Result: Decimal
    begin
        Result := 0;
        if not SourceSet then
            exit(Result);

        with SourceReservationEntry do begin
            if FindSet then
                repeat
                    if ReservedFromILE(SourceReservationEntry, ILENo) then
                        Result -= "Quantity (Base)"; // "Quantity (Base)" is negative
                until Next = 0;
        end;

        exit(Result);
    end;

    local procedure ReservedFromILE(ReservationEntry: Record "Reservation Entry"; ILENo: Integer): Boolean
    begin
        with ReservationEntry do begin
            Positive := not Positive;
            Find;
            exit(
              ("Source ID" = '') and ("Source Ref. No." = ILENo) and
              ("Source Type" = DATABASE::"Item Ledger Entry") and ("Source Subtype" = 0) and
              ("Source Batch Name" = '') and ("Source Prod. Order Line" = 0) and
              ("Reservation Status" = "Reservation Status"::Reservation));
        end;
    end;

    local procedure CalcAvailQtyOnWarehouse(var WhseEntry: Record "Warehouse Entry"): Decimal
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        with WarehouseEntry do begin
            CopyFilters(WhseEntry);
            SetRange("Lot No.", WhseEntry."Lot No.");
            SetRange("Serial No.", WhseEntry."Serial No.");
            CalcSums(Quantity);
            exit(Quantity);
        end;
    end;

    local procedure IsItemTrackingBlocked(ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]): Boolean
    var
        LotNoInformation: Record "Lot No. Information";
        SerialNoInformation: Record "Serial No. Information";
        IsBlocked: Boolean;
    begin
        if LotNoInformation.Get(ItemNo, VariantCode, LotNo) then
            if LotNoInformation.Blocked then
                exit(true);
        if SerialNoInformation.Get(ItemNo, VariantCode, SerialNo) then
            if SerialNoInformation.Blocked then
                exit(true);

        IsBlocked := false;
        OnAfterIsItemTrackingBlocked(SourceReservationEntry, ItemNo, VariantCode, LotNo, IsBlocked);

        exit(IsBlocked);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateEntrySummaryFEFO(var TempEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsItemTrackingBlocked(var ReservEntry: Record "Reservation Entry"; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; var IsBlocked: Boolean)
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
    local procedure OnBeforeSetSource(SourceType2: Integer; SourceSubType2: Integer; SourceNo2: Code[20]; SourceLineNo2: Integer; SourceSubLineNo2: Integer)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeSummarizeInventoryFEFO(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; HasExpirationDate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEntrySummaryFEFOExistsOnAfterSetFilters(var TempGlobalEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSummarizeAdjustmentBinFEFOOnBeforeInsertEntrySummaryFEFO(var TempGlobalEntrySummary: Record "Entry Summary" temporary; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSummarizeInventoryFEFOOnBeforeInsertEntrySummaryFEFO(var TempGlobalEntrySummary: Record "Entry Summary" temporary; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;
}

