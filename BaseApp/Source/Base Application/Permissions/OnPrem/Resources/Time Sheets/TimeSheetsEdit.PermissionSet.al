permissionset 4450 "Time Sheets - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Fill in time sheets';

    Permissions = tabledata Employee = r,
                  tabledata "Employee Absence" = r,
                  tabledata Job = R,
                  tabledata "Job Ledger Entry" = r,
                  tabledata "Job Planning Line - Calendar" = r,
                  tabledata "Job Planning Line" = r,
                  tabledata "Job Task" = R,
                  tabledata "Res. Capacity Entry" = r,
                  tabledata Resource = R,
                  tabledata "Time Activity" = R,
                  tabledata "Time Sheet Chart Setup" = R,
                  tabledata "Time Sheet Cmt. Line Archive" = R,
                  tabledata "Time Sheet Comment Line" = RIMD,
                  tabledata "Time Sheet Detail" = RIMD,
                  tabledata "Time Sheet Detail Archive" = R,
                  tabledata "Time Sheet Header" = R,
                  tabledata "Time Sheet Header Archive" = R,
                  tabledata "Time Sheet Line" = RIMD,
                  tabledata "Time Sheet Line Archive" = R,
                  tabledata "Time Sheet Posting Entry" = R;
}
