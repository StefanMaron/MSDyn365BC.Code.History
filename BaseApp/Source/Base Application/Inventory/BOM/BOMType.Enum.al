namespace Microsoft.Inventory.BOM;

enum 5870 "BOM Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "") { Caption = ''; }
    value(1; "Item") { Caption = 'Item'; }
    value(2; "Machine Center") { Caption = 'Machine Center'; }
    value(3; "Work Center") { Caption = 'Work Center'; }
    value(4; "Resource") { Caption = 'Resource'; }
}