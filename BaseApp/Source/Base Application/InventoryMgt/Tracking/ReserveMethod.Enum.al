namespace Microsoft.Inventory.Tracking;

enum 100 "Reserve Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Never") { Caption = 'Never'; }
    value(1; "Optional") { Caption = 'Optional'; }
    value(2; "Always") { Caption = 'Always'; }
}