namespace System.Security.AccessControl;

#if not CLEAN22
using Microsoft.Finance.AuditFileExport;
using Microsoft.Finance.AutomaticAccounts;
#endif

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Caption = 'Country/region-specific read only access';
#if not CLEAN23
    Assignable = true;
    ObsoleteReason = 'The LOCAL READ permission set is obsolete, because it will be empty after SE delocalization process, it will be replaced by W1 version.';
    ObsoleteState = Pending;
    ObsoleteTag = '23.0';
#else
    Assignable = false;
#endif

#if not CLEAN22
    Permissions = tabledata "SIE Dimension" = R,
                  tabledata "Automatic Acc. Header" = R,
                  tabledata "Automatic Acc. Line" = R,
                  tabledata "SIE Import Buffer" = R;
#endif
}


