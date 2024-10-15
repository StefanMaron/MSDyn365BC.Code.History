table 6302 "Power BI Report Buffer"
{
    Caption = 'Power BI Report Buffer';
    ReplicateData = false;
#if CLEAN18
    TableType = Temporary;
#else
    ObsoleteState = Pending;
    ObsoleteReason = 'This table should not contain any data and will be marked as TableType=Temporary. Make sure you are not saving any data in this table.';
    ObsoleteTag = '18.0';
#endif

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
#if not CLEAN16
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
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

