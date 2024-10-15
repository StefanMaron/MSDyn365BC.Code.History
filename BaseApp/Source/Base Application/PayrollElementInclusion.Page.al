page 17486 "Payroll Element Inclusion"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payroll Element Inclusion';
    PageType = List;
    SourceTable = "Payroll Element Inclusion";
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
                field("Period Code"; "Period Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Element Code"; "Element Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';
                }
            }
        }
    }

    actions
    {
    }
}

