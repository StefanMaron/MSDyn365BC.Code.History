namespace Microsoft.Projects.Project.Journal;

enum 210 "Job Journal Line Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Usage")
    {
        Caption = 'Usage';
    }
    value(1; "Sale")
    {
        Caption = 'Sale';
    }
}