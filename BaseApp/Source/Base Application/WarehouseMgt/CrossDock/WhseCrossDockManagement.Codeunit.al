namespace Microsoft.Warehouse.CrossDock;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;

codeunit 5780 "Whse. Cross-Dock Management"
{

    trigger OnRun()
    begin
    end;

    var
        PurchaseLine: Record "Purchase Line";
        WhseManagement: Codeunit "Whse. Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        SourceType2: Integer;
        UseCrossDocking: Boolean;
        TemplateName: Code[10];
        NameNo: Code[20];
        LocationCode: Code[10];

    procedure GetUseCrossDock(var UseCrossDock: Boolean; LocationCode: Code[10]; ItemNo: Code[20])
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUseCrossDock(ItemNo, UseCrossDock, IsHandled);
        if IsHandled then
            exit;

        Location.Get(LocationCode);
        Item.Get(ItemNo);
        if StockkeepingUnit.Get(LocationCode, ItemNo) then
            Item."Use Cross-Docking" := StockkeepingUnit."Use Cross-Docking";

        if Item."Use Cross-Docking" and Location."Use Cross-Docking" then
            UseCrossDock := true
        else
            UseCrossDock := false;
    end;

    procedure CalculateCrossDockLines(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; NewTemplateName: Code[10]; NewNameNo: Code[20]; NewLocationCode: Code[10])
    var
        TempWarehouseReceiptLineNoSpecOrder: Record "Warehouse Receipt Line" temporary;
        TempWarehouseReceiptLineWithSpecOrder: Record "Warehouse Receipt Line" temporary;
        TempItemVariant: Record "Item Variant" temporary;
    begin
        SetTemplate(NewTemplateName, NewNameNo, NewLocationCode);
        if TemplateName <> '' then
            exit;

        SeparateWhseRcptLinesWthSpecOrder(TempWarehouseReceiptLineNoSpecOrder, TempWarehouseReceiptLineWithSpecOrder, TempItemVariant);
        FilterCrossDockOpp(WhseCrossDockOpportunity);
        CalcCrossDockWithoutSpecOrder(WhseCrossDockOpportunity, TempWarehouseReceiptLineNoSpecOrder, TempItemVariant);
        CalcCrossDockForSpecialOrder(WhseCrossDockOpportunity, TempWarehouseReceiptLineWithSpecOrder);

        OnAfterCalculateCrossDockLines(WhseCrossDockOpportunity, NewTemplateName, NewNameNo, NewLocationCode);
    end;

    local procedure CalcCrossDockForSpecialOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var TempWarehouseReceiptLine: Record "Warehouse Receipt Line" temporary)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        QtyToCrossDockBase: Decimal;
        QtyOnCrossDockBase: Decimal;
        RemainingNeededQtyBase: Decimal;
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
    begin
        with TempWarehouseReceiptLine do
            if Find('-') then
                repeat
                    WarehouseReceiptLine.Get("No.", "Line No.");
                    WhseCrossDockOpportunity.SetRange("Source Line No.", "Line No.");
                    WhseCrossDockOpportunity.DeleteAll();
                    GetSourceLine("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    CalculateCrossDock(
                      WhseCrossDockOpportunity, "Item No.", "Variant Code", LocationCode,
                      RemainingNeededQtyBase, QtyOnPickBase, QtyPickedBase, "Line No.");

                    UpdateQtyToCrossDock(
                      WarehouseReceiptLine, RemainingNeededQtyBase, QtyToCrossDockBase, QtyOnCrossDockBase);
                until Next() = 0;
    end;

    local procedure CalcCrossDockWithoutSpecOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var TempWarehouseReceiptLine: Record "Warehouse Receipt Line" temporary; var TempItemVariant: Record "Item Variant" temporary)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        QtyToCrossDockBase: Decimal;
        QtyOnCrossDockBase: Decimal;
        RemainingNeededQtyBase: Decimal;
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
        NewItemVariant: Boolean;
    begin
        if TempItemVariant.FindSet() then begin
            FilterWhseRcptLine(TempWarehouseReceiptLine);
            repeat
                NewItemVariant := true;
                with TempWarehouseReceiptLine do begin
                    SetRange("Item No.", TempItemVariant."Item No.");
                    SetRange("Variant Code", TempItemVariant.Code);
                    if Find('-') then
                        repeat
                            WarehouseReceiptLine.Get("No.", "Line No.");
                            WhseCrossDockOpportunity.SetRange("Source Line No.", "Line No.");
                            WhseCrossDockOpportunity.DeleteAll();
                            if NewItemVariant then begin
                                GetSourceLine("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                                CalculateCrossDock(
                                  WhseCrossDockOpportunity, "Item No.", "Variant Code", LocationCode,
                                  RemainingNeededQtyBase, QtyOnPickBase, QtyPickedBase, "Line No.");
                            end;
                            if NewItemVariant or (RemainingNeededQtyBase <> 0) then
                                UpdateQtyToCrossDock(
                                  WarehouseReceiptLine, RemainingNeededQtyBase, QtyToCrossDockBase, QtyOnCrossDockBase);

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

    procedure CalculateCrossDockLine(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; var QtyNeededBase: Decimal; var QtyToCrossDockBase: Decimal; var QtyOnCrossDockBase: Decimal; LineNo: Integer; QtyToHandleBase: Decimal)
    var
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
        Dummy: Decimal;
    begin
        FilterCrossDockOpp(WhseCrossDockOpportunity);
        WhseCrossDockOpportunity.SetRange("Source Line No.", LineNo);
        WhseCrossDockOpportunity.DeleteAll();

        CalculateCrossDock(
          WhseCrossDockOpportunity, ItemNo, VariantCode, LocationCode, QtyNeededBase, QtyOnPickBase, QtyPickedBase, LineNo);

        CalcCrossDockedItems(ItemNo, VariantCode, '', LocationCode, Dummy, QtyOnCrossDockBase);
        QtyOnCrossDockBase += CalcCrossDockReceivedNotCrossDocked(LocationCode, ItemNo, VariantCode);
        OnCalculateCrossDockLineOnAfterCalcQtyOnCrossDockBase(ItemNo, VariantCode, QtyNeededBase, HasSpecialOrder(), QtyOnCrossDockBase, LocationCode);

        QtyToCrossDockBase := QtyNeededBase - QtyOnCrossDockBase;
        if QtyToHandleBase < QtyToCrossDockBase then
            QtyToCrossDockBase := QtyToHandleBase;
        if QtyToCrossDockBase < 0 then
            QtyToCrossDockBase := 0;
    end;

    local procedure CalculateCrossDock(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var QtyNeededSumBase: Decimal; var QtyOnPickSumBase: Decimal; var QtyPickedSumBase: Decimal; LineNo: Integer)
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

        OnCalculateCrossDockOnAfterAssignCrossDocDate(WhseCrossDockOpportunity, CrossDockDate, ItemNo, VariantCode, LocationCode,
            QtyNeededSumBase, QtyOnPickSumBase, QtyPickedSumBase, LineNo, TemplateName, NameNo);

        CalcCrossDockToSalesOrder(WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        CalcCrossDockToTransferOrder(WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        CalcCrossDockToProdOrderComponent(WhseCrossDockOpportunity, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        CalcCrossDockToServiceOrder(WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);

        WhseCrossDockOpportunity.CalcSums("Qty. Needed (Base)", "Pick Qty. (Base)", "Picked Qty. (Base)");
        QtyNeededSumBase := WhseCrossDockOpportunity."Qty. Needed (Base)";
        QtyOnPickSumBase := WhseCrossDockOpportunity."Pick Qty. (Base)";
        QtyPickedSumBase := WhseCrossDockOpportunity."Picked Qty. (Base)";
    end;

    procedure InsertCrossDockOpp(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; QtyOutstanding: Decimal; QtyOutstandingBase: Decimal; QtyOnPick: Decimal; QtyOnPickBase: Decimal; QtyPicked: Decimal; QtyPickedBase: Decimal; UOMCode: Code[10]; QtyPerUOM: Decimal; DueDate: Date; ItemNo: Code[20]; VariantCode: Code[10]; LineNo: Integer)
    var
        IsHandled: Boolean;
    begin
        if HasSpecialOrder() and (SourceType <> Database::"Sales Line") then
            exit;
        if (QtyOutstandingBase - QtyOnPickBase - QtyPickedBase) <= 0 then
            exit;

        WhseCrossDockOpportunity.Init();
        WhseCrossDockOpportunity."Source Template Name" := TemplateName;
        WhseCrossDockOpportunity."Source Name/No." := NameNo;
        WhseCrossDockOpportunity."Source Line No." := LineNo;
        WhseCrossDockOpportunity."Line No." := WhseCrossDockOpportunity."Line No." + 10000;
        WhseCrossDockOpportunity."To Source Type" := SourceType;
        WhseCrossDockOpportunity."To Source Subtype" := SourceSubType;
        WhseCrossDockOpportunity."To Source No." := SourceNo;
        WhseCrossDockOpportunity."To Source Line No." := SourceLineNo;
        WhseCrossDockOpportunity."To Source Subline No." := SourceSubLineNo;
        WhseCrossDockOpportunity."To Source Document" :=
            WhseManagement.GetSourceDocumentType(WhseCrossDockOpportunity."To Source Type", WhseCrossDockOpportunity."To Source Subtype");
        WhseCrossDockOpportunity."Due Date" := DueDate;
        WhseCrossDockOpportunity."To-Src. Unit of Measure Code" := UOMCode;
        WhseCrossDockOpportunity."To-Src. Qty. per Unit of Meas." := QtyPerUOM;
        WhseCrossDockOpportunity."Item No." := ItemNo;
        WhseCrossDockOpportunity."Variant Code" := VariantCode;
        WhseCrossDockOpportunity."Location Code" := LocationCode;

        SubtractExistingCrossDockOppQtysToSource(WhseCrossDockOpportunity);

        OnInsertCrossDockLineOnBeforeCalculateQtyNeeded(QtyOutstanding, QtyOutstandingBase);

        WhseCrossDockOpportunity."Qty. Needed (Base)" := Maximum(WhseCrossDockOpportunity."Qty. Needed (Base)" + QtyOutstandingBase - QtyOnPickBase - QtyPickedBase, 0);
        WhseCrossDockOpportunity."Qty. Needed" := Maximum(WhseCrossDockOpportunity."Qty. Needed" + QtyOutstanding - QtyOnPick - QtyPicked, 0);

        WhseCrossDockOpportunity."Pick Qty. (Base)" := Maximum(WhseCrossDockOpportunity."Pick Qty. (Base)" + QtyOnPickBase, 0);
        WhseCrossDockOpportunity."Pick Qty." := Maximum(WhseCrossDockOpportunity."Pick Qty." + QtyOnPick, 0);

        WhseCrossDockOpportunity."Picked Qty. (Base)" := Maximum(WhseCrossDockOpportunity."Picked Qty. (Base)" + QtyPickedBase, 0);
        WhseCrossDockOpportunity."Picked Qty." := Maximum(WhseCrossDockOpportunity."Picked Qty." + QtyPicked, 0);

        IsHandled := false;
        OnBeforeCrossDockOppInsert(WhseCrossDockOpportunity, QtyPerUOM, NameNo, LineNo, IsHandled);
        if not IsHandled then
            WhseCrossDockOpportunity.Insert();
    end;

    procedure ShowCrossDock(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; SourceTemplateName: Code[10]; SourceNameNo: Code[20]; SourceLineNo: Integer; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10])
    var
        ReceiptLine: Record "Warehouse Receipt Line";
        CrossDockForm: Page "Cross-Dock Opportunities";
        QtyToCrossDock: Decimal;
    begin
        with WhseCrossDockOpportunity do begin
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
        CrossDockForm.SetTableView(WhseCrossDockOpportunity);
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
        BinContentList: Page "Bin Contents List";
    begin
        with BinContent do begin
            SetRange("Item No.", ItemNo);
            SetRange("Variant Code", VariantCode);
            SetRange("Cross-Dock Bin", true);
            if FilterOnUOM then
                SetRange("Unit of Measure Code", UOMCode);
        end;
        with BinContentList do begin
            SetTableView(BinContent);
            Initialize(LocationCode);
            RunModal();
        end;
        Clear(BinContentList);
    end;

    local procedure GetSourceLine(SourceType: Option; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    begin
        if SourceType = Database::"Purchase Line" then begin
            PurchaseLine.Get(SourceSubtype, SourceNo, SourceLineNo);
            SourceType2 := SourceType;
        end;

        OnAfterGetSourceLine(SourceType, SourceSubtype, SourceNo, SourceLineNo);
    end;

    procedure CalculatePickQty(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var QtyOnPick: Decimal; var QtyOnPickBase: Decimal; var QtyPicked: Decimal; var QtyPickedBase: Decimal; Qty: Decimal; QtyBase: Decimal; OutstandingQty: Decimal; OutstandingQtyBase: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculatePickQty(SourceType, SourceSubtype, SourceNo, SourceLineNo, Qty, QtyBase, OutstandingQty,
            OutstandingQtyBase, QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase, IsHandled);
        if not IsHandled then begin
            QtyOnPickBase := 0;
            QtyPickedBase := 0;
            with WarehouseShipmentLine do begin
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

    local procedure SeparateWhseRcptLinesWthSpecOrder(var TempWarehouseReceiptLineNoSpecOrder: Record "Warehouse Receipt Line" temporary; var TempWarehouseReceiptLineWithSpecOrder: Record "Warehouse Receipt Line" temporary; var TempItemVariant: Record "Item Variant" temporary)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FilterWhseRcptLine(WarehouseReceiptLine);
        with WarehouseReceiptLine do
            if FindSet() then
                repeat
                    GetSourceLine("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    if HasSpecialOrder() then begin
                        TempWarehouseReceiptLineWithSpecOrder := WarehouseReceiptLine;
                        TempWarehouseReceiptLineWithSpecOrder.Insert();
                    end else begin
                        TempWarehouseReceiptLineNoSpecOrder := WarehouseReceiptLine;
                        TempWarehouseReceiptLineNoSpecOrder.Insert();
                        InsertToItemList(WarehouseReceiptLine, TempItemVariant);
                    end;
                until Next() = 0;
    end;

    local procedure InsertToItemList(WarehouseReceiptLine: Record "Warehouse Receipt Line"; var TempItemVariant: Record "Item Variant" temporary)
    begin
        with TempItemVariant do begin
            Init();
            "Item No." := WarehouseReceiptLine."Item No.";
            Code := WarehouseReceiptLine."Variant Code";
            if Insert() then;
        end;
    end;

    local procedure FilterWhseRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
        with WarehouseReceiptLine do begin
            SetRange("No.", NameNo);
            SetRange("Location Code", LocationCode);
            SetFilter("Qty. to Receive", '>0');
        end;
    end;

    procedure FilterCrossDockOpp(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity")
    begin
        WhseCrossDockOpportunity.SetRange("Source Template Name", TemplateName);
        WhseCrossDockOpportunity.SetRange("Source Name/No.", NameNo);
        WhseCrossDockOpportunity.SetRange("Location Code", LocationCode);

        OnAfterFilterCrossDockOpp(WhseCrossDockOpportunity);
    end;

    local procedure UpdateQtyToCrossDock(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var RemainingNeededQtyBase: Decimal; var QtyToCrossDockBase: Decimal; var QtyOnCrossDockBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        GetUseCrossDock(UseCrossDocking, WarehouseReceiptLine."Location Code", WarehouseReceiptLine."Item No.");
        if not UseCrossDocking then
            exit;

        RemainingNeededQtyBase :=
            CalcRemainingNeededQtyBase(
                WarehouseReceiptLine."Item No.", WarehouseReceiptLine."Variant Code", RemainingNeededQtyBase,
                QtyToCrossDockBase, QtyOnCrossDockBase, WarehouseReceiptLine."Qty. to Receive (Base)");

        IsHandled := false;
        OnUpdateQtyToCrossDockOnBeforeValidateQtyToCrossDock(WarehouseReceiptLine, IsHandled);
        if not IsHandled then begin
            WarehouseReceiptLine.Validate("Qty. to Cross-Dock", Round(QtyToCrossDockBase / WarehouseReceiptLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
            WarehouseReceiptLine."Qty. to Cross-Dock (Base)" := QtyToCrossDockBase;
            WarehouseReceiptLine.Modify();
        end;

        OnAfterUpdateQtyToCrossDock(WarehouseReceiptLine);
    end;

    local procedure HasSpecialOrder(): Boolean
    begin
        exit((SourceType2 = Database::"Purchase Line") and PurchaseLine."Special Order");
    end;

    local procedure SubtractExistingCrossDockOppQtysToSource(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity")
    var
        ExistingWhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
    begin
        with ExistingWhseCrossDockOpportunity do begin
            SetRange("To Source Type", WhseCrossDockOpportunity."To Source Type");
            SetRange("To Source Subtype", WhseCrossDockOpportunity."To Source Subtype");
            SetRange("To Source No.", WhseCrossDockOpportunity."To Source No.");
            SetRange("To Source Line No.", WhseCrossDockOpportunity."To Source Line No.");
            SetRange("To Source Subline No.", WhseCrossDockOpportunity."To Source Subline No.");
            SetRange("Item No.", WhseCrossDockOpportunity."Item No.");
            SetRange("Variant Code", WhseCrossDockOpportunity."Variant Code");
            CalcSums("Qty. to Cross-Dock (Base)", "Pick Qty. (Base)", "Picked Qty. (Base)");

            WhseCrossDockOpportunity."Qty. Needed" :=
              -Round("Qty. to Cross-Dock (Base)" / WhseCrossDockOpportunity."To-Src. Qty. per Unit of Meas.", UOMMgt.QtyRndPrecision());
            WhseCrossDockOpportunity."Qty. Needed (Base)" := -"Qty. to Cross-Dock (Base)";
            WhseCrossDockOpportunity."Pick Qty." :=
              -Round("Pick Qty. (Base)" / WhseCrossDockOpportunity."To-Src. Qty. per Unit of Meas.", UOMMgt.QtyRndPrecision());
            WhseCrossDockOpportunity."Pick Qty. (Base)" := -"Pick Qty. (Base)";
            WhseCrossDockOpportunity."Picked Qty." :=
              -Round("Picked Qty. (Base)" / WhseCrossDockOpportunity."To-Src. Qty. per Unit of Meas.", UOMMgt.QtyRndPrecision());
            WhseCrossDockOpportunity."Picked Qty. (Base)" := -"Picked Qty. (Base)";
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

    local procedure CalcCrossDockToSalesOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        WarehouseRequest: Record "Warehouse Request";
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
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
        OnCalcCrossDockToSalesOrderOnAfterSalesLineSetFilters(SalesLine, WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        if SalesLine.Find('-') then
            repeat
                if WarehouseRequest.Get(WarehouseRequest.Type::Outbound, SalesLine."Location Code", Database::"Sales Line", SalesLine."Document Type", SalesLine."Document No.") and
                    (WarehouseRequest."Document Status" = WarehouseRequest."Document Status"::Released)
                then begin
                    CalculatePickQty(
                        Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
                        QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase, SalesLine.Quantity, SalesLine."Quantity (Base)",
                        SalesLine."Outstanding Quantity", SalesLine."Outstanding Qty. (Base)");
                    OnCalcCrossDockToSalesOrderOnBeforeInsertCrossDockLine(SalesLine);
                    InsertCrossDockOpp(
                        WhseCrossDockOpportunity,
                        Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0,
                        SalesLine.Quantity, SalesLine."Quantity (Base)", QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase,
                        SalesLine."Unit of Measure Code", SalesLine."Qty. per Unit of Measure", SalesLine."Shipment Date",
                        SalesLine."No.", SalesLine."Variant Code", LineNo);
                end;
                OnCalcCrossDockToSalesOrderOnAfterLoopIteration(WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo, WarehouseRequest, SalesLine);
            until SalesLine.Next() = 0;

        OnAfterCalcCrossDockToSalesOrder(WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
    end;

    local procedure CalcCrossDockToTransferOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    var
        TransferLine: Record "Transfer Line";
        WarehouseRequest: Record "Warehouse Request";
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCrossDockToTransferOrder(WhseCrossDockOpportunity, ItemNo, VariantCode, LocationCode, LineNo, IsHandled);
        if IsHandled then
            exit;

        TransferLine.SetRange("Transfer-from Code", LocationCode);
        TransferLine.SetRange(Status, TransferLine.Status::Released);
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.SetRange("Variant Code", VariantCode);
        TransferLine.SetRange("Shipment Date", 0D, CrossDockDate);
        TransferLine.SetFilter("Outstanding Qty. (Base)", '>0');
        OnCalcCrossDockToTransferOrderOnAfterTransferLineSetFilters(TransferLine, WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        if TransferLine.Find('-') then
            repeat
                if WarehouseRequest.Get(
                    WarehouseRequest.Type::Outbound, TransferLine."Transfer-from Code", Database::"Transfer Line", 0, TransferLine."Document No.") and
                    (WarehouseRequest."Document Status" = WarehouseRequest."Document Status"::Released)
                then begin
                    CalculatePickQty(
                        Database::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.",
                        QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase, TransferLine.Quantity, TransferLine."Quantity (Base)",
                        TransferLine."Outstanding Quantity", TransferLine."Outstanding Qty. (Base)");
                    OnCalcCrossDockToTransferOrderOnBeforeInsertCrossDockLine(TransferLine, WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
                    InsertCrossDockOpp(
                        WhseCrossDockOpportunity,
                        Database::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", 0,
                        TransferLine.Quantity, TransferLine."Quantity (Base)",
                        QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase,
                        TransferLine."Unit of Measure Code", TransferLine."Qty. per Unit of Measure", TransferLine."Shipment Date",
                        TransferLine."Item No.", TransferLine."Variant Code", LineNo);
                end;
            until TransferLine.Next() = 0;
    end;

    local procedure CalcCrossDockToProdOrderComponent(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.SetRange("Variant Code", VariantCode);
        ProdOrderComponent.SetRange("Location Code", LocationCode);
        ProdOrderComponent.SetRange("Due Date", 0D, CrossDockDate);
        ProdOrderComponent.SetRange("Planning Level Code", 0);
        ProdOrderComponent.SetFilter("Remaining Qty. (Base)", '>0');
        if ProdOrderComponent.Find('-') then
            repeat
                ProdOrderComponent.CalcFields("Pick Qty. (Base)");
                OnCalcCrossDockToProdOrderComponentOnBeforeInsertCrossDockLine(ProdOrderComponent);
                InsertCrossDockOpp(
                    WhseCrossDockOpportunity,
                    Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
                    ProdOrderComponent."Line No.", ProdOrderComponent."Prod. Order Line No.",
                    ProdOrderComponent."Remaining Quantity", ProdOrderComponent."Remaining Qty. (Base)",
                    ProdOrderComponent."Pick Qty.", ProdOrderComponent."Pick Qty. (Base)", ProdOrderComponent."Qty. Picked", ProdOrderComponent."Qty. Picked (Base)",
                    ProdOrderComponent."Unit of Measure Code", ProdOrderComponent."Qty. per Unit of Measure", ProdOrderComponent."Due Date",
                    ProdOrderComponent."Item No.", ProdOrderComponent."Variant Code", LineNo);
            until ProdOrderComponent.Next() = 0;
    end;

    local procedure CalcCrossDockToServiceOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    var
        ServiceLine: Record "Service Line";
        WarehouseRequest: Record "Warehouse Request";
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
        OnCalcCrossDockToServiceOrderOnAfterServiceLineSetFilters(ServiceLine, WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        if ServiceLine.Find('-') then
            repeat
                if WarehouseRequest.Get(
                    WarehouseRequest.Type::Outbound, ServiceLine."Location Code", Database::"Service Line", ServiceLine."Document Type", ServiceLine."Document No.") and
                   (WarehouseRequest."Document Status" = WarehouseRequest."Document Status"::Released)
                then begin
                    CalculatePickQty(
                      Database::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.",
                      QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase, ServiceLine.Quantity, ServiceLine."Quantity (Base)",
                      ServiceLine."Outstanding Quantity", ServiceLine."Outstanding Qty. (Base)");
                    OnCalcCrossDockToServiceOrderOnBeforeInsertCrossDockLine(ServiceLine, WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
                    InsertCrossDockOpp(
                      WhseCrossDockOpportunity,
                      Database::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.", 0,
                      ServiceLine.Quantity, ServiceLine."Quantity (Base)",
                      QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase,
                      ServiceLine."Unit of Measure Code", ServiceLine."Qty. per Unit of Measure", ServiceLine."Needed by Date",
                      ServiceLine."No.", ServiceLine."Variant Code", LineNo);
                    OnCalcCrossDockToServiceOrderOnAfterInsertCrossDockLine(ServiceLine, WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
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

