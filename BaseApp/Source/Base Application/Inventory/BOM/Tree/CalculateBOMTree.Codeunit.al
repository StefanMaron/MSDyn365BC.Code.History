// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM.Tree;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.StandardCost;

codeunit 5870 "Calculate BOM Tree"
{

    trigger OnRun()
    begin
    end;

    var
        TempItemAvailByDate: Record "Item Availability by Date" temporary;
        TempMemoizedResult: Record "Memoized Result" temporary;
        ItemFilter: Record Item;
        TempItem: Record Item temporary;
        AvailableToPromise: Codeunit "Available to Promise";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        WindowUpdateDateTime: DateTime;
        LocationSpecific: Boolean;
        HideDialog: Boolean;
        EntryNo: Integer;
        AvailToUse: Option UpdatedQtyOnItemAvail,QtyOnItemAvail,QtyAvail;
        MarkBottleneck: Boolean;
        ShowTotalAvailability: Boolean;
        TreeType: Option " ",Availability,Cost;

#pragma warning disable AA0074
        Text000: Label 'Generating Tree @1@@@@@@@';
#pragma warning restore AA0074

    local procedure OpenWindow()
    begin
        if HideDialog or not GuiAllowed() then
            exit;

        Window.Open(Text000);
        WindowUpdateDateTime := CurrentDateTime;
    end;

    local procedure UpdateWindow(ProgressValue: Integer)
    begin
        if HideDialog or not GuiAllowed() then
            exit;

        if CurrentDateTime - WindowUpdateDateTime >= 300 then begin
            WindowUpdateDateTime := CurrentDateTime;
            Window.Update(1, ProgressValue);
        end;
    end;

    local procedure InitVars()
    begin
        TempItemAvailByDate.Reset();
        TempItemAvailByDate.DeleteAll();
        TempMemoizedResult.Reset();
        TempMemoizedResult.DeleteAll();
        TempItem.Reset();
        TempItem.DeleteAll();
    end;

    local procedure InitBOMBuffer(var BOMBuffer: Record "BOM Buffer")
    begin
        BOMBuffer.Reset();
        BOMBuffer.DeleteAll();
    end;

    local procedure InitTreeType(NewTreeType: Option)
    begin
        TreeType := NewTreeType;
    end;

    procedure GenerateTreeForItems(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; TreeType: Option " ",Availability,Cost)
    var
        i: Integer;
        NoOfRecords: Integer;
        DemandDate: Date;
        IsHandled: Boolean;
    begin
        OnBeforeGenerateTreeForItems(HideDialog);

        OpenWindow();

        IsHandled := false;
        OnBeforeInitBOMBuffer(BOMBuffer, IsHandled);
        if not IsHandled then
            InitBOMBuffer(BOMBuffer);
        InitTreeType(TreeType);
        ItemFilter.Copy(ParentItem);

        if ParentItem.GetFilter(ParentItem."Date Filter") <> '' then
            DemandDate := ParentItem.GetRangeMax(ParentItem."Date Filter")
        else
            DemandDate := 99981231D;
        NoOfRecords := ParentItem.Count;
        if ParentItem.FindSet() then
            repeat
                i += 1;
                UpdateWindow(Round(i / NoOfRecords * 10000, 1));
                GenerateTreeForItemLocal(ParentItem, BOMBuffer, DemandDate, TreeType);
            until ParentItem.Next() = 0;

        ParentItem.Copy(ItemFilter);

        if not HideDialog and GuiAllowed() then
            Window.Close();
    end;

    procedure GenerateTreeForItem(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; DemandDate: Date; TreeType: Option)
    begin
        ItemFilter.Copy(ParentItem);

        ParentItem.Get(ParentItem."No.");
        InitBOMBuffer(BOMBuffer);
        InitTreeType(TreeType);
        GenerateTreeForItemLocal(ParentItem, BOMBuffer, DemandDate, TreeType);
        ParentItem.Copy(ItemFilter);
    end;

    local procedure GenerateTreeForItemLocal(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; DemandDate: Date; TreeType: Option)
    var
        BOMComp: Record "BOM Component";
        ProdBOMLine: Record "Production BOM Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenerateTreeForItemLocal(ParentItem, DemandDate, TreeType, BOMBuffer, IsHandled);
        if IsHandled then
            exit;

        InitVars();

        BOMComp.SetRange(Type, BOMComp.Type::Item);
        BOMComp.SetRange("No.", ParentItem."No.");

        ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
        ProdBOMLine.SetRange("No.", ParentItem."No.");

        if ParentItem.HasBOM() or (ParentItem."Routing No." <> '') then begin
            IsHandled := false;
            OnBeforeFilterBOMBuffer(ParentItem, BOMBuffer, DemandDate, TreeType, IsHandled);
            if not IsHandled then begin
                BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                BOMBuffer.TransferFromItem(EntryNo, ParentItem, DemandDate);
                GenerateItemSubTree(ParentItem."No.", BOMBuffer);
                OnGenerateTreeForItemLocalOnBeforeCalculateTreeType(ParentItem, BOMBuffer, TreeType, EntryNo);
                CalculateTreeType(BOMBuffer, ShowTotalAvailability, TreeType);
                OnAfterFilterBOMBuffer(ParentItem, BOMBuffer, DemandDate, TreeType);
            end;
        end;
    end;

    procedure GenerateTreeForAsm(AsmHeader: Record "Assembly Header"; var BOMBuffer: Record "BOM Buffer"; TreeType: Option)
    begin
        InitBOMBuffer(BOMBuffer);
        InitTreeType(TreeType);
        InitVars();

        LocationSpecific := true;

        BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
        BOMBuffer.TransferFromAsmHeader(EntryNo, AsmHeader);

        if not GenerateAsmHeaderSubTree(AsmHeader, BOMBuffer) then
            GenerateItemSubTree(AsmHeader."Item No.", BOMBuffer);

        CalculateTreeType(BOMBuffer, ShowTotalAvailability, TreeType);
    end;

    procedure GenerateTreeForProdLine(ProdOrderLine: Record "Prod. Order Line"; var BOMBuffer: Record "BOM Buffer"; TreeType: Option)
    begin
        InitBOMBuffer(BOMBuffer);
        InitTreeType(TreeType);
        InitVars();

        LocationSpecific := true;
        BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
        BOMBuffer.TransferFromProdOrderLine(EntryNo, ProdOrderLine);
        if not GenerateProdOrderLineSubTree(ProdOrderLine, BOMBuffer) then
            GenerateItemSubTree(ProdOrderLine."Item No.", BOMBuffer);

        CalculateTreeType(BOMBuffer, ShowTotalAvailability, TreeType);
    end;

    local procedure CalculateTreeType(var BOMBuffer: Record "BOM Buffer"; ShowTotalAvailability: Boolean; TreeType: Option " ",Availability,Cost)
    begin
        case TreeType of
            TreeType::Availability:
                UpdateAvailability(BOMBuffer, ShowTotalAvailability);
            TreeType::Cost:
                UpdateCost(BOMBuffer);
        end;
    end;

    local procedure GenerateItemSubTree(ItemNo: Code[20]; var BOMBuffer: Record "BOM Buffer"): Boolean
    var
        ParentItem: Record Item;
    begin
        ParentItem.Get(ItemNo);
        OnGenerateItemSubTreeOnAfterParentItemGet(ParentItem);
        if TempItem.Get(ItemNo) then begin
            BOMBuffer."Is Leaf" := false;
            BOMBuffer.Modify(true);
            exit(false);
        end;
        TempItem := ParentItem;
        TempItem.Insert();

        if ParentItem."Replenishment System" = ParentItem."Replenishment System"::"Prod. Order" then begin
            BOMBuffer."Is Leaf" := not GenerateProdCompSubTree(ParentItem, BOMBuffer);
            if BOMBuffer."Is Leaf" then
                BOMBuffer."Is Leaf" := not GenerateBOMCompSubTree(ParentItem, BOMBuffer);
        end else begin
            BOMBuffer."Is Leaf" := not GenerateBOMCompSubTree(ParentItem, BOMBuffer);
            if BOMBuffer."Is Leaf" then
                BOMBuffer."Is Leaf" := not GenerateProdCompSubTree(ParentItem, BOMBuffer);
        end;
        BOMBuffer.Modify(true);

        TempItem.Get(ItemNo);
        TempItem.Delete();
        exit(not BOMBuffer."Is Leaf");
    end;

    local procedure GenerateBOMCompSubTree(ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"): Boolean
    var
        BOMComp: Record "BOM Component";
        ParentBOMBuffer: Record "BOM Buffer";
        UOMMgt: Codeunit "Unit of Measure Management";
        IsHandled: Boolean;
    begin
        ParentBOMBuffer := BOMBuffer;
        BOMComp.SetRange("Parent Item No.", ParentItem."No.");
        if BOMComp.FindSet() then begin
            if ParentItem."Replenishment System" <> ParentItem."Replenishment System"::Assembly then
                exit(true);

            IsHandled := false;
            OnGenerateBOMCompSubTreeOnBeforeLoopBOMComponents(ParentItem, IsHandled);
            if IsHandled then
                exit(true);
            repeat
                if (BOMComp."No." <> '') and ((BOMComp.Type = BOMComp.Type::Item) or (TreeType in [TreeType::" ", TreeType::Cost])) then begin
                    BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                    BOMBuffer.TransferFromBOMComp(
                      EntryNo, BOMComp, ParentBOMBuffer.Indentation + 1,
                      Round(
                        ParentBOMBuffer."Qty. per Top Item" *
                        UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code"), UOMMgt.QtyRndPrecision()),
                      Round(
                        ParentBOMBuffer."Scrap Qty. per Top Item" *
                        UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code"), UOMMgt.QtyRndPrecision()),
                      CalcCompDueDate(ParentBOMBuffer."Needed by Date", ParentItem, BOMComp."Lead-Time Offset"),
                      ParentBOMBuffer."Location Code");
                    if BOMComp.Type = BOMComp.Type::Item then
                        GenerateItemSubTree(BOMComp."No.", BOMBuffer);
                end;
            until BOMComp.Next() = 0;
            BOMBuffer := ParentBOMBuffer;
            exit(true);
        end;
    end;

    local procedure GenerateProdCompSubTree(ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer") FoundSubTree: Boolean
    var
        CopyOfParentItem: Record Item;
        ProdBOMLine: Record "Production BOM Line";
        RoutingLine: Record "Routing Line";
        ParentBOMBuffer: Record "BOM Buffer";
        UOMMgt: Codeunit "Unit of Measure Management";
        VersionMgt: Codeunit VersionManagement;
        CostCalculationMgt: Codeunit "Cost Calculation Management";
        LotSize: Decimal;
        BomQtyPerUom: Decimal;
        IsHandled: Boolean;
        RunIteration: Boolean;
    begin
        ParentBOMBuffer := BOMBuffer;
        if not ProdBOMLine.ReadPermission then
            exit;
        ProdBOMLine.SetRange("Production BOM No.", ParentItem."Production BOM No.");
        ProdBOMLine.SetRange("Version Code", VersionMgt.GetBOMVersion(ParentItem."Production BOM No.", WorkDate(), true));
        ProdBOMLine.SetFilter("Starting Date", '%1|..%2', 0D, ParentBOMBuffer."Needed by Date");
        ProdBOMLine.SetFilter("Ending Date", '%1|%2..', 0D, ParentBOMBuffer."Needed by Date");
        IsHandled := false;
        OnBeforeFilterByQuantityPer(ProdBOMLine, IsHandled, ParentBOMBuffer);
        if not IsHandled then
            if TreeType = TreeType::Availability then
                ProdBOMLine.SetFilter("Quantity per", '>%1', 0);
        if ProdBOMLine.FindSet() then begin
            if ParentItem."Replenishment System" <> ParentItem."Replenishment System"::"Prod. Order" then begin
                FoundSubTree := true;
                OnGenerateProdCompSubTreeOnBeforeExitForNonProdOrder(ParentItem, BOMBuffer, FoundSubTree);
                exit(FoundSubTree);
            end;
            repeat
                IsHandled := false;
                OnBeforeTransferProdBOMLine(BOMBuffer, ProdBOMLine, ParentItem, ParentBOMBuffer, EntryNo, TreeType, IsHandled);
                if not IsHandled then
                    if ProdBOMLine."No." <> '' then
                        case ProdBOMLine.Type of
                            ProdBOMLine.Type::Item:
                                begin
                                    BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                                    BomQtyPerUom :=
                                    GetQtyPerBOMHeaderUnitOfMeasure(
                                        ParentItem, ParentBOMBuffer."Production BOM No.",
                                        VersionMgt.GetBOMVersion(ParentBOMBuffer."Production BOM No.", WorkDate(), true));
                                    BOMBuffer.TransferFromProdComp(
                                    EntryNo, ProdBOMLine, ParentBOMBuffer.Indentation + 1,
                                    Round(
                                        ParentBOMBuffer."Qty. per Top Item" *
                                        UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code"), UOMMgt.QtyRndPrecision()),
                                    Round(
                                        ParentBOMBuffer."Scrap Qty. per Top Item" *
                                        UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code"), UOMMgt.QtyRndPrecision()),
                                    ParentBOMBuffer."Scrap %",
                                    CalcCompDueDate(ParentBOMBuffer."Needed by Date", ParentItem, ProdBOMLine."Lead-Time Offset"),
                                    ParentBOMBuffer."Location Code",
                                    ParentItem, BomQtyPerUom);

                                    if ParentItem."Production BOM No." <> ParentBOMBuffer."Production BOM No." then begin
                                        BOMBuffer."Qty. per Parent" := BOMBuffer."Qty. per Parent" * ParentBOMBuffer."Qty. per Parent";
                                        BOMBuffer."Scrap Qty. per Parent" := BOMBuffer."Scrap Qty. per Parent" * ParentBOMBuffer."Qty. per Parent";
                                        BOMBuffer."Qty. per BOM Line" := BOMBuffer."Qty. per BOM Line" * ParentBOMBuffer."Qty. per Parent";
                                    end;
                                    OnAfterTransferFromProdItem(BOMBuffer, ProdBOMLine, EntryNo);
                                    GenerateItemSubTree(ProdBOMLine."No.", BOMBuffer);
                                    OnGenerateProdCompSubTreeOnAfterGenerateItemSubTree(ParentBOMBuffer, BOMBuffer);
                                end;
                            ProdBOMLine.Type::"Production BOM":
                                begin
                                    OnBeforeTransferFromProdBOM(BOMBuffer, ProdBOMLine, ParentItem, ParentBOMBuffer, EntryNo, TreeType);

                                    BOMBuffer := ParentBOMBuffer;
                                    BOMBuffer."Qty. per Top Item" := Round(BOMBuffer."Qty. per Top Item" * ProdBOMLine."Quantity per", UOMMgt.QtyRndPrecision());
                                    if ParentItem."Production BOM No." <> ParentBOMBuffer."Production BOM No." then
                                        BOMBuffer."Qty. per Parent" := ParentBOMBuffer."Qty. per Parent" * ProdBOMLine."Quantity per"
                                    else
                                        BOMBuffer."Qty. per Parent" := ProdBOMLine."Quantity per";

                                    BOMBuffer."Scrap %" := CombineScrapFactors(BOMBuffer."Scrap %", ProdBOMLine."Scrap %");
                                    if CostCalculationMgt.FindRountingLine(RoutingLine, ProdBOMLine, WorkDate(), ParentItem."Routing No.") then
                                        BOMBuffer."Scrap %" := CombineScrapFactors(BOMBuffer."Scrap %", RoutingLine."Scrap Factor % (Accumulated)" * 100);
                                    BOMBuffer."Scrap %" := Round(BOMBuffer."Scrap %", 0.00001);

                                    OnAfterTransferFromProdBOM(BOMBuffer, ProdBOMLine);

                                    CopyOfParentItem := ParentItem;
                                    ParentItem."Routing No." := '';
                                    ParentItem."Production BOM No." := ProdBOMLine."No.";
                                    GenerateProdCompSubTree(ParentItem, BOMBuffer);
                                    ParentItem := CopyOfParentItem;

                                    OnAfterGenerateProdCompSubTree(ParentItem, BOMBuffer, ParentBOMBuffer);
                                end;
                        end;
                OnGenerateProdCompSubTreeOnAfterProdBOMLineLoop(ParentBOMBuffer, BOMBuffer);
            until ProdBOMLine.Next() = 0;
            FoundSubTree := true;
        end;

        if RoutingLine.ReadPermission then
            if (TreeType in [TreeType::" ", TreeType::Cost]) and
                   RoutingLine.CertifiedRoutingVersionExists(ParentItem."Routing No.", WorkDate())
            then begin
                repeat
                    RunIteration := RoutingLine."No." <> '';
                    OnGenerateProdCompSubTreeOnBeforeRoutingLineLoop(RoutingLine, BOMBuffer, RunIteration);
                    if RunIteration then begin
                        BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                        BOMBuffer.TransferFromProdRouting(
                          EntryNo, RoutingLine, ParentBOMBuffer.Indentation + 1,
                          ParentBOMBuffer."Qty. per Top Item" *
                          UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code"),
                          ParentBOMBuffer."Needed by Date",
                          ParentBOMBuffer."Location Code");
                        OnAfterTransferFromProdRouting(BOMBuffer, RoutingLine);
                        if TreeType = TreeType::Cost then begin
                            LotSize := ParentBOMBuffer."Lot Size";
                            if LotSize = 0 then
                                if ParentBOMBuffer."Qty. per Top Item" <> 0 then
                                    LotSize := ParentBOMBuffer."Qty. per Top Item"
                                else
                                    LotSize := 1;
                            CalcRoutingLineCosts(RoutingLine, LotSize, ParentBOMBuffer."Scrap %", BOMBuffer, ParentItem);
                            BOMBuffer.RoundCosts(
                              ParentBOMBuffer."Qty. per Top Item" *
                              UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code") / LotSize);
                            OnGenerateProdCompSubTreeOnBeforeBOMBufferModify(BOMBuffer, ParentBOMBuffer, ParentItem);
                            BOMBuffer.Modify();
                        end;
                        OnGenerateProdCompSubTreeOnAfterBOMBufferModify(BOMBuffer, RoutingLine, LotSize, ParentItem, ParentBOMBuffer, TreeType);
                    end;
                until RoutingLine.Next() = 0;
                FoundSubTree := true;
            end;

        BOMBuffer := ParentBOMBuffer;
    end;

    local procedure GenerateAsmHeaderSubTree(AsmHeader: Record "Assembly Header"; var BOMBuffer: Record "BOM Buffer"): Boolean
    var
        AsmLine: Record "Assembly Line";
        OldAsmHeader: Record "Assembly Header";
        ParentBOMBuffer: Record "BOM Buffer";
    begin
        ParentBOMBuffer := BOMBuffer;
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        if AsmLine.FindSet() then begin
            repeat
                if (AsmLine.Type = AsmLine.Type::Item) and (AsmLine."No." <> '') then begin
                    OldAsmHeader.Get(AsmLine."Document Type", AsmLine."Document No.");
                    if AsmHeader."Due Date" <> OldAsmHeader."Due Date" then
                        AsmLine."Due Date" := AsmLine."Due Date" - (OldAsmHeader."Due Date" - AsmHeader."Due Date");

                    BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                    BOMBuffer.TransferFromAsmLine(EntryNo, AsmLine);
                    GenerateItemSubTree(AsmLine."No.", BOMBuffer);
                end;
                OnGenerateAsmHeaderSubTreeOnAfterAsmLineLoop(ParentBOMBuffer, BOMBuffer);
            until AsmLine.Next() = 0;
            BOMBuffer := ParentBOMBuffer;

            exit(true);
        end;
    end;

    local procedure GenerateProdOrderLineSubTree(ProdOrderLine: Record "Prod. Order Line"; var BOMBuffer: Record "BOM Buffer"): Boolean
    var
        OldProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ParentBOMBuffer: Record "BOM Buffer";
    begin
        ParentBOMBuffer := BOMBuffer;
        ProdOrderComp.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        if ProdOrderComp.FindSet() then begin
            repeat
                if ProdOrderComp."Item No." <> '' then begin
                    OldProdOrderLine.Get(ProdOrderComp.Status, ProdOrderComp."Prod. Order No.", ProdOrderComp."Prod. Order Line No.");
                    if ProdOrderLine."Due Date" <> OldProdOrderLine."Due Date" then
                        ProdOrderComp."Due Date" := ProdOrderComp."Due Date" - (OldProdOrderLine."Due Date" - ProdOrderLine."Due Date");

                    BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                    BOMBuffer.TransferFromProdOrderComp(EntryNo, ProdOrderComp);
                    GenerateItemSubTree(ProdOrderComp."Item No.", BOMBuffer);
                end;
            until ProdOrderComp.Next() = 0;
            BOMBuffer := ParentBOMBuffer;

            exit(true);
        end;
    end;

    local procedure UpdateMinAbleToMake(var BOMBuffer: Record "BOM Buffer"; AvailToUse: Option UpdatedQtyOnItemAvail,QtyOnItemAvail,QtyAvail): Decimal
    var
        AvailQty: Decimal;
    begin
        TempItemAvailByDate.SetRange("Item No.", BOMBuffer."No.");
        TempItemAvailByDate.SetRange("Variant Code", BOMBuffer."Variant Code");
        if LocationSpecific then
            TempItemAvailByDate.SetRange("Location Code", BOMBuffer."Location Code");
        TempItemAvailByDate.SetRange(Date, BOMBuffer."Needed by Date");
        TempItemAvailByDate.FindFirst();

        case AvailToUse of
            AvailToUse::UpdatedQtyOnItemAvail:
                AvailQty := TempItemAvailByDate."Updated Available Qty";
            AvailToUse::QtyOnItemAvail:
                AvailQty := TempItemAvailByDate."Available Qty";
            AvailToUse::QtyAvail:
                AvailQty := BOMBuffer."Available Quantity";
        end;

        if BOMBuffer."Calculation Formula" = BOMBuffer."Calculation Formula"::"Fixed Quantity" then
            exit(MinAbleToMakeWithFixedQuantity(BOMBuffer, AvailQty))
        else begin
            BOMBuffer.UpdateAbleToMake(AvailQty);
            BOMBuffer.Modify();
            exit(BOMBuffer."Able to Make Top Item");
        end;
    end;

    local procedure MinAbleToMakeWithFixedQuantity(var BOMBuffer: Record "BOM Buffer"; AvailableQty: Decimal): Decimal
    begin
        if BOMBuffer."Calculation Formula" = BOMBuffer."Calculation Formula"::"Fixed Quantity" then begin
            UpdateAvailabilityForFixedQty(BOMBuffer, AvailableQty);
            if AvailableQty < BOMBuffer."Qty. per Parent" then
                exit(0)
            else
                exit(999999999);
        end;
    end;

    local procedure UpdateAvailabilityForFixedQty(var BOMBuffer: Record "BOM Buffer"; AvailableQty: Decimal)
    begin
        if BOMBuffer."Calculation Formula" = BOMBuffer."Calculation Formula"::"Fixed Quantity" then begin
            BOMBuffer."Available Quantity" := AvailableQty;
            BOMBuffer.Modify();
        end;
    end;

    local procedure CalcMinAbleToMake(IsFirst: Boolean; OldMin: Decimal; NewMin: Decimal): Decimal
    begin
        if NewMin <= 0 then
            exit(0);
        if IsFirst then
            exit(NewMin);
        if NewMin < OldMin then
            exit(NewMin);
        exit(OldMin);
    end;

    local procedure InitItemAvailDates(var BOMBuffer: Record "BOM Buffer")
    var
        BOMItem: Record Item;
        ParentBOMBuffer: Record "BOM Buffer";
        ZeroDF: DateFormula;
    begin
        ParentBOMBuffer := BOMBuffer;
        TempItemAvailByDate.Reset();
        TempItemAvailByDate.DeleteAll();
        Evaluate(ZeroDF, '<0D>');

        repeat
            if not AvailByDateExists(BOMBuffer) then begin
                BOMItem.CopyFilters(ItemFilter);
                BOMItem.Get(BOMBuffer."No.");
                BOMItem.SetRange("Date Filter", 0D, BOMBuffer."Needed by Date");
                if BOMBuffer.Indentation = 0 then begin
                    BOMItem.SetFilter("Variant Filter", ItemFilter.GetFilter("Variant Filter"));
                    BOMItem.SetFilter("Location Filter", ItemFilter.GetFilter("Location Filter"));
                end else
                    BOMItem.SetRange("Variant Filter", BOMBuffer."Variant Code");

                TempItemAvailByDate.Init();
                TempItemAvailByDate."Item No." := BOMBuffer."No.";
                TempItemAvailByDate.Date := BOMBuffer."Needed by Date";
                TempItemAvailByDate."Variant Code" := BOMBuffer."Variant Code";
                if LocationSpecific then
                    TempItemAvailByDate."Location Code" := BOMBuffer."Location Code";

                Clear(AvailableToPromise);
                OnInitItemAvailDatesOnBeforeCalcAvailableQty(BOMItem);
                TempItemAvailByDate."Available Qty" :=
                  AvailableToPromise.CalcQtyAvailabletoPromise(
                      BOMItem, BOMBuffer."Gross Requirement", BOMBuffer."Scheduled Receipts", BOMBuffer."Needed by Date", "Analysis Period Type"::Day, ZeroDF);
                TempItemAvailByDate."Updated Available Qty" := TempItemAvailByDate."Available Qty";
                TempItemAvailByDate.Insert();

                BOMBuffer.Modify();
            end;
        until (BOMBuffer.Next() = 0) or (BOMBuffer.Indentation <= ParentBOMBuffer.Indentation);
        BOMBuffer := ParentBOMBuffer;
        BOMBuffer.Find();
    end;

    local procedure UpdateAvailability(var BOMBuffer: Record "BOM Buffer"; ShowTotalAvailability: Boolean)
    var
        CopyOfBOMBuffer: Record "BOM Buffer";
        SubOptimalQty: Decimal;
        OptimalQty: Decimal;
    begin
        CopyOfBOMBuffer.Copy(BOMBuffer);
        BOMBuffer.SetRange("Inventoriable", true);
        if BOMBuffer.Find() then
            repeat
                if BOMBuffer.Indentation = 0 then begin
                    InitItemAvailDates(BOMBuffer);
                    SubOptimalQty := TraverseTree(BOMBuffer, AvailToUse::QtyOnItemAvail);
                    TempMemoizedResult.DeleteAll();
                    OptimalQty := BinarySearchOptimal(BOMBuffer, UOMMgt.QtyRndPrecision(), SubOptimalQty);
                    MarkBottlenecks(BOMBuffer, OptimalQty);
                    CalcAvailability(BOMBuffer, OptimalQty, false);
                    if ShowTotalAvailability then
                        DistributeRemainingAvail(BOMBuffer);
                    TraverseTree(BOMBuffer, AvailToUse::QtyAvail);
                end;
            until BOMBuffer.Next() = 0;
        BOMBuffer.SetRange("Inventoriable");
        BOMBuffer.Copy(CopyOfBOMBuffer);
    end;

    local procedure TraverseTree(var BOMBuffer: Record "BOM Buffer"; AvailToUse: Option UpdatedQtyOnItemAvail,QtyOnItemAvail,QtyAvail): Decimal
    var
        ParentBOMBuffer: Record "BOM Buffer";
        IsFirst: Boolean;
        MinAbleToMakeQty: Decimal;
        MinAbleToMakeTopItem: Decimal;
        IsHandled: Boolean;
    begin
        ParentBOMBuffer := BOMBuffer;
        IsFirst := true;
        while (BOMBuffer.Next() <> 0) and (ParentBOMBuffer.Indentation < BOMBuffer.Indentation) do
            if ParentBOMBuffer.Indentation + 1 = BOMBuffer.Indentation then begin
                if not BOMBuffer."Is Leaf" then
                    TraverseTree(BOMBuffer, AvailToUse)
                else begin
                    MinAbleToMakeQty := UpdateMinAbleToMake(BOMBuffer, AvailToUse);
                    MinAbleToMakeTopItem := CalcMinAbleToMake(IsFirst, MinAbleToMakeTopItem, MinAbleToMakeQty);
                end;

                IsHandled := false;
                OnTraverseTreeOnBeforeCalcAbleToMakeParentAndTopItem(BOMBuffer, ParentBOMBuffer, IsHandled);
                if not IsHandled then
                    if BOMBuffer."Calculation Formula" = BOMBuffer."Calculation Formula"::"Fixed Quantity" then begin
                        ParentBOMBuffer."Able to Make Parent" := CalcMinAbleToMake(IsFirst, ParentBOMBuffer."Able to Make Parent", MinAbleToMakeTopItem);
                        ParentBOMBuffer."Able to Make Top Item" := CalcMinAbleToMake(IsFirst, ParentBOMBuffer."Able to Make Top Item", MinAbleToMakeTopItem);
                    end
                    else begin
                        ParentBOMBuffer."Able to Make Parent" := CalcMinAbleToMake(IsFirst, ParentBOMBuffer."Able to Make Parent", BOMBuffer."Able to Make Parent");
                        MinAbleToMakeTopItem := CalcMinAbleToMake(IsFirst, ParentBOMBuffer."Able to Make Top Item", BOMBuffer."Able to Make Top Item");
                        ParentBOMBuffer."Able to Make Top Item" := MinAbleToMakeTopItem;
                    end;
                IsFirst := false;
            end;

        BOMBuffer := ParentBOMBuffer;
        UpdateMinAbleToMake(BOMBuffer, AvailToUse);
        exit(MinAbleToMakeTopItem);
    end;

    local procedure UpdateCost(var BOMBuffer: Record "BOM Buffer")
    var
        CopyOfBOMBuffer: Record "BOM Buffer";
    begin
        CopyOfBOMBuffer.Copy(BOMBuffer);
        if BOMBuffer.Find() then
            repeat
                if BOMBuffer.Indentation = 0 then
                    TraverseCostTree(BOMBuffer);
            until BOMBuffer.Next() = 0;
        BOMBuffer.Copy(CopyOfBOMBuffer);
    end;

    local procedure TraverseCostTree(var BOMBuffer: Record "BOM Buffer"): Decimal
    var
        ParentBOMBuffer: Record "BOM Buffer";
    begin
        ParentBOMBuffer := BOMBuffer;
        while (BOMBuffer.Next() <> 0) and (ParentBOMBuffer.Indentation < BOMBuffer.Indentation) do
            if (ParentBOMBuffer.Indentation + 1 = BOMBuffer.Indentation) and
               ((BOMBuffer."Qty. per Top Item" <> 0) or (BOMBuffer.Type in [BOMBuffer.Type::"Machine Center", BOMBuffer.Type::"Work Center"]))
            then begin
                if not BOMBuffer."Is Leaf" then
                    TraverseCostTree(BOMBuffer)
                else
                    if (BOMBuffer.Type = BOMBuffer.Type::Resource) and (BOMBuffer."Resource Usage Type" = BOMBuffer."Resource Usage Type"::Fixed) then
                        UpdateNodeCosts(BOMBuffer, ParentBOMBuffer."Lot Size" / ParentBOMBuffer."Qty. per Top Item")
                    else
                        UpdateNodeCosts(BOMBuffer, 1);

                if BOMBuffer."Is Leaf" then begin
                    ParentBOMBuffer.AddMaterialCost(BOMBuffer."Single-Level Material Cost", BOMBuffer."Rolled-up Material Cost");
                    ParentBOMBuffer.AddCapacityCost(BOMBuffer."Single-Level Capacity Cost", BOMBuffer."Rolled-up Capacity Cost");
                    ParentBOMBuffer.AddSubcontrdCost(BOMBuffer."Single-Level Subcontrd. Cost", BOMBuffer."Rolled-up Subcontracted Cost");
                    ParentBOMBuffer.AddCapOvhdCost(BOMBuffer."Single-Level Cap. Ovhd Cost", BOMBuffer."Rolled-up Capacity Ovhd. Cost");
                    ParentBOMBuffer.AddMfgOvhdCost(BOMBuffer."Single-Level Mfg. Ovhd Cost", BOMBuffer."Rolled-up Mfg. Ovhd Cost");
                    ParentBOMBuffer.AddScrapCost(BOMBuffer."Single-Level Scrap Cost", BOMBuffer."Rolled-up Scrap Cost");
                end else begin
                    ParentBOMBuffer.AddMaterialCost(
                      BOMBuffer."Single-Level Material Cost" +
                      BOMBuffer."Single-Level Capacity Cost" +
                      BOMBuffer."Single-Level Subcontrd. Cost" +
                      BOMBuffer."Single-Level Cap. Ovhd Cost" +
                      BOMBuffer."Single-Level Mfg. Ovhd Cost",
                      BOMBuffer."Rolled-up Material Cost");
                    ParentBOMBuffer.AddCapacityCost(0, BOMBuffer."Rolled-up Capacity Cost");
                    ParentBOMBuffer.AddSubcontrdCost(0, BOMBuffer."Rolled-up Subcontracted Cost");
                    ParentBOMBuffer.AddCapOvhdCost(0, BOMBuffer."Rolled-up Capacity Ovhd. Cost");
                    ParentBOMBuffer.AddMfgOvhdCost(0, BOMBuffer."Rolled-up Mfg. Ovhd Cost");
                    ParentBOMBuffer.AddScrapCost(0, BOMBuffer."Rolled-up Scrap Cost");
                end;
                OnTraverseCostTreeOnAfterAddCosts(ParentBOMBuffer, BOMBuffer);
            end;

        BOMBuffer := ParentBOMBuffer;
        UpdateNodeCosts(BOMBuffer, ParentBOMBuffer."Lot Size");
        exit(BOMBuffer."Able to Make Top Item");
    end;

    local procedure UpdateNodeCosts(var BOMBuffer: Record "BOM Buffer"; LotSize: Decimal)
    begin
        if LotSize = 0 then
            LotSize := 1;
        BOMBuffer.RoundCosts(LotSize);

        if BOMBuffer."Is Leaf" then begin
            case BOMBuffer.Type of
                BOMBuffer.Type::Item:
                    BOMBuffer.GetItemCosts();
                BOMBuffer.Type::Resource:
                    BOMBuffer.GetResCosts();
            end;
            BOMBuffer.RoundCosts(1 / LotSize);
        end else
            if IsProductionOrAssemblyItem(BOMBuffer."No.") then begin
                BOMBuffer.CalcOvhdCost();
                BOMBuffer.RoundCosts(1 / LotSize);
                if not HasBomStructure(BOMBuffer."No.") then
                    BOMBuffer.GetItemUnitCost();
            end else
                if BOMBuffer.Type = BOMBuffer.Type::Item then begin
                    BOMBuffer.RoundCosts(1 / LotSize);
                    BOMBuffer.GetItemCosts();
                end;

        BOMBuffer.CalcUnitCost();
        BOMBuffer.Modify();
    end;

    local procedure BinarySearchOptimal(var BOMBuffer: Record "BOM Buffer"; InputLow: Decimal; InputHigh: Decimal): Decimal
    var
        InputMid: Decimal;
    begin
        if InputHigh <= 0 then
            exit(0);
        if CalcAvailability(BOMBuffer, InputHigh, true) then begin
            TempMemoizedResult.DeleteAll();
            exit(InputHigh);
        end;
        if InputHigh - InputLow = UOMMgt.QtyRndPrecision() then begin
            TempMemoizedResult.DeleteAll();
            exit(InputLow);
        end;
        InputMid := Round((InputLow + InputHigh) / 2, UOMMgt.QtyRndPrecision());
        if not CalcAvailability(BOMBuffer, InputMid, true) then
            exit(BinarySearchOptimal(BOMBuffer, InputLow, InputMid));
        exit(BinarySearchOptimal(BOMBuffer, InputMid, InputHigh));
    end;

    local procedure CalcAvailability(var BOMBuffer: Record "BOM Buffer"; Input: Decimal; IsTest: Boolean): Boolean
    var
        ParentBOMBuffer: Record "BOM Buffer";
        ExpectedQty: Decimal;
        AvailQty: Decimal;
        MaxTime: Integer;
    begin
        if BOMBuffer.Indentation = 0 then begin
            if IsTest then
                if TempMemoizedResult.Get(Input) then
                    exit(TempMemoizedResult.Output);

            ResetUpdatedAvailability();
        end;

        MaxTime := 0;
        ParentBOMBuffer := BOMBuffer;
        while (BOMBuffer.Next() <> 0) and (ParentBOMBuffer.Indentation < BOMBuffer.Indentation) do
            if ParentBOMBuffer.Indentation + 1 = BOMBuffer.Indentation then begin
                TempItemAvailByDate.SetRange("Item No.", BOMBuffer."No.");
                TempItemAvailByDate.SetRange(Date, BOMBuffer."Needed by Date");
                TempItemAvailByDate.SetRange("Variant Code", BOMBuffer."Variant Code");
                if LocationSpecific then
                    TempItemAvailByDate.SetRange("Location Code", BOMBuffer."Location Code");
                TempItemAvailByDate.FindFirst();
                if BOMBuffer."Calculation Formula" = BOMBuffer."Calculation Formula"::"Fixed Quantity" then begin
                    ExpectedQty := Round(BOMBuffer."Qty. per Parent", UOMMgt.QtyRndPrecision());
                    AvailQty := TempItemAvailByDate."Available Qty"
                end
                else begin
                    ExpectedQty := Round(BOMBuffer."Qty. per Parent" * Input, UOMMgt.QtyRndPrecision());
                    AvailQty := TempItemAvailByDate."Updated Available Qty";
                end;

                if AvailQty < ExpectedQty then begin
                    if BOMBuffer."Is Leaf" then begin
                        if MarkBottleneck then begin
                            BOMBuffer.Bottleneck := true;
                            BOMBuffer.Modify(true);
                        end;
                        BOMBuffer := ParentBOMBuffer;
                        if (BOMBuffer.Indentation = 0) and IsTest then
                            AddMemoizedResult(Input, false);
                        exit(false);
                    end;
                    if AvailQty <> 0 then
                        ReduceAvailability(BOMBuffer."No.", BOMBuffer."Variant Code", BOMBuffer."Location Code", BOMBuffer."Needed by Date", AvailQty, BOMBuffer."Calculation Formula");
                    if not IsTest then begin
                        BOMBuffer."Available Quantity" := AvailQty;
                        BOMBuffer.Modify();
                    end;
                    if not CalcAvailability(BOMBuffer, ExpectedQty - AvailQty, IsTest) then begin
                        if MarkBottleneck then begin
                            BOMBuffer.Bottleneck := true;
                            BOMBuffer.Modify(true);
                        end;
                        BOMBuffer := ParentBOMBuffer;
                        if (BOMBuffer.Indentation = 0) and IsTest then
                            AddMemoizedResult(Input, false);
                        exit(false);
                    end;
                    if not IsTest then
                        if MaxTime < (ParentBOMBuffer."Needed by Date" - BOMBuffer."Needed by Date") + BOMBuffer."Rolled-up Lead-Time Offset" then
                            MaxTime := (ParentBOMBuffer."Needed by Date" - BOMBuffer."Needed by Date") + BOMBuffer."Rolled-up Lead-Time Offset";
                end else begin
                    if not IsTest then begin
                        if BOMBuffer."Calculation Formula" <> BOMBuffer."Calculation Formula"::"Fixed Quantity" then begin
                            BOMBuffer."Available Quantity" := ExpectedQty;
                            BOMBuffer.Modify();
                        end;
                        if MaxTime < (ParentBOMBuffer."Needed by Date" - BOMBuffer."Needed by Date") + BOMBuffer."Rolled-up Lead-Time Offset" then
                            MaxTime := (ParentBOMBuffer."Needed by Date" - BOMBuffer."Needed by Date") + BOMBuffer."Rolled-up Lead-Time Offset";
                    end;
                    ReduceAvailability(BOMBuffer."No.", BOMBuffer."Variant Code", BOMBuffer."Location Code", BOMBuffer."Needed by Date", ExpectedQty, BOMBuffer."Calculation Formula");
                end;
            end;
        BOMBuffer := ParentBOMBuffer;
        BOMBuffer."Rolled-up Lead-Time Offset" := MaxTime;
        BOMBuffer.Modify(true);
        if (BOMBuffer.Indentation = 0) and IsTest then
            AddMemoizedResult(Input, true);
        exit(true);
    end;

    local procedure AddMemoizedResult(NewInput: Decimal; NewOutput: Boolean)
    begin
        TempMemoizedResult.Input := NewInput;
        TempMemoizedResult.Output := NewOutput;
        TempMemoizedResult.Insert();
    end;

    local procedure ResetUpdatedAvailability()
    begin
        TempItemAvailByDate.Reset();
        if TempItemAvailByDate.Find('-') then
            repeat
                if TempItemAvailByDate."Updated Available Qty" <> TempItemAvailByDate."Available Qty" then begin
                    TempItemAvailByDate."Updated Available Qty" := TempItemAvailByDate."Available Qty";
                    TempItemAvailByDate.Modify();
                end;
            until TempItemAvailByDate.Next() = 0;
    end;

    local procedure ReduceAvailability(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; ToDate: Date; Qty: Decimal; BOMLineCalcFormula: Enum "Quantity Calculation Formula")
    begin
        if BOMLineCalcFormula = BOMLineCalcFormula::"Fixed Quantity" then
            exit;
        TempItemAvailByDate.Reset();
        TempItemAvailByDate.SetRange("Item No.", ItemNo);
        TempItemAvailByDate.SetRange("Variant Code", VariantCode);
        if LocationSpecific then
            TempItemAvailByDate.SetRange("Location Code", LocationCode);
        TempItemAvailByDate.SetRange(Date, 0D, ToDate);
        if TempItemAvailByDate.FindSet() then
            repeat
                if TempItemAvailByDate."Updated Available Qty" <> 0 then begin
                    if TempItemAvailByDate."Updated Available Qty" > Qty then
                        TempItemAvailByDate."Updated Available Qty" := TempItemAvailByDate."Updated Available Qty" - Qty
                    else
                        TempItemAvailByDate."Updated Available Qty" := 0;
                    TempItemAvailByDate.Modify();
                end;
            until TempItemAvailByDate.Next() = 0;
        TempItemAvailByDate.SetRange("Item No.");
        TempItemAvailByDate.SetRange("Variant Code");
        TempItemAvailByDate.SetRange("Location Code");
        TempItemAvailByDate.SetRange(Date);
    end;

    local procedure DistributeRemainingAvail(var BOMBuffer: Record "BOM Buffer")
    var
        CurrItemAvailByDate: Record "Item Availability by Date";
        CopyOfBOMBuffer: Record "BOM Buffer";
    begin
        CopyOfBOMBuffer.Copy(BOMBuffer);
        BOMBuffer.Reset();
        BOMBuffer.SetCurrentKey(Type, "No.", Indentation);
        BOMBuffer.SetFilter("Entry No.", '>=%1', BOMBuffer."Entry No.");
        BOMBuffer.SetFilter("Calculation Formula", '<>%1', BOMBuffer."Calculation Formula"::"Fixed Quantity");
        TempItemAvailByDate.Reset();
        if TempItemAvailByDate.FindSet() then
            repeat
                if TempItemAvailByDate."Updated Available Qty" <> 0 then begin
                    CurrItemAvailByDate := TempItemAvailByDate;

                    BOMBuffer.SetRange(Type, BOMBuffer.Type);
                    BOMBuffer.SetRange("No.", TempItemAvailByDate."Item No.");
                    BOMBuffer.SetRange("Variant Code", TempItemAvailByDate."Variant Code");
                    if LocationSpecific then
                        BOMBuffer.SetRange("Location Code", TempItemAvailByDate."Location Code");
                    BOMBuffer.SetRange("Needed by Date", TempItemAvailByDate.Date);
                    if BOMBuffer.FindFirst() then begin
                        BOMBuffer."Available Quantity" += TempItemAvailByDate."Updated Available Qty";
                        BOMBuffer."Unused Quantity" += TempItemAvailByDate."Updated Available Qty";
                        BOMBuffer.Modify();

                        ReduceAvailability(BOMBuffer."No.", BOMBuffer."Variant Code", BOMBuffer."Location Code", BOMBuffer."Needed by Date", TempItemAvailByDate."Updated Available Qty", BOMBuffer."Calculation Formula");
                    end;

                    TempItemAvailByDate := CurrItemAvailByDate;
                end;
            until TempItemAvailByDate.Next() = 0;
        BOMBuffer.Copy(CopyOfBOMBuffer);
        BOMBuffer.Find();
    end;

    local procedure MarkBottlenecks(var BOMBuffer: Record "BOM Buffer"; Input: Decimal)
    begin
        MarkBottleneck := true;
        CalcAvailability(BOMBuffer, Input + UOMMgt.QtyRndPrecision(), true);
        MarkBottleneck := false;
    end;

    local procedure CalcCompDueDate(DemandDate: Date; ParentItem: Record Item; LeadTimeOffset: DateFormula) DueDate: Date
    var
        MfgSetup: Record "Manufacturing Setup";
        EndDate: Date;
        StartDate: Date;
    begin
        if DemandDate = 0D then
            exit;

        EndDate := DemandDate;
        if Format(ParentItem."Safety Lead Time") <> '' then
            EndDate := DemandDate - (CalcDate(ParentItem."Safety Lead Time", DemandDate) - DemandDate)
        else
            if MfgSetup.Get() and (Format(MfgSetup."Default Safety Lead Time") <> '') then
                EndDate := DemandDate - (CalcDate(MfgSetup."Default Safety Lead Time", DemandDate) - DemandDate);

        if Format(ParentItem."Lead Time Calculation") = '' then
            StartDate := EndDate
        else
            StartDate := EndDate - (CalcDate(ParentItem."Lead Time Calculation", EndDate) - EndDate);

        if Format(LeadTimeOffset) = '' then
            DueDate := StartDate
        else
            DueDate := StartDate - (CalcDate(LeadTimeOffset, StartDate) - StartDate);
    end;

    local procedure AvailByDateExists(BOMBuffer: Record "BOM Buffer"): Boolean
    begin
        if LocationSpecific then
            exit(TempItemAvailByDate.Get(BOMBuffer."No.", BOMBuffer."Variant Code", BOMBuffer."Location Code", BOMBuffer."Needed by Date"));
        exit(TempItemAvailByDate.Get(BOMBuffer."No.", BOMBuffer."Variant Code", '', BOMBuffer."Needed by Date"));
    end;

    procedure SetShowTotalAvailability(NewShowTotalAvailability: Boolean)
    begin
        ShowTotalAvailability := NewShowTotalAvailability;
    end;

    local procedure CalcRoutingLineCosts(RoutingLine: Record "Routing Line"; LotSize: Decimal; ScrapPct: Decimal; var BOMBuffer: Record "BOM Buffer"; ParentItem: Record Item)
    var
        CalcStdCost: Codeunit "Calculate Standard Cost";
        CostCalculationMgt: Codeunit "Cost Calculation Management";
        CapCost: Decimal;
        SubcontractedCapCost: Decimal;
        CapOverhead: Decimal;
    begin
        OnBeforeCalcRoutingLineCosts(RoutingLine, LotSize, ScrapPct, ParentItem);

        CalcStdCost.SetProperties(WorkDate(), false, false, false, '', false);
        CalcStdCost.CalcRtngLineCost(
          RoutingLine, CostCalculationMgt.CalcQtyAdjdForBOMScrap(LotSize, ScrapPct), CapCost, SubcontractedCapCost, CapOverhead, ParentItem);

        OnCalcRoutingLineCostsOnBeforeBOMBufferAdd(RoutingLine, LotSize, ScrapPct, CapCost, SubcontractedCapCost, CapOverhead, BOMBuffer);

        BOMBuffer.AddCapacityCost(CapCost, CapCost);
        BOMBuffer.AddSubcontrdCost(SubcontractedCapCost, SubcontractedCapCost);
        BOMBuffer.AddCapOvhdCost(CapOverhead, CapOverhead);
    end;

    local procedure HasBomStructure(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        case Item."Replenishment System" of
            Item."Replenishment System"::Assembly:
                begin
                    Item.CalcFields("Assembly BOM");
                    if Item."Assembly BOM" then
                        exit(true);
                end;
            Item."Replenishment System"::"Prod. Order":
                if Item."Production BOM No." <> '' then
                    exit(true);
        end;
    end;

    local procedure IsProductionOrAssemblyItem(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        if not Item.Get(ItemNo) then
            exit(false);

        exit(Item.IsMfgItem() or Item.IsAssemblyItem());
    end;

    procedure SetItemFilter(var Item: Record Item)
    begin
        ItemFilter.CopyFilters(Item);
    end;

    local procedure GetBOMUnitOfMeasure(ProdBOMNo: Code[20]; ProdBOMVersionNo: Code[20]): Code[10]
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
    begin
        if ProdBOMVersionNo <> '' then begin
            ProdBOMVersion.Get(ProdBOMNo, ProdBOMVersionNo);
            exit(ProdBOMVersion."Unit of Measure Code");
        end;

        ProdBOMHeader.Get(ProdBOMNo);
        exit(ProdBOMHeader."Unit of Measure Code");
    end;

    local procedure GetQtyPerBOMHeaderUnitOfMeasure(Item: Record Item; ProdBOMNo: Code[20]; ProdBOMVersionNo: Code[20]): Decimal
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        if ProdBOMNo = '' then
            exit(1);

        exit(UOMMgt.GetQtyPerUnitOfMeasure(Item, GetBOMUnitOfMeasure(ProdBOMNo, ProdBOMVersionNo)));
    end;

    local procedure CombineScrapFactors(LowLevelScrapPct: Decimal; HighLevelScrapPct: Decimal): Decimal
    begin
        exit(LowLevelScrapPct + HighLevelScrapPct + LowLevelScrapPct * HighLevelScrapPct / 100);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterBOMBuffer(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; DemandDate: Date; TreeType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGenerateProdCompSubTree(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; var ParentBOMBuffer: Record "BOM Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdItem(var BOMBuffer: Record "BOM Buffer"; ProdBOMLine: Record "Production BOM Line"; var EntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdBOM(var BOMBuffer: Record "BOM Buffer"; ProdBOMLine: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdRouting(var BOMBuffer: Record "BOM Buffer"; var RoutingLine: Record "Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRoutingLineCosts(var RoutingLine: Record "Routing Line"; var LotSize: Decimal; var ScrapPct: Decimal; ParentItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFilterBOMBuffer(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; DemandDate: Date; TreeType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFilterByQuantityPer(var ProductionBOMLine: Record "Production BOM Line"; var IsHandled: Boolean; BOMBuffer: Record "BOM Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateTreeForItems(var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateTreeForItemLocal(var ParentItem: Record Item; DemandDate: Date; TreeType: Option; var BOMBuffer: Record "BOM Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferFromProdBOM(var BOMBuffer: Record "BOM Buffer"; var ProdBOMLine: Record "Production BOM Line"; var ParentItem: Record Item; var ParentBOMBuffer: Record "BOM Buffer"; var EntryNo: Integer; TreeType: Option " ",Availability,Cost)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferProdBOMLine(var BOMBuffer: Record "BOM Buffer"; var ProdBOMLine: Record "Production BOM Line"; var ParentItem: Record Item; var ParentBOMBuffer: Record "BOM Buffer"; var EntryNo: Integer; TreeType: Option " ",Availability,Cost; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateAsmHeaderSubTreeOnAfterAsmLineLoop(var ParentBOMBuffer: Record "BOM Buffer"; var BOMBuffer: Record "BOM Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnBeforeExitForNonProdOrder(ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; var FoundSubTree: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnAfterGenerateItemSubTree(var ParentBOMBuffer: Record "BOM Buffer"; var BOMBuffer: Record "BOM Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnAfterProdBOMLineLoop(var ParentBOMBuffer: Record "BOM Buffer"; var BOMBuffer: Record "BOM Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateItemSubTreeOnAfterParentItemGet(var ParentItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnBeforeBOMBufferModify(var BOMBuffer: Record "BOM Buffer"; var ParentBOMBuffer: Record "BOM Buffer"; ParentItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTraverseCostTreeOnAfterAddCosts(var ParentBOMBuffer: Record "BOM Buffer"; var BOMBuffer: Record "BOM Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTraverseTreeOnBeforeCalcAbleToMakeParentAndTopItem(var BOMBuffer: Record "BOM Buffer"; var ParentBOMBuffer: Record "BOM Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRoutingLineCostsOnBeforeBOMBufferAdd(RoutingLine: Record "Routing Line"; LotSize: Decimal; ScrapPct: Decimal; var CapCost: Decimal; var SubcontractedCapCost: Decimal; var CapOverhead: Decimal; var BOMBuffer: Record "BOM Buffer");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnAfterBOMBufferModify(var BOMBuffer: Record "BOM Buffer"; RoutingLine: Record "Routing Line"; LotSize: Decimal; ParentItem: Record Item; ParentBOMBuffer: Record "BOM Buffer"; TreeType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnBeforeRoutingLineLoop(var RoutingLine: Record "Routing Line"; var BOMBuffer: Record "BOM Buffer"; var RunIteration: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateTreeForItemLocalOnBeforeCalculateTreeType(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; var TreeType: Option; var EntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitItemAvailDatesOnBeforeCalcAvailableQty(var BOMItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateBOMCompSubTreeOnBeforeLoopBOMComponents(ParentItem: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitBOMBuffer(var BOMBuffer: Record "BOM Buffer"; var IsHandled: Boolean)
    begin
    end;
}

