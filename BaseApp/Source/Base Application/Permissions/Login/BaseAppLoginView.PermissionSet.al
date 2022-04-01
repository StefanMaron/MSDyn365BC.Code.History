permissionset 186 "BaseApp Login - View"
{
    Access = Internal;
    Assignable = false;
    IncludedPermissionSets = "BaseApp Login - Read";

    Permissions = tabledata "License Agreement" = im,
                  tabledata "My Notifications" = i,
                  tabledata "User Group Member" = d;
}