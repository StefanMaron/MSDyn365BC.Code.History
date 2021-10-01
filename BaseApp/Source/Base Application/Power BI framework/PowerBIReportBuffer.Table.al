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
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(2; ReportName; Text[100])
        {
            Caption = 'ReportName';
            DataClassification = CustomerContent;
        }
        field(3; EmbedUrl; Text[250])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'The field has been extended to a bigger field. Use ReportEmbedUrl field instead.';
            Caption = 'EmbedUrl';
            DataClassification = CustomerContent;
            ObsoleteTag = '19.0';
        }
        field(4; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = SystemMetadata;
        }
        field(10; ReportEmbedUrl; Text[2048])
        {
            Caption = 'ReportEmbedUrl';
            DataClassification = CustomerContent;
        }
        field(20; "Workspace ID"; Guid)
        {
            Caption = 'Workspace ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(21; "Workspace Name"; Text[200])
        {
            Caption = 'Workspace Name';
            DataClassification = CustomerContent;
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
