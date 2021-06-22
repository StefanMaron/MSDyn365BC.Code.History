page 6080 "Service Price Groups"
{
    ApplicationArea = Service;
    Caption = 'Service Price Groups';
    PageType = List;
    SourceTable = "Service Price Group";
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
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for the service price group.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the service price group.';
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
        area(processing)
        {
            action("&Setup")
            {
                ApplicationArea = Service;
                Caption = '&Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Serv. Price Group Setup";
                RunPageLink = "Service Price Group Code" = FIELD(Code);
                ToolTip = 'View or edit how you group service prices.';
            }
        }
    }
}

