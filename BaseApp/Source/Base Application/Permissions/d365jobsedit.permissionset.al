permissionset 9886 "D365 JOBS, EDIT"
{
    Assignable = true;
    Caption = 'Dynamics 365 Create Jobs';

    IncludedPermissionSets = "D365 JOBS, VIEW",
                             "D365 JOBS, SETUP";

    Permissions = tabledata "Dtld. Price Calculation Setup" = RIMD,
                  tabledata "Duplicate Price Line" = RIMD,
                  tabledata Job = IMD,
                  tabledata "Job Cue" = IMD,
                  tabledata "Job Entry No." = IMD,
#if not CLEAN19
                  tabledata "Job G/L Account Price" = IMD,
                  tabledata "Job Item Price" = IMD,
#endif
                  tabledata "Job Journal Batch" = IMD,
                  tabledata "Job Journal Line" = IMD,
                  tabledata "Job Journal Quantity" = IMD,
                  tabledata "Job Ledger Entry" = imd,
                  tabledata "Job Planning Line - Calendar" = IMD,
                  tabledata "Job Planning Line" = IMD,
                  tabledata "Job Planning Line Invoice" = IMD,
                  tabledata "Job Register" = imd,
#if not CLEAN19
                  tabledata "Job Resource Price" = IMD,
#endif
                  tabledata "Job Task" = IMD,
                  tabledata "Job Task Dimension" = IMD,
                  tabledata "Job Usage Link" = IMD,
                  tabledata "Job WIP Entry" = IMD,
                  tabledata "Job WIP G/L Entry" = imd,
                  tabledata "Job WIP Method" = IMD,
                  tabledata "Job WIP Total" = IMD,
                  tabledata "Job WIP Warning" = IMD,
                  tabledata "My Job" = IMD,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD;
}
