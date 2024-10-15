permissionset 6200 "Trans. Stor. - Read"
{
    Access = Public;
    Assignable = true;
    IncludedPermissionSets = "Transact. Storage Objects";

    Permissions = tabledata "Transaction Storage Setup" = R,
                  tabledata "Transact. Storage Export State" = R,
                  tabledata "Transact. Storage Table Entry" = R,
                  tabledata "Transact. Storage Task Entry" = R;
}