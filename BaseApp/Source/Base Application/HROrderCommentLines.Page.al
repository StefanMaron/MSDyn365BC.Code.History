page 17394 "HR Order Comment Lines"
{
    AutoSplitKey = true;
    Caption = 'HR Order Comment Lines';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "HR Order Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the comment itself.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

