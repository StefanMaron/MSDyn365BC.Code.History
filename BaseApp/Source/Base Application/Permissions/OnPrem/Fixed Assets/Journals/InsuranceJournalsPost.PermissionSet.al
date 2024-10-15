permissionset 4465 "Insurance Journals - Post"
{
    Access = Public;
    Assignable = false;
    Caption = 'Post insurance journals';

    Permissions = tabledata "Depreciation Group" = R,
                  tabledata "Dimension Combination" = R,
                  tabledata "Dimension Value Combination" = R,
                  tabledata "FA Class" = R,
                  tabledata "FA Depreciation Book" = R,
#if not CLEAN18
                  tabledata "FA Extended Posting Group" = R,
#endif
                  tabledata "FA History Entry" = Rim,
                  tabledata "FA Journal Setup" = R,
                  tabledata "FA Location" = R,
                  tabledata "FA Subclass" = R,
                  tabledata "Fixed Asset" = R,
                  tabledata "Ins. Coverage Ledger Entry" = rim,
                  tabledata Insurance = R,
                  tabledata "Insurance Journal Batch" = RID,
                  tabledata "Insurance Journal Line" = RIMD,
                  tabledata "Insurance Journal Template" = RI,
                  tabledata "Insurance Register" = Rim;
}
