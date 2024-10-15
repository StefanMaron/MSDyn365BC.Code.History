permissionset 6202 "Trans. Stor. - Edit"
{
    Access = Public;
    Assignable = true;
    IncludedPermissionSets = "Trans. Stor. - Read";

    Permissions = tabledata "Transaction Storage Setup" = IM,
                  tabledata "Transact. Storage Export State" = IM,
                  tabledata "Transact. Storage Table Entry" = IMD,
                  tabledata "Transact. Storage Task Entry" = IM;
}