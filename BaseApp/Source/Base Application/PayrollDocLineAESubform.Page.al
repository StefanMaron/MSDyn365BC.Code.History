page 17481 "Payroll Doc. Line AE Subform"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Payroll Document Line AE";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source type that applies to the source number that is shown in the Source No. field.';
                }
                field("Ledger Entry No."; "Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
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

