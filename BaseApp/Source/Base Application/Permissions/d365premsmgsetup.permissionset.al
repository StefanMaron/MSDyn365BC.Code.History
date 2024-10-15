namespace System.Security.AccessControl;

using Microsoft.Service.Maintenance;
using Microsoft.Service.Loaner;
using Microsoft.Service.Resources;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;
using Microsoft.Service.Document;

permissionset 6524 "D365PREM SMG, SETUP"
{
    Assignable = true;

    Caption = 'D365 Service Management Setup';
    Permissions = tabledata "Fault Area" = RIMD,
                  tabledata "Fault Code" = RIMD,
                  tabledata "Fault Reason Code" = RIMD,
                  tabledata "Fault/Resol. Cod. Relationship" = RIMD,
                  tabledata Loaner = RIMD,
                  tabledata "Loaner Entry" = RIMD,
                  tabledata "Repair Status" = RIMD,
                  tabledata "Resolution Code" = RIMD,
                  tabledata "Resource Location" = RIMD,
                  tabledata "Serv. Price Group Setup" = RIMD,
                  tabledata "Service Mgt. Setup" = RIMD,
                  tabledata "Service Status Priority Setup" = RIMD,
                  tabledata "Symptom Code" = RIMD,
                  tabledata "Troubleshooting Header" = RIMD,
                  tabledata "Troubleshooting Line" = RIMD,
                  tabledata "Troubleshooting Setup" = RIMD,
                  tabledata "Work-Hour Template" = RIMD;
}
