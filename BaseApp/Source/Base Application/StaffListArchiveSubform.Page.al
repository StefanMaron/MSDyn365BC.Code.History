page 17389 "Staff List Archive Subform"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Staff List Line Archive";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Org. Unit Code"; "Org. Unit Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Org. Unit Name"; "Org. Unit Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job Title Code"; "Job Title Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job Title Name"; "Job Title Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Staff Positions"; "Staff Positions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Occupied Staff Positions"; "Occupied Staff Positions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Vacant Staff Positions"; "Vacant Staff Positions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Staff Base Salary"; "Staff Base Salary")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Staff Monthly Salary"; "Staff Monthly Salary")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Staff Additional Salary"; "Staff Additional Salary")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Staff Budgeted Salary"; "Staff Budgeted Salary")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Out-of-Staff Positions"; "Out-of-Staff Positions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Occup. Out-of-Staff Positions"; "Occup. Out-of-Staff Positions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Vacant Out-of-Staff Positions"; "Vacant Out-of-Staff Positions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Out-of-Staff Base Salary"; "Out-of-Staff Base Salary")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Out-of-Staff Monthly Salary"; "Out-of-Staff Monthly Salary")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Out-of-Staff Additional Salary"; "Out-of-Staff Additional Salary")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Out-of-Staff Budgeted Salary"; "Out-of-Staff Budgeted Salary")
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

