codeunit 5896 "Calc. Inventory Adjmt. - Order"
{
    Permissions = TableData "Capacity Ledger Entry" = r,
                  TableData "Inventory Adjmt. Entry (Order)" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;

    procedure Calculate(SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var InvtAdjmtBuf: Record "Inventory Adjustment Buffer")
    var
        ActInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        OutputQty: Decimal;
    begin
        if not Item.Get(SourceInvtAdjmtEntryOrder."Item No.") then
            Item.Init();

        OnCalculateOnAfterGetItem(Item, SourceInvtAdjmtEntryOrder);

        OutputQty := CalcOutputQty(SourceInvtAdjmtEntryOrder, false);
        CalcActualUsageCosts(SourceInvtAdjmtEntryOrder, OutputQty, ActInvtAdjmtEntryOrder);
        CalcActualVariances(SourceInvtAdjmtEntryOrder, OutputQty, ActInvtAdjmtEntryOrder);
        CalcOutputEntryCostAdjmts(SourceInvtAdjmtEntryOrder, OutputQty, ActInvtAdjmtEntryOrder, InvtAdjmtBuf);
    end;

    procedure CalcActualUsageCosts(SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OutputQty: Decimal; var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
        InvtAdjmtEntryOrder := SourceInvtAdjmtEntryOrder;
        InvtAdjmtEntryOrder.RoundCosts(0);

        CalcActualMaterialCosts(InvtAdjmtEntryOrder);
        CalcActualCapacityCosts(InvtAdjmtEntryOrder);
        InvtAdjmtEntryOrder.RoundCosts(1);

        InvtAdjmtEntryOrder.CalcOvhdCost(OutputQty);
        InvtAdjmtEntryOrder.RoundCosts(1);

        InvtAdjmtEntryOrder.CalcDirectCostFromCostShares();
        InvtAdjmtEntryOrder.CalcIndirectCostFromCostShares();
        InvtAdjmtEntryOrder.CalcUnitCost();
    end;

    local procedure CalcActualVariances(SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OutputQty: Decimal; var VarianceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    var
        StdCostInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        StdCostInvtAdjmtEntryOrder := SourceInvtAdjmtEntryOrder;

        if Item."Costing Method" = Item."Costing Method"::Standard then begin
            CalcStandardCost(StdCostInvtAdjmtEntryOrder, OutputQty);
            VarianceInvtAdjmtEntryOrder.CalcDiff(StdCostInvtAdjmtEntryOrder, true);
        end else
            VarianceInvtAdjmtEntryOrder.CalcDiff(VarianceInvtAdjmtEntryOrder, true);
    end;

    local procedure CalcOutputEntryCostAdjmts(SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OutputQty: Decimal; ActInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var InvtAdjmtBuf: Record "Inventory Adjustment Buffer")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        OldActInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        NewActInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        NewNegActInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        RemActInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        RemNegActInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ActNegInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        RemOutputQty: Decimal;
        RemNegOutputQty: Decimal;
        GrossOutputQty: Decimal;
        ReversedQty: Decimal;
        IsPositiveOutputs: Boolean;
    begin
        OutputItemLedgEntryExist(SourceInvtAdjmtEntryOrder, TempItemLedgEntry);
        GrossOutputQty := CalcOutputQty(SourceInvtAdjmtEntryOrder, true);
        if GrossOutputQty <> OutputQty then begin
            ActNegInvtAdjmtEntryOrder := ActInvtAdjmtEntryOrder;
            if OutputQty = 0 then
                ActNegInvtAdjmtEntryOrder.RoundCosts(-1)
            else
                ActNegInvtAdjmtEntryOrder.RoundCosts(-(GrossOutputQty - OutputQty) / OutputQty);
        end;

        for IsPositiveOutputs := true downto false do
            with TempItemLedgEntry do
                if Find('-') then begin
                    if IsPositiveOutputs then begin
                        RemOutputQty := OutputQty;
                        RemActInvtAdjmtEntryOrder := ActInvtAdjmtEntryOrder;
                        RemNegOutputQty := -(GrossOutputQty - OutputQty);
                        RemNegActInvtAdjmtEntryOrder := ActNegInvtAdjmtEntryOrder;
                    end else begin
                        RemOutputQty := -(GrossOutputQty - OutputQty);
                        RemActInvtAdjmtEntryOrder := ActNegInvtAdjmtEntryOrder;
                        RemNegOutputQty := 0;
                    end;

                    repeat
                        if Positive = IsPositiveOutputs then begin
                            ReversedQty := CalcExactCostReversingQty(TempItemLedgEntry);

                            OldActInvtAdjmtEntryOrder.Init();
                            CalcActualOutputCosts(OldActInvtAdjmtEntryOrder, "Entry No.");

                            NewActInvtAdjmtEntryOrder := RemActInvtAdjmtEntryOrder;
                            if RemOutputQty * (Quantity + ReversedQty) <> 0 then begin
                                // Calculate cost for gross output
                                NewActInvtAdjmtEntryOrder.RoundCosts((Quantity + ReversedQty) / RemOutputQty);

                                RemOutputQty -= (Quantity + ReversedQty);
                                RemActInvtAdjmtEntryOrder.CalcDiff(NewActInvtAdjmtEntryOrder, false);
                                RemActInvtAdjmtEntryOrder.RoundCosts(-1);
                            end else
                                NewActInvtAdjmtEntryOrder.RoundCosts(0);

                            if RemNegOutputQty * ReversedQty <> 0 then begin
                                // Calculate cost for negative output
                                NewNegActInvtAdjmtEntryOrder := RemNegActInvtAdjmtEntryOrder;
                                NewNegActInvtAdjmtEntryOrder.RoundCosts(ReversedQty / RemNegOutputQty);

                                RemNegOutputQty -= ReversedQty;
                                RemNegActInvtAdjmtEntryOrder.CalcDiff(NewNegActInvtAdjmtEntryOrder, false);
                                RemNegActInvtAdjmtEntryOrder.RoundCosts(-1);

                                // Gross + Negative Outputs
                                NewActInvtAdjmtEntryOrder.CalcDiff(NewNegActInvtAdjmtEntryOrder, false);
                                NewActInvtAdjmtEntryOrder.RoundCosts(-1);
                            end;

                            // Compute difference to post
                            NewActInvtAdjmtEntryOrder.CalcDiff(OldActInvtAdjmtEntryOrder, false);
                            NewActInvtAdjmtEntryOrder.RoundCosts(-1);

                            UpdateOutputAdjmtBuf(TempItemLedgEntry, NewActInvtAdjmtEntryOrder, InvtAdjmtBuf);
                            Delete();
                        end;
                    until Next() = 0;
                end;
    end;

    local procedure UpdateOutputAdjmtBuf(ItemLedgerEntry: Record "Item Ledger Entry"; InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var InventoryAdjustmentBuffer: Record "Inventory Adjustment Buffer")
    begin
        OnBeforeUpdateOutputAdjmtBuf(InventoryAdjmtEntryOrder, ItemLedgerEntry, InventoryAdjustmentBuffer);

        with InventoryAdjmtEntryOrder do begin
            if HasNewCost("Direct Cost", "Direct Cost (ACY)") or not "Completely Invoiced" then
                InventoryAdjustmentBuffer.AddCost(
                  ItemLedgerEntry."Entry No.", InventoryAdjustmentBuffer."Entry Type"::"Direct Cost", "Cost Variance Type"::" ", "Direct Cost", "Direct Cost (ACY)");
            if HasNewCost("Indirect Cost", "Indirect Cost (ACY)") then
                InventoryAdjustmentBuffer.AddCost(
                  ItemLedgerEntry."Entry No.", InventoryAdjustmentBuffer."Entry Type"::"Indirect Cost", "Cost Variance Type"::" ", "Indirect Cost", "Indirect Cost (ACY)");

            if Item."Costing Method" <> Item."Costing Method"::Standard then
                exit;

            if HasNewCost("Single-Level Material Cost", "Single-Lvl Material Cost (ACY)") then
                InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
                  InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::Material,
                  "Single-Level Material Cost", "Single-Lvl Material Cost (ACY)");

            if HasNewCost("Single-Level Capacity Cost", "Single-Lvl Capacity Cost (ACY)") then
                InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
                  InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::Capacity,
                  "Single-Level Capacity Cost", "Single-Lvl Capacity Cost (ACY)");

            if HasNewCost("Single-Level Cap. Ovhd Cost", "Single-Lvl Cap. Ovhd Cost(ACY)") then
                InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
                  InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::"Capacity Overhead",
                  "Single-Level Cap. Ovhd Cost", "Single-Lvl Cap. Ovhd Cost(ACY)");

            if HasNewCost("Single-Level Mfg. Ovhd Cost", "Single-Lvl Mfg. Ovhd Cost(ACY)") then
                InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
                  InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::"Manufacturing Overhead",
                  "Single-Level Mfg. Ovhd Cost", "Single-Lvl Mfg. Ovhd Cost(ACY)");

            if HasNewCost("Single-Level Subcontrd. Cost", "Single-Lvl Subcontrd Cost(ACY)") then
                InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
                  InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::Subcontracted,
                  "Single-Level Subcontrd. Cost", "Single-Lvl Subcontrd Cost(ACY)");
        end;

        OnAfterUpdateOutputAdjmtBuf(InventoryAdjmtEntryOrder, ItemLedgerEntry, InventoryAdjustmentBuffer);
    end;

    local procedure CalcStandardCost(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OutputQty: Decimal)
    begin
        if not InvtAdjmtEntryOrder.Find() or not InvtAdjmtEntryOrder."Completely Invoiced" then
            InvtAdjmtEntryOrder.GetCostsFromItem(OutputQty)
        else begin
            InvtAdjmtEntryOrder.RoundCosts(OutputQty);
            InvtAdjmtEntryOrder.CalcDirectCostFromCostShares();
            InvtAdjmtEntryOrder.CalcIndirectCostFromCostShares();
            InvtAdjmtEntryOrder.CalcUnitCost();
        end;
    end;

    local procedure CalcActualOutputCosts(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; ItemLedgerEntryNo: Integer)
    var
        OutputValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddCosts(InvtAdjmtEntryOrder, ItemLedgerEntryNo, IsHandled);
        if IsHandled then
            exit;

        with OutputValueEntry do begin
            SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
            if Find('-') then
                repeat
                    case "Entry Type" of
                        "Entry Type"::"Direct Cost":
                            InvtAdjmtEntryOrder.AddDirectCost("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
                        "Entry Type"::"Indirect Cost":
                            InvtAdjmtEntryOrder.AddIndirectCost("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
                        "Entry Type"::Variance:
                            case "Variance Type" of
                                "Variance Type"::Material:
                                    InvtAdjmtEntryOrder.AddSingleLvlMaterialCost("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
                                "Variance Type"::Capacity:
                                    InvtAdjmtEntryOrder.AddSingleLvlCapacityCost("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
                                "Variance Type"::"Capacity Overhead":
                                    InvtAdjmtEntryOrder.AddSingleLvlCapOvhdCost("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
                                "Variance Type"::"Manufacturing Overhead":
                                    InvtAdjmtEntryOrder.AddSingleLvlMfgOvhdCost("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
                                "Variance Type"::Subcontracted:
                                    InvtAdjmtEntryOrder.AddSingleLvlSubcontrdCost("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
                            end;
                    end;
                until Next() = 0;
        end;
    end;

    local procedure CalcActualMaterialCosts(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        CalcActualMaterialCostQuery: Query "Calculate Actual Material Cost";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcActualMaterialCosts(InvtAdjmtEntryOrder, IsHandled);
        if IsHandled then
            exit;

        CalcActualMaterialCostQuery.SetRange(Order_Type, InvtAdjmtEntryOrder."Order Type");
        CalcActualMaterialCostQuery.SetRange(Order_No_, InvtAdjmtEntryOrder."Order No.");
        CalcActualMaterialCostQuery.SetFilter(Entry_Type, '%1|%2',
                ItemLedgEntry."Entry Type"::Consumption,
                ItemLedgEntry."Entry Type"::"Assembly Consumption");

        CalcActualMaterialCostQuery.SetFilter(Value_Entry_Type, '<>%1', "Cost Entry Type"::Rounding);
        CalcActualMaterialCostQuery.SetRange(Inventoriable, true);

        if InvtAdjmtEntryOrder."Order Type" = InvtAdjmtEntryOrder."Order Type"::Production then
            CalcActualMaterialCostQuery.SetRange(Order_Line_No_, InvtAdjmtEntryOrder."Order Line No.");
        CalcActualMaterialCostQuery.Open();

        OnCalcActualMaterialCostsOnAfterSetFilters(ItemLedgEntry, InvtAdjmtEntryOrder, CalcActualMaterialCostQuery, IsHandled);
        if not IsHandled then
            while CalcActualMaterialCostQuery.Read() do begin
                InvtAdjmtEntryOrder.AddSingleLvlMaterialCost(
                    -CalcActualMaterialCostQuery.Cost_Amount__Actual_,
                    -CalcActualMaterialCostQuery.Cost_Amount__Actual___ACY_
                );
                InvtAdjmtEntryOrder.AddSingleLvlMaterialCost(
                    -CalcActualMaterialCostQuery.Cost_Amount__Non_Invtbl__,
                    -CalcActualMaterialCostQuery.Cost_Amount__Non_Invtbl___ACY_
                );

                if CalcActualMaterialCostQuery.Positive then
                    AdjustForRevNegCon(InvtAdjmtEntryOrder, CalcActualMaterialCostQuery.Entry_No_);
            end;
    end;

    local procedure AdjustForRevNegCon(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; ItemLedgEntryNo: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            SetCurrentKey("Item Ledger Entry No.", "Entry Type");
            SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
            SetRange("Entry Type", "Entry Type"::Revaluation);
            if FindSet() then
                repeat
                    InvtAdjmtEntryOrder.AddSingleLvlMaterialCost("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
                until Next() = 0;
        end;
    end;

    local procedure CalcActualCapacityCosts(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
        ShareOfTotalCapCost: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcActualCapacityCosts(InvtAdjmtEntryOrder, IsHandled);
        if IsHandled then
            exit;

        ShareOfTotalCapCost := CalcShareOfCapCost(InvtAdjmtEntryOrder);

        with CapLedgEntry do begin
            SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Routing No.", "Routing Reference No.");
            SetRange("Order Type", InvtAdjmtEntryOrder."Order Type");
            SetRange("Order No.", InvtAdjmtEntryOrder."Order No.");
            SetRange("Routing No.", InvtAdjmtEntryOrder."Routing No.");
            SetRange("Routing Reference No.", InvtAdjmtEntryOrder."Routing Reference No.");
            SetRange("Item No.", InvtAdjmtEntryOrder."Item No.");
            OnCalcActualCapacityCostsOnAfterSetFilters(CapLedgEntry, InvtAdjmtEntryOrder);
            if Find('-') then
                repeat
                    CalcFields("Direct Cost", "Direct Cost (ACY)", "Overhead Cost", "Overhead Cost (ACY)");
                    if Subcontracting then
                        InvtAdjmtEntryOrder.AddSingleLvlSubcontrdCost("Direct Cost" * ShareOfTotalCapCost, "Direct Cost (ACY)" *
                          ShareOfTotalCapCost)
                    else
                        InvtAdjmtEntryOrder.AddSingleLvlCapacityCost(
                          "Direct Cost" * ShareOfTotalCapCost, "Direct Cost (ACY)" * ShareOfTotalCapCost);
                    InvtAdjmtEntryOrder.AddSingleLvlCapOvhdCost(
                      "Overhead Cost" * ShareOfTotalCapCost, "Overhead Cost (ACY)" * ShareOfTotalCapCost);
                until Next() = 0;
        end;
    end;

    procedure CalcOutputQty(InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OnlyInbounds: Boolean) OutputQty: Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgEntry do begin
            SetCurrentKey("Order Type", "Order No.", "Order Line No.");
            SetRange("Order Type", InvtAdjmtEntryOrder."Order Type");
            SetRange("Order No.", InvtAdjmtEntryOrder."Order No.");
            SetFilter("Entry Type", '%1|%2',
              "Entry Type"::Output,
              "Entry Type"::"Assembly Output");
            if InvtAdjmtEntryOrder."Order Type" = InvtAdjmtEntryOrder."Order Type"::Production then
                SetRange("Order Line No.", InvtAdjmtEntryOrder."Order Line No.");
            OnCalcOutputQtyOnAfterSetFilters(ItemLedgEntry, InvtAdjmtEntryOrder);
            if Find('-') then
                repeat
                    OutputQty += Quantity;
                    if OnlyInbounds and not Positive then
                        OutputQty -= Quantity;
                until Next() = 0;
        end;
    end;

    local procedure CalcShareOfCapCost(InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)") ShareOfCapCost: Decimal
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        if InvtAdjmtEntryOrder."Order Type" = InvtAdjmtEntryOrder."Order Type"::Assembly then
            exit(1);

        with CapLedgEntry do begin
            SetCurrentKey("Order Type", "Order No.");
            SetRange("Order Type", InvtAdjmtEntryOrder."Order Type");
            SetRange("Order No.", InvtAdjmtEntryOrder."Order No.");
            SetRange("Order Line No.", InvtAdjmtEntryOrder."Order Line No.");
            SetRange("Routing No.", InvtAdjmtEntryOrder."Routing No.");
            SetRange("Routing Reference No.", InvtAdjmtEntryOrder."Routing Reference No.");
            SetRange("Item No.", InvtAdjmtEntryOrder."Item No.");
            CalcSums("Output Quantity");
            ShareOfCapCost := "Output Quantity";

            if InvtAdjmtEntryOrder."Order Type" = InvtAdjmtEntryOrder."Order Type"::Production then
                SetRange("Order Line No.");
            CalcSums("Output Quantity");
            if "Output Quantity" <> 0 then
                ShareOfCapCost := ShareOfCapCost / "Output Quantity"
            else
                ShareOfCapCost := 1;
        end;
    end;

    local procedure CopyILEToILE(var FromItemLedgEntry: Record "Item Ledger Entry"; var ToItemLedgEntry: Record "Item Ledger Entry")
    begin
        with ToItemLedgEntry do begin
            Reset();
            DeleteAll();
            if FromItemLedgEntry.FindSet() then
                repeat
                    ToItemLedgEntry := FromItemLedgEntry;
                    Insert();
                until FromItemLedgEntry.Next() = 0;
        end;
    end;

    local procedure OutputItemLedgEntryExist(SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var ToItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        FromItemLedgEntry: Record "Item Ledger Entry";
    begin
        with FromItemLedgEntry do begin
            SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
            SetRange("Order Type", SourceInvtAdjmtEntryOrder."Order Type");
            SetRange("Order No.", SourceInvtAdjmtEntryOrder."Order No.");
            SetFilter("Entry Type", '%1|%2', "Entry Type"::Output, "Entry Type"::"Assembly Output");
            if SourceInvtAdjmtEntryOrder."Order Type" = SourceInvtAdjmtEntryOrder."Order Type"::Production then
                SetRange("Order Line No.", SourceInvtAdjmtEntryOrder."Order Line No.");
            OnOutputItemLedgEntryExistOnAfterSetFilters(FromItemLedgEntry, SourceInvtAdjmtEntryOrder);
            CopyILEToILE(FromItemLedgEntry, ToItemLedgEntry);
            exit(ToItemLedgEntry.FindFirst());
        end;
    end;

    local procedure CalcExactCostReversingQty(ItemLedgEntry: Record "Item Ledger Entry") Qty: Decimal
    var
        OutbndItemLedgEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
        TempItemLedgEntryInChain: Record "Item Ledger Entry" temporary;
    begin
        ItemApplnEntry.GetVisitedEntries(ItemLedgEntry, TempItemLedgEntryInChain, true);
        with TempItemLedgEntryInChain do begin
            SetRange("Order Type", ItemLedgEntry."Order Type");
            SetRange("Order No.", ItemLedgEntry."Order No.");
            SetRange("Order Line No.", ItemLedgEntry."Order Line No.");
            SetRange("Entry Type", ItemLedgEntry."Entry Type");
            SetRange(Positive, false);
            if FindSet() then
                repeat
                    OutbndItemLedgEntry.Get("Entry No.");
                    if OutbndItemLedgEntry."Applies-to Entry" <> 0 then
                        Qty += OutbndItemLedgEntry.Quantity;
                until Next() = 0;
        end;
    end;

    local procedure HasNewCost(NewCost: Decimal; NewCostACY: Decimal): Boolean
    begin
        exit((NewCost <> 0) or (NewCostACY <> 0));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateOutputAdjmtBuf(InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; ItemLedgerEntry: Record "Item Ledger Entry"; var InventoryAdjustmentBuffer: Record "Inventory Adjustment Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOutputAdjmtBuf(InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; ItemLedgerEntry: Record "Item Ledger Entry"; var InventoryAdjustmentBuffer: Record "Inventory Adjustment Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcActualCapacityCosts(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddCosts(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; ItemLedgerEntryNo: Integer; var isHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcActualMaterialCosts(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcActualCapacityCostsOnAfterSetFilters(var CapLedgEntry: Record "Capacity Ledger Entry"; var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcActualMaterialCostsOnAfterSetFilters(var ItemLedgEntry: Record "Item Ledger Entry"; var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var CalculateActualMaterialCost: Query "Calculate Actual Material Cost"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcOutputQtyOnAfterSetFilters(var ItemLedgEntry: Record "Item Ledger Entry"; var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnAfterGetItem(var Item: Record Item; var SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOutputItemLedgEntryExistOnAfterSetFilters(var FromItemLedgEntry: Record "Item Ledger Entry"; var SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;
}

