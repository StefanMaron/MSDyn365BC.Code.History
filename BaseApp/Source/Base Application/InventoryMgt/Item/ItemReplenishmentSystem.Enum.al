namespace Microsoft.Inventory.Item;

enum 5420 "Item Replenishment System"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Purchase") { Caption = 'Purchase'; }
    value(1; "Prod. Order") { Caption = 'Prod. Order'; }
    value(3; "Assembly") { Caption = 'Assembly'; }
}