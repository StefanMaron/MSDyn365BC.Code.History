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
                    SetReport();
                end;

                trigger DocumentReady()
                begin
                    if LegacyPostMessage <> '' then
                        CurrPage.WebPageViewer.PostMessage(LegacyPostMessage, '*', false)
                    else
                        CurrPage.WebPageViewer.PostMessage(PowerBIEmbedHelper.GetLoadReportMessage(), PowerBIEmbedHelper.TargetOrigin(), false)
                end;

                trigger Callback(data: Text)
                begin
                    if LegacyFilterPostMessage <> '' then begin
                        if StrPos(data, 'reportPageLoaded') > 0 then begin
                            CurrPage.WebPageViewer.PostMessage(LegacyFilterPostMessage, '*', true);
                            CurrPage.WebPageViewer.PostMessage(ReportPageMessage, '*', true);
                        end
                    end else
                        HandleAddinCallback(data);
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
        PowerBIEmbedHelper: Codeunit "Power BI Embed Helper";
        EmbedUrl: Text;
        LegacyPostMessage: Text;  // For backwards compatibility only, remove with SetUrl
        LegacyFilterPostMessage: Text; // For backwards compatibility only, remove with SetFilter
        LatestReceivedFilterInfo: Text;
        CurrentListSelection: Text;
        ReportPageMessage: Text;

    [Obsolete('Use SetReportUrl instead','18.0')]
    procedure SetUrl(Url: Text; Message: Text)
    begin
        EmbedUrl := Url;
        LegacyPostMessage := Message;
    end;

    procedure SetReportUrl(Url: Text)
    begin
        EmbedUrl := Url;
    end;

    [Obsolete('Use SetFilterValue instead (pass as first parameter the filter value instead of the post message).','18.0')]
    procedure SetFilter(filterMessage: Text; firstpage: Text)
    begin
        LegacyFilterPostMessage := filterMessage;
        ReportPageMessage := firstpage;
    end;

    procedure SetFilterValue(FilterValue: Text; ReportPageMsg: Text)
    begin
        CurrentListSelection := FilterValue;
        ReportPageMessage := ReportPageMsg;
    end;

    local procedure HandleAddinCallback(CallbackMessage: Text)
    var
        MessageForWebPage: Text;
    begin
        PowerBiEmbedHelper.HandleAddInCallback(CallbackMessage, CurrentListSelection, ReportPageMessage, LatestReceivedFilterInfo, MessageForWebPage);
        if MessageForWebPage <> '' then
            CurrPage.WebPageViewer.PostMessage(MessageForWebPage, PowerBiEmbedHelper.TargetOrigin(), true);
    end;

    local procedure SetReport()
    var
        JsonArray: DotNet Array;
        DotNetString: DotNet String;
    begin
        // subscribe to events
        CurrPage.WebPageViewer.SubscribeToEvent('message', EmbedUrl);
        CurrPage.WebPageViewer.Navigate(EmbedUrl);
        JsonArray := JsonArray.CreateInstance(GetDotNetType(DotNetString), 1);
        JsonArray.SetValue('{"statusCode":202,"headers":{}}', 0);
        CurrPage.WebPageViewer.SetCallbacksFromSubscribedEventToIgnore('message', JsonArray);
    end;
}

