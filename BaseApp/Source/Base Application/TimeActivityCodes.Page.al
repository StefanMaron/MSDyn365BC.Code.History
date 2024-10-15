page 5210 "Time Activity Codes"
{
    AdditionalSearchTerms = 'vacation holiday sickness leave cause';
    ApplicationArea = BasicHR;
    Caption = 'Time Activity Codes';
    PageType = List;
    SourceTable = "Time Activity";
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
                    ToolTip = 'Specifies a cause of absence code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a description for the cause of absence.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Timesheet Code"; "Timesheet Code")
                {
                }
                field("Time Activity Type"; "Time Activity Type")
                {
                }
                field("Vacation Type"; "Vacation Type")
                {
                }
                field("Sick Leave Type"; "Sick Leave Type")
                {
                }
                field("Element Code"; "Element Code")
                {
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';
                }
                field("Allow Combination"; "Allow Combination")
                {
                }
                field("Allow Overtime"; "Allow Overtime")
                {
                }
                field("Allow Override"; "Allow Override")
                {
                }
                field("Paid Activity"; "Paid Activity")
                {
                }
                field("Save Position Rate"; "Save Position Rate")
                {
                }
                field("Use Accruals"; "Use Accruals")
                {
                }
                field("Min Days Allowed per Year"; "Min Days Allowed per Year")
                {
                }
                field("PF Reporting Absence Code"; "PF Reporting Absence Code")
                {
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

    trigger OnOpenPage()
    begin
        CurrPage.Editable := not CurrPage.LookupMode;
    end;
}

