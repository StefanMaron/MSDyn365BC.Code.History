page 10018 "IRS 1099 Adjustments"
{
    DelayedInsert = true;
    PageType = List;
    SourceTable = "IRS 1099 Adjustment";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor account.';
                }
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax year for the 1099 forms.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the adjustment amount.';
                }
            }
        }
    }

    actions
    {
    }
}

