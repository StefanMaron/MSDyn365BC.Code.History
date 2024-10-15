page 5215 "Grounds for Termination"
{
    ApplicationArea = BasicHR;
    Caption = 'Grounds for Termination';
    PageType = List;
    SourceTable = "Grounds for Termination";
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
                    ToolTip = 'Specifies a grounds for termination code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a description for the grounds for termination.';
                }
                field("Dismissal Type"; "Dismissal Type")
                {
                }
                field("Dismissal Article"; "Dismissal Article")
                {
                }
                field("Reporting Type"; "Reporting Type")
                {
                }
                field("Element Code"; "Element Code")
                {
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

