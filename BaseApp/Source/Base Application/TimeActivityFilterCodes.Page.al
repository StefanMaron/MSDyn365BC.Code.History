page 17446 "Time Activity Filter Codes"
{
    Caption = 'Time Activity Filter Codes';
    PageType = List;
    SourceTable = "Time Activity Filter Code";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Activity Code"; "Activity Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the activity.';
                }
                field("Activity Description"; "Activity Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the activity.';
                }
            }
        }
    }

    actions
    {
    }
}

