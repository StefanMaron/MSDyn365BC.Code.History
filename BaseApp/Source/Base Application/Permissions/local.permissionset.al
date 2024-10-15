namespace System.Security.AccessControl;

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
}
