page 7000063 "Customer Ratings"
{
    Caption = 'Customer Ratings';
    DataCaptionExpression = Caption;
    PageType = List;
    SourceTable = "Customer Rating";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer number for which the risk percentage will be defined by this bank.';
                }
                field("Risk Percentage"; "Risk Percentage")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the risk percentages assigned by the bank to the different customers.';
                }
            }
        }
    }

    actions
    {
    }
}

