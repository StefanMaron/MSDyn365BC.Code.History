namespace Microsoft.CRM.Task;

enum 5081 "Task Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Not Started")
    {
        Caption = 'Not Started';
    }
    value(1; "In Progress")
    {
        Caption = 'In Progress';
    }
    value(2; "Completed")
    {
        Caption = 'Completed';
    }
    value(3; "Waiting")
    {
        Caption = 'Waiting';
    }
    value(4; "Postponed")
    {
        Caption = 'Postponed';
    }
}