#if not CLEAN23
namespace System.Integration.PowerBI;

using System.Integration;

page 6305 "Power BI Report Dialog"
{
    Caption = 'Power BI Report Dialog';
    Editable = false;
    LinksAllowed = false;
    ShowFilter = false;
    ObsoleteState = Pending;
    ObsoleteReason = 'This page has been replaced by page 6323 "Power BI Element Card"';
    ObsoleteTag = '23.0';

    layout
    {
        area(content)
        {
            usercontrol(WebPageViewer; WebPageViewer)
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
        JsonArray: JsonArray;
        JsonValue: JsonValue;
    begin
        // subscribe to events
        CurrPage.WebPageViewer.SubscribeToEvent('message', EmbedUrl);
        CurrPage.WebPageViewer.Navigate(EmbedUrl);

        JsonValue.SetValue('{"statusCode":202,"headers":{}}');
        JsonArray.Add(JsonValue);
        CurrPage.WebPageViewer.SetCallbacksFromSubscribedEventToIgnore('message', JsonArray);
    end;

    [NonDebuggable]
    local procedure InitializeAddIn()
    var
        LoadReportMessage: SecretText;
    begin
        PowerBIEmbedHelper.TryGetLoadReportMessage(LoadReportMessage);
        CurrPage.WebPageViewer.PostMessage(LoadReportMessage.Unwrap(), PowerBIEmbedHelper.TargetOrigin(), false)
    end;
}

#endif