permissionset 91 "User Personalization - Edit"
{
    Access = Public;
    Assignable = False;

    IncludedPermissionSets = "User Personalization - Read";

    Permissions = tabledata "Page Data Personalization" = IMD,
                  tabledata "User Default Style Sheet" = IMD,
                  tabledata "User Personalization" = IMD,
                  tabledata "User Metadata" = IMD,
                  tabledata "User Page Metadata" = IMD;
}
