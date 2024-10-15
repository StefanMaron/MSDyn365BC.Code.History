/// <summary>
/// Stores which user has seen the What's New Wizard page.
/// </summary>
table 897 "What's New Notified"
{
    Access = Internal;
    DataPerCompany = false;
    ObsoleteState = Removed;
    ObsoleteReason = 'Temporary solution';
    ObsoleteTag = '19.0';
    ReplicateData = false;

    DataClassification = SystemMetadata;

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            DataClassification = SystemMetadata;
        }

        field(2; "Application Version"; Code[10])
        {
            DataClassification = SystemMetadata;
        }

        field(3; "Date Notified"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "User Security ID", "Application Version")
        {
            Clustered = true;
        }
    }
}