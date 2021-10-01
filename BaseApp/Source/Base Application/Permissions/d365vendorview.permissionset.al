permissionset 6555 "D365 VENDOR, VIEW"
{
    Assignable = true;

    Caption = 'Dynamics 365 View vendors';
    Permissions = tabledata "Item Reference" = R,
#if not CLEAN19
                  tabledata "Item Cross Reference" = R,
#endif
                  tabledata "Transaction Type" = R,
                  tabledata "Transport Method" = R,
                  tabledata "Vendor Bank Account" = R,
                  tabledata "Vendor Invoice Disc." = R,
                  tabledata "Vendor Ledger Entry" = R;
}
