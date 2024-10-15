namespace Microsoft.Projects.Project.Planning;

enum 1003 "Job Planning Line Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Budget") { Caption = 'Budget'; }
    value(1; "Billable") { Caption = 'Billable'; }
    value(2; "Both Budget and Billable") { Caption = 'Both Budget and Billable'; }
}
