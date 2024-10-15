permissionset 291 "Capacity Journals - Post"
{
    Access = Public;
    Assignable = false;
    Caption = 'Post Cap. Jnl.';

    Permissions = tabledata "Accounting Period" = R,
                  tabledata "Avg. Cost Adjmt. Entry Point" = Ri,
                  tabledata "Capacity Ledger Entry" = Rim,
                  tabledata "Dimension Combination" = R,
                  tabledata "Dimension Value Combination" = R,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "General Ledger Setup" = R,
                  tabledata "General Posting Setup" = R,
                  tabledata Item = Rm,
                  tabledata "Item Journal Batch" = RID,
                  tabledata "Item Journal Line" = RIMD,
                  tabledata "Item Journal Template" = RI,
                  tabledata "Item Register" = Rim,
                  tabledata "Item Unit of Measure" = R,
                  tabledata "Item Variant" = R,
                  tabledata "Machine Center" = R,
                  tabledata "Prod. Order Line" = R,
                  tabledata "Prod. Order Routing Line" = R,
                  tabledata "Production Order" = R,
                  tabledata Scrap = R,
                  tabledata "Stockkeeping Unit" = R,
                  tabledata Stop = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "User Setup" = R,
                  tabledata "Value Entry" = Rim,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Product Posting Group" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata "Work Center" = R;
}