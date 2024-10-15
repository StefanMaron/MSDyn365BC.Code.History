page 10701 "Non-Payment Periods"
{
    Caption = 'Non-Payment Periods';
    DataCaptionFields = "Code";
    PageType = List;
    SourceTable = "Non-Payment Period";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("From Date"; "From Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the non-payment period.';
                }
                field("To Date"; "To Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date of the non-payment period.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the non-payment period.';
                }
            }
        }
    }

    actions
    {
    }
}

