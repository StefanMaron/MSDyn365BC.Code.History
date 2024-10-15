namespace System.Security.AccessControl;

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
}


