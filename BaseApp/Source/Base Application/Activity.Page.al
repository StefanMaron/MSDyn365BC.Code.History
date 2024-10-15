page 5101 Activity
{
    Caption = 'Activity';
    PageType = ListPlus;
    SourceTable = Activity;

    layout
    {
        area(content)
        {
            group(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the activity.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the activity.';
                }
            }
            part(Control9; "Activity Step Subform")
            {
                ApplicationArea = RelationshipMgmt;
                SubPageLink = "Activity Code" = FIELD(Code);
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

