permissionset 185 "BaseApp Login - Read"
{
    Access = Internal;
    Assignable = false;
    IncludedPermissionSets = "BaseApp Login - Objects";
    Permissions = tabledata "Application Area Setup" = r,
                  tabledata "Assisted Company Setup Status" = r,
                  tabledata "Company Information" = r,
                  tabledata "License Agreement" = r,
#if not CLEAN22
                  tabledata "User Group Member" = r,
                  tabledata "User Group Plan" = r,
#endif
                  tabledata "My Notifications" = r;
}