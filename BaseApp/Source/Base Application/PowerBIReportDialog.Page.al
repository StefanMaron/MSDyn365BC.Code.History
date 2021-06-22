page 6305 "Power BI Report Dialog"
{
    Caption = 'Power BI Report Dialog';
    Editable = false;
    LinksAllowed = false;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            usercontrol(WebPageViewer; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
            {
                ApplicationArea = Basic, Suite;

                trigger ControlAddInReady(callbackUrl: Text)
                begin
                    if (FilterPostMessage <> '') and (reportfirstpage <> '') then
                        CurrPage.WebPageViewer.SubscribeToEvent('message', EmbedUrl);
                    CurrPage.WebPageViewer.Navigate(EmbedUrl);
                end;

                trigger DocumentReady()
                begin
                    CurrPage.WebPageViewer.PostMessage(PostMessage, '*', false);
                    CurrPage.Update;
                end;

                trigger Callback(data: Text)
                begin
                    // apply filter and navigate to the first page if report was expanded from FactBox
                    if StrPos(data, 'reportPageLoaded') > 0 then begin
                        CurrPage.WebPageViewer.PostMessage(FilterPostMessage, '*', true);
                        CurrPage.WebPageViewer.PostMessage(reportfirstpage, '*', true);
                    end;
                end;

                trigger Refresh(callbackUrl: Text)
                begin
                end;
            }
        }
    }

    actions
    {
    }

    var
        EmbedUrl: Text;
        PostMessage: Text;
        FilterPostMessage: Text;
        reportfirstpage: Text;

    procedure SetUrl(Url: Text; Message: Text)
    begin
        EmbedUrl := Url;
        PostMessage := Message;
    end;

    procedure SetFilter(filterMessage: Text; firstpage: Text)
    begin
        FilterPostMessage := filterMessage;
        reportfirstpage := firstpage;
    end;
}

