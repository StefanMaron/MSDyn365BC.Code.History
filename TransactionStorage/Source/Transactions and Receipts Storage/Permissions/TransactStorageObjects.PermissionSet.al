permissionset 6201 "Transact. Storage Objects"
{
    Access = Public;
    Assignable = false;

    Permissions = table "Transaction Storage Setup" = X,
                  table "Transact. Storage Export State" = X,
                  table "Transact. Storage Table Entry" = X,
                  table "Transact. Storage Task Entry" = X,
                  page "Transaction Storage Setup" = X,
                  codeunit "Transaction Storage Impl." = X,
                  codeunit "Transact. Storage Export Data" = X,
                  codeunit "Trans. Storage Error Handler" = X,
                  codeunit "Transaction Storage ABS" = X;
}