page 5106 "Team Salespeople"
{
    Caption = 'Team Salespeople';
    DataCaptionFields = "Team Code";
    PageType = List;
    SourceTable = "Team Salesperson";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the salesperson you want to register as part of the team.';
                }
                field("Salesperson Name"; "Salesperson Name")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the salesperson you want to register as part of the team.';
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

