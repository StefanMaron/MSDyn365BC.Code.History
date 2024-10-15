namespace System.Integration.PowerBI;

/// <summary>
/// Tracks if a user has active background sessions to deploy, delete or retry deployment of Power BI reports.
/// </summary>
table 6308 "Power BI Ongoing Deployments"
{
    Caption = 'Power BI Ongoing Deployments';
    DataPerCompany = false;
    ReplicateData = false;
    ObsoleteReason = 'Functionality has been moved to table 6325 "Power BI User Status" (notice: the new table is per company)';
    ObsoleteState = Removed;
    ObsoleteTag = '21.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            DataClassification = EndUserPseudonymousIdentifiers;
            Description = 'ID of the user, who each get one record in the table.';
        }
        field(2; "Is Deploying Reports"; Boolean)
        {
            Caption = 'Is Deploying Reports';
            DataClassification = CustomerContent;
            Description = 'Whether or not reports are currently being uploaded.';
        }
        field(3; "Is Retrying Uploads"; Boolean)
        {
            Caption = 'Is Retrying Uploads';
            DataClassification = CustomerContent;
            Description = 'Whether or not partial uploads are currently being finished.';
        }
        field(4; "Is Deleting Reports"; Boolean)
        {
            Caption = 'Is Deleting Reports';
            DataClassification = CustomerContent;
            Description = 'Whether or not reports are currently being deleted.';
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

