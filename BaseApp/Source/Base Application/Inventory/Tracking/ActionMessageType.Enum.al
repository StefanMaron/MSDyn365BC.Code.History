namespace Microsoft.Inventory.Tracking;

enum 99000849 "Action Message Type"
{
    AssignmentCompatibility = true;
    Extensible = true;

    value(0; " ") { Caption = ' '; }
    value(1; "New") { Caption = 'New'; }
    value(2; "Change Qty.") { Caption = 'Change Qty.'; }
    value(3; "Reschedule") { Caption = 'Reschedule'; }
    value(4; "Resched. & Chg. Qty.") { Caption = 'Resched. & Chg. Qty.'; }
    value(5; "Cancel") { Caption = 'Cancel'; }
}