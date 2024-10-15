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
    value(4; Appreciation)
    {
        Caption = 'Appreciation';
    }
}
