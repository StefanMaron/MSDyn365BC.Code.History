permissionset 6555 "D365 VENDOR, VIEW"
{
    Assignable = true;

    Caption = 'Dynamics 365 View vendors';
    Permissions = tabledata "Employee" = R,
                  tabledata "Item Cross Reference" = R,
                  tabledata "Item Reference" = R,
                  tabledata "Transaction Type" = R,
                  tabledata "Vendor Bank Account" = R,
                  tabledata "Vendor Invoice Disc." = R,
                  tabledata "Vendor Ledger Entry" = R;
}
