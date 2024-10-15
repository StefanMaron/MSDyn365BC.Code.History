namespace System.Security.AccessControl;

#if not CLEAN22
using Microsoft.Finance.AuditFileExport;
using Microsoft.Finance.AutomaticAccounts;
#endif

permissionset 1001 "LOCAL"
{
    Access = Public;
    Caption = 'Country/region-specific func.';
#if not CLEAN23
    Assignable = true;
    ObsoleteReason = 'The LOCAL permission set is obsolete, because it will be empty after SE delocalization process, it will be replaced by W1 version.';
    ObsoleteState = Pending;
    ObsoleteTag = '23.0';

    IncludedPermissionSets = "LOCAL READ";
#else
    Assignable = false;
#endif


#if not CLEAN22
    Permissions = tabledata "SIE Dimension" = IMD,
                  tabledata "Automatic Acc. Header" = IMD,
                  tabledata "Automatic Acc. Line" = IMD,
                  tabledata "SIE Import Buffer" = IMD;
#endif
}
