page 1289 "Additional Match Details"
{
    Caption = 'Additional Match Details';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Payment Matching Details";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Message; Message)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    ToolTip = 'Specifies if a message with additional match details exists.';
                    Width = 250;
                }
            }
        }
    }

    actions
    {
    }
}

