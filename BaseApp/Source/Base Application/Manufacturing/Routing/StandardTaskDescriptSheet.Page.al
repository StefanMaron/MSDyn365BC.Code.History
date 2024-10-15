namespace Microsoft.Manufacturing.Routing;

page 99000807 "Standard Task Descript. Sheet"
{
    AutoSplitKey = true;
    Caption = 'Standard Task Descript. Sheet';
    DataCaptionFields = "Standard Task Code";
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Standard Task Description";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Text; Rec.Text)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the text for the standard task description.';
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

