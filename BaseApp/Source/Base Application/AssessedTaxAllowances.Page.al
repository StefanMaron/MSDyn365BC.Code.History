page 14920 "Assessed Tax Allowances"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Assessed Tax Allowances';
    PageType = List;
    SourceTable = "Assessed Tax Allowance";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1470000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for an assessed tax allowance.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of an assessed tax allowance on fixed assets.';
                }
            }
        }
    }

    actions
    {
    }
}

