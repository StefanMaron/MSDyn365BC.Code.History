namespace Microsoft.Service.Contract;

enum 5967 "Service Contract Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Signed") { Caption = 'Signed'; }
    value(2; "Cancelled") { Caption = 'Cancelled'; }
}