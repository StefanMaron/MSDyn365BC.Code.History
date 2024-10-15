permissionset 4970 "Customer - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read customers and entries';

    Permissions = tabledata "Comment Line" = R,
                  tabledata Contact = R,
                  tabledata "Contact Profile Answer" = R,
                  tabledata Currency = R,
                  tabledata "Cust. Ledger Entry" = R,
                  tabledata Customer = R,
                  tabledata "Customer Bank Account" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Detailed Cust. Ledg. Entry" = R,
                  tabledata "Item Cross Reference" = R,
                  tabledata "Item Reference" = R,
                  tabledata Location = R,
                  tabledata "My Customer" = Rimd,
                  tabledata "Profile Questionnaire Line" = R,
                  tabledata "Reminder/Fin. Charge Entry" = R,
                  tabledata "Responsibility Center" = R,
                  tabledata "Service Line" = r,
                  tabledata "Ship-to Address" = R,
                  tabledata "Shipping Agent" = R,
                  tabledata "Shipping Agent Services" = R;
}
