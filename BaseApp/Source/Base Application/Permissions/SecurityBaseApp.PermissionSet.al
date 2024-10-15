permissionset 7372 "Security - Baseapp"
{
    Access = Internal;
    Assignable = false;
    Caption = 'Assign permissions to users';

    IncludedPermissionSets = "BaseApp Objects - Exec";

    Permissions = tabledata "AAD Application" = RIMD,
                  tabledata "Activity Log" = RIMD,
                  tabledata "Application Area Setup" = R,
                  tabledata "Change Log Entry" = Rimd,
                  tabledata "Company Information" = R,
                  tabledata "Designer Diagnostic" = RIMD,
                  tabledata "Experience Tier Setup" = R,
                  tabledata "General Ledger Setup" = R,
                  tabledata "Permission Buffer" = RIMD,
                  tabledata "Permission Set Buffer" = RIMD,
                  tabledata "Permission Set Link" = rimd,
                  tabledata "Plan Permission Set" = Rimd,
                  tabledata "Profile Designer Diagnostic" = RIMD,
                  tabledata "Profile Import" = RIMD,
                  tabledata "Support Contact Information" = Rimd,
                  tabledata "Terms And Conditions" = RIM,
                  tabledata "Terms And Conditions State" = RIM,
                  tabledata "User Group" = RIMD,
                  tabledata "User Group Access Control" = RIMD,
                  tabledata "User Group Member" = RIMD,
                  tabledata "User Group Permission Set" = RIMD,
                  tabledata "User Group Plan" = RIMD,
                  tabledata "User Security Status" = RIMD;
}
