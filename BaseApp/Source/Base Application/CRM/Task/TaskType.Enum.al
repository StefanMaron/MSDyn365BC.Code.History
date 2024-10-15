namespace Microsoft.CRM.Task;

enum 5080 "Task Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Meeting") { Caption = 'Meeting'; }
    value(2; "Phone Call") { Caption = 'Phone Call'; }
}