page 17435 "Payroll Expression Errors"
{
    Caption = 'Payroll Expression Errors';
    PageType = List;
    SourceTable = "Payroll Calculation Error";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
            }
        }
    }

    actions
    {
    }
}

