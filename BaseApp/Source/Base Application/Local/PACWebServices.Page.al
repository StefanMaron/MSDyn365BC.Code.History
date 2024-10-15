page 10455 "PAC Web Services"
{
    ApplicationArea = Basic, Suite;
    Caption = 'PAC Web Services';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "PAC Web Service";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1020000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the unique code for the authorized service provider, PAC.';
                }
                field(Name; Name)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the name of the authorized service provider, PAC.';
                }
                field(Certificate; Certificate)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the certificate from the authorized service provider, PAC.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&PAC Web Service")
            {
                Caption = '&PAC Web Service';
                action("&Details")
                {
                    ApplicationArea = BasicMX;
                    Caption = '&Details';
                    Image = View;
                    RunObject = Page "PAC Web Service Details";
                    RunPageLink = "PAC Code" = FIELD(Code);
                    ToolTip = 'View technical information about the web services that are used by an authorized service provider, PAC.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Details_Promoted"; "&Details")
                {
                }
            }
        }
    }
}

