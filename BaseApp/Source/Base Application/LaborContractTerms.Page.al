page 17370 "Labor Contract Terms"
{
    Caption = 'Labor Contract Terms';
    PageType = List;
    SourceTable = "Labor Contract Terms";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Line Type"; "Line Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Element Code"; "Element Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';
                }
                field("Time Activity Code"; "Time Activity Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';
                }
                field(Percent; Percent)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many units of the record are processed.';
                }
                field("Salary Indexation"; "Salary Indexation")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Depends on Salary Element"; "Depends on Salary Element")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the record.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Calculate Vacation Compensation")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate Vacation Compensation';
                    Image = Calculate;

                    trigger OnAction()
                    begin
                        CalcVacationCompensation;
                    end;
                }
            }
        }
    }
}

