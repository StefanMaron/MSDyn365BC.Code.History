namespace Microsoft.Projects.Project.Planning;

enum 1048 "Job Planning Line Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Planning)
    {
        Caption = 'Planning';
    }
    value(1; Quote)
    {
        Caption = 'Quote';
    }
    value(2; Order)
    {
        Caption = 'Order';
    }
    value(3; Completed)
    {
        Caption = 'Completed';
    }
}