page 17494 "Vacation Schedule Lines"
{
    Caption = 'Vacation Schedule Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Vacation Schedule Line";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("Calendar Days"; "Calendar Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of calendar days.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field("Actual Start Date"; "Actual Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the employee''s vacation.';
                }
                field("Carry Over Reason"; "Carry Over Reason")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Estimated Start Date"; "Estimated Start Date")
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

