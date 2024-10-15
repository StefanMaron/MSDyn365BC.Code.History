page 17421 "Payroll Base Amount Entries"
{
    Caption = 'Payroll Base Amount Entries';
    PageType = List;
    SourceTable = "Payroll Ledger Base Amount";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry.';
                }
                field("Base Type"; "Base Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Detailed Base Type"; "Detailed Base Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Element Type"; "Element Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that after you post an FA Movement Act, you can use this report to print the posted document.';
                }
                field("Element Code"; "Element Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Period Code"; "Period Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';
                }
                field("Payroll Directory Code"; "Payroll Directory Code")
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

