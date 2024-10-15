page 17443 "Timesheet Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Timesheet Codes';
    PageType = List;
    SourceTable = "Timesheet Code";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the timesheet code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the timesheet.';
                }
                field("Digital Code"; "Digital Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the digital code for the timesheet code.';
                }
            }
        }
    }

    actions
    {
    }
}

