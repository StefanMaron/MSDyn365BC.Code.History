page 31080 "Excel Template"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Excel Templates';
    PageType = List;
    SourceTable = "Excel Template";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1220008)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of excel template.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the excel template.';
                }
                field("Template.HASVALUE"; Template.HasValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Template';
                    Editable = false;
                    ToolTip = 'Specifies template';
                }
                field(Sheet; Sheet)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies sheet of excel template';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to block of the excel template.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Import)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import';
                Image = Import;
                ToolTip = 'Allows to import of excel template into system.';

                trigger OnAction()
                begin
                    ImportFile('', false);
                end;
            }
            action(Open)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open';
                Image = Open;
                ToolTip = 'Enables to open the excel template.';

                trigger OnAction()
                begin
                    ShowFile(false);
                end;
            }
            action(Export)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export';
                Image = Export;
                ToolTip = 'Allows the excel template export.';

                trigger OnAction()
                var
                    FileName: Text[250];
                begin
                    ExportToClientFile(FileName);
                end;
            }
            action(Delete)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete';
                Image = Delete;
                ToolTip = 'Enables to delete the excel template.';

                trigger OnAction()
                begin
                    RemoveTemplate(true);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcFields(Template);
    end;
}

