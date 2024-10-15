page 17498 "Person Tax Deductions"
{
    Caption = 'Person Tax Deductions';
    PageType = List;
    SourceTable = "Person Tax Deduction";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Deduction Code"; "Deduction Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Deduction Amount"; "Deduction Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Deduction Quantity"; "Deduction Quantity")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Calculation; Calculation)
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

