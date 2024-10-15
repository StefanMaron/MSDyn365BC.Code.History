permissionset 5577 "Insurance Journals - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create entries in ins. jnls.';

    Permissions = tabledata Bin = R,
                  tabledata "Comment Line" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Default Dimension Priority" = R,
#if not CLEAN18
                  tabledata "Depreciation Group" = R,
#endif
                  tabledata "FA Class" = R,
#if not CLEAN18
                  tabledata "FA Extended Posting Group" = R,
                  tabledata "FA History Entry" = Rim,
#endif
                  tabledata "FA Journal Setup" = R,
                  tabledata "FA Location" = R,
                  tabledata "FA Subclass" = R,
                  tabledata "Fixed Asset" = R,
                  tabledata "Ins. Coverage Ledger Entry" = R,
                  tabledata Insurance = R,
                  tabledata "Insurance Journal Batch" = RI,
                  tabledata "Insurance Journal Line" = RIMD,
                  tabledata "Insurance Journal Template" = RI,
                  tabledata "Insurance Type" = R,
                  tabledata Location = R,
                  tabledata "Reason Code" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata Vendor = R;
}
