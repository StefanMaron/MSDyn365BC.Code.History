page 12174 "Stop Payment Periods"
{
    Caption = 'Stop Payment Periods';
    DataCaptionFields = "No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Deferring Due Dates";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("From-Date"; "From-Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the time period in which payments are not allowed.';
                }
                field("To-Date"; "To-Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date of the time period in which payments are not allowed.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the deferring due dates.';
                }
                field("Due Date Calculation"; "Due Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the formula that is used to calculate the time period in which payments are not allowed.';
                }
            }
        }
    }

    actions
    {
    }
}

