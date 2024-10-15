#if not CLEAN20
page 11783 "Multiple Interest Rates"
{
    Caption = 'Multiple Interest Rates (Obsolete)';
    DataCaptionFields = "Finance Charge Code";
    PageType = List;
    SourceTable = "Multiple Interest Rate";
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';
    ObsoleteReason = 'Replaced by Finance Charge Interest Rates';

    layout
    {
        area(content)
        {
            repeater(Control1220007)
            {
                ShowCaption = false;
                field("Valid from Date"; "Valid from Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date that will be used to determine the interest rate.';
                }
                field("Interest Rate"; "Interest Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage to use to calculate interest for this finance charge code.';
                }
                field("Interest Period (Days)"; "Interest Period (Days)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the length of the interest period in days.';
                }
                field("Use Due Date Interest Rate"; "Use Due Date Interest Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies using Due Date Interest Rate';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220002; Notes)
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

#endif