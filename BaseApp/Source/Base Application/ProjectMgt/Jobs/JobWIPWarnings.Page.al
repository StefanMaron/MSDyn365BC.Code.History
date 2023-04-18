page 1026 "Job WIP Warnings"
{
    Caption = 'Job WIP Warnings';
    PageType = List;
    SourceTable = "Job WIP Warning";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related job.';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related job task.';
                }
                field("Job WIP Total Entry No."; Rec."Job WIP Total Entry No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the entry number from the associated job WIP total.';
                }
                field("Warning Message"; Rec."Warning Message")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a warning message that is related to a job WIP calculation.';
                }
            }
        }
    }

    actions
    {
    }
}

