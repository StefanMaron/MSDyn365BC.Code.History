page 582 "XBRL Taxonomies"
{
    ApplicationArea = XBRL;
    Caption = 'XBRL Taxonomies';
    PageType = List;
    SourceTable = "XBRL Taxonomy";
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the name of the XBRL taxonomy.';
                }
                field(Description; Description)
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies a description of the XBRL taxonomy name.';
                }
                field(targetNamespace; targetNamespace)
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the uniform resource identifier (URI) for the namespace if there is an overall targetNamespace for this taxonomy.';

                    trigger OnAssistEdit()
                    var
                        XBRLImport: Codeunit "XBRL Import Taxonomy Spec. 2";
                        Newxmlns: Text[1024];
                        FileName: Text[1024];
                    begin
                        FileName := schemaLocation;
                        Newxmlns := XBRLImport.ReadNamespaceFromSchema(FileName);
                        if Newxmlns <> '' then begin
                            targetNamespace := CopyStr(Newxmlns, 1, MaxStrLen(targetNamespace));
                            if schemaLocation = '' then
                                schemaLocation := CopyStr(FileName, 1, MaxStrLen(schemaLocation));
                        end;
                    end;
                }
                field(schemaLocation; schemaLocation)
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the uniform resource identifier (URI) of the schema file if there is an overall targetNamespace for this taxonomy.';
                }
                field("xmlns:xbrli"; "xmlns:xbrli")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the uniform resource identifier (uri) for the version of the specification.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ta&xonomy")
            {
                Caption = 'Ta&xonomy';
                Image = Line;
                action(Lines)
                {
                    ApplicationArea = XBRL;
                    Caption = 'Lines';
                    Image = AllLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    RunObject = Page "XBRL Taxonomy Lines";
                    RunPageLink = "XBRL Taxonomy Name" = FIELD(Name);
                    ToolTip = 'View the XBRL lines. The XBRL Taxonomies Lines window contains all definitions that exist within a given taxonomy and you can assign information to each line.';
                }
                separator(Action12)
                {
                }
                action(Schemas)
                {
                    ApplicationArea = XBRL;
                    Caption = 'Schemas';
                    Image = Documents;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    RunObject = Page "XBRL Schemas";
                    RunPageLink = "XBRL Taxonomy Name" = FIELD(Name);
                    ToolTip = 'View the XBRL schemas.';
                }
            }
        }
    }
}

