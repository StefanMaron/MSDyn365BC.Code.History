#if not CLEAN22
namespace System.Security.AccessControl;

using System.Tooling;

permissionset 7243 "User Groups - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'User Groups Setup';
    ObsoleteState = Pending;
    ObsoleteReason = 'The user group functionality is deprecated.';
    ObsoleteTag = '22.0';

    IncludedPermissionSets = "Permissions & Licenses - Edit";

    Permissions =
                  tabledata "User Group" = RIMD,
                  tabledata "User Group Access Control" = RIMD,
                  tabledata "User Group Member" = RIMD,
                  tabledata "User Group Permission Set" = RIMD,
                  tabledata "Recorded Event Buffer" = RIMD;
}
#endif
