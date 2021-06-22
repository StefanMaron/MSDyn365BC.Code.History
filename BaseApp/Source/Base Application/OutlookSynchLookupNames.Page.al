page 5306 "Outlook Synch. Lookup Names"
{
    Caption = 'Outlook Synch. Lookup Names';
    Editable = false;
    PageType = List;
    SourceTable = "Outlook Synch. Lookup Name";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the Outlook object which you want to synchronize. This object can be an Outlook item, collection, or property.';
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

