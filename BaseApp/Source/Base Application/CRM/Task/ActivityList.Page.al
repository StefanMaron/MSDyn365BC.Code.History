namespace Microsoft.CRM.Task;

page 5103 "Activity List"
{
    AdditionalSearchTerms = 'marketing activities';
    ApplicationArea = RelationshipMgmt;
    Caption = 'Activities';
    CardPageID = Activity;
    Editable = false;
    PageType = List;
    SourceTable = Activity;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the activity.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the activity.';
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

