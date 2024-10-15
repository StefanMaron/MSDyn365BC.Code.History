permissionset 7243 "User Groups - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'User Groups Setup';

    IncludedPermissionSets = "Permissions & Licenses - Edit";

    Permissions = tabledata "Recorded Event Buffer" = RIMD,
#if not CLEAN21
                  tabledata "Table Permission Buffer" = RIMD,
#endif
                  tabledata "User Group" = RIMD,
                  tabledata "User Group Access Control" = RIMD,
                  tabledata "User Group Member" = RIMD,
                  tabledata "User Group Permission Set" = RIMD;
}
