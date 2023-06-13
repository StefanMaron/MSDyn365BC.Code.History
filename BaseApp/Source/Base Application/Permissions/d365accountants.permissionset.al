permissionset 2911 "D365 ACCOUNTANTS"
{
    Access = Public;
    Assignable = true;
    Caption = 'Dynamics 365 for Accountants';

    IncludedPermissionSets = "LOGIN",
                             "Metadata - Read",
                             "User Personalization - Edit",
                             "Webhook - Edit";

    Permissions = tabledata "NAV App Tenant Add-In" = R,
                  tabledata "Campaign Target Group" = R,
                  tabledata Company = R,
                  tabledata "Company Information" = RM,
                  tabledata Contact = RIMD,
                  tabledata "Contact Business Relation" = RIMD,
                  tabledata "CRM Integration Record" = R,
                  tabledata "Cust. Ledger Entry" = R,
                  tabledata Customer = RIMD,
                  tabledata "Customer Bank Account" = RD,
                  tabledata "Customer Templ." = RIMD,
#if not CLEAN20
                  tabledata "Customer Template" = RIMD,
#endif
                  tabledata "Item Reference" = RD,
                  tabledata "Reminder/Fin. Charge Entry" = Rm,
                  tabledata "Sales Cr.Memo Header" = R,
                  tabledata "Sales Discount Access" = Rimd,
                  tabledata "Sales Invoice Header" = R,
#if not CLEAN21
                  tabledata "Sales Line Discount" = Rimd,
#endif
                  tabledata "Sales Prepayment %" = D,
                  tabledata "Sales Shipment Header" = R,
                  tabledata "Standard Customer Sales Code" = RD,
                  tabledata "User Setup" = RIM,
                  tabledata "Warranty Ledger Entry" = Rm;
}
