permissionset 4222 "Absense - Edit"
{
    Access = Public;
    Assignable = false;

    Caption = 'Create and edit absence';
    Permissions = tabledata "Cause of Absence" = R,
                  tabledata Employee = R,
                  tabledata "Employee Absence" = RIMD,
                  tabledata "Human Resource Comment Line" = RIMD,
                  tabledata "Unit of Measure" = R;
}
