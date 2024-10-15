permissionset 3242 "D365 HR, EDIT"
{
    Assignable = true;
    Caption = 'Dynamics 365 Create Basic HR';

    IncludedPermissionSets = "D365 HR, VIEW";

    Permissions = tabledata "Alternative Address" = RD,
                  tabledata "Cause of Absence" = RIMD,
                  tabledata "Confidential Information" = RD,
                  tabledata Employee = IMD,
                  tabledata "Employee Absence" = RID,
                  tabledata "Employee Qualification" = RMD,
                  tabledata "Employee Relative" = RD,
                  tabledata "G/L Account" = R,
                  tabledata "Human Resource Comment Line" = RD,
                  tabledata "Misc. Article Information" = RD;
}
