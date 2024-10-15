namespace Microsoft.Inventory.Tracking;

enum 337 "Reservation Status"
{
    AssignmentCompatibility = true;
    Extensible = true;

    value(0; "Reservation") { Caption = 'Reservation'; }
    value(1; "Tracking") { Caption = 'Tracking'; }
    value(2; "Surplus") { Caption = 'Surplus'; }
    value(3; "Prospect") { Caption = 'Prospect'; }
}