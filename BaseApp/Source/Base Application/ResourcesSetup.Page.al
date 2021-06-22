page 462 "Resources Setup"
{
    AccessByPermission = TableData Resource = R;
    ApplicationArea = Jobs;
    Caption = 'Resources Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Resources Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Resource Nos."; "Resource Nos.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number series code you can use to assign numbers to resources.';
                }
                field("Time Sheet Nos."; "Time Sheet Nos.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number series code you can use to assign document numbers to time sheets.';
                }
                field("Time Sheet First Weekday"; "Time Sheet First Weekday")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the first weekday to use on a time sheet. The default is Monday.';
                }
                field("Time Sheet by Job Approval"; "Time Sheet by Job Approval")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether time sheets must be approved on a per job basis by the user specified for the job.';
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
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

