page 9980 "Contact MS Sales"
{
    Caption = 'Contact MS Sales';
    Editable = false;
    ObsoleteState = Pending;
    ObsoleteReason = 'The Microsoft Sales page is now opened as a hyperlink.';
    ObsoleteTag = '16.0';

    layout
    {
        area(content)
        {
            usercontrol(WebPageViewer; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
            {
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

