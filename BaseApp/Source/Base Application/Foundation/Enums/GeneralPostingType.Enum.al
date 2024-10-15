namespace Microsoft.Foundation.Enums;

enum 57 "General Posting Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Purchase") { Caption = 'Purchase'; }
    value(2; "Sale") { Caption = 'Sale'; }
    value(3; "Settlement") { Caption = 'Settlement'; }
}
