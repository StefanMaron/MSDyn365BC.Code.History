page 17445 "Time Activity Group Subform"
{
    Caption = 'Lines';
    PageType = ListPart;
    SourceTable = "Time Activity Filter";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first date on which activities are included in the view.';
                }
                field("Activity Code Filter"; "Activity Code Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which activity codes are included in the view. ';
                }
                field("Timesheet Code Filter"; "Timesheet Code Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which timesheets are included in the view. ';
                }
            }
        }
    }

    actions
    {
    }
}

