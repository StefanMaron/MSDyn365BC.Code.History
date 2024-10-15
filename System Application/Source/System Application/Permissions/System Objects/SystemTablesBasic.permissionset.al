permissionset 66 "System Tables - Basic"
{
    Access = Internal;
    Assignable = false;
    Caption = 'Basic User (All Inclusive)';

    IncludedPermissionSets = "Company - Read",
                             "Media - View",
                             "Metadata - Read",
                             "Permissions & Licenses - Read",
                             "Power BI - Read",
                             "Satisfaction Survey - View",
                             "Session - Read",
                             "System Execute - Basic",
                             "User Login Times - View",
                             "User Personalization - Edit",
                             "User Selection - Read",
                             "Webhook - Edit";

    Permissions = tabledata "Add-in" = R,
                  tabledata "Aggregate Permission Set" = Rimd,
                  tabledata Chart = R,
                  tabledata "Code Coverage" = Rimd,
                  tabledata "Configuration Package File" = RIMD,
                  tabledata Device = Rimd,
                  tabledata "Document Service" = R,
                  tabledata Drive = Rimd,
                  tabledata "Event Subscription" = Rimd,
                  tabledata Field = Rimd,
                  tabledata File = Rimd,
                  tabledata "Object Options" = Rimd,
                  tabledata "OData Edm Type" = Rimd,
                  tabledata "Record Link" = RIMD,
                  tabledata "Report Layout" = RIMD,
                  tabledata "Report Layout Definition" = R,
                  tabledata "Scheduled Task" = R,
                  tabledata "Send-To Program" = RIMD,
                  tabledata Session = Rimd,
                  tabledata "Server Instance" = Rimd,
                  tabledata "SID - Account ID" = Rimd,
                  tabledata "Style Sheet" = RIMD,
                  tabledata "System Object" = Rimd,
                  tabledata "Tenant Profile Page Metadata" = Rimd,
                  tabledata "Tenant Report Layout" = R,
                  tabledata "Tenant Report Layout Selection" = RIMD,
                  tabledata "Token Cache" = Rimd;
}
