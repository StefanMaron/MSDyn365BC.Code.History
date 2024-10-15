page 17372 "Default Labor Contract Terms"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Default Labor Contract Terms';
    PageType = Card;
    SourceTable = "Default Labor Contract Terms";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Category Code"; "Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category.';
                }
                field("Org. Unit Code"; "Org. Unit Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job Title Code"; "Job Title Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Element Code"; "Element Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';
                }
                field("Additional Salary"; "Additional Salary")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a salary that is paid in addition to the base salary. ';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("Operation Type"; "Operation Type")
                {
                    ApplicationArea = Basic, Suite;
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
                field("Org. Unit Hierarchy"; "Org. Unit Hierarchy")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job Title Hierarchy"; "Job Title Hierarchy")
                {
                    ApplicationArea = Basic, Suite;
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
            }
        }
    }

    actions
    {
    }
}

