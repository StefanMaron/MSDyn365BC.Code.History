namespace Microsoft.Inventory.Journal;

enum 83 "Item Journal Template Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Item") { Caption = 'Item'; }
    value(1; "Transfer") { Caption = 'Transfer'; }
    value(2; "Phys. Inventory") { Caption = 'Phys. Inventory'; }
    value(3; "Revaluation") { Caption = 'Revaluation'; }
    value(4; "Consumption") { Caption = 'Consumption'; }
    value(5; "Output") { Caption = 'Output'; }
    value(6; "Capacity") { Caption = 'Capacity'; }
    value(7; "Prod. Order") { Caption = 'Prod. Order'; }
}