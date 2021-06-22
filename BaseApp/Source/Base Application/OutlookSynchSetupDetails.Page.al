page 5310 "Outlook Synch. Setup Details"
{
    Caption = 'Outlook Synch. Setup Details';
    DataCaptionExpression = GetFormCaption;
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Outlook Synch. Setup Detail";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Outlook Collection"; "Outlook Collection")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the Outlook collection which is selected to be synchronized.';
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

    procedure GetFormCaption(): Text[80]
    var
        OSynchEntity: Record "Outlook Synch. Entity";
    begin
        OSynchEntity.Get("Synch. Entity Code");
        exit(StrSubstNo('%1 %2', OSynchEntity.TableCaption, "Synch. Entity Code"));
    end;
}

