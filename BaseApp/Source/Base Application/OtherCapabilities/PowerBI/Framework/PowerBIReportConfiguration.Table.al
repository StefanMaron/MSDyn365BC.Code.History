/// <summary>
/// Saves a list of reports to be displayed for a user in each specific context.
/// </summary>
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
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(3; Context; Text[30])
        {
            Caption = 'Context';
            Description = 'Identifies the page, role center, or other host container the report is selected for.';
            DataClassification = CustomerContent;
        }
        field(4; EmbedUrl; Text[250])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'The field has been extended to a bigger field. Use ReportEmbedUrl field instead.';
            Caption = 'EmbedUrl';
            DataClassification = CustomerContent;
            Description = 'Cached display URL.';
            ObsoleteTag = '19.0';
        }
        field(5; ReportName; Text[200])
        {
            Caption = 'ReportName';
            DataClassification = CustomerContent;
        }
        field(10; ReportEmbedUrl; Text[2048])
        {
            Caption = 'ReportEmbedUrl';
            DataClassification = CustomerContent;
            Description = 'Cached display URL.';
        }
        field(20; "Workspace ID"; Guid)
        {
            Caption = 'Workspace ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(21; "Workspace Name"; Text[200])
        {
            Caption = 'Workspace Display Name';
            DataClassification = CustomerContent;
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
