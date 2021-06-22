page 99000808 "Routing Version List"
{
    Caption = 'Routing Version List';
    CardPageID = "Routing Version";
    DataCaptionFields = "Routing No.";
    Editable = false;
    PageType = List;
    SourceTable = "Routing Version";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Version Code"; "Version Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the version code of the routing.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description for the routing version.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting date for this routing version.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies in which order operations in the routing are performed.';
                    Visible = false;
                }
                field(Status; Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the status of this routing version.';
                    Visible = false;
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

