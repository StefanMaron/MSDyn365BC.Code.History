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
                    InitializeAddIn();
                end;

                trigger Callback(data: Text)
                begin
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
        LatestReceivedFilterInfo: Text;
        CurrentListSelection: Text;
        ReportPageMessage: Text;

    procedure SetReportUrl(Url: Text)
    begin
        EmbedUrl := Url;
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

    [NonDebuggable]
    local procedure InitializeAddIn()
    var
        LoadReportMessage: Text;
    begin
        PowerBIEmbedHelper.TryGetLoadReportMessage(LoadReportMessage);
        CurrPage.WebPageViewer.PostMessage(LoadReportMessage, PowerBIEmbedHelper.TargetOrigin(), false)
    end;
}

