namespace Microsoft.Projects.Project.Journal;

enum 1025 "Job Journal Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Resource") { Caption = 'Resource'; }
    value(1; Item) { Caption = 'Item'; }
    value(2; "G/L Account") { Caption = 'G/L Account'; }
}
