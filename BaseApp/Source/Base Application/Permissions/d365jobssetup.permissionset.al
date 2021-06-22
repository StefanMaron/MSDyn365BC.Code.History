permissionset 6408 "D365 JOBS, SETUP"
{
    Assignable = true;

    Caption = 'Dynamics 365 Jobs Setup';
    Permissions = tabledata "Job Journal Template" = RIMD,
                  tabledata "Job Posting Buffer" = RIMD,
                  tabledata "Job Posting Group" = RIMD,
                  tabledata "Jobs Setup" = RIMD;
}
