namespace System.Security.AccessControl;

using Microsoft.HumanResources.Employee;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Intrastat;
using Microsoft.Purchases.Vendor;
using Microsoft.Purchases.Payables;

permissionset 6555 "D365 VENDOR, VIEW"
{
    Assignable = true;

    Caption = 'Dynamics 365 View vendors';
    Permissions = tabledata "Employee" = R,
                  tabledata "G/L Account" = R,
                  tabledata "Item Reference" = R,
                  tabledata "Transaction Type" = R,
                  tabledata "Transport Method" = R,
                  tabledata "Vendor Bank Account" = R,
                  tabledata "Vendor Invoice Disc." = R,
                  tabledata "Vendor Ledger Entry" = R;
}
