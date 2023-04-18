page 65 "Rounding Methods"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Rounding Methods';
    PageType = List;
    SourceTable = "Rounding Method";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the rounding method for item prices.';
                }
                field("Minimum Amount"; Rec."Minimum Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minimum amount to round.';
                }
                field("Amount Added Before"; Rec."Amount Added Before")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an amount to add before it is rounded.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to round.';
                }
                field(Precision; Precision)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the size of the interval that you want between rounded amounts.';
                }
                field("Amount Added After"; Rec."Amount Added After")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an amount to add, after the amount has been rounded.';
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

