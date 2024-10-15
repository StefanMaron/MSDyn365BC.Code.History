#if not CLEAN19
permissionset 6912 "G/L Registers - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read G/L registers';

    Permissions = tabledata "Bank Account Ledger Entry" = R,
                  tabledata "Detailed G/L Entry" = R,
                  tabledata "G/L Entry - VAT Entry Link" = R,
                  tabledata "G/L Entry" = R,
                  tabledata "G/L Register" = R,
                  tabledata "VAT Entry" = R;
}

#endif