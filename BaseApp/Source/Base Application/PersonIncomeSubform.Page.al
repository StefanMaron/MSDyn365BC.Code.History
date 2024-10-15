page 17496 "Person Income Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    PageType = ListPart;
    SourceTable = "Person Income Line";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Period Code"; "Period Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Advance Income"; "Advance Income")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies income that is received in advance.';
                }
                field("Taxable Income (Interim)"; "Taxable Income (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Taxable Income (Calc)"; "Taxable Income (Calc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Taxable Income"; "Taxable Income")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Deductions"; "Tax Deductions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Non-Taxable Income (Interim)"; "Non-Taxable Income (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Non-Taxable Income (Calc)"; "Non-Taxable Income (Calc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Non-Taxable Income"; "Non-Taxable Income")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Accrued Tax (Interim)"; "Accrued Tax (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total tax amount of unrealized amounts.';
                }
                field("Accrued Tax"; "Accrued Tax")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total tax amount.';
                }
                field("Paid to Budget (Interim)"; "Paid to Budget (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Paid to Budget (Calc)"; "Paid to Budget (Calc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Paid to Budget"; "Paid to Budget")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Paid to Person (Interim)"; "Paid to Person (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Paid to Person (Calc)"; "Paid to Person (Calc)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Paid to Person"; "Paid to Person")
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
        area(processing)
        {
            group("L&ines")
            {
                Caption = 'L&ines';
                action(Edit)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit';
                    Image = Edit;

                    trigger OnAction()
                    begin
                        EditLine;
                    end;
                }
            }
        }
    }
}

