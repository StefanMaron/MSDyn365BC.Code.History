namespace Microsoft.Inventory.Tracking;

enum 341 "Inventory Planning Flexibility"
{
    AssignmentCompatibility = true;

    value(0; "Unlimited") { Caption = 'Unlimited'; }
    value(1; "None") { Caption = 'None'; }
    value(2; "Reduce Only") { Caption = 'Reduce Only'; }   
}