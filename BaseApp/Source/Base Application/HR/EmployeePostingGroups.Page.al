page 5224 "Employee Posting Groups"
{
    ApplicationArea = BasicHR;
    Caption = 'Employee Posting Groups';
    PageType = List;
    SourceTable = "Employee Posting Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies an identifier for the employee posting group.';
                }
                field("Payables Account"; Rec."Payables Account")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the general ledger account to use when you post payables to employees in this posting group.';
                }
            }
        }
    }

    actions
    {
    }
}

