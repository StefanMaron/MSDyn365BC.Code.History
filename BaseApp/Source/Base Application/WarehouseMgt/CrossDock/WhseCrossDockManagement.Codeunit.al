codeunit 5780 "Whse. Cross-Dock Management"
{

    trigger OnRun()
    begin
    end;

    var
        PurchaseLine: Record "Purchase Line";
        WhseMgt: Codeunit "Whse. Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        SourceType2: Integer;
        UseCrossDocking: Boolean;
        TemplateName: Code[10];
        NameNo: Code[20];
        LocationCode: Code[10];

    procedure GetUseCrossDock(var UseCrossDock: Boolean; LocationCode: Code[10]; ItemNo: Code[20])
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUseCrossDock(ItemNo, UseCrossDock, IsHandled);
        if IsHandled then
            exit;

        Location.Get(LocationCode);
        Item.Get(ItemNo);
        if SKU.Get(LocationCode, ItemNo) then
            Item."Use Cross-Docking" := SKU."Use Cross-Docking";

        if Item."Use Cross-Docking" and Location."Use Cross-Docking" then
            UseCrossDock := true
        else
            UseCrossDock := false;
    end;

    procedure CalculateCrossDockLines(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; NewTemplateName: Code[10]; NewNameNo: Code[20]; NewLocationCode: Code[10])
    var
        TempWhseRcptLineNoSpecOrder: Record "Warehouse Receipt Line" temporary;
        TempWhseRcptLineWthSpecOrder: Record "Warehouse Receipt Line" temporary;
        TempItemVariant: Record "Item Variant" temporary;
    begin
        SetTemplate(NewTemplateName, NewNameNo, NewLocationCode);
        if TemplateName <> '' then
            exit;

        SeparateWhseRcptLinesWthSpecOrder(TempWhseRcptLineNoSpecOrder, TempWhseRcptLineWthSpecOrder, TempItemVariant);
        FilterCrossDockOpp(WhseCrossDockOpp);
        CalcCrossDockWithoutSpecOrder(WhseCrossDockOpp, TempWhseRcptLineNoSpecOrder, TempItemVariant);
        CalcCrossDockForSpecialOrder(WhseCrossDockOpp, TempWhseRcptLineWthSpecOrder);

        OnAfterCalculateCrossDockLines(WhseCrossDockOpp, NewTemplateName, NewNameNo, NewLocationCode);
    end;

    local procedure CalcCrossDockForSpecialOrder(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var TempWhseRcptLine: Record "Warehouse Receipt Line" temporary)
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        QtyToCrossDockBase: Decimal;
        QtyOnCrossDockBase: Decimal;
        RemainingNeededQtyBase: Decimal;
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
    begin
        with TempWhseRcptLine do
            if Find('-') then
                repeat
                    WhseRcptLine.Get("No.", "Line No.");
                    WhseCrossDockOpp.SetRange("Source Line No.", "Line No.");
                    WhseCrossDockOpp.DeleteAll();
                    GetSourceLine("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    CalculateCrossDock(
                      WhseCrossDockOpp, "Item No.", "Variant Code", LocationCode,
                      RemainingNeededQtyBase, QtyOnPickBase, QtyPickedBase, "Line No.");

                    UpdateQtyToCrossDock(
                      WhseRcptLine, RemainingNeededQtyBase, QtyToCrossDockBase, QtyOnCrossDockBase);
                until Next() = 0;
    end;

    local procedure CalcCrossDockWithoutSpecOrder(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var TempWhseRcptLine: Record "Warehouse Receipt Line" temporary; var TempItemVariant: Record "Item Variant" temporary)
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        QtyToCrossDockBase: Decimal;
        QtyOnCrossDockBase: Decimal;
        RemainingNeededQtyBase: Decimal;
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
        NewItemVariant: Boolean;
    begin
        if TempItemVariant.FindSet() then begin
            FilterWhseRcptLine(TempWhseRcptLine);
            repeat
                NewItemVariant := true;
                with TempWhseRcptLine do begin
                    SetRange("Item No.", TempItemVariant."Item No.");
                    SetRange("Variant Code", TempItemVariant.Code);
                    if Find('-') then
                        repeat
                            WhseRcptLine.Get("No.", "Line No.");
                            WhseCrossDockOpp.SetRange("Source Line No.", "Line No.");
                            WhseCrossDockOpp.DeleteAll();
                            if NewItemVariant then begin
                                GetSourceLine("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                                CalculateCrossDock(
                                  WhseCrossDockOpp, "Item No.", "Variant Code", LocationCode,
                                  RemainingNeededQtyBase, QtyOnPickBase, QtyPickedBase, "Line No.");
                            end;
                            if NewItemVariant or (RemainingNeededQtyBase <> 0) then
                                UpdateQtyToCrossDock(
                                  WhseRcptLine, RemainingNeededQtyBase, QtyToCrossDockBase, QtyOnCrossDockBase);

                            NewItemVariant := false;
                        until (Next() = 0) or (RemainingNeededQtyBase = 0);
                end;
            until TempItemVariant.Next() = 0;
        end;
    end;

    procedure CalcRemainingNeededQtyBase(ItemNo: Code[20]; VariantCode: Code[10]; QtyNeededBase: Decimal; var QtyToCrossDockBase: Decimal; var QtyOnCrossDockBase: Decimal; QtyToHandleBase: Decimal) RemainingNeededQtyBase: Decimal
    var
        Dummy: Decimal;
    begin
        CalcCrossDockedItems(ItemNo, VariantCode, '', LocationCode, Dummy, QtyOnCrossDockBase);
        QtyOnCrossDockBase += CalcCrossDockReceivedNotCrossDocked(LocationCode, ItemNo, VariantCode);
        OnCalcRemainingNeededQtyBaseOnAfterCalcQtyOnCrossDockBase(ItemNo, VariantCode, QtyNeededBase, HasSpecialOrder(), QtyOnCrossDockBase, LocationCode);

        QtyToCrossDockBase := QtyNeededBase - QtyOnCrossDockBase;
        if QtyToHandleBase < QtyToCrossDockBase then begin
            RemainingNeededQtyBase := QtyToCrossDockBase - QtyToHandleBase;
            QtyToCrossDockBase := QtyToHandleBase
        end else
            RemainingNeededQtyBase := 0;
        if QtyToCrossDockBase < 0 then
            QtyToCrossDockBase := 0;
    end;

    procedure CalculateCrossDockLine(var CrossDockOpp: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; var QtyNeededBase: Decimal; var QtyToCrossDockBase: Decimal; var QtyOnCrossDockBase: Decimal; LineNo: Integer; QtyToHandleBase: Decimal)
    var
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
        Dummy: Decimal;
    begin
        FilterCrossDockOpp(CrossDockOpp);
        CrossDockOpp.SetRange("Source Line No.", LineNo);
        CrossDockOpp.DeleteAll();

        CalculateCrossDock(
          CrossDockOpp, ItemNo, VariantCode, LocationCode, QtyNeededBase, QtyOnPickBase, QtyPickedBase, LineNo);

        CalcCrossDockedItems(ItemNo, VariantCode, '', LocationCode, Dummy, QtyOnCrossDockBase);
        QtyOnCrossDockBase += CalcCrossDockReceivedNotCrossDocked(LocationCode, ItemNo, VariantCode);
        OnCalculateCrossDockLineOnAfterCalcQtyOnCrossDockBase(ItemNo, VariantCode, QtyNeededBase, HasSpecialOrder(), QtyOnCrossDockBase, LocationCode);

        QtyToCrossDockBase := QtyNeededBase - QtyOnCrossDockBase;
        if QtyToHandleBase < QtyToCrossDockBase then
            QtyToCrossDockBase := QtyToHandleBase;
        if QtyToCrossDockBase < 0 then
            QtyToCrossDockBase := 0;
    end;

    local procedure CalculateCrossDock(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var QtyNeededSumBase: Decimal; var QtyOnPickSumBase: Decimal; var QtyPickedSumBase: Decimal; LineNo: Integer)
    var
        Location: Record Location;
        QtyOnPick: Decimal;
        QtyPicked: Decimal;
        CrossDockDate: Date;
    begin
        Location.Get(LocationCode);
        if Format(Location."Cross-Dock Due Date Calc.") <> '' then
            CrossDockDate := CalcDate(Location."Cross-Dock Due Date Calc.", WorkDate())
        else
            CrossDockDate := WorkDate();

        OnCalculateCrossDockOnAfterAssignCrossDocDate(WhseCrossDockOpp, CrossDockDate, ItemNo, VariantCode, LocationCode,
            QtyNeededSumBase, QtyOnPickSumBase, QtyPickedSumBase, LineNo, TemplateName, NameNo);

        CalcCrossDockToSalesOrder(WhseCrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        CalcCrossDockToTransferOrder(WhseCrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        CalcCrossDockToProdOrderComponent(WhseCrossDockOpp, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        CalcCrossDockToServiceOrder(WhseCrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);

        WhseCrossDockOpp.CalcSums("Qty. Needed (Base)", "Pick Qty. (Base)", "Picked Qty. (Base)");
        QtyNeededSumBase := WhseCrossDockOpp."Qty. Needed (Base)";
        QtyOnPickSumBase := WhseCrossDockOpp."Pick Qty. (Base)";
        QtyPickedSumBase := WhseCrossDockOpp."Picked Qty. (Base)";
    end;

    procedure InsertCrossDockOpp(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; QtyOutstanding: Decimal; QtyOutstandingBase: Decimal; QtyOnPick: Decimal; QtyOnPickBase: Decimal; QtyPicked: Decimal; QtyPickedBase: Decimal; UOMCode: Code[10]; QtyPerUOM: Decimal; DueDate: Date; ItemNo: Code[20]; VariantCode: Code[10]; LineNo: Integer)
    var
        IsHandled: Boolean;
    begin
        if HasSpecialOrder() and (SourceType <> DATABASE::"Sales Line") then
            exit;
        if (QtyOutstandingBase - QtyOnPickBase - QtyPickedBase) <= 0 then
            exit;

        WhseCrossDockOpp.Init();
        WhseCrossDockOpp."Source Template Name" := TemplateName;
        WhseCrossDockOpp."Source Name/No." := NameNo;
        WhseCrossDockOpp."Source Line No." := LineNo;
        WhseCrossDockOpp."Line No." := WhseCrossDockOpp."Line No." + 10000;
        WhseCrossDockOpp."To Source Type" := SourceType;
        WhseCrossDockOpp."To Source Subtype" := SourceSubType;
        WhseCrossDockOpp."To Source No." := SourceNo;
        WhseCrossDockOpp."To Source Line No." := SourceLineNo;
        WhseCrossDockOpp."To Source Subline No." := SourceSubLineNo;
        WhseCrossDockOpp."To Source Document" :=
            WhseMgt.GetSourceDocumentType(WhseCrossDockOpp."To Source Type", WhseCrossDockOpp."To Source Subtype").AsInteger();
        WhseCrossDockOpp."Due Date" := DueDate;
        WhseCrossDockOpp."To-Src. Unit of Measure Code" := UOMCode;
        WhseCrossDockOpp."To-Src. Qty. per Unit of Meas." := QtyPerUOM;
        WhseCrossDockOpp."Item No." := ItemNo;
        WhseCrossDockOpp."Variant Code" := VariantCode;
        WhseCrossDockOpp."Location Code" := LocationCode;

        SubtractExistingCrossDockOppQtysToSource(WhseCrossDockOpp);

        OnInsertCrossDockLineOnBeforeCalculateQtyNeeded(QtyOutstanding, QtyOutstandingBase);

        WhseCrossDockOpp."Qty. Needed (Base)" := Maximum(WhseCrossDockOpp."Qty. Needed (Base)" + QtyOutstandingBase - QtyOnPickBase - QtyPickedBase, 0);
        WhseCrossDockOpp."Qty. Needed" := Maximum(WhseCrossDockOpp."Qty. Needed" + QtyOutstanding - QtyOnPick - QtyPicked, 0);

        WhseCrossDockOpp."Pick Qty. (Base)" := Maximum(WhseCrossDockOpp."Pick Qty. (Base)" + QtyOnPickBase, 0);
        WhseCrossDockOpp."Pick Qty." := Maximum(WhseCrossDockOpp."Pick Qty." + QtyOnPick, 0);

        WhseCrossDockOpp."Picked Qty. (Base)" := Maximum(WhseCrossDockOpp."Picked Qty. (Base)" + QtyPickedBase, 0);
        WhseCrossDockOpp."Picked Qty." := Maximum(WhseCrossDockOpp."Picked Qty." + QtyPicked, 0);

        IsHandled := false;
        OnBeforeCrossDockOppInsert(WhseCrossDockOpp, QtyPerUOM, NameNo, LineNo, IsHandled);
        if not IsHandled then
            WhseCrossDockOpp.Insert();
    end;

    procedure ShowCrossDock(var CrossDockOpp: Record "Whse. Cross-Dock Opportunity"; SourceTemplateName: Code[10]; SourceNameNo: Code[20]; SourceLineNo: Integer; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10])
    var
        ReceiptLine: Record "Warehouse Receipt Line";
        CrossDockForm: Page "Cross-Dock Opportunities";
        QtyToCrossDock: Decimal;
    begin
        with CrossDockOpp do begin
            FilterGroup(2);
            SetRange("Source Template Name", SourceTemplateName);
            SetRange("Source Name/No.", SourceNameNo);
            SetRange("Item No.", ItemNo);
            SetRange("Location Code", LocationCode);
            FilterGroup(0);
        end;
        ReceiptLine.Get(SourceNameNo, SourceLineNo);
        CrossDockForm.SetValues(ItemNo, VariantCode, LocationCode, SourceTemplateName, SourceNameNo, SourceLineNo,
          ReceiptLine."Unit of Measure Code", ReceiptLine."Qty. per Unit of Measure");
        CrossDockForm.LookupMode(true);
        CrossDockForm.SetTableView(CrossDockOpp);
        if CrossDockForm.RunModal() = ACTION::LookupOK then begin
            ReceiptLine.Get(SourceNameNo, SourceLineNo);
            CrossDockForm.GetValues(QtyToCrossDock);
            QtyToCrossDock := QtyToCrossDock / ReceiptLine."Qty. per Unit of Measure";
            if ReceiptLine."Qty. to Receive" < QtyToCrossDock then
                QtyToCrossDock := ReceiptLine."Qty. to Receive";
            ReceiptLine.Validate("Qty. to Cross-Dock", QtyToCrossDock);
            ReceiptLine.Modify();
            OnShowCrossDockOnAfterReceiptLineModify(ReceiptLine);
        end;
    end;

    procedure CalcCrossDockedItems(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; LocationCode: Code[10]; var QtyCrossDockedUOMBase: Decimal; var QtyCrossDockedAllUOMBase: Decimal)
    var
        BinContent: Record "Bin Content";
        QtyAvailToPickBase: Decimal;
    begin
        QtyCrossDockedUOMBase := 0;
        QtyCrossDockedAllUOMBase := 0;
        with BinContent do begin
            Reset();
            SetRange("Location Code", LocationCode);
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetRange("Cross-Dock Bin", true);
            if Find('-') then
                repeat
                    QtyAvailToPickBase := CalcQtyAvailToPick(0);
                    if "Unit of Measure Code" = UOMCode then
                        QtyCrossDockedUOMBase := QtyCrossDockedUOMBase + QtyAvailToPickBase;
                    QtyCrossDockedAllUOMBase := QtyCrossDockedAllUOMBase + QtyAvailToPickBase;
                until Next() = 0;
        end;
    end;

    procedure CalcCrossDockReceivedNotCrossDocked(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]) ReceivedNotCrossDockedQty: Decimal
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ReceivedCrossDockedQty: Decimal;
    begin
        ReceivedNotCrossDockedQty := 0;

        with PostedWhseReceiptLine do begin
            SetRange("Location Code", LocationCode);
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetFilter(Status, '%1|%2', Status::" ", Status::"Partially Put Away");
            SetFilter("Cross-Dock Bin Code", '<>%1', '');
            if FindSet() then
                repeat
                    // calculate received, yet not put-away quantity, that is assumed to be put-away in a cross-dock bin
                    ReceivedCrossDockedQty := CalcCrossDockedQtyInPostedReceipt(PostedWhseReceiptLine);
                    ReceivedNotCrossDockedQty +=
                      Minimum(
                        Maximum("Qty. Cross-Docked (Base)" - ReceivedCrossDockedQty, 0),
                        "Qty. (Base)" - "Qty. Put Away (Base)");
                until Next() = 0;
        end;
    end;

    procedure ShowBinContentsCrossDocked(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; LocationCode: Code[10]; FilterOnUOM: Boolean)
    var
        BinContent: Record "Bin Content";
        BinContentLookup: Page "Bin Contents List";
    begin
        with BinContent do begin
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetRange("Cross-Dock Bin", true);
            if FilterOnUOM then
                SetRange("Unit of Measure Code", UOMCode);
        end;
        with BinContentLookup do begin
            SetTableView(BinContent);
            Initialize(LocationCode);
            RunModal();
        end;
        Clear(BinContentLookup);
    end;

    local procedure GetSourceLine(SourceType: Option; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    begin
        if SourceType = DATABASE::"Purchase Line" then begin
            PurchaseLine.Get(SourceSubtype, SourceNo, SourceLineNo);
            SourceType2 := SourceType;
        end;

        OnAfterGetSourceLine(SourceType, SourceSubtype, SourceNo, SourceLineNo);
    end;

    procedure CalculatePickQty(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var QtyOnPick: Decimal; var QtyOnPickBase: Decimal; var QtyPicked: Decimal; var QtyPickedBase: Decimal; Qty: Decimal; QtyBase: Decimal; OutstandingQty: Decimal; OutstandingQtyBase: Decimal)
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculatePickQty(SourceType, SourceSubtype, SourceNo, SourceLineNo, Qty, QtyBase, OutstandingQty,
            OutstandingQtyBase, QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase, IsHandled);
        if not IsHandled then begin
            QtyOnPickBase := 0;
            QtyPickedBase := 0;
            with WhseShptLine do begin
                Reset();
                SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                SetRange("Source Type", SourceType);
                SetRange("Source Subtype", SourceSubtype);
                SetRange("Source No.", SourceNo);
                SetRange("Source Line No.", SourceLineNo);
                if Find('-') then
                    repeat
                        CalcFields("Pick Qty. (Base)", "Pick Qty.");
                        QtyOnPick := QtyOnPick + "Pick Qty.";
                        QtyOnPickBase := QtyOnPickBase + "Pick Qty. (Base)";
                        QtyPicked := QtyPicked + "Qty. Picked";
                        QtyPickedBase := QtyPickedBase + "Qty. Picked (Base)";
                    until Next() = 0;
                if QtyPickedBase = 0 then begin
                    QtyPicked := Qty - OutstandingQty;
                    QtyPickedBase := QtyBase - OutstandingQtyBase;
                end;
            end;
        end;

        OnAfterCalculatePickQty(
            SourceType, SourceSubtype, SourceNo, SourceLineNo, Qty, QtyBase, OutstandingQty,
            OutstandingQtyBase, QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase);
    end;

    procedure SetTemplate(NewTemplateName: Code[10]; NewNameNo: Code[20]; NewLocationCode: Code[10])
    begin
        TemplateName := NewTemplateName;
        NameNo := NewNameNo;
        LocationCode := NewLocationCode;
    end;

    local procedure SeparateWhseRcptLinesWthSpecOrder(var TempWhseRcptLineNoSpecOrder: Record "Warehouse Receipt Line" temporary; var TempWhseRcptLineWthSpecOrder: Record "Warehouse Receipt Line" temporary; var TempItemVariant: Record "Item Variant" temporary)
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        FilterWhseRcptLine(WhseRcptLine);
        with WhseRcptLine do
            if FindSet() then
                repeat
                    GetSourceLine("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    if HasSpecialOrder() then begin
                        TempWhseRcptLineWthSpecOrder := WhseRcptLine;
                        TempWhseRcptLineWthSpecOrder.Insert();
                    end else begin
                        TempWhseRcptLineNoSpecOrder := WhseRcptLine;
                        TempWhseRcptLineNoSpecOrder.Insert();
                        InsertToItemList(WhseRcptLine, TempItemVariant);
                    end;
                until Next() = 0;
    end;

    local procedure InsertToItemList(WhseRcptLine: Record "Warehouse Receipt Line"; var TempItemVariant: Record "Item Variant" temporary)
    begin
        with TempItemVariant do begin
            Init();
            "Item No." := WhseRcptLine."Item No.";
            Code := WhseRcptLine."Variant Code";
            if Insert() then;
        end;
    end;

    local procedure FilterWhseRcptLine(var WhseRcptLine: Record "Warehouse Receipt Line")
    begin
        with WhseRcptLine do begin
            SetRange("No.", NameNo);
            SetRange("Location Code", LocationCode);
            SetFilter("Qty. to Receive", '>0');
        end;
    end;

    procedure FilterCrossDockOpp(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity")
    begin
        WhseCrossDockOpp.SetRange("Source Template Name", TemplateName);
        WhseCrossDockOpp.SetRange("Source Name/No.", NameNo);
        WhseCrossDockOpp.SetRange("Location Code", LocationCode);

        OnAfterFilterCrossDockOpp(WhseCrossDockOpp);
    end;

    local procedure UpdateQtyToCrossDock(var WhseRcptLine: Record "Warehouse Receipt Line"; var RemainingNeededQtyBase: Decimal; var QtyToCrossDockBase: Decimal; var QtyOnCrossDockBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        GetUseCrossDock(UseCrossDocking, WhseRcptLine."Location Code", WhseRcptLine."Item No.");
        if not UseCrossDocking then
            exit;

        RemainingNeededQtyBase :=
            CalcRemainingNeededQtyBase(
                WhseRcptLine."Item No.", WhseRcptLine."Variant Code", RemainingNeededQtyBase,
                QtyToCrossDockBase, QtyOnCrossDockBase, WhseRcptLine."Qty. to Receive (Base)");

        IsHandled := false;
        OnUpdateQtyToCrossDockOnBeforeValidateQtyToCrossDock(WhseRcptLine, IsHandled);
        if not IsHandled then begin
            WhseRcptLine.Validate("Qty. to Cross-Dock", Round(QtyToCrossDockBase / WhseRcptLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
            WhseRcptLine."Qty. to Cross-Dock (Base)" := QtyToCrossDockBase;
            WhseRcptLine.Modify();
        end;

        OnAfterUpdateQtyToCrossDock(WhseRcptLine);
    end;

    local procedure HasSpecialOrder(): Boolean
    begin
        exit((SourceType2 = DATABASE::"Purchase Line") and PurchaseLine."Special Order");
    end;

    local procedure SubtractExistingCrossDockOppQtysToSource(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity")
    var
        ExistingWhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity";
    begin
        with ExistingWhseCrossDockOpp do begin
            SetRange("To Source Type", WhseCrossDockOpp."To Source Type");
            SetRange("To Source Subtype", WhseCrossDockOpp."To Source Subtype");
            SetRange("To Source No.", WhseCrossDockOpp."To Source No.");
            SetRange("To Source Line No.", WhseCrossDockOpp."To Source Line No.");
            SetRange("To Source Subline No.", WhseCrossDockOpp."To Source Subline No.");
            SetRange("Item No.", WhseCrossDockOpp."Item No.");
            SetRange("Variant Code", WhseCrossDockOpp."Variant Code");
            CalcSums("Qty. to Cross-Dock (Base)", "Pick Qty. (Base)", "Picked Qty. (Base)");

            WhseCrossDockOpp."Qty. Needed" :=
              -Round("Qty. to Cross-Dock (Base)" / WhseCrossDockOpp."To-Src. Qty. per Unit of Meas.", UOMMgt.QtyRndPrecision());
            WhseCrossDockOpp."Qty. Needed (Base)" := -"Qty. to Cross-Dock (Base)";
            WhseCrossDockOpp."Pick Qty." :=
              -Round("Pick Qty. (Base)" / WhseCrossDockOpp."To-Src. Qty. per Unit of Meas.", UOMMgt.QtyRndPrecision());
            WhseCrossDockOpp."Pick Qty. (Base)" := -"Pick Qty. (Base)";
            WhseCrossDockOpp."Picked Qty." :=
              -Round("Picked Qty. (Base)" / WhseCrossDockOpp."To-Src. Qty. per Unit of Meas.", UOMMgt.QtyRndPrecision());
            WhseCrossDockOpp."Picked Qty. (Base)" := -"Picked Qty. (Base)";
        end;
    end;

    local procedure CalcCrossDockedQtyInPostedReceipt(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"): Decimal
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        with WarehouseEntry do begin
            SetRange("Whse. Document Type", "Whse. Document Type"::Receipt);
            SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
            SetRange("Whse. Document Line No.", PostedWhseReceiptLine."Line No.");
            SetFilter("Bin Code", PostedWhseReceiptLine."Cross-Dock Bin Code");
            CalcSums("Qty. (Base)");
            exit("Qty. (Base)");
        end;
    end;

    local procedure CalcCrossDockToSalesOrder(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        WhseRequest: Record "Warehouse Request";
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
    begin
        SalesLine.SetRange("Document Type", "Sales Document Type"::Order);
        SalesLine.SetRange(Type, "Sales Line Type"::Item);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.SetRange("Variant Code", VariantCode);
        SalesLine.SetRange("Drop Shipment", false);
        SalesLine.SetRange("Location Code", LocationCode);
        SalesLine.SetRange("Shipment Date", 0D, CrossDockDate);
        SalesLine.SetFilter("Outstanding Qty. (Base)", '>0');
        if HasSpecialOrder() then begin
            SalesLine.SetRange("Document No.", PurchaseLine."Special Order Sales No.");
            SalesLine.SetRange("Line No.", PurchaseLine."Special Order Sales Line No.");
        end else
            SalesLine.SetRange("Special Order", false);
        OnCalcCrossDockToSalesOrderOnAfterSalesLineSetFilters(SalesLine, WhseCrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        if SalesLine.Find('-') then
            repeat
                if WhseRequest.Get(WhseRequest.Type::Outbound, SalesLine."Location Code", DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.") and
                    (WhseRequest."Document Status" = WhseRequest."Document Status"::Released)
                then begin
                    CalculatePickQty(
                        DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
                        QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase, SalesLine.Quantity, SalesLine."Quantity (Base)",
                        SalesLine."Outstanding Quantity", SalesLine."Outstanding Qty. (Base)");
                    OnCalcCrossDockToSalesOrderOnBeforeInsertCrossDockLine(SalesLine);
                    InsertCrossDockOpp(
                        WhseCrossDockOpp,
                        DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0,
                        SalesLine.Quantity, SalesLine."Quantity (Base)", QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase,
                        SalesLine."Unit of Measure Code", SalesLine."Qty. per Unit of Measure", SalesLine."Shipment Date",
                        SalesLine."No.", SalesLine."Variant Code", LineNo);
                end;
                OnCalcCrossDockToSalesOrderOnAfterLoopIteration(WhseCrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo, WhseRequest, SalesLine);
            until SalesLine.Next() = 0;

        OnAfterCalcCrossDockToSalesOrder(WhseCrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
    end;

    local procedure CalcCrossDockToTransferOrder(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    var
        TransferLine: Record "Transfer Line";
        WhseRequest: Record "Warehouse Request";
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCrossDockToTransferOrder(WhseCrossDockOpp, ItemNo, VariantCode, LocationCode, LineNo, IsHandled);
        if IsHandled then
            exit;

        TransferLine.SetRange("Transfer-from Code", LocationCode);
        TransferLine.SetRange(Status, TransferLine.Status::Released);
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.SetRange("Variant Code", VariantCode);
        TransferLine.SetRange("Shipment Date", 0D, CrossDockDate);
        TransferLine.SetFilter("Outstanding Qty. (Base)", '>0');
        OnCalcCrossDockToTransferOrderOnAfterTransferLineSetFilters(TransferLine, WhseCrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        if TransferLine.Find('-') then
            repeat
                if WhseRequest.Get(
                    WhseRequest.Type::Outbound, TransferLine."Transfer-from Code", DATABASE::"Transfer Line", 0, TransferLine."Document No.") and
                    (WhseRequest."Document Status" = WhseRequest."Document Status"::Released)
                then begin
                    CalculatePickQty(
                        DATABASE::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.",
                        QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase, TransferLine.Quantity, TransferLine."Quantity (Base)",
                        TransferLine."Outstanding Quantity", TransferLine."Outstanding Qty. (Base)");
                    OnCalcCrossDockToTransferOrderOnBeforeInsertCrossDockLine(TransferLine, WhseCrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
                    InsertCrossDockOpp(
                        WhseCrossDockOpp,
                        DATABASE::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", 0,
                        TransferLine.Quantity, TransferLine."Quantity (Base)",
                        QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase,
                        TransferLine."Unit of Measure Code", TransferLine."Qty. per Unit of Measure", TransferLine."Shipment Date",
                        TransferLine."Item No.", TransferLine."Variant Code", LineNo);
                end;
            until TransferLine.Next() = 0;
    end;

    local procedure CalcCrossDockToProdOrderComponent(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetRange(Status, ProdOrderComp.Status::Released);
        ProdOrderComp.SetRange("Item No.", ItemNo);
        ProdOrderComp.SetRange("Variant Code", VariantCode);
        ProdOrderComp.SetRange("Location Code", LocationCode);
        ProdOrderComp.SetRange("Due Date", 0D, CrossDockDate);
        ProdOrderComp.SetRange("Planning Level Code", 0);
        ProdOrderComp.SetFilter("Remaining Qty. (Base)", '>0');
        if ProdOrderComp.Find('-') then
            repeat
                ProdOrderComp.CalcFields("Pick Qty. (Base)");
                OnCalcCrossDockToProdOrderComponentOnBeforeInsertCrossDockLine(ProdOrderComp);
                InsertCrossDockOpp(
                    WhseCrossDockOpp,
                    DATABASE::"Prod. Order Component", ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.",
                    ProdOrderComp."Line No.", ProdOrderComp."Prod. Order Line No.",
                    ProdOrderComp."Remaining Quantity", ProdOrderComp."Remaining Qty. (Base)",
                    ProdOrderComp."Pick Qty.", ProdOrderComp."Pick Qty. (Base)", ProdOrderComp."Qty. Picked", ProdOrderComp."Qty. Picked (Base)",
                    ProdOrderComp."Unit of Measure Code", ProdOrderComp."Qty. per Unit of Measure", ProdOrderComp."Due Date",
                    ProdOrderComp."Item No.", ProdOrderComp."Variant Code", LineNo);
            until ProdOrderComp.Next() = 0;
    end;

    local procedure CalcCrossDockToServiceOrder(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    var
        ServiceLine: Record "Service Line";
        WhseRequest: Record "Warehouse Request";
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
    begin
        ServiceLine.SetRange("Document Type", "Service Document Type"::Order);
        ServiceLine.SetRange(Type, "Service Line Type"::Item);
        ServiceLine.SetRange("No.", ItemNo);
        ServiceLine.SetRange("Variant Code", VariantCode);
        ServiceLine.SetRange("Location Code", LocationCode);
        ServiceLine.SetRange("Needed by Date", 0D, CrossDockDate);
        ServiceLine.SetFilter("Outstanding Qty. (Base)", '>0');
        OnCalcCrossDockToServiceOrderOnAfterServiceLineSetFilters(ServiceLine, WhseCrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        if ServiceLine.Find('-') then
            repeat
                if WhseRequest.Get(
                    WhseRequest.Type::Outbound, ServiceLine."Location Code", DATABASE::"Service Line", ServiceLine."Document Type", ServiceLine."Document No.") and
                   (WhseRequest."Document Status" = WhseRequest."Document Status"::Released)
                then begin
                    CalculatePickQty(
                      DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.",
                      QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase, ServiceLine.Quantity, ServiceLine."Quantity (Base)",
                      ServiceLine."Outstanding Quantity", ServiceLine."Outstanding Qty. (Base)");
                    OnCalcCrossDockToServiceOrderOnBeforeInsertCrossDockLine(ServiceLine, WhseCrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
                    InsertCrossDockOpp(
                      WhseCrossDockOpp,
                      DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.", 0,
                      ServiceLine.Quantity, ServiceLine."Quantity (Base)",
                      QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase,
                      ServiceLine."Unit of Measure Code", ServiceLine."Qty. per Unit of Measure", ServiceLine."Needed by Date",
                      ServiceLine."No.", ServiceLine."Variant Code", LineNo);
                    OnCalcCrossDockToServiceOrderOnAfterInsertCrossDockLine(ServiceLine, WhseCrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
                end;
            until ServiceLine.Next() = 0;
    end;

    local procedure Maximum(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 >= Value2 then
            exit(Value1);
        exit(Value2);
    end;

    local procedure Minimum(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 <= Value2 then
            exit(Value1);
        exit(Value2);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculatePickQty(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; Qty: Decimal; QtyBase: Decimal; OutstandingQty: Decimal; OutstandingQtyBase: Decimal; var QtyOnPick: Decimal; var QtyOnPickBase: Decimal; var QtyPicked: Decimal; var QtyPickedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculatePickQty(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; Qty: Decimal; QtyBase: Decimal; OutstandingQty: Decimal; OutstandingQtyBase: Decimal; var QtyOnPick: Decimal; var QtyOnPickBase: Decimal; var QtyPicked: Decimal; var QtyPickedBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateCrossDockLines(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; NewTemplateName: Code[10]; NewNameNo: Code[20]; NewLocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcCrossDockToSalesOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSourceLine(SourceType: Option; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterCrossDockOpp(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateQtyToCrossDock(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCrossDockToTransferOrder(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; LineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCrossDockOppInsert(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; QtyPerUOM: Decimal; NameNo: Code[20]; LineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowCrossDockOnAfterReceiptLineModify(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUseCrossDock(ItemNo: Code[20]; var UseCrossDock: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockToSalesOrderOnBeforeInsertCrossDockLine(SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcCrossDockToSalesOrderOnAfterLoopIteration(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer; WarehouseRequest: Record "Warehouse Request"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcCrossDockToSalesOrderOnAfterSalesLineSetFilters(var SalesLine: Record "Sales Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockToProdOrderComponentOnBeforeInsertCrossDockLine(ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockToServiceOrderOnAfterServiceLineSetFilters(var ServiceLine: Record "Service Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockToServiceOrderOnAfterInsertCrossDockLine(ServiceLine: Record "Service Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockToServiceOrderOnBeforeInsertCrossDockLine(ServiceLine: Record "Service Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockToTransferOrderOnAfterTransferLineSetFilters(var TransferLine: Record "Transfer Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockToTransferOrderOnBeforeInsertCrossDockLine(TransferLine: Record "Transfer Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateCrossDockOnAfterAssignCrossDocDate(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var CrossDockDate: Date; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var QtyNeededSumBase: Decimal; var QtyOnPickSumBase: Decimal; var QtyPickedSumBase: Decimal; LineNo: Integer; TemplateName: Code[10]; NameNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRemainingNeededQtyBaseOnAfterCalcQtyOnCrossDockBase(ItemNo: Code[20]; VariantCode: Code[10]; QtyNeededBase: Decimal; SpecialOrder: Boolean; var QtyOnCrossDockBase: Decimal; LocationCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateCrossDockLineOnAfterCalcQtyOnCrossDockBase(ItemNo: Code[20]; VariantCode: Code[10]; QtyNeededBase: Decimal; SpecialOrder: Boolean; var QtyOnCrossDockBase: Decimal; LocationCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCrossDockLineOnBeforeCalculateQtyNeeded(var QtyOutstanding: Decimal; var QtyOutstandingBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateQtyToCrossDockOnBeforeValidateQtyToCrossDock(WhseRcptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;
}

