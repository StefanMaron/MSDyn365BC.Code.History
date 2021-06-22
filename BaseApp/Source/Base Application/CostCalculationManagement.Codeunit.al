codeunit 5836 "Cost Calculation Management"
{
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Prod. Order Capacity Need" = r,
                  TableData "Value Entry" = r;

    trigger OnRun()
    begin
    end;

    var
        UOMMgt: Codeunit "Unit of Measure Management";
        ExpOvhdCost: Decimal;

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

    procedure RoutingCostPerUnit(Type: Option "Work Center","Machine Center"; No: Code[20]; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Option Time,Unit)
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
        RoutingCostPerUnit(Type, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculation, WorkCenter, MachineCenter);
    end;

    procedure RoutingCostPerUnit(Type: Option "Work Center","Machine Center"; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Option Time,Unit; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center")
    begin
        UnitCostCalculation := UnitCostCalculation::Time;
        case Type of
            Type::"Work Center":
                begin
                    UnitCostCalculation := WorkCenter."Unit Cost Calculation";
                    IndirCostPct := WorkCenter."Indirect Cost %";
                    OvhdRate := WorkCenter."Overhead Rate";
                    if WorkCenter."Specific Unit Cost" then begin
                        DirUnitCost := CalcDirUnitCost(UnitCost, OvhdRate, IndirCostPct);
                    end else begin
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
    end;

    procedure CalcShareOfTotalCapCost(ProdOrderLine: Record "Prod. Order Line"; var ShareOfTotalCapCost: Decimal)
    var
        Qty: Decimal;
    begin
        with ProdOrderLine do begin
            SetCurrentKey(Status, "Prod. Order No.", "Routing No.", "Routing Reference No.");
            SetRange(Status, Status);
            SetRange("Prod. Order No.", "Prod. Order No.");
            SetRange("Routing Reference No.", "Routing Reference No.");
            SetRange("Routing No.", "Routing No.");
            ShareOfTotalCapCost := 0;
            if Status = Status::Finished then begin
                Qty := "Finished Quantity";
                CalcSums("Finished Quantity");
                if "Finished Quantity" <> 0 then
                    ShareOfTotalCapCost := Qty / "Finished Quantity";
            end else begin
                Qty := Quantity;
                CalcSums(Quantity);
                if Quantity <> 0 then
                    ShareOfTotalCapCost := Qty / Quantity;
            end;
        end;
    end;

    procedure CalcProdOrderLineStdCost(ProdOrderLine: Record "Prod. Order Line"; CurrencyFactor: Decimal; RndgPrec: Decimal; var StdMatCost: Decimal; var StdCapDirCost: Decimal; var StdSubDirCost: Decimal; var StdCapOvhdCost: Decimal; var StdMfgOvhdCost: Decimal)
    var
        Item: Record Item;
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        QtyBase: Decimal;
        IsHandled: Boolean;
    begin
        with ProdOrderLine do begin
            if InvtAdjmtEntryOrder.Get(InvtAdjmtEntryOrder."Order Type"::Production, "Prod. Order No.", "Line No.") and
               InvtAdjmtEntryOrder."Completely Invoiced"
            then begin
                Item."Single-Level Material Cost" := InvtAdjmtEntryOrder."Single-Level Material Cost";
                Item."Single-Level Capacity Cost" := InvtAdjmtEntryOrder."Single-Level Capacity Cost";
                Item."Single-Level Subcontrd. Cost" := InvtAdjmtEntryOrder."Single-Level Subcontrd. Cost";
                Item."Single-Level Cap. Ovhd Cost" := InvtAdjmtEntryOrder."Single-Level Cap. Ovhd Cost";
                Item."Single-Level Mfg. Ovhd Cost" := InvtAdjmtEntryOrder."Single-Level Mfg. Ovhd Cost";
                QtyBase := "Finished Qty. (Base)";
            end else begin
                Item.Get("Item No.");
                QtyBase := "Quantity (Base)";
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
    begin
        with ProdOrderLine do begin
            ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.");
            ProdOrderComp.SetRange(Status, Status);
            ProdOrderComp.SetRange("Prod. Order No.", "Prod. Order No.");
            ProdOrderComp.SetRange("Prod. Order Line No.", "Line No.");
            if ProdOrderComp.Find('-') then
                repeat
                    ExpMatCost := ExpMatCost + ProdOrderComp."Cost Amount";
                until ProdOrderComp.Next = 0;

            ProdOrderRtngLine.SetRange(Status, Status);
            ProdOrderRtngLine.SetRange("Prod. Order No.", "Prod. Order No.");
            ProdOrderRtngLine.SetRange("Routing No.", "Routing No.");
            ProdOrderRtngLine.SetRange("Routing Reference No.", "Routing Reference No.");
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
                until ProdOrderRtngLine.Next = 0;

            ExpCapDirCost := ExpCapDirCost + Round(ExpCapDirCostRtng * ShareOfTotalCapCost);
            ExpSubDirCost := ExpSubDirCost + Round(ExpSubDirCostRtng * ShareOfTotalCapCost);
            ExpCapOvhdCost := ExpCapOvhdCost + Round(ExpCapOvhdCostRtng * ShareOfTotalCapCost);
            ExpMfgDirCost := ExpMatCost + ExpCapDirCost + ExpSubDirCost + ExpCapOvhdCost;
            ExpOvhdCost := ExpOvhdCost + "Overhead Rate" * "Quantity (Base)";
            ExpMfgOvhdCost := ExpOvhdCost +
              Round(CalcOvhdCost(ExpMfgDirCost, "Indirect Cost %", 0, 0));
        end;
    end;

    procedure CalcProdOrderLineActCost(ProdOrderLine: Record "Prod. Order Line"; var ActMatCost: Decimal; var ActCapDirCost: Decimal; var ActSubDirCost: Decimal; var ActCapOvhdCost: Decimal; var ActMfgOvhdCost: Decimal; var ActMatCostCostACY: Decimal; var ActCapDirCostACY: Decimal; var ActSubDirCostACY: Decimal; var ActCapOvhdCostACY: Decimal; var ActMfgOvhdCostACY: Decimal)
    var
        TempSourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)" temporary;
        CalcInvtAdjmtOrder: Codeunit "Calc. Inventory Adjmt. - Order";
        OutputQty: Decimal;
    begin
        if ProdOrderLine.Status < ProdOrderLine.Status::Released then begin
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

        with TempSourceInvtAdjmtEntryOrder do begin
            SetProdOrderLine(ProdOrderLine);
            OutputQty := CalcInvtAdjmtOrder.CalcOutputQty(TempSourceInvtAdjmtEntryOrder, false);
            CalcInvtAdjmtOrder.CalcActualUsageCosts(TempSourceInvtAdjmtEntryOrder, OutputQty, TempSourceInvtAdjmtEntryOrder);

            ActMatCost += "Single-Level Material Cost";
            ActCapDirCost += "Single-Level Capacity Cost";
            ActSubDirCost += "Single-Level Subcontrd. Cost";
            ActCapOvhdCost += "Single-Level Cap. Ovhd Cost";
            ActMfgOvhdCost += "Single-Level Mfg. Ovhd Cost";
            ActMatCostCostACY += "Single-Lvl Material Cost (ACY)";
            ActCapDirCostACY += "Single-Lvl Capacity Cost (ACY)";
            ActCapOvhdCostACY += "Single-Lvl Cap. Ovhd Cost(ACY)";
            ActSubDirCostACY += "Single-Lvl Subcontrd Cost(ACY)";
            ActMfgOvhdCostACY += "Single-Lvl Mfg. Ovhd Cost(ACY)";
        end;
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

        with ProdOrder do
            if Status <> Status::Finished then begin
                ProdOrderCapNeed.SetRange(Status, Status);
                ProdOrderCapNeed.SetRange("Prod. Order No.", "No.");
                ProdOrderCapNeed.SetFilter(Type, GetFilter("Capacity Type Filter"));
                ProdOrderCapNeed.SetFilter("No.", "Capacity No. Filter");
                ProdOrderCapNeed.SetFilter("Work Center No.", "Work Center Filter");
                ProdOrderCapNeed.SetFilter(Date, GetFilter("Date Filter"));
                ProdOrderCapNeed.SetRange("Requested Only", false);
                if ProdOrderCapNeed.FindSet then begin
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
                    until ProdOrderCapNeed.Next = 0;
                    ProdOrderCapNeed.MarkedOnly(true);
                end;
                if DrillDown then
                    PAGE.Run(0, ProdOrderCapNeed, ProdOrderCapNeed."Needed Time")
                else
                    exit(NeededTime);
            end else begin
                ProdOrderRtngLine.SetRange(Status, Status);
                ProdOrderRtngLine.SetRange("Prod. Order No.", "No.");
                if ProdOrderRtngLine.FindSet then begin
                    repeat
                        if ProdOrderRtngLine.Type = ProdOrderRtngLine.Type::"Work Center" then begin
                            if not WorkCenter.Get(ProdOrderRtngLine."No.") then
                                Clear(WorkCenter);
                        end else
                            Clear(WorkCenter);
                        if WorkCenter."Subcontractor No." = '' then begin
                            ExpectedCapNeed += ProdOrderRtngLine."Expected Capacity Need";
                            ProdOrderRtngLine.Mark(true);
                        end;
                    until ProdOrderRtngLine.Next = 0;
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
    begin
        OnBeforeCalcProdOrderActTimeUsed(ProdOrder, CapLedgEntry);

        with CapLedgEntry do begin
            if ProdOrder.Status < ProdOrder.Status::Released then
                exit(0);

            SetCurrentKey("Order Type", "Order No.");
            SetRange("Order Type", "Order Type"::Production);
            SetRange("Order No.", ProdOrder."No.");
            if FindSet then begin
                repeat
                    if Type = Type::"Work Center" then begin
                        if not WorkCenter.Get("No.") then
                            Clear(WorkCenter);
                    end else
                        Clear(WorkCenter);
                    if WorkCenter."Subcontractor No." = '' then begin
                        if "Qty. per Cap. Unit of Measure" = 0 then
                            GetCapacityUoM(CapLedgEntry);
                        Qty +=
                          ("Setup Time" + "Run Time") /
                          "Qty. per Cap. Unit of Measure" *
                          CalendarMgt.TimeFactor("Cap. Unit of Measure Code");
                        Mark(true);
                    end;
                until Next = 0;
                MarkedOnly(true);
            end;

            if DrillDown then
                PAGE.Run(0, CapLedgEntry, Quantity)
            else
                exit(Qty);
        end;
    end;

    local procedure GetCapacityUoM(var CapacityLedgerEntry: Record "Capacity Ledger Entry")
    var
        WorkCenter: Record "Work Center";
    begin
        CapacityLedgerEntry."Qty. per Cap. Unit of Measure" := 1;
        if WorkCenter.Get(CapacityLedgerEntry."Work Center No.") then
            CapacityLedgerEntry."Cap. Unit of Measure Code" := WorkCenter."Unit of Measure Code";
    end;

    procedure CalcOutputQtyBaseOnPurchOrder(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"): Decimal
    var
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        OutstandingBaseQty: Decimal;
    begin
        with PurchLine do begin
            SetCurrentKey(
              "Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
            SetRange("Document Type", "Document Type"::Order);
            SetRange(Type, Type::Item);
            SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
            SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
            SetRange("Routing No.", ProdOrderRtngLine."Routing No.");
            SetRange("Operation No.", ProdOrderRtngLine."Operation No.");
            if Find('-') then
                repeat
                    if Item."No." <> "No." then
                        Item.Get("No.");
                    OutstandingBaseQty :=
                      OutstandingBaseQty +
                      UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code") * "Outstanding Quantity";
                until Next = 0;
            exit(OutstandingBaseQty);
        end;
    end;

    procedure CalcActOutputQtyBase(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"): Decimal
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        with CapLedgEntry do begin
            if ProdOrderLine.Status < ProdOrderLine.Status::Released then
                exit(0);

            SetCurrentKey(
              "Order Type", "Order No.", "Order Line No.", "Routing No.", "Routing Reference No.", "Operation No.");
            SetFilterByProdOrderRoutingLine(
              ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
              ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
            SetRange("Operation No.", ProdOrderRtngLine."Operation No.");
            OnCalcActOutputQtyBaseOnAfterSetFilters(CapLedgEntry, ProdOrderLine, ProdOrderRtngLine);
            CalcSums("Output Quantity");
            exit("Output Quantity");
        end;
    end;

    procedure CalcActQtyBase(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"): Decimal
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        with CapLedgEntry do begin
            if ProdOrderLine.Status < ProdOrderLine.Status::Released then
                exit(0);

            SetCurrentKey(
              "Order Type", "Order No.", "Order Line No.", "Routing No.", "Routing Reference No.", "Operation No.", "Last Output Line");
            SetFilterByProdOrderRoutingLine(
              ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
              ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
            SetRange("Last Output Line", true);
            CalcSums(Quantity);
            exit(Quantity / ProdOrderLine."Qty. per Unit of Measure");
        end;
    end;

    procedure CalcActOperOutputAndScrap(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line") OutputQtyBase: Decimal
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        with CapLedgEntry do begin
            if ProdOrderLine.Status < ProdOrderLine.Status::Released then
                exit(0);

            SetCurrentKey(
              "Order Type", "Order No.", "Order Line No.", "Routing No.", "Routing Reference No.", "Operation No.", "Last Output Line");
            SetFilterByProdOrderRoutingLine(
              ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
              ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
            SetRange("Last Output Line", true);
            OnCalcActOperOutputAndScrapOnAfterFilterCapLedgEntry(CapLedgEntry);
            CalcSums("Output Quantity", "Scrap Quantity");
            OutputQtyBase := "Output Quantity" + "Scrap Quantity";

            exit(OutputQtyBase);
        end;
    end;

    procedure CalcActNeededQtyBase(ProdOrderLine: Record "Prod. Order Line"; ProdOrderComp: Record "Prod. Order Component"; OutputQtyBase: Decimal): Decimal
    var
        CompQtyBasePerMfgQtyBase: Decimal;
    begin
        OnBeforeCalcActNeededQtyBase(OutputQtyBase, ProdOrderComp);

        CompQtyBasePerMfgQtyBase := ProdOrderComp."Quantity (Base)" / ProdOrderLine."Qty. per Unit of Measure";
        exit(CalcQtyAdjdForBOMScrap(OutputQtyBase * CompQtyBasePerMfgQtyBase, ProdOrderComp."Scrap %"));
    end;

    procedure CalcActTimeAndQtyBase(ProdOrderLine: Record "Prod. Order Line"; OperationNo: Code[10]; var ActRunTime: Decimal; var ActSetupTime: Decimal; var ActOutputQty: Decimal; var ActScrapQty: Decimal)
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        with CapLedgEntry do begin
            SetCurrentKey(
              "Order Type", "Order No.", "Order Line No.", "Routing No.", "Routing Reference No.",
              "Operation No.", "Last Output Line");

            SetFilterByProdOrderRoutingLine(
              ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
              ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.");
            SetRange("Operation No.", OperationNo);
            OnCalcActTimeAndQtyBaseOnAfterFilterCapLedgEntry(CapLedgEntry);
            if Find('-') then
                repeat
                    ActSetupTime += "Setup Time";
                    ActRunTime += "Run Time";
                    // Base Units
                    ActOutputQty += "Output Quantity";
                    ActScrapQty += "Scrap Quantity";
                until Next = 0;
        end;
    end;

    procedure CalcCompItemQtyBase(ProdBOMComponent: Record "Production BOM Line"; CalculationDate: Date; MfgItemQtyBase: Decimal; RtngNo: Code[20]; AdjdForRtngScrap: Boolean): Decimal
    var
        RtngLine: Record "Routing Line";
    begin
        with ProdBOMComponent do begin
            MfgItemQtyBase := CalcQtyAdjdForBOMScrap(MfgItemQtyBase, "Scrap %");
            if AdjdForRtngScrap and FindRountingLine(RtngLine, ProdBOMComponent, CalculationDate, RtngNo) then
                MfgItemQtyBase :=
                  CalcQtyAdjdForRoutingScrap(MfgItemQtyBase, RtngLine."Scrap Factor % (Accumulated)", RtngLine."Fixed Scrap Qty. (Accum.)");
            MfgItemQtyBase := MfgItemQtyBase * Quantity * GetQtyPerUnitOfMeasure;

            exit(MfgItemQtyBase);
        end;
    end;

    procedure CalcCostTime(MfgItemQtyBase: Decimal; SetupTime: Decimal; SetupTimeUOMCode: Code[10]; RunTime: Decimal; RunTimeUOMCode: Code[10]; RtngLotSize: Decimal; ScrapFactorPctAccum: Decimal; FixedScrapQtyAccum: Decimal; WorkCenterNo: Code[20]; UnitCostCalculation: Option Time,Unit; CostInclSetup: Boolean; ConcurrentCapacities: Decimal) CostTime: Decimal
    var
        CalendarMgt: Codeunit "Shop Calendar Management";
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
                          RunTimePer * MfgItemQtyBase * CalendarMgt.QtyperTimeUnitofMeasure(WorkCenterNo, RunTimeUOMCode),
                          UOMMgt.TimeRndPrecision),
                        ScrapFactorPctAccum,
                        Round(
                          RunTimePer * FixedScrapQtyAccum * CalendarMgt.QtyperTimeUnitofMeasure(WorkCenterNo, RunTimeUOMCode),
                          UOMMgt.TimeRndPrecision));
                    if CostInclSetup then
                        CostTime :=
                          CostTime +
                          Round(
                            ConcurrentCapacities *
                            SetupTime * CalendarMgt.QtyperTimeUnitofMeasure(WorkCenterNo, SetupTimeUOMCode),
                            UOMMgt.TimeRndPrecision);
                end;
            UnitCostCalculation::Unit:
                CostTime := CalcQtyAdjdForRoutingScrap(MfgItemQtyBase, ScrapFactorPctAccum, FixedScrapQtyAccum);
        end;
    end;

    procedure CalcQtyAdjdForBOMScrap(Qty: Decimal; ScrapPct: Decimal): Decimal
    begin
        exit(Qty * (1 + ScrapPct / 100));
    end;

    procedure CalcQtyAdjdForRoutingScrap(Qty: Decimal; ScrapFactorPctAccum: Decimal; FixedScrapQtyAccum: Decimal): Decimal
    begin
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
        if not RoutingLine.IsEmpty then begin
            if ProdBOMLine."Routing Link Code" <> '' then
                RoutingLine.SetRange("Routing Link Code", ProdBOMLine."Routing Link Code");
            RecFound := RoutingLine.FindFirst;
            if not RecFound then begin
                RoutingLine.SetRange("Routing Link Code");
                RecFound := RoutingLine.FindFirst;
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
        with ItemLedgEntry2 do
            exit(
              ("Document Type" = ItemLedgEntry."Document Type") and
              ("Document No." = ItemLedgEntry."Document No.") and
              ("Document Line No." = ItemLedgEntry."Document Line No.") and
              ("Posting Date" = ItemLedgEntry."Posting Date") and
              ("Source Type" = ItemLedgEntry."Source Type") and
              ("Source No." = ItemLedgEntry."Source No.") and
              ("Entry Type" = ItemLedgEntry."Entry Type") and
              ("Item No." = ItemLedgEntry."Item No.") and
              ("Location Code" = ItemLedgEntry."Location Code") and
              ("Variant Code" = ItemLedgEntry."Variant Code") and
              (QtyBase = Quantity + ItemLedgEntry.Quantity) and
              (Quantity = "Invoiced Quantity"));
    end;

    procedure CalcSalesLineCostLCY(SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing) TotalAdjCostLCY: Decimal
    var
        PostedQtyBase: Decimal;
        RemQtyToCalcBase: Decimal;
    begin
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

    local procedure CalcSalesLineShptAdjCostLCY(SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing; var TotalAdjCostLCY: Decimal; var PostedQtyBase: Decimal; var RemQtyToCalcBase: Decimal)
    var
        SalesShptLine: Record "Sales Shipment Line";
        QtyShippedNotInvcdBase: Decimal;
        AdjCostLCY: Decimal;
    begin
        with SalesShptLine do begin
            if SalesLine."Shipment No." <> '' then begin
                SetRange("Document No.", SalesLine."Shipment No.");
                SetRange("Line No.", SalesLine."Shipment Line No.");
            end else begin
                SetCurrentKey("Order No.", "Order Line No.");
                SetRange("Order No.", SalesLine."Document No.");
                SetRange("Order Line No.", SalesLine."Line No.");
            end;
            SetRange(Correction, false);
            if QtyType = QtyType::Invoicing then begin
                SetFilter("Qty. Shipped Not Invoiced", '<>0');
                RemQtyToCalcBase := SalesLine."Qty. to Invoice (Base)" - SalesLine."Qty. to Ship (Base)";
            end else
                RemQtyToCalcBase := SalesLine."Quantity (Base)";

            if FindSet then
                repeat
                    if "Qty. per Unit of Measure" = 0 then
                        QtyShippedNotInvcdBase := "Qty. Shipped Not Invoiced"
                    else
                        QtyShippedNotInvcdBase :=
                          Round("Qty. Shipped Not Invoiced" * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);

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
                                  TotalAdjCostLCY + AdjCostLCY / "Quantity (Base)" * RemQtyToCalcBase;
                                RemQtyToCalcBase := 0;
                            end;
                        else begin
                                PostedQtyBase := PostedQtyBase + "Quantity (Base)";
                                TotalAdjCostLCY := TotalAdjCostLCY + AdjCostLCY;
                            end;
                    end;
                until (Next = 0) or (RemQtyToCalcBase = 0);
        end;
    end;

    local procedure CalcSalesLineRcptAdjCostLCY(SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing; var TotalAdjCostLCY: Decimal; var PostedQtyBase: Decimal; var RemQtyToCalcBase: Decimal)
    var
        ReturnRcptLine: Record "Return Receipt Line";
        RtrnQtyRcvdNotInvcdBase: Decimal;
        AdjCostLCY: Decimal;
    begin
        with ReturnRcptLine do begin
            if SalesLine."Return Receipt No." <> '' then begin
                SetRange("Document No.", SalesLine."Return Receipt No.");
                SetRange("Line No.", SalesLine."Return Receipt Line No.");
            end else begin
                SetCurrentKey("Return Order No.", "Return Order Line No.");
                SetRange("Return Order No.", SalesLine."Document No.");
                SetRange("Return Order Line No.", SalesLine."Line No.");
            end;
            SetRange(Correction, false);
            if QtyType = QtyType::Invoicing then begin
                SetFilter("Return Qty. Rcd. Not Invd.", '<>0');
                RemQtyToCalcBase :=
                  SalesLine."Qty. to Invoice (Base)" - SalesLine."Return Qty. to Receive (Base)";
            end else
                RemQtyToCalcBase := SalesLine."Quantity (Base)";

            if FindSet then
                repeat
                    if "Qty. per Unit of Measure" = 0 then
                        RtrnQtyRcvdNotInvcdBase := "Return Qty. Rcd. Not Invd."
                    else
                        RtrnQtyRcvdNotInvcdBase :=
                          Round("Return Qty. Rcd. Not Invd." * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);

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
                                  TotalAdjCostLCY + AdjCostLCY / "Quantity (Base)" * RemQtyToCalcBase;
                                RemQtyToCalcBase := 0;
                            end;
                        else begin
                                PostedQtyBase := PostedQtyBase + "Quantity (Base)";
                                TotalAdjCostLCY := TotalAdjCostLCY + AdjCostLCY;
                            end;
                    end;
                until (Next = 0) or (RemQtyToCalcBase = 0);
        end;
    end;

    local procedure CalcSalesShptLineCostLCY(SalesShptLine: Record "Sales Shipment Line"; QtyType: Option General,Invoicing,Shipping) AdjCostLCY: Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        with SalesShptLine do begin
            if (Quantity = 0) or (Type = Type::"Charge (Item)") then
                exit(0);

            if Type = Type::Item then begin
                FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                if ItemLedgEntry.IsEmpty then
                    exit(0);
                AdjCostLCY := CalcPostedDocLineCostLCY(ItemLedgEntry, QtyType);
            end else begin
                if QtyType = QtyType::Invoicing then
                    AdjCostLCY := -"Qty. Shipped Not Invoiced" * "Unit Cost (LCY)"
                else
                    AdjCostLCY := -Quantity * "Unit Cost (LCY)";
            end;
        end;
    end;

    local procedure CalcReturnRcptLineCostLCY(ReturnRcptLine: Record "Return Receipt Line"; QtyType: Option General,Invoicing,Shipping) AdjCostLCY: Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        with ReturnRcptLine do begin
            if (Quantity = 0) or (Type = Type::"Charge (Item)") then
                exit(0);

            if Type = Type::Item then begin
                FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                if ItemLedgEntry.IsEmpty then
                    exit(0);
                AdjCostLCY := CalcPostedDocLineCostLCY(ItemLedgEntry, QtyType);
            end else begin
                if QtyType = QtyType::Invoicing then
                    AdjCostLCY := "Return Qty. Rcd. Not Invd." * "Unit Cost (LCY)"
                else
                    AdjCostLCY := Quantity * "Unit Cost (LCY)";
            end;
        end;
    end;

    local procedure CalcPostedDocLineCostLCY(var ItemLedgEntry: Record "Item Ledger Entry"; QtyType: Option General,Invoicing,Shipping,Consuming) AdjCostLCY: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        with ItemLedgEntry do begin
            FindSet;
            repeat
                if (QtyType = QtyType::Invoicing) or (QtyType = QtyType::Consuming) then begin
                    CalcFields("Cost Amount (Expected)");
                    AdjCostLCY := AdjCostLCY + "Cost Amount (Expected)";
                end else begin
                    ValueEntry.SetCurrentKey("Item Ledger Entry No.");
                    ValueEntry.SetRange("Item Ledger Entry No.", "Entry No.");
                    if ValueEntry.FindSet then
                        repeat
                            if (ValueEntry."Entry Type" <> ValueEntry."Entry Type"::Revaluation) and
                               (ValueEntry."Item Charge No." = '')
                            then
                                AdjCostLCY :=
                                  AdjCostLCY + ValueEntry."Cost Amount (Expected)" + ValueEntry."Cost Amount (Actual)";
                        until ValueEntry.Next = 0;
                end;
            until Next = 0;
        end;
    end;

    procedure CalcSalesInvLineCostLCY(SalesInvLine: Record "Sales Invoice Line") AdjCostLCY: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        with SalesInvLine do begin
            if Quantity = 0 then
                exit(0);

            if Type in [Type::Item, Type::"Charge (Item)"] then begin
                FilterPstdDocLineValueEntries(ValueEntry);
                AdjCostLCY := -SumValueEntriesCostAmt(ValueEntry);
            end else
                AdjCostLCY := Quantity * "Unit Cost (LCY)";
        end;
    end;

    procedure CalcSalesInvLineNonInvtblCostAmt(SalesInvoiceLine: Record "Sales Invoice Line"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            SetRange("Document No.", SalesInvoiceLine."Document No.");
            SetRange("Document Type", "Document Type"::"Sales Invoice");
            SetRange("Document Line No.", SalesInvoiceLine."Line No.");
            CalcSums("Cost Amount (Non-Invtbl.)");
            exit(-"Cost Amount (Non-Invtbl.)");
        end;
    end;

    procedure CalcSalesCrMemoLineCostLCY(SalesCrMemoLine: Record "Sales Cr.Memo Line") AdjCostLCY: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        with SalesCrMemoLine do begin
            if Quantity = 0 then
                exit(0);

            if Type in [Type::Item, Type::"Charge (Item)"] then begin
                FilterPstdDocLineValueEntries(ValueEntry);
                AdjCostLCY := SumValueEntriesCostAmt(ValueEntry);
            end else
                AdjCostLCY := Quantity * "Unit Cost (LCY)";
        end;
    end;

    procedure CalcSalesCrMemoLineNonInvtblCostAmt(SalesCrMemoLine: Record "Sales Cr.Memo Line"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            SetRange("Document No.", SalesCrMemoLine."Document No.");
            SetRange("Document Type", "Document Type"::"Sales Credit Memo");
            SetRange("Document Line No.", SalesCrMemoLine."Line No.");
            CalcSums("Cost Amount (Non-Invtbl.)");
            exit("Cost Amount (Non-Invtbl.)");
        end;
    end;

    procedure CalcServCrMemoLineCostLCY(ServCrMemoLine: Record "Service Cr.Memo Line") AdjCostLCY: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        with ServCrMemoLine do begin
            if Quantity = 0 then
                exit(0);

            if Type = Type::Item then begin
                FilterPstdDocLineValueEntries(ValueEntry);
                AdjCostLCY := SumValueEntriesCostAmt(ValueEntry);
            end else
                AdjCostLCY := Quantity * "Unit Cost (LCY)";
        end;
    end;

    procedure CalcCustLedgAdjmtCostLCY(CustLedgEntry: Record "Cust. Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        with CustLedgEntry do begin
            if not ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) then
                FieldError("Document Type");

            ValueEntry.SetCurrentKey("Document No.");
            ValueEntry.SetRange("Document No.", "Document No.");
            if "Document Type" = "Document Type"::Invoice then
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
    end;

    procedure CalcCustAdjmtCostLCY(var Customer: Record Customer): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            SetCurrentKey("Source Type", "Source No.");
            SetRange("Source Type", "Source Type"::Customer);
            SetRange("Source No.", Customer."No.");
            SetFilter("Posting Date", Customer.GetFilter("Date Filter"));
            SetFilter("Global Dimension 1 Code", Customer.GetFilter("Global Dimension 1 Filter"));
            SetFilter("Global Dimension 2 Code", Customer.GetFilter("Global Dimension 2 Filter"));
            SetRange(Adjustment, true);

            CalcSums("Cost Amount (Actual)");
            exit("Cost Amount (Actual)");
        end;
    end;

    procedure CalcCustLedgActualCostLCY(CustLedgEntry: Record "Cust. Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        with CustLedgEntry do begin
            if not ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) then
                FieldError("Document Type");

            ValueEntry.SetCurrentKey("Document No.");
            ValueEntry.SetRange("Document No.", "Document No.");
            if "Document Type" = "Document Type"::Invoice then
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
    end;

    procedure CalcCustActualCostLCY(var Customer: Record Customer) CostAmt: Decimal
    var
        ValueEntry: Record "Value Entry";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        with ValueEntry do begin
            SetRange("Source Type", "Source Type"::Customer);
            SetRange("Source No.", Customer."No.");
            SetFilter("Posting Date", Customer.GetFilter("Date Filter"));
            SetFilter("Global Dimension 1 Code", Customer.GetFilter("Global Dimension 1 Filter"));
            SetFilter("Global Dimension 2 Code", Customer.GetFilter("Global Dimension 2 Filter"));
            SetFilter("Entry Type", '<> %1', "Entry Type"::Revaluation);
            CalcSums("Cost Amount (Actual)");
            CostAmt := "Cost Amount (Actual)";
        end;

        with ResLedgerEntry do begin
            SetRange("Source Type", "Source Type"::Customer);
            SetRange("Source No.", Customer."No.");
            SetFilter("Posting Date", Customer.GetFilter("Date Filter"));
            SetFilter("Global Dimension 1 Code", Customer.GetFilter("Global Dimension 1 Filter"));
            SetFilter("Global Dimension 2 Code", Customer.GetFilter("Global Dimension 2 Filter"));
            CalcSums("Total Cost");
            CostAmt += "Total Cost";
        end;
    end;

    procedure NonInvtblCostAmt(var Customer: Record Customer): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            SetRange("Source Type", "Source Type"::Customer);
            SetRange("Source No.", Customer."No.");
            SetFilter("Posting Date", Customer.GetFilter("Date Filter"));
            SetFilter("Global Dimension 1 Code", Customer.GetFilter("Global Dimension 1 Filter"));
            SetFilter("Global Dimension 2 Code", Customer.GetFilter("Global Dimension 2 Filter"));
            CalcSums("Cost Amount (Non-Invtbl.)");
            exit("Cost Amount (Non-Invtbl.)");
        end;
    end;

    procedure SumValueEntriesCostAmt(var ValueEntry: Record "Value Entry") CostAmt: Decimal
    begin
        with ValueEntry do
            if FindSet then
                repeat
                    CostAmt := CostAmt + "Cost Amount (Actual)";
                until Next = 0;
        exit(CostAmt);
    end;

    procedure GetDocType(TableNo: Integer): Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgEntry do
            case TableNo of
                DATABASE::"Purch. Rcpt. Header":
                    exit("Document Type"::"Purchase Receipt");
                DATABASE::"Purch. Inv. Header":
                    exit("Document Type"::"Purchase Invoice");
                DATABASE::"Purch. Cr. Memo Hdr.":
                    exit("Document Type"::"Purchase Credit Memo");
                DATABASE::"Return Shipment Header":
                    exit("Document Type"::"Purchase Return Shipment");
                DATABASE::"Sales Shipment Header":
                    exit("Document Type"::"Sales Shipment");
                DATABASE::"Sales Invoice Header":
                    exit("Document Type"::"Sales Invoice");
                DATABASE::"Sales Cr.Memo Header":
                    exit("Document Type"::"Sales Credit Memo");
                DATABASE::"Return Receipt Header":
                    exit("Document Type"::"Sales Return Receipt");
                DATABASE::"Transfer Shipment Header":
                    exit("Document Type"::"Transfer Shipment");
                DATABASE::"Transfer Receipt Header":
                    exit("Document Type"::"Transfer Receipt");
                DATABASE::"Posted Assembly Header":
                    exit("Document Type"::"Posted Assembly");
            end;
    end;

    procedure CalcServLineCostLCY(ServLine: Record "Service Line"; QtyType: Option General,Invoicing,Shipping,Consuming,ServLineItems,ServLineResources,ServLineCosts) TotalAdjCostLCY: Decimal
    var
        PostedQtyBase: Decimal;
        RemQtyToCalcBase: Decimal;
    begin
        case ServLine."Document Type" of
            ServLine."Document Type"::Order, ServLine."Document Type"::Invoice:
                if ((ServLine."Quantity Shipped" <> 0) or (ServLine."Shipment No." <> '')) and
                   ((QtyType = QtyType::General) or
                    (QtyType = QtyType::ServLineItems) or
                    (QtyType = QtyType::ServLineResources) or
                    (QtyType = QtyType::ServLineCosts) or
                    (ServLine."Qty. to Invoice" > ServLine."Qty. to Ship") or
                    (ServLine."Qty. to Consume" > 0))
                then
                    CalcServLineShptAdjCostLCY(ServLine, QtyType, TotalAdjCostLCY, PostedQtyBase, RemQtyToCalcBase);
        end;
    end;

    local procedure CalcServLineShptAdjCostLCY(ServLine: Record "Service Line"; QtyType: Option General,Invoicing,Shipping,Consuming; var TotalAdjCostLCY: Decimal; var PostedQtyBase: Decimal; var RemQtyToCalcBase: Decimal)
    var
        ServShptLine: Record "Service Shipment Line";
        QtyShippedNotInvcdBase: Decimal;
        AdjCostLCY: Decimal;
    begin
        with ServShptLine do begin
            if ServLine."Shipment No." <> '' then begin
                SetRange("Document No.", ServLine."Shipment No.");
                SetRange("Line No.", ServLine."Shipment Line No.");
            end else begin
                SetCurrentKey("Order No.", "Order Line No.");
                SetRange("Order No.", ServLine."Document No.");
                SetRange("Order Line No.", ServLine."Line No.");
            end;
            SetRange(Correction, false);
            if QtyType = QtyType::Invoicing then begin
                SetFilter("Qty. Shipped Not Invoiced", '<>0');
                RemQtyToCalcBase := ServLine."Qty. to Invoice (Base)" - ServLine."Qty. to Ship (Base)";
            end else
                if (QtyType = QtyType::Consuming) and (ServLine."Qty. to Consume" > 0) then
                    RemQtyToCalcBase := ServLine."Qty. to Consume (Base)"
                else
                    RemQtyToCalcBase := ServLine."Quantity (Base)";

            if FindSet then
                repeat
                    if "Qty. per Unit of Measure" = 0 then
                        QtyShippedNotInvcdBase := "Qty. Shipped Not Invoiced"
                    else
                        QtyShippedNotInvcdBase :=
                          Round("Qty. Shipped Not Invoiced" * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);

                    AdjCostLCY := CalcServShptLineCostLCY(ServShptLine, QtyType);

                    case true of
                        QtyType = QtyType::Invoicing, QtyType = QtyType::Consuming:
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
                        ServLine."Shipment No." <> '':
                            begin
                                PostedQtyBase := PostedQtyBase + QtyShippedNotInvcdBase;
                                TotalAdjCostLCY :=
                                  TotalAdjCostLCY + AdjCostLCY / "Quantity (Base)" * RemQtyToCalcBase;
                                RemQtyToCalcBase := 0;
                            end;
                        else begin
                                PostedQtyBase := PostedQtyBase + "Quantity (Base)";
                                TotalAdjCostLCY := TotalAdjCostLCY + AdjCostLCY;
                            end;
                    end;
                until (Next = 0) or (RemQtyToCalcBase = 0);
        end;
    end;

    local procedure CalcServShptLineCostLCY(ServShptLine: Record "Service Shipment Line"; QtyType: Option General,Invoicing,Shipping,Consuming) AdjCostLCY: Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        with ServShptLine do begin
            if Quantity = 0 then
                exit(0);

            if Type = Type::Item then begin
                FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                if ItemLedgEntry.IsEmpty then
                    exit(0);
                AdjCostLCY := CalcPostedDocLineCostLCY(ItemLedgEntry, QtyType);
            end else begin
                if QtyType = QtyType::Invoicing then
                    AdjCostLCY := -"Qty. Shipped Not Invoiced" * "Unit Cost (LCY)"
                else
                    AdjCostLCY := -Quantity * "Unit Cost (LCY)";
            end;
        end;
    end;

    procedure CalcServInvLineCostLCY(ServInvLine: Record "Service Invoice Line") AdjCostLCY: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        with ServInvLine do begin
            if Quantity = 0 then
                exit(0);

            if Type = Type::Item then begin
                FilterPstdDocLineValueEntries(ValueEntry);
                AdjCostLCY := -SumValueEntriesCostAmt(ValueEntry);
            end else
                AdjCostLCY := Quantity * "Unit Cost (LCY)";
        end;
    end;

    procedure AdjustForRevNegCon(var ActMatCost: Decimal; var ActMatCostCostACY: Decimal; var ItemLedgEntry: Record "Item Ledger Entry")
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ItemLedgEntry.SetRange(Positive, true);
        if ItemLedgEntry.FindSet then
            repeat
                ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
                if ValueEntry.FindSet then
                    repeat
                        ActMatCost += ValueEntry."Cost Amount (Actual)";
                        ActMatCostCostACY += ValueEntry."Cost Amount (Actual) (ACY)";
                    until ValueEntry.Next = 0;
            until ItemLedgEntry.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcActNeededQtyBase(var OutputQtyBase: Decimal; ProdOrderComponent: Record "Prod. Order Component")
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
    local procedure OnBeforeCalcProdOrderExpCapNeed(ProductionOrder: Record "Production Order"; var ProdOrderCapacityNeed: Record "Prod. Order Capacity Need"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
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
    local procedure OnCalcActOutputQtyBaseOnAfterSetFilters(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;
}

