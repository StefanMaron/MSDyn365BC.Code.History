namespace System.Security.AccessControl;

using Microsoft.Finance.VAT.Setup;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions = tabledata "IRS Groups" = R,
                  tabledata "IRS Numbers" = R,
                  tabledata "IRS Types" = R;
}
