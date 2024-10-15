page 28042 "WHT Revenue Types"
{
    ApplicationArea = Basic, Suite;
    Caption = 'WHT Revenue Types';
    PageType = List;
    SourceTable = "WHT Revenue Types";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1500000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies code for the Revenue Type.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description for the WHT Revenue Type.';
                }
                field(Sequence; Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the integer to group the Revenue Types.';
                }
            }
        }
    }

    actions
    {
    }
}

