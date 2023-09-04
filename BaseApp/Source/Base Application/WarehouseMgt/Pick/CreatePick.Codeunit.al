codeunit 7312 "Create Pick"
{
    Permissions = TableData "Whse. Item Tracking Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        CreatePickParameters: Record "Create Pick Parameters";
        WhseActivHeader: Record "Warehouse Activity Header";
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        TempTotalWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        SourceWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        ProdOrderCompLine: Record "Prod. Order Component";
        AssemblyLine: Record "Assembly Line";
        JobPlanningLine: Record "Job Planning Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseSetup: Record "Warehouse Setup";
        Location: Record Location;
        WhseSetupLocation: Record Location;
        Item: Record Item;
        Bin: Record Bin;
        BinType: Record "Bin Type";
        SKU: Record "Stockkeeping Unit";
        WhseMgt: Codeunit "Whse. Management";
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        SourceSubType: Option;
        SourceNo: Code[20];
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
        ShipmentMethodCode: Code[10];
        TransferRemQtyToPickBase: Decimal;
        TempNo: Integer;
        BreakbulkNo: Integer;
        TempLineNo: Integer;
        SourceType: Integer;
        SourceLineNo: Integer;
        SourceSubLineNo: Integer;
        IsMovementWorksheet: Boolean;
        LastWhseItemTrkgLineNo: Integer;
        WhseItemTrkgLineCount: Integer;
        Text000: Label 'Nothing to handle. %1.';
        WhseItemTrkgExists: Boolean;
        CrossDock: Boolean;
        ReservationExists: Boolean;
        ReservedForItemLedgEntry: Boolean;
        CalledFromPickWksh: Boolean;
        CalledFromMoveWksh: Boolean;
        CalledFromWksh: Boolean;
        ReqFEFOPick: Boolean;
        HasExpiredItems: Boolean;
        CannotBeHandledReasons: array[20] of Text;
        TotalQtyPickedBase: Decimal;
        BinIsNotForPickTxt: Label 'The quantity to be picked is in bin %1, which is not set up for picking', Comment = '%1: Field("Bin Code")';
        BinIsForReceiveOrShipTxt: Label 'The quantity to be picked is in bin %1, which is set up for receiving or shipping', Comment = '%1: Field("Bin Code")';
        QtyReservedNotFromInventoryTxt: Label 'The quantity to be picked is not in inventory yet. You must first post the supply from which the source document is reserved';
        ValidValuesIfSNDefinedErr: Label 'Field %1 can only have values -1, 0 or 1 when serial no. is defined. Current value is %2.', Comment = '%1 = field name, %2 = field value';

    procedure CreateTempLine(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var TotalQtytoPick: Decimal; var TotalQtytoPickBase: Decimal)
    begin
        CreateTempLine(LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, ToBinCode, QtyPerUnitofMeasure, 0, 0, TotalQtytoPick, TotalQtytoPickBase);
    end;

    procedure CreateTempLine(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; QtyRoundingPrecision: Decimal; QtyRoundingPrecisionBase: Decimal; var TotalQtytoPick: Decimal; var TotalQtytoPickBase: Decimal)
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        QtyToPick: Decimal;
        RemQtyToPick: Decimal;
        i: Integer;
        RemQtyToPickBase: Decimal;
        QtyToPickBase: Decimal;
        QtyToTrackBase: Decimal;
        QtyBaseMaxAvailToPick: Decimal;
        TotalItemTrackedQtyToPick: Decimal;
        TotalItemTrackedQtyToPickBase: Decimal;
        NewQtyToHandle: Decimal;
        IsHandled: Boolean;
    begin
        TotalQtyPickedBase := 0;
        GetLocation(LocationCode);

        IsHandled := false;
        OnCreateTempLineOnBeforeCheckReservation(SourceType, SourceNo, SourceLineNo, QtyBaseMaxAvailToPick, IsHandled, LocationCode, ItemNo);
        if not IsHandled then begin
            if Location."Directed Put-away and Pick" then
                QtyBaseMaxAvailToPick := // Total qty (excl. Receive bin content) that are not assigned to any activity/ order
                    CalcTotalQtyOnBinType('', LocationCode, ItemNo, VariantCode) -
                    CalcTotalQtyAssgndOnWhse(LocationCode, ItemNo, VariantCode) +
                    CalcTotalQtyAssgndOnWhseAct(TempWhseActivLine."Activity Type"::"Put-away", LocationCode, ItemNo, VariantCode) -
                    CalcTotalQtyOnBinType(GetBinTypeFilter(0), LocationCode, ItemNo, VariantCode) // Receive area
            else
                QtyBaseMaxAvailToPick :=
                    CalcAvailableQty(ItemNo, VariantCode) -
                    CalcPickQtyAssigned(LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, TempWhseItemTrackingLine);

            OnCreateTempLineOnAfterCalcQtyBaseMaxAvailToPick(QtyBaseMaxAvailToPick, LocationCode, ItemNo, VariantCode);
            CheckReservation(
            QtyBaseMaxAvailToPick, SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, Location."Always Create Pick Line",
            QtyPerUnitofMeasure, TotalQtytoPick, TotalQtytoPickBase);
        end;

        OnAfterCreateTempLineCheckReservation(
            LocationCode, ItemNo, VariantCode, UnitofMeasureCode, QtyPerUnitofMeasure, TotalQtytoPick, TotalQtytoPickBase,
            SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, LastWhseItemTrkgLineNo, TempWhseItemTrackingLine, WhseShptLine);

        RemQtyToPick := TotalQtytoPick;
        RemQtyToPickBase := TotalQtytoPickBase;
        ItemTrackingMgt.GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);

        ReqFEFOPick := false;
        HasExpiredItems := false;
        if PickAccordingToFEFO(LocationCode, WhseItemTrackingSetup) or PickStrictExpirationPosting(ItemNo, WhseItemTrackingSetup) then begin
            QtyToTrackBase := RemQtyToPickBase;
            if UndefinedItemTrkg(QtyToTrackBase) then begin
                CreateTempItemTrkgLines(ItemNo, VariantCode, QtyToTrackBase, true);
                CreateTempItemTrkgLines(ItemNo, VariantCode, TransferRemQtyToPickBase, false);
            end;
        end;

        if TotalQtytoPickBase <> 0 then begin
            TempWhseItemTrackingLine.Reset();
            TempWhseItemTrackingLine.SetFilter("Qty. to Handle", '<> 0');
            if TempWhseItemTrackingLine.Find('-') then begin
                repeat
                    if TempWhseItemTrackingLine."Qty. to Handle (Base)" <> 0 then begin
                        if TempWhseItemTrackingLine."Qty. to Handle (Base)" > RemQtyToPickBase then begin
                            TempWhseItemTrackingLine."Qty. to Handle (Base)" := RemQtyToPickBase;
                            OnBeforeTempWhseItemTrackingLineModifyOnAfterAssignRemQtyToPickBase(TempWhseItemTrackingLine);
                            TempWhseItemTrackingLine.Modify();
                        end;
                        NewQtyToHandle :=
                          Round(RemQtyToPick / RemQtyToPickBase * TempWhseItemTrackingLine."Qty. to Handle (Base)", UOMMgt.QtyRndPrecision()); // TODO
                        if TempWhseItemTrackingLine."Qty. to Handle" <> NewQtyToHandle then begin
                            TempWhseItemTrackingLine."Qty. to Handle" := NewQtyToHandle;
                            OnBeforeTempWhseItemTrackingLineModify(TempWhseItemTrackingLine);
                            TempWhseItemTrackingLine.Modify();
                        end;

                        QtyToPick := TempWhseItemTrackingLine."Qty. to Handle";
                        QtyToPickBase := TempWhseItemTrackingLine."Qty. to Handle (Base)";
                        TotalItemTrackedQtyToPick += QtyToPick;
                        TotalItemTrackedQtyToPickBase += QtyToPickBase;

                        CreateTempLine(
                            LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, ToBinCode,
                            QtyPerUnitofMeasure, QtyRoundingPrecision, QtyRoundingPrecisionBase, QtyToPick, TempWhseItemTrackingLine, QtyToPickBase, WhseItemTrackingSetup);
                        RemQtyToPickBase -= TempWhseItemTrackingLine."Qty. to Handle (Base)" - QtyToPickBase;
                        RemQtyToPick -= TempWhseItemTrackingLine."Qty. to Handle" - QtyToPick;
                    end;
                until (TempWhseItemTrackingLine.Next() = 0) or (RemQtyToPickBase <= 0);
                RemQtyToPick := Minimum(RemQtyToPick, TotalQtytoPick - TotalItemTrackedQtyToPick);
                RemQtyToPickBase := Minimum(RemQtyToPickBase, TotalQtytoPickBase - TotalItemTrackedQtyToPickBase);
                TotalQtytoPick := RemQtyToPick;
                TotalQtytoPickBase := RemQtyToPickBase;

                SaveTempItemTrkgLines();
                Clear(TempWhseItemTrackingLine);
                WhseItemTrkgExists := false;
            end;

            IsHandled := false;
            OnCreateTempLineOnAfterCreateTempLineWithItemTracking(TotalQtytoPickBase, HasExpiredItems, LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, ToBinCode, QtyPerUnitofMeasure, TempWhseActivLine, TempLineNo, IsHandled);
            if not IsHandled then
                if TotalQtytoPickBase <> 0 then
                    if not HasExpiredItems then begin
                        if WhseItemTrackingSetup."Serial No. Required" then begin
                            IsHandled := false;
                            OnCreateTempLineOnBeforeCreateTempLineForSerialNo(
                                LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, ToBinCode, QtyPerUnitofMeasure,
                                TotalQtytoPick, TotalQtytoPickBase, TempWhseItemTrackingLine, WhseItemTrackingSetup, IsHandled);
                            if IsHandled then
                                exit;

                            for i := 1 to TotalQtytoPickBase do begin
                                QtyToPickBase := 1;
                                QtyToPick := UOMMgt.RoundQty(QtyToPickBase / QtyPerUnitofMeasure, QtyRoundingPrecision);
                                CreateTempLine(
                                    LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, ToBinCode, QtyPerUnitofMeasure,
                                    QtyRoundingPrecision, QtyRoundingPrecisionBase, QtyToPick, TempWhseItemTrackingLine, QtyToPickBase, WhseItemTrackingSetup);
                            end;
                            TotalQtytoPick := 0;
                            TotalQtytoPickBase := 0;
                        end else
                            CreateTempLine(
                                LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, ToBinCode, QtyPerUnitofMeasure,
                                QtyRoundingPrecision, QtyRoundingPrecisionBase, TotalQtytoPick, TempWhseItemTrackingLine, TotalQtytoPickBase, WhseItemTrackingSetup);
                    end;
        end;

        OnAfterCreateTempLine(LocationCode, ToBinCode, ItemNo, VariantCode, UnitofMeasureCode, QtyPerUnitofMeasure);
    end;

    local procedure CreateTempLine(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal;
        QtyRoundingPrecision: Decimal; QtyRoundingPrecisionBase: Decimal; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var TotalQtytoPickBase: Decimal;
        WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        QtytoPick: Decimal;
        QtytoPickBase: Decimal;
        QtyAvailableBase: Decimal;
        IsHandled: Boolean;
        FirstBinCode: Code[20];
    begin
        GetLocation(LocationCode);
        if Location."Bin Mandatory" then begin
            if not Location."Directed Put-away and Pick" then begin
                QtyAvailableBase :=
                    CalcAvailableQty(ItemNo, VariantCode) -
                    CalcPickQtyAssigned(LocationCode, ItemNo, VariantCode, UnitofMeasureCode, '', TempWhseItemTrackingLine);

                if QtyAvailableBase > 0 then begin
                    if TotalQtytoPickBase > QtyAvailableBase then
                        TotalQtytoPickBase := QtyAvailableBase;
                    CalcBWPickBin(
                        LocationCode, ItemNo, VariantCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtyRoundingPrecision, QtyRoundingPrecisionBase,
                        TotalQtytoPick, TotalQtytoPickBase, TempWhseItemTrackingLine, WhseItemTrackingSetup);
                end;
                exit;
            end;

            IsHandled := false;
            OnCreateTempLine2OnBeforeDirectedPutAwayAndPick(
                LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, ToBinCode, QtyPerUnitofMeasure,
                TotalQtytoPick, TotalQtytoPickBase, TempWhseItemTrackingLine, CreatePickParameters."Whse. Document", IsHandled,
                ReservationExists, ReservedForItemLedgEntry, TempWhseActivLine, TempLineNo);
            if IsHandled then
                exit;

            if IsMovementWorksheet and (FromBinCode <> '') then begin
                InsertTempActivityLineFromMovWkshLine(
                    LocationCode, ItemNo, VariantCode, FromBinCode, QtyPerUnitofMeasure,
                    TotalQtytoPick, TempWhseItemTrackingLine, TotalQtytoPickBase,
                    QtyRoundingPrecision, QtyRoundingPrecisionBase);
                exit;
            end;

            if (ReservationExists and ReservedForItemLedgEntry) or not ReservationExists then begin
                if Location."Use Cross-Docking" then
                    CalcPickBin(
                        LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode, QtyPerUnitofMeasure,
                        QtyRoundingPrecision, QtyRoundingPrecisionBase, TotalQtytoPick, TempWhseItemTrackingLine, true,
                        TotalQtytoPickBase, QtyRoundingPrecision, QtyRoundingPrecisionBase);
                if TotalQtytoPickBase > 0 then
                    CalcPickBin(
                        LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode, QtyPerUnitofMeasure,
                        QtyRoundingPrecision, QtyRoundingPrecisionBase, TotalQtytoPick, TempWhseItemTrackingLine, false,
                        TotalQtytoPickBase, QtyRoundingPrecision, QtyRoundingPrecisionBase);
            end;
            if (TotalQtytoPickBase > 0) and Location."Always Create Pick Line" then begin
                UpdateQuantitiesToPick(
                    TotalQtytoPickBase,
                    QtyPerUnitofMeasure, QtytoPick, QtytoPickBase,
                    QtyPerUnitofMeasure, QtytoPick, QtytoPickBase,
                    TotalQtytoPick, TotalQtytoPickBase);

                FirstBinCode := '';
                OnBeforeCreateTempActivityLineWithoutBinCode(FirstBinCode);
                CreateTempActivityLine(
                    LocationCode, FirstBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtytoPickBase, 1, 0, QtyRoundingPrecision, QtyRoundingPrecisionBase);
                CreateTempActivityLine(
                    LocationCode, ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtytoPickBase, 2, 0, QtyRoundingPrecision, QtyRoundingPrecisionBase);
            end;
            exit;
        end;

        QtyAvailableBase :=
            CalcAvailableQty(ItemNo, VariantCode) -
            CalcPickQtyAssigned(LocationCode, ItemNo, VariantCode, UnitofMeasureCode, '', TempWhseItemTrackingLine);
        OnCreateTempLineOnBeforeUpdateQuantitesToPick(QtyAvailableBase, QtyPerUnitofMeasure, QtytoPick, QtytoPickBase, TotalQtytoPick, TotalQtytoPickBase);
        if QtyAvailableBase > 0 then begin
            UpdateQuantitiesToPick(
                QtyAvailableBase,
                QtyPerUnitofMeasure, QtytoPick, QtytoPickBase,
                QtyPerUnitofMeasure, QtytoPick, QtytoPickBase,
                TotalQtytoPick, TotalQtytoPickBase);

            CreateTempActivityLine(LocationCode, '', UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtytoPickBase, 0, 0, QtyRoundingPrecision, QtyRoundingPrecisionBase);
        end;
    end;

    local procedure InsertTempActivityLineFromMovWkshLine(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; FromBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var TotalQtyToPickBase: Decimal; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal)
    var
        FromBinContent: Record "Bin Content";
        FromItemUOM: Record "Item Unit of Measure";
        FromQtyToPick: Decimal;
        FromQtyToPickBase: Decimal;
        ToQtyToPick: Decimal;
        ToQtyToPickBase: Decimal;
        QtyAvailableBase: Decimal;
    begin
        QtyAvailableBase := TotalQtyToPickBase;

        if WhseWkshLine."From Unit of Measure Code" <> WhseWkshLine."Unit of Measure Code" then begin
            FromBinContent.Get(
              LocationCode, FromBinCode, ItemNo, VariantCode, WhseWkshLine."From Unit of Measure Code");
            FromBinContent.SetFilterOnUnitOfMeasure();
            FromBinContent.CalcFields("Quantity (Base)", "Pick Quantity (Base)", "Negative Adjmt. Qty. (Base)");

            QtyAvailableBase :=
              FromBinContent."Quantity (Base)" - FromBinContent."Pick Quantity (Base)" -
              FromBinContent."Negative Adjmt. Qty. (Base)" -
              CalcPickQtyAssigned(
                LocationCode, ItemNo, VariantCode,
                WhseWkshLine."From Unit of Measure Code",
                WhseWkshLine."From Bin Code", TempWhseItemTrackingLine);

            FromItemUOM.Get(ItemNo, FromBinContent."Unit of Measure Code");

            BreakbulkNo := BreakbulkNo + 1;
        end;

        UpdateQuantitiesToPick(
          QtyAvailableBase,
          WhseWkshLine."Qty. per From Unit of Measure", FromQtyToPick, FromQtyToPickBase,
          QtyPerUnitofMeasure, ToQtyToPick, ToQtyToPickBase,
          TotalQtytoPick, TotalQtyToPickBase);
        CreateBreakBulkTempLines(
          WhseWkshLine."Location Code",
          WhseWkshLine."From Unit of Measure Code",
          WhseWkshLine."Unit of Measure Code",
          FromBinCode,
          WhseWkshLine."To Bin Code",
          WhseWkshLine."Qty. per From Unit of Measure",
          WhseWkshLine."Qty. per Unit of Measure",
          BreakbulkNo,
          ToQtyToPick, ToQtyToPickBase, FromQtyToPick, FromQtyToPickBase, QtyRndPrec, QtyRndPrecBase);

        TotalQtyToPickBase := 0;
        TotalQtytoPick := 0;
    end;

    local procedure CalcMaxQty(var QtytoHandle: Decimal; QtyOutstanding: Decimal; var QtytoHandleBase: Decimal; QtyOutstandingBase: Decimal; ActionType: Enum "Warehouse Action Type")
    var
        WhseActivLine2: Record "Warehouse Activity Line";
    begin
        WhseActivLine2.Copy(TempWhseActivLine);
        with TempWhseActivLine do begin
            SetCurrentKey(
              "Whse. Document No.", "Whse. Document Type", "Activity Type", "Whse. Document Line No.");
            SetRange("Whse. Document Type", "Whse. Document Type");
            SetRange("Whse. Document No.", "Whse. Document No.");
            SetRange("Activity Type", "Activity Type");
            SetRange("Whse. Document Line No.", "Whse. Document Line No.");
            SetRange("Source Type", "Source Type");
            SetRange("Source Subtype", "Source Subtype");
            SetRange("Source No.", "Source No.");
            SetRange("Source Line No.", "Source Line No.");
            SetRange("Source Subline No.", "Source Subline No.");
            SetRange("Action Type", ActionType);
            SetRange("Breakbulk No.", 0);
            OnCalcMaxQtyOnAfterTempWhseActivLineSetFilters(TempWhseActivLine);
            if Find('-') then
                if ("Action Type" <> "Action Type"::Take) or (WhseActivLine2."Unit of Measure Code" = TempWhseActivLine."Unit of Measure Code") then begin
                    CalcSums(Quantity);
                    if QtyOutstanding < Quantity + QtytoHandle then
                        QtytoHandle := QtyOutstanding - Quantity;
                    if QtytoHandle < 0 then
                        QtytoHandle := 0;
                    CalcSums("Qty. (Base)");
                    if QtyOutstandingBase < "Qty. (Base)" + QtytoHandleBase then
                        QtytoHandleBase := QtyOutstandingBase - "Qty. (Base)";
                    if QtytoHandleBase < 0 then
                        QtytoHandleBase := 0;
                end;
        end;
        TempWhseActivLine.Copy(WhseActivLine2);
    end;

    local procedure CalcBWPickBin(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal; QtyRoundingPrecision: Decimal; QtyRoundingPrecisionBase: Decimal;
        var TotalQtyToPick: Decimal; var TotalQtytoPickBase: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        WhseSource2: Option;
        ToBinCode: Code[20];
        IsHandled: Boolean;
    begin
        // Basic warehousing
        IsHandled := false;
        OnBeforeCalcBWPickBin(TotalQtyToPick, TotalQtytoPickBase, TempWhseItemTrackingLine, TempWhseActivLine, WhseItemTrkgExists, IsHandled);
        if IsHandled then
            exit;

        if (CreatePickParameters."Whse. Document" = CreatePickParameters."Whse. Document"::Shipment) and WhseShptLine."Assemble to Order" then
            WhseSource2 := CreatePickParameters."Whse. Document"::Assembly
        else
            WhseSource2 := CreatePickParameters."Whse. Document";

        if TotalQtytoPickBase > 0 then
            case WhseSource2 of
                CreatePickParameters."Whse. Document"::"Pick Worksheet":
                    ToBinCode := WhseWkshLine."To Bin Code";
                CreatePickParameters."Whse. Document"::Shipment:
                    ToBinCode := WhseShptLine."Bin Code";
                CreatePickParameters."Whse. Document"::Production:
                    ToBinCode := ProdOrderCompLine."Bin Code";
                CreatePickParameters."Whse. Document"::Assembly:
                    ToBinCode := AssemblyLine."Bin Code";
                CreatePickParameters."Whse. Document"::Job:
                    ToBinCode := JobPlanningLine."Bin Code";
            end;

        RunFindBWPickBinLoop(
            LocationCode, ItemNo, VariantCode,
            ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtyRoundingPrecision, QtyRoundingPrecisionBase,
            TotalQtyToPick, TotalQtytoPickBase, TempWhseItemTrackingLine, WhseItemTrackingSetup);
    end;

    local procedure RunFindBWPickBinLoop(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToBinCode: Code[20];
        UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal;
        var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        DefaultBin: Boolean;
        CrossDockBin: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunFindBWPickBinLoop(LocationCode, ItemNo, VariantCode, ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure,
            TotalQtyToPick, TotalQtytoPickBase, TempWhseItemTrackingLine, WhseItemTrackingSetup, IsHandled);
        if IsHandled then
            exit;

        for CrossDockBin := true downto false do
            for DefaultBin := true downto false do
                if TotalQtytoPickBase > 0 then
                    FindBWPickBin(
                      LocationCode, ItemNo, VariantCode,
                      ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtyRndPrec, QtyRndPrecBase, DefaultBin, CrossDockBin,
                      TotalQtyToPick, TotalQtytoPickBase, TempWhseItemTrackingLine, WhseItemTrackingSetup);
    end;

    local procedure FindBWPickBin(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToBinCode: Code[20]; UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal;
        QtyRoundingPrecision: Decimal; QtyRoundingPrecisionBase: Decimal; DefaultBin: Boolean; CrossDockBin: Boolean; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal;
        var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        FromBinContent: Record "Bin Content";
        QtyAvailableBase: Decimal;
        QtyToPickBase: Decimal;
        QtytoPick: Decimal;
        BinCodeFilterText: Text[250];
        IsSetCurrentKeyHandled: Boolean;
        IsHandled: Boolean;
        EndLoop: Boolean;
    begin
        IsSetCurrentKeyHandled := false;
        OnBeforeFindBWPickBin(FromBinContent, IsSetCurrentKeyHandled);
        if not IsSetCurrentKeyHandled then
            if CrossDockBin then begin
                FromBinContent.SetCurrentKey(
                  "Location Code", "Item No.", "Variant Code", "Cross-Dock Bin", "Qty. per Unit of Measure", "Bin Ranking");
                FromBinContent.Ascending(false);
            end else
                FromBinContent.SetCurrentKey(Default, "Location Code", "Item No.", "Variant Code", "Bin Code");

        with FromBinContent do begin
            SetRange(Default, DefaultBin);
            SetRange("Cross-Dock Bin", CrossDockBin);
            SetRange("Location Code", LocationCode);
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            GetLocation(LocationCode);
            IsHandled := false;
            OnBeforeSetBinCodeFilter(BinCodeFilterText, LocationCode, ItemNo, VariantCode, ToBinCode, IsHandled, SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo);
            if not IsHandled then begin
                if Location."Require Pick" and (Location."Shipment Bin Code" <> '') then
                    AddToFilterText(BinCodeFilterText, '&', '<>', Location."Shipment Bin Code");
                if Location."Require Put-away" and (Location."Receipt Bin Code" <> '') then
                    AddToFilterText(BinCodeFilterText, '&', '<>', Location."Receipt Bin Code");
                if ToBinCode <> '' then
                    AddToFilterText(BinCodeFilterText, '&', '<>', ToBinCode);

                OnFindBWPickBinOnBeforeApplyBinCodeFilter(BinCodeFilterText);
                if BinCodeFilterText <> '' then
                    SetFilter("Bin Code", BinCodeFilterText);
                if WhseItemTrkgExists then begin
                    WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine);
                    SetTrackingFilterFromItemTrackingSetupIfRequiredWithBlank(WhseItemTrackingSetup);
                end;
            end;

            IsHandled := false;
#if not CLEAN20
            OnFindBWPickBinOnBeforeFindFromBinContent(FromBinContent, SourceType, TotalQtyPickedBase, IsHandled, TotalQtyToPickBase);
#endif
            OnFindBWPickBinOnBeforeFromBinContentFindSet(FromBinContent, SourceType, TotalQtyPickedBase, TotalQtyToPickBase, IsHandled, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, LocationCode, ItemNo, VariantCode, ToBinCode);
            if not IsHandled then
                if FindSet() then
                    repeat
                        QtyAvailableBase :=
                            CalcQtyAvailToPick(0) -
                            CalcPickQtyAssigned(LocationCode, ItemNo, VariantCode, '', "Bin Code", TempWhseItemTrackingLine);

                        OnCalcAvailQtyOnFindBWPickBin(
                            ItemNo, VariantCode,
                            WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", WhseItemTrkgExists,
                            TempWhseItemTrackingLine."Serial No.", TempWhseItemTrackingLine."Lot No.", "Location Code", "Bin Code",
                            SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtyToPickBase, QtyAvailableBase);

                        if QtyAvailableBase > 0 then begin
                            IsHandled := false;
                            OnFindBWPickBinOnBeforeSetQtyAvailableBaseForSerialNo(FromBinContent, QtyAvailableBase, IsHandled);
                            if not IsHandled then
                                if WhseItemTrackingSetup."Serial No. Required" then
                                    QtyAvailableBase := 1;

                            UpdateQuantitiesToPick(
                                QtyAvailableBase,
                                QtyPerUnitofMeasure, QtytoPick, QtyToPickBase,
                                QtyPerUnitofMeasure, QtytoPick, QtyToPickBase,
                                TotalQtyToPick, TotalQtyToPickBase);

                            CreateTempActivityLine(
                                LocationCode, "Bin Code", UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtyToPickBase, 1, 0, QtyRoundingPrecision, QtyRoundingPrecisionBase);
                            CreateTempActivityLine(
                                LocationCode, ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtyToPickBase, 2, 0, QtyRoundingPrecision, QtyRoundingPrecisionBase);
                        end;
                        EndLoop := false;
                        IsHandled := false;
                        OnFindBWPickBinOnBeforeEndLoop(FromBinContent, TotalQtyToPickBase, EndLoop, IsHandled, QtytoPick, QtyToPickBase);
                        if not IsHandled then
                            EndLoop := (Next() = 0) or (TotalQtyToPickBase = 0);
                    until EndLoop;
        end;
    end;

    local procedure CalcPickBin(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal;
        QtyRoundingPrecision: Decimal; QtyRoundingPrecisionBase: Decimal; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        CrossDock: Boolean; var TotalQtytoPickBase: Decimal; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal)
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        // Directed put-away and pick
        IsHandled := false;
        OnBeforeCalcPickBin(
            TempWhseActivLine, TotalQtytoPick, TotalQtytoPickBase, TempWhseItemTrackingLine,
            CrossDock, WhseItemTrkgExists, CreatePickParameters."Whse. Document",
            LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode, QtyPerUnitofMeasure, IsHandled);
        if IsHandled then
            exit;

        if TotalQtytoPickBase > 0 then begin
            ItemTrackingMgt.GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);
            OnCalcPickBinOnAfterGetWhseItemTrkgSetup(WhseItemTrackingSetup, LocationCode);
            FindPickBin(
                LocationCode, ItemNo, VariantCode, UnitofMeasureCode,
                ToBinCode, QtyRoundingPrecision, QtyRoundingPrecisionBase, TempWhseActivLine, TotalQtytoPick, TempWhseItemTrackingLine, CrossDock, TotalQtytoPickBase, WhseItemTrackingSetup);
            if (TotalQtytoPickBase > 0) and Location."Allow Breakbulk" then begin
                FindBreakBulkBin(
                    LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode,
                    QtyPerUnitofMeasure, TempWhseActivLine, TotalQtytoPick, TempWhseItemTrackingLine, CrossDock,
                    TotalQtytoPickBase, WhseItemTrackingSetup, QtyRndPrec, QtyRndPrecBase);
                if TotalQtytoPickBase > 0 then
                    FindSmallerUOMBin(
                        LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode,
                        QtyPerUnitofMeasure, TotalQtytoPick, TempWhseItemTrackingLine, CrossDock, TotalQtytoPickBase, WhseItemTrackingSetup, QtyRndPrec, QtyRndPrecBase);
            end;
        end;
    end;

    local procedure BinContentBlocked(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]): Boolean
    var
        BinContent: Record "Bin Content";
    begin
        with BinContent do begin
            Get(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode);
            if "Block Movement" in ["Block Movement"::Outbound, "Block Movement"::All] then
                exit(true);
        end;
    end;

    local procedure BreakBulkPlacingExists(var TempBinContent: Record "Bin Content" temporary; ItemNo: Code[20]; LocationCode: Code[10]; UOMCode: Code[10]; VariantCode: Code[10]; CrossDock: Boolean; WhseItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        BinContent2: Record "Bin Content";
        WhseActivLine2: Record "Warehouse Activity Line";
    begin
        TempBinContent.Reset();
        TempBinContent.DeleteAll();
        with BinContent2 do begin
            SetCurrentKey("Location Code", "Item No.", "Variant Code", "Cross-Dock Bin", "Qty. per Unit of Measure", "Bin Ranking");
            SetRange("Location Code", LocationCode);
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetRange("Cross-Dock Bin", CrossDock);
            OnBreakBulkPlacingExistsOnAfterBinContent2SetFilters(BinContent2);
            if IsMovementWorksheet then
                SetFilter("Bin Ranking", '<%1', Bin."Bin Ranking");
            if WhseItemTrkgExists then begin
                WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine);
                SetTrackingFilterFromItemTrackingSetupIfRequiredWithBlank(WhseItemTrackingSetup);
            end;
            Ascending(false);
        end;

        WhseActivLine2.Copy(TempWhseActivLine);
        with TempWhseActivLine do begin
            SetRange("Location Code", LocationCode);
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetRange("Unit of Measure Code", UOMCode);
            SetRange("Action Type", "Action Type"::Place);
            SetFilter("Breakbulk No.", '<>0');
            SetRange("Bin Code");
            if WhseItemTrkgExists then begin
                WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine);
                SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup);
            end;
            if FindFirst() then
                repeat
                    BinContent2.SetRange("Bin Code", "Bin Code");
                    BinContent2.SetRange("Unit of Measure Code", UOMCode);
                    if BinContent2.IsEmpty() then begin
                        BinContent2.SetRange("Unit of Measure Code");
                        if BinContent2.FindFirst() then begin
                            TempBinContent := BinContent2;
                            TempBinContent.Validate("Unit of Measure Code", UOMCode);
                            if TempBinContent.Insert() then;
                        end;
                    end;
                until Next() = 0;
        end;
        TempWhseActivLine.Copy(WhseActivLine2);
        exit(not TempBinContent.IsEmpty);
    end;

    local procedure FindPickBin(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; ToBinCode: Code[20];
        QtyRndPrec: Decimal; QtyRndPrecBase: Decimal; var TempWhseActivLine2: Record "Warehouse Activity Line" temporary; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        CrossDock: Boolean; var TotalQtytoPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        FromBinContent: Record "Bin Content";
        FromQtyToPick: Decimal;
        FromQtyToPickBase: Decimal;
        ToQtyToPick: Decimal;
        ToQtyToPickBase: Decimal;
        TotalAvailQtyToPickBase: Decimal;
        AvailableQtyBase: Decimal;
        BinIsForPick: Boolean;
        BinIsForReplenishment: Boolean;
        IsHandled: Boolean;
    begin
        // Directed put-away and pick
        GetBin(LocationCode, ToBinCode);
        GetLocation(LocationCode);

        WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine);

        IsHandled := false;
        OnBeforeFindPickBin(
            LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode, QtyRndPrec, QtyRndPrecBase,
            TempWhseActivLine2, TotalQtytoPick, TempWhseItemTrackingLine, CrossDock, TotalQtytoPickBase,
            WhseItemTrackingSetup, IsMovementWorksheet, WhseItemTrkgExists, IsHandled);
        if IsHandled then
            exit;

        if GetBinContent(
            FromBinContent, ItemNo, VariantCode, UnitofMeasureCode, LocationCode, ToBinCode, CrossDock,
            IsMovementWorksheet, WhseItemTrkgExists, false, false, WhseItemTrackingSetup, TotalQtytoPick, TotalQtytoPickBase)
        then begin
            TotalAvailQtyToPickBase :=
                CalcTotalAvailQtyToPick(
                    LocationCode, ItemNo, VariantCode, TempWhseItemTrackingLine,
                    SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtytoPickBase, false);
            if TotalAvailQtyToPickBase < 0 then
                TotalAvailQtyToPickBase := 0;

            OnFindPickBinOnBeforeStartFromBinContentLoop(TempWhseItemTrackingLine, TotalAvailQtyToPickBase);
            repeat
                BinIsForPick := UseForPick(FromBinContent) and (not IsMovementWorksheet);
                BinIsForReplenishment := UseForReplenishment(FromBinContent) and IsMovementWorksheet;
                if FromBinContent."Bin Code" <> ToBinCode then
                    CalcBinAvailQtyToPick(AvailableQtyBase, FromBinContent, TempWhseActivLine2, WhseItemTrackingSetup);
                if BinIsForPick or BinIsForReplenishment then begin
                    if TotalAvailQtyToPickBase < AvailableQtyBase then
                        AvailableQtyBase := TotalAvailQtyToPickBase;

                    if TotalQtytoPickBase < AvailableQtyBase then
                        AvailableQtyBase := TotalQtytoPickBase;

                    OnCalcAvailQtyOnFindPickBin2(
                        ItemNo, VariantCode,
                        WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", WhseItemTrkgExists,
                        TempWhseItemTrackingLine."Lot No.", TempWhseItemTrackingLine."Serial No.",
                        FromBinContent."Location Code", FromBinContent."Bin Code",
                        SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtytoPickBase, AvailableQtyBase);

                    if AvailableQtyBase > 0 then begin
                        ToQtyToPickBase := CalcQtyToPickBase(FromBinContent, TempWhseActivLine);
                        if AvailableQtyBase > ToQtyToPickBase then
                            AvailableQtyBase := ToQtyToPickBase;

                        IsHandled := false;
                        OnFindPickBinOnBeforeUpdateQuantitesAndCreateActivityLines(FromBinContent, TempWhseActivLine, ToQtyToPick, ToQtyToPickBase, AvailableQtyBase, IsHandled);
                        if not IsHandled then begin
                            UpdateQuantitiesToPick(
                                AvailableQtyBase,
                                FromBinContent."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase,
                                FromBinContent."Qty. per Unit of Measure", ToQtyToPick, ToQtyToPickBase,
                                TotalQtytoPick, TotalQtytoPickBase);

                            CreateTempActivityLine(
                                LocationCode, FromBinContent."Bin Code", UnitofMeasureCode, FromBinContent."Qty. per Unit of Measure",
                                FromQtyToPick, FromQtyToPickBase, 1, 0, QtyRndPrec, QtyRndPrecBase);
                            CreateTempActivityLine(
                                LocationCode, ToBinCode, UnitofMeasureCode, FromBinContent."Qty. per Unit of Measure",
                                ToQtyToPick, ToQtyToPickBase, 2, 0, QtyRndPrec, QtyRndPrecBase);
                        end;

                        TotalAvailQtyToPickBase := TotalAvailQtyToPickBase - ToQtyToPickBase;
                        OnFindPickBinOnAfterUpdateTotalAvailQtyToPickBase(TempWhseItemTrackingLine, TotalAvailQtyToPickBase, ToQtyToPick, ToQtyToPickBase);
                    end;
                end else
                    EnqueueCannotBeHandledReason(
                        GetMessageForUnhandledQtyDueToBin(
                            BinIsForPick, BinIsForReplenishment, IsMovementWorksheet,
                            AvailableQtyBase, FromBinContent));
            until (FromBinContent.Next() = 0) or (TotalQtytoPickBase = 0);
        end;
    end;

    local procedure GetBinContent(
        var FromBinContent: Record "Bin Content";
        ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; LocationCode: Code[10]; ToBinCode: Code[20];
        CrossDock: Boolean; IsMovementWorksheet: Boolean; WhseItemTrkgExists: Boolean; BreakbulkBins: Boolean; SmallerUOMBins: Boolean;
        WhseItemTrackingSetup: Record "Item Tracking Setup"; TotalQtytoPick: Decimal; TotalQtytoPickBase: Decimal): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetBinContent(
            FromBinContent, ItemNo, VariantCode, UnitofMeasureCode, LocationCode, ToBinCode, CrossDock, IsMovementWorksheet,
            WhseItemTrkgExists, BreakbulkBins, SmallerUOMBins, WhseItemTrackingSetup, TotalQtytoPick, TotalQtytoPickBase,
            Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(
            FromBinContent.GetBinContent(
                ItemNo, VariantCode, UnitofMeasureCode, LocationCode, ToBinCode, CrossDock,
                IsMovementWorksheet, WhseItemTrkgExists, WhseItemTrackingSetup));
    end;

    local procedure FindBreakBulkBin(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToUOMCode: Code[10]; ToBinCode: Code[20]; ToQtyPerUOM: Decimal;
        var TempWhseActivLine2: Record "Warehouse Activity Line" temporary; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        CrossDock: Boolean; var TotalQtytoPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal)
    var
        FromItemUOM: Record "Item Unit of Measure";
        FromBinContent: Record "Bin Content";
        TotalAvailQtyToPickBase: Decimal;
    begin
        // Directed put-away and pick
        GetBin(LocationCode, ToBinCode);

        TotalAvailQtyToPickBase :=
          CalcTotalAvailQtyToPick(
            LocationCode, ItemNo, VariantCode, TempWhseItemTrackingLine,
            SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, 0, false);

        if TotalAvailQtyToPickBase < 0 then
            TotalAvailQtyToPickBase := 0;

        if not Location."Always Create Pick Line" then begin
            if TotalAvailQtyToPickBase = 0 then
                exit;

            if TotalAvailQtyToPickBase < TotalQtytoPickBase then begin
                TotalQtytoPickBase := TotalAvailQtyToPickBase;
                TotalQtytoPick := Round(TotalQtytoPickBase / ToQtyPerUOM, UOMMgt.QtyRndPrecision());
            end;
        end;

        WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine);

        FromItemUOM.SetCurrentKey("Item No.", "Qty. per Unit of Measure");
        FromItemUOM.SetRange("Item No.", ItemNo);
        FromItemUOM.SetFilter("Qty. per Unit of Measure", '>=%1', ToQtyPerUOM);
        FromItemUOM.SetFilter(Code, '<>%1', ToUOMCode);
        if FromItemUOM.Find('-') then
            repeat
                if GetBinContent(
                    FromBinContent, ItemNo, VariantCode, FromItemUOM.Code, LocationCode, ToBinCode, CrossDock,
                    IsMovementWorksheet, WhseItemTrkgExists, true, false, WhseItemTrackingSetup, TotalQtytoPick, TotalQtytoPickBase)
                then
                    repeat
                        if (FromBinContent."Bin Code" <> ToBinCode) and
                            ((UseForPick(FromBinContent) and (not IsMovementWorksheet)) or
                            (UseForReplenishment(FromBinContent) and IsMovementWorksheet))
                        then
                            if FindBreakBulkBinPerBinContent(FromItemUOM, FromBinContent, ItemNo, VariantCode, ToUOMCode, ToBinCode, ToQtyPerUOM,
                                TempWhseActivLine2, TotalQtytoPick, TempWhseItemTrackingLine, TotalQtytoPickBase, WhseItemTrackingSetup, QtyRndPrec, QtyRndPrecBase)
                            then
                                exit;
                    until FromBinContent.Next() = 0;
            until FromItemUOM.Next() = 0;
    end;

    local procedure FindBreakBulkBinPerBinContent(FromItemUOM: Record "Item Unit of Measure"; var FromBinContent: Record "Bin Content"; ItemNo: Code[20]; VariantCode: Code[10]; ToUOMCode: Code[10]; ToBinCode: Code[20]; ToQtyPerUOM: Decimal;
        var TempWhseActivLine2: Record "Warehouse Activity Line" temporary; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        var TotalQtytoPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal) StopProcessing: Boolean
    var
        QtyAvailableBase: Decimal;
        FromQtyToPick: Decimal;
        FromQtyToPickBase: Decimal;
        ToQtyToPick: Decimal;
        ToQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindBreakBulkBinPerBinContent(
            FromBinContent, ItemNo, VariantCode, WhseItemTrackingSetup, WhseItemTrkgExists, TempWhseItemTrackingLine,
             SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtytoPickBase, QtyAvailableBase,
             StopProcessing, IsHandled);
        if IsHandled then
            exit(StopProcessing);

        // Check and use bulk that has previously been broken
        QtyAvailableBase := CalcBinAvailQtyInBreakbulk(TempWhseActivLine2, FromBinContent, ToUOMCode, WhseItemTrackingSetup);

        OnCalcAvailQtyOnFindBreakBulkBin(
            true, ItemNo, VariantCode,
            WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", WhseItemTrkgExists,
            TempWhseItemTrackingLine."Lot No.", TempWhseItemTrackingLine."Serial No.",
            FromBinContent."Location Code", FromBinContent."Bin Code",
            SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtytoPickBase, QtyAvailableBase,
            WhseItemTrackingSetup);

        if QtyAvailableBase > 0 then begin
            UpdateQuantitiesToPick(
                QtyAvailableBase,
                ToQtyPerUOM, FromQtyToPick, FromQtyToPickBase,
                ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase,
                TotalQtytoPick, TotalQtytoPickBase);

            CreateBreakBulkTempLines(
                FromBinContent."Location Code", ToUOMCode, ToUOMCode,
                FromBinContent."Bin Code", ToBinCode, ToQtyPerUOM, ToQtyPerUOM,
                0, FromQtyToPick, FromQtyToPickBase, ToQtyToPick, ToQtyToPickBase, QtyRndPrec, QtyRndPrecBase);
        end;

        if TotalQtytoPickBase <= 0 then
            exit(true);

        // Now break bulk and use
        QtyAvailableBase := CalcBinAvailQtyToBreakbulk(TempWhseActivLine2, FromBinContent, WhseItemTrackingSetup);

        OnCalcAvailQtyOnFindBreakBulkBin(
            false, ItemNo, VariantCode,
            WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", WhseItemTrkgExists,
            TempWhseItemTrackingLine."Lot No.", TempWhseItemTrackingLine."Serial No.",
            FromBinContent."Location Code", FromBinContent."Bin Code",
            SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtytoPickBase, QtyAvailableBase,
            WhseItemTrackingSetup);

        if QtyAvailableBase > 0 then begin
            FromItemUOM.Get(ItemNo, FromBinContent."Unit of Measure Code");
            UpdateQuantitiesToPick(
                QtyAvailableBase,
                FromItemUOM."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase,
                ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase,
                TotalQtytoPick, TotalQtytoPickBase);

            BreakbulkNo := BreakbulkNo + 1;
            CreateBreakBulkTempLines(
                FromBinContent."Location Code", FromBinContent."Unit of Measure Code", ToUOMCode,
                FromBinContent."Bin Code", ToBinCode, FromItemUOM."Qty. per Unit of Measure", ToQtyPerUOM,
                BreakbulkNo, ToQtyToPick, ToQtyToPickBase, FromQtyToPick, FromQtyToPickBase,
                QtyRndPrec, QtyRndPrecBase);
        end;
        if TotalQtytoPickBase <= 0 then
            exit(true);
    end;

    local procedure FindSmallerUOMBin(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; ToBinCode: Code[20]; QtyPerUnitOfMeasure: Decimal;
        var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        CrossDock: Boolean; var TotalQtytoPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal)
    var
        ItemUOM: Record "Item Unit of Measure";
        FromBinContent: Record "Bin Content";
        TempFromBinContent: Record "Bin Content" temporary;
        FromQtyToPick: Decimal;
        FromQtyToPickBase: Decimal;
        ToQtyToPick: Decimal;
        ToQtyToPickBase: Decimal;
        QtyAvailableBase: Decimal;
        TotalAvailQtyToPickBase: Decimal;
    begin
        // Directed put-away and pick
        TotalAvailQtyToPickBase :=
          CalcTotalAvailQtyToPick(
            LocationCode, ItemNo, VariantCode, TempWhseItemTrackingLine,
            SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, 0, false);

        if TotalAvailQtyToPickBase < 0 then
            TotalAvailQtyToPickBase := 0;

        if not Location."Always Create Pick Line" then begin
            if TotalAvailQtyToPickBase = 0 then
                exit;

            if TotalAvailQtyToPickBase < TotalQtytoPickBase then begin
                TotalQtytoPickBase := TotalAvailQtyToPickBase;
                ItemUOM.Get(ItemNo, UnitofMeasureCode);
                TotalQtytoPick := Round(TotalQtytoPickBase / ItemUOM."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
            end;
        end;

        GetBin(LocationCode, ToBinCode);

        WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine);

        ItemUOM.SetCurrentKey("Item No.", "Qty. per Unit of Measure");
        ItemUOM.SetRange("Item No.", ItemNo);
        ItemUOM.SetFilter("Qty. per Unit of Measure", '<%1', QtyPerUnitOfMeasure);
        ItemUOM.SetFilter(Code, '<>%1', UnitofMeasureCode);
        ItemUOM.Ascending(false);
        if ItemUOM.Find('-') then
            repeat
                if GetBinContent(
                    FromBinContent, ItemNo, VariantCode, ItemUOM.Code, LocationCode, ToBinCode, CrossDock,
                    IsMovementWorksheet, WhseItemTrkgExists, false, true, WhseItemTrackingSetup, TotalQtytoPick, TotalQtytoPickBase)
                then
                    repeat
                        if (FromBinContent."Bin Code" <> ToBinCode) and
                            ((UseForPick(FromBinContent) and (not IsMovementWorksheet)) or
                            (UseForReplenishment(FromBinContent) and IsMovementWorksheet))
                        then begin
                            CalcBinAvailQtyFromSmallerUOM(QtyAvailableBase, FromBinContent, false, WhseItemTrackingSetup);

                            OnCalcAvailQtyOnFindSmallerUOMBin(
                                false, ItemNo, VariantCode,
                                WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", WhseItemTrkgExists,
                                TempWhseItemTrackingLine."Lot No.", TempWhseItemTrackingLine."Serial No.",
                                FromBinContent."Location Code", FromBinContent."Bin Code",
                                SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtytoPickBase, QtyAvailableBase,
                                WhseItemTrackingSetup);

                            if QtyAvailableBase > 0 then begin
                                UpdateQuantitiesToPick(
                                    QtyAvailableBase,
                                    ItemUOM."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase,
                                    QtyPerUnitOfMeasure, ToQtyToPick, ToQtyToPickBase,
                                    TotalQtytoPick, TotalQtytoPickBase);

                                CreateTempActivityLine(
                                    LocationCode, FromBinContent."Bin Code", FromBinContent."Unit of Measure Code",
                                    ItemUOM."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase, 1, 0, QtyRndPrec, QtyRndPrecBase);
                                CreateTempActivityLine(
                                    LocationCode, ToBinCode, UnitofMeasureCode,
                                    QtyPerUnitOfMeasure, ToQtyToPick, ToQtyToPickBase, 2, 0, QtyRndPrec, QtyRndPrecBase);

                                TotalAvailQtyToPickBase := TotalAvailQtyToPickBase - ToQtyToPickBase;
                            end;
                        end;
                    until (FromBinContent.Next() = 0) or (TotalQtytoPickBase = 0);

                if TotalQtytoPickBase > 0 then
                    if BreakBulkPlacingExists(TempFromBinContent, ItemNo, LocationCode, ItemUOM.Code, VariantCode, CrossDock, WhseItemTrackingSetup) then
                        repeat
                            if (TempFromBinContent."Bin Code" <> ToBinCode) and
                                ((UseForPick(TempFromBinContent) and (not IsMovementWorksheet)) or
                                (UseForReplenishment(TempFromBinContent) and IsMovementWorksheet))
                            then begin
                                CalcBinAvailQtyFromSmallerUOM(QtyAvailableBase, TempFromBinContent, true, WhseItemTrackingSetup);

                                OnCalcAvailQtyOnFindSmallerUOMBin(
                                    true, ItemNo, VariantCode,
                                    WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", WhseItemTrkgExists,
                                    TempWhseItemTrackingLine."Lot No.", TempWhseItemTrackingLine."Serial No.",
                                    TempFromBinContent."Location Code", TempFromBinContent."Bin Code",
                                    SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtytoPickBase, QtyAvailableBase,
                                    WhseItemTrackingSetup);

                                if QtyAvailableBase > 0 then begin
                                    UpdateQuantitiesToPick(
                                        QtyAvailableBase,
                                        ItemUOM."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase,
                                        QtyPerUnitOfMeasure, ToQtyToPick, ToQtyToPickBase,
                                        TotalQtytoPick, TotalQtytoPickBase);

                                    CreateTempActivityLine(
                                        LocationCode, TempFromBinContent."Bin Code", TempFromBinContent."Unit of Measure Code",
                                        ItemUOM."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase, 1, 0);
                                    CreateTempActivityLine(
                                        LocationCode, ToBinCode, UnitofMeasureCode,
                                        QtyPerUnitOfMeasure, ToQtyToPick, ToQtyToPickBase, 2, 0);
                                    TotalAvailQtyToPickBase := TotalAvailQtyToPickBase - ToQtyToPickBase;
                                end;
                            end;
                        until (TempFromBinContent.Next() = 0) or (TotalQtytoPickBase = 0);
            until (ItemUOM.Next() = 0) or (TotalQtytoPickBase = 0);
    end;

    local procedure FindWhseActivLine(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; Location: Record Location; var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]): Boolean
    begin
        TempWhseActivLine.SetRange("Location Code", TempWhseActivLine."Location Code");
        if Location."Bin Mandatory" then
            TempWhseActivLine.SetRange("Action Type", TempWhseActivLine."Action Type"::Take)
        else
            TempWhseActivLine.SetRange("Action Type", TempWhseActivLine."Action Type"::" ");

        if not TempWhseActivLine.Find('-') then begin
            OnAfterFindWhseActivLine(FirstWhseDocNo, LastWhseDocNo);
            exit(false);
        end;

        exit(true);
    end;

    procedure CalcBinAvailQtyToPick(var QtyToPickBase: Decimal; var BinContent: Record "Bin Content"; var TempWhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        AvailableQtyBase: Decimal;
    begin
        with TempWhseActivLine do begin
            Reset();
            SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Action Type",
              "Variant Code", "Unit of Measure Code", "Breakbulk No.");
            SetRange("Item No.", BinContent."Item No.");
            SetRange("Bin Code", BinContent."Bin Code");
            SetRange("Location Code", BinContent."Location Code");
            SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
            SetRange("Variant Code", BinContent."Variant Code");
            if WhseItemTrkgExists then
                SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup);

            if Location."Allow Breakbulk" then begin
                SetRange("Action Type", "Action Type"::Place);
                SetFilter("Breakbulk No.", '<>0');
                CalcSums("Qty. (Base)");
                AvailableQtyBase := "Qty. (Base)";
            end;

            SetRange("Action Type", "Action Type"::Take);
            SetRange("Breakbulk No.", 0);
            CalcSums("Qty. (Base)");
        end;

        QtyToPickBase := BinContent.CalcQtyAvailToPick(AvailableQtyBase - TempWhseActivLine."Qty. (Base)");
    end;

    local procedure CalcBinAvailQtyToBreakbulk(var TempWhseActivLine2: Record "Warehouse Activity Line"; var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup") QtyToPickBase: Decimal
    begin
        with BinContent do begin
            SetFilterOnUnitOfMeasure();
            CalcFields("Quantity (Base)", "Pick Quantity (Base)", "Negative Adjmt. Qty. (Base)");
            QtyToPickBase := "Quantity (Base)" - "Pick Quantity (Base)" - "Negative Adjmt. Qty. (Base)";
        end;
        if QtyToPickBase <= 0 then
            exit(0);

        with TempWhseActivLine2 do begin
            SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Action Type",
              "Variant Code", "Unit of Measure Code", "Breakbulk No.");
            SetRange("Action Type", "Action Type"::Take);
            SetRange("Location Code", BinContent."Location Code");
            SetRange("Bin Code", BinContent."Bin Code");
            SetRange("Item No.", BinContent."Item No.");
            SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
            SetRange("Variant Code", BinContent."Variant Code");
            if WhseItemTrkgExists then
                SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup)
            else
                ClearTrackingFilter();

            ClearSourceFilter();
            SetRange("Breakbulk No.");
            CalcSums("Qty. (Base)");
            QtyToPickBase := QtyToPickBase - "Qty. (Base)";
            exit(QtyToPickBase);
        end;
    end;

    local procedure CalcBinAvailQtyInBreakbulk(var TempWhseActivLine2: Record "Warehouse Activity Line"; var BinContent: Record "Bin Content"; ToUOMCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup") QtyToPickBase: Decimal
    begin
        with TempWhseActivLine2 do begin
            if (CreatePickParameters."Max No. of Source Doc." > 1) or (CreatePickParameters."Max No. of Lines" <> 0) then
                exit(0);

            SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Action Type",
              "Variant Code", "Unit of Measure Code", "Breakbulk No.");
            SetRange("Action Type", "Action Type"::Take);
            SetRange("Location Code", BinContent."Location Code");
            SetRange("Bin Code", BinContent."Bin Code");
            SetRange("Item No.", BinContent."Item No.");
            SetRange("Unit of Measure Code", ToUOMCode);
            SetRange("Variant Code", BinContent."Variant Code");
            if WhseItemTrkgExists then
                SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup)
            else
                ClearTrackingFilter();
            SetRange("Breakbulk No.", 0);
            CalcSums("Qty. (Base)");
            QtyToPickBase := "Qty. (Base)";

            SetRange("Action Type", "Action Type"::Place);
            SetFilter("Breakbulk No.", '<>0');
            SetRange("No.", Format(TempNo));
            if CreatePickParameters."Max No. of Source Doc." = 1 then begin
                SetRange("Source Type", WhseWkshLine."Source Type");
                SetRange("Source Subtype", WhseWkshLine."Source Subtype");
                SetRange("Source No.", WhseWkshLine."Source No.");
            end;
            CalcSums("Qty. (Base)");
            QtyToPickBase := "Qty. (Base)" - QtyToPickBase;
            exit(QtyToPickBase);
        end;
    end;

    local procedure CalcBinAvailQtyFromSmallerUOM(var AvailableQtyBase: Decimal; var BinContent: Record "Bin Content"; AllowInitialZero: Boolean; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        with BinContent do begin
            SetFilterOnUnitOfMeasure();
            CalcFields("Quantity (Base)", "Pick Quantity (Base)", "Negative Adjmt. Qty. (Base)");
            AvailableQtyBase := "Quantity (Base)" - "Pick Quantity (Base)" - "Negative Adjmt. Qty. (Base)";
        end;
        if (AvailableQtyBase < 0) or ((AvailableQtyBase = 0) and (not AllowInitialZero)) then
            exit;

        with TempWhseActivLine do begin
            SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Action Type",
              "Variant Code", "Unit of Measure Code", "Breakbulk No.");

            SetRange("Item No.", BinContent."Item No.");
            SetRange("Bin Code", BinContent."Bin Code");
            SetRange("Location Code", BinContent."Location Code");
            SetRange("Action Type", "Action Type"::Take);
            SetRange("Variant Code", BinContent."Variant Code");
            SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
            if WhseItemTrkgExists then
                SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup)
            else
                ClearTrackingFilter();
            CalcSums("Qty. (Base)");
            AvailableQtyBase := AvailableQtyBase - "Qty. (Base)";

            SetRange("Action Type", "Action Type"::Place);
            SetFilter("Breakbulk No.", '<>0');
            CalcSums("Qty. (Base)");
            AvailableQtyBase := AvailableQtyBase + "Qty. (Base)";
            Reset();
        end;
    end;

    local procedure CreateBreakBulkTempLines(LocationCode: Code[10]; FromUOMCode: Code[10]; ToUOMCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; FromQtyPerUOM: Decimal; ToQtyPerUOM: Decimal; BreakbulkNo2: Integer; ToQtyToPick: Decimal; ToQtyToPickBase: Decimal; FromQtyToPick: Decimal; FromQtyToPickBase: Decimal; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal)
    var
        QtyToBreakBulk: Decimal;
    begin
        // Directed put-away and pick
        if FromUOMCode <> ToUOMCode then begin
            CreateTempActivityLine(
              LocationCode, FromBinCode, FromUOMCode, FromQtyPerUOM, FromQtyToPick, FromQtyToPickBase, 1, BreakbulkNo2, QtyRndPrec, QtyRndPrecBase);

            if FromQtyToPickBase = ToQtyToPickBase then
                QtyToBreakBulk := ToQtyToPick
            else
                QtyToBreakBulk := Round(FromQtyToPick * FromQtyPerUOM / ToQtyPerUOM, UOMMgt.QtyRndPrecision());
            CreateTempActivityLine(
              LocationCode, FromBinCode, ToUOMCode, ToQtyPerUOM, QtyToBreakBulk, FromQtyToPickBase, 2, BreakbulkNo2, QtyRndPrec, QtyRndPrecBase);
        end;
        CreateTempActivityLine(LocationCode, FromBinCode, ToUOMCode, ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase, 1, 0, QtyRndPrec, QtyRndPrecBase);
        CreateTempActivityLine(LocationCode, ToBinCode, ToUOMCode, ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase, 2, 0, QtyRndPrec, QtyRndPrecBase);
    end;

    procedure CreateWhseDocument(var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; ShowError: Boolean)
    var
        OldNo: Code[20];
        OldSourceNo: Code[20];
        OldLocationCode: Code[10];
        OldBinCode: Code[20];
        OldZoneCode: Code[10];
        NoOfLines: Integer;
        NoOfSourceDoc: Integer;
        CreateNewHeader: Boolean;
        WhseDocCreated: Boolean;
        IsHandled: Boolean;
    begin
        TempWhseActivLine.Reset();
        if not TempWhseActivLine.Find('-') then begin
            OnCreateWhseDocumentOnBeforeShowError(ShowError);
            if ShowError then
                Error(Text000, DequeueCannotBeHandledReason());
            exit;
        end;

        IsHandled := false;
        OnBeforeCreateWhseDocument(TempWhseActivLine, CreatePickParameters."Whse. Document", IsHandled);
        if IsHandled then
            exit;

        LockTables();

        if IsMovementWorksheet then
            TempWhseActivLine.SetRange("Activity Type", TempWhseActivLine."Activity Type"::Movement)
        else
            TempWhseActivLine.SetRange("Activity Type", TempWhseActivLine."Activity Type"::Pick);

        NoOfLines := 0;
        NoOfSourceDoc := 0;

        repeat
            GetLocation(TempWhseActivLine."Location Code");
            if not FindWhseActivLine(TempWhseActivLine, Location, FirstWhseDocNo, LastWhseDocNo) then
                exit;

            if CreatePickParameters."Per Bin" then
                TempWhseActivLine.SetRange("Bin Code", TempWhseActivLine."Bin Code");
            if CreatePickParameters."Per Zone" then
                TempWhseActivLine.SetRange("Zone Code", TempWhseActivLine."Zone Code");

            OnCreateWhseDocumentOnAfterSetFiltersBeforeLoop(TempWhseActivLine, CreatePickParameters."Per Bin", CreatePickParameters."Per Zone");

            repeat
                IsHandled := false;
                CreateNewHeader := false;
                OnCreateWhseDocumentOnBeforeCreateDocAndLine(TempWhseActivLine, IsHandled, CreateNewHeader);
                if IsHandled then begin
                    if CreateNewHeader then begin
                        CreateWhseActivHeader(
                          TempWhseActivLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
                          NoOfSourceDoc, NoOfLines, WhseDocCreated);
                        CreateWhseDocLine();
                    end else
                        CreateNewWhseDoc(
                          OldNo, OldSourceNo, OldLocationCode, FirstWhseDocNo, LastWhseDocNo,
                          NoOfSourceDoc, NoOfLines, WhseDocCreated);
                end else
                    if CreatePickParameters."Per Bin" then begin
                        if TempWhseActivLine."Bin Code" <> OldBinCode then begin
                            CreateWhseActivHeader(
                              TempWhseActivLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
                              NoOfSourceDoc, NoOfLines, WhseDocCreated);
                            CreateWhseDocLine();
                        end else
                            CreateNewWhseDoc(
                              OldNo, OldSourceNo, OldLocationCode, FirstWhseDocNo, LastWhseDocNo,
                              NoOfSourceDoc, NoOfLines, WhseDocCreated);
                    end else begin
                        if CreatePickParameters."Per Zone" then begin
                            if TempWhseActivLine."Zone Code" <> OldZoneCode then begin
                                CreateWhseActivHeader(
                                  TempWhseActivLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
                                  NoOfSourceDoc, NoOfLines, WhseDocCreated);
                                CreateWhseDocLine();
                            end else
                                CreateNewWhseDoc(
                                  OldNo, OldSourceNo, OldLocationCode, FirstWhseDocNo, LastWhseDocNo,
                                  NoOfSourceDoc, NoOfLines, WhseDocCreated);
                        end else
                            CreateNewWhseDoc(
                              OldNo, OldSourceNo, OldLocationCode, FirstWhseDocNo, LastWhseDocNo,
                              NoOfSourceDoc, NoOfLines, WhseDocCreated);
                    end;

                OldZoneCode := TempWhseActivLine."Zone Code";
                OldBinCode := TempWhseActivLine."Bin Code";
                OldNo := TempWhseActivLine."No.";
                OldSourceNo := TempWhseActivLine."Source No.";
                OldLocationCode := TempWhseActivLine."Location Code";
                OnCreateWhseDocumentOnAfterSaveOldValues(TempWhseActivLine, WhseActivHeader, LastWhseDocNo);
            until TempWhseActivLine.Next() = 0;
            OnCreateWhseDocumentOnBeforeClearFilters(TempWhseActivLine, WhseActivHeader);
            TempWhseActivLine.SetRange("Bin Code");
            TempWhseActivLine.SetRange("Zone Code");
            TempWhseActivLine.SetRange("Location Code");
            TempWhseActivLine.SetRange("Action Type");
            OnCreateWhseDocumentOnAfterSetFiltersAfterLoop(TempWhseActivLine);
            if not TempWhseActivLine.Find('-') then begin
                OnAfterCreateWhseDocument(FirstWhseDocNo, LastWhseDocNo, CreatePickParameters);
                exit;
            end;

        until false;
    end;

    local procedure CreateNewWhseDoc(OldNo: Code[20]; OldSourceNo: Code[20]; OldLocationCode: Code[10]; var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; var NoOfSourceDoc: Integer; var NoOfLines: Integer; var WhseDocCreated: Boolean)
    begin
        OnBeforeCreateNewWhseDoc(
          TempWhseActivLine, OldNo, OldSourceNo, OldLocationCode, FirstWhseDocNo, LastWhseDocNo, NoOfSourceDoc, NoOfLines, WhseDocCreated);

        if (TempWhseActivLine."No." <> OldNo) or
           (TempWhseActivLine."Location Code" <> OldLocationCode)
        then begin
            CreateWhseActivHeader(
              TempWhseActivLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
              NoOfSourceDoc, NoOfLines, WhseDocCreated);
            CreateWhseDocLine();
        end else begin
            NoOfLines := NoOfLines + 1;
            if TempWhseActivLine."Source No." <> OldSourceNo then
                NoOfSourceDoc := NoOfSourceDoc + 1;
            if (CreatePickParameters."Max No. of Source Doc." > 0) and (NoOfSourceDoc > CreatePickParameters."Max No. of Source Doc.") then
                CreateWhseActivHeader(
                  TempWhseActivLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
                  NoOfSourceDoc, NoOfLines, WhseDocCreated);
            if (CreatePickParameters."Max No. of Lines" > 0) and (NoOfLines > CreatePickParameters."Max No. of Lines") then
                CreateWhseActivHeader(
                  TempWhseActivLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
                  NoOfSourceDoc, NoOfLines, WhseDocCreated);
            CreateWhseDocLine();
        end;
    end;

    local procedure CreateWhseActivHeader(LocationCode: Code[10]; var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; var NoOfSourceDoc: Integer; var NoOfLines: Integer; var WhseDocCreated: Boolean)
    begin
        WhseActivHeader.Init();
        WhseActivHeader."No." := '';
        if CreatePickParameters."Whse. Document Type" = CreatePickParameters."Whse. Document Type"::Movement then
            WhseActivHeader.Type := WhseActivHeader.Type::Movement
        else
            WhseActivHeader.Type := WhseActivHeader.Type::Pick;
        WhseActivHeader."Location Code" := LocationCode;
        if CreatePickParameters."Assigned ID" <> '' then
            WhseActivHeader.Validate("Assigned User ID", CreatePickParameters."Assigned ID");
        WhseActivHeader."Sorting Method" := CreatePickParameters."Sorting Method";
        WhseActivHeader."Breakbulk Filter" := CreatePickParameters."Breakbulk Filter";
        OnBeforeWhseActivHeaderInsert(WhseActivHeader, TempWhseActivLine, CreatePickParameters, WhseShptLine);
        WhseActivHeader.Insert(true);
        OnCreateWhseActivHeaderOnAfterWhseActivHeaderInsert(WhseActivHeader, TempWhseActivLine, CreatePickParameters);

        NoOfLines := 1;
        NoOfSourceDoc := 1;

        if not WhseDocCreated then begin
            FirstWhseDocNo := WhseActivHeader."No.";
            WhseDocCreated := true;
        end;
        LastWhseDocNo := WhseActivHeader."No.";
    end;

    local procedure CreateWhseDocLine()
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        LineNo: Integer;
        IsHandled: Boolean;
    begin
        TempWhseActivLine.SetRange("Breakbulk No.", 0);
        TempWhseActivLine.Find('-');
        WhseActivLine.SetRange("Activity Type", WhseActivHeader.Type);
        WhseActivLine.SetRange("No.", WhseActivHeader."No.");
        if WhseActivLine.FindLast() then
            LineNo := WhseActivLine."Line No."
        else
            LineNo := 0;

        ItemTrackingMgt.GetWhseItemTrkgSetup(TempWhseActivLine."Item No.", WhseItemTrackingSetup);
        OnCreateWhseDocLineOnAfterGetWhseItemTrkgSetup(WhseItemTrackingSetup, TempWhseActivLine);

        LineNo := LineNo + 10000;
        WhseActivLine.Init();
        WhseActivLine := TempWhseActivLine;
        WhseActivLine."No." := WhseActivHeader."No.";
        if not (WhseActivLine."Whse. Document Type" in [
                                                        WhseActivLine."Whse. Document Type"::"Internal Pick",
                                                        WhseActivLine."Whse. Document Type"::"Movement Worksheet"])
        then
            WhseActivLine."Source Document" := WhseMgt.GetWhseActivSourceDocument(WhseActivLine."Source Type", WhseActivLine."Source Subtype");

        IsHandled := false;
        OnBeforeCreateWhseDocTakeLine(WhseActivLine, Location, IsHandled);
        if not IsHandled then
            if Location."Bin Mandatory" and (not WhseItemTrackingSetup."Serial No. Required") then
                CreateWhseDocTakeLine(WhseActivLine, LineNo)
            else
                TempWhseActivLine.Delete();

        if WhseActivLine."Qty. (Base)" <> 0 then begin
            WhseActivLine."Line No." := LineNo;
            ProcessDoNotFillQtytoHandle(WhseActivLine);
            OnBeforeWhseActivLineInsert(WhseActivLine, WhseActivHeader);
            WhseActivLine.Insert();
            OnAfterWhseActivLineInsert(WhseActivLine);
        end;

        if Location."Bin Mandatory" then
            CreateWhseDocPlaceLine(WhseActivLine.Quantity, WhseActivLine."Qty. (Base)", LineNo);

        OnAfterCreateWhseDocLine(WhseActivLine);
    end;

    local procedure CreateWhseDocTakeLine(var WhseActivLine: Record "Warehouse Activity Line"; var LineNo: Integer)
    var
        WhseActivLine2: Record "Warehouse Activity Line";
        TempWhseActivLine2: Record "Warehouse Activity Line" temporary;
        WhseActivLine3: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateWhseDocTakeLineProcedure(WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        TempWhseActivLine2.Copy(TempWhseActivLine);
        TempWhseActivLine.SetCurrentKey(
          "Whse. Document No.", "Whse. Document Type", "Activity Type", "Whse. Document Line No.", "Action Type");
        TempWhseActivLine.Delete();

        TempWhseActivLine.SetRange("Whse. Document Type", TempWhseActivLine2."Whse. Document Type");
        TempWhseActivLine.SetRange("Whse. Document No.", TempWhseActivLine2."Whse. Document No.");
        TempWhseActivLine.SetRange("Activity Type", TempWhseActivLine2."Activity Type");
        TempWhseActivLine.SetRange("Whse. Document Line No.", TempWhseActivLine2."Whse. Document Line No.");
        TempWhseActivLine.SetRange("Action Type", TempWhseActivLine2."Action Type"::Take);
        TempWhseActivLine.SetSourceFilter(
          TempWhseActivLine2."Source Type", TempWhseActivLine2."Source Subtype", TempWhseActivLine2."Source No.",
          TempWhseActivLine2."Source Line No.", TempWhseActivLine2."Source Subline No.", false);
        TempWhseActivLine.SetRange("No.", TempWhseActivLine2."No.");
        TempWhseActivLine.SetFilter("Line No.", '>%1', TempWhseActivLine2."Line No.");
        TempWhseActivLine.SetRange("Bin Code", TempWhseActivLine2."Bin Code");
        TempWhseActivLine.SetRange("Unit of Measure Code", WhseActivLine."Unit of Measure Code");
        TempWhseActivLine.SetRange("Zone Code");
        TempWhseActivLine.SetRange("Breakbulk No.", 0);
        TempWhseActivLine.SetTrackingFilterFromWhseActivityLine(TempWhseActivLine2);
        OnCreateWhseDocTakeLineOnAfterSetFilters(TempWhseActivLine, TempWhseActivLine2, WhseActivLine);
        if TempWhseActivLine.Find('-') then begin
            repeat
                WhseActivLine.Quantity := WhseActivLine.Quantity + TempWhseActivLine.Quantity;
            until TempWhseActivLine.Next() = 0;
            TempWhseActivLine.DeleteAll();
            WhseActivLine.Validate(Quantity);
        end;

        // insert breakbulk lines
        if Location."Directed Put-away and Pick" then begin
            TempWhseActivLine.ClearSourceFilter();
            TempWhseActivLine.SetRange("Line No.");
            TempWhseActivLine.SetRange("Unit of Measure Code");
            TempWhseActivLine.SetFilter("Breakbulk No.", '<>0');
            if TempWhseActivLine.Find('-') then
                repeat
                    WhseActivLine2.Init();
                    WhseActivLine2 := TempWhseActivLine;
                    WhseActivLine2."No." := WhseActivHeader."No.";
                    WhseActivLine2."Line No." := LineNo;
                    WhseActivLine2."Source Document" := WhseActivLine."Source Document";

                    ProcessDoNotFillQtytoHandle(WhseActivLine2);
                    OnCreateWhseDocTakeLineOnBeforeWhseActivLineInsert(WhseActivLine2, WhseActivHeader, TempWhseActivLine);
                    WhseActivLine2.Insert();
                    OnAfterWhseActivLineInsert(WhseActivLine2);

                    TempWhseActivLine.Delete();
                    LineNo := LineNo + 10000;

                    WhseActivLine3.Copy(TempWhseActivLine);
                    TempWhseActivLine.SetRange("Action Type", TempWhseActivLine."Action Type"::Place);
                    TempWhseActivLine.SetRange("Line No.");
                    TempWhseActivLine.SetRange("Breakbulk No.", TempWhseActivLine."Breakbulk No.");
                    TempWhseActivLine.Find('-');

                    WhseActivLine2.Init();
                    WhseActivLine2 := TempWhseActivLine;
                    WhseActivLine2."No." := WhseActivHeader."No.";
                    WhseActivLine2."Line No." := LineNo;
                    WhseActivLine2."Source Document" := WhseActivLine."Source Document";

                    ProcessDoNotFillQtytoHandle(WhseActivLine2);

                    WhseActivLine2."Original Breakbulk" :=
                      WhseActivLine."Qty. (Base)" = WhseActivLine2."Qty. (Base)";
                    if CreatePickParameters."Breakbulk Filter" then
                        WhseActivLine2.Breakbulk := WhseActivLine2."Original Breakbulk";
                    OnCreateWhseDocTakeLineOnBeforeWhseActivLine2Insert(WhseActivLine2, WhseActivHeader, TempWhseActivLine);
                    WhseActivLine2.Insert();
                    OnAfterWhseActivLineInsert(WhseActivLine2);

                    TempWhseActivLine.Delete();
                    LineNo := LineNo + 10000;

                    TempWhseActivLine.Copy(WhseActivLine3);
                    WhseActivLine."Original Breakbulk" := WhseActivLine2."Original Breakbulk";
                    if CreatePickParameters."Breakbulk Filter" then
                        WhseActivLine.Breakbulk := WhseActivLine."Original Breakbulk";
                until TempWhseActivLine.Next() = 0;
        end;

        TempWhseActivLine.Copy(TempWhseActivLine2);
    end;

    local procedure CreateWhseDocPlaceLine(PickQty: Decimal; PickQtyBase: Decimal; var LineNo: Integer)
    var
        WhseActivLine: Record "Warehouse Activity Line";
        TempWhseActivLine2: Record "Warehouse Activity Line" temporary;
        TempWhseActivLine3: Record "Warehouse Activity Line" temporary;
    begin
        TempWhseActivLine2.Copy(TempWhseActivLine);
        TempWhseActivLine.SetCurrentKey(
          "Whse. Document No.", "Whse. Document Type", "Activity Type", "Whse. Document Line No.", "Action Type");
        TempWhseActivLine.SetRange("Whse. Document No.", TempWhseActivLine2."Whse. Document No.");
        TempWhseActivLine.SetRange("Whse. Document Type", TempWhseActivLine2."Whse. Document Type");
        TempWhseActivLine.SetRange("Activity Type", TempWhseActivLine2."Activity Type");
        TempWhseActivLine.SetRange("Whse. Document Line No.", TempWhseActivLine2."Whse. Document Line No.");
        TempWhseActivLine.SetRange("Source Subline No.", TempWhseActivLine2."Source Subline No.");
        TempWhseActivLine.SetRange("No.", TempWhseActivLine2."No.");
        TempWhseActivLine.SetRange("Action Type", TempWhseActivLine2."Action Type"::Place);
        TempWhseActivLine.SetFilter("Line No.", '>%1', TempWhseActivLine2."Line No.");
        TempWhseActivLine.SetRange("Bin Code");
        TempWhseActivLine.SetRange("Zone Code");
        TempWhseActivLine.SetRange("Item No.", TempWhseActivLine2."Item No.");
        TempWhseActivLine.SetRange("Variant Code", TempWhseActivLine2."Variant Code");
        TempWhseActivLine.SetRange("Breakbulk No.", 0);
        TempWhseActivLine.SetTrackingFilterFromWhseActivityLine(TempWhseActivLine2);
        OnCreateWhseDocPlaceLineOnAfterSetFilters(TempWhseActivLine, TempWhseActivLine2, LineNo);
        if TempWhseActivLine.Find('-') then
            repeat
                LineNo := LineNo + 10000;
                WhseActivLine.Init();
                WhseActivLine := TempWhseActivLine;
                OnCreateWhseDocPlaceLineOnAfterTransferTempWhseActivLineToWhseActivLine(WhseActivLine, TempWhseActivLine, PickQty, PickQtyBase);

                with WhseActivLine do
                    if (PickQty * "Qty. per Unit of Measure") <> PickQtyBase then
                        PickQty := UOMMgt.RoundQty(PickQtyBase / "Qty. per Unit of Measure", "Qty. Rounding Precision");

                PickQtyBase := PickQtyBase - WhseActivLine."Qty. (Base)";
                PickQty := PickQty - WhseActivLine.Quantity;

                WhseActivLine."No." := WhseActivHeader."No.";
                WhseActivLine."Line No." := LineNo;

                if not (WhseActivLine."Whse. Document Type" in [
                                                                WhseActivLine."Whse. Document Type"::"Internal Pick",
                                                                WhseActivLine."Whse. Document Type"::"Movement Worksheet"])
                then
                    WhseActivLine."Source Document" := WhseMgt.GetWhseActivSourceDocument(WhseActivLine."Source Type", WhseActivLine."Source Subtype");

                TempWhseActivLine.Delete();
                if PickQtyBase > 0 then begin
                    TempWhseActivLine3.Copy(TempWhseActivLine);
                    TempWhseActivLine.SetRange(
                      "Unit of Measure Code", WhseActivLine."Unit of Measure Code");
                    TempWhseActivLine.SetFilter("Line No.", '>%1', TempWhseActivLine."Line No.");
                    TempWhseActivLine.SetRange("No.", TempWhseActivLine2."No.");
                    TempWhseActivLine.SetRange("Bin Code", WhseActivLine."Bin Code");
                    OnCreateWhseDocPlaceLineOnAfterTempWhseActivLineSetFilters(TempWhseActivLine, WhseActivLine);
                    if TempWhseActivLine.Find('-') then begin
                        repeat
                            if TempWhseActivLine."Qty. (Base)" >= PickQtyBase then begin
                                WhseActivLine.Quantity := WhseActivLine.Quantity + PickQty;
                                WhseActivLine."Qty. (Base)" := WhseActivLine."Qty. (Base)" + PickQtyBase;
                                TempWhseActivLine.Quantity -= PickQty;
                                TempWhseActivLine."Qty. (Base)" -= PickQtyBase;
                                TempWhseActivLine.Modify();
                                PickQty := 0;
                                PickQtyBase := 0;
                            end else begin
                                WhseActivLine.Quantity := WhseActivLine.Quantity + TempWhseActivLine.Quantity;
                                WhseActivLine."Qty. (Base)" := WhseActivLine."Qty. (Base)" + TempWhseActivLine."Qty. (Base)";
                                PickQty := PickQty - TempWhseActivLine.Quantity;
                                PickQtyBase := PickQtyBase - TempWhseActivLine."Qty. (Base)";
                                TempWhseActivLine.Delete();
                            end;
                        until (TempWhseActivLine.Next() = 0) or (PickQtyBase = 0);
                    end else
                        if TempWhseActivLine.Delete() then;
                    TempWhseActivLine.Copy(TempWhseActivLine3);
                end;

                if WhseActivLine.Quantity > 0 then begin
                    TempWhseActivLine3 := WhseActivLine;
                    ValidateWhseActivLineQtyFIeldsFromCreateWhseDocPlaceLine(WhseActivLine, TempWhseActivLine3);

                    ProcessDoNotFillQtytoHandle(WhseActivLine);
                    OnCreateWhseDocPlaceLineOnBeforeWhseActivLineInsert(WhseActivLine);
                    WhseActivLine.Insert();
                    OnAfterWhseActivLineInsert(WhseActivLine);
                end;
            until (TempWhseActivLine.Next() = 0) or (PickQtyBase = 0);

        TempWhseActivLine.Copy(TempWhseActivLine2);
    end;

    local procedure ProcessDoNotFillQtytoHandle(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        if CreatePickParameters."Do Not Fill Qty. to Handle" then begin
            WarehouseActivityLine."Qty. to Handle" := 0;
            WarehouseActivityLine."Qty. to Handle (Base)" := 0;
            WarehouseActivityLine.Cubage := 0;
            WarehouseActivityLine.Weight := 0;
        end;

        OnAfterProcessDoNotFillQtytoHandle(WarehouseActivityLine, TempWhseActivLine);
    end;

    local procedure ValidateWhseActivLineQtyFIeldsFromCreateWhseDocPlaceLine(var WhseActivLine: Record "Warehouse Activity Line"; TempWhseActivLine3: Record "Warehouse Activity Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateWhseActivLineQtyFIeldsFromCreateWhseDocPlaceLine(WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        WhseActivLine.Validate(Quantity);
        WhseActivLine."Qty. (Base)" := TempWhseActivLine3."Qty. (Base)";
        WhseActivLine."Qty. Outstanding (Base)" := TempWhseActivLine3."Qty. (Base)";
        WhseActivLine."Qty. to Handle (Base)" := TempWhseActivLine3."Qty. (Base)";
    end;

    local procedure AssignSpecEquipment(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]): Code[10]
    begin
        if (BinCode <> '') and
           (Location."Special Equipment" =
            Location."Special Equipment"::"According to Bin")
        then begin
            GetBin(LocationCode, BinCode);
            if Bin."Special Equipment Code" <> '' then
                exit(Bin."Special Equipment Code");

            GetSKU(LocationCode, ItemNo, VariantCode);
            if SKU."Special Equipment Code" <> '' then
                exit(SKU."Special Equipment Code");

            GetItem(ItemNo);
            exit(Item."Special Equipment Code");
        end;
        GetSKU(LocationCode, ItemNo, VariantCode);
        if SKU."Special Equipment Code" <> '' then
            exit(SKU."Special Equipment Code");

        GetItem(ItemNo);
        if Item."Special Equipment Code" <> '' then
            exit(Item."Special Equipment Code");

        GetBin(LocationCode, BinCode);
        exit(Bin."Special Equipment Code");
    end;

    local procedure CalcAvailableQty(ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        AvailableQtyBase: Decimal;
        LineReservedQty: Decimal;
        QtyReservedOnPickShip: Decimal;
        QtyOnDedicatedBins: Decimal;
        WhseSource2: Option;
    begin
        // For locations with pick/ship and without directed put-away and pick
        GetItem(ItemNo);
        AvailableQtyBase := WhseAvailMgt.CalcInvtAvailQty(Item, Location, VariantCode, TempWhseActivLine);
        OnCalcAvailableQtyOnAfterCalcAvailableQtyBase(Item, Location, VariantCode, SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, AvailableQtyBase);

        if (CreatePickParameters."Whse. Document" = CreatePickParameters."Whse. Document"::Shipment) and WhseShptLine."Assemble to Order" then
            WhseSource2 := CreatePickParameters."Whse. Document"::Assembly
        else
            WhseSource2 := CreatePickParameters."Whse. Document";

        case WhseSource2 of
            CreatePickParameters."Whse. Document"::"Pick Worksheet",
            CreatePickParameters."Whse. Document"::"Movement Worksheet":
                LineReservedQty :=
                  WhseAvailMgt.CalcLineReservedQtyOnInvt(
                    WhseWkshLine."Source Type", WhseWkshLine."Source Subtype", WhseWkshLine."Source No.",
                    WhseWkshLine."Source Line No.", WhseWkshLine."Source Subline No.", true, TempWhseActivLine);
            CreatePickParameters."Whse. Document"::Shipment:
                LineReservedQty :=
                  WhseAvailMgt.CalcLineReservedQtyOnInvt(
                    WhseShptLine."Source Type", WhseShptLine."Source Subtype", WhseShptLine."Source No.",
                    WhseShptLine."Source Line No.", 0, true, TempWhseActivLine);
            CreatePickParameters."Whse. Document"::Production:
                LineReservedQty :=
                  WhseAvailMgt.CalcLineReservedQtyOnInvt(
                    DATABASE::"Prod. Order Component", ProdOrderCompLine.Status.AsInteger(), ProdOrderCompLine."Prod. Order No.",
                    ProdOrderCompLine."Prod. Order Line No.", ProdOrderCompLine."Line No.", true, TempWhseActivLine);
            CreatePickParameters."Whse. Document"::Assembly:
                LineReservedQty :=
                  WhseAvailMgt.CalcLineReservedQtyOnInvt(
                    DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.",
                    AssemblyLine."Line No.", 0, true, TempWhseActivLine);
            CreatePickParameters."Whse. Document"::Job:
                LineReservedQty :=
                  WhseAvailMgt.CalcLineReservedQtyOnInvt(
                    Database::Job, "Job Planning Line Status"::Order.AsInteger(), JobPlanningLine."Job No.",
                    JobPlanningLine."Job Contract Entry No.",
                    JobPlanningLine."Line No.", true, TempWhseActivLine);
        end;

        QtyReservedOnPickShip := WhseAvailMgt.CalcReservQtyOnPicksShips(Location.Code, ItemNo, VariantCode, TempWhseActivLine);
        QtyOnDedicatedBins := WhseAvailMgt.CalcQtyOnDedicatedBins(Location.Code, ItemNo, VariantCode);

        exit(AvailableQtyBase + LineReservedQty + QtyReservedOnPickShip - QtyOnDedicatedBins);
    end;

    local procedure CalcPickQtyAssigned(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; BinCode: Code[20]; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary) PickQtyAssigned: Decimal
    var
        WhseActivLine2: Record "Warehouse Activity Line";
    begin
        WhseActivLine2.Copy(TempWhseActivLine);
        with TempWhseActivLine do begin
            Reset();
            SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Action Type", "Variant Code",
              "Unit of Measure Code", "Breakbulk No.", "Activity Type", "Lot No.", "Serial No.");
            SetRange("Item No.", ItemNo);
            SetRange("Location Code", LocationCode);
            if Location."Bin Mandatory" then begin
                SetRange("Action Type", "Action Type"::Take);
                if BinCode <> '' then
                    SetRange("Bin Code", BinCode)
                else
                    SetFilter("Bin Code", '<>%1', '');
            end else begin
                SetRange("Action Type", "Action Type"::" ");
                SetRange("Bin Code", '');
            end;
            SetRange("Variant Code", VariantCode);
            if UOMCode <> '' then
                SetRange("Unit of Measure Code", UOMCode);
            SetRange("Activity Type", "Activity Type");
            SetRange("Breakbulk No.", 0);
            if WhseItemTrkgExists then
                SetTrackingFilterFromWhseItemTrackingLineIfNotBlank(TempWhseItemTrackingLine);
            OnCalcQtyOutstandingBaseAfterSetFilters(TempWhseActivLine, TempWhseItemTrackingLine, LocationCode, ItemNo, VariantCode, UOMCode, BinCode);
            CalcSums("Qty. Outstanding (Base)");
            PickQtyAssigned := "Qty. Outstanding (Base)";
        end;
        TempWhseActivLine.Copy(WhseActivLine2);
        exit(PickQtyAssigned);
    end;

    local procedure CalcQtyAssignedToPick(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; BinCode: Code[20]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        with WhseActivLine do begin
            Reset();
            SetCurrentKey(
              "Item No.", "Location Code", "Activity Type", "Bin Type Code",
              "Unit of Measure Code", "Variant Code", "Breakbulk No.", "Action Type");

            SetRange("Item No.", ItemNo);
            SetRange("Location Code", LocationCode);
            SetRange("Activity Type", "Activity Type"::Pick);
            SetRange("Variant Code", VariantCode);
            SetRange("Breakbulk No.", 0);
            SetFilter("Action Type", '%1|%2', "Action Type"::" ", "Action Type"::Take);
            SetFilter("Bin Code", BinCode);
            SetTrackingFilterFromWhseItemTrackingSetupIfNotBlank(WhseItemTrackingSetup);
            OnCalcQtyAssignedToPickOnAfterSetFilters(WhseActivLine, WhseItemTrackingSetup);
            CalcSums("Qty. Outstanding (Base)");

            exit("Qty. Outstanding (Base)" + CalcBreakbulkOutstdQty(WhseActivLine, WhseItemTrackingSetup));
        end;
    end;

    local procedure UseForPick(FromBinContent: Record "Bin Content") IsForPick: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUseForPick(FromBinContent, IsForPick, IsHandled);
        if IsHandled then
            exit(IsForPick);

        with FromBinContent do begin
            if "Block Movement" in ["Block Movement"::Outbound, "Block Movement"::All] then
                exit(false);

            GetBinType("Bin Type Code");
            exit(BinType.Pick);
        end;
    end;

    local procedure UseForReplenishment(FromBinContent: Record "Bin Content"): Boolean
    begin
        with FromBinContent do begin
            if "Block Movement" in ["Block Movement"::Outbound, "Block Movement"::All] then
                exit(false);

            GetBinType("Bin Type Code");
            exit(not (BinType.Receive or BinType.Ship));
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location := WhseSetupLocation
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);

        OnAfterGetLocation(LocationCode);
    end;

    local procedure GetBinType(BinTypeCode: Code[10])
    begin
        if BinTypeCode = '' then
            BinType.Init()
        else
            if BinType.Code <> BinTypeCode then
                BinType.Get(BinTypeCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (Bin."Location Code" <> LocationCode) or
           (Bin.Code <> BinCode)
        then
            if not Bin.Get(LocationCode, BinCode) then
                Clear(Bin);
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if Item."No." <> ItemNo then
            Item.Get(ItemNo);
    end;

    local procedure GetSKU(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Boolean
    begin
        if (SKU."Location Code" <> LocationCode) or
           (SKU."Item No." <> ItemNo) or
           (SKU."Variant Code" <> VariantCode)
        then
            if not SKU.Get(LocationCode, ItemNo, VariantCode) then begin
                Clear(SKU);
                exit(false)
            end;
        exit(true);
    end;

    procedure SetParameters(NewCreatePickParameters: Record "Create Pick Parameters")
    begin
        CreatePickParameters := NewCreatePickParameters;
        if CreatePickParameters."Per Bin" then
            CreatePickParameters."Per Zone" := false
        else
            CreatePickParameters."Per Zone" := NewCreatePickParameters."Per Zone";
        WhseSetup.Get();
        WhseSetupLocation.GetLocationSetup('', WhseSetupLocation);
        Clear(TempWhseActivLine);
        LastWhseItemTrkgLineNo := 0;
        IsMovementWorksheet := CreatePickParameters."Whse. Document" = CreatePickParameters."Whse. Document"::"Movement Worksheet";

        OnAfterSetParameters(CreatePickParameters);
    end;

    procedure SetWhseWkshLine(WhseWkshLine2: Record "Whse. Worksheet Line"; TempNo2: Integer)
    begin
        WhseWkshLine := WhseWkshLine2;
        TempNo := TempNo2;
        SetSource(
            WhseWkshLine2."Source Type", WhseWkshLine2."Source Subtype", WhseWkshLine2."Source No.",
            WhseWkshLine2."Source Line No.", WhseWkshLine2."Source Subline No.");

        OnAfterSetWhseWkshLine(WhseWkshLine);
    end;

    procedure SetWhseShipment(WhseShptLine2: Record "Warehouse Shipment Line"; TempNo2: Integer; ShippingAgentCode2: Code[10]; ShippingAgentServiceCode2: Code[10]; ShipmentMethodCode2: Code[10])
    begin
        WhseShptLine := WhseShptLine2;
        TempNo := TempNo2;
        ShippingAgentCode := ShippingAgentCode2;
        ShippingAgentServiceCode := ShippingAgentServiceCode2;
        ShipmentMethodCode := ShipmentMethodCode2;
        SetSource(WhseShptLine2."Source Type", WhseShptLine2."Source Subtype", WhseShptLine2."Source No.", WhseShptLine2."Source Line No.", 0);

        OnAfterSetWhseShipment(WhseShptLine, TempNo2, ShippingAgentCode2, ShippingAgentServiceCode2, ShipmentMethodCode2);
    end;

    procedure SetWhseInternalPickLine(WhseInternalPickLine2: Record "Whse. Internal Pick Line"; TempNo2: Integer)
    begin
        WhseInternalPickLine := WhseInternalPickLine2;
        TempNo := TempNo2;

        OnAfterSetWhseInternalPickLine(WhseInternalPickLine);
    end;

    procedure SetProdOrderCompLine(ProdOrderCompLine2: Record "Prod. Order Component"; TempNo2: Integer)
    begin
        ProdOrderCompLine := ProdOrderCompLine2;
        TempNo := TempNo2;
        SetSource(
            DATABASE::"Prod. Order Component", ProdOrderCompLine2.Status.AsInteger(), ProdOrderCompLine2."Prod. Order No.",
            ProdOrderCompLine2."Prod. Order Line No.", ProdOrderCompLine2."Line No.");

        OnAfterSetProdOrderCompLine(ProdOrderCompLine);
    end;

    procedure SetAssemblyLine(AssemblyLine2: Record "Assembly Line"; TempNo2: Integer)
    begin
        AssemblyLine := AssemblyLine2;
        TempNo := TempNo2;
        SetSource(DATABASE::"Assembly Line", AssemblyLine2."Document Type".AsInteger(), AssemblyLine2."Document No.", AssemblyLine2."Line No.", 0);

        OnAfterSetAssemblyLine(AssemblyLine);
    end;

    procedure SetJobPlanningLine(JobPlanningLine2: Record "Job Planning Line")
    begin
        JobPlanningLine := JobPlanningLine2;
        TempNo := 1;
        SetSource(
          DATABASE::"Job Planning Line", "Job Planning Line Status"::Order.AsInteger(),
          JobPlanningLine2."Job No.", JobPlanningLine2."Job Contract Entry No.", JobPlanningLine2."Line No.");
    end;

    procedure SetTempWhseItemTrkgLine(SourceID: Code[20]; SourceType: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; LocationCode: Code[10])
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        TempWhseItemTrackingLine.DeleteAll();
        TempWhseItemTrackingLine.Init();
        WhseItemTrkgLineCount := 0;
        WhseItemTrkgExists := false;
        WhseItemTrackingLine.Reset();
        WhseItemTrackingLine.SetCurrentKey(
          "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
          "Source Prod. Order Line", "Source Ref. No.", "Location Code");
        WhseItemTrackingLine.SetRange("Source ID", SourceID);
        WhseItemTrackingLine.SetRange("Source Type", SourceType);
        WhseItemTrackingLine.SetRange("Source Batch Name", SourceBatchName);
        WhseItemTrackingLine.SetRange("Source Prod. Order Line", SourceProdOrderLine);
        WhseItemTrackingLine.SetRange("Source Ref. No.", SourceRefNo);
        WhseItemTrackingLine.SetRange("Location Code", LocationCode);
        if WhseItemTrackingLine.Find('-') then
            repeat
                if WhseItemTrackingLine."Qty. to Handle (Base)" > 0 then
                    CopyToTempWhseItemTrkgLine(WhseItemTrackingLine);
            until WhseItemTrackingLine.Next() = 0;

        OnAfterCreateTempWhseItemTrackingLines(TempWhseItemTrackingLine);

        SetSourceWhseItemTrkgLine(SourceID, SourceType, SourceBatchName, SourceProdOrderLine, SourceRefNo);
    end;

    procedure SetTempWhseItemTrkgLineFromBuffer(var TempWhseItemTrackingLineBuffer: Record "Whse. Item Tracking Line" temporary; SourceID: Code[20]; SourceType: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; LocationCode: Code[10])
    begin
        TempWhseItemTrackingLine.DeleteAll();
        TempWhseItemTrackingLine.Init();
        WhseItemTrkgLineCount := 0;
        WhseItemTrkgExists := false;

        TempWhseItemTrackingLineBuffer.Reset();
        TempWhseItemTrackingLineBuffer.SetSourceFilter(SourceType, 0, SourceID, SourceRefNo, true);
        TempWhseItemTrackingLineBuffer.SetSourceFilter(SourceBatchName, SourceProdOrderLine);
        TempWhseItemTrackingLineBuffer.SetRange("Location Code", LocationCode);
        if TempWhseItemTrackingLineBuffer.FindSet() then
            repeat
                CopyToTempWhseItemTrkgLine(TempWhseItemTrackingLineBuffer);
            until TempWhseItemTrackingLineBuffer.Next() = 0;

        SetSourceWhseItemTrkgLine(SourceID, SourceType, SourceBatchName, SourceProdOrderLine, SourceRefNo);
    end;

    local procedure CopyToTempWhseItemTrkgLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyToTempWhseItemTrkgLine(WhseItemTrackingLine, IsHandled);
        if IsHandled then
            exit;

        with TempWhseItemTrackingLine do begin
            TempWhseItemTrackingLine := WhseItemTrackingLine;
            "Entry No." := LastWhseItemTrkgLineNo + 1;
            OnCopyToTempWhseItemTrkgLineOnBeforeTempWhseItemTrackingLineInsert(TempWhseItemTrackingLine);
            TempWhseItemTrackingLine.Insert();
            LastWhseItemTrkgLineNo := "Entry No.";
            WhseItemTrkgExists := true;
            WhseItemTrkgLineCount += 1;
        end;
    end;

    local procedure SetSourceWhseItemTrkgLine(SourceID: Code[20]; SourceType: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer)
    begin
        SourceWhseItemTrackingLine.Init();
        SourceWhseItemTrackingLine."Source Type" := SourceType;
        SourceWhseItemTrackingLine."Source ID" := SourceID;
        SourceWhseItemTrackingLine."Source Batch Name" := SourceBatchName;
        SourceWhseItemTrackingLine."Source Prod. Order Line" := SourceProdOrderLine;
        SourceWhseItemTrackingLine."Source Ref. No." := SourceRefNo;

        OnAfterSetSourceWhseItemTrkgLine(TempWhseItemTrackingLine, LastWhseItemTrkgLineNo);
    end;

    procedure SaveTempItemTrkgLines()
    var
        i: Integer;
    begin
        if WhseItemTrkgLineCount = 0 then
            exit;

        i := 0;
        TempWhseItemTrackingLine.Reset();
        if TempWhseItemTrackingLine.Find('-') then
            repeat
                TempTotalWhseItemTrackingLine := TempWhseItemTrackingLine;
                TempTotalWhseItemTrackingLine.Insert();
                i += 1;
            until (TempWhseItemTrackingLine.Next() = 0) or (i = WhseItemTrkgLineCount);
    end;

    procedure ReturnTempItemTrkgLines(var TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary)
    begin
        if TempTotalWhseItemTrackingLine.Find('-') then
            repeat
                TempWhseItemTrackingLine2 := TempTotalWhseItemTrackingLine;
                TempWhseItemTrackingLine2.Insert();
            until TempTotalWhseItemTrackingLine.Next() = 0;
    end;

    local procedure CreateTempItemTrkgLines(ItemNo: Code[20]; VariantCode: Code[10]; TotalQtyToPickBase: Decimal; HasExpiryDate: Boolean)
    var
        EntrySummary: Record "Entry Summary";
        DummyEntrySummary2: Record "Entry Summary";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        WhseItemTrackingFEFO: Codeunit "Whse. Item Tracking FEFO";
        TotalAvailQtyToPickBase: Decimal;
        RemQtyToPickBase: Decimal;
        QtyToPickBase: Decimal;
        QtyTracked: Decimal;
        FromBinContentQty: Decimal;
        QtyCanBePicked: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempItemTrkgLines(Location, ItemNo, VariantCode, TotalQtyToPickBase, HasExpiryDate, IsHandled, WhseItemTrackingFEFO, WhseShptLine, WhseWkshLine);
        if IsHandled then
            exit;

        if not HasExpiryDate then
            if TotalQtyToPickBase <= 0 then
                exit;

        WhseItemTrackingFEFO.SetSource(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo);
        WhseItemTrackingFEFO.SetCalledFromMovementWksh(CalledFromMoveWksh);
        WhseItemTrackingFEFO.CreateEntrySummaryFEFO(Location, ItemNo, VariantCode, HasExpiryDate);

        RemQtyToPickBase := TotalQtyToPickBase;
        if HasExpiryDate then
            TransferRemQtyToPickBase := TotalQtyToPickBase;
        if WhseItemTrackingFEFO.FindFirstEntrySummaryFEFO(EntrySummary) then begin
            ReqFEFOPick := true;
            repeat
                if ((EntrySummary."Expiration Date" <> 0D) and HasExpiryDate) or
                   ((EntrySummary."Expiration Date" = 0D) and (not HasExpiryDate))
                then begin
                    WhseItemTrackingSetup.CopyTrackingFromEntrySummary(EntrySummary);
                    QtyTracked := ItemTrackedQuantity(WhseItemTrackingSetup);
                    OnCreateTempItemTrkgLinesOnAfterCalcQtyTracked(EntrySummary, TempWhseItemTrackingLine, QtyTracked);

                    if not ((EntrySummary."Serial No." <> '') and (QtyTracked > 0)) then begin
                        WhseItemTrackingLine.CopyTrackingFromEntrySummary(EntrySummary);
                        TotalAvailQtyToPickBase :=
                            CalcTotalAvailQtyToPick(
                                Location.Code, ItemNo, VariantCode, WhseItemTrackingLine,
                                SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, 0, HasExpiryDate);

                        OnCreateTempItemTrkgLinesOnBeforeGetFromBinContentQty(EntrySummary, ItemNo, VariantCode, TotalAvailQtyToPickBase);
                        if CalledFromWksh and (WhseWkshLine."From Bin Code" <> '') then begin
                            FromBinContentQty :=
                                GetFromBinContentQty(
                                    WhseWkshLine."Location Code", WhseWkshLine."From Bin Code", WhseWkshLine."Item No.",
                                    WhseWkshLine."Variant Code", WhseWkshLine."From Unit of Measure Code", WhseItemTrackingLine);
                            if TotalAvailQtyToPickBase > FromBinContentQty then
                                TotalAvailQtyToPickBase := FromBinContentQty;
                        end;

                        QtyCanBePicked :=
                            CalcQtyCanBePicked(Location.Code, ItemNo, VariantCode, EntrySummary, CalledFromMoveWksh);
                        TotalAvailQtyToPickBase := Minimum(TotalAvailQtyToPickBase, QtyCanBePicked);

                        TotalAvailQtyToPickBase := TotalAvailQtyToPickBase - QtyTracked;
                        QtyToPickBase := 0;

                        OnBeforeInsertTempItemTrkgLine(EntrySummary, RemQtyToPickBase, TotalAvailQtyToPickBase);

                        if TotalAvailQtyToPickBase > 0 then
                            if TotalAvailQtyToPickBase >= RemQtyToPickBase then begin
                                QtyToPickBase := RemQtyToPickBase;
                                RemQtyToPickBase := 0
                            end else begin
                                QtyToPickBase := TotalAvailQtyToPickBase;
                                RemQtyToPickBase := RemQtyToPickBase - QtyToPickBase;
                            end;

                        OnCreateTempItemTrkgLinesOnBeforeCheckQtyToPickBase(EntrySummary, ItemNo, VariantCode, Location.Code, TotalAvailQtyToPickBase, QtyToPickBase);
                        if QtyToPickBase > 0 then
                            InsertTempItemTrkgLine(Location.Code, ItemNo, VariantCode, EntrySummary, QtyToPickBase);
                    end;
                end;
            until not WhseItemTrackingFEFO.FindNextEntrySummaryFEFO(EntrySummary) or (RemQtyToPickBase = 0);
            if HasExpiryDate then
                TransferRemQtyToPickBase := RemQtyToPickBase;
        end;
        if not HasExpiryDate then
            if RemQtyToPickBase > 0 then
                if Location."Always Create Pick Line" then
                    InsertTempItemTrkgLine(Location.Code, ItemNo, VariantCode, DummyEntrySummary2, RemQtyToPickBase);
        if not HasExpiredItems then begin
            HasExpiredItems := WhseItemTrackingFEFO.GetHasExpiredItems();
            EnqueueCannotBeHandledReason(WhseItemTrackingFEFO.GetResultMessageForExpiredItem());
        end;
    end;

    procedure ItemTrackedQuantity(WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        QtyToHandleBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeItemTrackedQuantity(TempWhseItemTrackingLine, WhseItemTrackingSetup, QtyToHandleBase, IsHandled);
        if IsHandled then
            exit(QtyToHandleBase);

        with TempWhseItemTrackingLine do begin
            Reset();
            if not WhseItemTrackingSetup.TrackingExists() then
                if IsEmpty() then
                    exit(0);

            if WhseItemTrackingSetup."Serial No." <> '' then begin
                SetTrackingKey();
                SetRange("Serial No.", WhseItemTrackingSetup."Serial No.");
                if IsEmpty() then
                    exit(0);

                exit(1);
            end;

            if WhseItemTrackingSetup."Lot No." <> '' then begin
                SetTrackingKey();
                SetRange("Lot No.", WhseItemTrackingSetup."Lot No.");
                if IsEmpty() then
                    exit(0);
            end;

            IsHandled := false;
            OnItemTrackedQuantityOnAfterCheckIfEmpty(TempWhseItemTrackingLine, WhseItemTrackingSetup, IsHandled);
            if IsHandled then
                exit(0);

            SetCurrentKey(
              "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.", "Location Code");

            if WhseItemTrackingSetup."Lot No." <> '' then
                SetRange("Lot No.", WhseItemTrackingSetup."Lot No.");
            OnItemTrackedQuantityOnAfterSetFilters(TempWhseItemTrackingLine, WhseItemTrackingSetup);
            CalcSums("Qty. to Handle (Base)");
            exit("Qty. to Handle (Base)");
        end;
    end;

    procedure InsertTempItemTrkgLine(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; EntrySummary: Record "Entry Summary"; QuantityBase: Decimal)
    begin
        with TempWhseItemTrackingLine do begin
            Init();
            "Entry No." := LastWhseItemTrkgLineNo + 1;
            "Location Code" := LocationCode;
            "Item No." := ItemNo;
            "Variant Code" := VariantCode;
            CopyTrackingFromEntrySummary(EntrySummary);
            "Expiration Date" := EntrySummary."Expiration Date";
            "Source ID" := SourceWhseItemTrackingLine."Source ID";
            "Source Type" := SourceWhseItemTrackingLine."Source Type";
            "Source Batch Name" := SourceWhseItemTrackingLine."Source Batch Name";
            "Source Prod. Order Line" := SourceWhseItemTrackingLine."Source Prod. Order Line";
            "Source Ref. No." := SourceWhseItemTrackingLine."Source Ref. No.";
            Validate("Quantity (Base)", QuantityBase);
            OnBeforeTempWhseItemTrkgLineInsert(TempWhseItemTrackingLine, SourceWhseItemTrackingLine, EntrySummary);
            Insert();
            LastWhseItemTrkgLineNo := "Entry No.";
            WhseItemTrkgExists := true;
        end;
    end;

    local procedure TransferItemTrkgFields(var WhseActivLine2: Record "Warehouse Activity Line"; TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        EntriesExist: Boolean;
    begin
        if WhseItemTrkgExists then begin
            if TempWhseItemTrackingLine."Serial No." <> '' then
                ValidateQtyForSN(TempWhseItemTrackingLine);
            WhseActivLine2.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine);
            WhseActivLine2."Warranty Date" := TempWhseItemTrackingLine."Warranty Date";
            if TempWhseItemTrackingLine.TrackingExists() then begin
                WhseActivLine2."Expiration Date" := ItemTrackingMgt.ExistingExpirationDate(WhseActivLine2, false, EntriesExist);
                if not EntriesExist then
                    WhseActivLine2."Expiration Date" := TempWhseItemTrackingLine."Expiration Date";
            end;
            OnAfterTransferItemTrkgFields(WhseActivLine2, TempWhseItemTrackingLine, EntriesExist);
        end else begin
            ItemTrackingMgt.GetWhseItemTrkgSetup(TempWhseItemTrackingLine."Item No.", WhseItemTrackingSetup);
            if WhseItemTrackingSetup."Serial No. Required" then
                WhseActivLine2.ValidateQtyWhenSNDefined();
        end;
    end;

    local procedure ValidateQtyForSN(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQtyForSN(WhseItemTrackingLine, IsHandled);
        if IsHandled then
            exit;

        if not (WhseItemTrackingLine."Quantity (Base)" in [-1, 0, 1]) then
            Error(ValidValuesIfSNDefinedErr, WhseItemTrackingLine.FieldCaption("Quantity (Base)"), WhseItemTrackingLine."Quantity (Base)");

        if not (WhseItemTrackingLine."Qty. to Handle (Base)" in [-1, 0, 1]) then
            Error(ValidValuesIfSNDefinedErr, WhseItemTrackingLine.FieldCaption("Qty. to Handle (Base)"), WhseItemTrackingLine."Qty. to Handle (Base)");
    end;

    procedure SetSource(SourceType2: Integer; SourceSubType2: Option; SourceNo2: Code[20]; SourceLineNo2: Integer; SourceSubLineNo2: Integer)
    begin
        SourceType := SourceType2;
        SourceSubType := SourceSubType2;
        SourceNo := SourceNo2;
        SourceLineNo := SourceLineNo2;
        SourceSubLineNo := SourceSubLineNo2;
    end;

    procedure CheckReservation(QtyBaseAvailToPick: Decimal; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; AlwaysCreatePickLine: Boolean; QtyPerUnitOfMeasure: Decimal; var Quantity: Decimal; var QuantityBase: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
        WhseManagement: Codeunit "Whse. Management";
        Quantity2: Decimal;
        QuantityBase2: Decimal;
        QtyBaseResvdNotOnILE: Decimal;
        QtyResvdNotOnILE: Decimal;
        SrcDocQtyBaseToBeFilledByInvt: Decimal;
        SrcDocQtyToBeFilledByInvt: Decimal;
    begin
        ReservationExists := false;
        ReservedForItemLedgEntry := false;
        Quantity2 := Quantity;
        QuantityBase2 := QuantityBase;

        SetFiltersOnReservEntry(ReservEntry, SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo);
        if ReservEntry.Find('-') then begin
            ReservationExists := true;
            repeat
                QtyResvdNotOnILE += CalcQtyResvdNotOnILE(ReservEntry."Entry No.", ReservEntry.Positive);
            until ReservEntry.Next() = 0;
            QtyBaseResvdNotOnILE := QtyResvdNotOnILE;
            QtyResvdNotOnILE := Round(QtyResvdNotOnILE / QtyPerUnitOfMeasure, UOMMgt.QtyRndPrecision());

            WhseManagement.GetOutboundDocLineQtyOtsdg(SourceType, SourceSubType,
              SourceNo, SourceLineNo, SourceSubLineNo, SrcDocQtyToBeFilledByInvt, SrcDocQtyBaseToBeFilledByInvt);
            OnCheckReservationOnAfterGetOutboundDocLineQtyOtsdg(ReservEntry, SrcDocQtyToBeFilledByInvt, SrcDocQtyBaseToBeFilledByInvt, QtyResvdNotOnILE, QtyBaseResvdNotOnILE);
            SrcDocQtyBaseToBeFilledByInvt := SrcDocQtyBaseToBeFilledByInvt - QtyBaseResvdNotOnILE;
            SrcDocQtyToBeFilledByInvt := SrcDocQtyToBeFilledByInvt - QtyResvdNotOnILE;

            if QuantityBase > SrcDocQtyBaseToBeFilledByInvt then begin
                QuantityBase := SrcDocQtyBaseToBeFilledByInvt;
                Quantity := SrcDocQtyToBeFilledByInvt;
            end;

            if QuantityBase <= SrcDocQtyBaseToBeFilledByInvt then
                if (QuantityBase > QtyBaseAvailToPick) and (QtyBaseAvailToPick >= 0) then begin
                    QuantityBase := QtyBaseAvailToPick;
                    Quantity := Round(QtyBaseAvailToPick / QtyPerUnitOfMeasure, UOMMgt.QtyRndPrecision());
                end;

            ReservedForItemLedgEntry := QuantityBase <> 0;
            if AlwaysCreatePickLine then begin
                Quantity := Quantity2;
                QuantityBase := QuantityBase2;
            end;

            if Quantity <= 0 then
                EnqueueCannotBeHandledReason(GetMessageForUnhandledQtyDueToReserv());
        end else
            ReservationExists := false;

        OnAfterCheckReservation(Quantity, QuantityBase, QtyBaseAvailToPick, ReservationExists, SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo);
    end;

    procedure CalcTotalAvailQtyToPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; NeededQtyBase: Decimal; RespectLocationBins: Boolean): Decimal
    var
        DummyWhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        exit(
            CalcTotalAvailQtyToPick(
                LocationCode, ItemNo, VariantCode, DummyWhseItemTrackingLine,
                SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, NeededQtyBase, RespectLocationBins));
    end;

    procedure CalcTotalAvailQtyToPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingLine: Record "Whse. Item Tracking Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; NeededQtyBase: Decimal; RespectLocationBins: Boolean): Decimal
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TotalAvailQtyBase: Decimal;
        QtyInWhse: Decimal;
        QtyOnPickBins: Decimal;
        QtyOnPutAwayBins: Decimal;
        QtyOnOutboundBins: Decimal;
        QtyOnReceiveBins: Decimal;
        QtyOnDedicatedBins: Decimal;
        QtyBlocked: Decimal;
        SubTotal: Decimal;
        QtyReservedOnPickShip: Decimal;
        LineReservedQty: Decimal;
        QtyAssignedPick: Decimal;
        QtyAssignedToPick: Decimal;
        AvailableAfterReshuffle: Decimal;
        QtyOnToBinsBase: Decimal;
        QtyOnToBinsBaseInPicks: Decimal;
        ReservedQtyOnInventory: Decimal;
        ResetWhseItemTrkgExists: Boolean;
        BinTypeFilter: Text[1024];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcTotalAvailQtyToPick(
          LocationCode, ItemNo, VariantCode, WhseItemTrackingLine."Lot No.", WhseItemTrackingLine."Serial No.",
          SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo,
          NeededQtyBase, RespectLocationBins, CalledFromMoveWksh, CalledFromWksh, TempWhseActivLine, IsHandled, TotalAvailQtyBase, WhseItemTrackingLine);
        if IsHandled then
            exit(TotalAvailQtyBase);

        // Directed put-away and pick
        GetLocation(LocationCode);

        ItemTrackingMgt.GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);
        OnCalcTotalAvailQtyToPickOnAfterGetWhseItemTrkgSetup(WhseItemTrackingSetup, LocationCode);
        WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine);

        ReservedQtyOnInventory :=
            CalcReservedQtyOnInventory(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup);

        QtyAssignedToPick :=
            CalcQtyAssignedToPick(ItemNo, LocationCode, VariantCode, '', WhseItemTrackingSetup);

        QtyInWhse :=
            SumWhseEntries(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, '', '', false);

        // calculate quantity in receipt area and fixed receipt bin at location
        // quantity in pick bins is considered as total quantity on the warehouse excluding receipt area and fixed receipt bin
        CalcQtyOnPickAndReceiveBins(
            QtyOnReceiveBins, QtyOnPickBins, ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, RespectLocationBins);

        OnAfterCalcQtyOnPickAndReceiveBins(
            SourceType, LocationCode, ItemNo, VariantCode, WhseItemTrackingLine."Lot No.", WhseItemTrackingLine."Serial No.",
            CalledFromPickWksh, CalledFromMoveWksh, CalledFromWksh,
            QtyInWhse, QtyOnPickBins, QtyOnPutAwayBins, QtyOnOutboundBins, QtyOnReceiveBins, QtyOnDedicatedBins, QtyBlocked);

        if CalledFromMoveWksh then begin
            BinTypeFilter := GetBinTypeFilter(4); // put-away only
            if BinTypeFilter <> '' then
                QtyOnPutAwayBins :=
                    SumWhseEntries(
                        ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, BinTypeFilter, '', false);
            if WhseWkshLine."To Bin Code" <> '' then
                if not IsShipZone(WhseWkshLine."Location Code", WhseWkshLine."To Zone Code") then begin
                    QtyOnToBinsBase :=
                        SumWhseEntries(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, '', WhseWkshLine."To Bin Code", false);
                    QtyOnToBinsBaseInPicks :=
                        CalcQtyAssignedToPick(ItemNo, LocationCode, VariantCode, WhseWkshLine."To Bin Code", WhseItemTrackingSetup);
                    QtyOnToBinsBase -= Minimum(QtyOnToBinsBase, QtyOnToBinsBaseInPicks);
                end;
        end;

        QtyOnOutboundBins := WhseAvailMgt.CalcQtyOnOutboundBins(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, true);

        QtyOnDedicatedBins := WhseAvailMgt.CalcQtyOnDedicatedBins(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup);

        QtyBlocked := WhseAvailMgt.CalcQtyOnBlockedITOrOnBlockedOutbndBins(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup);

        TempWhseItemTrackingLine2.Copy(TempWhseItemTrackingLine);
        if ReqFEFOPick then begin
            TempWhseItemTrackingLine2."Entry No." := TempWhseItemTrackingLine2."Entry No." + 1;
            TempWhseItemTrackingLine2.CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine);
            if not WhseItemTrkgExists then begin
                WhseItemTrkgExists := true;
                ResetWhseItemTrkgExists := true;
            end;
        end;

        QtyAssignedPick := CalcPickQtyAssigned(LocationCode, ItemNo, VariantCode, '', '', TempWhseItemTrackingLine2);

        if ResetWhseItemTrkgExists then begin
            WhseItemTrkgExists := false;
            ResetWhseItemTrkgExists := false;
        end;

        if Location."Always Create Pick Line" or CrossDock then begin
            FilterWhsePickLinesWithUndefinedBin(WhseActivLine, ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup);
            WhseActivLine.CalcSums("Qty. Outstanding (Base)");
            QtyAssignedPick := QtyAssignedPick - WhseActivLine."Qty. Outstanding (Base)";
        end;

        OnCalcTotalAvailQtyToPickOnBeforeCalcSubTotal(QtyInWhse, QtyOnPickBins, QtyOnPutAwayBins, QtyOnOutboundBins, QtyOnDedicatedBins, QtyBlocked, QtyOnReceiveBins, ReservedQtyOnInventory);
        SubTotal :=
          QtyInWhse - QtyOnPickBins - QtyOnPutAwayBins - QtyOnOutboundBins - QtyOnDedicatedBins - QtyBlocked -
          QtyOnReceiveBins - Abs(ReservedQtyOnInventory);

        if (SubTotal < 0) or CalledFromPickWksh or CalledFromMoveWksh then begin
            TempTrackingSpecification.CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine);
            QtyReservedOnPickShip :=
                WhseAvailMgt.CalcReservQtyOnPicksShipsWithItemTracking(TempWhseActivLine, TempTrackingSpecification, LocationCode, ItemNo, VariantCode);

            if WhseItemTrackingLine.TrackingExists() and (QtyReservedOnPickShip > 0) then
                LineReservedQty :=
                    WhseAvailMgt.CalcLineReservedQtyOnInvt(
                      SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, true, WhseItemTrackingSetup, TempWhseActivLine)
            else
                LineReservedQty :=
                    WhseAvailMgt.CalcLineReservedQtyOnInvt(
                      SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, true, TempWhseActivLine);

            AdjustQtyReservedOnPickShip(SubTotal, QtyReservedOnPickShip, LineReservedQty, ReservedQtyOnInventory);

            case true of
                CalledFromPickWksh:
                    begin
                        TotalAvailQtyBase :=
                            QtyOnPickBins - QtyAssignedToPick - Abs(ReservedQtyOnInventory) + QtyReservedOnPickShip + LineReservedQty;
                        MovementFromShipZone(TotalAvailQtyBase, QtyOnOutboundBins + QtyBlocked);
                    end;
                CalledFromMoveWksh:
                    begin
                        TotalAvailQtyBase :=
                            QtyOnPickBins + QtyOnPutAwayBins - QtyAssignedToPick;
                        if CalledFromWksh then
                            TotalAvailQtyBase := TotalAvailQtyBase - QtyAssignedPick - QtyOnPutAwayBins;
                        MovementFromShipZone(TotalAvailQtyBase, QtyOnOutboundBins + QtyBlocked);
                    end;
                else
                    TotalAvailQtyBase :=
                      QtyOnPickBins -
                      QtyAssignedPick - QtyAssignedToPick +
                      SubTotal +
                      QtyReservedOnPickShip +
                      LineReservedQty;
            end
        end else
            TotalAvailQtyBase := QtyOnPickBins - QtyAssignedPick - QtyAssignedToPick;

        if (NeededQtyBase <> 0) and (NeededQtyBase > TotalAvailQtyBase) then
            if ReleaseNonSpecificReservations(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, NeededQtyBase - TotalAvailQtyBase) then begin
                AvailableAfterReshuffle :=
                    CalcTotalAvailQtyToPick(
                        LocationCode, ItemNo, VariantCode, TempWhseItemTrackingLine,
                        SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, 0, false);
                exit(AvailableAfterReshuffle);
            end;

        exit(TotalAvailQtyBase - QtyOnToBinsBase);
    end;

    local procedure AdjustQtyReservedOnPickShip(var SubTotal: Decimal; var QtyReservedOnPickShip: Decimal; LineReservedQty: Decimal; ReservedQtyOnInventory: Decimal)
    begin
        OnBeforeAdjustQtyReservedOnPickShip(SubTotal, QtyReservedOnPickShip, LineReservedQty, ReservedQtyOnInventory);
        if SubTotal < 0 then
            if Abs(SubTotal) < QtyReservedOnPickShip + LineReservedQty then
                QtyReservedOnPickShip := Abs(SubTotal) - LineReservedQty;
    end;

    local procedure CalcQtyOnPickAndReceiveBins(var QtyOnReceiveBins: Decimal; var QtyOnPickBins: Decimal; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; RespectLocationBins: Boolean)
    var
        WhseEntry: Record "Warehouse Entry";
        BinTypeFilter: Text;
    begin
        GetLocation(LocationCode);

        WhseEntry.SetCalculationFilters(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, false);
        BinTypeFilter := GetBinTypeFilter(0);
        if BinTypeFilter <> '' then begin
            if RespectLocationBins and (Location."Receipt Bin Code" <> '') then begin
                WhseEntry.SetRange("Bin Code", Location."Receipt Bin Code");
                WhseEntry.CalcSums("Qty. (Base)");
                QtyOnReceiveBins := WhseEntry."Qty. (Base)";

                WhseEntry.SetFilter("Bin Code", '<>%1', Location."Receipt Bin Code");
            end;
            WhseEntry.SetFilter("Bin Type Code", BinTypeFilter); // Receive
            WhseEntry.CalcSums("Qty. (Base)");
            QtyOnReceiveBins += WhseEntry."Qty. (Base)";

            WhseEntry.SetFilter("Bin Type Code", '<>%1', BinTypeFilter);
        end;
        WhseEntry.CalcSums("Qty. (Base)");
        QtyOnPickBins := WhseEntry."Qty. (Base)";
    end;

    local procedure CalcQtyCanBePicked(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; EntrySummary: Record "Entry Summary"; IsMovement: Boolean): Decimal
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        BinTypeFilter: Text;
        QtyOnOutboundBins: Decimal;
    begin
        ItemTrackingMgt.GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);
        OnCalcQtyCanBePickedOnAfterGetWhseItemTrkgSetup(WhseItemTrackingSetup, LocationCode);
        WhseItemTrackingSetup.CopyTrackingFromEntrySummary(EntrySummary);

        GetLocation(LocationCode);
        if not Location."Directed Put-away and Pick" then begin
            BinTypeFilter := '';
            QtyOnOutboundBins := WhseAvailMgt.CalcQtyOnOutboundBins(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, true);
        end else
            // movement can be picked from anywhere but receive and ship zones, yet pick only takes the pick zone
            if IsMovement then begin
                BinTypeFilter := StrSubstNo('<>%1', GetBinTypeFilter(0));
                QtyOnOutboundBins := WhseAvailMgt.CalcQtyOnOutboundBins(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, true);
            end else begin
                BinTypeFilter := GetBinTypeFilter(3);
                QtyOnOutboundBins := 0;
            end;

        exit(
            SumWhseEntries(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, BinTypeFilter, '', true) - QtyOnOutboundBins);
    end;

    procedure GetBinTypeFilter(Type: Option Receive,Ship,"Put Away",Pick,"Put Away only") BinTypeFilter: Text[1024]
    var
        BinType: Record "Bin Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetBinTypeFilter(BinTypeFilter, IsHandled, Type);
        if IsHandled then
            exit(BinTypeFilter);

        with BinType do begin
            case Type of
                Type::Receive:
                    SetRange(Receive, true);
                Type::Ship:
                    SetRange(Ship, true);
                Type::"Put Away":
                    SetRange("Put Away", true);
                Type::Pick:
                    SetRange(Pick, true);
                Type::"Put Away only":
                    begin
                        SetRange("Put Away", true);
                        SetRange(Pick, false);
                    end;
            end;
            if Find('-') then
                repeat
                    BinTypeFilter := StrSubstNo('%1|%2', BinTypeFilter, Code);
                until Next() = 0;
            if BinTypeFilter <> '' then
                BinTypeFilter := CopyStr(BinTypeFilter, 2);
        end;
        exit(BinTypeFilter);
    end;

    procedure CheckOutBound(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer) OutBoundQty: Decimal
    var
        WhseShipLine: Record "Warehouse Shipment Line";
        WhseActLine: Record "Warehouse Activity Line";
        ProdOrderComp: Record "Prod. Order Component";
        AsmLine: Record "Assembly Line";
    begin
        case SourceType of
            DATABASE::"Sales Line", DATABASE::"Purchase Line", DATABASE::"Transfer Line":
                begin
                    WhseShipLine.Reset();
                    WhseShipLine.SetCurrentKey(
                      "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    WhseShipLine.SetRange("Source Type", SourceType);
                    WhseShipLine.SetRange("Source Subtype", SourceSubType);
                    WhseShipLine.SetRange("Source No.", SourceNo);
                    WhseShipLine.SetRange("Source Line No.", SourceLineNo);
                    if WhseShipLine.FindFirst() then begin
                        WhseShipLine.CalcFields("Pick Qty. (Base)");
                        OutBoundQty := WhseShipLine."Pick Qty. (Base)" + WhseShipLine."Qty. Picked (Base)";
                    end else begin
                        WhseActLine.Reset();
                        WhseActLine.SetCurrentKey(
                          "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                        WhseActLine.SetRange("Source Type", SourceType);
                        WhseActLine.SetRange("Source Subtype", SourceSubType);
                        WhseActLine.SetRange("Source No.", SourceNo);
                        WhseActLine.SetRange("Source Line No.", SourceLineNo);
                        if WhseActLine.FindFirst() then
                            OutBoundQty := WhseActLine."Qty. Outstanding (Base)"
                        else
                            OutBoundQty := 0;
                    end;
                end;
            DATABASE::"Prod. Order Component":
                begin
                    ProdOrderComp.Reset();
                    ProdOrderComp.SetRange(Status, SourceSubType);
                    ProdOrderComp.SetRange("Prod. Order No.", SourceNo);
                    ProdOrderComp.SetRange("Prod. Order Line No.", SourceSubLineNo);
                    ProdOrderComp.SetRange("Line No.", SourceLineNo);
                    if ProdOrderComp.FindFirst() then begin
                        ProdOrderComp.CalcFields("Pick Qty. (Base)");
                        OutBoundQty := ProdOrderComp."Pick Qty. (Base)" + ProdOrderComp."Qty. Picked (Base)";
                    end else
                        OutBoundQty := 0;
                end;
            DATABASE::"Assembly Line":
                begin
                    if AsmLine.Get(SourceSubType, SourceNo, SourceLineNo) then begin
                        AsmLine.CalcFields("Pick Qty. (Base)");
                        OutBoundQty := AsmLine."Pick Qty. (Base)" + AsmLine."Qty. Picked (Base)";
                    end else
                        OutBoundQty := 0;
                end;
        end;
        OnAfterCheckOutBound(SourceType, SourceSubType, SourceNo, SourceLineNo, OutBoundQty);
    end;

    procedure SetCrossDock(CrossDock2: Boolean)
    begin
        CrossDock := CrossDock2;
    end;

    procedure GetReservationStatus(var ReservationExists2: Boolean; var ReservedForItemLedgEntry2: Boolean)
    begin
        ReservationExists2 := ReservationExists;
        ReservedForItemLedgEntry2 := ReservedForItemLedgEntry;
    end;

    procedure SetCalledFromPickWksh(CalledFromPickWksh2: Boolean)
    begin
        CalledFromPickWksh := CalledFromPickWksh2;
    end;

    procedure SetCalledFromMoveWksh(CalledFromMoveWksh2: Boolean)
    begin
        CalledFromMoveWksh := CalledFromMoveWksh2;
    end;

    procedure CalcQtyToPickBaseExt(var BinContent: Record "Bin Content"; var TempWhseActivLine: Record "Warehouse Activity Line" temporary): Decimal
    begin
        exit(CalcQtyToPickBase(BinContent, TempWhseActivLine));
    end;

    local procedure CalcQtyToPickBase(var BinContent: Record "Bin Content"; var TempWhseActivLine: Record "Warehouse Activity Line" temporary): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseJournalLine: Record "Warehouse Journal Line";
        QtyPlaced: Decimal;
        QtyTaken: Decimal;
    begin
        WhseEntry.SetCurrentKey(
            "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.");
        WhseEntry.SetRange("Location Code", BinContent."Location Code");
        WhseEntry.SetRange("Bin Code", BinContent."Bin Code");
        WhseEntry.SetRange("Item No.", BinContent."Item No.");
        WhseEntry.SetRange("Variant Code", BinContent."Variant Code");
        WhseEntry.SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
        WhseEntry.SetTrackingFilterFromBinContent(BinContent);
        WhseEntry.CalcSums("Qty. (Base)");

        WhseActivLine.SetCurrentKey(
            "Item No.", "Bin Code", "Location Code",
            "Action Type", "Variant Code", "Unit of Measure Code", "Breakbulk No.", "Activity Type", "Lot No.", "Serial No.");
        WhseActivLine.SetRange("Location Code", BinContent."Location Code");
        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Take);
        WhseActivLine.SetRange("Bin Code", BinContent."Bin Code");
        WhseActivLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivLine.SetRange("Variant Code", BinContent."Variant Code");
        WhseActivLine.SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
        WhseActivLine.SetTrackingFilterFromBinContent(BinContent);
        WhseActivLine.CalcSums("Qty. Outstanding (Base)");
        QtyTaken := WhseActivLine."Qty. Outstanding (Base)";

        TempWhseActivLine.Copy(WhseActivLine);
        TempWhseActivLine.CalcSums("Qty. Outstanding (Base)");
        QtyTaken += TempWhseActivLine."Qty. Outstanding (Base)";

        TempWhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Place);
        TempWhseActivLine.CalcSums("Qty. Outstanding (Base)");
        QtyPlaced := TempWhseActivLine."Qty. Outstanding (Base)";

        TempWhseActivLine.Reset();

        WhseJournalLine.SetCurrentKey(
            "Item No.", "From Bin Code", "Location Code", "Entry Type", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.");
        WhseJournalLine.SetRange("Location Code", BinContent."Location Code");
        WhseJournalLine.SetRange("From Bin Code", BinContent."Bin Code");
        WhseJournalLine.SetRange("Item No.", BinContent."Item No.");
        WhseJournalLine.SetRange("Variant Code", BinContent."Variant Code");
        WhseJournalLine.SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
        WhseJournalLine.SetTrackingFilterFromBinContent(BinContent);
        WhseJournalLine.CalcSums("Qty. (Absolute, Base)");

        exit(WhseEntry."Qty. (Base)" + WhseJournalLine."Qty. (Absolute, Base)" + QtyPlaced - QtyTaken);
    end;

    local procedure PickAccordingToFEFO(LocationCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup") PickAccordingToFEFO: Boolean
    begin
        GetLocation(LocationCode);
        PickAccordingToFEFO := Location."Pick According to FEFO" and WhseItemTrackingSetup.TrackingRequired();
        OnAfterPickAccordingToFEFO(LocationCode, WhseItemTrackingSetup, PickAccordingToFEFO);
    end;

    local procedure UndefinedItemTrkg(var QtyToTrackBase: Decimal): Boolean
    var
        DummyItemTrackingSetup: Record "Item Tracking Setup";
    begin
        QtyToTrackBase := QtyToTrackBase - ItemTrackedQuantity(DummyItemTrackingSetup);
        exit(QtyToTrackBase > 0);
    end;

    local procedure ReleaseNonSpecificReservations(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyToRelease: Decimal): Boolean
    var
        LateBindingMgt: Codeunit "Late Binding Management";
        xReservedQty: Decimal;
    begin
        if QtyToRelease <= 0 then
            exit;

        if WhseItemTrackingSetup.TrackingRequired() then
            if Item."Reserved Qty. on Inventory" > 0 then begin
                xReservedQty := Item."Reserved Qty. on Inventory";
                LateBindingMgt.ReleaseForReservation(ItemNo, VariantCode, LocationCode, WhseItemTrackingSetup, QtyToRelease);
                Item.CalcFields("Reserved Qty. on Inventory");
            end;

        exit(xReservedQty > Item."Reserved Qty. on Inventory");
    end;

    procedure SetCalledFromWksh(NewCalledFromWksh: Boolean)
    begin
        CalledFromWksh := NewCalledFromWksh;
    end;

    local procedure GetFromBinContentQty(LocCode: Code[10]; FromBinCode: Code[20]; ItemNo: Code[20]; Variant: Code[20]; UoMCode: Code[10]; WhseItemTrackingLine: Record "Whse. Item Tracking Line"): Decimal
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.Get(LocCode, FromBinCode, ItemNo, Variant, UoMCode);
        BinContent.SetTrackingFilterFromWhseItemTrackingLine(WhseItemTrackingLine);
        BinContent.CalcFields("Quantity (Base)");
        exit(BinContent."Quantity (Base)");
    end;

    procedure CreateTempActivityLine(
        LocationCode: Code[10]; BinCode: Code[20]; UOMCode: Code[10]; QtyPerUOM: Decimal; QtyToPick: Decimal; QtyToPickBase: Decimal; ActionType: Integer; BreakBulkNo: Integer)
    begin
        CreateTempActivityLine(LocationCode, BinCode, UOMCode, QtyPerUOM, QtyToPick, QtyToPickBase, ActionType, BreakBulkNo, 0, 0);
    end;

    procedure CreateTempActivityLine(
        LocationCode: Code[10]; BinCode: Code[20]; UOMCode: Code[10]; QtyPerUOM: Decimal; QtyToPick: Decimal; QtyToPickBase: Decimal; ActionType: Integer; BreakBulkNo: Integer; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal)
    var
        WhseSource2: Option;
        ShouldCalcMaxQty: Boolean;
    begin
        OnBeforeCreateTempActivityLine(BinCode, QtyToPick, QtyToPickBase, ActionType);
        if Location."Directed Put-away and Pick" then
            GetBin(LocationCode, BinCode);

        TempLineNo := TempLineNo + 10000;
        with TempWhseActivLine do begin
            Reset();
            Init();

            "No." := Format(TempNo);
            "Location Code" := LocationCode;
            "Unit of Measure Code" := UOMCode;
            "Qty. per Unit of Measure" := QtyPerUOM;
            "Qty. Rounding Precision" := QtyRndPrec;
            "Qty. Rounding Precision (Base)" := QtyRndPrecBase;
            "Starting Date" := WorkDate();
            "Bin Code" := BinCode;
            "Action Type" := "Warehouse Action Type".FromInteger(ActionType);
            "Breakbulk No." := BreakBulkNo;
            "Line No." := TempLineNo;

            case CreatePickParameters."Whse. Document" of
                CreatePickParameters."Whse. Document"::"Pick Worksheet":
                    TransferFromPickWkshLine(WhseWkshLine);
                CreatePickParameters."Whse. Document"::Shipment:
                    if WhseShptLine."Assemble to Order" then
                        TransferFromATOShptLine(WhseShptLine, AssemblyLine)
                    else
                        TransferFromShptLine(WhseShptLine);
                CreatePickParameters."Whse. Document"::"Internal Pick":
                    TransferFromIntPickLine(WhseInternalPickLine);
                CreatePickParameters."Whse. Document"::Production:
                    TransferFromCompLine(ProdOrderCompLine);
                CreatePickParameters."Whse. Document"::Assembly:
                    TransferFromAssemblyLine(AssemblyLine);
                CreatePickParameters."Whse. Document"::"Movement Worksheet":
                    TransferFromMovWkshLine(WhseWkshLine);
                CreatePickParameters."Whse. Document"::Job:
                    TransferFromJobPlanningLine(JobPlanningLine);
            end;

            OnCreateTempActivityLineOnAfterTransferFrom(TempWhseActivLine, CreatePickParameters."Whse. Document");

            if (CreatePickParameters."Whse. Document" = CreatePickParameters."Whse. Document"::Shipment) and WhseShptLine."Assemble to Order" then
                WhseSource2 := CreatePickParameters."Whse. Document"::Assembly
            else
                WhseSource2 := CreatePickParameters."Whse. Document";

            ShouldCalcMaxQty := (BreakBulkNo = 0) and ("Action Type" <> "Action Type"::" ");
            OnCreateTempActivityLineOnAfterShouldCalcMaxQty(TempWhseActivLine, BreakBulkNo, ShouldCalcMaxQty);
            if ShouldCalcMaxQty then
                case WhseSource2 of
                    CreatePickParameters."Whse. Document"::"Pick Worksheet",
                    CreatePickParameters."Whse. Document"::"Movement Worksheet":
                        if ("Action Type" <> "Action Type"::Take) or (WhseWkshLine."Unit of Measure Code" = TempWhseActivLine."Unit of Measure Code") then
                            CalcMaxQty(
                              QtyToPick, WhseWkshLine."Qty. to Handle", QtyToPickBase, WhseWkshLine."Qty. to Handle (Base)", "Action Type");

                    CreatePickParameters."Whse. Document"::Shipment:
                        if ("Action Type" <> "Action Type"::Take) or (WhseShptLine."Unit of Measure Code" = TempWhseActivLine."Unit of Measure Code") then begin
                            WhseShptLine.CalcFields("Pick Qty.", "Pick Qty. (Base)");
                            CalcMaxQty(
                              QtyToPick,
                              WhseShptLine.Quantity -
                              WhseShptLine."Qty. Picked" -
                              WhseShptLine."Pick Qty.",
                              QtyToPickBase,
                              WhseShptLine."Qty. (Base)" -
                              WhseShptLine."Qty. Picked (Base)" -
                              WhseShptLine."Pick Qty. (Base)",
                              "Action Type");
                        end;

                    CreatePickParameters."Whse. Document"::"Internal Pick":
                        if ("Action Type" <> "Action Type"::Take) or (WhseInternalPickLine."Unit of Measure Code" = TempWhseActivLine."Unit of Measure Code") then begin
                            WhseInternalPickLine.CalcFields("Pick Qty.", "Pick Qty. (Base)");
                            CalcMaxQty(
                              QtyToPick,
                              WhseInternalPickLine.Quantity -
                              WhseInternalPickLine."Qty. Picked" -
                              WhseInternalPickLine."Pick Qty.",
                              QtyToPickBase,
                              WhseInternalPickLine."Qty. (Base)" -
                              WhseInternalPickLine."Qty. Picked (Base)" -
                              WhseInternalPickLine."Pick Qty. (Base)",
                              "Action Type");
                        end;

                    CreatePickParameters."Whse. Document"::Production:
                        if ("Action Type" <> "Action Type"::Take) or (ProdOrderCompLine."Unit of Measure Code" = TempWhseActivLine."Unit of Measure Code") then begin
                            ProdOrderCompLine.CalcFields("Pick Qty.", "Pick Qty. (Base)");
                            CalcMaxQty(
                              QtyToPick,
                              ProdOrderCompLine."Expected Quantity" -
                              ProdOrderCompLine."Qty. Picked" -
                              ProdOrderCompLine."Pick Qty.",
                              QtyToPickBase,
                              ProdOrderCompLine."Expected Qty. (Base)" -
                              ProdOrderCompLine."Qty. Picked (Base)" -
                              ProdOrderCompLine."Pick Qty. (Base)",
                              "Action Type");
                        end;

                    CreatePickParameters."Whse. Document"::Assembly:
                        if ("Action Type" <> "Action Type"::Take) or (AssemblyLine."Unit of Measure Code" = TempWhseActivLine."Unit of Measure Code") then begin
                            AssemblyLine.CalcFields("Pick Qty.", "Pick Qty. (Base)");
                            CalcMaxQty(
                              QtyToPick,
                              AssemblyLine.Quantity -
                              AssemblyLine."Qty. Picked" -
                              AssemblyLine."Pick Qty.",
                              QtyToPickBase,
                              AssemblyLine."Quantity (Base)" -
                              AssemblyLine."Qty. Picked (Base)" -
                              AssemblyLine."Pick Qty. (Base)",
                              "Action Type");
                        end;

                    CreatePickParameters."Whse. Document"::Job:
                        if not (("Action Type" = "Action Type"::Take) and (JobPlanningLine."Unit of Measure Code" <> TempWhseActivLine."Unit of Measure Code")) then begin
                            JobPlanningLine.CalcFields("Pick Qty.", "Pick Qty. (Base)");
                            CalcMaxQty(
                              QtyToPick,
                              JobPlanningLine.Quantity -
                              JobPlanningLine."Qty. Picked" -
                              JobPlanningLine."Pick Qty.",
                              QtyToPickBase,
                              JobPlanningLine."Quantity (Base)" -
                              JobPlanningLine."Qty. Picked (Base)" -
                              JobPlanningLine."Pick Qty. (Base)",
                              "Action Type");
                        end;
                end;

            OnCreateTempActivityLineOnAfterCalcQtyToPick(
                TempWhseActivLine, QtyToPick, QtyToPickBase, CreatePickParameters."Whse. Document", WhseSource2);

            if (LocationCode <> '') and (BinCode <> '') then begin
                GetBin(LocationCode, BinCode);
                Dedicated := Bin.Dedicated;
            end;
            "Zone Code" := Bin."Zone Code";
            "Bin Ranking" := Bin."Bin Ranking";
            if Location."Directed Put-away and Pick" then
                "Bin Type Code" := Bin."Bin Type Code";
            if Location."Special Equipment" <> Location."Special Equipment"::" " then
                "Special Equipment Code" :=
                  AssignSpecEquipment(LocationCode, BinCode, "Item No.", "Variant Code");
            OnCreateTempActivityLineAfterAssignSpecEquipment(TempWhseActivLine, QtyToPick);

            Validate(Quantity, QtyToPick);
            if QtyToPickBase <> 0 then begin
                "Qty. (Base)" := QtyToPickBase;
                "Qty. to Handle (Base)" := QtyToPickBase;
                "Qty. Outstanding (Base)" := QtyToPickBase;
            end;
            OnCreateTempActivityLineOnAfterValidateQuantity(TempWhseActivLine);

            case CreatePickParameters."Whse. Document" of
                CreatePickParameters."Whse. Document"::Shipment:
                    begin
                        "Shipping Agent Code" := ShippingAgentCode;
                        "Shipping Agent Service Code" := ShippingAgentServiceCode;
                        "Shipment Method Code" := ShipmentMethodCode;
                        "Shipping Advice" := "Shipping Advice";
                    end;
                CreatePickParameters."Whse. Document"::Production,
                CreatePickParameters."Whse. Document"::Assembly,
                CreatePickParameters."Whse. Document"::Job:
                    if "Shelf No." = '' then begin
                        Item."No." := "Item No.";
                        Item.ItemSKUGet(Item, "Location Code", "Variant Code");
                        "Shelf No." := Item."Shelf No.";
                    end;
                CreatePickParameters."Whse. Document"::"Movement Worksheet":
                    if (WhseWkshLine."Qty. Outstanding" <> QtyToPick) and (BreakBulkNo = 0) then begin
                        "Source Type" := DATABASE::"Whse. Worksheet Line";
                        "Source No." := WhseWkshLine."Worksheet Template Name";
                        "Source Line No." := "Line No.";
                    end;
            end;

            TransferItemTrkgFields(TempWhseActivLine, TempWhseItemTrackingLine);

            if (BreakBulkNo = 0) and (ActionType <> 2) then
                TotalQtyPickedBase += QtyToPickBase;

            OnBeforeTempWhseActivLineInsert(TempWhseActivLine, ActionType);
            Insert();
        end;
    end;

    procedure UpdateQuantitiesToPick(QtyAvailableBase: Decimal; FromQtyPerUOM: Decimal; var FromQtyToPick: Decimal; var FromQtyToPickBase: Decimal; ToQtyPerUOM: Decimal; var ToQtyToPick: Decimal; var ToQtyToPickBase: Decimal; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal)
    begin
        UpdateToQtyToPick(QtyAvailableBase, ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase, TotalQtyToPick, TotalQtyToPickBase);
        UpdateFromQtyToPick(QtyAvailableBase, FromQtyPerUOM, FromQtyToPick, FromQtyToPickBase, ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase);
        UpdateTotalQtyToPick(ToQtyToPick, ToQtyToPickBase, TotalQtyToPick, TotalQtyToPickBase)
    end;

    procedure UpdateFromQtyToPick(QtyAvailableBase: Decimal; FromQtyPerUOM: Decimal; var FromQtyToPick: Decimal; var FromQtyToPickBase: Decimal; ToQtyPerUOM: Decimal; ToQtyToPick: Decimal; ToQtyToPickBase: Decimal)
    begin
        case FromQtyPerUOM of
            ToQtyPerUOM:
                begin
                    FromQtyToPick := ToQtyToPick;
                    FromQtyToPickBase := ToQtyToPickBase;
                end;
            0 .. ToQtyPerUOM:
                begin
                    FromQtyToPick := Round(ToQtyToPickBase / FromQtyPerUOM, UOMMgt.QtyRndPrecision());
                    FromQtyToPickBase := ToQtyToPickBase;
                end;
            else
                FromQtyToPick := Round(ToQtyToPickBase / FromQtyPerUOM, 1, '>');
                FromQtyToPickBase := FromQtyToPick * FromQtyPerUOM;
                if FromQtyToPickBase > QtyAvailableBase then begin
                    FromQtyToPickBase := ToQtyToPickBase;
                    FromQtyToPick := Round(FromQtyToPickBase / FromQtyPerUOM, UOMMgt.QtyRndPrecision());
                end;
        end;
    end;

    local procedure UpdateToQtyToPick(QtyAvailableBase: Decimal; ToQtyPerUOM: Decimal; var ToQtyToPick: Decimal; var ToQtyToPickBase: Decimal; TotalQtyToPick: Decimal; TotalQtyToPickBase: Decimal)
    begin
        ToQtyToPickBase := QtyAvailableBase;
        if ToQtyToPickBase > TotalQtyToPickBase then
            ToQtyToPickBase := TotalQtyToPickBase;

        ToQtyToPick := Round(ToQtyToPickBase / ToQtyPerUOM, UOMMgt.QtyRndPrecision());
        if ToQtyToPick > TotalQtyToPick then
            ToQtyToPick := TotalQtyToPick;
        if (ToQtyToPick <> TotalQtyToPick) and (ToQtyToPickBase = TotalQtyToPickBase) then
            if Abs(1 - ToQtyToPick / TotalQtyToPick) <= UOMMgt.QtyRndPrecision() then
                ToQtyToPick := TotalQtyToPick;
    end;

    procedure UpdateTotalQtyToPick(ToQtyToPick: Decimal; ToQtyToPickBase: Decimal; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal)
    begin
        TotalQtyToPick := TotalQtyToPick - ToQtyToPick;
        TotalQtyToPickBase := TotalQtyToPickBase - ToQtyToPickBase;
    end;

    local procedure CalcTotalQtyAssgndOnWhse(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
        ProdOrderComp: Record "Prod. Order Component";
        AsmLine: Record "Assembly Line";
        QtyAssgndToWhseAct: Decimal;
        QtyAssgndToShipment: Decimal;
        QtyAssgndToProdComp: Decimal;
        QtyAssgndToAsmLine: Decimal;
    begin
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct("Warehouse Activity Type"::" ", LocationCode, ItemNo, VariantCode);
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct("Warehouse Activity Type"::"Put-away", LocationCode, ItemNo, VariantCode);
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct("Warehouse Activity Type"::Pick, LocationCode, ItemNo, VariantCode);
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct("Warehouse Activity Type"::Movement, LocationCode, ItemNo, VariantCode);
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct("Warehouse Activity Type"::"Invt. Put-away", LocationCode, ItemNo, VariantCode);
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct("Warehouse Activity Type"::"Invt. Pick", LocationCode, ItemNo, VariantCode);

        with WhseShipmentLine do begin
            SetCurrentKey("Item No.", "Location Code", "Variant Code", "Due Date");
            SetRange("Location Code", LocationCode);
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            CalcSums("Qty. Picked (Base)", "Qty. Shipped (Base)");
            QtyAssgndToShipment := "Qty. Picked (Base)" - "Qty. Shipped (Base)";
        end;

        with ProdOrderComp do begin
            SetCurrentKey("Item No.", "Variant Code", "Location Code", Status, "Due Date");
            SetRange("Location Code", LocationCode);
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetRange(Status, Status::Released);
            CalcSums("Qty. Picked (Base)", "Expected Qty. (Base)", "Remaining Qty. (Base)");
            QtyAssgndToProdComp := "Qty. Picked (Base)" - ("Expected Qty. (Base)" - "Remaining Qty. (Base)");
        end;

        with AsmLine do begin
            SetCurrentKey("Document Type", Type, "No.", "Variant Code", "Location Code");
            SetRange("Document Type", "Document Type"::Order);
            SetRange("Location Code", LocationCode);
            SetRange(Type, Type::Item);
            SetRange("No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            CalcSums("Qty. Picked (Base)", "Consumed Quantity (Base)");
            QtyAssgndToAsmLine := CalcQtyPickedNotConsumedBase();
        end;

        OnAfterCalcTotalQtyAssgndOnWhse(
            LocationCode, ItemNo, VariantCode, QtyAssgndToWhseAct, QtyAssgndToShipment, QtyAssgndToProdComp, QtyAssgndToAsmLine);

        exit(QtyAssgndToWhseAct + QtyAssgndToShipment + QtyAssgndToProdComp + QtyAssgndToAsmLine);
    end;

    local procedure CalcTotalQtyAssgndOnWhseAct(ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        with WhseActivLine do begin
            SetCurrentKey(
              "Item No.", "Location Code", "Activity Type", "Bin Type Code",
              "Unit of Measure Code", "Variant Code", "Breakbulk No.", "Action Type");
            SetRange("Location Code", LocationCode);
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetRange("Activity Type", ActivityType);
            SetRange("Breakbulk No.", 0);
            SetFilter("Action Type", '%1|%2', "Action Type"::" ", "Action Type"::Take);
            CalcSums("Qty. Outstanding (Base)");
            exit("Qty. Outstanding (Base)");
        end;
    end;

    procedure CalcTotalQtyOnBinType(BinTypeFilter: Text[1024]; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        DummyItemTrackingSetup: Record "Item Tracking Setup";
    begin
        exit(SumWhseEntries(ItemNo, LocationCode, VariantCode, DummyItemTrackingSetup, BinTypeFilter, '', false));
    end;

    local procedure SumWhseEntries(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; BinTypeCodeFilter: Text; BinCodeFilter: Text; ExcludeDedicatedBins: Boolean): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        WhseEntry.SetCalculationFilters(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, ExcludeDedicatedBins);
        WhseEntry.SetFilter("Bin Type Code", BinTypeCodeFilter);
        WhseEntry.SetFilter("Bin Code", BinCodeFilter);
        WhseEntry.CalcSums("Qty. (Base)");
        exit(WhseEntry."Qty. (Base)");
    end;

    procedure CalcBreakbulkOutstdQty(var WhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        BinContent: Record "Bin Content";
        WhseActivLine1: Record "Warehouse Activity Line";
        WhseActivLine2: Record "Warehouse Activity Line";
        TempUOM: Record "Unit of Measure" temporary;
        QtyOnBreakbulk: Decimal;
        BreakbulkBinFound: Boolean;
    begin
        with WhseActivLine1 do begin
            CopyFilters(WhseActivLine);
            SetFilter("Breakbulk No.", '<>%1', 0);
            SetRange("Action Type", "Action Type"::Place);
            if FindSet() then begin
                BinContent.SetCurrentKey(
                  "Location Code", "Item No.", "Variant Code", "Cross-Dock Bin", "Qty. per Unit of Measure", "Bin Ranking");
                BinContent.SetRange("Location Code", "Location Code");
                BinContent.SetRange("Item No.", "Item No.");
                BinContent.SetRange("Variant Code", "Variant Code");
                BinContent.SetRange("Cross-Dock Bin", CrossDock);

                repeat
                    if not TempUOM.Get("Unit of Measure Code") then begin
                        TempUOM.Init();
                        TempUOM.Code := "Unit of Measure Code";
                        TempUOM.Insert();
                        SetRange("Unit of Measure Code", "Unit of Measure Code");
                        CalcSums("Qty. Outstanding (Base)");
                        QtyOnBreakbulk += "Qty. Outstanding (Base)";

                        // Exclude the qty counted in QtyAssignedToPick
                        BinContent.SetRange("Unit of Measure Code", "Unit of Measure Code");
                        if WhseItemTrackingSetup."Serial No. Required" then
                            BinContent.SetRange("Serial No. Filter", "Serial No.")
                        else
                            BinContent.SetFilter("Serial No. Filter", '%1|%2', "Serial No.", '');
                        if WhseItemTrackingSetup."Lot No. Required" then
                            BinContent.SetRange("Lot No. Filter", "Lot No.")
                        else
                            BinContent.SetFilter("Lot No. Filter", '%1|%2', "Lot No.", '');

                        BreakbulkBinFound := false;
                        if BinContent.FindSet() then
                            repeat
                                if UseForPick(BinContent) then begin
                                    BreakbulkBinFound := true;
                                    BinContent.SetFilterOnUnitOfMeasure();
                                    BinContent.CalcFields("Quantity (Base)", "Pick Quantity (Base)");
                                    if BinContent."Pick Quantity (Base)" > BinContent."Quantity (Base)" then
                                        QtyOnBreakbulk -= (BinContent."Pick Quantity (Base)" - BinContent."Quantity (Base)");
                                end;
                            until BinContent.Next() = 0;

                        if not BreakbulkBinFound then begin
                            WhseActivLine2.CopyFilters(WhseActivLine1);
                            WhseActivLine2.SetFilter("Action Type", '%1|%2', "Action Type"::" ", "Action Type"::Take);
                            WhseActivLine2.SetRange("Breakbulk No.", 0);
                            WhseActivLine2.CalcSums("Qty. Outstanding (Base)");
                            QtyOnBreakbulk -= WhseActivLine2."Qty. Outstanding (Base)";
                        end;
                        SetRange("Unit of Measure Code");
                    end;
                until Next() = 0;
            end;
            exit(QtyOnBreakbulk);
        end;
    end;

    procedure GetCannotBeHandledReason(): Text
    begin
        exit(DequeueCannotBeHandledReason());
    end;

    local procedure PickStrictExpirationPosting(ItemNo: Code[20]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        StrictExpirationPosting: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePickStrictExpirationPosting(
            ItemNo, WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", StrictExpirationPosting, IsHandled);
        if IsHandled then
            exit(StrictExpirationPosting);

        exit(ItemTrackingMgt.StrictExpirationPosting(ItemNo) and WhseItemTrackingSetup.TrackingRequired());
    end;

    procedure AddToFilterText(var TextVar: Text[250]; Separator: Code[1]; Comparator: Code[2]; Addendum: Code[20])
    begin
        if TextVar = '' then
            TextVar := Comparator + '''' + Addendum + ''''
        else
            TextVar += Separator + Comparator + '''' + Addendum + '''';
    end;

    procedure CreateAssemblyPickLine(AsmLine: Record "Assembly Line")
    var
        QtyToPickBase: Decimal;
        QtyToPick: Decimal;
    begin
        with AsmLine do begin
            TestField("Qty. per Unit of Measure");
            QtyToPickBase := CalcQtyToPickBase();
            QtyToPick := CalcQtyToPick();
            OnCreateAssemblyPickLineOnAfterCalcQtyToPick(AsmLine, QtyToPickBase, QtyToPick);
            if QtyToPick > 0 then begin
                SetAssemblyLine(AsmLine, 1);
                SetTempWhseItemTrkgLine(
                  "Document No.", DATABASE::"Assembly Line", '', 0, "Line No.", "Location Code");
                CreateTempLine(
                  "Location Code", "No.", "Variant Code", "Unit of Measure Code", '', "Bin Code",
                  "Qty. per Unit of Measure", "Qty. Rounding Precision", "Qty. Rounding Precision (Base)", QtyToPick, QtyToPickBase);
            end;
        end;
    end;

    local procedure MovementFromShipZone(var TotalAvailQtyBase: Decimal; QtyOnOutboundBins: Decimal)
    begin
        if not IsShipZone(WhseWkshLine."Location Code", WhseWkshLine."To Zone Code") then
            TotalAvailQtyBase := TotalAvailQtyBase - QtyOnOutboundBins;
    end;

    procedure IsShipZone(LocationCode: Code[10]; ZoneCode: Code[10]): Boolean
    var
        Zone: Record Zone;
        BinType: Record "Bin Type";
    begin
        if not Zone.Get(LocationCode, ZoneCode) then
            exit(false);
        if not BinType.Get(Zone."Bin Type Code") then
            exit(false);
        exit(BinType.Ship);
    end;

    local procedure Minimum(a: Decimal; b: Decimal): Decimal
    begin
        if a < b then
            exit(a);

        exit(b);
    end;

    procedure CalcQtyResvdNotOnILE(ReservEntryNo: Integer; ReservEntryPositive: Boolean) QtyResvdNotOnILE: Decimal
    var
        ReservEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyResvdNotOnILE(ReservEntryNo, ReservEntryPositive, QtyResvdNotOnILE, IsHandled);
        if not IsHandled then
            if ReservEntry.Get(ReservEntryNo, not ReservEntryPositive) then
                if ReservEntry."Source Type" <> DATABASE::"Item Ledger Entry" then
                    QtyResvdNotOnILE += ReservEntry."Quantity (Base)";

        exit(QtyResvdNotOnILE);
    end;

    procedure SetFiltersOnReservEntry(var ReservEntry: Record "Reservation Entry"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    begin
        with ReservEntry do begin
            SetCurrentKey(
              "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
              "Source Batch Name", "Source Prod. Order Line", "Reservation Status");
            SetRange("Source ID", SourceNo);
            case SourceType of
                Database::"Prod. Order Component":
                    begin
                        SetRange("Source Ref. No.", SourceSubLineNo);
                        SetRange("Source Prod. Order Line", SourceLineNo);
                        SetRange("Source Type", SourceType);
                        SetRange("Source Subtype", SourceSubType);
                    end;
                Database::Job, Database::"Job Planning Line":
                    begin
                        SetRange("Source Ref. No.", SourceLineNo);
                        SetRange("Source Type", Database::"Job Planning Line");
                        SetRange("Source Subtype", "Job Planning Line Status"::Order.AsInteger());
                    end;
                else
                    SetRange("Source Ref. No.", SourceLineNo);
                    SetRange("Source Type", SourceType);
                    SetRange("Source Subtype", SourceSubType);
            end;
            SetRange("Reservation Status", "Reservation Status"::Reservation);
        end;
    end;

    procedure GetActualQtyPickedBase(): Decimal
    begin
        exit(TotalQtyPickedBase);
    end;

    procedure CalcReservedQtyOnInventory(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; WhseItemTrackingSetup: record "Item Tracking Setup") ReservedQty: Decimal
    var
        CalcQtyInReservEntry: Query CalcQtyInReservEntry;
    begin
        ReservedQty := 0;

        CalcQtyInReservEntry.SetRange(Source_Type, Database::"Item Ledger Entry");
        CalcQtyInReservEntry.SetRange(Source_Subtype, 0);
        CalcQtyInReservEntry.SetRange(Reservation_Status, "Reservation Status"::Reservation);
        CalcQtyInReservEntry.SetRange(Location_Code, LocationCode);
        CalcQtyInReservEntry.SetRange(Item_No_, ItemNo);
        CalcQtyInReservEntry.SetRange(Variant_Code, VariantCode);
        CalcQtyInReservEntry.SetTrackingFilterFromWhseItemTrackingSetupIfRequired(WhseItemTrackingSetup);
        CalcQtyInReservEntry.Open();
        while CalcQtyInReservEntry.Read() do
            ReservedQty += DistributeReservedQtyByBins(CalcQtyInReservEntry);

        OnAfterCalcReservedQtyOnInventory(
            ItemNo, LocationCode, VariantCode,
            WhseItemTrackingSetup."Lot No.", WhseItemTrackingSetup."Lot No. Required",
            WhseItemTrackingSetup."Serial No.", WhseItemTrackingSetup."Serial No. Required",
            ReservedQty, WhseItemTrackingSetup);
    end;

    local procedure DistributeReservedQtyByBins(var CalcQtyInReservEntry: Query CalcQtyInReservEntry): Decimal
    var
        TempBinContentBufferByBins: Record "Bin Content Buffer" temporary;
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        CalcQtyInWhseEntries: Query CalcQtyInWhseEntries;
        QtyLeftToDistribute: Decimal;
        QtyInBin: Decimal;
        Qty: Decimal;
    begin
        QtyLeftToDistribute := CalcQtyInReservEntry.Quantity__Base_;
        GetLocation(CalcQtyInReservEntry.Location_Code);

        CalcQtyInWhseEntries.SetRange(Location_Code, CalcQtyInReservEntry.Location_Code);
        CalcQtyInWhseEntries.SetRange(Item_No_, CalcQtyInReservEntry.Item_No_);
        CalcQtyInWhseEntries.SetRange(Variant_Code, CalcQtyInReservEntry.Variant_Code);
        CalcQtyInWhseEntries.SetRange(Serial_No_, CalcQtyInReservEntry.Serial_No_);
        CalcQtyInWhseEntries.SetRange(Lot_No_, CalcQtyInReservEntry.Lot_No_);
        CalcQtyInWhseEntries.SetRange(Package_No_, CalcQtyInReservEntry.Package_No_);
        if Location."Directed Put-away and Pick" then begin
            if Location."Adjustment Bin Code" <> '' then
                CalcQtyInWhseEntries.SetFilter(Bin_Code, '<>%1', Location."Adjustment Bin Code");
            CalcQtyInWhseEntries.SetFilter(Bin_Type_Code, '<>%1', GetBinTypeFilter(0));
        end;
        CalcQtyInWhseEntries.Open();

        // step 1: distribute quantity by bins
        while CalcQtyInWhseEntries.Read() and (QtyLeftToDistribute <> 0) do begin
            QtyInBin := Minimum(QtyLeftToDistribute, CalcQtyInWhseEntries.Qty___Base_);
            QtyLeftToDistribute -= QtyInBin;

            WhseItemTrackingSetup."Serial No." := CalcQtyInWhseEntries.Serial_No_;
            WhseItemTrackingSetup."Lot No." := CalcQtyInWhseEntries.Lot_No_;
            WhseItemTrackingSetup."Package No." := CalcQtyInWhseEntries.Package_No_;
            TempBinContentBufferByBins.UpdateBuffer(
              CalcQtyInWhseEntries.Location_Code, CalcQtyInWhseEntries.Bin_Code,
              CalcQtyInWhseEntries.Item_No_, CalcQtyInWhseEntries.Variant_Code,
              CalcQtyInWhseEntries.Unit_of_Measure_Code, WhseItemTrackingSetup, QtyInBin);
        end;

        // step 2: remove blocked item tracking
        if TempBinContentBufferByBins.FindSet() then
            repeat
                if not BlockedBinOrTracking(TempBinContentBufferByBins) then
                    Qty += TempBinContentBufferByBins."Qty. to Handle (Base)";
            until TempBinContentBufferByBins.Next() = 0;

        exit(Qty);
    end;

    local procedure BlockedBinOrTracking(BinContentBuffer: Record "Bin Content Buffer"): Boolean
    var
        LotNoInformation: Record "Lot No. Information";
        SerialNoInformation: Record "Serial No. Information";
        IsBlocked: Boolean;
    begin
        with BinContentBuffer do begin
            if BinContentBlocked("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code") then
                exit(true);
            if LotNoInformation.Get("Item No.", "Variant Code", "Lot No.") then
                if LotNoInformation.Blocked then
                    exit(true);
            if SerialNoInformation.Get("Item No.", "Variant Code", "Serial No.") then
                if SerialNoInformation.Blocked then
                    exit(true);

            IsBlocked := false;
            OnAfterBlockedBinOrTracking(BinContentBuffer, IsBlocked);
            if IsBlocked then
                exit(true);
        end;

        exit(false);
    end;

    local procedure GetMessageForUnhandledQtyDueToBin(BinIsForPick: Boolean; BinIsForReplenishment: Boolean; IsMoveWksh: Boolean; AvailableQtyBase: Decimal; var FromBinContent: Record "Bin Content") Result: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN20
        RunOnBeforeGetMessageForUnhandledQtyDueToBin(BinIsForPick, BinIsForReplenishment, IsMoveWksh, AvailableQtyBase, FromBinContent, Result, IsHandled);
#endif
        OnBeforeGetMessageForUnhandledQtyDueToBinProcedure(BinIsForPick, BinIsForReplenishment, IsMoveWksh, AvailableQtyBase, FromBinContent, Result, IsHandled);
        if IsHandled then
            exit;

        if AvailableQtyBase <= 0 then
            exit('');
        if not BinIsForPick and not IsMoveWksh then
            exit(StrSubstNo(BinIsNotForPickTxt, FromBinContent."Bin Code"));
        if not BinIsForReplenishment and IsMoveWksh then
            exit(StrSubstNo(BinIsForReceiveOrShipTxt, FromBinContent."Bin Code"));
    end;

#if not CLEAN20
    [Obsolete('Replaced with OnBeforeGetMessageForUnhandledQtyDueToBinProcedure', '20.0')]
    local procedure RunOnBeforeGetMessageForUnhandledQtyDueToBin(var BinIsForPick: Boolean; var BinIsForReplenishment: Boolean; var IsMoveWksh: Boolean; var AvailableQtyBase: Decimal; FromBinContent: Record "Bin Content"; var Result: Text; var IsHandled: Boolean)
    var
        OldResult: Text[100];
    begin
        OnBeforeGetMessageForUnhandledQtyDueToBin(BinIsForPick, BinIsForReplenishment, IsMoveWksh, AvailableQtyBase, FromBinContent, OldResult, IsHandled);
        Result := OldResult;
    end;
#endif

    local procedure GetMessageForUnhandledQtyDueToReserv(): Text
    begin
        exit(QtyReservedNotFromInventoryTxt);
    end;

    procedure FilterWhsePickLinesWithUndefinedBin(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        with WarehouseActivityLine do begin
            Reset();
            SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Action Type", "Variant Code", "Unit of Measure Code", "Breakbulk No.", "Activity Type");
            SetRange("Item No.", ItemNo);
            SetRange("Bin Code", '');
            SetRange("Location Code", LocationCode);
            SetRange("Action Type", "Action Type"::Take);
            SetRange("Variant Code", VariantCode);
            SetTrackingFilterFromWhseItemTrackingSetupIfNotBlank(WhseItemTrackingSetup);
            SetRange("Breakbulk No.", 0);
            SetRange("Activity Type", "Activity Type"::Pick);
        end;
    end;

    procedure EnqueueCannotBeHandledReason(CannotBeHandledReason: Text)
    var
        NewReasonAdded: Boolean;
        i: Integer;
    begin
        if CannotBeHandledReason = '' then
            exit;

        repeat
            i += 1;
            if CannotBeHandledReasons[i] = '' then begin
                CannotBeHandledReasons[i] := CannotBeHandledReason;
                NewReasonAdded := true;
            end;
        until NewReasonAdded or (i = ArrayLen(CannotBeHandledReasons));
    end;

    local procedure DequeueCannotBeHandledReason() CannotBeHandledReason: Text
    begin
        CannotBeHandledReason := CannotBeHandledReasons[1];
        CannotBeHandledReasons[1] := '';
        CompressArray(CannotBeHandledReasons);
    end;

    local procedure LockTables()
    var
        WarehouseActivityHeaderToLock: Record "Warehouse Activity Header";
        WarehouseActivityLineToLock: Record "Warehouse Activity Line";
    begin
        WarehouseActivityHeaderToLock.Lock();
        WarehouseActivityLineToLock.Lock();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyOnPickAndReceiveBins(SourceType: Integer; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; CalledFromPickWksh: Boolean; CalledFromMoveWksh: Boolean; CalledFromWksh: Boolean; var QtyInWhse: Decimal; var QtyOnPickBins: Decimal; var QtyOnPutAwayBins: Decimal; var QtyOnOutboundBins: Decimal; var QtyOnReceiveBins: Decimal; var QtyOnDedicatedBins: Decimal; var QtyBlocked: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcReservedQtyOnInventory(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; LotNo: Code[50]; LNRequired: Boolean; SerialNo: Code[50]; SNRequired: Boolean; var ReservedQty: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcTotalQtyAssgndOnWhse(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; var QtyAssgndToWhseAct: Decimal; var QtyAssgndToShipment: Decimal; var QtyAssgndToProdComp: Decimal; var QtyAssgndToAsmLine: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckOutBound(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var OutBoundQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckReservation(var Quantity: Decimal; var QuantityBase: Decimal; var QtyBaseAvailToPick: Decimal; var ReservationExists: Boolean; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateTempLine(LocationCode: Code[10]; ToBinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempLineCheckReservation(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal; var TotalQtytoPick: Decimal; var TotalQtytoPickBase: Decimal; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; var LastWhseItemTrkgLineNo: Integer; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempWhseItemTrackingLines(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseDocument(var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; CreatePickParameters: Record "Create Pick Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseDocLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseActivLine(var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceWhseItemTrkgLine(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var LastWhseItemTrkgLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetParameters(var CreatePickParameters: Record "Create Pick Parameters");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAssemblyLine(var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProdOrderCompLine(var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; TempNo2: Integer; var ShippingAgentCode2: Code[10]; var ShippingAgentServiceCode2: Code[10]; var ShipmentMethodCode2: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseWkshLine(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseInternalPickLine(var WhseInternalPickLine: Record "Whse. Internal Pick Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferItemTrkgFields(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line"; EntriesExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjustQtyReservedOnPickShip(var SubTotal: Decimal; QtyReservedOnPickShip: Decimal; LineReservedQty: Decimal; ReservedQtyOnInventory: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyResvdNotOnILE(ReservEntryNo: Integer; ReservEntryPositive: Boolean; var QtyResvdNotOnILE: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseDocTakeLineProcedure(var WhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeCalcPickBin(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var TotalQtytoPick: Decimal; var TotalQtytoPickBase: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; CrossDock: Boolean; WhseTrackingExists: Boolean; WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcBWPickBin(var TotalQtyToPick: Decimal; var TotalQtytoPickBase: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; WhseItemTrkgExists: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcTotalAvailQtyToPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; NeededQtyBase: Decimal; RespectLocationBins: Boolean; CalledFromMoveWksh: Boolean; CalledFromWksh: Boolean; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var IsHandled: Boolean; var TotalAvailQtyBase: Decimal; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyToTempWhseItemTrkgLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseDocument(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeCreateNewWhseDoc(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; OldNo: Code[20]; OldSourceNo: Code[20]; OldLocationCode: Code[10]; var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; var NoOfSourceDoc: Integer; var NoOfLines: Integer; var WhseDocCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempItemTrkgLines(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; var TotalQtytoPickBase: Decimal; HasExpiryDate: Boolean; var IsHandled: Boolean; var WhseItemTrackingFEFO: Codeunit "Whse. Item Tracking FEFO"; WhseShptLine: Record "Warehouse Shipment Line"; WhseWkshLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempActivityLine(BinCode: Code[20]; QtyToPick: Decimal; QtyToPickBase: Decimal; ActionType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBinTypeFilter(var BinTypeFilter: Text[1024]; var IsHandled: Boolean; Type: Option)
    begin
    end;

#if not CLEAN20
    [Obsolete('Replaced with OnBeforeGetMessageForUnhandledQtyDueToBinProcedure', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetMessageForUnhandledQtyDueToBin(var BinIsForPick: Boolean; var BinIsForReplenishment: Boolean; var IsMoveWksh: Boolean; var AvailableQtyBase: Decimal; FromBinContent: Record "Bin Content"; var Result: Text[100]; var IsHandled: Boolean)
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetMessageForUnhandledQtyDueToBinProcedure(var BinIsForPick: Boolean; var BinIsForReplenishment: Boolean; var IsMoveWksh: Boolean; var AvailableQtyBase: Decimal; FromBinContent: Record "Bin Content"; var Result: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBWPickBin(var BinContent: Record "Bin Content"; var IsSetCurrentKeyHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBreakBulkBinPerBinContent(FromBinContent: Record "Bin Content"; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; WhseItemTrkgExists: Boolean; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; TotalQtyToPickBase: Decimal; var QtyAvailableBase: Decimal; var StopProcessing: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetBinCodeFilter(var BinCodeFilterText: Text[250]; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToBinCode: Code[20]; var IsHandled: Boolean; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePickStrictExpirationPosting(ItemNo: Code[20]; SNRequired: Boolean; LNRequired: Boolean; var StrictExpirationPosting: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemTrackedQuantity(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup"; var QtyToHandleBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeInsertTempItemTrkgLine(var EntrySummary: Record "Entry Summary"; RemQtyToPickBase: Decimal; var TotalAvailQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunFindBWPickBinLoop(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToBinCode: Code[20];
        UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal;
        var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseActivLineInsert(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; ActionType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseItemTrkgLineInsert(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; FromWhseItemTrackingLine: Record "Whse. Item Tracking Line"; EntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseItemTrackingLineModify(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseItemTrackingLineModifyOnAfterAssignRemQtyToPickBase(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUseForPick(var FromBinContent: Record "Bin Content"; var IsForPick: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWhseActivLineQtyFIeldsFromCreateWhseDocPlaceLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseActivHeaderInsert(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var TempWhseActivityLine: Record "Warehouse Activity Line" temporary; CreatePickParameters: Record "Create Pick Parameters"; WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyForSN(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailQtyOnFindBWPickBin(ItemNo: Code[20]; VariantCode: Code[10]; SNRequired: Boolean; LNRequired: Boolean; WhseItemTrkgExists: Boolean; SerialNo: Code[50]; LotNo: Code[50]; LocationCode: Code[10]; BinCode: Code[20]; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; TotalQtyToPickBase: Decimal; var QtyAvailableBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailQtyOnFindPickBin2(ItemNo: Code[20]; VariantCode: Code[10]; SNRequired: Boolean; LNRequired: Boolean; WhseItemTrkgExists: Boolean; LotNo: Code[50]; SerialNo: Code[50]; LocationCode: Code[10]; BinCode: Code[20]; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; TotalQtyToPickBase: Decimal; var QtyAvailableBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailableQtyOnAfterCalcAvailableQtyBase(Item: Record Item; Location: Record Location; VariantCode: Code[10]; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; var AvailableQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailQtyOnFindBreakBulkBin(Broken: Boolean; ItemNo: Code[20]; VariantCode: Code[10]; SNRequired: Boolean; LNRequired: Boolean; WhseItemTrkgExists: Boolean; SerialNo: Code[50]; LotNo: Code[50]; LocationCode: Code[10]; BinCode: Code[20]; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; TotalQtyToPickBase: Decimal; var QtyAvailableBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailQtyOnFindSmallerUOMBin(Broken: Boolean; ItemNo: Code[20]; VariantCode: Code[10]; SNRequired: Boolean; LNRequired: Boolean; WhseItemTrkgExists: Boolean; SerialNo: Code[50]; LotNo: Code[50]; LocationCode: Code[10]; BinCode: Code[20]; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; TotalQtyToPickBase: Decimal; var QtyAvailableBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcMaxQtyOnAfterTempWhseActivLineSetFilters(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAssignedToPickOnAfterSetFilters(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckReservationOnAfterGetOutboundDocLineQtyOtsdg(var ReservationEntry: Record "Reservation Entry"; var SrcDocQtyToBeFilledByInvt: Decimal; var SrcDocQtyBaseToBeFilledByInvt: Decimal; var QtyResvdNotOnILE: Decimal; var QtyBaseResvdNotOnILE: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyToTempWhseItemTrkgLineOnBeforeTempWhseItemTrackingLineInsert(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempItemTrkgLinesOnBeforeGetFromBinContentQty(EntrySummary: Record "Entry Summary"; ItemNo: Code[20]; VariantCode: Code[10]; var TotalAvailQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempItemTrkgLinesOnAfterCalcQtyTracked(EntrySummary: Record "Entry Summary"; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var QuantityTracked: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempItemTrkgLinesOnBeforeCheckQtyToPickBase(EntrySummary: Record "Entry Summary"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; TotalAvailQtyToPickBase: Decimal; var QtytoPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempActivityLineOnAfterTransferFrom(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WhseSource: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempActivityLineOnAfterShouldCalcMaxQty(var TempWarehouseActivityLine: Record "Warehouse Activity Line"; var BreakBulkNo: Integer; var ShouldCalcMaxQty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempActivityLineAfterAssignSpecEquipment(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; QtyToPick: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempActivityLineOnAfterValidateQuantity(var TempWhseActivLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLine2OnBeforeDirectedPutAwayAndPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var TotalQtytoPick: Decimal; var TotalQtytoPickBase: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly; var IsHandled: Boolean; ReservationExists: Boolean; ReservedForItemLedgEntry: Boolean; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var TempLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnAfterCreateTempLineWithItemTracking(var TotalQtytoPickBase: Decimal; var HasExpiredItems: Boolean; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var TempLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnAfterCalcQtyBaseMaxAvailToPick(var QtyBaseMaxAvailToPick: Decimal; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnBeforeCheckReservation(SourceType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var QtyBaseMaxAvailToPick: Decimal; var isHandled: Boolean; LocationCode: Code[10]; ItemNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempActivityLineOnAfterCalcQtyToPick(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var QtyToPick: Decimal; var QtyToPickBase: Decimal; WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly; WhseSource2: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnBeforeCreateTempLineForSerialNo(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10];
        FromBinCode: Code[20]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; TotalQtytoPick: Decimal; TotalQtytoPickBase: Decimal;
        var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup";
        var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnBeforeUpdateQuantitesToPick(var QtyAvailableBase: Decimal; var QtyPerUOM: Decimal; var QtyToPick: Decimal; var QtyToPickBase: Decimal; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocumentOnAfterSaveOldValues(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var WarehouseActivityHeader: Record "Warehouse Activity Header"; LastWhseDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocumentOnAfterSetFiltersAfterLoop(var TempWhseActivLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocumentOnAfterSetFiltersBeforeLoop(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; PerBin: Boolean; PerZone: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocumentOnBeforeClearFilters(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var WhseActivHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocumentOnBeforeCreateDocAndLine(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var IsHandled: Boolean; var CreateNewHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocumentOnBeforeShowError(var ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocTakeLineOnAfterSetFilters(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line"; var WhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocTakeLineOnBeforeWhseActivLine2Insert(var WarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocPlaceLineOnAfterSetFilters(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line"; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocPlaceLineOnBeforeWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindBWPickBinOnBeforeEndLoop(var FromBinContent: Record "Bin Content"; var TotalQtyToPickBase: Decimal; var EndLoop: Boolean; var IsHandled: Boolean; QtytoPick: Decimal; QtyToPickBase: Decimal)
    begin
    end;

#if not CLEAN20
    [Obsolete('Replaced by OnFindBWPickBinOnBeforeFromBinContentFindSet with correct param naming', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnFindBWPickBinOnBeforeFindFromBinContent(var FromBinContent: Record "Bin Content"; SourceType: Integer; var TotalQtyToPickBase: Decimal; var IsHandled: Boolean; var TotalQtyToPickBase2: Decimal)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnFindBWPickBinOnBeforeFromBinContentFindSet(var FromBinContent: Record "Bin Content"; SourceType: Integer; var TotalQtyPickedBase: Decimal; var TotalQtyToPickBase: Decimal; var IsHandled: Boolean; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToBinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindBWPickBinOnBeforeSetQtyAvailableBaseForSerialNo(var FromBinContent: Record "Bin Content"; var QtyAvailableBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPickBinOnAfterUpdateTotalAvailQtyToPickBase(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; TotalAvailQtyToPickBase: Decimal; ToQtyToPick: Decimal; ToQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPickBinOnBeforeStartFromBinContentLoop(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var TotalAvailQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPickBinOnBeforeUpdateQuantitesAndCreateActivityLines(var FromBinContent: Record "Bin Content"; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var ToQtyToPick: Decimal; var ToQtyToPickBase: Decimal; var AvailableQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotalAvailQtyToPickOnBeforeCalcSubTotal(var QtyInWhse: Decimal; var QtyOnPickBins: Decimal; var QtyOnPutAwayBins: Decimal; var QtyOnOutboundBins: Decimal; var QtyOnDedicatedBins: Decimal; var QtyBlocked: Decimal; var QtyOnReceiveBins: Decimal; var ReservedQtyOnInventory: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotalAvailQtyToPickOnAfterGetWhseItemTrkgSetup(var WhseItemTrackingSetup: Record "Item Tracking Setup"; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyCanBePickedOnAfterGetWhseItemTrkgSetup(var WhseItemTrackingSetup: Record "Item Tracking Setup"; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocLineOnAfterGetWhseItemTrkgSetup(var WhseItemTrackingSetup: Record "Item Tracking Setup"; TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPickBinOnAfterGetWhseItemTrkgSetup(var WhseItemTrackingSetup: Record "Item Tracking Setup"; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocTakeLineOnBeforeWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPickAccordingToFEFO(LocationCode: Code[10]; ItemTrackingSetup: Record "Item Tracking Setup"; var PickAccordingToFEFO: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessDoNotFillQtytoHandle(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseActivHeaderOnAfterWhseActivHeaderInsert(var WhseActivHeader: Record "Warehouse Activity Header"; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; CreatePickParameters: Record "Create Pick Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBlockedBinOrTracking(BinContentBuffer: Record "Bin Content Buffer"; var IsBlocked: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemTrackedQuantityOnAfterCheckIfEmpty(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemTrackedQuantityOnAfterSetFilters(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseDocTakeLine(var WhseActivLine: Record "Warehouse Activity Line"; Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAssemblyPickLineOnAfterCalcQtyToPick(var AsmLine: Record "Assembly Line"; var QtyToPickBase: Decimal; var QtyToPick: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocPlaceLineOnAfterTempWhseActivLineSetFilters(var TempWhseActivLine: Record "Warehouse Activity Line"; WhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocPlaceLineOnAfterTransferTempWhseActivLineToWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; PickQty: Decimal; PickQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBinContent(
        var TempBinContent: Record "Bin Content" temporary;
        ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; LocationCode: Code[10]; ToBinCode: Code[20];
        CrossDock: Boolean; IsMovementWorksheet: Boolean; WhseItemTrkgExists: Boolean; BreakbulkBins: Boolean; SmallerUOMBins: Boolean;
        WhseItemTrackingSetup: Record "Item Tracking Setup"; TotalQtytoPick: Decimal; TotalQtytoPickBase: Decimal;
        var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPickBin(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10];
        UnitofMeasureCode: Code[10]; ToBinCode: Code[20]; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal;
        var TempWhseActivLine2: Record "Warehouse Activity Line" temporary; var TotalQtytoPick: Decimal;
        var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; CrossDock: Boolean;
        var TotalQtytoPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup"; IsMovementWorksheet: Boolean;
        WhseItemTrkgExists: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLocation(LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyOutstandingBaseAfterSetFilters(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; BinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindBWPickBinOnBeforeApplyBinCodeFilter(var BinCodeFilterText: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempActivityLineWithoutBinCode(var BinCode: Code[20])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBreakBulkPlacingExistsOnAfterBinContent2SetFilters(var BinContent: Record "Bin Content")
    begin
    end;
}

