permissionset 6098 "Outlook Sync. - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Outlook Synch. common user';

    Permissions = tabledata "Scheduled Task" = R,
                  tabledata "Change Log Entry" = Ri,
                  tabledata "Change Log Setup (Field)" = Rim,
                  tabledata "Change Log Setup (Table)" = Rim,
                  tabledata "Change Log Setup" = R,
                  tabledata "Integration Record" = RIMD,
                  tabledata "Integration Record Archive" = RIMD,
                  tabledata "Job Queue Category" = Rimd,
                  tabledata "Job Queue Entry" = RImd,
#if not CLEAN19
                  codeunit "Outlook Synch. Export Schema" = X,
                  codeunit "Outlook Synch. Finalize" = X,
                  codeunit "Outlook Synch. Process Links" = X,
                  codeunit "Outlook Synch. Resolve Confl." = X,
                  tabledata "Outlook Synch. Dependency" = R,
                  tabledata "Outlook Synch. Entity" = R,
                  tabledata "Outlook Synch. Entity Element" = R,
                  tabledata "Outlook Synch. Field" = R,
                  tabledata "Outlook Synch. Filter" = R,
                  tabledata "Outlook Synch. Link" = RIMD,
                  tabledata "Outlook Synch. Lookup Name" = Rimd,
                  tabledata "Outlook Synch. Option Correl." = R,
                  tabledata "Outlook Synch. Setup Detail" = R,
                  tabledata "Outlook Synch. User Setup" = RM,
#endif
                  tabledata "Job Queue Log Entry" = Ri;
}
