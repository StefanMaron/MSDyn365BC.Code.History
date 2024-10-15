page 17346 "Payroll Limits"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payroll Limits';
    PageType = List;
    SourceTable = "Payroll Limit";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("Payroll Period"; "Payroll Period")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';
                }
            }
        }
    }

    actions
    {
    }
}

