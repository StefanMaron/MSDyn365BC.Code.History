namespace System.Security.AccessControl;

#if not CLEAN24
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance;
#endif

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Caption = 'Country/region-specific read only access.';
#if not CLEAN24
    Assignable = true;
    ObsoleteReason = 'Moved to IS Core App.';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
#else
    Assignable = false;
#endif

#if not CLEAN24
    Permissions = tabledata "IRS Groups" = R,
                  tabledata "IRS Numbers" = R,
                  tabledata "IRS Types" = R,
                  tabledata "IS Core App Setup" = R;
#endif
}
