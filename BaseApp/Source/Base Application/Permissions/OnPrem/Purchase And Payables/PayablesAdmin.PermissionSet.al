permissionset 6092 "Payables - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'P&P setup';

    Permissions = tabledata "Base Calendar" = RIMD,
                  tabledata "Base Calendar Change" = RIMD,
                  tabledata "Currency for Fin. Charge Terms" = RIMD,
                  tabledata "Customized Calendar Change" = RIMD,
                  tabledata "Customized Calendar Entry" = RIMD,
                  tabledata "Employee Posting Group" = RIMD,
                  tabledata "Finance Charge Terms" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Jnl. Allocation" = D,
                  tabledata "Gen. Journal Batch" = RIMD,
                  tabledata "Gen. Journal Line" = MD,
                  tabledata "Gen. Journal Template" = RIMD,
                  tabledata "Item Charge" = RIMD,
#if not CLEAN20
                  tabledata "Native - Payment" = MD,
#endif
                  tabledata "Payment Method" = RIMD,
                  tabledata "Payment Terms" = RIMD,
                  tabledata "Purchases & Payables Setup" = RIMD,
                  tabledata "Reason Code" = R,
                  tabledata "Report Selections" = RIMD,
                  tabledata "Req. Wksh. Template" = RIMD,
                  tabledata "Requisition Line" = D,
                  tabledata "Requisition Wksh. Name" = RIMD,
                  tabledata "Return Reason" = RIMD,
                  tabledata "Salesperson/Purchaser" = RIMD,
                  tabledata "Shipment Method" = RIMD,
                  tabledata "Source Code Setup" = R,
                  tabledata "Standard Purchase Code" = RIMD,
                  tabledata "Standard Purchase Line" = RIMD,
                  tabledata "Standard Vendor Purchase Code" = RIMD,
                  tabledata "Tax Area" = R,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "Vendor Invoice Disc." = RIMD,
                  tabledata "Vendor Posting Group" = RIMD;
}
