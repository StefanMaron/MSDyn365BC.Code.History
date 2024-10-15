namespace Microsoft.Inventory.Availability;

enum 354 "Item Availability Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Period") { Caption = 'Period'; }
    value(1; "Variant") { Caption = 'Variant'; }
    value(2; "Location") { Caption = 'Location'; }
    value(3; "Bin") { Caption = 'Bin'; }
    value(4; "Event") { Caption = 'Event'; }
    value(5; "BOM") { Caption = 'BOM'; }
    value(6; "UOM") { Caption = 'UOM'; }
}
