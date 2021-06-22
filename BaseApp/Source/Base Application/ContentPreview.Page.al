page 5084 "Content Preview"
{
    Caption = 'Content Preview';

    layout
    {
        area(content)
        {
            group(EmailBody)
            {
                Caption = 'Email Body';
                usercontrol(BodyHTMLMessage; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                {
                    ApplicationArea = RelationshipMgmt;
                }
            }
        }
    }

    actions
    {
    }

    var
        HTMLContent: Text;

    procedure SetContent(InHTMLContent: Text)
    begin
        HTMLContent := InHTMLContent;
    end;
}

