namespace Microsoft.Inventory.Costing;

using Microsoft.Finance.Analysis;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

codeunit 5822 "Cost Adjustment Bucket Runner"
{
    TableNo = "Cost Adj. Item Bucket";

    trigger OnRun()
    var
        Item: Record Item;
        InventoryAdjustmentHandler: Codeunit "Inventory Adjustment Handler";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        if not LockTables() then
            exit;

        Item.SetFilter("No.", Rec."Item Filter");
        InventoryAdjustmentHandler.SetFilterItem(Item);
        InventoryAdjustmentHandler.MakeInventoryAdjustment(false, Rec."Post to G/L");

        if Rec."Post to G/L" then
            UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
    end;

    local procedure LockTables(): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
    begin
        ItemApplicationEntry.LockTable();
        if ItemApplicationEntry.GetLastEntryNo() = 0 then
            exit(false);

        ItemLedgerEntry.LockTable();
        if ItemLedgerEntry.GetLastEntryNo() = 0 then
            exit(false);

        ValueEntry.LockTable();
        if ValueEntry.GetLastEntryNo() = 0 then
            exit(false);

        AvgCostEntryPointHandler.LockBuffer();

        exit(true);
    end;
}