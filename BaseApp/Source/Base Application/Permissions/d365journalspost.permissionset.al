permissionset 681 "D365 JOURNALS, POST"
{
    Assignable = true;
    Caption = 'Dynamics 365 Post journals';

    IncludedPermissionSets = "D365 JOURNALS, EDIT";

    Permissions = tabledata "Avg. Cost Adjmt. Entry Point" = RIM,
                  tabledata "Bank Account Ledger Entry" = Rim,
                  tabledata "Bank Account Posting Group" = R,
                  tabledata "Batch Processing Parameter" = Rimd,
                  tabledata "Batch Processing Session Map" = Rimd,
                  tabledata Currency = RIMD,
                  tabledata "Currency Exchange Rate" = RIM,
                  tabledata "Cust. Invoice Disc." = R,
                  tabledata "Cust. Ledger Entry" = imd,
                  tabledata "Detailed Cust. Ledg. Entry" = imd,
                  tabledata "Detailed Employee Ledger Entry" = imd,
                  tabledata "Detailed Vendor Ledg. Entry" = imd,
                  tabledata "Employee Ledger Entry" = imd,
                  tabledata "G/L Account" = RIMD,
                  tabledata "G/L - Item Ledger Relation" = RIMD,
                  tabledata "G/L Entry - VAT Entry Link" = Ri,
                  tabledata "G/L Entry" = Rimd,
                  tabledata "Item Register" = Rimd,
                  tabledata "Job Ledger Entry" = Rimd,
                  tabledata "Notification Entry" = RIMD,
                  tabledata "Sent Notification Entry" = RIMD,
                  tabledata "VAT Entry" = Rimd,
                  tabledata "Vendor Ledger Entry" = imd,
                  tabledata "Warehouse Register" = r;
}
