permissionset 865 "D365 CUSTOMER, VIEW"
{
    Assignable = true;

    Caption = 'Dynamics 365 View customers';
    Permissions = tabledata "Contact Profile Answer" = R,
                  tabledata "Cust. Invoice Disc." = R,
                  tabledata "Cust. Ledger Entry" = R,
                  tabledata "Customer Bank Account" = R,
                  tabledata "Item Reference" = R,
                  tabledata "Profile Questionnaire Line" = R,
                  tabledata "Reminder/Fin. Charge Entry" = R,
                  tabledata "Service Zone" = R,
                  tabledata "Shipping Agent Services" = R,
                  tabledata "Transaction Type" = R,
                  tabledata "Transport Method" = R,
                  tabledata "VAT Registration No. Format" = R;
}
