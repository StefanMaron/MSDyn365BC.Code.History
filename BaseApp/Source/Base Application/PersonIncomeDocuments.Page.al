page 17497 "Person Income Documents"
{
    Caption = 'Person Income Documents';
    Editable = false;
    PageType = List;
    SourceTable = "Person Income Header";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Person No."; "Person No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Total Income (Doc)"; "Total Income (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Taxable Income (Doc)"; "Taxable Income (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax Accrued (Doc)"; "Income Tax Accrued (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax Paid (Doc)"; "Income Tax Paid (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax Return LY (Doc)"; "Income Tax Return LY (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Return Settled LY (Doc)"; "Tax Return Settled LY (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Return Paid LY (Doc)"; "Tax Return Paid LY (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax Due (Doc)"; "Income Tax Due (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax Overpaid (Doc)"; "Income Tax Overpaid (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax for Withdraw. (Doc)"; "Income Tax for Withdraw. (Doc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Annual Tax Deductions"; "Annual Tax Deductions")
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

