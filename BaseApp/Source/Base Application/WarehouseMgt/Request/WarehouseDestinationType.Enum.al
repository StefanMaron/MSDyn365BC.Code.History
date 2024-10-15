namespace Microsoft.Warehouse.Request;

enum 7310 "Warehouse Destination Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Customer") { Caption = 'Customer'; }
    value(2; "Vendor") { Caption = 'Vendor'; }
    value(3; "Location") { Caption = 'Location'; }
    value(4; "Item") { Caption = 'Item'; }
    value(5; "Family") { Caption = 'Family'; }
    value(6; "Sales Order") { Caption = 'Sales Order'; }
}