permissionset 186 "BaseApp Login - View"
{
    Access = Internal;
    Assignable = false;
    IncludedPermissionSets = "BaseApp Login - Read";

    Permissions = tabledata "License Agreement" = im,
#if not CLEAN22
                  tabledata "User Group Member" = d,
#endif
                  tabledata "My Notifications" = i;
}