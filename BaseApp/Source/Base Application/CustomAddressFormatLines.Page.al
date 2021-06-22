page 726 "Custom Address Format Lines"
{
    Caption = 'Custom Address Format Lines';
    PageType = List;
    SourceTable = "Custom Address Format Line";
    SourceTableView = SORTING("Country/Region Code", "Line No.", "Field Position");

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
                field("Field Name"; "Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies reference address field name.';
                }
                field(Separator; Separator)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies separator symbol.';
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

