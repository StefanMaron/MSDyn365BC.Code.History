#if not CLEAN19
page 9981 "Buy Subscription"
{
    Caption = 'Buy Subscription';
    Editable = false;
    ObsoleteState = Pending;
    ObsoleteReason = 'The page is replaced by direct link to "purchase through partner" page, rather than to show embedded content.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            usercontrol(WebPageViewer; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
            {
                ApplicationArea = Basic, Suite;

                trigger ControlAddInReady(callbackUrl: Text)
                begin
                    CurrPage.WebPageViewer.Navigate(BuySubscriptionForwardLinkTxt);
                end;

                trigger DocumentReady()
                begin
                end;

                trigger Callback(data: Text)
                begin
                end;

                trigger Refresh(callbackUrl: Text)
                begin
                    CurrPage.WebPageViewer.Navigate(BuySubscriptionForwardLinkTxt);
                end;
            }
        }
    }

    actions
    {
    }

    var
        BuySubscriptionForwardLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828659', Locked = true;
}
#endif