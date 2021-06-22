page 572 "Finance Charge Interest Rates"
{
    Caption = 'Finance Charge Interest Rates';
    PageType = List;
    SourceTable = "Finance Charge Interest Rate";

    layout
    {
        area(content)
        {
            repeater(Control4)
            {
                ShowCaption = false;
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date for the interest rate.';
                }
                field("Interest Rate"; "Interest Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the interest rate percentage.';
                }
                field("Interest Period (Days)"; "Interest Period (Days)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of days in the interest period.';
                }
            }
        }
    }

    actions
    {
    }
}

