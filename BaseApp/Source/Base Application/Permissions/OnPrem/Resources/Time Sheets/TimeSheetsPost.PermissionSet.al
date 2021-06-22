permissionset 7665 "Time Sheets - Post"
{
    Access = Public;
    Assignable = false;
    Caption = 'Approve time sheets';

    Permissions = tabledata "Employee Absence" = RIM,
                  tabledata "Human Resource Unit of Measure" = R;
}
