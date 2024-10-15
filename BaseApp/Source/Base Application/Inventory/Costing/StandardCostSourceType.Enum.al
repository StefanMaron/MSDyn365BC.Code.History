namespace Microsoft.Inventory.StandardCost;

enum 5841 "Standard Cost Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Item") { Caption = 'Item'; }
    value(1; "Work Center") { Caption = 'Work Center'; }
    value(2; "Machine Center") { Caption = 'Machine Center'; }
    value(3; "Resource") { Caption = 'Resource'; }
}