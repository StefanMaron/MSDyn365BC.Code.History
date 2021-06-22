page 99000805 "Standard Task Qlty Measures"
{
    AutoSplitKey = true;
    Caption = 'Standard Task Qlty Measures';
    DataCaptionFields = "Standard Task Code";
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Standard Task Quality Measure";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Qlty Measure Code"; "Qlty Measure Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the quality measure.';
                }
                field(Description; Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the quality measure description.';
                }
                field("Min. Value"; "Min. Value")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the minimum value that must be met.';
                }
                field("Max. Value"; "Max. Value")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the maximum value that may be achieved.';
                }
                field("Mean Tolerance"; "Mean Tolerance")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the mean tolerance.';
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

