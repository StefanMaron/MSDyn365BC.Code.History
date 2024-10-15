namespace Microsoft.HumanResources.Employee;

enum 5200 "Employee Status"
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; Active)
    {
        Caption = 'Active';
    }
    value(1; Inactive)
    {
        Caption = 'Inactive';
    }
    value(2; Terminated)
    {
        Caption = 'Terminated';
    }
}