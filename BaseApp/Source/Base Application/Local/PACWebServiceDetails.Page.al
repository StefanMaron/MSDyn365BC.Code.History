page 10456 "PAC Web Service Details"
{
    Caption = 'PAC Web Service Details';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "PAC Web Service Detail";

    layout
    {
        area(content)
        {
            repeater(Control1020000)
            {
                ShowCaption = false;
                field(Environment; Environment)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies if the web service is for a test environment or a production environment.';
                }
                field(Type; Type)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies if the web service is for requesting digital stamps or for canceling signed invoices.';
                }
                field("Method Name"; Rec."Method Name")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the web method that will be used for this request type. Contact your authorized service provider, PAC, for this information.';
                }
                field(Address; Address)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the web method URL used for this type of request. Contact your authorized service provider, PAC, for this information.';
                }
            }
        }
    }

    actions
    {
    }
}

