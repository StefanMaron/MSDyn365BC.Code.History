// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;

codeunit 5894 "Inventory Adjustment Handler"
{
    var
        Item: Record Item;
        SkipJobUpdate: Boolean;
        IsItemFiltered: Boolean;

    procedure MakeInventoryAdjustment(var CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.")
    var
        CostAdjustmentParameter: Record "Cost Adjustment Parameter";
        InventoryAdjustment: Interface "Inventory Adjustment";
        CostAdjustmentWithParams: Interface "Cost Adjustment With Params";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeInventoryAdjustment(InventoryAdjustment, IsHandled);
        if not IsHandled then
            InventoryAdjustment := "Inventory Adjustment Impl."::"Default Implementation";

        if InventoryAdjustment is "Cost Adjustment With Params" then begin
            CostAdjustmentWithParams := InventoryAdjustment as "Cost Adjustment With Params";
            if IsItemFiltered then
                CostAdjustmentWithParams.SetFilterItem(Item);
            CostAdjustmentWithParams.MakeMultiLevelAdjmt(CostAdjustmentParamsMgt);
        end else begin
            CostAdjustmentParamsMgt.GetParameters(CostAdjustmentParameter);
            InventoryAdjustment.SetProperties(CostAdjustmentParameter."Online Adjustment", CostAdjustmentParameter."Post to G/L");
            InventoryAdjustment.SetJobUpdateProperties(CostAdjustmentParameter."Skip Job Item Cost Update");
            if IsItemFiltered then
                InventoryAdjustment.SetFilterItem(Item);
            InventoryAdjustment.MakeMultiLevelAdjmt();
        end;

        OnAfterMakeInventoryAdjustment(CostAdjustmentParamsMgt);
    end;

    procedure MakeInventoryAdjustment(IsOnlineAdjmt: Boolean; PostToGL: Boolean)
    var
        CostAdjustmentParameter: Record "Cost Adjustment Parameter";
        CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.";
    begin
        CostAdjustmentParameter.Init();
        CostAdjustmentParameter."Online Adjustment" := IsOnlineAdjmt;
        CostAdjustmentParameter."Post to G/L" := PostToGL;
        CostAdjustmentParameter."Skip Job Item Cost Update" := SkipJobUpdate;
        OnMakeInventoryAdjustmentOnBeforeSetParameters(CostAdjustmentParameter);

        CostAdjustmentParamsMgt.SetParameters(CostAdjustmentParameter);
        OnMakeInventoryAdjustmentOnAfterSetParameters(CostAdjustmentParamsMgt);

        MakeInventoryAdjustment(CostAdjustmentParamsMgt);
    end;

    procedure SetJobUpdateProperties(SkipJobUpdate: Boolean)
    begin
        SkipJobUpdate := SkipJobUpdate;
    end;

    procedure SetFilterItem(var NewItem: Record Item)
    begin
        Item.CopyFilters(NewItem);
        IsItemFiltered := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeInventoryAdjustment(var InventoryAdjustment: Interface "Inventory Adjustment"; var IsHandled: Boolean)
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnAfterMakeInventoryAdjustment(var CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeInventoryAdjustmentOnBeforeSetParameters(var CostAdjustmentParameter: Record "Cost Adjustment Parameter")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeInventoryAdjustmentOnAfterSetParameters(var CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.")
    begin
    end;
}
