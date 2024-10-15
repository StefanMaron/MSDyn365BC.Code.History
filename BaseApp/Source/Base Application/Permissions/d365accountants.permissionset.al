permissionset 2911 "D365 ACCOUNTANTS"
{
    Access = Public;
    Assignable = true;
    Caption = 'Dynamics 365 for Accountants';

    IncludedPermissionSets = "User Login Times - View",
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
#if not CLEAN18
                  tabledata "Customer Template" = RIMD,
                  tabledata "Item Cross Reference" = RD,
#endif
                  tabledata "Item Reference" = RD,
                  tabledata "Reminder/Fin. Charge Entry" = Rm,
                  tabledata "Sales Cr.Memo Header" = R,
                  tabledata "Sales Discount Access" = Rimd,
                  tabledata "Sales Invoice Header" = R,
#if not CLEAN19
                  tabledata "Sales Line Discount" = Rimd,
#endif
                  tabledata "Sales Prepayment %" = D,
                  tabledata "Sales Shipment Header" = R,
                  tabledata "SMTP Mail Setup" = RIM,
                  tabledata "Standard Customer Sales Code" = RD,
                  tabledata "User Setup" = RIM,
                  tabledata "Warranty Ledger Entry" = Rm;
}
