permissionset 3560 "Payables Registers - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read G/L registers (P&P)';

    Permissions = tabledata "Detailed Vendor Ledg. Entry" = R,
                  tabledata "G/L Register" = R,
                  tabledata "Vendor Ledger Entry" = R;
}
