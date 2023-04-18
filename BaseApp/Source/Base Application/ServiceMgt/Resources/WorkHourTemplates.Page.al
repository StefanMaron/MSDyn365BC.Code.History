page 6017 "Work-Hour Templates"
{
    ApplicationArea = Jobs, Service;
    Caption = 'Work-Hour Templates';
    PageType = List;
    SourceTable = "Work-Hour Template";
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
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies a code for the work-hour template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies a description of the work-hour template.';
                }
                field(Monday; Monday)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the number of work-hours on Monday.';
                }
                field(Tuesday; Tuesday)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the number of work-hours on Tuesday.';
                }
                field(Wednesday; Wednesday)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the number of work-hours on Wednesday.';
                }
                field(Thursday; Thursday)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the number of work-hours on Thursday.';
                }
                field(Friday; Friday)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the number of work-hours on Friday.';
                }
                field(Saturday; Saturday)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the number of work-hours on Saturday.';
                }
                field(Sunday; Sunday)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the number of work-hours on Sunday.';
                }
                field("Total per Week"; Rec."Total per Week")
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the total number of work-hours per week for the work-hour template.';
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

