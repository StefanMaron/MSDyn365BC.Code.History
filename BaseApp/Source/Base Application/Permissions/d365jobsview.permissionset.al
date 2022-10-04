permissionset 448 "D365 JOBS, VIEW"
{
    Assignable = true;

    Caption = 'Dynamics 365 View Jobs';
    Permissions = tabledata Job = R,
                  tabledata "Job Cue" = R,
                  tabledata "Job Entry No." = R,
#if not CLEAN21
                  tabledata "Job G/L Account Price" = R,
                  tabledata "Job Item Price" = R,
#endif
                  tabledata "Job Journal Batch" = R,
                  tabledata "Job Journal Line" = R,
                  tabledata "Job Journal Quantity" = R,
                  tabledata "Job Journal Template" = R,
                  tabledata "Job Ledger Entry" = R,
                  tabledata "Job Planning Line - Calendar" = R,
                  tabledata "Job Planning Line" = R,
                  tabledata "Job Planning Line Invoice" = R,
                  tabledata "Job Posting Buffer" = R,
                  tabledata "Job Posting Group" = R,
                  tabledata "Job Register" = R,
#if not CLEAN21
                  tabledata "Job Resource Price" = R,
#endif
                  tabledata "Job Task" = R,
                  tabledata "Job Task Dimension" = R,
                  tabledata "Job Usage Link" = R,
                  tabledata "Job WIP Entry" = R,
                  tabledata "Job WIP G/L Entry" = R,
                  tabledata "Job WIP Method" = R,
                  tabledata "Job WIP Total" = R,
                  tabledata "Job WIP Warning" = R,
                  tabledata "Jobs Setup" = R,
                  tabledata "My Job" = R;
}
