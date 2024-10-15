#if not CLEAN21
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
    value(3; "Custom 2")
    {
        Caption = 'Custom 2 (Obsolete)';
        ObsoleteState = Pending;
        ObsoleteReason = 'Moved to Fixed Asset Localization for Czech.';
        ObsoleteTag = '21.0';
    }
    value(4; Appreciation)
    {
        Caption = 'Appreciation';
    }
}
#endif
