namespace Microsoft.Inventory.Item.Substitution;

enum 102 "Item Substitution Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Item") { Caption = 'Item'; }
    value(1; "Nonstock Item") { Caption = 'Catalog Item'; }
}