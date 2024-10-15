namespace System.Integration.PowerBI;

/// <summary>
/// Saves a list of reports to be displayed for a user in each specific context.
/// </summary>
table 6301 "Power BI Report Configuration"
{
    Caption = 'Power BI Report Configuration';
    ReplicateData = false;
    ObsoleteReason = 'Use table Power BI Selected Elements instead. The new table supports multiple types of embedded elements.';
#if not CLEAN23
    ObsoleteState = Pending;
    ObsoleteTag = '23.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '26.0';
#endif
    DataClassification = CustomerContent;

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
        field(50; "Report Page"; Text[200])
        {
            Caption = 'Report Page';
            DataClassification = CustomerContent;
        }
        field(51; "Show Panes"; Boolean)
        {
            Caption = 'Show Panes';
            DataClassification = SystemMetadata;
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

#if not CLEAN23
    trigger OnInsert()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
    begin
        if Rec.IsTemporary() then
            exit;

        if PowerBIDisplayedElement.Get(Rec."User Security ID", Rec."Report ID", Rec.Context) then
            exit;

        PowerBIDisplayedElement.Init();
        PowerBIDisplayedElement.UserSID := Rec."User Security ID";
        PowerBIDisplayedElement.Context := Rec.Context;
        PowerBIDisplayedElement.ElementId := Format(Rec."Report ID");
        PowerBIDisplayedElement.ElementType := PowerBIDisplayedElement.ElementType::Report;
        PowerBIDisplayedElement.ElementEmbedUrl := Rec.ReportEmbedUrl;
        PowerBIDisplayedElement.ElementName := Rec.ReportName;
        PowerBIDisplayedElement.WorkspaceID := Rec."Workspace ID";
        PowerBIDisplayedElement.WorkspaceName := Rec."Workspace Name";
        PowerBIDisplayedElement.ReportPage := Rec."Report Page";
        PowerBIDisplayedElement.ShowPanesInExpandedMode := Rec."Show Panes";
        PowerBIDisplayedElement.ShowPanesInNormalMode := Rec."Show Panes";
        PowerBIDisplayedElement.Insert();
    end;

    trigger OnModify()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
    begin
        if Rec.IsTemporary() then
            exit;

        if not PowerBIDisplayedElement.Get(Rec."User Security ID", Rec.Context, Format(Rec."Report ID"), Enum::"Power BI Element Type"::Report) then
            exit;

        PowerBIDisplayedElement.UserSID := Rec."User Security ID";
        PowerBIDisplayedElement.Context := Rec.Context;
        PowerBIDisplayedElement.ElementId := Format(Rec."Report ID");
        PowerBIDisplayedElement.ElementType := PowerBIDisplayedElement.ElementType::Report;
        PowerBIDisplayedElement.ElementEmbedUrl := Rec.ReportEmbedUrl;
        PowerBIDisplayedElement.ElementName := Rec.ReportName;
        PowerBIDisplayedElement.WorkspaceID := Rec."Workspace ID";
        PowerBIDisplayedElement.WorkspaceName := Rec."Workspace Name";
        PowerBIDisplayedElement.ReportPage := Rec."Report Page";
        PowerBIDisplayedElement.ShowPanesInExpandedMode := Rec."Show Panes";
        PowerBIDisplayedElement.ShowPanesInNormalMode := Rec."Show Panes";
        PowerBIDisplayedElement.Modify();
    end;

    trigger OnDelete()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
    begin
        if Rec.IsTemporary() then
            exit;

        if PowerBIDisplayedElement.Get(Rec."User Security ID", Rec.Context, Format(Rec."Report ID"), Enum::"Power BI Element Type"::Report) then
            PowerBIDisplayedElement.Delete();
    end;
#endif
}
