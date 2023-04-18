page 5196 "Task Interaction Languages"
{
    Caption = 'Task Interaction Languages';
    PageType = List;
    SourceTable = "To-do Interaction Language";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the interaction template that you have chosen for the task.';
                }
                field("""Attachment No."" > 0"; Rec."Attachment No." > 0)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    Caption = 'Attachment';
                    ToolTip = 'Specifies if the linked attachment is inherited or unique.';

                    trigger OnAssistEdit()
                    begin
                        if "Attachment No." = 0 then
                            CreateAttachment(("To-do No." = '') or Task.Closed)
                        else
                            OpenAttachment(("To-do No." = '') or Task.Closed);
                        CurrPage.Update();
                    end;
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
            group(Attachment)
            {
                Caption = '&Attachment';
                Image = Attachments;
                action(Open)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open';
                    Image = Edit;
                    ShortCutKey = 'Return';
                    ToolTip = 'Open the card for the selected record.';

                    trigger OnAction()
                    begin
                        OpenAttachment(("To-do No." = '') or Task.Closed);
                    end;
                }
                action(Create)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create';
                    Ellipsis = true;
                    Image = New;
                    ToolTip = 'Create an attachment.';

                    trigger OnAction()
                    begin
                        CreateAttachment(("To-do No." = '') or Task.Closed);
                    end;
                }
                action("Copy &from")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy &from';
                    Ellipsis = true;
                    Image = Copy;
                    ToolTip = 'Copy from an attachment.';

                    trigger OnAction()
                    begin
                        CopyFromAttachment();
                    end;
                }
                action(Import)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import an attachment.';

                    trigger OnAction()
                    begin
                        ImportAttachment();
                    end;
                }
                action("E&xport")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xport';
                    Ellipsis = true;
                    Image = Export;
                    ToolTip = 'Export an attachment.';

                    trigger OnAction()
                    begin
                        ExportAttachment();
                    end;
                }
                action(Remove)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove';
                    Ellipsis = true;
                    Image = Cancel;
                    ToolTip = 'Remove an attachment.';

                    trigger OnAction()
                    begin
                        RemoveAttachment(true);
                    end;
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        RecordsFound: Boolean;
    begin
        RecordsFound := Find(Which);
        CurrPage.Editable := ("To-do No." <> '');
        if Task.Get("To-do No.") then
            CurrPage.Editable := not Task.Closed;

        exit(RecordsFound);
    end;

    var
        Task: Record "To-do";
}

