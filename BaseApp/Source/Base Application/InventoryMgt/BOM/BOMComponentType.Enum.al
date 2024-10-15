namespace Microsoft.Inventory.BOM;

enum 91 "BOM Component Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Item") { Caption = 'Item'; }
    value(2; "Resource") { Caption = 'Resource'; }
}