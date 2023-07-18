#if not CLEAN23
enum 9550 "Doc. Service Conflict Behavior"
{
    // These values map to an enum in the platform, and hence should not be extended by partners
    ObsoleteReason = 'Replaced with "Doc. Sharing Conflict Behavior" in System Application.';
    ObsoleteState = Pending;
    ObsoleteTag = '23.0';
    Extensible = false;

    value(0; Fail)
    {
    }
    value(1; Replace)
    {
    }
    value(2; Rename)
    {
    }
    value(3; Reuse)
    {
    }
}
#endif