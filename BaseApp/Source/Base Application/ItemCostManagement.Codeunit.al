codeunit 5804 ItemCostManagement
{
    Permissions = TableData Item = rm,
                  TableData "Stockkeeping Unit" = rm,
                  TableData "Value Entry" = r;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        InvtSetup: Record "Inventory Setup";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        InvoicedQty: Decimal;
        RndgSetupRead: Boolean;
        CalledFromAdjustment: Boolean;
        InvtSetupRead: Boolean;
        GLSetupRead: Boolean;

    procedure UpdateUnitCost(var Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; LastDirectCost: Decimal; NewStdCost: Decimal; UpdateSKU: Boolean; FilterSKU: Boolean; RecalcStdCost: Boolean; CalledByFieldNo: Integer)
    var
        CheckItem: Record Item;
        AverageCost: Decimal;
        AverageCostACY: Decimal;
        UnitCostUpdated: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeUpdateUnitCost(
          Item, LocationCode, VariantCode, LastDirectCost, NewStdCost, UpdateSKU, FilterSKU, RecalcStdCost, CalledByFieldNo, UnitCostUpdated);
        if UnitCostUpdated then
            exit;

        with Item do begin
            if NewStdCost <> 0 then
                "Standard Cost" := NewStdCost;

            if "Costing Method" = "Costing Method"::Standard then
                "Unit Cost" := "Standard Cost"
            else
                if CalledFromAdjustment then begin
                    CostCalcMgt.GetRndgSetup(GLSetup, Currency, RndgSetupRead);
                    if CalculateAverageCost(Item, AverageCost, AverageCostACY) then begin
                        if AverageCost <> 0 then
                            "Unit Cost" := Round(AverageCost, GLSetup."Unit-Amount Rounding Precision");
                    end else begin
                        CalcLastAdjEntryAvgCost(Item, AverageCost, AverageCostACY);
                        if AverageCost <> 0 then
                            "Unit Cost" := Round(AverageCost, GLSetup."Unit-Amount Rounding Precision");
                    end;
                end else
                    if ("Unit Cost" = 0) or ((InvoicedQty > 0) and (LastDirectCost <> 0)) then begin
                        CalcFields("Net Invoiced Qty.");
                        IsHandled := false;
                        OnUpdateUnitCostOnBeforeNetInvoiceQtyCheck(Item, IsHandled);
                        if ("Net Invoiced Qty." > 0) and ("Net Invoiced Qty." <= InvoicedQty) and not IsHandled then
                            "Unit Cost" := LastDirectCost;
                    end;

            if RecalcStdCost then
                RecalcStdCostItem(Item);

            if LastDirectCost <> 0 then
                "Last Direct Cost" := LastDirectCost;

            IsHandled := false;
            OnUpdateUnitCostOnBeforeValidatePriceProfitCalculation(Item, IsHandled);
            if not IsHandled then
                Validate("Price/Profit Calculation");

            if CheckItem.Get("No.") then
                if CalledByFieldNo <> 0 then
                    Modify(true)
                else
                    Modify;

            OnUpdateUnitCostOnBeforeUpdateSKU(Item, UpdateSKU);
            if UpdateSKU then
                FindUpdateUnitCostSKU(Item, LocationCode, VariantCode, FilterSKU, LastDirectCost);
        end;
    end;

    procedure UpdateStdCostShares(FromItem: Record Item)
    var
        Item: Record Item;
    begin
        with FromItem do begin
            Item.Get("No.");
            Item.Validate("Standard Cost", "Standard Cost");
            Item."Single-Level Material Cost" := "Single-Level Material Cost";
            Item."Single-Level Capacity Cost" := "Single-Level Capacity Cost";
            Item."Single-Level Subcontrd. Cost" := "Single-Level Subcontrd. Cost";
            Item."Single-Level Cap. Ovhd Cost" := "Single-Level Cap. Ovhd Cost";
            Item."Single-Level Mfg. Ovhd Cost" := "Single-Level Mfg. Ovhd Cost";
            Item."Rolled-up Material Cost" := "Rolled-up Material Cost";
            Item."Rolled-up Capacity Cost" := "Rolled-up Capacity Cost";
            Item."Rolled-up Subcontracted Cost" := "Rolled-up Subcontracted Cost";
            Item."Rolled-up Mfg. Ovhd Cost" := "Rolled-up Mfg. Ovhd Cost";
            Item."Rolled-up Cap. Overhead Cost" := "Rolled-up Cap. Overhead Cost";
            Item."Last Unit Cost Calc. Date" := "Last Unit Cost Calc. Date";
            OnUpdateStdCostSharesOnAfterCopyCosts(Item, FromItem);
            Item.Modify();
        end;
    end;

    procedure UpdateUnitCostSKU(Item: Record Item; var SKU: Record "Stockkeeping Unit"; LastDirectCost: Decimal; NewStdCost: Decimal; MatchSKU: Boolean; CalledByFieldNo: Integer)
    var
        ValueEntry: Record "Value Entry";
        AverageCost: Decimal;
        AverageCostACY: Decimal;
        UnitCostUpdated: Boolean;
    begin
        OnBeforeUpdateUnitCostSKU(Item, SKU, LastDirectCost, NewStdCost, MatchSKU, CalledByFieldNo, UnitCostUpdated);
        if UnitCostUpdated then
            exit;

        with SKU do begin
            if NewStdCost <> 0 then
                "Standard Cost" := NewStdCost;
            if Item."Costing Method" <> Item."Costing Method"::Standard then begin
                GetInvtSetup;
                if InvtSetup."Average Cost Calc. Type" <> InvtSetup."Average Cost Calc. Type"::Item then begin
                    if CalledFromAdjustment then begin
                        ValueEntry."Item No." := Item."No.";
                        ValueEntry."Valuation Date" := DMY2Date(31, 12, 9999);
                        ValueEntry."Location Code" := "Location Code";
                        ValueEntry."Variant Code" := "Variant Code";
                        ValueEntry.SumCostsTillValuationDate(ValueEntry);
                        if ValueEntry."Item Ledger Entry Quantity" <> 0 then begin
                            AverageCost :=
                              (ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)") /
                              ValueEntry."Item Ledger Entry Quantity";
                            if AverageCost < 0 then
                                AverageCost := 0;
                        end else begin
                            Item.SetRange("Location Filter", "Location Code");
                            Item.SetRange("Variant Filter", "Variant Code");
                            CalcLastAdjEntryAvgCost(Item, AverageCost, AverageCostACY);
                        end;
                        if AverageCost <> 0 then
                            "Unit Cost" := Round(AverageCost, GLSetup."Unit-Amount Rounding Precision");
                    end else
                        if ("Unit Cost" = 0) or ((InvoicedQty > 0) and MatchSKU and (LastDirectCost <> 0)) then begin
                            Item.SetRange("Location Filter", "Location Code");
                            Item.SetRange("Variant Filter", "Variant Code");
                            Item.CalcFields("Net Invoiced Qty.");
                            Item.SetRange("Location Filter");
                            Item.SetRange("Variant Filter");
                            if (Item."Net Invoiced Qty." > 0) and (Item."Net Invoiced Qty." <= InvoicedQty) then
                                "Unit Cost" := LastDirectCost;
                        end;
                end else
                    "Unit Cost" := Item."Unit Cost";
            end else
                "Unit Cost" := "Standard Cost";

            OnUpdateUnitCostSKUOnBeforeMatchSKU(SKU, Item);
            if MatchSKU and (LastDirectCost <> 0) then
                "Last Direct Cost" := LastDirectCost;

            if CalledByFieldNo <> 0 then
                Modify(true)
            else
                Modify;
        end;
    end;

    local procedure RecalcStdCostItem(var Item: Record Item)
    begin
        with Item do begin
            "Single-Level Material Cost" := "Standard Cost";
            "Single-Level Mfg. Ovhd Cost" := 0;
            "Single-Level Capacity Cost" := 0;
            "Single-Level Subcontrd. Cost" := 0;
            "Single-Level Cap. Ovhd Cost" := 0;
            "Rolled-up Material Cost" := "Standard Cost";
            "Rolled-up Mfg. Ovhd Cost" := 0;
            "Rolled-up Capacity Cost" := 0;
            "Rolled-up Subcontracted Cost" := 0;
            "Rolled-up Cap. Overhead Cost" := 0;
        end;
    end;

    local procedure CalcLastAdjEntryAvgCost(var Item: Record Item; var AverageCost: Decimal; var AverageCostACY: Decimal)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        ComputeThisEntry: Boolean;
        IsSubOptimal: Boolean;
        AvgCostCalculated: Boolean;
    begin
        OnBeforeCalcLastAdjEntryAvgCost(Item, AverageCost, AverageCostACY, AvgCostCalculated);
        if AvgCostCalculated then
            exit;

        AverageCost := 0;
        AverageCostACY := 0;

        if CalculateQuantity(Item) <> 0 then
            exit;
        if not HasOpenEntries(Item) then
            exit;

        with ValueEntry do begin
            SetFilters(ValueEntry, Item);
            if Find('+') then
                repeat
                    ComputeThisEntry := ("Item Ledger Entry Quantity" < 0) and not Adjustment and not "Drop Shipment";
                    if ComputeThisEntry then begin
                        ItemLedgEntry.Get("Item Ledger Entry No.");
                        IsSubOptimal :=
                          ItemLedgEntry.Correction or
                          ((Item."Costing Method" = Item."Costing Method"::Average) and not "Valued By Average Cost");

                        if not IsSubOptimal or (IsSubOptimal and (AverageCost = 0)) then begin
                            ItemLedgEntry.CalcFields(
                              "Cost Amount (Expected)", "Cost Amount (Actual)",
                              "Cost Amount (Expected) (ACY)", "Cost Amount (Actual) (ACY)");
                            AverageCost :=
                              (ItemLedgEntry."Cost Amount (Expected)" +
                               ItemLedgEntry."Cost Amount (Actual)") /
                              ItemLedgEntry.Quantity;
                            AverageCostACY :=
                              (ItemLedgEntry."Cost Amount (Expected) (ACY)" +
                               ItemLedgEntry."Cost Amount (Actual) (ACY)") /
                              ItemLedgEntry.Quantity;

                            OnCalcLastAdjEntryAvgCostOnAfterCalcAverageCost(ItemLedgEntry, ValueEntry, Item, AverageCost, AverageCostACY);
                            if (AverageCost <> 0) and not IsSubOptimal then
                                exit;
                        end;
                    end;
                until Next(-1) = 0;
        end;
    end;

    procedure CalculateAverageCost(var Item: Record Item; var AverageCost: Decimal; var AverageCostACY: Decimal): Boolean
    var
        AverageQty: Decimal;
        CostAmt: Decimal;
        CostAmtACY: Decimal;
        NeedCalcPreciseAmt: Boolean;
        NeedCalcPreciseAmtACY: Boolean;
        AvgCostCalculated: Boolean;
    begin
        OnBeforeCalculateAverageCost(Item, AverageCost, AverageCostACY, AvgCostCalculated);
        if AvgCostCalculated then
            exit;

        AverageCost := 0;
        AverageCostACY := 0;

        if CalledFromAdjustment then
            ExcludeOpenOutbndCosts(Item, AverageCost, AverageCostACY, AverageQty);
        AverageQty := AverageQty + CalculateQuantity(Item);

        if AverageQty <> 0 then begin
            CostAmt := AverageCost + CalculateCostAmt(Item, true) + CalculateCostAmt(Item, false);
            if (CostAmt > 0) and (CostAmt = GLSetup."Amount Rounding Precision") then
                NeedCalcPreciseAmt := true;

            GetGLSetup;
            if GLSetup."Additional Reporting Currency" <> '' then begin
                Currency.Get(GLSetup."Additional Reporting Currency");
                CostAmtACY := AverageCostACY + CalculateCostAmtACY(Item, true) + CalculateCostAmtACY(Item, false);
                if (CostAmtACY > 0) and (CostAmtACY = Currency."Amount Rounding Precision") then
                    NeedCalcPreciseAmtACY := true;
            end;

            if NeedCalcPreciseAmt or NeedCalcPreciseAmtACY then
                CalculatePreciseCostAmounts(Item, NeedCalcPreciseAmt, NeedCalcPreciseAmtACY, CostAmt, CostAmtACY);

            AverageCost := CostAmt / AverageQty;
            AverageCostACY := CostAmtACY / AverageQty;

            if AverageCost < 0 then
                AverageCost := 0;
            if AverageCostACY < 0 then
                AverageCostACY := 0;
        end else begin
            AverageCost := 0;
            AverageCostACY := 0;
        end;
        if AverageQty <= 0 then
            exit(false);

        exit(true);
    end;

    procedure SetFilters(var ValueEntry: Record "Value Entry"; var Item: Record Item)
    begin
        with ValueEntry do begin
            Reset;
            SetCurrentKey("Item No.", "Valuation Date", "Location Code", "Variant Code");
            SetRange("Item No.", Item."No.");
            SetFilter("Valuation Date", Item.GetFilter("Date Filter"));
            SetFilter("Location Code", Item.GetFilter("Location Filter"));
            SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        end;
        OnAfterSetFilters(ValueEntry, Item);
    end;

    local procedure CalculateQuantity(var Item: Record Item) CalcQty: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            SetFilters(ValueEntry, Item);
            CalcSums("Item Ledger Entry Quantity");
            CalcQty := "Item Ledger Entry Quantity";
            OnAfterCalculateQuantity(ValueEntry, Item, CalcQty);
            exit(CalcQty);
        end;
    end;

    local procedure CalculateCostAmt(var Item: Record Item; Actual: Boolean) CostAmount: Decimal
    var
        ValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateCostAmount(Item, Actual, CostAmount, IsHandled);
        if IsHandled then
            exit(CostAmount);

        with ValueEntry do begin
            SetFilters(ValueEntry, Item);
            if Actual then begin
                CalcSums("Cost Amount (Actual)");
                exit("Cost Amount (Actual)");
            end;
            CalcSums("Cost Amount (Expected)");
            exit("Cost Amount (Expected)");
        end;
    end;

    local procedure CalculateCostAmtACY(var Item: Record Item; Actual: Boolean): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            SetFilters(ValueEntry, Item);
            if Actual then begin
                CalcSums("Cost Amount (Actual) (ACY)");
                exit("Cost Amount (Actual) (ACY)");
            end;
            CalcSums("Cost Amount (Expected) (ACY)");
            exit("Cost Amount (Expected) (ACY)");
        end;
    end;

    local procedure CalculatePreciseCostAmounts(var Item: Record Item; NeedCalcPreciseAmt: Boolean; NeedCalcPreciseAmtACY: Boolean; var PreciseAmt: Decimal; var PreciseAmtACY: Decimal)
    var
        OpenInbndItemLedgEntry: Record "Item Ledger Entry";
        OpenOutbndItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        // Collect precise (not rounded) remaining cost on:
        // 1. open inbound item ledger entries;
        // 2. closed inbound item ledger entries the open outbound item entries are applied to.
        PreciseAmt := 0;
        PreciseAmtACY := 0;

        OpenInbndItemLedgEntry.SetRange("Item No.", Item."No.");
        OpenInbndItemLedgEntry.SetRange(Open, true);
        OpenInbndItemLedgEntry.SetRange(Positive, true);
        OpenInbndItemLedgEntry.SetRange("Location Code", Item.GetFilter("Location Filter"));
        OpenInbndItemLedgEntry.SetRange("Variant Code", Item.GetFilter("Variant Filter"));
        if OpenInbndItemLedgEntry.FindSet() then
            repeat
                TempItemLedgerEntry := OpenInbndItemLedgEntry;
                TempItemLedgerEntry.Insert();
            until OpenInbndItemLedgEntry.Next() = 0;

        OpenOutbndItemLedgEntry.CopyFilters(OpenInbndItemLedgEntry);
        OpenOutbndItemLedgEntry.SetRange(Positive, false);
        if OpenOutbndItemLedgEntry.FindSet() then
            repeat
                if ItemApplicationEntry.GetInboundEntriesTheOutbndEntryAppliedTo(OpenOutbndItemLedgEntry."Entry No.") then
                    repeat
                        if TempItemLedgerEntry.Get(ItemApplicationEntry."Inbound Item Entry No.") then begin
                            TempItemLedgerEntry."Remaining Quantity" -= ItemApplicationEntry.Quantity;
                            TempItemLedgerEntry.Modify();
                        end else begin
                            OpenInbndItemLedgEntry.Get(ItemApplicationEntry."Inbound Item Entry No.");
                            TempItemLedgerEntry := OpenInbndItemLedgEntry;
                            TempItemLedgerEntry."Remaining Quantity" := -ItemApplicationEntry.Quantity;
                            TempItemLedgerEntry.Insert();
                        end;
                    until ItemApplicationEntry.Next() = 0;
            until OpenOutbndItemLedgEntry.Next() = 0;

        with TempItemLedgerEntry do begin
            Reset();
            if FindSet then
                repeat
                    if NeedCalcPreciseAmt then begin
                        CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
                        PreciseAmt += ("Cost Amount (Actual)" + "Cost Amount (Expected)") / Quantity * "Remaining Quantity";
                    end;
                    if NeedCalcPreciseAmtACY then begin
                        CalcFields("Cost Amount (Actual) (ACY)", "Cost Amount (Expected) (ACY)");
                        PreciseAmtACY += ("Cost Amount (Actual) (ACY)" + "Cost Amount (Expected) (ACY)") / Quantity * "Remaining Quantity";
                    end;
                until Next = 0;
        end;
    end;

    local procedure ExcludeOpenOutbndCosts(var Item: Record Item; var CostAmt: Decimal; var CostAmtACY: Decimal; var Quantity: Decimal)
    var
        OpenItemLedgEntry: Record "Item Ledger Entry";
        OpenValueEntry: Record "Value Entry";
    begin
        with OpenValueEntry do begin
            OpenItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive);
            OpenItemLedgEntry.SetRange("Item No.", Item."No.");
            OpenItemLedgEntry.SetRange(Open, true);
            OpenItemLedgEntry.SetRange(Positive, false);
            OpenItemLedgEntry.SetFilter("Location Code", Item.GetFilter("Location Filter"));
            OpenItemLedgEntry.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
            SetCurrentKey("Item Ledger Entry No.");
            if OpenItemLedgEntry.Find('-') then
                repeat
                    SetRange("Item Ledger Entry No.", OpenItemLedgEntry."Entry No.");
                    if Find('-') then
                        repeat
                            CostAmt := CostAmt - "Cost Amount (Actual)" - "Cost Amount (Expected)";
                            CostAmtACY := CostAmtACY - "Cost Amount (Actual) (ACY)" - "Cost Amount (Expected) (ACY)";
                            Quantity := Quantity - "Item Ledger Entry Quantity";
                        until Next = 0;
                until OpenItemLedgEntry.Next = 0;
        end;
    end;

    local procedure HasOpenEntries(var Item: Record Item): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgEntry do begin
            Reset;
            SetCurrentKey("Item No.", Open);
            SetRange("Item No.", Item."No.");
            SetRange(Open, true);
            SetFilter("Location Code", Item.GetFilter("Location Filter"));
            SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
            exit(not FindFirst)
        end;
    end;

    procedure SetProperties(NewCalledFromAdjustment: Boolean; NewInvoicedQty: Decimal)
    begin
        CalledFromAdjustment := NewCalledFromAdjustment;
        InvoicedQty := NewInvoicedQty;
    end;

    local procedure GetInvtSetup()
    begin
        if not InvtSetupRead then
            InvtSetup.Get();
        InvtSetupRead := true;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    procedure FindUpdateUnitCostSKU(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; FilterSKU: Boolean; LastDirectCost: Decimal)
    var
        SKU: Record "Stockkeeping Unit";
    begin
        GetInvtSetup;
        with SKU do begin
            SetRange("Item No.", Item."No.");
            if InvtSetup."Average Cost Calc. Type" <> InvtSetup."Average Cost Calc. Type"::Item then
                if FilterSKU then begin
                    SetFilter("Location Code", '%1|%2', '', LocationCode);
                    SetFilter("Variant Code", '%1|%2', '', VariantCode);
                end else begin
                    SetFilter("Location Code", Item.GetFilter("Location Filter"));
                    SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                end;
            if Find('-') then
                repeat
                    UpdateUnitCostSKU(
                      Item, SKU, LastDirectCost, 0,
                      ("Location Code" = LocationCode) and ("Variant Code" = VariantCode), 0);
                until Next = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateQuantity(var ValueEntry: Record "Value Entry"; var Item: Record Item; var CalcQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var ValueEntry: Record "Value Entry"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLastAdjEntryAvgCost(var Item: Record Item; var AverageCost: Decimal; var AverageCostACY: Decimal; var AvgCostCalculated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateCostAmount(var Item: Record Item; Actual: Boolean; var CostAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateAverageCost(var Item: Record Item; var AverageCost: Decimal; var AverageCostACY: Decimal; var AvgCostCalculated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCost(var Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; LastDirectCost: Decimal; NewStdCost: Decimal; UpdateSKU: Boolean; FilterSKU: Boolean; RecalcStdCost: Boolean; CalledByFieldNo: Integer; var UnitCostUpdated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCostSKU(Item: Record Item; var SKU: Record "Stockkeeping Unit"; LastDirectCost: Decimal; NewStdCost: Decimal; MatchSKU: Boolean; CalledByFieldNo: Integer; var UnitCostUpdated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLastAdjEntryAvgCostOnAfterCalcAverageCost(ItemLedgEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry"; var Item: Record Item; var AverageCost: Decimal; var AverageCostACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnBeforeNetInvoiceQtyCheck(Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnBeforeUpdateSKU(var Item: Record Item; var UpdateSKU: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnBeforeValidatePriceProfitCalculation(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostSKUOnBeforeMatchSKU(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateStdCostSharesOnAfterCopyCosts(var Item: Record Item; FromItem: Record Item)
    begin
    end;
}

