page 17371 "Labor Contract Terms Setup"
{
    Caption = 'Labor Contract Terms Setup';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Labor Contract Terms Setup";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Operation Type"; "Operation Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Table Type"; "Table Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("Element Code"; "Element Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field("Additional Salary"; "Additional Salary")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a salary that is paid in addition to the base salary. ';
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
            }
        }
    }

    actions
    {
    }
}

