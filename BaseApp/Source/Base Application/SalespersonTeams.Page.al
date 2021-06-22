page 5107 "Salesperson Teams"
{
    Caption = 'Salesperson Teams';
    DataCaptionFields = "Salesperson Code";
    PageType = List;
    SourceTable = "Team Salesperson";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Team Code"; "Team Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the team to which the salesperson belongs.';
                }
                field("Team Name"; "Team Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the team.';
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

