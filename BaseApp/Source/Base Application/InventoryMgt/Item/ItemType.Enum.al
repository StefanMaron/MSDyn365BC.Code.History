namespace Microsoft.Inventory.Item;

enum 27 "Item Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Inventory") { Caption = 'Inventory'; }
    value(1; "Service") { Caption = 'Service'; }
    value(2; "Non-Inventory") { Caption = 'Non-Inventory'; }
}