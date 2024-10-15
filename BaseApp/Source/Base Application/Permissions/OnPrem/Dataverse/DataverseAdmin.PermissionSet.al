namespace System.Security.AccessControl;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;

permissionset 8708 "Dataverse - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Setup MS Dataverse Int.';

    Permissions = tabledata "CDS Company" = RIMD,
                  tabledata "CDS Connection Setup" = RIMD,
                  tabledata "CDS Coupled Business Unit" = RIMD,
                  tabledata "CDS Environment" = RIMD,
                  tabledata "CDS Solution" = RIMD,
                  tabledata "CDS Teamroles" = RIMD,
                  tabledata "Dataverse Entity Change" = RID,
                  tabledata "CRM Account" = RIMD,
                  tabledata "CRM Businessunit" = RIMD,
                  tabledata "CRM Contact" = RIMD,
                  tabledata "CRM Customeraddress" = RIMD,
                  tabledata "CRM Organization" = RIMD,
                  tabledata "CRM Role" = RIMD,
                  tabledata "CRM Systemuser" = RIMD,
                  tabledata "CRM Systemuserroles" = RIMD,
                  tabledata "CRM Team" = RIMD,
                  tabledata "CRM Transactioncurrency" = RIMD;
}
