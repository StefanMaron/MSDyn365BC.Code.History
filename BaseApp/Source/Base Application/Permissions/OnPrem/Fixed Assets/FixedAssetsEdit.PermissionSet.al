permissionset 3846 "Fixed Assets - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit fixed assets';

    Permissions = tabledata "Bank Account Ledger Entry" = r,
                  tabledata Bin = R,
                  tabledata "Check Ledger Entry" = r,
#if not CLEAN18
                  tabledata "Classification Code" = R,
#endif
                  tabledata "Comment Line" = RIMD,
                  tabledata Currency = R,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata "Cust. Ledger Entry" = r,
                  tabledata "Default Dimension" = RIMD,
#if not CLEAN18
                  tabledata "Depreciation Group" = R,
#endif
                  tabledata "Depreciation Table Header" = RIMD,
                  tabledata "Depreciation Table Line" = RIMD,
#if not CLEAN19
                  tabledata "Detailed G/L Entry" = rm,
#endif
                  tabledata Employee = R,
                  tabledata "Employee Ledger Entry" = r,
                  tabledata "FA Class" = RIMD,
                  tabledata "FA Depreciation Book" = RIMD,
#if not CLEAN18
                  tabledata "FA Extended Posting Group" = R,
                  tabledata "FA History Entry" = Rim,
#endif
                  tabledata "FA Ledger Entry" = Rm,
                  tabledata "FA Location" = RIMD,
                  tabledata "FA Posting Group" = R,
                  tabledata "FA Subclass" = RIMD,
                  tabledata "Fixed Asset" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Entry" = rm,
                  tabledata "Gen. Journal Batch" = r,
                  tabledata "Gen. Journal Line" = r,
                  tabledata "Gen. Journal Template" = r,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "Human Resource Comment Line" = r,
                  tabledata "Ins. Coverage Ledger Entry" = rm,
                  tabledata Insurance = rm,
                  tabledata Location = R,
                  tabledata "Main Asset Component" = RIMD,
                  tabledata Maintenance = RIMD,
                  tabledata "Maintenance Ledger Entry" = Rm,
                  tabledata "Maintenance Registration" = RIMD,
#if not CLEAN20
                  tabledata "Native - Payment" = r,
#endif
                  tabledata "Purch. Cr. Memo Line" = r,
                  tabledata "Purch. Inv. Line" = rm,
                  tabledata "Purch. Rcpt. Line" = rm,
                  tabledata "Purchase Line" = r,
                  tabledata "Return Receipt Line" = r,
                  tabledata "Return Shipment Line" = r,
                  tabledata "Sales Cr.Memo Line" = r,
                  tabledata "Sales Invoice Line" = r,
                  tabledata "Sales Line" = r,
                  tabledata "Sales Shipment Line" = r,
                  tabledata "Standard General Journal" = r,
                  tabledata "Standard General Journal Line" = r,
                  tabledata "Standard Purchase Line" = r,
                  tabledata "Standard Sales Line" = r,
                  tabledata "VAT Product Posting Group" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata Vendor = R,
                  tabledata "Vendor Ledger Entry" = r;
}
