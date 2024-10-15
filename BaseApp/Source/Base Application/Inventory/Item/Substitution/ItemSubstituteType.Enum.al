namespace Microsoft.Inventory.Item.Substitution;

enum 101 "Item Substitute Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Item") { Caption = 'Item'; }
    value(1; "Nonstock Item") { Caption = 'Catalog Item'; }
}