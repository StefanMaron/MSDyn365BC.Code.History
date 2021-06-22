page 394 "Entry/Exit Points"
{
    ApplicationArea = BasicEU;
    Caption = 'Entry/Exit Points';
    PageType = List;
    SourceTable = "Entry/Exit Point";
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
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the code for the shipping location (Entry/Exit Point).';
                }
                field(Description; Description)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies a description of the shipping location (Entry/Exit Point).';
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

