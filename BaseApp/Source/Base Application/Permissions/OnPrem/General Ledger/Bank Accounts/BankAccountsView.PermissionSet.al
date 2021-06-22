permissionset 1083 "Bank Accounts - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read bank accounts and entries';

    Permissions = tabledata "Bank Account" = R,
                  tabledata "Bank Account Ledger Entry" = R,
                  tabledata "Bank Account Posting Group" = R,
                  tabledata "Bank Account Statement" = R,
                  tabledata "Bank Account Statement Line" = R,
                  tabledata "Check Ledger Entry" = R,
                  tabledata "Default Dimension" = RIMD;
}
