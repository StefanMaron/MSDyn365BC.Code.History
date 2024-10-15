permissionset 3242 "D365 HR, EDIT"
{
    Assignable = true;

    Caption = 'Dynamics 365 Create Basic HR';
    Permissions = tabledata "Alternative Address" = RD,
                  tabledata "Cause of Absence" = RIMD,
                  tabledata "Confidential Information" = RD,
                  tabledata Employee = RIMD,
                  tabledata "Employee Absence" = RID,
                  tabledata "Employee Ledger Entry" = Rm,
                  tabledata "Employee Posting Group" = RIMD,
                  tabledata "Employee Qualification" = RMD,
                  tabledata "Employee Relative" = RD,
                  tabledata "Human Resource Comment Line" = RD,
                  tabledata "Misc. Article Information" = RD;
}
