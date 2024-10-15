permissionset 7568 "Fixed Assets - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'FA setup';

#if CLEAN18
    Permissions = tabledata "Depreciation Book" = RIMD,
#else
    Permissions = tabledata "Classification Code" = RIMD,
                  tabledata "Depreciation Book" = RIMD,
                  tabledata "Depreciation Group" = RIMD,
#endif
                  tabledata "FA Allocation" = RIMD,
                  tabledata "FA Depreciation Book" = RIMD,
#if not CLEAN18
                  tabledata "FA Extended Posting Group" = RIMD,
#endif
                  tabledata "FA Journal Batch" = RIMD,
                  tabledata "FA Journal Line" = MD,
                  tabledata "FA Journal Setup" = RIMD,
                  tabledata "FA Journal Template" = RIMD,
                  tabledata "FA Posting Group" = RIMD,
                  tabledata "FA Posting Type Setup" = RiMd,
                  tabledata "FA Reclass. Journal Batch" = RIMD,
                  tabledata "FA Reclass. Journal Line" = MD,
                  tabledata "FA Reclass. Journal Template" = RIMD,
                  tabledata "FA Setup" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata "Gen. Jnl. Allocation" = MD,
                  tabledata "Gen. Journal Batch" = RIMD,
                  tabledata "Gen. Journal Line" = MD,
                  tabledata "Gen. Journal Template" = RIMD,
                  tabledata "Insurance Journal Batch" = RIMD,
                  tabledata "Insurance Journal Line" = MD,
                  tabledata "Insurance Journal Template" = RIMD,
#if not CLEAN20
                  tabledata "Native - Payment" = MD,
#endif
                  tabledata "Reason Code" = R,
                  tabledata "Report Selections" = RIMD,
                  tabledata "Source Code Setup" = R;
}
