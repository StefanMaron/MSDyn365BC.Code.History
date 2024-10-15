namespace Microsoft.Inventory.Setup;

using Microsoft.Inventory.Item;

codeunit 8625 "Setup Item Costing Method"
{
    TableNo = Item;

    trigger OnRun()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        Rec."Costing Method" := InventorySetup."Default Costing Method"::FIFO;
        if Rec.Type = Rec.Type::Inventory then
            if InventorySetup.Get() then
                Rec."Costing Method" := InventorySetup."Default Costing Method";
        Rec.Modify();
    end;
}

