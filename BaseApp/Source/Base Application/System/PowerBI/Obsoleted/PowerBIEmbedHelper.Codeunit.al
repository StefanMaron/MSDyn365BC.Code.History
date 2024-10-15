#if not CLEAN23
namespace System.Integration.PowerBI;

using System;
using System.Azure.Identity;
using System.Integration;
using System.Utilities;

codeunit 6299 "Power BI Embed Helper"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This functionality has been replaced by the Power BI javascript library';
    ObsoleteTag = '23.0';

    // // Handles creation of messages to post to the Power BI Embed page in the WebPageViewer control addin

    /**
        The payloads in this file are generated according to the PowerBi-Javascript framework:
        https://github.com/Microsoft/PowerBI-JavaScript

        Find more information and example JSON payloads in the wiki page "WebPageViewer message flow":
        https://dynamicssmb2.visualstudio.com/Dynamics%20SMB/_wiki/wikis/Wiki/1318/WebPageViewer-message-flow
    **/

    var
        PowerBiServiceMgt: Codeunit "Power BI Service Mgt.";
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        // Json payloads
        LoadReportMessageJsonTxt: Label '{"action":"loadReport","accessToken":"%1"}', Locked = true;
        GetPagesWebRequestJsonTxt: Label '{"method":"GET","url":"/report/pages","headers":{"id":"getpagesfromreport"}}', Locked = true;
        PutActivePageWebRequestJsonTxt: Label '{"method":"PUT","url":"/report/pages/active","headers":{"id":"setpage,%1"},"body": {"name":"%1","displayName": null}}', Comment = '%1=The name of the page to be set as active', Locked = true;
        GetReportFilterWebRequestJsonTxt: Label '{"method":"GET","url":"/report/filters","headers": {"id":"getfilters,%1"}}', Locked = true;
        PutReportFilterWebRequestJsonTxt: Label '{"method":"PUT","url":"/report/filters","headers": {}, "body": [{"$schema":%1,"target":{"table":%2,"column":%3},"operator":%4,"values":[%5]}]}', Comment = '%1,%2,%3=the schema, table and column where the filter applies, as communicated to us by Power BI; %4=the operator to handle the Power BI filter, e.g. "In" or "All"; %5=the value to set the filter to', Locked = true;
        // Other labels
        FailedAuthErr: Label 'We failed to authenticate with Power BI. Try to sign out and in again. This problem typically happens if you no longer have a license for Power BI or if you just changed your email or password.';
        FailedToHandleCallbackTelemetryMsg: Label 'Failed to handle callback message. LastError: %2.', Locked = true;
        EmptyAccessTokenForPBITelemetryMsg: Label 'Empty access token generated for Power BI.', Locked = true;
        NoFiltersOnReportTelemetryMsg: Label 'The report has no filters.', Locked = true;
        FailureStatusCodeTelemetryMsg: Label 'Received a message with a failure status code %1.', Locked = true;
        InvalidCallbackMessageTelemetryMsg: Label 'The CallbackMessage is invalid (length: %1). Last error: %2.', Locked = true;
        TargetOriginWildcardTelemetryMsg: Label 'Could not determine target origin, defaulting to wildcard.', Locked = true;
        InvalidJsonResponseErr: Label 'The response for the Power BI report page was invalid: %1.', Comment = '%1 = A string that represents an invalid Json object.';

    [Scope('OnPrem')]
    procedure HandleAddInCallback(CallbackMessage: Text; CurrentListSelection: Text; var CurrentReportFirstPage: Text; var LatestReceivedFilterInfo: Text; var ResponseForWebPage: Text)
    begin
        if not TryHandleAddInCallback(CallbackMessage, CurrentListSelection, CurrentReportFirstPage, LatestReceivedFilterInfo, ResponseForWebPage) then
            Session.LogMessage('0000B6U', StrSubstNo(FailedToHandleCallbackTelemetryMsg, GetLastErrorText(true)), Verbosity::Error, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
    end;

    [Scope('OnPrem')]
    [TryFunction]
    local procedure TryHandleAddInCallback(CallbackMessage: Text; CurrentListSelection: Text; var CurrentReportFirstPage: Text; var LatestReceivedFilterInfo: Text; var ResponseForWebPage: Text)
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        HttpUtility: DotNet HttpUtility;
        JsonCallbackMessage: JsonToken;
        JsonFirstPageNameToken: JsonToken;
        TempJsonToken: JsonToken;
        UrlTokenText: Text;
        HeaderIdTokenText: Text;
    begin
        Clear(ResponseForWebPage); // Clear output

        if not JsonCallbackMessage.ReadFrom(CallbackMessage) then begin
            Session.LogMessage('0000FT1', StrSubstNo(InvalidCallbackMessageTelemetryMsg, StrLen(CallbackMessage), GetLastErrorText(true)), Verbosity::Warning, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
            Error(GetLastErrorText());
        end;

        if JsonCallbackMessage.SelectToken('$.statusCode', TempJsonToken) then
            if WebRequestHelper.IsFailureStatusCode(TempJsonToken.AsValue().AsText()) then
                Session.LogMessage('0000B6V', StrSubstNo(FailureStatusCodeTelemetryMsg, TempJsonToken.AsValue().AsText()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());

        if JsonCallbackMessage.SelectToken('$.url', TempJsonToken) then
            UrlTokenText := TempJsonToken.AsValue().AsText();
        if JsonCallbackMessage.SelectToken('$.headers.id', TempJsonToken) then
            HeaderIdTokenText := TempJsonToken.AsValue().AsText();

        // Power BI sends a response with the same ID that we send in the request.
        // This way, we can know the last step we performed and perform the following one.

        case true of
            IsIgnoredEventUrl(UrlTokenText):
                exit; // Power BI notifies us of these events: no reaction needed
            IsReportLoadedEvent(JsonCallbackMessage),
            StrPos(UrlTokenText, '/loaded') > 0:
                // Step 1: Power BI report is ready, get all pages of the report
                ResponseForWebPage := GetPagesWebRequestJsonTxt;
            StrPos(HeaderIdTokenText, 'getpagesfromreport') > 0:
                begin
                    // Step 2: Navigate to the first page of the report
                    JsonCallbackMessage.SelectToken('$.body[0].name', JsonFirstPageNameToken);
                    ResponseForWebPage := StrSubstNo(PutActivePageWebRequestJsonTxt,
                        HttpUtility.JavaScriptStringEncode(JsonFirstPageNameToken.AsValue().AsText()));
                    CurrentReportFirstPage := ResponseForWebPage;
                end;
            StrPos(HeaderIdTokenText, 'setpage') > 0:
                // Step 3: Find all filters on this page of the report
                // Page-only filters are currently not supported, but can be retrieved with a call similar to:
                // messagefilter := StrSubstNo(GetPageFilterWebRequestJsonTxt, ...); // page filters
                // Which also requires the variable:
                // GetPageFilterWebRequestJsonTxt: Label '{"method":"GET","url":"/report/pages/%1/filters","headers": {"id":"getfilters,%1"}}', Comment = '%1=The name of the page within the report to retrieve the filters for', Locked = true;

                // Pull out the page we injected in the ID in step 2
                ResponseForWebPage := StrSubstNo(GetReportFilterWebRequestJsonTxt,
                    HttpUtility.JavaScriptStringEncode(SelectStr(2, HeaderIdTokenText)));
            StrPos(HeaderIdTokenText, 'getfilters') > 0:
                // Step 4: Change the filter value to the one received from the corresponding list (only for basic filters)

                // Filter only if there is a basic filter in the report.
                if JsonCallbackMessage.SelectToken('$.body[0].$schema', TempJsonToken)
                and (StrPos(TempJsonToken.AsValue().AsText(), '/schema#basic') > 0) then begin
                    LatestReceivedFilterInfo := CallbackMessage; // save data for filter update on change of selected list element
                    if CurrentListSelection = '' then
                        exit; // There is no list selection information available. We should not clear the filter, because the report itself might have some filtering set up

                    ResponseForWebPage := GetPutReportFilterRequest(JsonCallbackMessage, CurrentListSelection);
                end else begin
                    // There are no filters on the page, that is OK
                    Session.LogMessage('0000B6W', NoFiltersOnReportTelemetryMsg, Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
                    exit;
                end;
        end;

        if ResponseForWebPage = '' then
            Error('');

        if not IsValidJson(ResponseForWebPage) then
            Error(InvalidJsonResponseErr, ResponseForWebPage);
    end;

    local procedure IsReportLoadedEvent(JsonCallbackText: JsonToken): Boolean
    var
        DecodedCallbackJson: JsonToken;
        RaisedEventJson: JsonToken;
    begin
        // Workaround for bug 441863:
        // Power BI stopped sending /loaded events. We should now instead listen to reportPageLoaded events and eventually move to a supported library.
        // These events come as encoded json objects, so we need to read the value again to make sure it's decoded.

        if JsonCallbackText.IsValue() then
            if DecodedCallbackJson.ReadFrom(JsonCallbackText.AsValue().AsText()) then
                if DecodedCallbackJson.SelectToken('$.event', RaisedEventJson) then
                    if RaisedEventJson.IsValue() then
                        exit(RaisedEventJson.AsValue().AsText() = 'reportPageLoaded');

        exit(false);
    end;

    local procedure IsValidJson(JsonData: Text): Boolean
    var
        JToken: JsonToken;
    begin
        exit(JToken.ReadFrom(JsonData));
    end;

    local procedure GetPutReportFilterRequest(DataToken: JsonToken; CurrentListSelection: Text): Text
    var
        SchemaJsonToken: JsonToken;
        TableJsonToken: JsonToken;
        ColumnJsonToken: JsonToken;
        FilterOperatorToken: JsonValue;
    begin
        // Note: do not catch these errors. If those tokens do not exist, it means PowerBI changed their schema, or simply we cannot apply the filtering,
        // so this error needs to be thrown and propagated up to the TryFunction.
        DataToken.SelectToken('$.body[0].$schema', SchemaJsonToken);
        DataToken.SelectToken('$.body[0].target.table', TableJsonToken);
        DataToken.SelectToken('$.body[0].target.column', ColumnJsonToken);

        if CurrentListSelection = '' then
            FilterOperatorToken.SetValue('All')
        else
            FilterOperatorToken.SetValue('In');

        exit(StrSubstNo(PutReportFilterWebRequestJsonTxt,
            SchemaJsonToken,
            TableJsonToken,
            ColumnJsonToken,
            FilterOperatorToken,
            CurrentListSelection
            ));
    end;

    [Scope('OnPrem')]
    procedure TargetOrigin(): Text
    var
        EmbeddedTargetOrigin: Text;
    begin
        if TryGetTargetOrigin(EmbeddedTargetOrigin) then
            if EmbeddedTargetOrigin <> '' then
                exit(EmbeddedTargetOrigin);

        Session.LogMessage('0000BI3', TargetOriginWildcardTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
        EmbeddedTargetOrigin := '*'; // Give up and post to any TargetOrigin
    end;

    [Scope('OnPrem')]
    [TryFunction]
    local procedure TryGetTargetOrigin(var EmbeddedTargetOrigin: Text)
    var
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
        UriBuilderFullUrl: DotNet UriBuilder;
        UriBuilderBaseUrl: DotNet UriBuilder;
    begin
        // From documentation about TargetOrigin:
        //   This string is the concatenation of the protocol and "://", the host name if one exists, and ":" followed by a port number if a port is present
        //   and differs from the default port for the given protocol. Examples of typical origins are https://example.org (implying port 443), http://example.net 
        //   (implying port 80), and http://example.com:8080.

        UriBuilderFullUrl := UriBuilderFullUrl.UriBuilder(PowerBIUrlMgt.GetPowerBIEmbedReportsUrl()); // If this fails, the URL is not valid, meaning we could not load the embed experience in the first place
        UriBuilderBaseUrl := UriBuilderBaseUrl.UriBuilder(UriBuilderFullUrl.Scheme, UriBuilderFullUrl.Host, UriBuilderFullUrl.Port);
        EmbeddedTargetOrigin := UriBuilderBaseUrl.Uri().AbsoluteUri();
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    [TryFunction]
    procedure TryGetLoadReportMessage(var LoadReportMessage: Text)
    var
        Result: SecretText;
    begin
        Result := LoadReportMessage;
        TryGetLoadReportMessage(Result);
        LoadReportMessage := Result.Unwrap();
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    [TryFunction]
    procedure TryGetLoadReportMessage(var LoadReportMessage: SecretText)
    var
        AccessToken: SecretText;
        HttpUtility: DotNet HttpUtility;
    begin
        AccessToken := HttpUtility.JavaScriptStringEncode(
            AzureAdMgt.GetAccessTokenAsSecretText(PowerBiServiceMgt.GetPowerBIResourceUrl(), PowerBiServiceMgt.GetPowerBiResourceName(), false).Unwrap()
            );

        if AccessToken.IsEmpty() then begin
            Session.LogMessage('0000FT0', EmptyAccessTokenForPBITelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
            Error(FailedAuthErr);
        end;

        LoadReportMessage := SecretStrSubstNo(LoadReportMessageJsonTxt, AccessToken);
    end;

    procedure IsIgnoredEventUrl(EventUrl: Text): Boolean
    begin
        // https://go.microsoft.com/fwlink/?linkid=2205494
        exit(
            (StrPos(EventUrl, '/rendered') > 0) or
            (StrPos(EventUrl, '/renderingStarted') > 0) or
            (StrPos(EventUrl, '/pageChanged') > 0) or
            (StrPos(EventUrl, '/buttonClicked') > 0) or
            (StrPos(EventUrl, '/commandTriggered') > 0) or
            (StrPos(EventUrl, '/dataHyperlinkClicked') > 0) or
            (StrPos(EventUrl, '/visualRendered') > 0) or
            (StrPos(EventUrl, '/dataSelected') > 0) or
            (StrPos(EventUrl, '/swipeStart') > 0) or
            (StrPos(EventUrl, '/swipeEnd') > 0) or
            (StrPos(EventUrl, '/tileClicked') > 0) or
            (StrPos(EventUrl, '/tileLoaded') > 0) or
            (StrPos(EventUrl, '/visualClicked') > 0)
        );
    end;

}

#endif