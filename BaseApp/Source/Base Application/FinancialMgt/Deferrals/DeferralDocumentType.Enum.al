namespace Microsoft.Finance.Deferral;

enum 1702 "Deferral Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Purchase") { Caption = 'Purchase'; }
    value(1; "Sales") { Caption = 'Sales'; }
    value(2; "G/L") { Caption = 'G/L'; }
}