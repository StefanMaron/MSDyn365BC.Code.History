codeunit 99000855 "Planning-Get Parameters"
{

    trigger OnRun()
    begin
    end;

    var
        GlobalSKU: Record "Stockkeeping Unit";
        Item: Record Item;
        MfgSetup: Record "Manufacturing Setup";
        HasGotMfgSetUp: Boolean;
        LotForLot: Boolean;

    procedure AtSKU(var SKU: Record "Stockkeeping Unit"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        GetMfgSetUp();
        with GlobalSKU do begin
            if (ItemNo <> "Item No.") or
               (VariantCode <> "Variant Code") or
               (LocationCode <> "Location Code")
            then begin
                Clear(GlobalSKU);
                SetRange("Item No.", ItemNo);
                SetRange("Variant Code", VariantCode);
                SetRange("Location Code", LocationCode);
                if not FindFirst() then begin
                    GetItem(ItemNo);
                    "Item No." := ItemNo;
                    "Variant Code" := VariantCode;
                    "Location Code" := LocationCode;
                    CopyFromItem(Item);
                    OnAtSKUOnAfterCopyFromItem(GlobalSKU, Item, ItemNo, VariantCode, LocationCode);
                    if LotForLot then begin
                        "Reorder Point" := 0;
                        "Maximum Inventory" := 0;
                        "Reorder Quantity" := 0;
                        case Item."Reordering Policy" of
                            "Reordering Policy"::" ":
                                "Reordering Policy" := "Reordering Policy"::" ";
                            "Reordering Policy"::Order:
                                "Reordering Policy" := "Reordering Policy"::Order;
                            "Reordering Policy"::"Lot-for-Lot":
                                "Reordering Policy" := "Reordering Policy"::"Lot-for-Lot";
                            else
                                "Reordering Policy" := "Reordering Policy"::"Lot-for-Lot";
                        end;
                        if "Reordering Policy" = "Reordering Policy"::"Lot-for-Lot" then
                            "Include Inventory" := true
                        else
                            "Include Inventory" := Item."Include Inventory";
                        "Minimum Order Quantity" := 0;
                        "Maximum Order Quantity" := 0;
                        "Safety Stock Quantity" := 0;
                        "Order Multiple" := 0;
                        "Overflow Level" := 0;
                    end;
                end;
                SetComponentsAtLocation(LocationCode);
            end;
            if Format("Safety Lead Time") = '' then
                if Format(MfgSetup."Default Safety Lead Time") <> '' then
                    "Safety Lead Time" := MfgSetup."Default Safety Lead Time"
                else
                    Evaluate("Safety Lead Time", '<0D>');
            AdjustInvalidSettings(GlobalSKU);
        end;
        SKU := GlobalSKU;

        OnAfterAtSKU(SKU, GlobalSKU);
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if Item."No." <> ItemNo then
            Item.Get(ItemNo);
    end;

    local procedure GetMfgSetUp()
    begin
        if not HasGotMfgSetUp then
            HasGotMfgSetUp := MfgSetup.Get();
    end;

    local procedure SetComponentsAtLocation(LocationCode: Code[10])
    begin
        if GlobalSKU."Components at Location" = '' then
            if MfgSetup."Components at Location" <> '' then
                GlobalSKU."Components at Location" := MfgSetup."Components at Location"
            else
                GlobalSKU."Components at Location" := LocationCode;
        OnAfterSetComponentsAtLocation(GlobalSKU, Item);
    end;

    procedure SetLotForLot()
    begin
        LotForLot := true;
    end;

#if not CLEAN20
    [Obsolete('Replaced by SetPlanningParameters().', '19.0')]
    procedure SetUpPlanningControls(ReorderingPolicy: Option " ","Fixed Reorder Qty.","Maximum Qty.","Order","Lot-for-Lot"; IncludeInventory: Boolean; var TimeBucketEnabled: Boolean; var SafetyLeadTimeEnabled: Boolean; var SafetyStockQtyEnabled: Boolean; var ReorderPointEnabled: Boolean; var ReorderQuantityEnabled: Boolean; var MaximumInventoryEnabled: Boolean; var MinimumOrderQtyEnabled: Boolean; var MaximumOrderQtyEnabled: Boolean; var OrderMultipleEnabled: Boolean; var IncludeInventoryEnabled: Boolean; var ReschedulingPeriodEnabled: Boolean; var LotAccumulationPeriodEnabled: Boolean; var DampenerPeriodEnabled: Boolean; var DampenerQuantityEnabled: Boolean; var OverflowLevelEnabled: Boolean)
    var
        PlanningParameters: Record "Planning Parameters";
    begin
        PlanningParameters."Include Inventory" := IncludeInventory;
        PlanningParameters."Time Bucket Enabled" := TimeBucketEnabled;
        PlanningParameters."Safety Lead Time Enabled" := SafetyLeadTimeEnabled;
        PlanningParameters."Safety Stock Qty Enabled" := SafetyStockQtyEnabled;
        PlanningParameters."Reorder Point Enabled" := ReorderPointEnabled;
        PlanningParameters."Reorder Quantity Enabled" := ReorderQuantityEnabled;
        PlanningParameters."Maximum Inventory Enabled" := MaximumInventoryEnabled;
        PlanningParameters."Minimum Order Qty Enabled" := MinimumOrderQtyEnabled;
        PlanningParameters."Maximum Order Qty Enabled" := MaximumOrderQtyEnabled;
        PlanningParameters."Order Multiple Enabled" := OrderMultipleEnabled;
        PlanningParameters."Include Inventory Enabled" := IncludeInventoryEnabled;
        PlanningParameters."Rescheduling Period Enabled" := ReschedulingPeriodEnabled;
        PlanningParameters."Lot Accum. Period Enabled" := LotAccumulationPeriodEnabled;
        PlanningParameters."Dampener Period Enabled" := DampenerPeriodEnabled;
        PlanningParameters."Dampener Quantity Enabled" := DampenerQuantityEnabled;
        PlanningParameters."Overflow Level Enabled" := OverflowLevelEnabled;

        SetPlanningParameters(PlanningParameters);

        TimeBucketEnabled := PlanningParameters."Time Bucket Enabled";
        SafetyLeadTimeEnabled := PlanningParameters."Safety Lead Time Enabled";
        SafetyStockQtyEnabled := PlanningParameters."Safety Stock Qty Enabled";
        ReorderPointEnabled := PlanningParameters."Reorder Point Enabled";
        ReorderQuantityEnabled := PlanningParameters."Reorder Quantity Enabled";
        MaximumInventoryEnabled := PlanningParameters."Maximum Inventory Enabled";
        MinimumOrderQtyEnabled := PlanningParameters."Minimum Order Qty Enabled";
        MaximumOrderQtyEnabled := PlanningParameters."Maximum Order Qty Enabled";
        OrderMultipleEnabled := PlanningParameters."Order Multiple Enabled";
        IncludeInventoryEnabled := PlanningParameters."Include Inventory Enabled";
        ReschedulingPeriodEnabled := PlanningParameters."Rescheduling Period Enabled";
        LotAccumulationPeriodEnabled := PlanningParameters."Lot Accum. Period Enabled";
        DampenerPeriodEnabled := PlanningParameters."Dampener Period Enabled";
        DampenerQuantityEnabled := PlanningParameters."Dampener Quantity Enabled";
        OverflowLevelEnabled := PlanningParameters."Overflow Level Enabled";

        OnAfterSetUpPlanningControls(
            ReorderingPolicy, IncludeInventory, TimebucketEnabled, SafetyLeadTimeEnabled, SafetyStockQtyEnabled,
            ReorderPointEnabled, ReorderQuantityEnabled, MaximumInventoryEnabled,
            MinimumOrderQtyEnabled, MaximumOrderQtyEnabled, OrderMultipleEnabled, IncludeInventoryEnabled,
            ReschedulingPeriodEnabled, LotAccumulationPeriodEnabled,
            DampenerPeriodEnabled, DampenerQuantityEnabled, OverflowLevelEnabled);
    end;
#endif

    procedure SetPlanningParameters(var PlanningParameters: Record "Planning Parameters")
    var
        xPlanningParameters: Record "Planning Parameters";
    begin
        xPlanningParameters := PlanningParameters;
        Clear(PlanningParameters);
        PlanningParameters."Reordering Policy" := xPlanningParameters."Reordering Policy";
        PlanningParameters."Include Inventory" := xPlanningParameters."Include Inventory";

        case PlanningParameters."Reordering Policy" of
            "Reordering Policy"::" ":
                PlanningParameters."Safety Lead Time Enabled" := true;
            "Reordering Policy"::"Fixed Reorder Qty.":
                begin
                    PlanningParameters."Time Bucket Enabled" := true;
                    PlanningParameters."Safety Lead Time Enabled" := true;
                    PlanningParameters."Safety Stock Qty Enabled" := true;
                    PlanningParameters."Reorder Point Enabled" := true;
                    PlanningParameters."Reorder Quantity Enabled" := true;
                    PlanningParameters."Maximum Inventory Enabled" := false;
                    PlanningParameters."Minimum Order Qty Enabled" := true;
                    PlanningParameters."Maximum Order Qty Enabled" := true;
                    PlanningParameters."Order Multiple Enabled" := true;
                    PlanningParameters."Include Inventory Enabled" := false;
                    PlanningParameters."Rescheduling Period Enabled" := false;
                    PlanningParameters."Lot Accum. Period Enabled" := false;
                    PlanningParameters."Dampener Period Enabled" := false;
                    PlanningParameters."Dampener Quantity Enabled" := true;
                    PlanningParameters."Overflow Level Enabled" := true;
                end;
            "Reordering Policy"::"Maximum Qty.":
                begin
                    PlanningParameters."Time Bucket Enabled" := true;
                    PlanningParameters."Safety Lead Time Enabled" := true;
                    PlanningParameters."Safety Stock Qty Enabled" := true;
                    PlanningParameters."Reorder Point Enabled" := true;
                    PlanningParameters."Reorder Quantity Enabled" := false;
                    PlanningParameters."Maximum Inventory Enabled" := true;
                    PlanningParameters."Minimum Order Qty Enabled" := true;
                    PlanningParameters."Maximum Order Qty Enabled" := true;
                    PlanningParameters."Order Multiple Enabled" := true;
                    PlanningParameters."Include Inventory Enabled" := false;
                    PlanningParameters."Rescheduling Period Enabled" := false;
                    PlanningParameters."Lot Accum. Period Enabled" := false;
                    PlanningParameters."Dampener Period Enabled" := false;
                    PlanningParameters."Dampener Quantity Enabled" := true;
                    PlanningParameters."Overflow Level Enabled" := true;
                end;
            "Reordering Policy"::Order:
                begin
                    PlanningParameters."Time Bucket Enabled" := false;
                    PlanningParameters."Safety Lead Time Enabled" := true;
                    PlanningParameters."Safety Stock Qty Enabled" := false;
                    PlanningParameters."Reorder Point Enabled" := false;
                    PlanningParameters."Reorder Quantity Enabled" := false;
                    PlanningParameters."Maximum Inventory Enabled" := false;
                    PlanningParameters."Minimum Order Qty Enabled" := false;
                    PlanningParameters."Maximum Order Qty Enabled" := false;
                    PlanningParameters."Order Multiple Enabled" := false;
                    PlanningParameters."Include Inventory Enabled" := false;
                    PlanningParameters."Rescheduling Period Enabled" := false;
                    PlanningParameters."Lot Accum. Period Enabled" := false;
                    PlanningParameters."Dampener Period Enabled" := true;
                    PlanningParameters."Dampener Quantity Enabled" := false;
                    PlanningParameters."Overflow Level Enabled" := false;
                end;
            "Reordering Policy"::"Lot-for-Lot":
                begin
                    PlanningParameters."Time Bucket Enabled" := false;
                    PlanningParameters."Safety Lead Time Enabled" := true;
                    PlanningParameters."Safety Stock Qty Enabled" := xPlanningParameters."Include Inventory";
                    PlanningParameters."Reorder Point Enabled" := false;
                    PlanningParameters."Reorder Quantity Enabled" := false;
                    PlanningParameters."Maximum Inventory Enabled" := false;
                    PlanningParameters."Minimum Order Qty Enabled" := true;
                    PlanningParameters."Maximum Order Qty Enabled" := true;
                    PlanningParameters."Order Multiple Enabled" := true;
                    PlanningParameters."Include Inventory Enabled" := true;
                    PlanningParameters."Rescheduling Period Enabled" := true;
                    PlanningParameters."Lot Accum. Period Enabled" := true;
                    PlanningParameters."Dampener Period Enabled" := true;
                    PlanningParameters."Dampener Quantity Enabled" := true;
                    PlanningParameters."Overflow Level Enabled" := false;
                end;
            else
                OnSetPlanningParametersOnReorderingPolicyElseCase(PlanningParameters);
        end;

        OnAfterSetPlanningParameters(PlanningParameters, xPlanningParameters);
    end;

    procedure AdjustInvalidSettings(var SKU: Record "Stockkeeping Unit")
    var
        PlanningParameters: Record "Planning Parameters";
    begin
        PlanningParameters."Reordering Policy" := SKU."Reordering Policy";
        PlanningParameters."Include Inventory" := SKU."Include Inventory";

        SetPlanningParameters(PlanningParameters);

        if not PlanningParameters."Time Bucket Enabled" then
            Evaluate(SKU."Time Bucket", '<0D>');
        if not PlanningParameters."Safety Lead Time Enabled" then
            Evaluate(SKU."Safety Lead Time", '<0D>');
        if not PlanningParameters."Safety Stock Qty Enabled" then
            SKU."Safety Stock Quantity" := 0;
        if not PlanningParameters."Reorder Point Enabled" then
            SKU."Reorder Point" := 0;
        if not PlanningParameters."Reorder Quantity Enabled" then
            SKU."Reorder Quantity" := 0;
        if not PlanningParameters."Maximum Inventory Enabled" then
            SKU."Maximum Inventory" := 0;
        if not PlanningParameters."Minimum Order Qty Enabled" then
            SKU."Minimum Order Quantity" := 0;
        if not PlanningParameters."Maximum Order Qty Enabled" then
            SKU."Maximum Order Quantity" := 0;
        if not PlanningParameters."Order Multiple Enabled" then
            SKU."Order Multiple" := 0;
        if not PlanningParameters."Rescheduling Period Enabled" then
            Evaluate(SKU."Rescheduling Period", '<0D>');
        if not PlanningParameters."Lot Accum. Period Enabled" then
            Evaluate(SKU."Lot Accumulation Period", '<0D>');
        if not PlanningParameters."Dampener Period Enabled" then
            Evaluate(SKU."Dampener Period", '<0D>');
        if not PlanningParameters."Dampener Quantity Enabled" then
            SKU."Dampener Quantity" := 0;
        if not PlanningParameters."Overflow Level Enabled" then
            SKU."Overflow Level" := 0;

        AdjustInvalidValues(SKU, PlanningParameters."Reorder Point Enabled");

        OnAfterAdjustInvalidSettings(SKU, PlanningParameters);
    end;

    local procedure AdjustInvalidValues(var SKU: Record "Stockkeeping Unit"; ReorderPointEnabled: Boolean)
    begin
        if SKU."Reorder Point" < 0 then
            SKU."Reorder Point" := 0;

        if SKU."Safety Stock Quantity" < 0 then
            SKU."Safety Stock Quantity" := 0;

        if (SKU."Reorder Point" < SKU."Safety Stock Quantity") and
           ReorderPointEnabled
        then
            SKU."Reorder Point" := SKU."Safety Stock Quantity";

        if SKU."Maximum Order Quantity" < 0 then
            SKU."Maximum Order Quantity" := 0;

        if SKU."Minimum Order Quantity" < 0 then
            SKU."Minimum Order Quantity" := 0;

        if SKU."Maximum Order Quantity" <> 0 then
            if SKU."Maximum Order Quantity" < SKU."Minimum Order Quantity" then
                SKU."Maximum Order Quantity" := SKU."Minimum Order Quantity";

        if (SKU."Maximum Inventory" < SKU."Safety Stock Quantity") or
           (SKU."Maximum Inventory" < SKU."Reorder Point")
        then
            SKU."Maximum Inventory" := 0;

        if SKU."Overflow Level" <> 0 then
            case SKU."Reordering Policy" of
                SKU."Reordering Policy"::"Fixed Reorder Qty.":
                    if SKU."Overflow Level" < (SKU."Reorder Point" + SKU."Reorder Quantity") then
                        SKU."Overflow Level" := SKU."Reorder Point" + SKU."Reorder Quantity";
                SKU."Reordering Policy"::"Maximum Qty.":
                    if SKU."Overflow Level" < SKU."Maximum Inventory" then
                        SKU."Overflow Level" := SKU."Maximum Inventory";
            end;
    end;

    procedure CalcDampenerDays(SKU: Record "Stockkeeping Unit") DampenerDays: Integer
    begin
        if Format(SKU."Dampener Period") = '' then begin
            GetMfgSetUp();
            DampenerDays := CalcDate(MfgSetup."Default Dampener Period") - Today;
        end else
            DampenerDays := CalcDate(SKU."Dampener Period") - Today;

        // The Dampener Period must not be less than the Lot Accumulation Period unless
        // the Reordering Policy is order
        if SKU."Reordering Policy" <> SKU."Reordering Policy"::Order then
            if DampenerDays > CalcDate(SKU."Lot Accumulation Period") - Today then
                DampenerDays := CalcDate(SKU."Lot Accumulation Period") - Today;
    end;

    procedure CalcDampenerQty(SKU: Record "Stockkeeping Unit") DampenerQty: Decimal
    begin
        if SKU."Reordering Policy" <> SKU."Reordering Policy"::Order then
            if SKU."Dampener Quantity" = 0 then begin
                GetMfgSetUp();
                DampenerQty := SKU."Lot Size" * MfgSetup."Default Dampener %" / 100;
            end else
                DampenerQty := SKU."Dampener Quantity"
        else
            DampenerQty := 0;
    end;

    procedure CalcOverflowLevel(SKU: Record "Stockkeeping Unit") WarningLevel: Decimal
    begin
        if SKU."Overflow Level" <> 0 then
            WarningLevel := SKU."Overflow Level"
        else begin
            GetMfgSetUp();
            if MfgSetup."Blank Overflow Level" = MfgSetup."Blank Overflow Level"::"Allow Default Calculation" then begin
                case SKU."Reordering Policy" of
                    SKU."Reordering Policy"::"Maximum Qty.":
                        WarningLevel := SKU."Maximum Inventory" + SKU."Minimum Order Quantity";
                    SKU."Reordering Policy"::"Fixed Reorder Qty.":
                        begin
                            if SKU."Minimum Order Quantity" > SKU."Reorder Quantity" then
                                WarningLevel := SKU."Minimum Order Quantity"
                            else
                                WarningLevel := SKU."Reorder Quantity";
                            WarningLevel += SKU."Reorder Point";
                        end
                    else
                        WarningLevel := 0;
                end;
                if SKU."Order Multiple" > 0 then
                    WarningLevel := Round(WarningLevel, SKU."Order Multiple", '>');
            end else
                WarningLevel := 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAdjustInvalidSettings(var StockkeepingUnit: Record "Stockkeeping Unit"; var PlanningParameters: Record "Planning Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAtSKU(var SKU: Record "Stockkeeping Unit"; var GlobalSKU: Record "Stockkeeping Unit");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAtSKUOnAfterCopyFromItem(var GlobalSKU: Record "Stockkeeping Unit"; var Item: Record Item; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
    end;

#if not CLEAN20
    [Obsolete('Replaced by event OnAfterSetPlanningParameters()', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpPlanningControls(ReorderingPolicy: Option " ","Fixed Reorder Qty.","Maximum Qty.","Order","Lot-for-Lot"; IncludeInventory: Boolean; var TimeBucketEnabled: Boolean; var SafetyLeadTimeEnabled: Boolean; var SafetyStockQtyEnabled: Boolean; var ReorderPointEnabled: Boolean; var ReorderQuantityEnabled: Boolean; var MaximumInventoryEnabled: Boolean; var MinimumOrderQtyEnabled: Boolean; var MaximumOrderQtyEnabled: Boolean; var OrderMultipleEnabled: Boolean; var IncludeInventoryEnabled: Boolean; var ReschedulingPeriodEnabled: Boolean; var LotAccumulationPeriodEnabled: Boolean; var DampenerPeriodEnabled: Boolean; var DampenerQuantityEnabled: Boolean; var OverflowLevelEnabled: Boolean);
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPlanningParameters(PlanningParameters: Record "Planning Parameters"; xPlanningParameters: Record "Planning Parameters");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetComponentsAtLocation(var GlobalStockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetPlanningParametersOnReorderingPolicyElseCase(var PlanningParameters: Record "Planning Parameters")
    begin
    end;
}

