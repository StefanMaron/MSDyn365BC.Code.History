page 12124 "Activity Codes"
{
    ApplicationArea = Basic, Suite;
    PageType = List;
    SourceTable = "Activity Code";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a number that identifies your company''s business, such as 12348, if your company conducts trade.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a text description of the activity code.';
                }
            }
        }
    }

    actions
    {
    }
}

