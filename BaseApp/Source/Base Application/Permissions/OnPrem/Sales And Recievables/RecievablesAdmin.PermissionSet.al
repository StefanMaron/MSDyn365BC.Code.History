permissionset 3723 "Recievables - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'S&R  setup';

    Permissions = tabledata "Additional Fee Setup" = RIMD,
                  tabledata "Alt. Customer Posting Group" = RIMD,
                  tabledata "Base Calendar" = RIMD,
                  tabledata "Base Calendar Change" = RIMD,
                  tabledata "Currency for Fin. Charge Terms" = RIMD,
                  tabledata "Currency for Reminder Level" = RIMD,
                  tabledata "Cust. Invoice Disc." = RIMD,
                  tabledata "Customer Posting Group" = RIMD,
                  tabledata "Customized Calendar Change" = RIMD,
                  tabledata "Customized Calendar Entry" = RIMD,
                  tabledata "Finance Charge Terms" = RIMD,
                  tabledata "Finance Charge Text" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata "Gen. Jnl. Allocation" = MD,
                  tabledata "Gen. Journal Batch" = RIMD,
                  tabledata "Gen. Journal Line" = MD,
                  tabledata "Gen. Journal Template" = RIMD,
                  tabledata "Item Charge" = RIMD,
                  tabledata "Line Fee Note on Report Hist." = RIMD,
#if not CLEAN20
                  tabledata "Native - Payment" = MD,
#endif
                  tabledata "Payment Method" = RIMD,
                  tabledata "Payment Terms" = RIMD,
                  tabledata "Reason Code" = R,
                  tabledata "Reminder Level" = RIMD,
                  tabledata "Reminder Terms" = RIMD,
                  tabledata "Reminder Terms Translation" = RIMD,
                  tabledata "Reminder Text" = RIMD,
                  tabledata "Report Selections" = RIMD,
                  tabledata "Return Reason" = RIMD,
                  tabledata "Sales & Receivables Setup" = RIMD,
                  tabledata "Sales Discount Access" = RIMD,
#if not CLEAN21
                  tabledata "Sales Line Discount" = RIMD,
#endif
                  tabledata "Salesperson/Purchaser" = RIMD,
                  tabledata "Shipment Method" = RIMD,
                  tabledata "Shipping Agent" = RIMD,
                  tabledata "Shipping Agent Services" = RIMD,
                  tabledata "Sorting Table" = RIMD,
                  tabledata "Source Code Setup" = R,
                  tabledata "Standard Customer Sales Code" = RIMD,
                  tabledata "Standard Sales Code" = RIMD,
                  tabledata "Standard Sales Line" = RIMD;
}
