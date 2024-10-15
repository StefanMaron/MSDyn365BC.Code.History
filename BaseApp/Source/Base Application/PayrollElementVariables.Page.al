page 17437 "Payroll Element Variables"
{
    Caption = 'Payroll Element Variables';
    PageType = List;
    SourceTable = "Payroll Element Variable";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Variable; Variable)
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

