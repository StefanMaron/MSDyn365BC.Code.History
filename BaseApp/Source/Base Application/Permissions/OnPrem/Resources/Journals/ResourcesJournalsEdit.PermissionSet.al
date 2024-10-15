permissionset 386 "Resources Journals - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create entries in res. jnls.';

    Permissions = tabledata "Accounting Period" = R,
                  tabledata "Comment Line" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Default Dimension Priority" = R,
                  tabledata "Dtld. Price Calculation Setup" = R,
                  tabledata "Duplicate Price Line" = R,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata Job = R,
                  tabledata "Price Asset" = R,
                  tabledata "Price Calculation Buffer" = R,
                  tabledata "Price Calculation Setup" = R,
                  tabledata "Price Line Filters" = R,
                  tabledata "Price List Header" = R,
                  tabledata "Price List Line" = R,
                  tabledata "Price Source" = R,
                  tabledata "Reason Code" = R,
                  tabledata "Res. Journal Batch" = RI,
                  tabledata "Res. Journal Line" = RIMD,
                  tabledata "Res. Journal Template" = RI,
                  tabledata Resource = R,
                  tabledata "Resource Cost" = R,
                  tabledata "Resource Group" = R,
                  tabledata "Resource Price" = R,
                  tabledata "Resource Unit of Measure" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Time Sheet Chart Setup" = R,
                  tabledata "Time Sheet Detail" = R,
                  tabledata "Time Sheet Detail Archive" = R,
                  tabledata "Time Sheet Header" = R,
                  tabledata "Time Sheet Line" = R,
                  tabledata "Time Sheet Posting Entry" = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "VAT Period" = R,
                  tabledata "Work Type" = R;
}
