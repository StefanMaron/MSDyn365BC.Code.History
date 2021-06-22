page 725 "Custom Address Format"
{
    Caption = 'Custom Address Format';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Custom Address Format";
    SourceTableView = SORTING("Country/Region Code", "Line Position");

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Field ID"; "Field ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies reference field ID.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupField;
                    end;
                }
                field("Line Format"; "Line Format")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    Editable = false;
                    ToolTip = 'Specifies address format fields.';

                    trigger OnAssistEdit()
                    begin
                        ShowCustomAddressFormatLines;
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Move Up")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Move Up';
                Image = MoveUp;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Move current line up.';

                trigger OnAction()
                begin
                    MoveLine(-1);
                end;
            }
            action("Move Down")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Move Down';
                Image = MoveDown;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Move current line down.';

                trigger OnAction()
                begin
                    MoveLine(1);
                end;
            }
        }
    }
}

