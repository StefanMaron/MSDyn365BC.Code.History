namespace Microsoft.Finance.Consolidation;

enum 220 "Business Unit File Format"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Version 4.00 or Later (.xml)") { Caption = 'Version 4.00 or Later (.xml)'; }
    value(1; "Version 3.70 or Earlier (.txt)") { Caption = 'Version 3.70 or Earlier (.txt)'; }
}