#pragma warning disable AS0030
page 5210 "Causes of Absence"
{
    AdditionalSearchTerms = 'vacation holiday sickness leave cause';
    ApplicationArea = BasicHR;
    Caption = 'Causes of Absence';
    PageType = List;
    SourceTable = "Cause of Absence";
    UsageCategory = Administration;
#pragma warning restore AS0030

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
                    ToolTip = 'Specifies a cause of absence code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a description for the cause of absence.';
                }
                field("Total Absence (Base)"; "Total Absence (Base)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the total number of absences (calculated in days or hours) for all employees.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
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

