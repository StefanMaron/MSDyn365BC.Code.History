page 5929 "Fault Reason Codes"
{
    ApplicationArea = Service;
    Caption = 'Fault Reason Codes';
    PageType = List;
    SourceTable = "Fault Reason Code";
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
                    ToolTip = 'Specifies a code for the fault reason.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the fault reason code.';
                }
                field("Exclude Warranty Discount"; "Exclude Warranty Discount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you want to exclude a warranty discount for the service item assigned this fault reason code.';
                }
                field("Exclude Contract Discount"; "Exclude Contract Discount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you want to exclude a contract/service discount for the service item assigned this fault reason code.';
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
        area(navigation)
        {
            group("&Fault")
            {
                Caption = '&Fault';
                Image = Error;
                action("Serv&ice Line List")
                {
                    ApplicationArea = Service;
                    Caption = 'Serv&ice Line List';
                    Image = ServiceLines;
                    RunObject = Page "Service Line List";
                    RunPageLink = "Fault Reason Code" = FIELD(Code);
                    RunPageView = SORTING("Fault Reason Code");
                    ToolTip = 'View the service lines that contain the fault code.';
                }
                action("Service Item Line List")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Item Line List';
                    Image = ServiceItem;
                    RunObject = Page "Service Item Lines";
                    RunPageLink = "Fault Reason Code" = FIELD(Code);
                    RunPageView = SORTING("Fault Reason Code");
                    ToolTip = 'View the list of ongoing service item lines.';
                }
            }
        }
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := false;
    end;
}

