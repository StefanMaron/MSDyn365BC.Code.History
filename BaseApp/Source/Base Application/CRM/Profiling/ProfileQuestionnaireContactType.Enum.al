namespace Microsoft.CRM.Profiling;

#pragma warning disable AL0659
enum 5087 "Profile Questionnaire Contact Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Companies") { Caption = 'Companies'; }
    value(2; "People") { Caption = 'People'; }
}