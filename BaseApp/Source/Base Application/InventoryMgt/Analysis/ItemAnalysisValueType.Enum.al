namespace Microsoft.Inventory.Analysis;

enum 9210 "Item Analysis Value Type"
{
    AssignmentCompatibility = true;
    Extensible = false;

    value(0; "Sales Amount") { Caption = 'Sales Amount'; }
    value(1; "Cost Amount") { Caption = 'Cost Amount'; }
    value(2; "Quantity") { Caption = 'Quantity'; }
}