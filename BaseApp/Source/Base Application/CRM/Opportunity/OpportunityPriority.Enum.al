namespace Microsoft.CRM.Opportunity;

enum 5093 "Opportunity Priority"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Low") { Caption = 'Low'; }
    value(1; "Normal") { Caption = 'Normal'; }
    value(2; "High") { Caption = 'High'; }
}