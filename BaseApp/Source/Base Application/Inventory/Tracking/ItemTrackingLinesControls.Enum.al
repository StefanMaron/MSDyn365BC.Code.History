namespace Microsoft.Inventory.Tracking;

enum 6511 "Item Tracking Lines Controls"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Handle") { Caption = 'Handle'; }
    value(1; "Invoice") { Caption = 'Invoice'; }
    value(2; "Quantity") { Caption = 'Quantity'; }
    value(3; "Reclass") { Caption = 'Reclass'; }
    value(4; "Tracking") { Caption = 'Tracking'; }
}