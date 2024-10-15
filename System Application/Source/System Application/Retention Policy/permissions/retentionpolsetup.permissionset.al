/// <summary>
/// this permission set is required to create retention policies
/// </summary>
#if not CLEAN18
permissionset 3903 "RETENTION POL. SETUP"
{
    Access = Public;
    Assignable = true;
    Caption = '(Obsolete) Reten. Pol. Setup';

    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced with PermissionSet Retention Pol. Admin';
    ObsoleteTag = '18.0';

    IncludedPermissionSets = "Retention Policy - Admin";
}
#endif