namespace Microsoft.Projects.Project.Job;

enum 1624 "Job Blocked"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; Posting)
    {
        Caption = 'Posting';
    }
    value(2; All)
    {
        Caption = 'All';
    }
}