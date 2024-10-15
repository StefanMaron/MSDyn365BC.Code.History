namespace Microsoft.Inventory.Tracking;

#pragma warning disable AL0659
enum 340 "Reservation Planning Flexibility"
#pragma warning restore AL0659
{
    AssignmentCompatibility = true;

    value(0; "Unlimited") { Caption = 'Unlimited'; }
    value(1; "None") { Caption = 'None'; }
}