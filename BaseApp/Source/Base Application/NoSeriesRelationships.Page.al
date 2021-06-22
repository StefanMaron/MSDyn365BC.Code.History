page 458 "No. Series Relationships"
{
    Caption = 'No. Series Relationships';
    DataCaptionFields = "Code";
    PageType = List;
    SourceTable = "No. Series Relationship";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code that represents the related number series.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the description of the number series represented by the code in the Code field.';
                    Visible = false;
                }
                field("Series Code"; "Series Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for a number series that you want to include in the group of related number series.';
                }
                field("Series Description"; "Series Description")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the description of the number series represented by the code in the Series Code field.';
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

