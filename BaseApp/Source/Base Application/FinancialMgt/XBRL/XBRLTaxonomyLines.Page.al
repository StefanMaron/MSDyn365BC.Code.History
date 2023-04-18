#if not CLEAN20
page 583 "XBRL Taxonomy Lines"
{
    Caption = 'XBRL Taxonomy Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "XBRL Taxonomy Line";
    SourceTableView = SORTING("XBRL Taxonomy Name", "Presentation Order");
    ObsoleteReason = 'XBRL feature will be discontinued';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrentTaxonomy; CurrentTaxonomy)
                {
                    ApplicationArea = XBRL;
                    Caption = 'Taxonomy Name';
                    Editable = false;
                    TableRelation = "XBRL Taxonomy";
                    ToolTip = 'Specifies the name of the XBRL taxonomy.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        XBRLTaxonomy: Record "XBRL Taxonomy";
                    begin
                        XBRLTaxonomy.Name := CurrentTaxonomy;
                        if PAGE.RunModal(0, XBRLTaxonomy) <> ACTION::LookupOK then
                            exit(false);

                        CurrentTaxonomy := XBRLTaxonomy.Name;
                        CurrentTaxonomyOnAfterValidate();
                        Text := XBRLTaxonomy.Name;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        CurrentTaxonomyOnAfterValidate();
                    end;
                }
                field(OnlyShowPresentation; OnlyShowPresentation)
                {
                    ApplicationArea = XBRL;
                    Caption = 'Show Only Presentation';
                    ToolTip = 'Specifies if the XBRL content is shown using the Presentation layout only, which provides information about the structure and relationships of elements on the taxonomy lines.';

                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;
                }
                field(CurrentLang; CurrentLang)
                {
                    ApplicationArea = XBRL;
                    Caption = 'Label Language';
                    ToolTip = 'Specifies the language you want the labels to be shown in. The label is a user-readable element of the taxonomy.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        XBRLTaxonomyLabel: Record "XBRL Taxonomy Label";
                        XBRLTaxonomyLabels: Page "XBRL Taxonomy Labels";
                    begin
                        XBRLTaxonomyLabel.SetRange("XBRL Taxonomy Name", CurrentTaxonomy);
                        if not XBRLTaxonomyLabel.FindFirst() then
                            Error(Text002, "XBRL Taxonomy Name");
                        XBRLTaxonomyLabel.SetRange(
                          "XBRL Taxonomy Line No.", XBRLTaxonomyLabel."XBRL Taxonomy Line No.");
                        XBRLTaxonomyLabels.SetTableView(XBRLTaxonomyLabel);
                        XBRLTaxonomyLabels.LookupMode := true;
                        if XBRLTaxonomyLabels.RunModal() = ACTION::LookupOK then begin
                            XBRLTaxonomyLabels.GetRecord(XBRLTaxonomyLabel);
                            Text := XBRLTaxonomyLabel."XML Language Identifier";
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    var
                        XBRLTaxonomyLabel: Record "XBRL Taxonomy Label";
                    begin
                        XBRLTaxonomyLabel.SetRange("XBRL Taxonomy Name", CurrentTaxonomy);
                        XBRLTaxonomyLabel.SetRange("XML Language Identifier", CurrentLang);
                        if CurrentLang <> '' then
                            if XBRLTaxonomyLabel.IsEmpty() then
                                Error(Text001, CurrentLang);
                        SetFilters();
                    end;
                }
            }
            repeater(Control1)
            {
                IndentationColumn = Level;
                IndentationControls = Label;
                ShowAsTree = true;
                ShowCaption = false;
                field(Label; Label)
                {
                    ApplicationArea = XBRL;
                    DrillDown = false;
                    Style = Strong;
                    StyleExpr = LabelEmphasize;
                    ToolTip = 'Specifies the label that was assigned to this line. The label is a user-readable element of the taxonomy.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the source of the information for this line that you want to export. You can only export one type of information for each line. The Tuple option means that the line represents a number of related lines. The related lines are listed below this line and are indented.';
                }
                field("Constant Amount"; Rec."Constant Amount")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the amount that will be exported if the source type is Constant.';
                }
                field(Control10; Information)
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies if there is information in the Comment table about this line. The information was imported from the info attribute when the taxonomy was imported.';

                    trigger OnDrillDown()
                    begin
                        OpenInformation();
                    end;
                }
                field(Control32; Reference)
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies if the Comment table contains a reference to official material that you can read about this line. The reference was imported from the reference linkbase when the taxonomy was imported.';

                    trigger OnDrillDown()
                    begin
                        OpenReference();
                    end;
                }
                field(Control12; Notes)
                {
                    ApplicationArea = XBRL;
                    Editable = false;
                    ToolTip = 'Specifies if there are notes entered in the Comment table about this line element.';

                    trigger OnDrillDown()
                    begin
                        OpenNotes();
                    end;
                }
                field("G/L Map Lines"; Rec."G/L Map Lines")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies which general ledger accounts will be used to calculate the amount that will be exported for this line.';

                    trigger OnDrillDown()
                    begin
                        OpenGLMapLines();
                    end;
                }
                field(Rollup; Rollup)
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies if there are records in the Rollup Line table about this line. This data was imported when the taxonomy was imported.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the text that will be exported if the source type is Description. You can create a description formula using codes. Examples: %1: End of Financial Period - Day of Month (1 - 31) %2: End of Financial Period - Day of Month (01 - 31). See more codes the help topic for the Description field.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the name that the program assigned to this line. This field is populated during the import of the taxonomy.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part("Reference/Information"; "XBRL Comment Lines Part")
            {
                ApplicationArea = XBRL;
                Caption = 'Reference/Information';
                SubPageLink = "XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"),
                              "XBRL Taxonomy Line No." = FIELD("Line No."),
                              "Comment Type" = FILTER(Information | Reference);
            }
            part(Control7; "XBRL Comment Lines Part")
            {
                ApplicationArea = XBRL;
                Caption = 'Notes';
                SubPageLink = "XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"),
                              "XBRL Taxonomy Line No." = FIELD("Line No."),
                              "Comment Type" = CONST(Notes),
                              "Label Language Filter" = FIELD("Label Language Filter");
            }
            part("G/L Map"; "XBRL G/L Map Lines Part")
            {
                ApplicationArea = XBRL;
                Caption = 'G/L Map';
                SubPageLink = "XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"),
                              "XBRL Taxonomy Line No." = FIELD("Line No."),
                              "Label Language Filter" = FIELD("Label Language Filter");
            }
            part(Control13; "XBRL Line Constants Part")
            {
                ApplicationArea = XBRL;
                Caption = 'Constants';
                SubPageLink = "XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"),
                              "XBRL Taxonomy Line No." = FIELD("Line No."),
                              "Label Language Filter" = FIELD("Label Language Filter");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&XBRL Line")
            {
                Caption = '&XBRL Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = XBRL;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "XBRL Taxonomy Line Card";
                    RunPageLink = "XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"),
                                  "Line No." = FIELD("Line No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                separator(Action23)
                {
                    Caption = '';
                }
                action(Information)
                {
                    ApplicationArea = XBRL;
                    Caption = 'Information';
                    Image = Info;
                    ToolTip = 'View information in the Comment table about this line. The information was imported from the info attribute when the taxonomy was imported.';

                    trigger OnAction()
                    begin
                        OpenInformation();
                    end;
                }
                action(Reference)
                {
                    ApplicationArea = XBRL;
                    Caption = 'Re&ference';
                    Image = EntriesList;
                    ToolTip = 'View if the Comment table contains a reference to official material that you can read about this line. The reference was imported from the reference linkbase when the taxonomy was imported.';

                    trigger OnAction()
                    begin
                        OpenReference();
                    end;
                }
                action(Rollups)
                {
                    ApplicationArea = XBRL;
                    Caption = 'Rollups';
                    Image = Totals;
                    ToolTip = 'View how XBRL information is rolled up from other lines.';

                    trigger OnAction()
                    var
                        XBRLRollupLine: Record "XBRL Rollup Line";
                    begin
                        XBRLRollupLine.FilterGroup(2);
                        XBRLRollupLine.SetRange("XBRL Taxonomy Name", "XBRL Taxonomy Name");
                        XBRLRollupLine.SetRange("XBRL Taxonomy Line No.", "Line No.");
                        XBRLRollupLine.SetRange("Label Language Filter", "Label Language Filter");
                        XBRLRollupLine.FilterGroup(0);

                        PAGE.RunModal(PAGE::"XBRL Rollup Lines", XBRLRollupLine);
                    end;
                }
                action(Notes)
                {
                    ApplicationArea = XBRL;
                    Caption = 'Notes';
                    Image = Notes;
                    ToolTip = 'View any notes entered in the Comment table about this line element.';

                    trigger OnAction()
                    begin
                        OpenNotes();
                    end;
                }
                action(GLMapLines)
                {
                    ApplicationArea = XBRL;
                    Caption = 'G/L Map Lines';
                    Image = CompareCOA;
                    ToolTip = 'View which general ledger accounts will be used to calculate the amount that will be exported for this line.';

                    trigger OnAction()
                    begin
                        OpenGLMapLines();
                    end;
                }
                action(Constants)
                {
                    ApplicationArea = XBRL;
                    Caption = 'C&onstants';
                    Image = AmountByPeriod;
                    ToolTip = 'View or create date-specific constant amounts to be exported.';

                    trigger OnAction()
                    var
                        XBRLLineConstant: Record "XBRL Line Constant";
                    begin
                        XBRLLineConstant.FilterGroup(2);
                        XBRLLineConstant.SetRange("XBRL Taxonomy Name", "XBRL Taxonomy Name");
                        XBRLLineConstant.SetRange("XBRL Taxonomy Line No.", "Line No.");
                        XBRLLineConstant.SetRange("Label Language Filter", "Label Language Filter");
                        XBRLLineConstant.FilterGroup(0);

                        PAGE.RunModal(PAGE::"XBRL Line Constants", XBRLLineConstant);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CopyXBRLSetup)
                {
                    ApplicationArea = XBRL;
                    Caption = 'Copy XBRL Setup';
                    Ellipsis = true;
                    Image = Copy;
                    ToolTip = 'Copy the setup of one taxonomy to another. The setup includes description, constant amount, notes, and G/L map lines.';

                    trigger OnAction()
                    var
                        XBRLCopySetup: Report "XBRL Copy Setup";
                    begin
                        XBRLCopySetup.SetCopyTo(CurrentTaxonomy);
                        XBRLCopySetup.Run();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Notes_Promoted; Notes)
                {
                }
                actionref(GLMapLines_Promoted; GLMapLines)
                {
                }
                actionref(Constants_Promoted; Constants)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Label = '' then
            Label := Name;
        LabelOnFormat();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if not FiltersApplied then
            SetFilters();
        FiltersApplied := true;
        exit(Find(Which));
    end;

    trigger OnOpenPage()
    var
        XBRLTaxonomy: Record "XBRL Taxonomy";
        XBRLTaxonomyLabel: Record "XBRL Taxonomy Label";
        XBRLDeprecationNotification: Codeunit "XBRL Deprecation Notification";
    begin
        XBRLDeprecationNotification.Show();
        if GetFilter("XBRL Taxonomy Name") <> '' then
            CurrentTaxonomy := GetRangeMin("XBRL Taxonomy Name");
        if not XBRLTaxonomy.Get(CurrentTaxonomy) then
            if not XBRLTaxonomy.FindFirst() then
                XBRLTaxonomy.Init();
        CurrentTaxonomy := XBRLTaxonomy.Name;

        XBRLTaxonomyLabel.SetRange("XBRL Taxonomy Name", CurrentTaxonomy);
        if CurrentLang <> '' then
            XBRLTaxonomyLabel.SetRange("XML Language Identifier", CurrentLang);
        if XBRLTaxonomyLabel.FindFirst() then
            CurrentLang := XBRLTaxonomyLabel."XML Language Identifier"
        else
            if CurrentLang <> '' then begin
                XBRLTaxonomyLabel.SetRange("XML Language Identifier");
                if XBRLTaxonomyLabel.FindFirst() then
                    CurrentLang := XBRLTaxonomyLabel."XML Language Identifier"
            end;
    end;

    var
        CurrentTaxonomy: Code[20];
        CurrentLang: Text[10];
        Text001: Label 'Labels are not defined for language %1.';
        Text002: Label 'There are no labels defined for %1.';
        OnlyShowPresentation: Boolean;
        [InDataSet]
        LabelEmphasize: Boolean;
        FiltersApplied: Boolean;

    procedure SetCurrentSchema(NewCurrentTaxonomy: Code[20])
    begin
        CurrentTaxonomy := NewCurrentTaxonomy;
        ResetFilter();
    end;

    local procedure SetFilters()
    begin
        SetRange("Label Language Filter", CurrentLang);
        if OnlyShowPresentation then
            SetFilter("Presentation Linkbase Line No.", '>0')
        else
            SetRange("Presentation Linkbase Line No.");
        CurrPage.Update(false);
    end;

    local procedure ResetFilter()
    begin
        Reset();
        SetRange("XBRL Taxonomy Name", CurrentTaxonomy);
        FilterGroup(0);
        SetFilters();
    end;

    local procedure CurrentTaxonomyOnAfterValidate()
    begin
        ResetFilter();
    end;

    local procedure LabelOnFormat()
    begin
        LabelEmphasize := Level = 0;
    end;

    local procedure OpenInformation()
    var
        XBRLCommentLine: Record "XBRL Comment Line";
    begin
        XBRLCommentLine.FilterGroup(2);
        XBRLCommentLine.SetRange("XBRL Taxonomy Name", "XBRL Taxonomy Name");
        XBRLCommentLine.SetRange("XBRL Taxonomy Line No.", "Line No.");
        XBRLCommentLine.SetRange("Comment Type", XBRLCommentLine."Comment Type"::Information);
        XBRLCommentLine.SetRange("Label Language Filter", "Label Language Filter");
        XBRLCommentLine.FilterGroup(0);

        PAGE.RunModal(PAGE::"XBRL Comment Lines", XBRLCommentLine);
    end;

    local procedure OpenReference()
    var
        XBRLCommentLine: Record "XBRL Comment Line";
    begin
        XBRLCommentLine.FilterGroup(2);
        XBRLCommentLine.SetRange("XBRL Taxonomy Name", "XBRL Taxonomy Name");
        XBRLCommentLine.SetRange("XBRL Taxonomy Line No.", "Line No.");
        XBRLCommentLine.SetRange("Comment Type", XBRLCommentLine."Comment Type"::Reference);
        XBRLCommentLine.SetRange("Label Language Filter", "Label Language Filter");
        XBRLCommentLine.FilterGroup(0);

        PAGE.RunModal(PAGE::"XBRL Comment Lines", XBRLCommentLine);
    end;

    local procedure OpenNotes()
    var
        XBRLCommentLine: Record "XBRL Comment Line";
    begin
        XBRLCommentLine.FilterGroup(2);
        XBRLCommentLine.SetRange("XBRL Taxonomy Name", "XBRL Taxonomy Name");
        XBRLCommentLine.SetRange("XBRL Taxonomy Line No.", "Line No.");
        XBRLCommentLine.SetRange("Comment Type", XBRLCommentLine."Comment Type"::Notes);
        XBRLCommentLine.SetRange("Label Language Filter", "Label Language Filter");
        XBRLCommentLine.FilterGroup(0);

        PAGE.RunModal(PAGE::"XBRL Comment Lines", XBRLCommentLine);
    end;

    local procedure OpenGLMapLines()
    var
        XBRLGLMapLine: Record "XBRL G/L Map Line";
    begin
        XBRLGLMapLine.FilterGroup(2);
        XBRLGLMapLine.SetRange("XBRL Taxonomy Name", "XBRL Taxonomy Name");
        XBRLGLMapLine.SetRange("XBRL Taxonomy Line No.", "Line No.");
        XBRLGLMapLine.SetRange("Label Language Filter", "Label Language Filter");
        XBRLGLMapLine.FilterGroup(0);

        PAGE.RunModal(PAGE::"XBRL G/L Map Lines", XBRLGLMapLine);
    end;
}


#endif