page 17426 "Payroll Doc. Line Variables"
{
    Caption = 'Payroll Doc. Line Variables';
    Editable = false;
    PageType = List;
    SourceTable = "Payroll Document Line Var.";

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
                field(Value; Value)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Error; Error)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Calculated; Calculated)
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

