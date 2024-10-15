// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Assembly.History;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 5836 "Cost Calculation Management"
{
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Prod. Order Capacity Need" = r,
                  TableData "Value Entry" = r;

    SingleInstance = true;

    procedure ResourceCostPerUnit(No: Code[20]; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal)
    var
        Resource: Record Resource;
    begin
        Resource.Get(No);
        DirUnitCost := Resource."Direct Unit Cost";
        OvhdRate := 0;
        IndirCostPct := Resource."Indirect Cost %";
        UnitCost := Resource."Unit Cost";
    end;

#if not CLEAN23
    [Obsolete('Replaced by procedure CalcRoutingCostPerUnit()', '23.0')]
    procedure RoutingCostPerUnit(Type: Enum "Capacity Type"; No: Code[20]; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Option Time,Unit)
    var
        UnitCostCalculationTypeEnum: Enum "Unit Cost Calculation Type";
    begin
        UnitCostCalculationTypeEnum := "Unit Cost Calculation Type".FromInteger(UnitCostCalculation);
        CalcRoutingCostPerUnit(Type, No, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculationTypeEnum);
        UnitCostCalculation := UnitCostCalculationTypeEnum.AsInteger();
    end;
#endif

    procedure CalcRoutingCostPerUnit(Type: Enum "Capacity Type"; No: Code[20]; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Enum "Unit Cost Calculation Type")
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        case Type of
            Type::"Work Center":
                WorkCenter.Get(No);
            Type::"Machine Center":
                MachineCenter.Get(No);
        end;
        CalcRoutingCostPerUnit(Type, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculation, WorkCenter, MachineCenter);
    end;

#if not CLEAN23
    [Obsolete('Replaced by procedure CalcRoutingCostPerUnit()', '23.0')]
    procedure RoutingCostPerUnit(Type: Enum "Capacity Type"; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Option Time,Unit; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center")
    var
        UnitCostCalculationTypeEnum: Enum "Unit Cost Calculation Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRoutingCostPerUnit(Type, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculation, WorkCenter, MachineCenter, IsHandled);
        if IsHandled then
            exit;

        UnitCostCalculationTypeEnum := "Unit Cost Calculation Type".FromInteger(UnitCostCalculation);
        CalcRoutingCostPerUnit(Type, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculationTypeEnum, WorkCenter, MachineCenter);
        UnitCostCalculation := UnitCostCalculationTypeEnum.AsInteger();
    end;
#endif

    procedure CalcRoutingCostPerUnit(Type: Enum "Capacity Type"; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Enum "Unit Cost Calculation Type"; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center")
    var
#if not CLEAN23
        UnitCostCalculationOption: Option;
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcRoutingCostPerUnit(Type, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculation, WorkCenter, MachineCenter, IsHandled);
        if IsHandled then
            exit;

        UnitCostCalculation := UnitCostCalculation::Time;
        case Type of
            Type::"Work Center":
                begin
                    UnitCostCalculation := WorkCenter."Unit Cost Calculation";
                    IndirCostPct := WorkCenter."Indirect Cost %";
                    OvhdRate := WorkCenter."Overhead Rate";
                    if WorkCenter."Specific Unit Cost" then
                        DirUnitCost := CalcDirUnitCost(UnitCost, OvhdRate, IndirCostPct)
                    else begin
                        DirUnitCost := WorkCenter."Direct Unit Cost";
                        UnitCost := WorkCenter."Unit Cost";
                    end;
                end;
            Type::"Machine Center":
                begin
                    MachineCenter.TestField("Work Center No.");
                    DirUnitCost := MachineCenter."Direct Unit Cost";
                    OvhdRate := MachineCenter."Overhead Rate";
                    IndirCostPct := MachineCenter."Indirect Cost %";
                    UnitCost := MachineCenter."Unit Cost";
                end;
        end;
#if not CLEAN23
        UnitCostCalculationOption := UnitCostCalculation.AsInteger();
        OnAfterRoutingCostPerUnit(Type, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculationOption, WorkCenter, MachineCenter);
        UnitCostCalculation := "Unit Cost Calculation Type".FromInteger(UnitCostCalculationOption);
#endif
        OnAfterCalcRoutingCostPerUnit(Type, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculation, WorkCenter, MachineCenter);
    end;

    procedure CalcShareOfTotalCapCost(ProdOrderLine: Record "Prod. Order Line"; var ShareOfTotalCapCost: Decimal)
    var
        Qty: Decimal;
    begin
        ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Routing No.", "Routing Reference No.");
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ShareOfTotalCapCost := 0;
        Qty := ProdOrderLine.Quantity;
        ProdOrderLine.CalcSums(Quantity);
        if ProdOrderLine.Quantity <> 0 then
            ShareOfTotalCapCost := Qty / ProdOrderLine.Quantity;

        OnAfterCalcShareOfTotalCapCost(ProdOrderLine, ShareOfTotalCapCost);
    end;

    procedure CalcProdOrderLineStdCost(ProdOrderLine: Record "Prod. Order Line"; CurrencyFactor: Decimal; RndgPrec: Decimal; var StdMatCost: Decimal; var StdCapDirCost: Decimal; var StdSubDirCost: Decimal; var StdCapOvhdCost: Decimal; var StdMfgOvhdCost: Decimal)
    var
        Item: Record Item;
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        QtyBase: Decimal;
        IsHandled: Boolean;
    begin
        if InvtAdjmtEntryOrder.Get(InvtAdjmtEntryOrder."Order Type"::Production, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.") and
           InvtAdjmtEntryOrder."Completely Invoiced"
        then begin
            Item."Single-Level Material Cost" := InvtAdjmtEntryOrder."Single-Level Material Cost";
            Item."Single-Level Capacity Cost" := InvtAdjmtEntryOrder."Single-Level Capacity Cost";
            Item."Single-Level Subcontrd. Cost" := InvtAdjmtEntryOrder."Single-Level Subcontrd. Cost";
            Item."Single-Level Cap. Ovhd Cost" := InvtAdjmtEntryOrder."Single-Level Cap. Ovhd Cost";
            Item."Single-Level Mfg. Ovhd Cost" := InvtAdjmtEntryOrder."Single-Level Mfg. Ovhd Cost";
            OnCalcProdOrderLineStdCostOnAfterCalcSingleLevelCost(Item, InvtAdjmtEntryOrder);
            QtyBase := ProdOrderLine."Finished Qty. (Base)";
        end else begin
            Item.Get(ProdOrderLine."Item No.");
            QtyBase := ProdOrderLine."Quantity (Base)";
        end;

        IsHandled := false;
        OnBeforeCalcProdOrderLineStdCost(
          ProdOrderLine, QtyBase, CurrencyFactor, RndgPrec,
          StdMatCost, StdCapDirCost, StdSubDirCost, StdCapOvhdCost, StdMfgOvhdCost, IsHandled);
        if IsHandled then
            exit;

        StdMatCost := StdMatCost +
          Round(QtyBase * Item."Single-Level Material Cost" * CurrencyFactor, RndgPrec);
        StdCapDirCost := StdCapDirCost +
          Round(QtyBase * Item."Single-Level Capacity Cost" * CurrencyFactor, RndgPrec);
        StdSubDirCost := StdSubDirCost +
          Round(QtyBase * Item."Single-Level Subcontrd. Cost" * CurrencyFactor, RndgPrec);
        StdCapOvhdCost := StdCapOvhdCost +
          Round(QtyBase * Item."Single-Level Cap. Ovhd Cost" * CurrencyFactor, RndgPrec);
        StdMfgOvhdCost := StdMfgOvhdCost +
          Round(QtyBase * Item."Single-Level Mfg. Ovhd Cost" * CurrencyFactor, RndgPrec);
    end;

    procedure CalcProdOrderLineExpCost(ProdOrderLine: Record "Prod. Order Line"; ShareOfTotalCapCost: Decimal; var ExpMatCost: Decimal; var ExpCapDirCost: Decimal; var ExpSubDirCost: Decimal; var ExpCapOvhdCost: Decimal; var ExpMfgOvhdCost: Decimal)
    var
        WorkCenter: Record "Work Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ExpOperCost: Decimal;
        ExpMfgDirCost: Decimal;
        ExpCapDirCostRtng: Decimal;
        ExpSubDirCostRtng: Decimal;
        ExpCapOvhdCostRtng: Decimal;
        ExpOvhdCost: Decimal;
    begin
        ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.");
        ProdOrderComp.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        OnCalcProdOrderLineExpCostOnAfterProdOrderCompSetFilters(ProdOrderComp, ProdOrderLine);
        if ProdOrderComp.Find('-') then
            repeat
                ExpMatCost := ExpMatCost + ProdOrderComp."Cost Amount";
            until ProdOrderComp.Next() = 0;

        ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        OnCalcProdOrderLineExpCostOnAfterProdOrderRtngLineSetFilters(ProdOrderRtngLine, ProdOrderLine);
        if ProdOrderRtngLine.Find('-') then
            repeat
                ExpOperCost :=
                  ProdOrderRtngLine."Expected Operation Cost Amt." -
                  ProdOrderRtngLine."Expected Capacity Ovhd. Cost";
                OnCalcProdOrderLineExpCostOnExpOperCostCalculated(ExpOperCost, ProdOrderRtngLine);
                if ProdOrderRtngLine.Type = ProdOrderRtngLine.Type::"Work Center" then begin
                    if not WorkCenter.Get(ProdOrderRtngLine."No.") then
                        Clear(WorkCenter);
                end else
                    Clear(WorkCenter);

                if WorkCenter."Subcontractor No." <> '' then
                    ExpSubDirCostRtng := ExpSubDirCostRtng + ExpOperCost
                else
                    ExpCapDirCostRtng := ExpCapDirCostRtng + ExpOperCost;
                ExpCapOvhdCostRtng := ExpCapOvhdCostRtng + ProdOrderRtngLine."Expected Capacity Ovhd. Cost";
            until ProdOrderRtngLine.Next() = 0;

        ExpCapDirCost := ExpCapDirCost + Round(ExpCapDirCostRtng * ShareOfTotalCapCost);
        ExpSubDirCost := ExpSubDirCost + Round(ExpSubDirCostRtng * ShareOfTotalCapCost);
        ExpCapOvhdCost := ExpCapOvhdCost + Round(ExpCapOvhdCostRtng * ShareOfTotalCapCost);
        ExpMfgDirCost := ExpMatCost + ExpCapDirCost + ExpSubDirCost + ExpCapOvhdCost;
        ExpOvhdCost := ExpOvhdCost + ProdOrderLine."Overhead Rate" * ProdOrderLine."Quantity (Base)";
        ExpMfgOvhdCost := ExpOvhdCost +
          Round(CalcOvhdCost(ExpMfgDirCost, ProdOrderLine."Indirect Cost %", 0, 0));

        OnAfterCalcProdOrderLineExpCost(ProdOrderLine, ShareOfTotalCapCost, ExpMatCost, ExpCapDirCost, ExpSubDirCost, ExpCapOvhdCost, ExpMfgOvhdCost);
    end;

    procedure CalcProdOrderLineActCost(ProdOrderLine: Record "Prod. Order Line"; var ActMatCost: Decimal; var ActCapDirCost: Decimal; var ActSubDirCost: Decimal; var ActCapOvhdCost: Decimal; var ActMfgOvhdCost: Decimal; var ActMatCostCostACY: Decimal; var ActCapDirCostACY: Decimal; var ActSubDirCostACY: Decimal; var ActCapOvhdCostACY: Decimal; var ActMfgOvhdCostACY: Decimal)
    var
        TempSourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)" temporary;
        CalcInvtAdjmtOrder: Codeunit "Calc. Inventory Adjmt. - Order";
        OutputQty: Decimal;
    begin
        if ProdOrderLine.IsStatusLessThanReleased() then begin
            ActMatCost := 0;
            ActCapDirCost := 0;
            ActSubDirCost := 0;
            ActCapOvhdCost := 0;
            ActMfgOvhdCost := 0;
            ActMatCostCostACY := 0;
            ActCapDirCostACY := 0;
            ActCapOvhdCostACY := 0;
            ActSubDirCostACY := 0;
            ActMfgOvhdCostACY := 0;
            exit;
        end;

        OnCalcProdOrderLineActCostOnBeforeSetProdOrderLine(ProdOrderLine, ActMatCost, ActCapDirCost, ActSubDirCost, ActCapOvhdCost, ActMfgOvhdCost, ActMatCostCostACY, ActCapDirCostACY, ActSubDirCostACY, ActCapOvhdCostACY, ActMfgOvhdCostACY);

        TempSourceInvtAdjmtEntryOrder.SetProdOrderLine(ProdOrderLine);
        OutputQty := CalcInvtAdjmtOrder.CalcOutputQty(TempSourceInvtAdjmtEntryOrder, false);
        CalcInvtAdjmtOrder.CalcActualUsageCosts(TempSourceInvtAdjmtEntryOrder, OutputQty, TempSourceInvtAdjmtEntryOrder);

        ActMatCost += TempSourceInvtAdjmtEntryOrder."Single-Level Material Cost";
        ActCapDirCost += TempSourceInvtAdjmtEntryOrder."Single-Level Capacity Cost";
        ActSubDirCost += TempSourceInvtAdjmtEntryOrder."Single-Level Subcontrd. Cost";
        ActCapOvhdCost += TempSourceInvtAdjmtEntryOrder."Single-Level Cap. Ovhd Cost";
        ActMfgOvhdCost += TempSourceInvtAdjmtEntryOrder."Single-Level Mfg. Ovhd Cost";
        ActMatCostCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Material Cost (ACY)";
        ActCapDirCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Capacity Cost (ACY)";
        ActCapOvhdCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Cap. Ovhd Cost(ACY)";
        ActSubDirCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Subcontrd Cost(ACY)";
        ActMfgOvhdCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Mfg. Ovhd Cost(ACY)";
    end;

    procedure CalcProdOrderExpCapNeed(ProdOrder: Record "Production Order"; DrillDown: Boolean): Decimal
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
        WorkCenter: Record "Work Center";
        NeededTime: Decimal;
        ExpectedCapNeed: Decimal;
    begin
        OnBeforeCalcProdOrderExpCapNeed(ProdOrder, ProdOrderCapNeed, ProdOrderRtngLine);

        if ProdOrder.Status <> ProdOrder.Status::Finished then begin
            ProdOrderCapNeed.SetRange(Status, ProdOrder.Status);
            ProdOrderCapNeed.SetRange("Prod. Order No.", ProdOrder."No.");
            ProdOrderCapNeed.SetFilter(Type, ProdOrder.GetFilter("Capacity Type Filter"));
            ProdOrderCapNeed.SetFilter("No.", ProdOrder.GetFilter("Capacity No. Filter"));
            ProdOrderCapNeed.SetFilter("Work Center No.", ProdOrder.GetFilter("Work Center Filter"));
            ProdOrderCapNeed.SetFilter(Date, ProdOrder.GetFilter("Date Filter"));
            ProdOrderCapNeed.SetRange("Requested Only", false);
            OnCalcProdOrderExpCapNeedOnAfterProdOrderCapNeedSetFilters(ProdOrderCapNeed, ProdOrder);
            if ProdOrderCapNeed.FindSet() then begin
                repeat
                    if ProdOrderCapNeed.Type = ProdOrderCapNeed.Type::"Work Center" then begin
                        if not WorkCenter.Get(ProdOrderCapNeed."No.") then
                            Clear(WorkCenter);
                    end else
                        Clear(WorkCenter);
                    if WorkCenter."Subcontractor No." = '' then begin
                        NeededTime += ProdOrderCapNeed."Needed Time (ms)";
                        ProdOrderCapNeed.Mark(true);
                    end;
                until ProdOrderCapNeed.Next() = 0;
                ProdOrderCapNeed.MarkedOnly(true);
            end;
            if DrillDown then
                PAGE.Run(0, ProdOrderCapNeed, ProdOrderCapNeed."Needed Time")
            else
                exit(NeededTime);
        end else begin
            ProdOrderRtngLine.SetRange(Status, ProdOrder.Status);
            ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrder."No.");
            if ProdOrderRtngLine.FindSet() then begin
                repeat
                    if ProdOrderRtngLine.Type = ProdOrderRtngLine.Type::"Work Center" then begin
                        if not WorkCenter.Get(ProdOrderRtngLine."No.") then
                            Clear(WorkCenter);
                    end else
                        Clear(WorkCenter);
                    if WorkCenter."Subcontractor No." = '' then begin
                        ExpectedCapNeed += ProdOrderRtngLine."Expected Capacity Need";
                        OnCalcProdOrderExpCapNeedOnBeforeMarkNotFinishedProdOrderRtngLine(ProdOrderRtngLine, WorkCenter, ExpectedCapNeed);
                        ProdOrderRtngLine.Mark(true);
                    end;
                until ProdOrderRtngLine.Next() = 0;
                ProdOrderRtngLine.MarkedOnly(true);
            end;
            if DrillDown then
                PAGE.Run(0, ProdOrderRtngLine, ProdOrderRtngLine."Expected Capacity Need")
            else
                exit(ExpectedCapNeed);
        end;
    end;

    procedure CalcProdOrderActTimeUsed(ProdOrder: Record "Production Order"; DrillDown: Boolean): Decimal
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
        WorkCenter: Record "Work Center";
        CalendarMgt: Codeunit "Shop Calendar Management";
        Qty: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeCalcProdOrderActTimeUsed(ProdOrder, CapLedgEntry);

        if ProdOrder.IsStatusLessThanReleased() then
            exit(0);

        CapLedgEntry.SetCurrentKey("Order Type", "Order No.");
        CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
        CapLedgEntry.SetRange("Order No.", ProdOrder."No.");
        OnCalcProdOrderActTimeUsedOnAfterCapacityLedgerEntrySetFilters(CapLedgEntry, ProdOrder);
        if CapLedgEntry.FindSet() then begin
            repeat
                ClearWorkCenter(CapLedgEntry, WorkCenter);
                if WorkCenter."Subcontractor No." = '' then begin
                    if CapLedgEntry."Qty. per Cap. Unit of Measure" = 0 then
                        GetCapacityUoM(CapLedgEntry);

                    IsHandled := false;
                    OnCalcProdOrderActTimeUsedOnBeforeCalcQty(CapLedgEntry, Qty, IsHandled);
                    if not IsHandled then
                        Qty +=
                            CapLedgEntry.Quantity /
                            CapLedgEntry."Qty. per Cap. Unit of Measure" *
                            CalendarMgt.TimeFactor(CapLedgEntry."Cap. Unit of Measure Code");
                    CapLedgEntry.Mark(true);
                end;
            until CapLedgEntry.Next() = 0;
            CapLedgEntry.MarkedOnly(true);
        end;

        if DrillDown then
            PAGE.Run(0, CapLedgEntry, CapLedgEntry.Quantity)
        else
            exit(Qty);
    end;

    local procedure GetCapacityUoM(var CapacityLedgerEntry: Record "Capacity Ledger Entry")
    var
        WorkCenter: Record "Work Center";
    begin
        CapacityLedgerEntry."Qty. per Cap. Unit of Measure" := 1;
        if WorkCenter.Get(CapacityLedgerEntry."Work Center No.") then
            CapacityLedgerEntry."Cap. Unit of Measure Code" := WorkCenter."Unit of Measure Code";
    end;

    local procedure ClearWorkCenter(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; var WorkCenter: Record "Work Center")
    begin
        if CapacityLedgerEntry.Type = CapacityLedgerEntry.Type::"Work Center" then begin
            if not WorkCenter.Get(CapacityLedgerEntry."No.") then
                Clear(WorkCenter);
        end else
            Clear(WorkCenter);
        OnAfterClearWorkCenter(CapacityLedgerEntry, WorkCenter);
    end;

    procedure CalcOutputQtyBaseOnPurchOrder(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"): Decimal
    var
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        OutstandingBaseQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OutstandingBaseQty := 0;
        OnBeforeCalcOutputQtyBaseOnPurchOrder(ProdOrderLine, ProdOrderRtngLine, OutstandingBaseQty, IsHandled);
        if IsHandled then
            exit;

        PurchLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        PurchLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        PurchLine.SetRange("Routing No.", ProdOrderRtngLine."Routing No.");
        PurchLine.SetRange("Operation No.", ProdOrderRtngLine."Operation No.");
        if PurchLine.Find('-') then
            repeat
                if Item."No." <> PurchLine."No." then
                    Item.Get(PurchLine."No.");
                OutstandingBaseQty :=
                  OutstandingBaseQty +
                  UOMMgt.GetQtyPerUnitOfMeasure(Item, PurchLine."Unit of Measure Code") * PurchLine."Outstanding Quantity";
            until PurchLine.Next() = 0;
        exit(OutstandingBaseQty);
    end;

    procedure CalcActOutputQtyBase(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"): Decimal
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        if ProdOrderLine.IsStatusLessThanReleased() then
            exit(0);

        CapLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Routing No.", "Routing Reference No.", "Operation No.");
        CapLedgEntry.SetFilterByProdOrderRoutingLine(
          ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
          ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
        CapLedgEntry.SetRange("Operation No.", ProdOrderRtngLine."Operation No.");
        OnCalcActOutputQtyBaseOnAfterSetFilters(CapLedgEntry, ProdOrderLine, ProdOrderRtngLine);
        CapLedgEntry.CalcSums("Output Quantity");
        exit(CapLedgEntry."Output Quantity");
    end;

    procedure CalcActualOutputQtyWithNoCapacity(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"): Decimal
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        if ProdOrderLine.Status.AsInteger() < ProdOrderLine.Status::Released.AsInteger() then
            exit(0);

        CapLedgEntry.SetCurrentKey(
          "Order Type", "Order No.", "Order Line No.", "Routing No.", "Routing Reference No.", "Operation No.", "Last Output Line");
        CapLedgEntry.SetFilterByProdOrderRoutingLine(
          ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
          ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
        CapLedgEntry.SetRange("Last Output Line", true);
        CapLedgEntry.SetRange(Quantity, 0);
        CapLedgEntry.CalcSums("Output Quantity", "Scrap Quantity");
        exit(CapLedgEntry."Output Quantity" + CapLedgEntry."Scrap Quantity");
    end;

    procedure CalcActQtyBase(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"): Decimal
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        if ProdOrderLine.IsStatusLessThanReleased() then
            exit(0);

        CapLedgEntry.SetCurrentKey(
          CapLedgEntry."Order Type", CapLedgEntry."Order No.", CapLedgEntry."Order Line No.", CapLedgEntry."Routing No.", CapLedgEntry."Routing Reference No.", CapLedgEntry."Operation No.", CapLedgEntry."Last Output Line");
        CapLedgEntry.SetFilterByProdOrderRoutingLine(
          ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
          ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
        CapLedgEntry.SetRange("Last Output Line", true);
        CapLedgEntry.CalcSums(CapLedgEntry.Quantity);
        exit(CapLedgEntry.Quantity / ProdOrderLine."Qty. per Unit of Measure");
    end;

    procedure CalcActOperOutputAndScrap(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line") OutputQtyBase: Decimal
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        if ProdOrderLine.IsStatusLessThanReleased() then
            exit(0);

        CapLedgEntry.SetCurrentKey(
          "Order Type", "Order No.", "Order Line No.", "Routing No.", "Routing Reference No.", "Operation No.", "Last Output Line");
        CapLedgEntry.SetFilterByProdOrderRoutingLine(
          ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
          ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
        CapLedgEntry.SetRange("Last Output Line", true);
        OnCalcActOperOutputAndScrapOnAfterFilterCapLedgEntry(CapLedgEntry);
        CapLedgEntry.CalcSums("Output Quantity", "Scrap Quantity");
        OutputQtyBase := CapLedgEntry."Output Quantity" + CapLedgEntry."Scrap Quantity";

        exit(OutputQtyBase);
    end;

    procedure CalcActNeededQtyBase(ProdOrderLine: Record "Prod. Order Line"; ProdOrderComp: Record "Prod. Order Component"; OutputQtyBase: Decimal) Result: Decimal
    var
        CompQtyBasePerMfgQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcActNeededQtyBase(OutputQtyBase, ProdOrderComp, ProdOrderLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ProdOrderComp."Flushing Method" = ProdOrderComp."Flushing Method"::"Pick + Backward" then
            CompQtyBasePerMfgQtyBase := (ProdOrderComp."Quantity per" * ProdOrderComp."Qty. per Unit of Measure") / ProdOrderLine."Qty. per Unit of Measure"
        else
            CompQtyBasePerMfgQtyBase := (ProdOrderComp."Quantity" * ProdOrderComp."Qty. per Unit of Measure") / ProdOrderLine."Qty. per Unit of Measure";

        if (ProdOrderComp."Calculation Formula" = ProdOrderComp."Calculation Formula"::"Fixed Quantity") and (OutputQtyBase <> 0) then
            exit(CalcQtyAdjdForBOMScrap(CompQtyBasePerMfgQtyBase, ProdOrderComp."Scrap %"))
        else
            exit(CalcQtyAdjdForBOMScrap(OutputQtyBase * CompQtyBasePerMfgQtyBase, ProdOrderComp."Scrap %"));
    end;

    procedure CalcActTimeAndQtyBase(ProdOrderLine: Record "Prod. Order Line"; OperationNo: Code[10]; var ActRunTime: Decimal; var ActSetupTime: Decimal; var ActOutputQty: Decimal; var ActScrapQty: Decimal)
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        CapLedgEntry.SetCurrentKey(
            "Order Type", "Order No.", "Order Line No.", "Routing No.", "Routing Reference No.", "Operation No.", "Last Output Line");
        CapLedgEntry.SetFilterByProdOrderRoutingLine(
          ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
          ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.");
        CapLedgEntry.SetRange("Operation No.", OperationNo);
        OnCalcActTimeAndQtyBaseOnAfterFilterCapLedgEntry(CapLedgEntry);
        if CapLedgEntry.Find('-') then
            repeat
                ActSetupTime += CapLedgEntry."Setup Time";
                ActRunTime += CapLedgEntry."Run Time";
                // Base Units
                ActOutputQty += CapLedgEntry."Output Quantity";
                ActScrapQty += CapLedgEntry."Scrap Quantity";
            until CapLedgEntry.Next() = 0;
    end;

    procedure CalcCompItemQtyBase(ProdBOMComponent: Record "Production BOM Line"; CalculationDate: Date; MfgItemQtyBase: Decimal; RtngNo: Code[20]; AdjdForRtngScrap: Boolean): Decimal
    var
        RtngLine: Record "Routing Line";
        IsHandled: Boolean;
    begin
        OnBeforeCalcCompItemQtyBase(ProdBOMComponent, CalculationDate, MfgItemQtyBase, RtngNo, AdjdForRtngScrap, IsHandled);
        if IsHandled then
            exit(MfgItemQtyBase);

        if ProdBOMComponent."Calculation Formula" = ProdBOMComponent."Calculation Formula"::"Fixed Quantity" then
            MfgItemQtyBase := ProdBOMComponent.Quantity * ProdBOMComponent.GetQtyPerUnitOfMeasure()
        else begin
            MfgItemQtyBase := CalcQtyAdjdForBOMScrap(MfgItemQtyBase, ProdBOMComponent."Scrap %");
            if AdjdForRtngScrap and FindRountingLine(RtngLine, ProdBOMComponent, CalculationDate, RtngNo) then
                MfgItemQtyBase := CalcQtyAdjdForRoutingScrap(MfgItemQtyBase, RtngLine."Scrap Factor % (Accumulated)", RtngLine."Fixed Scrap Qty. (Accum.)");
            MfgItemQtyBase := MfgItemQtyBase * ProdBOMComponent.Quantity * ProdBOMComponent.GetQtyPerUnitOfMeasure();
        end;
        exit(MfgItemQtyBase);
    end;

#if not CLEAN23
    [Obsolete('Replaced by procedure CalculateCostTime()', '23.0')]
    procedure CalcCostTime(MfgItemQtyBase: Decimal; SetupTime: Decimal; SetupTimeUOMCode: Code[10]; RunTime: Decimal; RunTimeUOMCode: Code[10]; RtngLotSize: Decimal; ScrapFactorPctAccum: Decimal; FixedScrapQtyAccum: Decimal; WorkCenterNo: Code[20]; UnitCostCalculation: Option Time,Unit; CostInclSetup: Boolean; ConcurrentCapacities: Decimal) CostTime: Decimal
    begin
        exit(CalculateCostTime(MfgItemQtyBase, SetupTime, SetupTimeUOMCode, RunTime, RunTimeUOMCode, RtngLotSize, ScrapFactorPctAccum, FixedScrapQtyAccum, WorkCenterNo, "Unit Cost Calculation Type".FromInteger(UnitCostCalculation), CostInclSetup, ConcurrentCapacities));
    end;
#endif

    procedure CalculateCostTime(MfgItemQtyBase: Decimal; SetupTime: Decimal; SetupTimeUOMCode: Code[10]; RunTime: Decimal; RunTimeUOMCode: Code[10]; RtngLotSize: Decimal; ScrapFactorPctAccum: Decimal; FixedScrapQtyAccum: Decimal; WorkCenterNo: Code[20]; UnitCostCalculation: Enum "Unit Cost Calculation Type"; CostInclSetup: Boolean; ConcurrentCapacities: Decimal) CostTime: Decimal
    var
        ShopCalendarManagement: Codeunit "Shop Calendar Management";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        RunTimePer: Decimal;
    begin
        if ConcurrentCapacities = 0 then
            ConcurrentCapacities := 1;

        case UnitCostCalculation of
            UnitCostCalculation::Time:
                begin
                    if RtngLotSize = 0 then
                        RtngLotSize := 1;
                    RunTimePer := RunTime / RtngLotSize;
                    CostTime :=
                      CalcQtyAdjdForRoutingScrap(
                        Round(
                          RunTimePer * MfgItemQtyBase * ShopCalendarManagement.QtyperTimeUnitofMeasure(WorkCenterNo, RunTimeUOMCode),
                          UnitOfMeasureManagement.TimeRndPrecision()),
                        ScrapFactorPctAccum,
                        Round(
                          RunTimePer * FixedScrapQtyAccum * ShopCalendarManagement.QtyperTimeUnitofMeasure(WorkCenterNo, RunTimeUOMCode),
                          UnitOfMeasureManagement.TimeRndPrecision()));
                    if CostInclSetup then
                        CostTime :=
                          CostTime +
                          Round(
                            ConcurrentCapacities *
                            SetupTime * ShopCalendarManagement.QtyperTimeUnitofMeasure(WorkCenterNo, SetupTimeUOMCode),
                            UnitOfMeasureManagement.TimeRndPrecision());
                end;
            UnitCostCalculation::Units:
                CostTime := CalcQtyAdjdForRoutingScrap(MfgItemQtyBase, ScrapFactorPctAccum, FixedScrapQtyAccum);
        end;
    end;

    procedure CalcQtyAdjdForBOMScrap(Qty: Decimal; ScrapPct: Decimal) QtyAdjdForBOMScrap: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyAdjdForBOMScrap(Qty, ScrapPct, QtyAdjdForBomScrap, IsHandled);
        if not IsHandled then
            exit(Qty * (1 + ScrapPct / 100));
    end;

    procedure CalcQtyAdjdForRoutingScrap(Qty: Decimal; ScrapFactorPctAccum: Decimal; FixedScrapQtyAccum: Decimal) QtyAdjdForRoutingScrap: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyAdjdForRoutingScrap(Qty, ScrapFactorPctAccum, FixedScrapQtyAccum, QtyAdjdForRoutingScrap, IsHandled);
        if not IsHandled then
            exit(Qty * (1 + ScrapFactorPctAccum) + FixedScrapQtyAccum);
    end;

    procedure CalcDirCost(Cost: Decimal; OvhdCost: Decimal; VarPurchCost: Decimal): Decimal
    begin
        exit(Cost - OvhdCost - VarPurchCost);
    end;

    procedure CalcDirUnitCost(UnitCost: Decimal; OvhdRate: Decimal; IndirCostPct: Decimal): Decimal
    begin
        exit((UnitCost - OvhdRate) / (1 + IndirCostPct / 100));
    end;

    procedure CalcOvhdCost(DirCost: Decimal; IndirCostPct: Decimal; OvhdRate: Decimal; QtyBase: Decimal): Decimal
    begin
        exit(DirCost * IndirCostPct / 100 + OvhdRate * QtyBase);
    end;

    procedure CalcUnitCost(DirCost: Decimal; IndirCostPct: Decimal; OvhdRate: Decimal; RndgPrec: Decimal): Decimal
    begin
        exit(Round(DirCost * (1 + IndirCostPct / 100) + OvhdRate, RndgPrec));
    end;

    procedure FindRountingLine(var RoutingLine: Record "Routing Line"; ProdBOMLine: Record "Production BOM Line"; CalculationDate: Date; RoutingNo: Code[20]) RecFound: Boolean
    var
        VersionMgt: Codeunit VersionManagement;
    begin
        if RoutingNo = '' then
            exit(false);

        RecFound := false;
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange("Version Code", VersionMgt.GetRtngVersion(RoutingNo, CalculationDate, true));
        OnFindRountingLineOnAfterRoutingLineSetFilters(RoutingLine, ProdBOMLine, CalculationDate, RoutingNo);
        if not RoutingLine.IsEmpty() then begin
            if ProdBOMLine."Routing Link Code" <> '' then
                RoutingLine.SetRange("Routing Link Code", ProdBOMLine."Routing Link Code");
            RecFound := RoutingLine.FindFirst();
            if not RecFound then begin
                RoutingLine.SetRange("Routing Link Code");
                RecFound := RoutingLine.FindFirst();
            end;
        end;

        exit(RecFound);
    end;

    procedure GetRndgSetup(var GLSetup: Record "General Ledger Setup"; var Currency: Record Currency; var RndgSetupRead: Boolean)
    begin
        if RndgSetupRead then
            exit;
        GLSetup.Get();
        GLSetup.TestField("Amount Rounding Precision");
        GLSetup.TestField("Unit-Amount Rounding Precision");
        if GLSetup."Additional Reporting Currency" <> '' then begin
            Currency.Get(GLSetup."Additional Reporting Currency");
            Currency.TestField("Amount Rounding Precision");
            Currency.TestField("Unit-Amount Rounding Precision");
        end;
        RndgSetupRead := true;
    end;

    procedure TransferCost(var Cost: Decimal; var UnitCost: Decimal; SrcCost: Decimal; Qty: Decimal; UnitAmtRndgPrec: Decimal)
    begin
        Cost := SrcCost;
        if Qty <> 0 then
            UnitCost := Round(Cost / Qty, UnitAmtRndgPrec);
    end;

    procedure SplitItemLedgerEntriesExist(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; QtyBase: Decimal; ItemLedgEntryNo: Integer): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
    begin
        if ItemLedgEntryNo = 0 then
            exit(false);
        TempItemLedgEntry.Reset();
        TempItemLedgEntry.DeleteAll();
        if ItemLedgEntry.Get(ItemLedgEntryNo) and (ItemLedgEntry.Quantity <> QtyBase) then
            if ItemLedgEntry2.Get(ItemLedgEntry."Entry No." - 1) and
               IsSameDocLineItemLedgEntry(ItemLedgEntry, ItemLedgEntry2, QtyBase)
            then begin
                TempItemLedgEntry := ItemLedgEntry2;
                TempItemLedgEntry.Insert();
                TempItemLedgEntry := ItemLedgEntry;
                TempItemLedgEntry.Insert();
                exit(true);
            end;

        exit(false);
    end;

    local procedure IsSameDocLineItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry2: Record "Item Ledger Entry"; QtyBase: Decimal): Boolean
    begin
        exit(
              (ItemLedgEntry2."Document Type" = ItemLedgEntry."Document Type") and
              (ItemLedgEntry2."Document No." = ItemLedgEntry."Document No.") and
              (ItemLedgEntry2."Document Line No." = ItemLedgEntry."Document Line No.") and
              (ItemLedgEntry2."Posting Date" = ItemLedgEntry."Posting Date") and
              (ItemLedgEntry2."Source Type" = ItemLedgEntry."Source Type") and
              (ItemLedgEntry2."Source No." = ItemLedgEntry."Source No.") and
              (ItemLedgEntry2."Entry Type" = ItemLedgEntry."Entry Type") and
              (ItemLedgEntry2."Item No." = ItemLedgEntry."Item No.") and
              (ItemLedgEntry2."Location Code" = ItemLedgEntry."Location Code") and
              (ItemLedgEntry2."Variant Code" = ItemLedgEntry."Variant Code") and
              (QtyBase = ItemLedgEntry2.Quantity + ItemLedgEntry.Quantity) and
              (ItemLedgEntry2.Quantity = ItemLedgEntry2."Invoiced Quantity"));
    end;

    procedure CalcSalesLineCostLCY(SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing) TotalAdjCostLCY: Decimal
    var
        PostedQtyBase: Decimal;
        RemQtyToCalcBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcSalesLineCostLCY(SalesLine, QtyType, IsHandled, TotalAdjCostLCY);
        if IsHandled then
            exit;
        case SalesLine."Document Type" of
            SalesLine."Document Type"::Order, SalesLine."Document Type"::Invoice:
                if ((SalesLine."Quantity Shipped" <> 0) or (SalesLine."Shipment No." <> '')) and
                   ((QtyType = QtyType::General) or (SalesLine."Qty. to Invoice" > SalesLine."Qty. to Ship"))
                then
                    CalcSalesLineShptAdjCostLCY(SalesLine, QtyType, TotalAdjCostLCY, PostedQtyBase, RemQtyToCalcBase);
            SalesLine."Document Type"::"Return Order", SalesLine."Document Type"::"Credit Memo":
                if ((SalesLine."Return Qty. Received" <> 0) or (SalesLine."Return Receipt No." <> '')) and
                   ((QtyType = QtyType::General) or (SalesLine."Qty. to Invoice" > SalesLine."Return Qty. to Receive"))
                then
                    CalcSalesLineRcptAdjCostLCY(SalesLine, QtyType, TotalAdjCostLCY, PostedQtyBase, RemQtyToCalcBase);
        end;
    end;

    procedure CalcSalesLineShptAdjCostLCY(SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing; var TotalAdjCostLCY: Decimal; var PostedQtyBase: Decimal; var RemQtyToCalcBase: Decimal)
    var
        SalesShptLine: Record "Sales Shipment Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        QtyShippedNotInvcdBase: Decimal;
        AdjCostLCY: Decimal;
    begin
        if SalesLine."Shipment No." <> '' then begin
            SalesShptLine.SetRange("Document No.", SalesLine."Shipment No.");
            SalesShptLine.SetRange("Line No.", SalesLine."Shipment Line No.");
        end else begin
            SalesShptLine.SetCurrentKey("Order No.", "Order Line No.");
            SalesShptLine.SetRange("Order No.", SalesLine."Document No.");
            SalesShptLine.SetRange("Order Line No.", SalesLine."Line No.");
        end;
        SalesShptLine.SetRange(Correction, false);
        OnCalcSalesLineShptAdjCostLCYBeforeSalesShptLineFind(SalesShptLine, SalesLine);
        if QtyType = QtyType::Invoicing then begin
            SalesShptLine.SetFilter(SalesShptLine."Qty. Shipped Not Invoiced", '<>0');
            RemQtyToCalcBase := SalesLine."Qty. to Invoice (Base)" - SalesLine."Qty. to Ship (Base)";
        end else
            RemQtyToCalcBase := SalesLine."Quantity (Base)";

        if SalesShptLine.FindSet() then
            repeat
                if SalesShptLine."Qty. per Unit of Measure" = 0 then
                    QtyShippedNotInvcdBase := SalesShptLine."Qty. Shipped Not Invoiced"
                else
                    QtyShippedNotInvcdBase :=
                      Round(SalesShptLine."Qty. Shipped Not Invoiced" * SalesShptLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());

                AdjCostLCY := CalcSalesShptLineCostLCY(SalesShptLine, QtyType);

                case true of
                    QtyType = QtyType::Invoicing:
                        if RemQtyToCalcBase > QtyShippedNotInvcdBase then begin
                            TotalAdjCostLCY := TotalAdjCostLCY + AdjCostLCY;
                            RemQtyToCalcBase := RemQtyToCalcBase - QtyShippedNotInvcdBase;
                            PostedQtyBase := PostedQtyBase + QtyShippedNotInvcdBase;
                        end else begin
                            PostedQtyBase := PostedQtyBase + RemQtyToCalcBase;
                            TotalAdjCostLCY :=
                              TotalAdjCostLCY + AdjCostLCY / QtyShippedNotInvcdBase * RemQtyToCalcBase;
                            RemQtyToCalcBase := 0;
                        end;
                    SalesLine."Shipment No." <> '':
                        begin
                            PostedQtyBase := PostedQtyBase + QtyShippedNotInvcdBase;
                            TotalAdjCostLCY :=
                              TotalAdjCostLCY + AdjCostLCY / SalesShptLine."Quantity (Base)" * RemQtyToCalcBase;
                            RemQtyToCalcBase := 0;
                        end;
                    else begin
                        PostedQtyBase := PostedQtyBase + SalesShptLine."Quantity (Base)";
                        TotalAdjCostLCY := TotalAdjCostLCY + AdjCostLCY;
                    end;
                end;
            until (SalesShptLine.Next() = 0) or (RemQtyToCalcBase = 0);
    end;

    procedure CalcSalesLineRcptAdjCostLCY(SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing; var TotalAdjCostLCY: Decimal; var PostedQtyBase: Decimal; var RemQtyToCalcBase: Decimal)
    var
        ReturnRcptLine: Record "Return Receipt Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        RtrnQtyRcvdNotInvcdBase: Decimal;
        AdjCostLCY: Decimal;
    begin
        if SalesLine."Return Receipt No." <> '' then begin
            ReturnRcptLine.SetRange("Document No.", SalesLine."Return Receipt No.");
            ReturnRcptLine.SetRange("Line No.", SalesLine."Return Receipt Line No.");
        end else begin
            ReturnRcptLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
            ReturnRcptLine.SetRange("Return Order No.", SalesLine."Document No.");
            ReturnRcptLine.SetRange("Return Order Line No.", SalesLine."Line No.");
        end;
        ReturnRcptLine.SetRange(Correction, false);
        if QtyType = QtyType::Invoicing then begin
            ReturnRcptLine.SetFilter(ReturnRcptLine."Return Qty. Rcd. Not Invd.", '<>0');
            RemQtyToCalcBase :=
              SalesLine."Qty. to Invoice (Base)" - SalesLine."Return Qty. to Receive (Base)";
        end else
            RemQtyToCalcBase := SalesLine."Quantity (Base)";

        if ReturnRcptLine.FindSet() then
            repeat
                if ReturnRcptLine."Qty. per Unit of Measure" = 0 then
                    RtrnQtyRcvdNotInvcdBase := ReturnRcptLine."Return Qty. Rcd. Not Invd."
                else
                    RtrnQtyRcvdNotInvcdBase :=
                      Round(ReturnRcptLine."Return Qty. Rcd. Not Invd." * ReturnRcptLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());

                AdjCostLCY := CalcReturnRcptLineCostLCY(ReturnRcptLine, QtyType);

                case true of
                    QtyType = QtyType::Invoicing:
                        if RemQtyToCalcBase > RtrnQtyRcvdNotInvcdBase then begin
                            TotalAdjCostLCY := TotalAdjCostLCY + AdjCostLCY;
                            RemQtyToCalcBase := RemQtyToCalcBase - RtrnQtyRcvdNotInvcdBase;
                            PostedQtyBase := PostedQtyBase + RtrnQtyRcvdNotInvcdBase;
                        end else begin
                            PostedQtyBase := PostedQtyBase + RemQtyToCalcBase;
                            TotalAdjCostLCY :=
                              TotalAdjCostLCY + AdjCostLCY / RtrnQtyRcvdNotInvcdBase * RemQtyToCalcBase;
                            RemQtyToCalcBase := 0;
                        end;
                    SalesLine."Return Receipt No." <> '':
                        begin
                            PostedQtyBase := PostedQtyBase + RtrnQtyRcvdNotInvcdBase;
                            TotalAdjCostLCY :=
                              TotalAdjCostLCY + AdjCostLCY / ReturnRcptLine."Quantity (Base)" * RemQtyToCalcBase;
                            RemQtyToCalcBase := 0;
                        end;
                    else begin
                        PostedQtyBase := PostedQtyBase + ReturnRcptLine."Quantity (Base)";
                        TotalAdjCostLCY := TotalAdjCostLCY + AdjCostLCY;
                    end;
                end;
            until (ReturnRcptLine.Next() = 0) or (RemQtyToCalcBase = 0);
    end;

    local procedure CalcSalesShptLineCostLCY(SalesShptLine: Record "Sales Shipment Line"; QtyType: Option General,Invoicing,Shipping) AdjCostLCY: Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        if (SalesShptLine.Quantity = 0) or (SalesShptLine.Type = SalesShptLine.Type::"Charge (Item)") then
            exit(0);

        if SalesShptLine.Type = SalesShptLine.Type::Item then begin
            SalesShptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
            if ItemLedgEntry.IsEmpty() then
                exit(0);
            AdjCostLCY := CalcPostedDocLineCostLCY(ItemLedgEntry, QtyType);
            if RelatedReturnReceiptExist(SalesShptLine, ReturnRcptLine) then
                repeat
                    AdjCostLCY += CalcReturnRcptLineCostLCY(ReturnRcptLine, QtyType);
                until ReturnRcptLine.Next() = 0;
        end else
            if QtyType = QtyType::Invoicing then
                AdjCostLCY := -SalesShptLine."Qty. Shipped Not Invoiced" * SalesShptLine."Unit Cost (LCY)"
            else
                AdjCostLCY := -SalesShptLine.Quantity * SalesShptLine."Unit Cost (LCY)";
    end;

    local procedure RelatedReturnReceiptExist(var SalesShptLine: Record "Sales Shipment Line"; var ReturnRcptLine: Record "Return Receipt Line"): Boolean
    begin
        if SalesShptLine."Item Shpt. Entry No." = 0 then exit;
        ReturnRcptLine.SetRange("Appl.-from Item Entry", SalesShptLine."Item Shpt. Entry No.");
        if ReturnRcptLine.FindSet() then
            exit(true);
    end;

    local procedure CalcReturnRcptLineCostLCY(ReturnRcptLine: Record "Return Receipt Line"; QtyType: Option General,Invoicing,Shipping) AdjCostLCY: Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if (ReturnRcptLine.Quantity = 0) or (ReturnRcptLine.Type = ReturnRcptLine.Type::"Charge (Item)") then
            exit(0);

        if ReturnRcptLine.Type = ReturnRcptLine.Type::Item then begin
            ReturnRcptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
            if ItemLedgEntry.IsEmpty() then
                exit(0);
            AdjCostLCY := CalcPostedDocLineCostLCY(ItemLedgEntry, QtyType);
        end else
            if QtyType = QtyType::Invoicing then
                AdjCostLCY := ReturnRcptLine."Return Qty. Rcd. Not Invd." * ReturnRcptLine."Unit Cost (LCY)"
            else
                AdjCostLCY := ReturnRcptLine.Quantity * ReturnRcptLine."Unit Cost (LCY)";
    end;

    procedure CalcPostedDocLineCostLCY(var ItemLedgEntry: Record "Item Ledger Entry"; QtyType: Option General,Invoicing,Shipping,Consuming) AdjCostLCY: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ItemLedgEntry.FindSet();
        repeat
            if (QtyType = QtyType::Invoicing) or (QtyType = QtyType::Consuming) then begin
                ItemLedgEntry.CalcFields("Cost Amount (Expected)");
                AdjCostLCY := AdjCostLCY + ItemLedgEntry."Cost Amount (Expected)";
            end else begin
                ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                ValueEntry.SetFilter("Entry Type", '<>%1', ValueEntry."Entry Type"::Revaluation);
                ValueEntry.SetRange("Item Charge No.", '');
                ValueEntry.CalcSums("Cost Amount (Expected)", "Cost Amount (Actual)");
                AdjCostLCY += ValueEntry."Cost Amount (Expected)" + ValueEntry."Cost Amount (Actual)";
            end;
        until ItemLedgEntry.Next() = 0;
    end;

    procedure CalcSalesInvLineCostLCY(SalesInvLine: Record "Sales Invoice Line") AdjCostLCY: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        if SalesInvLine.Quantity = 0 then
            exit(0);

        if SalesInvLine.Type in [SalesInvLine.Type::Item, SalesInvLine.Type::"Charge (Item)"] then begin
            SalesInvLine.FilterPstdDocLineValueEntries(ValueEntry);
            AdjCostLCY := -SumValueEntriesCostAmt(ValueEntry);
        end else
            AdjCostLCY := SalesInvLine.Quantity * SalesInvLine."Unit Cost (LCY)";
    end;

    procedure CalcSalesInvLineNonInvtblCostAmt(SalesInvoiceLine: Record "Sales Invoice Line"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", SalesInvoiceLine."Document No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        ValueEntry.SetRange("Document Line No.", SalesInvoiceLine."Line No.");
        ValueEntry.CalcSums("Cost Amount (Non-Invtbl.)");
        exit(-ValueEntry."Cost Amount (Non-Invtbl.)");
    end;

    procedure CalcSalesCrMemoLineCostLCY(SalesCrMemoLine: Record "Sales Cr.Memo Line") AdjCostLCY: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        if SalesCrMemoLine.Quantity = 0 then
            exit(0);

        if SalesCrMemoLine.Type in [SalesCrMemoLine.Type::Item, SalesCrMemoLine.Type::"Charge (Item)"] then begin
            SalesCrMemoLine.FilterPstdDocLineValueEntries(ValueEntry);
            AdjCostLCY := SumValueEntriesCostAmt(ValueEntry);
        end else
            AdjCostLCY := SalesCrMemoLine.Quantity * SalesCrMemoLine."Unit Cost (LCY)";
    end;

    procedure CalcSalesCrMemoLineNonInvtblCostAmt(SalesCrMemoLine: Record "Sales Cr.Memo Line"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", SalesCrMemoLine."Document No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Credit Memo");
        ValueEntry.SetRange("Document Line No.", SalesCrMemoLine."Line No.");
        ValueEntry.CalcSums("Cost Amount (Non-Invtbl.)");
        exit(ValueEntry."Cost Amount (Non-Invtbl.)");
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit Serv. Cost Calculation Mgt.', '25.0')]
    procedure CalcServCrMemoLineCostLCY(ServCrMemoLine: Record Microsoft.Service.History."Service Cr.Memo Line") AdjCostLCY: Decimal
    var
        ServCostCalculationMgt: Codeunit "Serv. Cost Calculation Mgt.";
    begin
        exit(ServCostCalculationMgt.CalcServCrMemoLineCostLCY(ServCrMemoLine));
    end;
#endif

    procedure CalcCustLedgAdjmtCostLCY(CustLedgEntry: Record "Cust. Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        if not (CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::Invoice, CustLedgEntry."Document Type"::"Credit Memo"]) then
            CustLedgEntry.FieldError(CustLedgEntry."Document Type");

        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", CustLedgEntry."Document No.");
        if CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice then
            ValueEntry.SetFilter(
              "Document Type",
              '%1|%2',
              ValueEntry."Document Type"::"Sales Invoice", ValueEntry."Document Type"::"Service Invoice")
        else
            ValueEntry.SetFilter(
              "Document Type",
              '%1|%2',
              ValueEntry."Document Type"::"Sales Credit Memo", ValueEntry."Document Type"::"Service Credit Memo");
        ValueEntry.SetRange(Adjustment, true);
        exit(SumValueEntriesCostAmt(ValueEntry));
    end;

    procedure CalcCustAdjmtCostLCY(var Customer: Record Customer): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Source Type", "Source No.");
        ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Customer);
        ValueEntry.SetRange("Source No.", Customer."No.");
        ValueEntry.SetFilter("Posting Date", Customer.GetFilter("Date Filter"));
        ValueEntry.SetFilter("Global Dimension 1 Code", Customer.GetFilter("Global Dimension 1 Filter"));
        ValueEntry.SetFilter("Global Dimension 2 Code", Customer.GetFilter("Global Dimension 2 Filter"));
        ValueEntry.SetRange(Adjustment, true);

        ValueEntry.CalcSums("Cost Amount (Actual)");
        exit(ValueEntry."Cost Amount (Actual)");
    end;

    procedure CalcCustLedgActualCostLCY(CustLedgEntry: Record "Cust. Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        if not (CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::Invoice, CustLedgEntry."Document Type"::"Credit Memo"]) then
            CustLedgEntry.FieldError(CustLedgEntry."Document Type");

        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", CustLedgEntry."Document No.");
        if CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice then
            ValueEntry.SetFilter(
              "Document Type",
              '%1|%2',
              ValueEntry."Document Type"::"Sales Invoice", ValueEntry."Document Type"::"Service Invoice")
        else
            ValueEntry.SetFilter(
              "Document Type",
              '%1|%2',
              ValueEntry."Document Type"::"Sales Credit Memo", ValueEntry."Document Type"::"Service Credit Memo");
        ValueEntry.SetFilter("Entry Type", '<> %1', ValueEntry."Entry Type"::Revaluation);
        exit(SumValueEntriesCostAmt(ValueEntry));
    end;

    procedure CalcCustActualCostLCY(var Customer: Record Customer) CostAmt: Decimal
    var
        ValueEntry: Record "Value Entry";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Customer);
        ValueEntry.SetRange("Source No.", Customer."No.");
        ValueEntry.SetFilter("Posting Date", Customer.GetFilter("Date Filter"));
        ValueEntry.SetFilter("Global Dimension 1 Code", Customer.GetFilter("Global Dimension 1 Filter"));
        ValueEntry.SetFilter("Global Dimension 2 Code", Customer.GetFilter("Global Dimension 2 Filter"));
        ValueEntry.SetFilter("Entry Type", '<> %1', ValueEntry."Entry Type"::Revaluation);
        OnCalcCustActualCostLCYOnAfterFilterValueEntry(Customer, ValueEntry);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        CostAmt := ValueEntry."Cost Amount (Actual)";

        ResLedgerEntry.SetRange("Entry Type", ResLedgerEntry."Entry Type"::Sale);
        ResLedgerEntry.SetRange("Source Type", ResLedgerEntry."Source Type"::Customer);
        ResLedgerEntry.SetRange("Source No.", Customer."No.");
        ResLedgerEntry.SetFilter("Posting Date", Customer.GetFilter("Date Filter"));
        ResLedgerEntry.SetFilter("Global Dimension 1 Code", Customer.GetFilter("Global Dimension 1 Filter"));
        ResLedgerEntry.SetFilter("Global Dimension 2 Code", Customer.GetFilter("Global Dimension 2 Filter"));
        OnCalcCustActualCostLCYOnAfterFilterResLedgerEntry(Customer, ResLedgerEntry);
        ResLedgerEntry.CalcSums(ResLedgerEntry."Total Cost");
        CostAmt += ResLedgerEntry."Total Cost";
    end;

    procedure NonInvtblCostAmt(var Customer: Record Customer): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange(ValueEntry."Source Type", ValueEntry."Source Type"::Customer);
        ValueEntry.SetRange(ValueEntry."Source No.", Customer."No.");
        ValueEntry.SetFilter(ValueEntry."Posting Date", Customer.GetFilter("Date Filter"));
        ValueEntry.SetFilter(ValueEntry."Global Dimension 1 Code", Customer.GetFilter("Global Dimension 1 Filter"));
        ValueEntry.SetFilter(ValueEntry."Global Dimension 2 Code", Customer.GetFilter("Global Dimension 2 Filter"));
        ValueEntry.CalcSums(ValueEntry."Cost Amount (Non-Invtbl.)");
        exit(ValueEntry."Cost Amount (Non-Invtbl.)");
    end;

    procedure SumValueEntriesCostAmt(var ValueEntry: Record "Value Entry") CostAmt: Decimal
    begin
        ValueEntry.CalcSums("Cost Amount (Actual)");
        CostAmt := ValueEntry."Cost Amount (Actual)";
        exit(CostAmt);
    end;

    procedure GetDocType(TableNo: Integer): Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        case TableNo of
            Database::"Purch. Rcpt. Header":
                exit(ItemLedgEntry."Document Type"::"Purchase Receipt".AsInteger());
            Database::"Purch. Inv. Header":
                exit(ItemLedgEntry."Document Type"::"Purchase Invoice".AsInteger());
            Database::"Purch. Cr. Memo Hdr.":
                exit(ItemLedgEntry."Document Type"::"Purchase Credit Memo".AsInteger());
            Database::"Return Shipment Header":
                exit(ItemLedgEntry."Document Type"::"Purchase Return Shipment".AsInteger());
            Database::"Sales Shipment Header":
                exit(ItemLedgEntry."Document Type"::"Sales Shipment".AsInteger());
            Database::"Sales Invoice Header":
                exit(ItemLedgEntry."Document Type"::"Sales Invoice".AsInteger());
            Database::"Sales Cr.Memo Header":
                exit(ItemLedgEntry."Document Type"::"Sales Credit Memo".AsInteger());
            Database::"Return Receipt Header":
                exit(ItemLedgEntry."Document Type"::"Sales Return Receipt".AsInteger());
            Database::"Transfer Shipment Header":
                exit(ItemLedgEntry."Document Type"::"Transfer Shipment".AsInteger());
            Database::"Transfer Receipt Header":
                exit(ItemLedgEntry."Document Type"::"Transfer Receipt".AsInteger());
            Database::"Posted Assembly Header":
                exit(ItemLedgEntry."Document Type"::"Posted Assembly".AsInteger());
        end;
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit Serv. Cost Calculation Mgt.', '25.0')]
    procedure CalcServLineCostLCY(ServLine: Record Microsoft.Service.Document."Service Line"; QtyType: Option General,Invoicing,Shipping,Consuming,ServLineItems,ServLineResources,ServLineCosts) TotalAdjCostLCY: Decimal
    var
        ServCostCalculationMgt: Codeunit "Serv. Cost Calculation Mgt.";
    begin
        exit(ServCostCalculationMgt.CalcServLineCostLCY(ServLine, QtyType));
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit Serv. Cost Calculation Mgt.', '25.0')]
    procedure CalcServInvLineCostLCY(ServInvLine: Record Microsoft.Service.History."Service Invoice Line") AdjCostLCY: Decimal
    var
        ServCostCalculationMgt: Codeunit "Serv. Cost Calculation Mgt.";
    begin
        exit(ServCostCalculationMgt.CalcServInvLineCostLCY(ServInvLine));
    end;
#endif

    procedure AdjustForRevNegCon(var ActMatCost: Decimal; var ActMatCostCostACY: Decimal; var ItemLedgEntry: Record "Item Ledger Entry")
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ItemLedgEntry.SetRange(Positive, true);
        if ItemLedgEntry.FindSet() then
            repeat
                ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
                ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
                ActMatCost += ValueEntry."Cost Amount (Actual)";
                ActMatCostCostACY += ValueEntry."Cost Amount (Actual) (ACY)";
            until ItemLedgEntry.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcShareOfTotalCapCost(var ProdOrderLine: Record "Prod. Order Line"; var ShareOfTotalCapCost: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcProdOrderLineExpCost(var ProdOrderLine: Record "Prod. Order Line"; var ShareOfTotalCapCost: Decimal; var ExpMatCost: Decimal; var ExpCapDirCost: Decimal; var ExpSubDirCost: Decimal; var ExpCapOvhdCost: Decimal; var ExpMfgOvhdCost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearWorkCenter(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; var WorkCenter: Record "Work Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcActNeededQtyBase(var OutputQtyBase: Decimal; ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCompItemQtyBase(ProdBOMComponent: Record "Production BOM Line"; CalculationDate: Date; var MfgItemQtyBase: Decimal; RtngNo: Code[20]; AdjdForRtngScrap: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcProdOrderActTimeUsed(ProductionOrder: Record "Production Order"; var CapacityLedgerEntry: Record "Capacity Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcProdOrderLineStdCost(var ProdOrderLine: Record "Prod. Order Line"; QtyBase: Decimal; CurrencyFactor: Decimal; RndgPrec: Decimal; var StdMatCost: Decimal; var StdCapDirCost: Decimal; var StdSubDirCost: Decimal; var StdCapOvhdCost: Decimal; var StdMfgOvhdCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyAdjdForBOMScrap(Qty: Decimal; ScrapPct: Decimal; var QtyAdjdForBomScrap: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyAdjdForRoutingScrap(Qty: Decimal; ScrapFactorPctAccum: Decimal; FixedScrapQtyAccum: Decimal; var QtyAdjdForRoutingScrap: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcProdOrderExpCapNeed(ProductionOrder: Record "Production Order"; var ProdOrderCapacityNeed: Record "Prod. Order Capacity Need"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced by event OnBeforeCalcRoutingCostPerUnit()', '23.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoutingCostPerUnit(Type: Enum "Capacity Type"; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Option Time,Unit; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRoutingCostPerUnit(Type: Enum "Capacity Type"; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Enum "Unit Cost Calculation Type"; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcActOperOutputAndScrapOnAfterFilterCapLedgEntry(var CapacityLedgerEntry: Record "Capacity Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcActTimeAndQtyBaseOnAfterFilterCapLedgEntry(var CapacityLedgerEntry: Record "Capacity Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderLineExpCostOnExpOperCostCalculated(var ExpOperCost: Decimal; ProdOrderRtngLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderLineStdCostOnAfterCalcSingleLevelCost(var Item: record Item; InvtAdjmtEntryOrder: record "Inventory Adjmt. Entry (Order)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderLineActCostOnBeforeSetProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; var ActMatCost: Decimal; var ActCapDirCost: Decimal; var ActSubDirCost: Decimal; var ActCapOvhdCost: Decimal; var ActMfgOvhdCost: Decimal; var ActMatCostCostACY: Decimal; var ActCapDirCostACY: Decimal; var ActSubDirCostACY: Decimal; var ActCapOvhdCostACY: Decimal; var ActMfgOvhdCostACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcActOutputQtyBaseOnAfterSetFilters(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced by event OnAfterCalcRoutingCostPerUnit()', '23.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterRoutingCostPerUnit(Type: Enum "Capacity Type"; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Option Time,Unit; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcRoutingCostPerUnit(Type: Enum "Capacity Type"; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Enum "Unit Cost Calculation Type"; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderActTimeUsedOnBeforeCalcQty(CapLedgEntry: Record "Capacity Ledger Entry"; var Qty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderActTimeUsedOnAfterCapacityLedgerEntrySetFilters(var CapLedgEntry: Record "Capacity Ledger Entry"; ProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderExpCapNeedOnAfterProdOrderCapNeedSetFilters(var ProdOrderCapNeed: Record "Prod. Order Capacity Need"; ProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderExpCapNeedOnBeforeMarkNotFinishedProdOrderRtngLine(ProdOrderRtngLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center"; var ExpectedCapNeed: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderLineExpCostOnAfterProdOrderCompSetFilters(var ProdOrderComp: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderLineExpCostOnAfterProdOrderRtngLineSetFilters(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcSalesLineCostLCY(SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing; var IsHandled: Boolean; var TotalAdjCostLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcSalesLineShptAdjCostLCYBeforeSalesShptLineFind(var SalesShptLine: Record "Sales Shipment Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRountingLineOnAfterRoutingLineSetFilters(var RoutingLine: Record "Routing Line"; ProdBOMLine: Record "Production BOM Line"; CalculationDate: Date; RoutingNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcOutputQtyBaseOnPurchOrder(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"; var OutstandingBaseQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCustActualCostLCYOnAfterFilterValueEntry(var Customer: Record Customer; var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCustActualCostLCYOnAfterFilterResLedgerEntry(var Customer: Record Customer; var ResLedgerEntry: Record "Res. Ledger Entry")
    begin
    end;
}

