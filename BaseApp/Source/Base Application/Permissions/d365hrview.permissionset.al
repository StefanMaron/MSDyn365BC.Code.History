permissionset 1825 "D365 HR, VIEW"
{
    Assignable = true;

    Caption = 'Dynamics 365 View Basic HR';
    Permissions = tabledata Employee = R,
                  tabledata "Employee Ledger Entry" = R;
}
