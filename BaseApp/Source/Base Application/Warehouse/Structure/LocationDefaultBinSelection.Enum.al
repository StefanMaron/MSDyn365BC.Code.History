namespace Microsoft.Warehouse.Structure;

enum 14 "Location Default Bin Selection"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Fixed Bin") { Caption = 'Fixed Bin'; }
    value(2; "Last-Used Bin") { Caption = 'Last-Used Bin'; }
}