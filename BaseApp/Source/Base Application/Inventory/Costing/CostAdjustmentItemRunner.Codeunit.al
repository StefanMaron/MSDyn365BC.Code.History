namespace Microsoft.Inventory.Costing;

using Microsoft.Finance.Analysis;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;

codeunit 5823 "Cost Adjustment Item Runner"
{
    TableNo = Item;

    var
        PostToGL: Boolean;

    trigger OnRun()
    var
        InventoryAdjustmentHandler: Codeunit "Inventory Adjustment Handler";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        InventoryAdjustmentHandler.SetFilterItem(Rec);
        InventoryAdjustmentHandler.MakeInventoryAdjustment(false, PostToGL);

        if PostToGL then
            UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
    end;

    procedure SetPostToGL(NewPostToGL: Boolean)
    begin
        PostToGL := NewPostToGL;
    end;
}