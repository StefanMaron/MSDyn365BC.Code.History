codeunit 7203 "CDS Environment"
{
    Access = Internal;

    trigger OnRun();
    begin
    end;

    var
        CategoryTok: Label 'AL Common Data Service Integration', Locked = true;
        SelectedDefaultEnvironmentTxt: Label 'Selected the default environment: %1', Locked = true, Comment = '%1 = The URL of the by default selected environment';
        SelectedEnvironmentTxt: Label 'Selected environment: %1', Locked = true, Comment = '%1 = The URL of the selected environment';
        CannotGetAuthorizationTokenTxt: Label 'Cannot get authorization token.', Locked = true;
        RequestFailedTxt: Label 'Request failed', Locked = true;
        CannotReadResponseTxt: Label 'Cannot read response.', Locked = true;
        CannotParseResponseTxt: Label 'Cannot parse response.', Locked = true;
        CannotInsertEnvironmentTxt: Label 'Cannot insert environment.', Locked = true;
        DiscoveredEnvironmentsCountTxt: Label 'Discovered environments count: %1.', Locked = true, Comment = '%1 = The number of environments discovered';
        EnvironmentUrlEmptyTxt: Label 'Environment URL is empty.', Locked = true;
        GlobalDiscoOnlyAvailableInSaaSMsg: Label 'Retreiving environment URL is only available in SaaS.';
        NoEnvironmentsWhenUrlNotEmptyMsg: Label 'No Common Data Service environments were discovered.';
        NoEnvironmentsWhenUrlEmptyMsg: Label 'No Common Data Service environments were discovered. Please enter the URL of the Common Data Service environment to connect to.';


    [Scope('OnPrem')]
    [NonDebuggable]
    procedure SelectTenantEnvironment(var CDSConnectionSetup: Record "CDS Connection Setup"; Token: Text; GuiAllowed: Boolean): Boolean
    var
        TempCDSEnvironment: Record "CDS Environment" temporary;
        EnvironmentInfo: Codeunit "Environment Information";
        EnvironmentCount: Integer;
    begin
        if not EnvironmentInfo.IsSaaS() then begin
            if GuiAllowed then
                Message(GlobalDiscoOnlyAvailableInSaaSMsg);
            exit(false);
        end;
        EnvironmentCount := GetCDSEnvironments(TempCDSEnvironment, Token);
        SendTraceTag('0000AVA', CategoryTok, VERBOSITY::Normal, StrSubstNo(DiscoveredEnvironmentsCountTxt, EnvironmentCount), DataClassification::SystemMetadata);

        if EnvironmentCount = 0 then begin
            if GuiAllowed then
                if (CDSConnectionSetup."Server Address" <> '') then
                    Message(NoEnvironmentsWhenUrlNotEmptyMsg)
                else
                    Message(NoEnvironmentsWhenUrlEmptyMsg);

            exit(false);
        end;

        if EnvironmentCount = 1 then begin
            TempCDSEnvironment.FindFirst();
            CDSConnectionSetup."Server Address" := TempCDSEnvironment.Url;
            SendTraceTag('0000BFV', CategoryTok, Verbosity::Normal, StrSubstNo(SelectedDefaultEnvironmentTxt, TempCDSEnvironment.Url), DataClassification::OrganizationIdentifiableInformation);
            exit(true);
        end;


        if PAGE.RunModal(PAGE::"CDS Environments", TempCDSEnvironment) = ACTION::LookupOK then begin
            SendTraceTag('0000AVC', CategoryTok, VERBOSITY::Normal, StrSubstNo(SelectedEnvironmentTxt, TempCDSEnvironment.Url), DataClassification::OrganizationIdentifiableInformation);
            CDSConnectionSetup."Server Address" := TempCDSEnvironment.Url;
            exit(true);
        end;
        exit(false);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetOnBehalfAuthorizationToken(): Text
    var
        Token: Text;
    begin
        if not TryGetOnBehalfAuthorizationToken(Token) then
            Token := '';
        if Token = '' then
            SendTraceTag('0000AVD', CategoryTok, VERBOSITY::Normal, CannotGetAuthorizationTokenTxt, DataClassification::SystemMetadata);

        exit(Token);
    end;

    [TryFunction]
    [NonDebuggable]
    [Scope('OnPrem')]
    local procedure TryGetOnBehalfAuthorizationToken(var Token: Text)
    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
    begin
        Token := AzureADMgt.GetOnBehalfAccessToken(GlobalDiscoUrlTok);
    end;

    [NonDebuggable]
    local procedure GetCDSEnvironments(var TempCDSEnvironment: Record "CDS Environment" temporary; Token: Text): Integer
    var
        TempBlob: Codeunit "Temp Blob";
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        Client: HttpClient;
        ResponseStream: InStream;
        EnvironmentsListLine: Text;
        EnvironmentsList: Text;
        IsSuccessful: Boolean;
        JsonResponse: JsonObject;
        JsonEnvironment: JsonToken;
        JsonEnvironmentList: JsonArray;
        JObject: JsonObject;
        JToken: JsonToken;
        StatusCode: Integer;
        EnvironmentCount: Integer;
    begin
        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', 'Bearer ' + Token);

        RequestMessage.SetRequestUri(GlobalDiscoApiUrlTok);
        RequestMessage.Method('GET');

        Clear(TempBlob);
        TempBlob.CreateInStream(ResponseStream);

        IsSuccessful := Client.Send(RequestMessage, ResponseMessage);

        if not IsSuccessful then begin
            SendTraceTag('0000AVE', CategoryTok, VERBOSITY::Normal, RequestFailedTxt, DataClassification::SystemMetadata);
            exit(0);
        end;

        if not ResponseMessage.IsSuccessStatusCode() then begin
            StatusCode := ResponseMessage.HttpStatusCode();
            SendTraceTag('0000B1B', CategoryTok, VERBOSITY::Warning, StrSubstNo(RequestFailedWithStatusCodeTxt, StatusCode), DATACLASSIFICATION::SystemMetadata);
            exit(0);
        end;

        if not ResponseMessage.Content().ReadAs(ResponseStream) then begin
            SendTraceTag('0000AVF', CategoryTok, VERBOSITY::Normal, CannotReadResponseTxt, DataClassification::SystemMetadata);
            exit(0);
        end;

        while not ResponseStream.EOS() do begin
            ResponseStream.ReadText(EnvironmentsListLine);
            EnvironmentsList += EnvironmentsListLine;
        end;

        if not JsonResponse.ReadFrom(EnvironmentsList) then begin
            SendTraceTag('0000AVG', CategoryTok, VERBOSITY::Normal, CannotParseResponseTxt, DataClassification::SystemMetadata);
            exit(0);
        end;
        if not JsonResponse.Get('value', JToken) then begin
            SendTraceTag('0000AVH', CategoryTok, VERBOSITY::Normal, CannotParseResponseTxt, DataClassification::SystemMetadata);
            exit(0);
        end;
        JsonEnvironmentList := JToken.AsArray();
        foreach JsonEnvironment in JsonEnvironmentList do begin
            JObject := JsonEnvironment.AsObject();

            TempCDSEnvironment.Init();

            if JObject.Get('Url', JToken) then
                TempCDSEnvironment.Url := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempCDSEnvironment.Url));

            if JObject.Get('ApiUrl', JToken) then
                TempCDSEnvironment."API Url" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempCDSEnvironment."API Url"));

            if JObject.Get('FriendlyName', JToken) then
                TempCDSEnvironment."Environment Name" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempCDSEnvironment."Environment Name"));

            if JObject.Get('Id', JToken) then
                Evaluate(TempCDSEnvironment.Id, JToken.AsValue().AsText());

            if JObject.Get('LastUpdated', JToken) then
                TempCDSEnvironment."Last Updated" := JToken.AsValue().AsDateTime();

            if JObject.Get('State', JToken) then
                TempCDSEnvironment.State := JToken.AsValue().AsInteger();

            if JObject.Get('UniqueName', JToken) then
                TempCDSEnvironment."Unique Name" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempCDSEnvironment."Unique Name"));

            if JObject.Get('UrlName', JToken) then
                TempCDSEnvironment."Url Name" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempCDSEnvironment."Url Name"));

            if JObject.Get('Version', JToken) then
                TempCDSEnvironment.Version := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempCDSEnvironment.Version));

            if TempCDSEnvironment.Url = '' then
                SendTraceTag('0000AVI', CategoryTok, VERBOSITY::Normal, EnvironmentUrlEmptyTxt, DataClassification::SystemMetadata)
            else
                if not TempCDSEnvironment.Insert() then
                    SendTraceTag('0000AVJ', CategoryTok, VERBOSITY::Normal, CannotInsertEnvironmentTxt, DataClassification::SystemMetadata)
                else
                    EnvironmentCount += 1;
        end;

        exit(EnvironmentCount);
    end;

    var
        GlobalDiscoUrlTok: Label 'https://globaldisco.crm.dynamics.com/', Locked = true;
        GlobalDiscoApiUrlTok: Label 'https://globaldisco.crm.dynamics.com/api/discovery/v1.0/Instances', Locked = true;
        RequestFailedWithStatusCodeTxt: Label 'Request failed with status code %1.', Locked = true;

}