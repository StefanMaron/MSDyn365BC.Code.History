permissionset 7871 "Outlook Sync. - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Outlook Synch. power user';

    Permissions = tabledata "Scheduled Task" = R,
                  tabledata "Change Log Entry" = Ri,
                  tabledata "Change Log Setup (Field)" = RIM,
                  tabledata "Change Log Setup (Table)" = RIM,
                  tabledata "Change Log Setup" = RM,
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
                  tabledata "Outlook Synch. Entity" = RM,
                  tabledata "Outlook Synch. Entity Element" = R,
                  tabledata "Outlook Synch. Field" = RIMD,
                  tabledata "Outlook Synch. Filter" = RIMD,
                  tabledata "Outlook Synch. Link" = RIMD,
                  tabledata "Outlook Synch. Lookup Name" = Rimd,
                  tabledata "Outlook Synch. Option Correl." = RIMD,
                  tabledata "Outlook Synch. Setup Detail" = RIMD,
                  tabledata "Outlook Synch. User Setup" = RIMD,
#endif
                  tabledata "Job Queue Log Entry" = Ri;
}
