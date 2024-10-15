namespace Microsoft.Manufacturing.Capacity;

enum 5873 "Capacity Type Journal"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Work Center") { Caption = 'Work Center'; }
    value(1; "Machine Center") { Caption = 'Machine Center'; }
    value(2; " ") { Caption = ' '; }
    value(3; "Resource") { Caption = 'Resource'; }
}