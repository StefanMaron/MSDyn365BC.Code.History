permissionset 4222 "Absense - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create and edit absence';

    Permissions = tabledata "Absence Header" = RIMD,
                  tabledata "Absence Line" = RIMD,
                  tabledata Employee = R,
                  tabledata "Employee Absence" = RIMD,
                  tabledata "Employee Absence Entry" = Rimd,
                  tabledata "Human Resource Comment Line" = RIMD,
                  tabledata "Posted Absence Header" = Rimd,
                  tabledata "Posted Absence Line" = Rimd,
                  tabledata "Sick Leave Setup" = RIMD,
                  tabledata "Time Activity" = R,
                  tabledata "Unit of Measure" = R;
}
