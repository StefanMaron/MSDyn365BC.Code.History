permissionset 8689 "Fixed Assets - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'FA periodic activities';

    Permissions = tabledata "Accounting Period" = r,
                  tabledata "Date Compr. Register" = RimD,
                  tabledata "Depreciation Book" = R,
                  tabledata "Depreciation Table Header" = R,
                  tabledata "Depreciation Table Line" = R,
                  tabledata "FA Allocation" = R,
                  tabledata "FA Depreciation Book" = Rm,
                  tabledata "FA Journal Batch" = R,
                  tabledata "FA Journal Line" = Ri,
                  tabledata "FA Journal Setup" = R,
                  tabledata "FA Journal Template" = R,
                  tabledata "FA Ledger Entry" = Rimd,
                  tabledata "FA Posting Group" = R,
                  tabledata "FA Register" = Rimd,
                  tabledata "Fixed Asset" = R,
                  tabledata "G/L Register" = Rimd,
                  tabledata "Gen. Journal Batch" = R,
                  tabledata "Gen. Journal Line" = Ri,
                  tabledata "Gen. Journal Template" = R,
                  tabledata "General Ledger Setup" = rm,
                  tabledata "General Posting Setup" = r,
                  tabledata "Ins. Coverage Ledger Entry" = Rimd,
                  tabledata Insurance = R,
                  tabledata "Insurance Journal Batch" = R,
                  tabledata "Insurance Journal Line" = Ri,
                  tabledata "Insurance Journal Template" = R,
                  tabledata "Insurance Register" = Rimd,
                  tabledata "Maintenance Ledger Entry" = Rimd,
#if not CLEAN20
                  tabledata "Native - Payment" = Ri,
#endif
                  tabledata "Source Code Setup" = R;
}
