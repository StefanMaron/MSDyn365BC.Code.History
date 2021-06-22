table 6302 "Power BI Report Buffer"
{
    Caption = 'Power BI Report Buffer';
    ReplicateData = false;

    fields
    {
        field(1; ReportID; Guid)
        {
            Caption = 'ReportID';
            DataClassification = SystemMetadata;
        }
        field(2; ReportName; Text[100])
        {
            Caption = 'ReportName';
            DataClassification = SystemMetadata;
        }
        field(3; EmbedUrl; Text[250])
        {
            Caption = 'EmbedUrl';
            DataClassification = SystemMetadata;
        }
        field(4; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; ReportID)
        {
            Clustered = true;
        }
        key(Key2; ReportName)
        {
        }
    }

    fieldgroups
    {
    }
}

