namespace Microsoft.Inventory.Item.Substitution;

page 5717 "Condition Entry"
{
    AutoSplitKey = true;
    Caption = 'Condition';
    PageType = List;
    SourceTable = "Substitution Condition";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Condition; Rec.Condition)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the condition for item substitution.';
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
    }
}

