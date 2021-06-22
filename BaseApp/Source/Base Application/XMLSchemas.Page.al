page 9600 "XML Schemas"
{
    ApplicationArea = Basic, Suite;
    Caption = 'XML Schemas';
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Show';
    SourceTable = "XML Schema";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = Indentation;
                IndentationControls = "Code";
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the XML schema.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the XML schema file that has been loaded for the line.';
                }
                field("Target Namespace"; "Target Namespace")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the namespace of the XML schema file that has been loaded for the line.';
                }
                field("XSD.HASVALUE"; XSD.HasValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Schema is Loaded';
                    ToolTip = 'Specifies that an XML schema file has been loaded for the line.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control7; Notes)
            {
                ApplicationArea = Notes;
            }
            systempart(Control8; Links)
            {
                ApplicationArea = RecordLinks;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Load Schema")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Load Schema';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Load an XML schema into the database.';

                trigger OnAction()
                begin
                    LoadSchema;
                end;
            }
            action("Export Schema")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Schema';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Export an XML schema to a file.';

                trigger OnAction()
                begin
                    ExportSchema(true);
                end;
            }
            action("Open Schema Viewer")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open Schema Viewer';
                Image = ViewWorksheet;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View the XML schema of a file for which you want to create an XMLport or a data exchange definition so that users can import/export data to or from the file in question.';

                trigger OnAction()
                var
                    XMLSchemaViewer: Page "XML Schema Viewer";
                begin
                    XMLSchemaViewer.SetXMLSchemaCode(Code);
                    XMLSchemaViewer.Run;
                end;
            }
            action("Expand All")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Expand All';
                Image = ExpandAll;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'Expand all elements.';

                trigger OnAction()
                begin
                    SetRange(Indentation);
                end;
            }
            action("Collapse All")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Collapse All';
                Image = CollapseAll;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'Collapse all elements.';

                trigger OnAction()
                begin
                    SetRange(Indentation, 0);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetRange(Indentation, 0);
    end;
}

