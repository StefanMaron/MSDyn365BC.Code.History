permissionset 5600 "Vendor - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read vendors and entries';

    Permissions = tabledata "Comment Line" = R,
                  tabledata Contact = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Detailed Vendor Ledg. Entry" = R,
                  tabledata "Employee Ledger Entry" = R,
                  tabledata "Item Reference" = R,
                  tabledata Location = R,
                  tabledata "My Vendor" = Rimd,
                  tabledata "Order Address" = R,
                  tabledata "Remit Address" = R,
                  tabledata "Responsibility Center" = R,
                  tabledata Vendor = R,
                  tabledata "Vendor Bank Account" = R,
                  tabledata "Vendor Ledger Entry" = R;
}
