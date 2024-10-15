page 7000026 "Operation Fees"
{
    Caption = 'Operation Fees';
    DataCaptionExpression = Caption;
    DataCaptionFields = "Currency Code";
    PageType = List;
    SourceTable = "Operation Fee";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Type of Fee"; "Type of Fee")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of operation for which the commission is being charged.';
                }
                field("Charge Amt. per Operation"; "Charge Amt. per Operation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of commission charged for each type of commission-based operation.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Fee")
            {
                Caption = '&Fee';
                Image = Costs;
                action("&Fee Ranges")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Fee Ranges';
                    Image = Ranges;
                    RunObject = Page "Fee Ranges";
                    RunPageLink = Code = FIELD(Code),
                                  "Currency Code" = FIELD("Currency Code"),
                                  "Type of Fee" = FIELD("Type of Fee");
                    ToolTip = 'View itemized bank charges for document management. There are seven different types of operations in the Cartera module: receivables management, discount management, discount interests, management of outstanding debt, payment orders management, factoring without risk management, and factoring with risk management.';
                }
            }
        }
    }
}

