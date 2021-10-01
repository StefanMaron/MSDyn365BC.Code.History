permissionset 3285 "Outlook Sync - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Outlook Synch. administrator';

    Permissions = tabledata "Scheduled Task" = R,
                  tabledata "Web Service" = RIMD,
                  tabledata "Azure AD Mgt. Setup" = RIMD,
                  tabledata "Change Log Entry" = Rid,
                  tabledata "Change Log Setup (Field)" = RIMd,
                  tabledata "Change Log Setup (Table)" = RIMd,
                  tabledata "Change Log Setup" = RIMD,
                  tabledata "Exchange Service Setup" = RIMD,
                  tabledata "Integration Record" = RIMD,
                  tabledata "Integration Record Archive" = RIMD,
                  tabledata "Job Queue Category" = RIMD,
                  tabledata "Job Queue Entry" = RIMD,
                  tabledata "Job Queue Log Entry" = Rid,
                  tabledata "Office Add-in" = RIMD,
                  tabledata "Office Add-in Setup" = RIMD,
#if not CLEAN19
                  tabledata "Outlook Synch. Dependency" = RIMD,
                  tabledata "Outlook Synch. Entity" = RIMD,
                  tabledata "Outlook Synch. Entity Element" = RIMD,
                  tabledata "Outlook Synch. Field" = RIMD,
                  tabledata "Outlook Synch. Filter" = RIMD,
                  tabledata "Outlook Synch. Link" = RIMD,
                  tabledata "Outlook Synch. Lookup Name" = Rimd,
                  tabledata "Outlook Synch. Option Correl." = RIMD,
                  tabledata "Outlook Synch. Setup Detail" = RIMD,
                  tabledata "Outlook Synch. User Setup" = RIMD,
#endif
                  tabledata "Office Admin. Credentials" = RIMD;
}
