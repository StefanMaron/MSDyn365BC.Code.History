namespace Microsoft.Manufacturing.Routing;

page 99000804 "Standard Task Personnel"
{
    AutoSplitKey = true;
    Caption = 'Standard Task Personnel';
    DataCaptionFields = "Standard Task Code";
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Standard Task Personnel";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the description for the personnel, such as the names or type of the personnel.';
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

