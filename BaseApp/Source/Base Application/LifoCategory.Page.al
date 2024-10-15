page 12128 "Lifo Category"
{
    Caption = 'Lifo Category';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Lifo Category";

    layout
    {
        area(content)
        {
            repeater(Control1130001)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a LIFO category code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the LIFO category.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("LIFO Band")
            {
                Caption = 'LIFO Band';
                Image = LIFO;
                action("LIFO Band List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LIFO Band List';
                    Image = LIFO;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View details related to year-end inventory LIFO valuations.';

                    trigger OnAction()
                    begin
                        LIFOBandList.Editable(false);
                        LIFOBandList.Run;
                    end;
                }
            }
        }
    }

    var
        LIFOBandList: Page "Lifo Band List";
}

