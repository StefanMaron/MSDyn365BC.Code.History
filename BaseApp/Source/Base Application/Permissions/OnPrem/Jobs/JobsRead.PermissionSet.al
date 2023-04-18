permissionset 1087 "Jobs - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read jobs and entries';

    Permissions = tabledata "Comment Line" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Dtld. Price Calculation Setup" = R,
                  tabledata "Duplicate Price Line" = R,
                  tabledata Job = R,
#if not CLEAN21
                  tabledata "Job G/L Account Price" = R,
                  tabledata "Job Item Price" = R,
#endif
                  tabledata "Job Ledger Entry" = R,
                  tabledata "Job Planning Line - Calendar" = R,
                  tabledata "Job Planning Line" = R,
                  tabledata "Job Planning Line Invoice" = R,
#if not CLEAN21
                  tabledata "Job Resource Price" = R,
#endif
                  tabledata "Job Task" = R,
                  tabledata "Job Usage Link" = R,
                  tabledata "Job WIP Entry" = R,
                  tabledata "Job WIP G/L Entry" = R,
                  tabledata "Job WIP Method" = R,
                  tabledata "Job WIP Total" = R,
                  tabledata "Job WIP Warning" = R,
                  tabledata "Price Asset" = R,
                  tabledata "Price Calculation Buffer" = R,
                  tabledata "Price Calculation Setup" = R,
                  tabledata "Price Line Filters" = R,
                  tabledata "Price List Header" = R,
                  tabledata "Price List Line" = R,
                  tabledata "Price Source" = R,
                  tabledata "Price Worksheet Line" = R;
}
