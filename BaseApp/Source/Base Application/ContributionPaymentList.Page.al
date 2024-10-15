page 12131 "Contribution Payment List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'INAIL Payment';
    Editable = false;
    PageType = List;
    SourceTable = "Contribution Payment";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Month; Month)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the month of the contribution payment in numeric format.';
                }
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year of the contribution payment in numeric format.';
                }
                field("Payment Date"; "Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the contribution amount is paid to the tax authority.';
                }
                field("Gross Amount"; "Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to contributions.';
                }
                field("Non Taxable Amount"; "Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is not taxable due to provisions in the law.';
                }
                field("Contribution Base"; "Contribution Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to contribution tax after nontaxable amounts have been subtracted.';
                }
                field("Total Social Security Amount"; "Total Social Security Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of Social Security tax that is due for this payment.';
                }
                field("Free-Lance Amount"; "Free-Lance Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the Social Security tax that is paid by the independent contractor or vendor.';
                }
                field("Company Amount"; "Company Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of Social Security tax that your company is liable for.';
                }
                field("Series Number"; "Series Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign the entry number.';
                }
                field("Quiettance No."; "Quiettance No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number that was assigned to the entry upon payment to release your organization from the contribution debt and obligation.';
                }
            }
        }
    }

    actions
    {
    }
}

