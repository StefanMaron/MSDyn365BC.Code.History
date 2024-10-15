namespace Microsoft.Manufacturing.Comment;

enum 99000770 "Mfg. Comment Table Name"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Work Center") { Caption = 'Work Center'; }
    value(1; "Machine Center") { Caption = 'Machine Center'; }
    value(2; "Routing Header") { Caption = 'Routing Header'; }
    value(3; "Production BOM Header") { Caption = 'Production BOM Header'; }
}