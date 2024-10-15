namespace Microsoft.Projects.Project.Ledger;

enum 1026 "Job Ledger Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Resource") { Caption = 'Resource'; }
    value(2; Item) { Caption = 'Item'; }
    value(3; "G/L Account") { Caption = 'G/L Account'; }
}
