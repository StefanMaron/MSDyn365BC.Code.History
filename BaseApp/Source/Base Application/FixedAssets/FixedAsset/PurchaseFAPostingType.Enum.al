namespace Microsoft.FixedAssets.Posting;

enum 5607 "Purchase FA Posting Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; "Acquisition Cost")
    {
        Caption = 'Acquisition Cost';
    }
    value(2; Maintenance)
    {
        Caption = 'Maintenance';
    }
#if not CLEAN22
    value(3; "Custom 2")
    {
        Caption = 'Custom 2 (Obsolete)';
        ObsoleteReason = 'Moved to Fixed Asset Localization for Czech.';
        ObsoleteState = Pending;
        ObsoleteTag = '21.0';
    }
#endif
    value(4; Appreciation)
    {
        Caption = 'Appreciation';
    }
}
