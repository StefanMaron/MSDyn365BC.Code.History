codeunit 7312 "Create Pick"
{
    Permissions = TableData "Whse. Item Tracking Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        WhseActivHeader: Record "Warehouse Activity Header";
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        TempTotalWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        SourceWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        ProdOrderCompLine: Record "Prod. Order Component";
        AssemblyLine: Record "Assembly Line";
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
        WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly;
        SortPick: Option " ",Item,Document,"Shelf/Bin No.","Due Date","Ship-To","Bin Ranking","Action Type";
        WhseDocType: Option "Put-away",Pick,Movement;
        SourceSubType: Option;
        SourceNo: Code[20];
        AssignedID: Code[50];
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
        ShipmentMethodCode: Code[10];
        TransferRemQtyToPickBase: Decimal;
        TempNo: Integer;
        MaxNoOfLines: Integer;
        BreakbulkNo: Integer;
        TempLineNo: Integer;
        MaxNoOfSourceDoc: Integer;
        SourceType: Integer;
        SourceLineNo: Integer;
        SourceSubLineNo: Integer;
        LastWhseItemTrkgLineNo: Integer;
        WhseItemTrkgLineCount: Integer;
        PerZone: Boolean;
        Text000: Label 'Nothing to handle. %1.';
        PerBin: Boolean;
        DoNotFillQtytoHandle: Boolean;
        BreakbulkFilter: Boolean;
        WhseItemTrkgExists: Boolean;
        SNRequired: Boolean;
        LNRequired: Boolean;
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

    procedure CreateTempLine(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var TotalQtytoPick: Decimal; var TotalQtytoPickBase: Decimal)
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
        OnCreateTempLineOnBeforeCheckReservation(SourceType, SourceNo, SourceLineNo, QtyBaseMaxAvailToPick, IsHandled);
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

            CheckReservation(
            QtyBaseMaxAvailToPick, SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, Location."Always Create Pick Line",
            QtyPerUnitofMeasure, TotalQtytoPick, TotalQtytoPickBase);
        end;

        OnAfterCreateTempLineCheckReservation(
            LocationCode, ItemNo, VariantCode, UnitofMeasureCode, QtyPerUnitofMeasure, TotalQtytoPick, TotalQtytoPickBase,
            SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, LastWhseItemTrkgLineNo, TempWhseItemTrackingLine);

        RemQtyToPick := TotalQtytoPick;
        RemQtyToPickBase := TotalQtytoPickBase;
        ItemTrackingMgt.GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);
        SNRequired := WhseItemTrackingSetup."Serial No. Required";
        LNRequired := WhseItemTrackingSetup."Lot No. Required";

        ReqFEFOPick := false;
        HasExpiredItems := false;
        if PickAccordingToFEFO(LocationCode) or PickStrictExpirationPosting(ItemNo) then begin
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
                          Round(RemQtyToPick / RemQtyToPickBase * TempWhseItemTrackingLine."Qty. to Handle (Base)", UOMMgt.QtyRndPrecision);
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
                          QtyPerUnitofMeasure, QtyToPick, TempWhseItemTrackingLine, QtyToPickBase);
                        RemQtyToPickBase -= TempWhseItemTrackingLine."Qty. to Handle (Base)" - QtyToPickBase;
                        RemQtyToPick -= TempWhseItemTrackingLine."Qty. to Handle" - QtyToPick;
                    end;
                until (TempWhseItemTrackingLine.Next = 0) or (RemQtyToPickBase <= 0);
                RemQtyToPick := Minimum(RemQtyToPick, TotalQtytoPick - TotalItemTrackedQtyToPick);
                RemQtyToPickBase := Minimum(RemQtyToPickBase, TotalQtytoPickBase - TotalItemTrackedQtyToPickBase);
                TotalQtytoPick := RemQtyToPick;
                TotalQtytoPickBase := RemQtyToPickBase;

                SaveTempItemTrkgLines;
                Clear(TempWhseItemTrackingLine);
                WhseItemTrkgExists := false;
            end;

            OnCreateTempLineOnAfterCreateTempLineWithItemTracking(TotalQtytoPickBase, HasExpiredItems);

            if TotalQtytoPickBase <> 0 then
                if not HasExpiredItems then begin
                    if SNRequired then begin
                        for i := 1 to TotalQtytoPick do begin
                            QtyToPick := 1;
                            QtyToPickBase := 1;
                            CreateTempLine(LocationCode, ItemNo, VariantCode, UnitofMeasureCode,
                              FromBinCode, ToBinCode, QtyPerUnitofMeasure, QtyToPick, TempWhseItemTrackingLine, QtyToPickBase);
                        end;
                        TotalQtytoPick := 0;
                        TotalQtytoPickBase := 0;
                    end else
                        CreateTempLine(LocationCode, ItemNo, VariantCode, UnitofMeasureCode,
                          FromBinCode, ToBinCode, QtyPerUnitofMeasure, TotalQtytoPick, TempWhseItemTrackingLine, TotalQtytoPickBase);
                end;
        end;

        OnAfterCreateTempLine(LocationCode, ToBinCode, ItemNo, VariantCode, UnitofMeasureCode, QtyPerUnitofMeasure);
    end;

    local procedure CreateTempLine(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var TotalQtytoPickBase: Decimal)
    var
        QtytoPick: Decimal;
        QtytoPickBase: Decimal;
        QtyAvailableBase: Decimal;
        IsHandled: Boolean;
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
                      LocationCode, ItemNo, VariantCode, UnitofMeasureCode,
                      QtyPerUnitofMeasure, TotalQtytoPick, TotalQtytoPickBase, TempWhseItemTrackingLine);
                end;
                exit;
            end;

            IsHandled := false;
            OnCreateTempLine2OnBeforeDirectedPutAwayAndPick(
              LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, ToBinCode, QtyPerUnitofMeasure,
              TotalQtytoPick, TotalQtytoPickBase, TempWhseItemTrackingLine, WhseSource, IsHandled);
            if IsHandled then
                exit;

            if (WhseSource = WhseSource::"Movement Worksheet") and (FromBinCode <> '') then begin
                InsertTempActivityLineFromMovWkshLine(
                  LocationCode, ItemNo, VariantCode, FromBinCode,
                  QtyPerUnitofMeasure, TotalQtytoPick, TempWhseItemTrackingLine, TotalQtytoPickBase);
                exit;
            end;

            if (ReservationExists and ReservedForItemLedgEntry) or not ReservationExists then begin
                if Location."Use Cross-Docking" then
                    CalcPickBin(
                      LocationCode, ItemNo, VariantCode, UnitofMeasureCode,
                      ToBinCode, QtyPerUnitofMeasure,
                      TotalQtytoPick, TempWhseItemTrackingLine, true, TotalQtytoPickBase);
                if TotalQtytoPickBase > 0 then
                    CalcPickBin(
                      LocationCode, ItemNo, VariantCode, UnitofMeasureCode,
                      ToBinCode, QtyPerUnitofMeasure,
                      TotalQtytoPick, TempWhseItemTrackingLine, false, TotalQtytoPickBase);
            end;
            if (TotalQtytoPickBase > 0) and Location."Always Create Pick Line" then begin
                UpdateQuantitiesToPick(
                  TotalQtytoPickBase,
                  QtyPerUnitofMeasure, QtytoPick, QtytoPickBase,
                  QtyPerUnitofMeasure, QtytoPick, QtytoPickBase,
                  TotalQtytoPick, TotalQtytoPickBase);

                CreateTempActivityLine(
                  LocationCode, '', UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtytoPickBase, 1, 0);
                CreateTempActivityLine(
                  LocationCode, ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtytoPickBase, 2, 0);
            end;
            exit;
        end;

        QtyAvailableBase :=
          CalcAvailableQty(ItemNo, VariantCode) -
          CalcPickQtyAssigned(LocationCode, ItemNo, VariantCode, UnitofMeasureCode, '', TempWhseItemTrackingLine);

        if QtyAvailableBase > 0 then begin
            UpdateQuantitiesToPick(
              QtyAvailableBase,
              QtyPerUnitofMeasure, QtytoPick, QtytoPickBase,
              QtyPerUnitofMeasure, QtytoPick, QtytoPickBase,
              TotalQtytoPick, TotalQtytoPickBase);

            CreateTempActivityLine(LocationCode, '', UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtytoPickBase, 0, 0);
        end;
    end;

    local procedure InsertTempActivityLineFromMovWkshLine(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; FromBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var TotalQtyToPickBase: Decimal)
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
            FromBinContent.SetFilterOnUnitOfMeasure;
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
          ToQtyToPick, ToQtyToPickBase, FromQtyToPick, FromQtyToPickBase);

        TotalQtyToPickBase := 0;
        TotalQtytoPick := 0;
    end;

    local procedure CalcMaxQtytoPlace(var QtytoHandle: Decimal; QtyOutstanding: Decimal; var QtytoHandleBase: Decimal; QtyOutstandingBase: Decimal)
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
            SetRange("Action Type", "Action Type"::Place);
            SetRange("Breakbulk No.", 0);
            if Find('-') then begin
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

    local procedure CalcBWPickBin(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal; var TotalQtyToPick: Decimal; var TotalQtytoPickBase: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    var
        WhseSource2: Option;
        ToBinCode: Code[20];
        DefaultBin: Boolean;
        CrossDockBin: Boolean;
        IsHandled: Boolean;
    begin
        // Basic warehousing
        IsHandled := false;
        OnBeforeCalcBWPickBin(TotalQtyToPick, TotalQtytoPickBase, TempWhseItemTrackingLine, TempWhseActivLine, WhseItemTrkgExists, IsHandled);
        if IsHandled then
            exit;

        if (WhseSource = WhseSource::Shipment) and WhseShptLine."Assemble to Order" then
            WhseSource2 := WhseSource::Assembly
        else
            WhseSource2 := WhseSource;

        if TotalQtytoPickBase > 0 then
            case WhseSource2 of
                WhseSource::"Pick Worksheet":
                    ToBinCode := WhseWkshLine."To Bin Code";
                WhseSource::Shipment:
                    ToBinCode := WhseShptLine."Bin Code";
                WhseSource::Production:
                    ToBinCode := ProdOrderCompLine."Bin Code";
                WhseSource::Assembly:
                    ToBinCode := AssemblyLine."Bin Code";
            end;

        for CrossDockBin := true downto false do
            for DefaultBin := true downto false do
                if TotalQtytoPickBase > 0 then
                    FindBWPickBin(
                      LocationCode, ItemNo, VariantCode,
                      ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, DefaultBin, CrossDockBin,
                      TotalQtyToPick, TotalQtytoPickBase, TempWhseItemTrackingLine);
    end;

    local procedure FindBWPickBin(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToBinCode: Code[20]; UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal; DefaultBin: Boolean; CrossDockBin: Boolean; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
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
            OnBeforeSetBinCodeFilter(BinCodeFilterText, LocationCode, ItemNo, VariantCode, ToBinCode);
            if Location."Require Pick" and (Location."Shipment Bin Code" <> '') then
                AddToFilterText(BinCodeFilterText, '&', '<>', Location."Shipment Bin Code");
            if Location."Require Put-away" and (Location."Receipt Bin Code" <> '') then
                AddToFilterText(BinCodeFilterText, '&', '<>', Location."Receipt Bin Code");
            if ToBinCode <> '' then
                AddToFilterText(BinCodeFilterText, '&', '<>', ToBinCode);
            if BinCodeFilterText <> '' then
                SetFilter("Bin Code", BinCodeFilterText);
            if WhseItemTrkgExists then
                SetTrackingFilterFromWhseItemTrackingLine(TempWhseItemTrackingLine);

            IsHandled := false;
            OnFindBWPickBinOnBeforeFindFromBinContent(FromBinContent, SourceType, TotalQtyPickedBase, IsHandled);
            if not IsHandled then
                if FindSet then
                    repeat
                        QtyAvailableBase :=
                          CalcQtyAvailToPick(0) -
                          CalcPickQtyAssigned(LocationCode, ItemNo, VariantCode, '', "Bin Code", TempWhseItemTrackingLine);

                        OnCalcAvailQtyOnFindBWPickBin(
                          ItemNo, VariantCode, SNRequired, LNRequired, WhseItemTrkgExists,
                          TempWhseItemTrackingLine."Serial No.", TempWhseItemTrackingLine."Lot No.", "Location Code", "Bin Code",
                          SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtyToPickBase, QtyAvailableBase);

                        if QtyAvailableBase > 0 then begin
                            if SNRequired then
                                QtyAvailableBase := 1;

                            UpdateQuantitiesToPick(
                              QtyAvailableBase,
                              QtyPerUnitofMeasure, QtytoPick, QtyToPickBase,
                              QtyPerUnitofMeasure, QtytoPick, QtyToPickBase,
                              TotalQtyToPick, TotalQtyToPickBase);

                            CreateTempActivityLine(
                              LocationCode, "Bin Code", UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtyToPickBase, 1, 0);
                            CreateTempActivityLine(
                              LocationCode, ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtyToPickBase, 2, 0);
                        end;
                        EndLoop := false;
                        IsHandled := false;
                        OnFindBWPickBinOnBeforeEndLoop(FromBinContent, TotalQtyToPickBase, EndLoop, IsHandled);
                        if not IsHandled then
                            EndLoop := (Next = 0) or (TotalQtyToPickBase = 0);
                    until EndLoop;
        end;
    end;

    local procedure CalcPickBin(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; CrossDock: Boolean; var TotalQtytoPickBase: Decimal)
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
    begin
        // Directed put-away and pick
        OnBeforeCalcPickBin(
          TempWhseActivLine, TotalQtytoPick, TotalQtytoPickBase, TempWhseItemTrackingLine, CrossDock, WhseItemTrkgExists, WhseSource,
          LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode, QtyPerUnitofMeasure);

        if TotalQtytoPickBase > 0 then begin
            ItemTrackingMgt.GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);
            SNRequired := WhseItemTrackingSetup."Serial No. Required";
            LNRequired := WhseItemTrackingSetup."Lot No. Required";
            FindPickBin(
                LocationCode, ItemNo, VariantCode, UnitofMeasureCode,
                ToBinCode, TempWhseActivLine, TotalQtytoPick, TempWhseItemTrackingLine, CrossDock, TotalQtytoPickBase);
            if (TotalQtytoPickBase > 0) and Location."Allow Breakbulk" then begin
                FindBreakBulkBin(
                    LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode,
                    QtyPerUnitofMeasure, TempWhseActivLine, TotalQtytoPick, TempWhseItemTrackingLine, CrossDock, TotalQtytoPickBase);
                if TotalQtytoPickBase > 0 then
                    FindSmallerUOMBin(
                        LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode,
                        QtyPerUnitofMeasure, TotalQtytoPick, TempWhseItemTrackingLine, CrossDock, TotalQtytoPickBase);
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
            if WhseSource = WhseSource::"Movement Worksheet" then
                SetFilter("Bin Ranking", '<%1', Bin."Bin Ranking");
            if WhseItemTrkgExists then begin
                if WhseItemTrackingSetup."Lot No. Required" then
                    SetRange("Lot No. Filter", TempWhseItemTrackingLine."Lot No.")
                else
                    SetFilter("Lot No. Filter", '%1|%2', TempWhseItemTrackingLine."Lot No.", '');
                if WhseItemTrackingSetup."Serial No. Required" then
                    SetRange("Serial No. Filter", TempWhseItemTrackingLine."Serial No.")
                else
                    SetFilter("Serial No. Filter", '%1|%2', TempWhseItemTrackingLine."Serial No.", '');
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
                if WhseItemTrackingSetup."Lot No. Required" then
                    SetRange("Lot No.", TempWhseItemTrackingLine."Lot No.")
                else
                    SetFilter("Lot No.", '%1|%2', TempWhseItemTrackingLine."Lot No.", '');
                if WhseItemTrackingSetup."Serial No. Required" then
                    SetRange("Serial No.", TempWhseItemTrackingLine."Serial No.")
                else
                    SetFilter("Serial No.", '%1|%2', TempWhseItemTrackingLine."Serial No.", '');
            end;
            if FindFirst then
                repeat
                    BinContent2.SetRange("Bin Code", "Bin Code");
                    BinContent2.SetRange("Unit of Measure Code", UOMCode);
                    if BinContent2.IsEmpty then begin
                        BinContent2.SetRange("Unit of Measure Code");
                        if BinContent2.FindFirst then begin
                            TempBinContent := BinContent2;
                            TempBinContent.Validate("Unit of Measure Code", UOMCode);
                            if TempBinContent.Insert() then;
                        end;
                    end;
                until Next = 0;
        end;
        TempWhseActivLine.Copy(WhseActivLine2);
        exit(not TempBinContent.IsEmpty);
    end;

    local procedure FindPickBin(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; ToBinCode: Code[20]; var TempWhseActivLine2: Record "Warehouse Activity Line" temporary; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; CrossDock: Boolean; var TotalQtytoPickBase: Decimal)
    var
        FromBinContent: Record "Bin Content";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        FromQtyToPick: Decimal;
        FromQtyToPickBase: Decimal;
        ToQtyToPick: Decimal;
        ToQtyToPickBase: Decimal;
        TotalAvailQtyToPickBase: Decimal;
        AvailableQtyBase: Decimal;
        BinIsForPick: Boolean;
        BinIsForReplenishment: Boolean;
    begin
        // Directed put-away and pick
        GetBin(LocationCode, ToBinCode);
        GetLocation(LocationCode);

        WhseItemTrackingSetup."Serial No. Required" := true;
        WhseItemTrackingSetup."Lot No. Required" := true;
        WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine);

        if FromBinContent.GetBinContent(
            ItemNo, VariantCode, UnitofMeasureCode, LocationCode, ToBinCode, CrossDock,
            WhseSource = WhseSource::"Movement Worksheet", WhseItemTrkgExists, WhseItemTrackingSetup)
        then begin
            TotalAvailQtyToPickBase :=
                CalcTotalAvailQtyToPick(
                    LocationCode, ItemNo, VariantCode,
                    TempWhseItemTrackingLine."Lot No.", TempWhseItemTrackingLine."Serial No.",
                    SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtytoPickBase, false);
            if TotalAvailQtyToPickBase < 0 then
                TotalAvailQtyToPickBase := 0;

            repeat
                BinIsForPick := UseForPick(FromBinContent) and (WhseSource <> WhseSource::"Movement Worksheet");
                BinIsForReplenishment := UseForReplenishment(FromBinContent) and (WhseSource = WhseSource::"Movement Worksheet");
                if FromBinContent."Bin Code" <> ToBinCode then
                    CalcBinAvailQtyToPick(AvailableQtyBase, FromBinContent, TempWhseActivLine2);
                if BinIsForPick or BinIsForReplenishment then begin
                    if TotalAvailQtyToPickBase < AvailableQtyBase then
                        AvailableQtyBase := TotalAvailQtyToPickBase;

                    if TotalQtytoPickBase < AvailableQtyBase then
                        AvailableQtyBase := TotalQtytoPickBase;

                    OnCalcAvailQtyOnFindPickBin(
                        ItemNo, VariantCode, SNRequired, LNRequired, WhseItemTrkgExists,
                        TempWhseItemTrackingLine."Lot No.", TempWhseItemTrackingLine."Serial No.",
                        FromBinContent."Location Code", FromBinContent."Bin Code",
                        SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtytoPickBase, AvailableQtyBase);

                    if AvailableQtyBase > 0 then begin
                        ToQtyToPickBase := CalcQtyToPickBase(FromBinContent, TempWhseActivLine);
                        if AvailableQtyBase > ToQtyToPickBase then
                            AvailableQtyBase := ToQtyToPickBase;

                        UpdateQuantitiesToPick(
                            AvailableQtyBase,
                            FromBinContent."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase,
                            FromBinContent."Qty. per Unit of Measure", ToQtyToPick, ToQtyToPickBase,
                            TotalQtytoPick, TotalQtytoPickBase);

                        CreateTempActivityLine(
                            LocationCode, FromBinContent."Bin Code", UnitofMeasureCode, FromBinContent."Qty. per Unit of Measure",
                            FromQtyToPick, FromQtyToPickBase, 1, 0);
                        CreateTempActivityLine(
                            LocationCode, ToBinCode, UnitofMeasureCode, FromBinContent."Qty. per Unit of Measure",
                            ToQtyToPick, ToQtyToPickBase, 2, 0);

                        TotalAvailQtyToPickBase := TotalAvailQtyToPickBase - ToQtyToPickBase;
                    end;
                end else
                    EnqueueCannotBeHandledReason(
                        GetMessageForUnhandledQtyDueToBin(
                            BinIsForPick, BinIsForReplenishment, WhseSource = WhseSource::"Movement Worksheet",
                            AvailableQtyBase, FromBinContent."Bin Code"));
            until (FromBinContent.Next() = 0) or (TotalQtytoPickBase = 0);
        end;
    end;

    local procedure FindBreakBulkBin(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToUOMCode: Code[10]; ToBinCode: Code[20]; ToQtyPerUOM: Decimal; var TempWhseActivLine2: Record "Warehouse Activity Line" temporary; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; CrossDock: Boolean; var TotalQtytoPickBase: Decimal)
    var
        FromItemUOM: Record "Item Unit of Measure";
        FromBinContent: Record "Bin Content";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        FromQtyToPick: Decimal;
        FromQtyToPickBase: Decimal;
        ToQtyToPick: Decimal;
        ToQtyToPickBase: Decimal;
        QtyAvailableBase: Decimal;
        TotalAvailQtyToPickBase: Decimal;
    begin
        // Directed put-away and pick
        GetBin(LocationCode, ToBinCode);

        TotalAvailQtyToPickBase :=
          CalcTotalAvailQtyToPick(
            LocationCode, ItemNo, VariantCode, TempWhseItemTrackingLine."Lot No.", TempWhseItemTrackingLine."Serial No.",
            SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, 0, false);

        if TotalAvailQtyToPickBase < 0 then
            TotalAvailQtyToPickBase := 0;

        if not Location."Always Create Pick Line" then begin
            if TotalAvailQtyToPickBase = 0 then
                exit;

            if TotalAvailQtyToPickBase < TotalQtytoPickBase then begin
                TotalQtytoPickBase := TotalAvailQtyToPickBase;
                TotalQtytoPick := Round(TotalQtytoPickBase / ToQtyPerUOM, UOMMgt.QtyRndPrecision);
            end;
        end;

        WhseItemTrackingSetup."Serial No. Required" := SNRequired;
        WhseItemTrackingSetup."Lot No. Required" := LNRequired;
        WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine);

        FromItemUOM.SetCurrentKey("Item No.", "Qty. per Unit of Measure");
        FromItemUOM.SetRange("Item No.", ItemNo);
        FromItemUOM.SetFilter("Qty. per Unit of Measure", '>=%1', ToQtyPerUOM);
        FromItemUOM.SetFilter(Code, '<>%1', ToUOMCode);
        if FromItemUOM.Find('-') then
            repeat
                if FromBinContent.GetBinContent(
                    ItemNo, VariantCode, FromItemUOM.Code, LocationCode, ToBinCode, CrossDock,
                    WhseSource = WhseSource::"Movement Worksheet", WhseItemTrkgExists, WhseItemTrackingSetup)
                then
                    repeat
                        if (FromBinContent."Bin Code" <> ToBinCode) and
                            ((UseForPick(FromBinContent) and (WhseSource <> WhseSource::"Movement Worksheet")) or
                            (UseForReplenishment(FromBinContent) and (WhseSource = WhseSource::"Movement Worksheet")))
                        then begin
                            // Check and use bulk that has previously been broken
                            QtyAvailableBase := CalcBinAvailQtyInBreakbulk(TempWhseActivLine2, FromBinContent, ToUOMCode);

                            OnCalcAvailQtyOnFindBreakBulkBin(
                                true, ItemNo, VariantCode, SNRequired, LNRequired, WhseItemTrkgExists,
                                TempWhseItemTrackingLine."Lot No.", TempWhseItemTrackingLine."Serial No.",
                                FromBinContent."Location Code", FromBinContent."Bin Code",
                                SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtytoPickBase, QtyAvailableBase);

                            if QtyAvailableBase > 0 then begin
                                UpdateQuantitiesToPick(
                                    QtyAvailableBase,
                                    ToQtyPerUOM, FromQtyToPick, FromQtyToPickBase,
                                    ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase,
                                    TotalQtytoPick, TotalQtytoPickBase);

                                CreateBreakBulkTempLines(
                                    FromBinContent."Location Code", ToUOMCode, ToUOMCode,
                                    FromBinContent."Bin Code", ToBinCode, ToQtyPerUOM, ToQtyPerUOM,
                                    0, FromQtyToPick, FromQtyToPickBase, ToQtyToPick, ToQtyToPickBase);
                            end;

                            if TotalQtytoPickBase <= 0 then
                                exit;

                            // Now break bulk and use
                            QtyAvailableBase := CalcBinAvailQtyToBreakbulk(TempWhseActivLine2, FromBinContent, WhseItemTrackingSetup);

                            OnCalcAvailQtyOnFindBreakBulkBin(
                                false, ItemNo, VariantCode, SNRequired, LNRequired, WhseItemTrkgExists,
                                TempWhseItemTrackingLine."Lot No.", TempWhseItemTrackingLine."Serial No.",
                                FromBinContent."Location Code", FromBinContent."Bin Code",
                                SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtytoPickBase, QtyAvailableBase);

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
                                    BreakbulkNo, ToQtyToPick, ToQtyToPickBase, FromQtyToPick, FromQtyToPickBase);
                            end;
                            if TotalQtytoPickBase <= 0 then
                                exit;
                        end;
                    until FromBinContent.Next() = 0;
            until FromItemUOM.Next = 0;
    end;

    local procedure FindSmallerUOMBin(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; ToBinCode: Code[20]; QtyPerUnitOfMeasure: Decimal; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; CrossDock: Boolean; var TotalQtytoPickBase: Decimal)
    var
        ItemUOM: Record "Item Unit of Measure";
        FromBinContent: Record "Bin Content";
        TempFromBinContent: Record "Bin Content" temporary;
        WhseItemTrackingSetup: Record "Item Tracking Setup";
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
            LocationCode, ItemNo, VariantCode,
            TempWhseItemTrackingLine."Lot No.", TempWhseItemTrackingLine."Serial No.",
            SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, 0, false);

        if TotalAvailQtyToPickBase < 0 then
            TotalAvailQtyToPickBase := 0;

        if not Location."Always Create Pick Line" then begin
            if TotalAvailQtyToPickBase = 0 then
                exit;

            if TotalAvailQtyToPickBase < TotalQtytoPickBase then begin
                TotalQtytoPickBase := TotalAvailQtyToPickBase;
                ItemUOM.Get(ItemNo, UnitofMeasureCode);
                TotalQtytoPick := Round(TotalQtytoPickBase / ItemUOM."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
            end;
        end;

        GetBin(LocationCode, ToBinCode);

        WhseItemTrackingSetup."Serial No. Required" := SNRequired;
        WhseItemTrackingSetup."Lot No. Required" := LNRequired;
        WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine);

        ItemUOM.SetCurrentKey("Item No.", "Qty. per Unit of Measure");
        ItemUOM.SetRange("Item No.", ItemNo);
        ItemUOM.SetFilter("Qty. per Unit of Measure", '<%1', QtyPerUnitOfMeasure);
        ItemUOM.SetFilter(Code, '<>%1', UnitofMeasureCode);
        ItemUOM.Ascending(false);
        if ItemUOM.Find('-') then
            repeat
                if FromBinContent.GetBinContent(
                    ItemNo, VariantCode, ItemUOM.Code, LocationCode, ToBinCode, CrossDock,
                    WhseSource = WhseSource::"Movement Worksheet", WhseItemTrkgExists, WhseItemTrackingSetup)
                then
                    repeat
                        if (FromBinContent."Bin Code" <> ToBinCode) and
                            ((UseForPick(FromBinContent) and (WhseSource <> WhseSource::"Movement Worksheet")) or
                            (UseForReplenishment(FromBinContent) and (WhseSource = WhseSource::"Movement Worksheet")))
                        then begin
                            CalcBinAvailQtyFromSmallerUOM(QtyAvailableBase, FromBinContent, false);

                            OnCalcAvailQtyOnFindSmallerUOMBin(
                                false, ItemNo, VariantCode, SNRequired, LNRequired, WhseItemTrkgExists,
                                TempWhseItemTrackingLine."Lot No.", TempWhseItemTrackingLine."Serial No.",
                                FromBinContent."Location Code", FromBinContent."Bin Code",
                                SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtytoPickBase, QtyAvailableBase);

                            if QtyAvailableBase > 0 then begin
                                UpdateQuantitiesToPick(
                                    QtyAvailableBase,
                                    ItemUOM."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase,
                                    QtyPerUnitOfMeasure, ToQtyToPick, ToQtyToPickBase,
                                    TotalQtytoPick, TotalQtytoPickBase);

                                CreateTempActivityLine(
                                    LocationCode, FromBinContent."Bin Code", FromBinContent."Unit of Measure Code",
                                    ItemUOM."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase, 1, 0);
                                CreateTempActivityLine(
                                    LocationCode, ToBinCode, UnitofMeasureCode,
                                    QtyPerUnitOfMeasure, ToQtyToPick, ToQtyToPickBase, 2, 0);

                                TotalAvailQtyToPickBase := TotalAvailQtyToPickBase - ToQtyToPickBase;
                            end;
                        end;
                    until (FromBinContent.Next() = 0) or (TotalQtytoPickBase = 0);

                if TotalQtytoPickBase > 0 then
                    if BreakBulkPlacingExists(TempFromBinContent, ItemNo, LocationCode, ItemUOM.Code, VariantCode, CrossDock, WhseItemTrackingSetup) then
                        repeat
                            if (TempFromBinContent."Bin Code" <> ToBinCode) and
                                ((UseForPick(TempFromBinContent) and (WhseSource <> WhseSource::"Movement Worksheet")) or
                                (UseForReplenishment(TempFromBinContent) and (WhseSource = WhseSource::"Movement Worksheet")))
                            then begin
                                CalcBinAvailQtyFromSmallerUOM(QtyAvailableBase, TempFromBinContent, true);

                                OnCalcAvailQtyOnFindSmallerUOMBin(
                                    true, ItemNo, VariantCode, SNRequired, LNRequired, WhseItemTrkgExists,
                                    TempWhseItemTrackingLine."Lot No.", TempWhseItemTrackingLine."Serial No.",
                                    TempFromBinContent."Location Code", TempFromBinContent."Bin Code",
                                    SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtytoPickBase, QtyAvailableBase);

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

    procedure CalcBinAvailQtyToPick(var QtyToPickBase: Decimal; var BinContent: Record "Bin Content"; var TempWhseActivLine: Record "Warehouse Activity Line")
    var
        AvailableQtyBase: Decimal;
    begin
        with TempWhseActivLine do begin
            Reset;
            SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Action Type",
              "Variant Code", "Unit of Measure Code", "Breakbulk No.");
            SetRange("Item No.", BinContent."Item No.");
            SetRange("Bin Code", BinContent."Bin Code");
            SetRange("Location Code", BinContent."Location Code");
            SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
            SetRange("Variant Code", BinContent."Variant Code");
            if WhseItemTrkgExists then begin
                if LNRequired then
                    SetRange("Lot No.", TempWhseItemTrackingLine."Lot No.")
                else
                    SetFilter("Lot No.", '%1|%2', TempWhseItemTrackingLine."Lot No.", '');
                if SNRequired then
                    SetRange("Serial No.", TempWhseItemTrackingLine."Serial No.")
                else
                    SetFilter("Serial No.", '%1|%2', TempWhseItemTrackingLine."Serial No.", '');
            end;

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
            SetFilterOnUnitOfMeasure;
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
            if WhseItemTrkgExists then begin
                WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine);
                SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup);
            end else
                ClearTrackingFilter;

            ClearSourceFilter;
            SetRange("Breakbulk No.");
            CalcSums("Qty. (Base)");
            QtyToPickBase := QtyToPickBase - "Qty. (Base)";
            exit(QtyToPickBase);
        end;
    end;

    local procedure CalcBinAvailQtyInBreakbulk(var TempWhseActivLine2: Record "Warehouse Activity Line"; var BinContent: Record "Bin Content"; ToUOMCode: Code[10]) QtyToPickBase: Decimal
    begin
        with TempWhseActivLine2 do begin
            if (MaxNoOfSourceDoc > 1) or (MaxNoOfLines <> 0) then
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
            if WhseItemTrkgExists then begin
                if LNRequired then
                    SetRange("Lot No.", TempWhseItemTrackingLine."Lot No.")
                else
                    SetFilter("Lot No.", '%1|%2', TempWhseItemTrackingLine."Lot No.", '');
                if SNRequired then
                    SetRange("Serial No.", TempWhseItemTrackingLine."Serial No.")
                else
                    SetFilter("Serial No.", '%1|%2', TempWhseItemTrackingLine."Serial No.", '');
            end else begin
                SetRange("Lot No.");
                SetRange("Serial No.");
            end;
            SetRange("Breakbulk No.", 0);
            CalcSums("Qty. (Base)");
            QtyToPickBase := "Qty. (Base)";

            SetRange("Action Type", "Action Type"::Place);
            SetFilter("Breakbulk No.", '<>0');
            SetRange("No.", Format(TempNo));
            if MaxNoOfSourceDoc = 1 then begin
                SetRange("Source Type", WhseWkshLine."Source Type");
                SetRange("Source Subtype", WhseWkshLine."Source Subtype");
                SetRange("Source No.", WhseWkshLine."Source No.");
            end;
            CalcSums("Qty. (Base)");
            QtyToPickBase := "Qty. (Base)" - QtyToPickBase;
            exit(QtyToPickBase);
        end;
    end;

    local procedure CalcBinAvailQtyFromSmallerUOM(var AvailableQtyBase: Decimal; var BinContent: Record "Bin Content"; AllowInitialZero: Boolean)
    begin
        with BinContent do begin
            SetFilterOnUnitOfMeasure;
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
            if WhseItemTrkgExists then begin
                if LNRequired then
                    SetRange("Lot No.", TempWhseItemTrackingLine."Lot No.")
                else
                    SetFilter("Lot No.", '%1|%2', TempWhseItemTrackingLine."Lot No.", '');
                if SNRequired then
                    SetRange("Serial No.", TempWhseItemTrackingLine."Serial No.")
                else
                    SetFilter("Serial No.", '%1|%2', TempWhseItemTrackingLine."Serial No.", '');
            end else begin
                SetRange("Lot No.");
                SetRange("Serial No.");
            end;
            CalcSums("Qty. (Base)");
            AvailableQtyBase := AvailableQtyBase - "Qty. (Base)";

            SetRange("Action Type", "Action Type"::Place);
            SetFilter("Breakbulk No.", '<>0');
            CalcSums("Qty. (Base)");
            AvailableQtyBase := AvailableQtyBase + "Qty. (Base)";
            Reset;
        end;
    end;

    local procedure CreateBreakBulkTempLines(LocationCode: Code[10]; FromUOMCode: Code[10]; ToUOMCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; FromQtyPerUOM: Decimal; ToQtyPerUOM: Decimal; BreakbulkNo2: Integer; ToQtyToPick: Decimal; ToQtyToPickBase: Decimal; FromQtyToPick: Decimal; FromQtyToPickBase: Decimal)
    var
        QtyToBreakBulk: Decimal;
    begin
        // Directed put-away and pick
        if FromUOMCode <> ToUOMCode then begin
            CreateTempActivityLine(
              LocationCode, FromBinCode, FromUOMCode, FromQtyPerUOM, FromQtyToPick, FromQtyToPickBase, 1, BreakbulkNo2);

            if FromQtyToPickBase = ToQtyToPickBase then
                QtyToBreakBulk := ToQtyToPick
            else
                QtyToBreakBulk := Round(FromQtyToPick * FromQtyPerUOM / ToQtyPerUOM, UOMMgt.QtyRndPrecision);
            CreateTempActivityLine(
              LocationCode, FromBinCode, ToUOMCode, ToQtyPerUOM, QtyToBreakBulk, FromQtyToPickBase, 2, BreakbulkNo2);
        end;
        CreateTempActivityLine(LocationCode, FromBinCode, ToUOMCode, ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase, 1, 0);
        CreateTempActivityLine(LocationCode, ToBinCode, ToUOMCode, ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase, 2, 0);
    end;

    procedure CreateWhseDocument(var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; ShowError: Boolean)
    var
        WhseActivLine: Record "Warehouse Activity Line";
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
                Error(Text000, DequeueCannotBeHandledReason);
            exit;
        end;

        OnBeforeCreateWhseDocument(TempWhseActivLine, WhseSource);

        WhseActivHeader.LockTable();
        if WhseActivHeader.FindLast then;
        WhseActivLine.LockTable();
        if WhseActivLine.FindLast then;

        if WhseSource = WhseSource::"Movement Worksheet" then
            TempWhseActivLine.SetRange("Activity Type", TempWhseActivLine."Activity Type"::Movement)
        else
            TempWhseActivLine.SetRange("Activity Type", TempWhseActivLine."Activity Type"::Pick);

        NoOfLines := 0;
        NoOfSourceDoc := 0;

        repeat
            GetLocation(TempWhseActivLine."Location Code");
            if not FindWhseActivLine(TempWhseActivLine, Location, FirstWhseDocNo, LastWhseDocNo) then
                exit;

            if PerBin then
                TempWhseActivLine.SetRange("Bin Code", TempWhseActivLine."Bin Code");
            if PerZone then
                TempWhseActivLine.SetRange("Zone Code", TempWhseActivLine."Zone Code");

            OnCreateWhseDocumentOnAfterSetFiltersBeforeLoop(TempWhseActivLine, PerBin, PerZone);

            repeat
                IsHandled := false;
                CreateNewHeader := false;
                OnCreateWhseDocumentOnBeforeCreateDocAndLine(TempWhseActivLine, IsHandled, CreateNewHeader);
                if IsHandled then begin
                    if CreateNewHeader then begin
                        CreateWhseActivHeader(
                          TempWhseActivLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
                          NoOfSourceDoc, NoOfLines, WhseDocCreated);
                        CreateWhseDocLine;
                    end else
                        CreateNewWhseDoc(
                          OldNo, OldSourceNo, OldLocationCode, FirstWhseDocNo, LastWhseDocNo,
                          NoOfSourceDoc, NoOfLines, WhseDocCreated);
                end else
                    if PerBin then begin
                        if TempWhseActivLine."Bin Code" <> OldBinCode then begin
                            CreateWhseActivHeader(
                              TempWhseActivLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
                              NoOfSourceDoc, NoOfLines, WhseDocCreated);
                            CreateWhseDocLine;
                        end else
                            CreateNewWhseDoc(
                              OldNo, OldSourceNo, OldLocationCode, FirstWhseDocNo, LastWhseDocNo,
                              NoOfSourceDoc, NoOfLines, WhseDocCreated);
                    end else begin
                        if PerZone then begin
                            if TempWhseActivLine."Zone Code" <> OldZoneCode then begin
                                CreateWhseActivHeader(
                                  TempWhseActivLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
                                  NoOfSourceDoc, NoOfLines, WhseDocCreated);
                                CreateWhseDocLine;
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
                OnCreateWhseDocumentOnAfterSaveOldValues(TempWhseActivLine);
            until TempWhseActivLine.Next = 0;
            OnCreateWhseDocumentOnBeforeClearFilters(TempWhseActivLine);
            TempWhseActivLine.SetRange("Bin Code");
            TempWhseActivLine.SetRange("Zone Code");
            TempWhseActivLine.SetRange("Location Code");
            TempWhseActivLine.SetRange("Action Type");
            OnCreateWhseDocumentOnAfterSetFiltersAfterLoop(TempWhseActivLine);
            if not TempWhseActivLine.Find('-') then begin
                OnAfterCreateWhseDocument(FirstWhseDocNo, LastWhseDocNo);
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
            CreateWhseDocLine;
        end else begin
            NoOfLines := NoOfLines + 1;
            if TempWhseActivLine."Source No." <> OldSourceNo then
                NoOfSourceDoc := NoOfSourceDoc + 1;
            if (MaxNoOfSourceDoc > 0) and (NoOfSourceDoc > MaxNoOfSourceDoc) then
                CreateWhseActivHeader(
                  TempWhseActivLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
                  NoOfSourceDoc, NoOfLines, WhseDocCreated);
            if (MaxNoOfLines > 0) and (NoOfLines > MaxNoOfLines) then
                CreateWhseActivHeader(
                  TempWhseActivLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
                  NoOfSourceDoc, NoOfLines, WhseDocCreated);
            CreateWhseDocLine;
        end;
    end;

    local procedure CreateWhseActivHeader(LocationCode: Code[10]; var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; var NoOfSourceDoc: Integer; var NoOfLines: Integer; var WhseDocCreated: Boolean)
    begin
        WhseActivHeader.Init();
        WhseActivHeader."No." := '';
        if WhseDocType = WhseDocType::Movement then
            WhseActivHeader.Type := WhseActivHeader.Type::Movement
        else
            WhseActivHeader.Type := WhseActivHeader.Type::Pick;
        WhseActivHeader."Location Code" := LocationCode;
        if AssignedID <> '' then
            WhseActivHeader.Validate("Assigned User ID", AssignedID);
        WhseActivHeader."Sorting Method" := SortPick;
        WhseActivHeader."Breakbulk Filter" := BreakbulkFilter;
        OnBeforeWhseActivHeaderInsert(WhseActivHeader, TempWhseActivLine);
        WhseActivHeader.Insert(true);

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
    begin
        TempWhseActivLine.SetRange("Breakbulk No.", 0);
        TempWhseActivLine.Find('-');
        WhseActivLine.SetRange("Activity Type", WhseActivHeader.Type);
        WhseActivLine.SetRange("No.", WhseActivHeader."No.");
        if WhseActivLine.FindLast then
            LineNo := WhseActivLine."Line No."
        else
            LineNo := 0;

        ItemTrackingMgt.GetWhseItemTrkgSetup(TempWhseActivLine."Item No.", WhseItemTrackingSetup);
        SNRequired := WhseItemTrackingSetup."Serial No. Required";
        LNRequired := WhseItemTrackingSetup."Lot No. Required";

        LineNo := LineNo + 10000;
        WhseActivLine.Init();
        WhseActivLine := TempWhseActivLine;
        WhseActivLine."No." := WhseActivHeader."No.";
        if not (WhseActivLine."Whse. Document Type" in [
                                                        WhseActivLine."Whse. Document Type"::"Internal Pick",
                                                        WhseActivLine."Whse. Document Type"::"Movement Worksheet"])
        then
            WhseActivLine."Source Document" := WhseMgt.GetSourceDocument(WhseActivLine."Source Type", WhseActivLine."Source Subtype");

        if Location."Bin Mandatory" and (not SNRequired) then
            CreateWhseDocTakeLine(WhseActivLine, LineNo)
        else
            TempWhseActivLine.Delete();

        if WhseActivLine."Qty. (Base)" <> 0 then begin
            WhseActivLine."Line No." := LineNo;
            if DoNotFillQtytoHandle then begin
                WhseActivLine."Qty. to Handle" := 0;
                WhseActivLine."Qty. to Handle (Base)" := 0;
                WhseActivLine.Cubage := 0;
                WhseActivLine.Weight := 0;
            end;
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
    begin
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
        OnCreateWhseDocTakeLineOnAfterSetFilters(TempWhseActivLine, TempWhseActivLine2);
        if TempWhseActivLine.Find('-') then begin
            repeat
                WhseActivLine.Quantity := WhseActivLine.Quantity + TempWhseActivLine.Quantity;
            until TempWhseActivLine.Next = 0;
            TempWhseActivLine.DeleteAll();
            WhseActivLine.Validate(Quantity);
        end;

        // insert breakbulk lines
        if Location."Directed Put-away and Pick" then begin
            TempWhseActivLine.ClearSourceFilter;
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

                    if DoNotFillQtytoHandle then begin
                        WhseActivLine2."Qty. to Handle" := 0;
                        WhseActivLine2."Qty. to Handle (Base)" := 0;
                        WhseActivLine2.Cubage := 0;
                        WhseActivLine2.Weight := 0;
                    end;
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

                    if DoNotFillQtytoHandle then begin
                        WhseActivLine2."Qty. to Handle" := 0;
                        WhseActivLine2."Qty. to Handle (Base)" := 0;
                        WhseActivLine2.Cubage := 0;
                        WhseActivLine2.Weight := 0;
                    end;

                    WhseActivLine2."Original Breakbulk" :=
                      WhseActivLine."Qty. (Base)" = WhseActivLine2."Qty. (Base)";
                    if BreakbulkFilter then
                        WhseActivLine2.Breakbulk := WhseActivLine2."Original Breakbulk";
                    WhseActivLine2.Insert();
                    OnAfterWhseActivLineInsert(WhseActivLine2);

                    TempWhseActivLine.Delete();
                    LineNo := LineNo + 10000;

                    TempWhseActivLine.Copy(WhseActivLine3);
                    WhseActivLine."Original Breakbulk" := WhseActivLine2."Original Breakbulk";
                    if BreakbulkFilter then
                        WhseActivLine.Breakbulk := WhseActivLine."Original Breakbulk";
                until TempWhseActivLine.Next = 0;
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

                with WhseActivLine do
                    if (PickQty * "Qty. per Unit of Measure") <> PickQtyBase then
                        PickQty := Round(PickQtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);

                PickQtyBase := PickQtyBase - WhseActivLine."Qty. (Base)";
                PickQty := PickQty - WhseActivLine.Quantity;

                WhseActivLine."No." := WhseActivHeader."No.";
                WhseActivLine."Line No." := LineNo;

                if not (WhseActivLine."Whse. Document Type" in [
                                                                WhseActivLine."Whse. Document Type"::"Internal Pick",
                                                                WhseActivLine."Whse. Document Type"::"Movement Worksheet"])
                then
                    WhseActivLine."Source Document" := WhseMgt.GetSourceDocument(WhseActivLine."Source Type", WhseActivLine."Source Subtype");

                TempWhseActivLine.Delete();
                if PickQtyBase > 0 then begin
                    TempWhseActivLine3.Copy(TempWhseActivLine);
                    TempWhseActivLine.SetRange(
                      "Unit of Measure Code", WhseActivLine."Unit of Measure Code");
                    TempWhseActivLine.SetFilter("Line No.", '>%1', TempWhseActivLine."Line No.");
                    TempWhseActivLine.SetRange("No.", TempWhseActivLine2."No.");
                    TempWhseActivLine.SetRange("Bin Code", WhseActivLine."Bin Code");
                    if TempWhseActivLine.Find('-') then begin
                        repeat
                            if TempWhseActivLine."Qty. (Base)" >= PickQtyBase then begin
                                WhseActivLine.Quantity := WhseActivLine.Quantity + PickQty;
                                WhseActivLine."Qty. (Base)" := WhseActivLine."Qty. (Base)" + PickQtyBase;
                                PickQty := 0;
                                PickQtyBase := 0;
                            end else begin
                                WhseActivLine.Quantity := WhseActivLine.Quantity + TempWhseActivLine.Quantity;
                                WhseActivLine."Qty. (Base)" := WhseActivLine."Qty. (Base)" + TempWhseActivLine."Qty. (Base)";
                                PickQty := PickQty - TempWhseActivLine.Quantity;
                                PickQtyBase := PickQtyBase - TempWhseActivLine."Qty. (Base)";
                                TempWhseActivLine.Delete();
                            end;
                        until (TempWhseActivLine.Next = 0) or (PickQtyBase = 0);
                    end else
                        if TempWhseActivLine.Delete then;
                    TempWhseActivLine.Copy(TempWhseActivLine3);
                end;

                if WhseActivLine.Quantity > 0 then begin
                    TempWhseActivLine3 := WhseActivLine;
                    WhseActivLine.Validate(Quantity);
                    WhseActivLine."Qty. (Base)" := TempWhseActivLine3."Qty. (Base)";
                    WhseActivLine."Qty. Outstanding (Base)" := TempWhseActivLine3."Qty. (Base)";
                    WhseActivLine."Qty. to Handle (Base)" := TempWhseActivLine3."Qty. (Base)";
                    if DoNotFillQtytoHandle then begin
                        WhseActivLine."Qty. to Handle" := 0;
                        WhseActivLine."Qty. to Handle (Base)" := 0;
                        WhseActivLine.Cubage := 0;
                        WhseActivLine.Weight := 0;
                    end;
                    WhseActivLine.Insert();
                    OnAfterWhseActivLineInsert(WhseActivLine);
                end;
            until (TempWhseActivLine.Next = 0) or (PickQtyBase = 0);

        TempWhseActivLine.Copy(TempWhseActivLine2);
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

        if (WhseSource = WhseSource::Shipment) and WhseShptLine."Assemble to Order" then
            WhseSource2 := WhseSource::Assembly
        else
            WhseSource2 := WhseSource;
        case WhseSource2 of
            WhseSource::"Pick Worksheet", WhseSource::"Movement Worksheet":
                LineReservedQty :=
                  WhseAvailMgt.CalcLineReservedQtyOnInvt(
                    WhseWkshLine."Source Type",
                    WhseWkshLine."Source Subtype",
                    WhseWkshLine."Source No.",
                    WhseWkshLine."Source Line No.",
                    WhseWkshLine."Source Subline No.",
                    true, '', '', TempWhseActivLine);
            WhseSource::Shipment:
                LineReservedQty :=
                  WhseAvailMgt.CalcLineReservedQtyOnInvt(
                    WhseShptLine."Source Type",
                    WhseShptLine."Source Subtype",
                    WhseShptLine."Source No.",
                    WhseShptLine."Source Line No.",
                    0,
                    true, '', '', TempWhseActivLine);
            WhseSource::Production:
                LineReservedQty :=
                  WhseAvailMgt.CalcLineReservedQtyOnInvt(
                    DATABASE::"Prod. Order Component",
                    ProdOrderCompLine.Status,
                    ProdOrderCompLine."Prod. Order No.",
                    ProdOrderCompLine."Prod. Order Line No.",
                    ProdOrderCompLine."Line No.",
                    true, '', '', TempWhseActivLine);
            WhseSource::Assembly:
                LineReservedQty :=
                  WhseAvailMgt.CalcLineReservedQtyOnInvt(
                    DATABASE::"Assembly Line",
                    AssemblyLine."Document Type",
                    AssemblyLine."Document No.",
                    AssemblyLine."Line No.",
                    0,
                    true, '', '', TempWhseActivLine);
        end;

        QtyReservedOnPickShip := WhseAvailMgt.CalcReservQtyOnPicksShips(Location.Code, ItemNo, VariantCode, TempWhseActivLine);
        QtyOnDedicatedBins := WhseAvailMgt.CalcQtyOnDedicatedBins(Location.Code, ItemNo, VariantCode, '', '');

        exit(AvailableQtyBase + LineReservedQty + QtyReservedOnPickShip - QtyOnDedicatedBins);
    end;

    local procedure CalcPickQtyAssigned(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; BinCode: Code[20]; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary) PickQtyAssigned: Decimal
    var
        WhseActivLine2: Record "Warehouse Activity Line";
    begin
        WhseActivLine2.Copy(TempWhseActivLine);
        with TempWhseActivLine do begin
            Reset;
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
            if WhseItemTrkgExists then begin
                if TempWhseItemTrackingLine."Lot No." <> '' then
                    SetRange("Lot No.", TempWhseItemTrackingLine."Lot No.");
                if TempWhseItemTrackingLine."Serial No." <> '' then
                    SetRange("Serial No.", TempWhseItemTrackingLine."Serial No.");
            end;
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
            Reset;
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
            if WhseItemTrackingSetup."Lot No." <> '' then
                if WhseItemTrackingSetup."Lot No. Required" then
                    SetRange("Lot No.", WhseItemTrackingSetup."Lot No.")
                else
                    SetFilter("Lot No.", '%1|%2', WhseItemTrackingSetup."Lot No.", '');
            if WhseItemTrackingSetup."Serial No." <> '' then
                if WhseItemTrackingSetup."Serial No. Required" then
                    SetRange("Serial No.", WhseItemTrackingSetup."Serial No.")
                else
                    SetFilter("Serial No.", '%1|%2', WhseItemTrackingSetup."Serial No.", '');
            OnCalcQtyAssignedToPickOnAfterSetFilters(WhseActivLine);
            CalcSums("Qty. Outstanding (Base)");

            exit("Qty. Outstanding (Base)" + CalcBreakbulkOutstdQty(WhseActivLine, LNRequired, SNRequired));
        end;
    end;

    local procedure UseForPick(FromBinContent: Record "Bin Content"): Boolean
    begin
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
    end;

    local procedure GetBinType(BinTypeCode: Code[10])
    begin
        if BinTypeCode = '' then
            BinType.Init
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

    procedure SetValues(AssignedID2: Code[50]; WhseDocument2: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly; SortPick2: Option " ",Item,Document,"Shelf/Bin No.","Due Date","Ship-To","Bin Ranking","Action Type"; WhseDocType2: Option "Put-away",Pick,Movement; MaxNoOfSourceDoc2: Integer; MaxNoOfLines2: Integer; PerZone2: Boolean; DoNotFillQtytoHandle2: Boolean; BreakbulkFilter2: Boolean; PerBin2: Boolean)
    begin
        WhseSource := WhseDocument2;
        AssignedID := AssignedID2;
        SortPick := SortPick2;
        WhseDocType := WhseDocType2;
        PerBin := PerBin2;
        if PerBin then
            PerZone := false
        else
            PerZone := PerZone2;
        DoNotFillQtytoHandle := DoNotFillQtytoHandle2;
        MaxNoOfSourceDoc := MaxNoOfSourceDoc2;
        MaxNoOfLines := MaxNoOfLines2;
        BreakbulkFilter := BreakbulkFilter2;
        WhseSetup.Get();
        WhseSetupLocation.GetLocationSetup('', WhseSetupLocation);
        Clear(TempWhseActivLine);
        LastWhseItemTrkgLineNo := 0;

        OnAfterSetValues(
          AssignedID, SortPick, MaxNoOfSourceDoc, MaxNoOfLines, PerBin, PerZone, DoNotFillQtytoHandle, BreakbulkFilter, WhseSource);
    end;

    procedure SetWhseWkshLine(WhseWkshLine2: Record "Whse. Worksheet Line"; TempNo2: Integer)
    begin
        WhseWkshLine := WhseWkshLine2;
        TempNo := TempNo2;
        SetSource(
          WhseWkshLine2."Source Type",
          WhseWkshLine2."Source Subtype",
          WhseWkshLine2."Source No.",
          WhseWkshLine2."Source Line No.",
          WhseWkshLine2."Source Subline No.");

        OnAfterSetWhseWkshLine(WhseWkshLine);
    end;

    procedure SetWhseShipment(WhseShptLine2: Record "Warehouse Shipment Line"; TempNo2: Integer; ShippingAgentCode2: Code[10]; ShippingAgentServiceCode2: Code[10]; ShipmentMethodCode2: Code[10])
    begin
        WhseShptLine := WhseShptLine2;
        TempNo := TempNo2;
        ShippingAgentCode := ShippingAgentCode2;
        ShippingAgentServiceCode := ShippingAgentServiceCode2;
        ShipmentMethodCode := ShipmentMethodCode2;
        SetSource(
          WhseShptLine2."Source Type",
          WhseShptLine2."Source Subtype",
          WhseShptLine2."Source No.",
          WhseShptLine2."Source Line No.",
          0);

        OnAfterSetWhseShipment(WhseShptLine);
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
          DATABASE::"Prod. Order Component",
          ProdOrderCompLine2.Status,
          ProdOrderCompLine2."Prod. Order No.",
          ProdOrderCompLine2."Prod. Order Line No.",
          ProdOrderCompLine2."Line No.");

        OnAfterSetProdOrderCompLine(ProdOrderCompLine);
    end;

    procedure SetAssemblyLine(AssemblyLine2: Record "Assembly Line"; TempNo2: Integer)
    begin
        AssemblyLine := AssemblyLine2;
        TempNo := TempNo2;
        SetSource(
          DATABASE::"Assembly Line",
          AssemblyLine2."Document Type",
          AssemblyLine2."Document No.",
          AssemblyLine2."Line No.",
          0);

        OnAfterSetAssemblyLine(AssemblyLine);
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

    [Scope('OnPrem')]
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
    begin
        with TempWhseItemTrackingLine do begin
            TempWhseItemTrackingLine := WhseItemTrackingLine;
            "Entry No." := LastWhseItemTrkgLineNo + 1;
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
    end;

    local procedure SaveTempItemTrkgLines()
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
            until (TempWhseItemTrackingLine.Next = 0) or (i = WhseItemTrkgLineCount);
    end;

    procedure ReturnTempItemTrkgLines(var TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary)
    begin
        if TempTotalWhseItemTrackingLine.Find('-') then
            repeat
                TempWhseItemTrackingLine2 := TempTotalWhseItemTrackingLine;
                TempWhseItemTrackingLine2.Insert();
            until TempTotalWhseItemTrackingLine.Next = 0;
    end;

    local procedure CreateTempItemTrkgLines(ItemNo: Code[20]; VariantCode: Code[10]; TotalQtyToPickBase: Decimal; HasExpiryDate: Boolean)
    var
        EntrySummary: Record "Entry Summary";
        DummyEntrySummary2: Record "Entry Summary";
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
        OnBeforeCreateTempItemTrkgLines(Location, ItemNo, VariantCode, TotalQtyToPickBase, HasExpiryDate, IsHandled);
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
                    QtyTracked := ItemTrackedQuantity(EntrySummary."Lot No.", EntrySummary."Serial No.");

                    if not ((EntrySummary."Serial No." <> '') and (QtyTracked > 0)) then begin
                        TotalAvailQtyToPickBase :=
                          CalcTotalAvailQtyToPick(
                            Location.Code, ItemNo, VariantCode,
                            EntrySummary."Lot No.", EntrySummary."Serial No.",
                            SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, 0, HasExpiryDate);

                        if CalledFromWksh and (WhseWkshLine."From Bin Code" <> '') then begin
                            FromBinContentQty :=
                              GetFromBinContentQty(
                                WhseWkshLine."Location Code", WhseWkshLine."From Bin Code", WhseWkshLine."Item No.",
                                WhseWkshLine."Variant Code", WhseWkshLine."From Unit of Measure Code",
                                EntrySummary."Lot No.", EntrySummary."Serial No.");
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
            HasExpiredItems := WhseItemTrackingFEFO.GetHasExpiredItems;
            EnqueueCannotBeHandledReason(WhseItemTrackingFEFO.GetResultMessageForExpiredItem);
        end;
    end;

    procedure ItemTrackedQuantity(LotNo: Code[50]; SerialNo: Code[50]): Decimal
    begin
        with TempWhseItemTrackingLine do begin
            Reset;
            if (LotNo = '') and (SerialNo = '') then
                if IsEmpty then
                    exit(0);

            if SerialNo <> '' then begin
                SetCurrentKey("Serial No.", "Lot No.");
                SetRange("Serial No.", SerialNo);
                if IsEmpty then
                    exit(0);

                exit(1);
            end;

            if LotNo <> '' then begin
                SetCurrentKey("Serial No.", "Lot No.");
                SetRange("Lot No.", LotNo);
                if IsEmpty then
                    exit(0);
            end;

            SetCurrentKey(
              "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.", "Location Code");
            if LotNo <> '' then
                SetRange("Lot No.", LotNo);
            CalcSums("Qty. to Handle (Base)");
            exit("Qty. to Handle (Base)");
        end;
    end;

    procedure InsertTempItemTrkgLine(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; EntrySummary: Record "Entry Summary"; QuantityBase: Decimal)
    begin
        with TempWhseItemTrackingLine do begin
            Init;
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
            Insert;
            LastWhseItemTrkgLineNo := "Entry No.";
            WhseItemTrkgExists := true;
        end;
    end;

    local procedure TransferItemTrkgFields(var WhseActivLine2: Record "Warehouse Activity Line"; TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    var
        EntriesExist: Boolean;
    begin
        if WhseItemTrkgExists then begin
            if TempWhseItemTrackingLine."Serial No." <> '' then
                TempWhseItemTrackingLine.TestField("Qty. per Unit of Measure", 1);
            WhseActivLine2.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine);
            WhseActivLine2."Warranty Date" := TempWhseItemTrackingLine."Warranty Date";
            if TempWhseItemTrackingLine.TrackingExists then
                WhseActivLine2."Expiration Date" :=
                  ItemTrackingMgt.ExistingExpirationDate(
                    TempWhseItemTrackingLine."Item No.", TempWhseItemTrackingLine."Variant Code",
                    TempWhseItemTrackingLine."Lot No.", TempWhseItemTrackingLine."Serial No.",
                    false, EntriesExist);
            OnAfterTransferItemTrkgFields(WhseActivLine2, TempWhseItemTrackingLine, EntriesExist);
        end else
            if SNRequired then
                WhseActivLine2.TestField("Qty. per Unit of Measure", 1);
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
            until ReservEntry.Next = 0;
            QtyBaseResvdNotOnILE := QtyResvdNotOnILE;
            QtyResvdNotOnILE := Round(QtyResvdNotOnILE / QtyPerUnitOfMeasure, UOMMgt.QtyRndPrecision);

            WhseManagement.GetOutboundDocLineQtyOtsdg(SourceType, SourceSubType,
              SourceNo, SourceLineNo, SourceSubLineNo, SrcDocQtyToBeFilledByInvt, SrcDocQtyBaseToBeFilledByInvt);
            SrcDocQtyBaseToBeFilledByInvt := SrcDocQtyBaseToBeFilledByInvt - QtyBaseResvdNotOnILE;
            SrcDocQtyToBeFilledByInvt := SrcDocQtyToBeFilledByInvt - QtyResvdNotOnILE;

            if QuantityBase > SrcDocQtyBaseToBeFilledByInvt then begin
                QuantityBase := SrcDocQtyBaseToBeFilledByInvt;
                Quantity := SrcDocQtyToBeFilledByInvt;
            end;

            if QuantityBase <= SrcDocQtyBaseToBeFilledByInvt then
                if (QuantityBase > QtyBaseAvailToPick) and (QtyBaseAvailToPick >= 0) then begin
                    QuantityBase := QtyBaseAvailToPick;
                    Quantity := Round(QtyBaseAvailToPick / QtyPerUnitOfMeasure, UOMMgt.QtyRndPrecision);
                end;

            ReservedForItemLedgEntry := QuantityBase <> 0;
            if AlwaysCreatePickLine then begin
                Quantity := Quantity2;
                QuantityBase := QuantityBase2;
            end;

            if Quantity <= 0 then
                EnqueueCannotBeHandledReason(GetMessageForUnhandledQtyDueToReserv);
        end else
            ReservationExists := false;
    end;

    procedure CalcTotalAvailQtyToPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; NeededQtyBase: Decimal; RespectLocationBins: Boolean): Decimal
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
          LocationCode, ItemNo, VariantCode, LotNo, SerialNo, SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo,
          NeededQtyBase, RespectLocationBins, CalledFromMoveWksh, CalledFromWksh, TempWhseActivLine, IsHandled, TotalAvailQtyBase);
        if IsHandled then
            exit(TotalAvailQtyBase);

        // Directed put-away and pick
        GetLocation(LocationCode);

        ItemTrackingMgt.GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);
        WhseItemTrackingSetup."Serial No." := SerialNo;
        WhseItemTrackingSetup."Lot No." := LotNo;
        SNRequired := WhseItemTrackingSetup."Serial No. Required";
        LNRequired := WhseItemTrackingSetup."Lot No. Required";

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
            SourceType, LocationCode, ItemNo, VariantCode, LotNo, SerialNo, CalledFromPickWksh, CalledFromMoveWksh, CalledFromWksh,
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

        QtyOnDedicatedBins := WhseAvailMgt.CalcQtyOnDedicatedBins(LocationCode, ItemNo, VariantCode, LotNo, SerialNo);

        QtyBlocked := WhseAvailMgt.CalcQtyOnBlockedITOrOnBlockedOutbndBins(LocationCode, ItemNo, VariantCode, LotNo, SerialNo, LNRequired, SNRequired);

        TempWhseItemTrackingLine2.Copy(TempWhseItemTrackingLine);
        if ReqFEFOPick then begin
            TempWhseItemTrackingLine2."Entry No." := TempWhseItemTrackingLine2."Entry No." + 1;
            TempWhseItemTrackingLine2."Lot No." := LotNo;
            TempWhseItemTrackingLine2."Serial No." := SerialNo;
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
            FilterWhsePickLinesWithUndefinedBin(
              WhseActivLine, ItemNo, LocationCode, VariantCode, LNRequired, LotNo, SNRequired, SerialNo);
            WhseActivLine.CalcSums("Qty. Outstanding (Base)");
            QtyAssignedPick := QtyAssignedPick - WhseActivLine."Qty. Outstanding (Base)";
        end;

        SubTotal :=
          QtyInWhse - QtyOnPickBins - QtyOnPutAwayBins - QtyOnOutboundBins - QtyOnDedicatedBins - QtyBlocked -
          QtyOnReceiveBins - Abs(ReservedQtyOnInventory);

        if (SubTotal < 0) or CalledFromPickWksh or CalledFromMoveWksh then begin
            TempTrackingSpecification."Lot No." := LotNo;
            TempTrackingSpecification."Serial No." := SerialNo;
            QtyReservedOnPickShip :=
                WhseAvailMgt.CalcReservQtyOnPicksShipsWithItemTracking(TempWhseActivLine, TempTrackingSpecification, LocationCode, ItemNo, VariantCode);

            LineReservedQty :=
                WhseAvailMgt.CalcLineReservedQtyOnInvt(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, true, '', '', TempWhseActivLine);

            if SubTotal < 0 then
                if Abs(SubTotal) < QtyReservedOnPickShip + LineReservedQty then
                    QtyReservedOnPickShip := Abs(SubTotal) - LineReservedQty;

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
                            QtyOnPickBins + QtyOnPutAwayBins - QtyAssignedToPick - Abs(ReservedQtyOnInventory) + QtyReservedOnPickShip + LineReservedQty;
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
            if ReleaseNonSpecificReservations(LocationCode, ItemNo, VariantCode, LotNo, SerialNo, NeededQtyBase - TotalAvailQtyBase) then begin
                AvailableAfterReshuffle :=
                    CalcTotalAvailQtyToPick(
                        LocationCode, ItemNo, VariantCode,
                        TempWhseItemTrackingLine."Lot No.", TempWhseItemTrackingLine."Serial No.",
                        SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, 0, false);
                exit(AvailableAfterReshuffle);
            end;

        exit(TotalAvailQtyBase - QtyOnToBinsBase);
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

    [Obsolete('Procedure moved to codeunit WarehouseAvailabilityMgt.', '16.0')]
    procedure CalcQtyOnOutboundBins(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; ExcludeDedicatedBinContent: Boolean) QtyOnOutboundBins: Decimal
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
    begin
        WhseItemTrackingSetup."Serial No." := SerialNo;
        WhseItemTrackingSetup."Lot No." := LotNo;
        exit(
            WhseAvailMgt.CalcQtyOnOutboundBins(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, ExcludeDedicatedBinContent));
    end;

    local procedure CalcQtyCanBePicked(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; EntrySummary: Record "Entry Summary"; IsMovement: Boolean): Decimal
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        BinTypeFilter: Text;
        QtyOnOutboundBins: Decimal;
    begin
        ItemTrackingMgt.GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);
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

    procedure GetBinTypeFilter(Type: Option Receive,Ship,"Put Away",Pick,"Put Away only"): Text[1024]
    var
        BinType: Record "Bin Type";
        "Filter": Text[1024];
    begin
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
                    Filter := StrSubstNo('%1|%2', Filter, Code);
                until Next = 0;
            if Filter <> '' then
                Filter := CopyStr(Filter, 2);
        end;
        exit(Filter);
    end;

    procedure CheckOutBound(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer): Decimal
    var
        WhseShipLine: Record "Warehouse Shipment Line";
        WhseActLine: Record "Warehouse Activity Line";
        ProdOrderComp: Record "Prod. Order Component";
        AsmLine: Record "Assembly Line";
        OutBoundQty: Decimal;
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
                    if WhseShipLine.FindFirst then begin
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
                        if WhseActLine.FindFirst then
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
                    if ProdOrderComp.FindFirst then begin
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
        exit(OutBoundQty);
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

    local procedure CalcQtyToPickBase(var BinContent: Record "Bin Content"; var TempWhseActivLine: Record "Warehouse Activity Line" temporary): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseJrnl: Record "Warehouse Journal Line";
        QtyPlaced: Decimal;
        QtyTaken: Decimal;
    begin
        with BinContent do begin
            WhseEntry.SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.");
            WhseEntry.SetRange("Location Code", "Location Code");
            WhseEntry.SetRange("Bin Code", "Bin Code");
            WhseEntry.SetRange("Item No.", "Item No.");
            WhseEntry.SetRange("Variant Code", "Variant Code");
            WhseEntry.SetRange("Unit of Measure Code", "Unit of Measure Code");
            CopyFilter("Serial No. Filter", WhseEntry."Serial No.");
            CopyFilter("Lot No. Filter", WhseEntry."Lot No.");
            WhseEntry.CalcSums("Qty. (Base)");

            WhseActivLine.SetCurrentKey(
              "Item No.", "Bin Code", "Location Code",
              "Action Type", "Variant Code", "Unit of Measure Code", "Breakbulk No.", "Activity Type", "Lot No.", "Serial No.");
            WhseActivLine.SetRange("Location Code", "Location Code");
            WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Take);
            WhseActivLine.SetRange("Bin Code", "Bin Code");
            WhseActivLine.SetRange("Item No.", "Item No.");
            WhseActivLine.SetRange("Variant Code", "Variant Code");
            WhseActivLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
            CopyFilter("Lot No. Filter", WhseActivLine."Lot No.");
            CopyFilter("Serial No. Filter", WhseActivLine."Serial No.");
            WhseActivLine.CalcSums("Qty. Outstanding (Base)");
            QtyTaken := WhseActivLine."Qty. Outstanding (Base)";

            TempWhseActivLine.Copy(WhseActivLine);
            TempWhseActivLine.CalcSums("Qty. Outstanding (Base)");
            QtyTaken += TempWhseActivLine."Qty. Outstanding (Base)";

            TempWhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Place);
            TempWhseActivLine.CalcSums("Qty. Outstanding (Base)");
            QtyPlaced := TempWhseActivLine."Qty. Outstanding (Base)";

            TempWhseActivLine.Reset();

            WhseJrnl.SetCurrentKey(
              "Item No.", "From Bin Code", "Location Code", "Entry Type", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.");
            WhseJrnl.SetRange("Location Code", "Location Code");
            WhseJrnl.SetRange("From Bin Code", "Bin Code");
            WhseJrnl.SetRange("Item No.", "Item No.");
            WhseJrnl.SetRange("Variant Code", "Variant Code");
            WhseJrnl.SetRange("Unit of Measure Code", "Unit of Measure Code");
            CopyFilter("Lot No. Filter", WhseJrnl."Lot No.");
            CopyFilter("Serial No. Filter", WhseJrnl."Serial No.");
            WhseJrnl.CalcSums("Qty. (Absolute, Base)");

            exit(WhseEntry."Qty. (Base)" + WhseJrnl."Qty. (Absolute, Base)" + QtyPlaced - QtyTaken);
        end;
    end;

    local procedure PickAccordingToFEFO(LocationCode: Code[10]): Boolean
    begin
        GetLocation(LocationCode);
        exit(Location."Pick According to FEFO" and (SNRequired or LNRequired));
    end;

    local procedure UndefinedItemTrkg(var QtyToTrackBase: Decimal): Boolean
    begin
        QtyToTrackBase := QtyToTrackBase - ItemTrackedQuantity('', '');
        exit(QtyToTrackBase > 0);
    end;

    local procedure ReleaseNonSpecificReservations(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; QtyToRelease: Decimal): Boolean
    var
        LateBindingMgt: Codeunit "Late Binding Management";
        xReservedQty: Decimal;
    begin
        if QtyToRelease <= 0 then
            exit;

        if LNRequired or SNRequired then
            if Item."Reserved Qty. on Inventory" > 0 then begin
                xReservedQty := Item."Reserved Qty. on Inventory";
                LateBindingMgt.ReleaseForReservation(ItemNo, VariantCode, LocationCode, SerialNo, LotNo, QtyToRelease);
                Item.CalcFields("Reserved Qty. on Inventory");
            end;

        exit(xReservedQty > Item."Reserved Qty. on Inventory");
    end;

    procedure SetCalledFromWksh(NewCalledFromWksh: Boolean)
    begin
        CalledFromWksh := NewCalledFromWksh;
    end;

    local procedure GetFromBinContentQty(LocCode: Code[10]; FromBinCode: Code[20]; ItemNo: Code[20]; Variant: Code[20]; UoMCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]): Decimal
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.Get(LocCode, FromBinCode, ItemNo, Variant, UoMCode);
        BinContent.SetRange("Lot No. Filter", LotNo);
        BinContent.SetRange("Serial No. Filter", SerialNo);
        BinContent.CalcFields("Quantity (Base)");
        exit(BinContent."Quantity (Base)");
    end;

    procedure CreateTempActivityLine(LocationCode: Code[10]; BinCode: Code[20]; UOMCode: Code[10]; QtyPerUOM: Decimal; QtyToPick: Decimal; QtyToPickBase: Decimal; ActionType: Integer; BreakBulkNo: Integer)
    var
        WhseSource2: Option;
    begin
        if Location."Directed Put-away and Pick" then
            GetBin(LocationCode, BinCode);

        TempLineNo := TempLineNo + 10000;
        with TempWhseActivLine do begin
            Reset;
            Init;

            "No." := Format(TempNo);
            "Location Code" := LocationCode;
            "Unit of Measure Code" := UOMCode;
            "Qty. per Unit of Measure" := QtyPerUOM;
            "Starting Date" := WorkDate;
            "Bin Code" := BinCode;
            "Action Type" := ActionType;
            "Breakbulk No." := BreakBulkNo;
            "Line No." := TempLineNo;

            case WhseSource of
                WhseSource::"Pick Worksheet":
                    TransferFromPickWkshLine(WhseWkshLine);
                WhseSource::Shipment:
                    if WhseShptLine."Assemble to Order" then
                        TransferFromATOShptLine(WhseShptLine, AssemblyLine)
                    else
                        TransferFromShptLine(WhseShptLine);
                WhseSource::"Internal Pick":
                    TransferFromIntPickLine(WhseInternalPickLine);
                WhseSource::Production:
                    TransferFromCompLine(ProdOrderCompLine);
                WhseSource::Assembly:
                    TransferFromAssemblyLine(AssemblyLine);
                WhseSource::"Movement Worksheet":
                    TransferFromMovWkshLine(WhseWkshLine);
            end;

            OnCreateTempActivityLineOnAfterTransferFrom(TempWhseActivLine);

            if (WhseSource = WhseSource::Shipment) and WhseShptLine."Assemble to Order" then
                WhseSource2 := WhseSource::Assembly
            else
                WhseSource2 := WhseSource;
            if (BreakBulkNo = 0) and ("Action Type" = "Action Type"::Place) then
                case WhseSource2 of
                    WhseSource::"Pick Worksheet", WhseSource::"Movement Worksheet":
                        CalcMaxQtytoPlace(
                          QtyToPick, WhseWkshLine."Qty. to Handle", QtyToPickBase, WhseWkshLine."Qty. to Handle (Base)");
                    WhseSource::Shipment:
                        begin
                            WhseShptLine.CalcFields("Pick Qty.", "Pick Qty. (Base)");
                            CalcMaxQtytoPlace(
                              QtyToPick,
                              WhseShptLine.Quantity -
                              WhseShptLine."Qty. Picked" -
                              WhseShptLine."Pick Qty.",
                              QtyToPickBase,
                              WhseShptLine."Qty. (Base)" -
                              WhseShptLine."Qty. Picked (Base)" -
                              WhseShptLine."Pick Qty. (Base)");
                        end;
                    WhseSource::"Internal Pick":
                        begin
                            WhseInternalPickLine.CalcFields("Pick Qty.", "Pick Qty. (Base)");
                            CalcMaxQtytoPlace(
                              QtyToPick,
                              WhseInternalPickLine.Quantity -
                              WhseInternalPickLine."Qty. Picked" -
                              WhseInternalPickLine."Pick Qty.",
                              QtyToPickBase,
                              WhseInternalPickLine."Qty. (Base)" -
                              WhseInternalPickLine."Qty. Picked (Base)" -
                              WhseInternalPickLine."Pick Qty. (Base)");
                        end;
                    WhseSource::Production:
                        begin
                            ProdOrderCompLine.CalcFields("Pick Qty.", "Pick Qty. (Base)");
                            CalcMaxQtytoPlace(
                              QtyToPick,
                              ProdOrderCompLine."Expected Quantity" -
                              ProdOrderCompLine."Qty. Picked" -
                              ProdOrderCompLine."Pick Qty.",
                              QtyToPickBase,
                              ProdOrderCompLine."Expected Qty. (Base)" -
                              ProdOrderCompLine."Qty. Picked (Base)" -
                              ProdOrderCompLine."Pick Qty. (Base)");
                        end;
                    WhseSource::Assembly:
                        begin
                            AssemblyLine.CalcFields("Pick Qty.", "Pick Qty. (Base)");
                            CalcMaxQtytoPlace(
                              QtyToPick,
                              AssemblyLine.Quantity -
                              AssemblyLine."Qty. Picked" -
                              AssemblyLine."Pick Qty.",
                              QtyToPickBase,
                              AssemblyLine."Quantity (Base)" -
                              AssemblyLine."Qty. Picked (Base)" -
                              AssemblyLine."Pick Qty. (Base)");
                        end;
                end;

            if (LocationCode <> '') and (BinCode <> '') then begin
                GetBin(LocationCode, BinCode);
                Dedicated := Bin.Dedicated;
            end;
            if Location."Directed Put-away and Pick" then begin
                "Zone Code" := Bin."Zone Code";
                "Bin Ranking" := Bin."Bin Ranking";
                "Bin Type Code" := Bin."Bin Type Code";
                if Location."Special Equipment" <> Location."Special Equipment"::" " then
                    "Special Equipment Code" :=
                      AssignSpecEquipment(LocationCode, BinCode, "Item No.", "Variant Code");
            end;

            Validate(Quantity, QtyToPick);
            if QtyToPickBase <> 0 then begin
                "Qty. (Base)" := QtyToPickBase;
                "Qty. to Handle (Base)" := QtyToPickBase;
                "Qty. Outstanding (Base)" := QtyToPickBase;
            end;

            case WhseSource of
                WhseSource::Shipment:
                    begin
                        "Shipping Agent Code" := ShippingAgentCode;
                        "Shipping Agent Service Code" := ShippingAgentServiceCode;
                        "Shipment Method Code" := ShipmentMethodCode;
                        "Shipping Advice" := "Shipping Advice";
                    end;
                WhseSource::Production, WhseSource::Assembly:
                    if "Shelf No." = '' then begin
                        Item."No." := "Item No.";
                        Item.ItemSKUGet(Item, "Location Code", "Variant Code");
                        "Shelf No." := Item."Shelf No.";
                    end;
                WhseSource::"Movement Worksheet":
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
            Insert;
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
                    FromQtyToPick := Round(ToQtyToPickBase / FromQtyPerUOM, UOMMgt.QtyRndPrecision);
                    FromQtyToPickBase := ToQtyToPickBase;
                end;
            else
                FromQtyToPick := Round(ToQtyToPickBase / FromQtyPerUOM, 1, '>');
                FromQtyToPickBase := FromQtyToPick * FromQtyPerUOM;
                if FromQtyToPickBase > QtyAvailableBase then begin
                    FromQtyToPickBase := ToQtyToPickBase;
                    FromQtyToPick := Round(FromQtyToPickBase / FromQtyPerUOM, UOMMgt.QtyRndPrecision);
                end;
        end;
    end;

    local procedure UpdateToQtyToPick(QtyAvailableBase: Decimal; ToQtyPerUOM: Decimal; var ToQtyToPick: Decimal; var ToQtyToPickBase: Decimal; TotalQtyToPick: Decimal; TotalQtyToPickBase: Decimal)
    begin
        ToQtyToPickBase := QtyAvailableBase;
        if ToQtyToPickBase > TotalQtyToPickBase then
            ToQtyToPickBase := TotalQtyToPickBase;

        ToQtyToPick := Round(ToQtyToPickBase / ToQtyPerUOM, UOMMgt.QtyRndPrecision);
        if ToQtyToPick > TotalQtyToPick then
            ToQtyToPick := TotalQtyToPick;
        if (ToQtyToPick <> TotalQtyToPick) and (ToQtyToPickBase = TotalQtyToPickBase) then
            if Abs(1 - ToQtyToPick / TotalQtyToPick) <= UOMMgt.QtyRndPrecision then
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
          CalcTotalQtyAssgndOnWhseAct(TempWhseActivLine."Activity Type"::" ", LocationCode, ItemNo, VariantCode);
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct(TempWhseActivLine."Activity Type"::"Put-away", LocationCode, ItemNo, VariantCode);
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct(TempWhseActivLine."Activity Type"::Pick, LocationCode, ItemNo, VariantCode);
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct(TempWhseActivLine."Activity Type"::Movement, LocationCode, ItemNo, VariantCode);
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct(TempWhseActivLine."Activity Type"::"Invt. Put-away", LocationCode, ItemNo, VariantCode);
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct(TempWhseActivLine."Activity Type"::"Invt. Pick", LocationCode, ItemNo, VariantCode);

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
            QtyAssgndToAsmLine := CalcQtyPickedNotConsumedBase;
        end;

        OnAfterCalcTotalQtyAssgndOnWhse(
            LocationCode, ItemNo, VariantCode, QtyAssgndToWhseAct, QtyAssgndToShipment, QtyAssgndToProdComp, QtyAssgndToAsmLine);

        exit(QtyAssgndToWhseAct + QtyAssgndToShipment + QtyAssgndToProdComp + QtyAssgndToAsmLine);
    end;

    local procedure CalcTotalQtyAssgndOnWhseAct(ActivityType: Option; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
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

    local procedure CalcTotalQtyOnBinType(BinTypeFilter: Text[1024]; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
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

    procedure CalcBreakbulkOutstdQty(var WhseActivLine: Record "Warehouse Activity Line"; LNRequired: Boolean; SNRequired: Boolean): Decimal
    var
        BinContent: Record "Bin Content";
        WhseActivLine1: Record "Warehouse Activity Line";
        WhseActivLine2: Record "Warehouse Activity Line";
        TempUOM: Record "Unit of Measure" temporary;
        QtyOnBreakbulk: Decimal;
    begin
        with WhseActivLine1 do begin
            CopyFilters(WhseActivLine);
            SetFilter("Breakbulk No.", '<>%1', 0);
            SetRange("Action Type", "Action Type"::Place);
            if FindSet then begin
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
                        if LNRequired then
                            BinContent.SetRange("Lot No. Filter", "Lot No.")
                        else
                            BinContent.SetFilter("Lot No. Filter", '%1|%2', "Lot No.", '');
                        if SNRequired then
                            BinContent.SetRange("Serial No. Filter", "Serial No.")
                        else
                            BinContent.SetFilter("Serial No. Filter", '%1|%2', "Serial No.", '');

                        if BinContent.FindSet then
                            repeat
                                BinContent.SetFilterOnUnitOfMeasure;
                                BinContent.CalcFields("Quantity (Base)", "Pick Quantity (Base)");
                                if BinContent."Pick Quantity (Base)" > BinContent."Quantity (Base)" then
                                    QtyOnBreakbulk -= (BinContent."Pick Quantity (Base)" - BinContent."Quantity (Base)");
                            until BinContent.Next = 0
                        else begin
                            WhseActivLine2.CopyFilters(WhseActivLine1);
                            WhseActivLine2.SetFilter("Action Type", '%1|%2', "Action Type"::" ", "Action Type"::Take);
                            WhseActivLine2.SetRange("Breakbulk No.", 0);
                            WhseActivLine2.CalcSums("Qty. Outstanding (Base)");
                            QtyOnBreakbulk -= WhseActivLine2."Qty. Outstanding (Base)";
                        end;
                        SetRange("Unit of Measure Code");
                    end;
                until Next = 0;
            end;
            exit(QtyOnBreakbulk);
        end;
    end;

    procedure GetCannotBeHandledReason(): Text
    begin
        exit(DequeueCannotBeHandledReason);
    end;

    local procedure PickStrictExpirationPosting(ItemNo: Code[20]): Boolean
    var
        StrictExpirationPosting: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePickStrictExpirationPosting(ItemNo, SNRequired, LNRequired, StrictExpirationPosting, IsHandled);
        if IsHandled then
            exit(StrictExpirationPosting);

        exit(ItemTrackingMgt.StrictExpirationPosting(ItemNo) and (SNRequired or LNRequired));
    end;

    local procedure AddToFilterText(var TextVar: Text[250]; Separator: Code[1]; Comparator: Code[2]; Addendum: Code[20])
    begin
        if TextVar = '' then
            TextVar := Comparator + Addendum
        else
            TextVar += Separator + Comparator + Addendum;
    end;

    procedure CreateAssemblyPickLine(AsmLine: Record "Assembly Line")
    var
        QtyToPickBase: Decimal;
        QtyToPick: Decimal;
    begin
        with AsmLine do begin
            TestField("Qty. per Unit of Measure");
            QtyToPickBase := CalcQtyToPickBase;
            QtyToPick := CalcQtyToPick;
            if QtyToPick > 0 then begin
                SetAssemblyLine(AsmLine, 1);
                SetTempWhseItemTrkgLine(
                  "Document No.", DATABASE::"Assembly Line", '', 0, "Line No.", "Location Code");
                CreateTempLine(
                  "Location Code", "No.", "Variant Code", "Unit of Measure Code", '', "Bin Code",
                  "Qty. per Unit of Measure", QtyToPick, QtyToPickBase);
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
    begin
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
            if SourceType = DATABASE::"Prod. Order Component" then begin
                SetRange("Source Ref. No.", SourceSubLineNo);
                SetRange("Source Prod. Order Line", SourceLineNo);
            end else
                SetRange("Source Ref. No.", SourceLineNo);
            SetRange("Source Type", SourceType);
            SetRange("Source Subtype", SourceSubType);
            SetRange("Reservation Status", "Reservation Status"::Reservation);
        end;
    end;

    procedure GetActualQtyPickedBase(): Decimal
    begin
        exit(TotalQtyPickedBase);
    end;

    [Obsolete('Replaced by CalcReservedQtyOnInventory with WhseItemTrackingSetup as parameter.', '16.0')]
    procedure CalcReservedQtyOnInventory(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; LotNo: Code[50]; LNRequired: Boolean; SerialNo: Code[50]; SNRequired: Boolean) ReservedQty: Decimal
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
    begin
        WhseItemTrackingSetup."Lot No. Required" := LNRequired;
        WhseItemTrackingSetup."Serial No. Required" := SNRequired;
        WhseItemTrackingSetup."Lot No." := LotNo;
        WhseItemTrackingSetup."Serial No." := SerialNo;
        exit(CalcReservedQtyOnInventory(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup));
    end;

    procedure CalcReservedQtyOnInventory(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; WhseItemTrackingSetup: record "Item Tracking Setup") ReservedQty: Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        TempBinContentBuffer: Record "Bin Content Buffer" temporary;
    begin
        ReservedQty := 0;

        with ReservationEntry do begin
            SetRange("Item No.", ItemNo);
            SetRange("Source Type", DATABASE::"Item Ledger Entry");
            SetRange("Source Subtype", 0);
            SetRange("Reservation Status", "Reservation Status"::Reservation);
            SetRange("Location Code", LocationCode);
            SetRange("Variant Code", VariantCode);
            SetTrackingFilterFromWhseItemTrackingSetupIfRequired(WhseItemTrackingSetup);
            if FindSet then
                repeat
                    InsertTempBinContentBuf(
                      TempBinContentBuffer, "Location Code", '', "Item No.", "Variant Code", '', "Lot No.", "Serial No.", "Quantity (Base)");
                until Next = 0;

            DistrubuteReservedQtyByBins(TempBinContentBuffer);
            TempBinContentBuffer.CalcSums("Qty. to Handle (Base)");
            ReservedQty := TempBinContentBuffer."Qty. to Handle (Base)";
        end;

        OnAfterCalcReservedQtyOnInventory(
            ItemNo, LocationCode, VariantCode,
            WhseItemTrackingSetup."Lot No.", WhseItemTrackingSetup."Lot No. Required",
            WhseItemTrackingSetup."Serial No.", WhseItemTrackingSetup."Serial No. Required",
            ReservedQty, WhseItemTrackingSetup);
    end;

    [Obsolete('Moved to codeunit WarehouseAvailabilityMgt.', '16.0')]
    procedure CalcResidualPickedQty(var WhseEntry: Record "Warehouse Entry") Result: Decimal
    begin
        exit(WhseAvailMgt.CalcResidualPickedQty(WhseEntry));
    end;

    local procedure DistrubuteReservedQtyByBins(var TempBinContentBuffer: Record "Bin Content Buffer" temporary)
    var
        TempBinContentBufferByBins: Record "Bin Content Buffer" temporary;
        TempBinContentBufferByBlockedBins: Record "Bin Content Buffer" temporary;
        WarehouseEntry: Record "Warehouse Entry";
        QtyLeftToDistribute: Decimal;
        QtyInBin: Decimal;
    begin
        with TempBinContentBuffer do begin
            if FindSet then
                repeat
                    QtyLeftToDistribute := "Qty. to Handle (Base)";
                    WarehouseEntry.SetCurrentKey(
                      "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.",
                      "Entry Type", Dedicated);
                    WarehouseEntry.SetRange("Location Code", "Location Code");
                    WarehouseEntry.SetRange("Item No.", "Item No.");
                    WarehouseEntry.SetRange("Variant Code", "Variant Code");
                    WarehouseEntry.SetTrackingFilterFromBinContentBuffer(TempBinContentBuffer);
                    GetLocation("Location Code");
                    if Location."Adjustment Bin Code" <> '' then begin
                        WarehouseEntry.FilterGroup(2);
                        WarehouseEntry.SetFilter("Bin Code", '<>%1', Location."Adjustment Bin Code");
                        WarehouseEntry.FilterGroup(0);
                    end;
                    WarehouseEntry.SetFilter("Bin Type Code", '<>%1', GetBinTypeFilter(0));

                    if WarehouseEntry.FindSet then
                        repeat
                            WarehouseEntry.SetRange("Bin Code", WarehouseEntry."Bin Code");
                            WarehouseEntry.SetRange("Unit of Measure Code", WarehouseEntry."Unit of Measure Code");
                            WarehouseEntry.CalcSums("Qty. (Base)");
                            if WarehouseEntry."Qty. (Base)" > 0 then
                                if not BinContentBlocked(
                                     "Location Code", WarehouseEntry."Bin Code", "Item No.", "Variant Code", WarehouseEntry."Unit of Measure Code")
                                then begin
                                    QtyInBin := Minimum(QtyLeftToDistribute, WarehouseEntry."Qty. (Base)");
                                    QtyLeftToDistribute -= QtyInBin;
                                    InsertTempBinContentBuf(
                                      TempBinContentBufferByBins,
                                      "Location Code", WarehouseEntry."Bin Code", "Item No.", "Variant Code",
                                      WarehouseEntry."Unit of Measure Code", "Lot No.", "Serial No.", QtyInBin);
                                end else
                                    InsertTempBinContentBuf(
                                      TempBinContentBufferByBlockedBins,
                                      "Location Code", WarehouseEntry."Bin Code", "Item No.", "Variant Code",
                                      WarehouseEntry."Unit of Measure Code", "Lot No.", "Serial No.", WarehouseEntry."Qty. (Base)");
                            WarehouseEntry.FindLast;
                            WarehouseEntry.SetRange("Unit of Measure Code");
                            WarehouseEntry.SetRange("Bin Code");
                        until (WarehouseEntry.Next = 0) or (QtyLeftToDistribute = 0);

                    if (QtyLeftToDistribute > 0) and TempBinContentBufferByBlockedBins.FindSet then
                        repeat
                            QtyInBin := Minimum(QtyLeftToDistribute, TempBinContentBufferByBlockedBins."Qty. to Handle (Base)");
                            QtyLeftToDistribute -= QtyInBin;
                            InsertTempBinContentBuf(
                              TempBinContentBufferByBins,
                              "Location Code", TempBinContentBufferByBlockedBins."Bin Code", "Item No.", "Variant Code",
                              TempBinContentBufferByBlockedBins."Unit of Measure Code", "Lot No.", "Serial No.", QtyInBin);
                        until (TempBinContentBufferByBlockedBins.Next = 0) or (QtyLeftToDistribute = 0);
                until Next = 0;

            DeleteAll();
            if TempBinContentBufferByBins.FindSet then
                repeat
                    if not BlockedBinOrTracking(TempBinContentBufferByBins) then begin
                        TempBinContentBuffer := TempBinContentBufferByBins;
                        Insert;
                    end;
                until TempBinContentBufferByBins.Next = 0;
        end;
    end;

    local procedure InsertTempBinContentBuf(var TempBinContentBuffer: Record "Bin Content Buffer" temporary; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; QtyBase: Decimal)
    begin
        with TempBinContentBuffer do
            if Get(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode, LotNo, SerialNo) then begin
                "Qty. to Handle (Base)" += QtyBase;
                Modify;
            end else begin
                Init;
                "Location Code" := LocationCode;
                "Bin Code" := BinCode;
                "Item No." := ItemNo;
                "Variant Code" := VariantCode;
                "Unit of Measure Code" := UnitOfMeasureCode;
                "Lot No." := LotNo;
                "Serial No." := SerialNo;
                "Qty. to Handle (Base)" := QtyBase;
                Insert;
            end;
    end;

    local procedure BlockedBinOrTracking(BinContentBuffer: Record "Bin Content Buffer"): Boolean
    var
        LotNoInformation: Record "Lot No. Information";
        SerialNoInformation: Record "Serial No. Information";
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
        end;

        exit(false);
    end;

    local procedure GetMessageForUnhandledQtyDueToBin(BinIsForPick: Boolean; BinIsForReplenishment: Boolean; IsMoveWksh: Boolean; AvailableQtyBase: Decimal; BinCode: Code[20]): Text[100]
    begin
        if AvailableQtyBase <= 0 then
            exit('');
        if not BinIsForPick and not IsMoveWksh then
            exit(StrSubstNo(BinIsNotForPickTxt, BinCode));
        if not BinIsForReplenishment and IsMoveWksh then
            exit(StrSubstNo(BinIsForReceiveOrShipTxt, BinCode));
    end;

    local procedure GetMessageForUnhandledQtyDueToReserv(): Text
    begin
        exit(QtyReservedNotFromInventoryTxt);
    end;

    procedure FilterWhsePickLinesWithUndefinedBin(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; IsLNRequired: Boolean; LotNo: Code[50]; IsSNRequired: Boolean; SerialNo: Code[50])
    var
        LotNoFilter: Text;
        SerialNoFilter: Text;
    begin
        if LotNo <> '' then
            if IsLNRequired then
                LotNoFilter := LotNo
            else
                LotNoFilter := StrSubstNo('%1|%2', LotNo, '');
        if SerialNo <> '' then
            if IsSNRequired then
                SerialNoFilter := SerialNo
            else
                SerialNoFilter := StrSubstNo('%1|%2', SerialNo, '');

        with WarehouseActivityLine do begin
            Reset;
            SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Action Type", "Variant Code", "Unit of Measure Code", "Breakbulk No.", "Activity Type");
            SetRange("Item No.", ItemNo);
            SetRange("Bin Code", '');
            SetRange("Location Code", LocationCode);
            SetRange("Action Type", "Action Type"::Take);
            SetRange("Variant Code", VariantCode);
            SetFilter("Lot No.", LotNoFilter);
            SetFilter("Serial No.", SerialNoFilter);
            SetRange("Breakbulk No.", 0);
            SetRange("Activity Type", "Activity Type"::Pick);
        end;
    end;

    local procedure EnqueueCannotBeHandledReason(CannotBeHandledReason: Text)
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
    local procedure OnAfterWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempLine(LocationCode: Code[10]; ToBinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempLineCheckReservation(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal; var TotalQtytoPick: Decimal; var TotalQtytoPickBase: Decimal; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; LastWhseItemTrkgLineNo: Integer; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempWhseItemTrackingLines(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseDocument(var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20])
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
    local procedure OnAfterSetValues(var AssignedID: Code[50]; var SortPick: Option " ",Item,Document,"Shelf/Bin No.","Due Date","Ship-To","Bin Ranking","Action Type"; var MaxNoOfSourceDoc: Integer; var MaxNoOfLines: Integer; var PerBin: Boolean; var PerZone: Boolean; var DoNotFillQtytoHandle: Boolean; var BreakbulkFilter: Boolean; var WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly)
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
    local procedure OnAfterSetWhseShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
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

    [Obsolete('Event moved to table BinContent together with procedure BinContentExists.', '16.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterBinContentExistsFilter(var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeCalcPickBin(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var TotalQtytoPick: Decimal; var TotalQtytoPickBase: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; CrossDock: Boolean; WhseTrackingExists: Boolean; WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcBWPickBin(var TotalQtyToPick: Decimal; var TotalQtytoPickBase: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; WhseItemTrkgExists: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcTotalAvailQtyToPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; NeededQtyBase: Decimal; RespectLocationBins: Boolean; CalledFromMoveWksh: Boolean; CalledFromWksh: Boolean; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var IsHandled: Boolean; var TotalAvailQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseDocument(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeCreateNewWhseDoc(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; OldNo: Code[20]; OldSourceNo: Code[20]; OldLocationCode: Code[10]; var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; var NoOfSourceDoc: Integer; var NoOfLines: Integer; var WhseDocCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempItemTrkgLines(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; var TotalQtytoPickBase: Decimal; HasExpiryDate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBWPickBin(var BinContent: Record "Bin Content"; var IsSetCurrentKeyHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetBinCodeFilter(var BinCodeFilterText: Text[250]; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToBinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePickStrictExpirationPosting(ItemNo: Code[20]; SNRequired: Boolean; LNRequired: Boolean; var StrictExpirationPosting: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeInsertTempItemTrkgLine(var EntrySummary: Record "Entry Summary"; RemQtyToPickBase: Decimal; var TotalAvailQtyToPickBase: Decimal)
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
    local procedure OnBeforeWhseActivHeaderInsert(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var TempWhseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailQtyOnFindBWPickBin(ItemNo: Code[20]; VariantCode: Code[10]; SNRequired: Boolean; LNRequired: Boolean; WhseItemTrkgExists: Boolean; SerialNo: Code[50]; LotNo: Code[50]; LocationCode: Code[10]; BinCode: Code[20]; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; TotalQtyToPickBase: Decimal; var QtyAvailableBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailQtyOnFindPickBin(ItemNo: Code[20]; VariantCode: Code[10]; SNRequired: Boolean; LNRequired: Boolean; WhseItemTrkgExists: Boolean; SerialNo: Code[50]; LotNo: Code[50]; LocationCode: Code[10]; BinCode: Code[20]; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; TotalQtyToPickBase: Decimal; var QtyAvailableBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailQtyOnFindBreakBulkBin(Broken: Boolean; ItemNo: Code[20]; VariantCode: Code[10]; SNRequired: Boolean; LNRequired: Boolean; WhseItemTrkgExists: Boolean; SerialNo: Code[50]; LotNo: Code[50]; LocationCode: Code[10]; BinCode: Code[20]; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; TotalQtyToPickBase: Decimal; var QtyAvailableBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailQtyOnFindSmallerUOMBin(Broken: Boolean; ItemNo: Code[20]; VariantCode: Code[10]; SNRequired: Boolean; LNRequired: Boolean; WhseItemTrkgExists: Boolean; SerialNo: Code[50]; LotNo: Code[50]; LocationCode: Code[10]; BinCode: Code[20]; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; TotalQtyToPickBase: Decimal; var QtyAvailableBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAssignedToPickOnAfterSetFilters(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempActivityLineOnAfterTransferFrom(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLine2OnBeforeDirectedPutAwayAndPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var TotalQtytoPick: Decimal; var TotalQtytoPickBase: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnAfterCreateTempLineWithItemTracking(var TotalQtytoPickBase: Decimal; var HasExpiredItems: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnBeforeCheckReservation(SourceType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var QtyBaseMaxAvailToPick: Decimal; var isHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocumentOnAfterSaveOldValues(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
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
    local procedure OnCreateWhseDocumentOnBeforeClearFilters(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
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
    local procedure OnCreateWhseDocTakeLineOnAfterSetFilters(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocPlaceLineOnAfterSetFilters(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line"; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindBWPickBinOnBeforeEndLoop(var FromBinContent: Record "Bin Content"; var TotalQtyToPickBase: Decimal; var EndLoop: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindBWPickBinOnBeforeFindFromBinContent(var FromBinContent: Record "Bin Content"; SourceType: Integer; var TotalQtyToPickBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocTakeLineOnBeforeWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;
}

