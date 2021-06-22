permissionset 3300 "Resources Journals - Post"
{
    Access = Public;
    Assignable = false;
    Caption = 'Post resource journals';

    Permissions = tabledata "Accounting Period" = R,
                  tabledata "Dimension Combination" = R,
                  tabledata "Dimension Value Combination" = R,
                  tabledata "General Ledger Setup" = R,
                  tabledata "Res. Journal Batch" = RID,
                  tabledata "Res. Journal Line" = RIMD,
                  tabledata "Res. Journal Template" = RI,
                  tabledata "Res. Ledger Entry" = Ri,
                  tabledata Resource = R,
                  tabledata "Resource Register" = Rim,
                  tabledata "Time Sheet Chart Setup" = R,
                  tabledata "Time Sheet Detail" = Rm,
                  tabledata "Time Sheet Detail Archive" = Rm,
                  tabledata "Time Sheet Header" = R,
                  tabledata "Time Sheet Line" = Rm,
                  tabledata "Time Sheet Posting Entry" = R;
}
