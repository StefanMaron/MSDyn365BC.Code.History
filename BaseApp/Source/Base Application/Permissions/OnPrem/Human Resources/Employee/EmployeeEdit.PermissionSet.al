permissionset 2698 "Employee - Edit"
{
    Access = Public;
    Assignable = false;

    Caption = 'Edit employees';
    Permissions = tabledata "Alternative Address" = RIMD,
                  tabledata "Cause of Absence" = R,
                  tabledata "Cause of Inactivity" = R,
                  tabledata "Confidential Information" = RiD,
                  tabledata "Country/Region" = R,
                  tabledata "Default Dimension" = RIMD,
                  tabledata Employee = RIMD,
                  tabledata "Employee Absence" = RmD,
                  tabledata "Employee Qualification" = RIMD,
                  tabledata "Employee Relative" = RIMD,
                  tabledata "Employee Statistics Group" = R,
                  tabledata "Employment Contract" = R,
                  tabledata "Fixed Asset" = rm,
                  tabledata "Grounds for Termination" = R,
                  tabledata "Human Resource Comment Line" = RIMD,
                  tabledata "Misc. Article" = R,
                  tabledata "Misc. Article Information" = RIMD,
                  tabledata Qualification = R,
                  tabledata Resource = Rm,
                  tabledata "Salesperson/Purchaser" = Rm,
                  tabledata Union = R;
}
