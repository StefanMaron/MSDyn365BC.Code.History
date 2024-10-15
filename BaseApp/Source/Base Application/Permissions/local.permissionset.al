namespace System.Security.AccessControl;

#if not CLEAN24
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance;
#endif

permissionset 1001 "LOCAL"
{
#if not CLEAN24
    Assignable = true;
    ObsoleteReason = 'The LOCAL permission set is obsolete, because it will be empty after IS delocalization process, it will be replaced by W1 version.';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';

    IncludedPermissionSets = "LOCAL READ";
#else
    Assignable = false;
#endif

#if not CLEAN24
    Permissions = tabledata "IRS Groups" = RIMD,
                  tabledata "IRS Numbers" = RIMD,
                  tabledata "IRS Types" = RIMD,
                  tabledata "IS Core App Setup" = RIMD;
#endif
}
