table 6308 "Power BI Ongoing Deployments"
{
    // // Table for globally tracking when user is waiting on background sessions to deploy
    // // default Power BI reports. Makes it easier to tell when these tasks are done, especially
    // // across multiple pages.

    Caption = 'Power BI Ongoing Deployments';
    DataPerCompany = false;
    ReplicateData = false;

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

