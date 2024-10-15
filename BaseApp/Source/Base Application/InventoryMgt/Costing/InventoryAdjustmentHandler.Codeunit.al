namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;

codeunit 5894 "Inventory Adjustment Handler"
{
    var
        Item: Record Item;
        SkipJobUpdate: Boolean;
        IsItemFiltered: Boolean;

    procedure MakeInventoryAdjustment(IsOnlineAdjmt: Boolean; PostToGL: Boolean)
    var
        InventoryAdjustment: Interface "Inventory Adjustment";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeInventoryAdjustment(InventoryAdjustment, IsHandled);
        if not IsHandled then
            InventoryAdjustment := "Inventory Adjustment Impl."::"Default Implementation";

        InventoryAdjustment.SetProperties(IsOnlineAdjmt, PostToGL);
        InventoryAdjustment.SetJobUpdateProperties(SkipJobUpdate);
        if IsItemFiltered then
            InventoryAdjustment.SetFilterItem(Item);
        InventoryAdjustment.MakeMultiLevelAdjmt();
        Clear(InventoryAdjustment);
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
}