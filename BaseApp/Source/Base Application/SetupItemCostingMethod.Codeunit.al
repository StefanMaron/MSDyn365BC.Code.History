codeunit 8625 "Setup Item Costing Method"
{
    TableNo = Item;

    trigger OnRun()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        "Costing Method" := InventorySetup."Default Costing Method"::FIFO;
        if Type = Type::Inventory then
            if InventorySetup.Get() then
                "Costing Method" := InventorySetup."Default Costing Method";
        Modify();
    end;
}

