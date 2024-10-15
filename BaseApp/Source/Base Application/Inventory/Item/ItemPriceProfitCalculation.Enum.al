namespace Microsoft.Inventory.Item;

enum 19 "Item Price Profit Calculation"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Profit=Price-Cost") { Caption = 'Profit=Price-Cost'; }
    value(1; "Price=Cost+Profit") { Caption = 'Price=Cost+Profit'; }
    value(2; "No Relationship") { Caption = 'No Relationship'; }
}