permissionset 654 "Resources Registers - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read resource registers';

    Permissions = tabledata "Res. Ledger Entry" = R,
                  tabledata "Resource Register" = R;
}
