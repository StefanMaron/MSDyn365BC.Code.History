table 6301 "Power BI Report Configuration"
{
    Caption = 'Power BI Report Configuration';
    ReplicateData = false;

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(2; "Report ID"; Guid)
        {
            Caption = 'Report ID';
        }
        field(3; Context; Text[30])
        {
            Caption = 'Context';
            Description = 'Identifies the page, role center, or other host container the report is selected for.';
        }
        field(4; EmbedUrl; Text[250])
        {
            Caption = 'EmbedUrl';
            DataClassification = CustomerContent;
            Description = 'Cached display URL.';
        }
    }

    keys
    {
        key(Key1; "User Security ID", "Report ID", Context)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

