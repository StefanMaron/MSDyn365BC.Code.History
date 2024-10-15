namespace System.Integration.PowerBI;

/// <summary>
/// Caches the validity of the Power BI license for a user.
/// </summary>
table 6311 "Power BI User License"
{
    Caption = 'Power BI User License';
    DataPerCompany = false;
    ReplicateData = false;
    ObsoleteReason = 'Caching the license state caused a degraded user experience. Power BI license will be checked just in time.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            DataClassification = EndUserPseudonymousIdentifiers;
            Description = 'User security Id.';
        }
        field(2; "Has Power BI License"; Boolean)
        {
            Caption = 'Has Power BI License';
            DataClassification = SystemMetadata;
            Description = 'Value indicating whether user has power bi license or not.';
        }
    }

    keys
    {
        key(Key1; "User Security ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

