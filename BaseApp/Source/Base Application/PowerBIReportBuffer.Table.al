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
            ObsoleteState = Pending;
            ObsoleteReason = 'The field has been extended to a bigger field. Use ReportEmbedUrl field instead.';
            Caption = 'EmbedUrl';
            DataClassification = SystemMetadata;
            ObsoleteTag = '16.0';
        }
        field(4; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = SystemMetadata;
        }
        field(10; ReportEmbedUrl; Text[2048])
        {
            Caption = 'ReportEmbedUrl';
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

