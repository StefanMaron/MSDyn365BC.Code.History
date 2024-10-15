namespace Microsoft.Inventory.Tracking;

enum 6567 "Item Tracking Comment Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Serial No.") { Caption = 'Serial No.'; }
    value(2; "Lot No.") { Caption = 'Lot No.'; }
    value(3; "Package No.") { Caption = 'Package No.'; }
}