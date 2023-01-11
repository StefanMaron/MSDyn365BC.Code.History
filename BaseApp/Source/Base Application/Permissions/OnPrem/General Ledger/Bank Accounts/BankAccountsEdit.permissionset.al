permissionset 7785 "Bank Accounts - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit bank accounts';

    IncludedPermissionSets = "Language - Read";

    Permissions = tabledata "Bank Acc. Reconciliation" = r,
                  tabledata "Bank Acc. Reconciliation Line" = r,
                  tabledata "Bank Account" = RIMD,
                  tabledata "Bank Account Ledger Entry" = Rm,
                  tabledata "Bank Account Posting Group" = R,
                  tabledata "Bank Account Statement" = R,
                  tabledata "Bank Account Statement Line" = R,
                  tabledata "Bank Clearing Standard" = RIMD,
                  tabledata "Check Ledger Entry" = Rm,
                  tabledata "Comment Line" = RIMD,
                  tabledata "Cont. Duplicate Search String" = RID,
                  tabledata Contact = RIM,
                  tabledata "Contact Business Relation" = ImD,
                  tabledata "Contact Duplicate" = r,
                  tabledata "Country/Region" = R,
                  tabledata Currency = R,
                  tabledata "Cust. Ledger Entry" = r,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Duplicate Search String Setup" = R,
                  tabledata "Employee Ledger Entry" = rm,
                  tabledata "FA Ledger Entry" = r,
                  tabledata "G/L Entry" = rm,
                  tabledata "Gen. Journal Batch" = rm,
                  tabledata "Gen. Journal Line" = r,
                  tabledata "Gen. Journal Template" = r,
                  tabledata "Interaction Log Entry" = R,
                  tabledata "Maintenance Ledger Entry" = r,
#if not CLEAN20
                  tabledata "Native - Payment" = r,
#endif
                  tabledata Opportunity = R,
                  tabledata "Payment Method" = rm,
                  tabledata "Payment Rec. Related Entry" = R,
                  tabledata "Pmt. Rec. Applied-to Entry" = R,
                  tabledata "Post Code" = Ri,
                  tabledata "Purch. Cr. Memo Hdr." = r,
                  tabledata "Purch. Inv. Header" = rm,
                  tabledata "Purch. Rcpt. Header" = rm,
                  tabledata "Purchase Header" = r,
                  tabledata "Purchase Header Archive" = r,
                  tabledata "Return Receipt Header" = r,
                  tabledata "Return Shipment Header" = r,
                  tabledata "Sales Cr.Memo Header" = r,
                  tabledata "Sales Header" = r,
                  tabledata "Sales Header Archive" = r,
                  tabledata "Sales Invoice Header" = r,
                  tabledata "Sales Shipment Header" = r,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "Standard General Journal" = r,
                  tabledata "Standard General Journal Line" = r,
                  tabledata Territory = R,
                  tabledata "To-do" = R,
                  tabledata "Vendor Ledger Entry" = rm;
}
