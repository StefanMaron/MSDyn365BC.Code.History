permissionset 4123 "General Ledger Accounts - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read G/L accounts and entries';

    Permissions = tabledata "Bank Account Posting Group" = R,
                  tabledata "Business Unit" = R,
                  tabledata "Business Unit Information" = R,
                  tabledata "Business Unit Setup" = R,
                  tabledata "Comment Line" = R,
                  tabledata Currency = R,
                  tabledata "Customer Posting Group" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Employee Posting Group" = R,
                  tabledata "Extended Text Header" = R,
                  tabledata "Extended Text Line" = R,
                  tabledata "FA Allocation" = R,
                  tabledata "FA Posting Group" = R,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Account Category" = R,
                  tabledata "G/L Account Where-Used" = R,
                  tabledata "G/L Entry - VAT Entry Link" = R,
                  tabledata "G/L Entry" = R,
                  tabledata "Gen. Jnl. Allocation" = R,
                  tabledata "Gen. Journal Batch" = R,
                  tabledata "Gen. Journal Template" = R,
                  tabledata "General Posting Setup" = R,
                  tabledata "Inventory Posting Setup" = R,
                  tabledata "Job Posting Group" = R,
                  tabledata "Service Contract Account Group" = R,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Entry" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata "Vendor Posting Group" = R;
}
