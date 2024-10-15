page 5216 "Employee Statistics Groups"
{
    ApplicationArea = BasicHR;
    Caption = 'Employee Statistics Groups';
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Employee Statistics Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a code for the employee statistics group.';
                }
                field(Description; Description)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a description for the employee statistics group.';
                }
            }
        }
    }

    actions
    {
    }
}

