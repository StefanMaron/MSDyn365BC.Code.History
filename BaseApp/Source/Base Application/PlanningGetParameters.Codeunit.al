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
        GetMfgSetUp;
        with GlobalSKU do begin
            if (ItemNo <> "Item No.") or
               (VariantCode <> "Variant Code") or
               (LocationCode <> "Location Code")
            then begin
                Clear(GlobalSKU);
                SetRange("Item No.", ItemNo);
                SetRange("Variant Code", VariantCode);
                SetRange("Location Code", LocationCode);
                if not FindFirst then begin
                    GetItem(ItemNo);
                    "Item No." := ItemNo;
                    "Variant Code" := VariantCode;
                    "Location Code" := LocationCode;
                    CopyFromItem(Item);
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
                if "Components at Location" = '' then begin
                    if MfgSetup."Components at Location" <> '' then
                        "Components at Location" := MfgSetup."Components at Location"
                    else
                        "Components at Location" := LocationCode;
                end;
            end;
            if Format("Safety Lead Time") = '' then
                if Format(MfgSetup."Default Safety Lead Time") <> '' then
                    "Safety Lead Time" := MfgSetup."Default Safety Lead Time"
                else
                    Evaluate("Safety Lead Time", '<0D>');
            AdjustInvalidSettings(GlobalSKU);
        end;
        SKU := GlobalSKU;
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

    procedure SetLotForLot()
    begin
        LotForLot := true;
    end;

    procedure SetUpPlanningControls(ReorderingPolicy: Option " ","Fixed Reorder Qty.","Maximum Qty.","Order","Lot-for-Lot"; IncludeInventory: Boolean; var TimeBucketEnabled: Boolean; var SafetyLeadTimeEnabled: Boolean; var SafetyStockQtyEnabled: Boolean; var ReorderPointEnabled: Boolean; var ReorderQuantityEnabled: Boolean; var MaximumInventoryEnabled: Boolean; var MinimumOrderQtyEnabled: Boolean; var MaximumOrderQtyEnabled: Boolean; var OrderMultipleEnabled: Boolean; var IncludeInventoryEnabled: Boolean; var ReschedulingPeriodEnabled: Boolean; var LotAccumulationPeriodEnabled: Boolean; var DampenerPeriodEnabled: Boolean; var DampenerQuantityEnabled: Boolean; var OverflowLevelEnabled: Boolean)
    var
        ParamArray: array[15] of Boolean;
    begin
        case ReorderingPolicy of
            ReorderingPolicy::" ":
                AssignToArray(ParamArray, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false);
            ReorderingPolicy::"Fixed Reorder Qty.":
                AssignToArray(ParamArray, true, true, true, true, true, false, true, true, true, false, false, false, false, true, true);
            ReorderingPolicy::"Maximum Qty.":
                AssignToArray(ParamArray, true, true, true, true, false, true, true, true, true, false, false, false, false, true, true);
            ReorderingPolicy::Order:
                AssignToArray(ParamArray, false, true, false, false, false, false, false, false, false, false, false, false, true, false, false);
            ReorderingPolicy::"Lot-for-Lot":
                AssignToArray(ParamArray, false, true, IncludeInventory, false, false, false, true, true, true, true, true, true, true, true, false);
        end;

        TimeBucketEnabled := ParamArray[1];
        SafetyLeadTimeEnabled := ParamArray[2];
        SafetyStockQtyEnabled := ParamArray[3];
        ReorderPointEnabled := ParamArray[4];
        ReorderQuantityEnabled := ParamArray[5];
        MaximumInventoryEnabled := ParamArray[6];
        MinimumOrderQtyEnabled := ParamArray[7];
        MaximumOrderQtyEnabled := ParamArray[8];
        OrderMultipleEnabled := ParamArray[9];
        IncludeInventoryEnabled := ParamArray[10];
        ReschedulingPeriodEnabled := ParamArray[11];
        LotAccumulationPeriodEnabled := ParamArray[12];
        DampenerPeriodEnabled := ParamArray[13];
        DampenerQuantityEnabled := ParamArray[14];
        OverflowLevelEnabled := ParamArray[15];
    end;

    local procedure AssignToArray(var ParamArray: array[15] of Boolean; Bool1: Boolean; Bool2: Boolean; Bool3: Boolean; Bool4: Boolean; Bool5: Boolean; Bool6: Boolean; Bool7: Boolean; Bool8: Boolean; Bool9: Boolean; Bool10: Boolean; Bool11: Boolean; Bool12: Boolean; Bool13: Boolean; Bool14: Boolean; Bool15: Boolean)
    begin
        ParamArray[1] := Bool1;
        ParamArray[2] := Bool2;
        ParamArray[3] := Bool3;
        ParamArray[4] := Bool4;
        ParamArray[5] := Bool5;
        ParamArray[6] := Bool6;
        ParamArray[7] := Bool7;
        ParamArray[8] := Bool8;
        ParamArray[9] := Bool9;
        ParamArray[10] := Bool10;
        ParamArray[11] := Bool11;
        ParamArray[12] := Bool12;
        ParamArray[13] := Bool13;
        ParamArray[14] := Bool14;
        ParamArray[15] := Bool15;
    end;

    procedure AdjustInvalidSettings(var SKU: Record "Stockkeeping Unit")
    var
        TimebucketEnabled: Boolean;
        SafetyLeadTimeEnabled: Boolean;
        SafetyStockQtyEnabled: Boolean;
        ReorderPointEnabled: Boolean;
        ReorderQuantityEnabled: Boolean;
        MaximumInventoryEnabled: Boolean;
        MinimumOrderQtyEnabled: Boolean;
        MaximumOrderQtyEnabled: Boolean;
        OrderMultipleEnabled: Boolean;
        IncludeInventoryEnabled: Boolean;
        ReschedulingPeriodEnabled: Boolean;
        LotAccumulationPeriodEnabled: Boolean;
        DampenerPeriodEnabled: Boolean;
        DampenerQuantityEnabled: Boolean;
        OverflowLevelEnabled: Boolean;
    begin
        SetUpPlanningControls(SKU."Reordering Policy", SKU."Include Inventory",
          TimebucketEnabled, SafetyLeadTimeEnabled, SafetyStockQtyEnabled,
          ReorderPointEnabled, ReorderQuantityEnabled, MaximumInventoryEnabled,
          MinimumOrderQtyEnabled, MaximumOrderQtyEnabled, OrderMultipleEnabled, IncludeInventoryEnabled,
          ReschedulingPeriodEnabled, LotAccumulationPeriodEnabled,
          DampenerPeriodEnabled, DampenerQuantityEnabled, OverflowLevelEnabled);

        if not TimebucketEnabled then
            Evaluate(SKU."Time Bucket", '<0D>');
        if not SafetyLeadTimeEnabled then
            Evaluate(SKU."Safety Lead Time", '<0D>');
        if not SafetyStockQtyEnabled then
            SKU."Safety Stock Quantity" := 0;
        if not ReorderPointEnabled then
            SKU."Reorder Point" := 0;
        if not ReorderQuantityEnabled then
            SKU."Reorder Quantity" := 0;
        if not MaximumInventoryEnabled then
            SKU."Maximum Inventory" := 0;
        if not MinimumOrderQtyEnabled then
            SKU."Minimum Order Quantity" := 0;
        if not MaximumOrderQtyEnabled then
            SKU."Maximum Order Quantity" := 0;
        if not OrderMultipleEnabled then
            SKU."Order Multiple" := 0;
        if not ReschedulingPeriodEnabled then
            Evaluate(SKU."Rescheduling Period", '<0D>');
        if not LotAccumulationPeriodEnabled then
            Evaluate(SKU."Lot Accumulation Period", '<0D>');
        if not DampenerPeriodEnabled then
            Evaluate(SKU."Dampener Period", '<0D>');
        if not DampenerQuantityEnabled then
            SKU."Dampener Quantity" := 0;
        if not OverflowLevelEnabled then
            SKU."Overflow Level" := 0;

        AdjustInvalidValues(SKU, ReorderPointEnabled);
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
            GetMfgSetUp;
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
                GetMfgSetUp;
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
            GetMfgSetUp;
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
}

