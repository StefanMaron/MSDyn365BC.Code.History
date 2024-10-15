namespace Microsoft.Service.Contract;

enum 5968 "Service Contract Change Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Open") { Caption = 'Open'; }
    value(1; "Locked") { Caption = 'Locked'; }
}