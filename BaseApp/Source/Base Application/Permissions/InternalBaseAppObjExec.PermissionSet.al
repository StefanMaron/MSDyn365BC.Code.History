permissionset 23 "Internal BaseApp Obj. - Exec"
{
    Access = Public;
    Assignable = false;
    Caption = 'Internal BaseApp Obj. - Exec';

    permissions = Table "CDS Coupled Business Unit" = X,
                  Table "CDS Environment" = X,
                  Table "Email Item" = X,
                  Table "OData Initialized Status" = X,
                  Table "Permission Conflicts" = X,
                  Table "Permission Conflicts Overview" = X,
#if not CLEAN19
                  Table "SmartList Designer Setup" = X,
#endif
                  Codeunit "Application Area Cache" = X,
                  Codeunit "Base Application Logs Delete" = X,
                  Codeunit "CDS Environment" = X,
                  Codeunit "Company Setup Notification" = X,
                  Codeunit "Contact Business Relation" = X,
                  Codeunit "Data Admin. Page Notification" = X,
                  Codeunit "Email Address Lookup Subs" = X,
                  Codeunit "Environment Cleanup Subs" = X,
                  Codeunit "Lookup State Manager" = X,
                  Codeunit "Map Email Source" = X,
                  Codeunit "OData Initializer" = X,
                  Codeunit "Reten. Pol. Doc. Arch. Fltrng." = X,
                  Codeunit "Reten. Pol. Install - BaseApp" = X,
                  Codeunit "Reten. Pol. Upgrade - BaseApp" = X,
                  Codeunit "Retention Policy JQ" = X,
                  Codeunit "Retention Policy Scheduler" = X,
                  Codeunit "SMTP Mail Internals" = X,
                  Codeunit "Advanced Settings Ext. Impl." = X,
                  Codeunit "Azure AI Usage Impl." = X,
                  Codeunit "BOM Tree Impl." = X,
                  Codeunit "BOM Tree Node" = X,
                  Codeunit "BOM Tree Node Dictionary Impl." = X,
                  Codeunit "BOM Tree Nodes Bucket" = X,
#if not CLEAN17
                  Codeunit "Open Mail Setup Page" = X,
#endif
                  Codeunit "Global Admin Notifier" = X,
                  Codeunit "Intrastat File Writer" = X,
                  Codeunit "Job Queue Start Report" = X,
                  codeunit "Monitored Field Notification" = X,
#if not CLEAN19
                  Codeunit "Scheduled Tasks" = X,
                  Codeunit "SmartList Designer Impl" = X,
                  Codeunit "SmartList Mgmt" = X,
                  Codeunit "Query Navigation Builder" = X;
#else
                  Codeunit "Scheduled Tasks" = X;
#endif
}