page 17483 "Posted Payroll Doc. Line AE Sf"
{
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Posted Payroll Doc. Line AE";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Wage Period Code"; "Wage Period Code")
                {
                    ApplicationArea = Basic, Suite;
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
                field("Element Type"; "Element Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related payroll element for tax registration purposes.';
                }
                field("Bonus Type"; "Bonus Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';
                }
                field("Inclusion Factor"; "Inclusion Factor")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Amount for AE"; "Amount for AE")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that applies to average earnings.';
                }
                field("Indexed Amount for AE"; "Indexed Amount for AE")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Amount for FSI"; "Amount for FSI")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that applies to the Federal Social Insurance fund.';
                }
            }
        }
    }

    actions
    {
    }
}

