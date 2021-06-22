permissionset 7243 "User Groups - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'User Groups Setup';

    IncludedPermissionSets = "Permissions & Licenses - Edit";

    Permissions = tabledata "Recorded Event Buffer" = RIMD,
                  tabledata "Table Permission Buffer" = RIMD,
                  tabledata "User Group" = RIMD,
                  tabledata "User Group Access Control" = RIMD,
                  tabledata "User Group Member" = RIMD,
                  tabledata "User Group Permission Set" = RIMD;
}
