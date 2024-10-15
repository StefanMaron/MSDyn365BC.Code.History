namespace Microsoft.Projects.Project.Analysis;

enum 486 "Job Chart Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Profitability") { Caption = 'Profitability'; }
    value(1; "Actual to Budget Cost") { Caption = 'Actual to Budget Cost'; }
    value(2; "Actual to Budget Price") { Caption = 'Actual to Budget Price'; }
}