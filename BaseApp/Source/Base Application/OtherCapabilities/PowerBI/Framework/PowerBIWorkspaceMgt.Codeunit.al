codeunit 6319 "Power BI Workspace Mgt."
{
    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
        MyWorkspaceTxt: Label 'My Workspace', Comment = 'Workspace here is meant as "Power BI workspace". The wording "My Workspace" is used by Power BI.', MaxLength = 200;
        ParseWorkspacesWarningTelemetryMsg: Label 'Parse workspaces encountered an unexpected token.', Locked = true;
        FailedToInsertWorkspaceTelemetryMsg: Label 'Failed to insert workspace in buffer.', Locked = true;
        GetDataFailedTelemetryMsg: Label 'Could not get workspace data. Status code: %1.', Locked = true;
        WorkspaceResponseNotJsonTelemetryErrMsg: Label 'Workspace response is not a json.', Locked = true;
        WorkspacesAddedTelemetryMsg: Label 'Workspaces added. Initial count: %1, final count: %2.', Locked = true;
        UrlTooLongTelemetryMsg: Label 'Parsing reports encountered a URL that is too long to be saved to ReportEmbedUrl. Length: %1.', Locked = true;
        ParseReportsWarningTelemetryMsg: Label 'Parse reports encountered an unexpected token.', Locked = true;
        FailedToInsertReportTelemetryMsg: Label 'Could not insert parsed report.', Locked = true;
        MissingUrlErrorTelemetryMsg: Label 'Missing URL for Report Configuration.', Locked = true;

    [Scope('OnPrem')]
    procedure GetMyWorkspaceLabel(): Text[200]
    begin
        exit(MyWorkspaceTxt);
    end;

    [Scope('OnPrem')]
    procedure AddPersonalWorkspace(var TempPowerBISelectionElement: Record "Power BI Selection Element" temporary)
    begin
        TempPowerBISelectionElement.Init();
        TempPowerBISelectionElement.Type := TempPowerBISelectionElement.Type::Workspace;
        TempPowerBISelectionElement.Name := MyWorkspaceTxt;
        TempPowerBISelectionElement.WorkspaceName := TempPowerBISelectionElement.Name;
        TempPowerBISelectionElement.EmbedUrl := CopyStr(PowerBIServiceMgt.GetReportsUrl(), 1, MaxStrLen(TempPowerBISelectionElement.EmbedUrl));
        TempPowerBISelectionElement.Insert();
    end;

    [Scope('OnPrem')]
    procedure AddSharedWorkspaces(var TempPowerBISelectionElement: Record "Power BI Selection Element" temporary)
    var
        ExceptionMessage: Text;
        ExceptionDetails: Text;
        ResponseData: Text;
        InitialCount: Integer;
        ErrorStatusCode: Integer;
    begin
        // Workspace.Read.All
        InitialCount := TempPowerBISelectionElement.Count();

        ResponseData := PowerBIServiceMgt.GetDataCatchErrors(ExceptionMessage, ExceptionDetails, ErrorStatusCode, PowerBIUrlMgt.GetPowerBIWorkspacesUrl());
        if (ExceptionMessage <> '') or (ErrorStatusCode <> 0) then begin
            Session.LogMessage('0000F1X', StrSubstNo(GetDataFailedTelemetryMsg, ErrorStatusCode), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
            exit;
        end;

        ParseWorkspaces(TempPowerBISelectionElement, ResponseData);
        Session.LogMessage('0000F20', StrSubstNo(WorkspacesAddedTelemetryMsg, InitialCount, TempPowerBISelectionElement.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
    end;

    [Scope('OnPrem')]
    procedure GetReportsUrlForWorkspace(PowerBISelectionElement: Record "Power BI Selection Element" temporary): Text
    begin
        exit(PowerBIUrlMgt.GetPowerBISharedReportsUrl(PowerBISelectionElement.ID));
    end;

    local procedure ParseWorkspaces(var TempPowerBISelectionElement: Record "Power BI Selection Element" temporary; ResponseData: Text)
    var
        JToken: JsonToken;
        JArrayElement: JsonToken;
        JObject: JsonObject;
    begin
        if not JObject.ReadFrom(ResponseData) then begin
            Session.LogMessage('0000F1Y', WorkspaceResponseNotJsonTelemetryErrMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
            exit;
        end;

        if JObject.Get('value', JToken) then
            if JToken.IsArray() then begin
                foreach JArrayElement in JToken.AsArray() do
                    if JArrayElement.IsObject then begin
                        if not TryParseWorkspace(TempPowerBISelectionElement, JArrayElement.AsObject()) then
                            Session.LogMessage('0000F1Z', ParseWorkspacesWarningTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
                    end else
                        Session.LogMessage('0000F1D', ParseWorkspacesWarningTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
                exit;
            end;

        Session.LogMessage('0000F1E', ParseWorkspacesWarningTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
    end;

    [TryFunction]
    local procedure TryParseWorkspace(var TempPowerBISelectionElement: Record "Power BI Selection Element" temporary; JObj: JsonObject)
    var
        JToken: JsonToken;
    begin
        TempPowerBISelectionElement.Init();

        // report GUID identifier
        JObj.SelectToken('id', JToken);
        Evaluate(TempPowerBISelectionElement.ID, JToken.AsValue().AsText());
        Evaluate(TempPowerBISelectionElement.WorkspaceID, JToken.AsValue().AsText());

        // report name
        JObj.SelectToken('name', JToken);
        TempPowerBISelectionElement.Name := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempPowerBISelectionElement.Name));
        TempPowerBISelectionElement.WorkspaceName := TempPowerBISelectionElement.Name;
        TempPowerBISelectionElement.Type := TempPowerBISelectionElement.Type::Workspace;
        TempPowerBISelectionElement.EmbedUrl := CopyStr(GetReportsUrlForWorkspace(TempPowerBISelectionElement), 1, MaxStrLen(TempPowerBISelectionElement.EmbedUrl));

        if not TempPowerBISelectionElement.Insert() then
            Session.LogMessage('0000F21', FailedToInsertWorkspaceTelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
    end;

    [Scope('OnPrem')]
    procedure GetReportsAndWorkspaces(var TempPowerBISelectionElement: Record "Power BI Selection Element" temporary; EnglishContext: Text[30])
    var
        TempWorkspacePowerBISelectionElement: Record "Power BI Selection Element" temporary;
    begin
        TempPowerBISelectionElement.Reset();

        // Gets a list of reports from the user's Power BI account and loads them into the given buffer.
        // Reports are marked as Enabled if they've previously been selected for the given context (page ID).
        if not TempPowerBISelectionElement.IsEmpty() then
            exit;

        // Get reports for My Workspace
        AddPersonalWorkspace(TempPowerBISelectionElement);
        AddSharedWorkspaces(TempPowerBISelectionElement);

        TempWorkspacePowerBISelectionElement.Copy(TempPowerBISelectionElement, true);
        TempWorkspacePowerBISelectionElement.SetRange(Type, TempPowerBISelectionElement.Type::Workspace);

        if TempWorkspacePowerBISelectionElement.FindSet() then
            repeat
                GetReportsForWorkspace(TempPowerBISelectionElement, TempWorkspacePowerBISelectionElement, EnglishContext);
            until TempWorkspacePowerBISelectionElement.Next() = 0;
    end;

    local procedure GetReportsForWorkspace(var TempPowerBISelectionElement: Record "Power BI Selection Element" temporary; var TempWorkspacePowerBISelectionElement: Record "Power BI Selection Element" temporary; EnglishContext: Text[30])
    var
        ResponseText: Text;
        HttpErrorCode: Integer;
        JObj: JsonObject;
        ExceptionMessage: Text;
        ExceptionDetails: Text;
    begin
        // Do not catch errors if we cannot access the personal workspace: we should instead throw
        if IsNullGuid(TempWorkspacePowerBISelectionElement.ID) then
            ResponseText := PowerBIServiceMgt.GetData(ExceptionMessage, ExceptionDetails, TempWorkspacePowerBISelectionElement.EmbedUrl)
        else begin
            ResponseText := PowerBIServiceMgt.GetDataCatchErrors(ExceptionMessage, ExceptionDetails, HttpErrorCode, TempWorkspacePowerBISelectionElement.EmbedUrl);

            if (ExceptionMessage <> '') or (HttpErrorCode <> 0) then begin
                Session.LogMessage('0000F2C', StrSubstNo(GetDataFailedTelemetryMsg, HttpErrorCode), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
                exit;
            end;
        end;

        JObj.ReadFrom(ResponseText);
        ParseReports(TempPowerBISelectionElement, JObj, EnglishContext, TempWorkspacePowerBISelectionElement);
    end;

    [TryFunction]
    local procedure TryParseReport(var TempPowerBISelectionElement: Record "Power BI Selection Element" temporary; JObj: JsonObject; EnglishContext: Text[30]; TempWorkspacePowerBISelectionElement: Record "Power BI Selection Element" temporary)
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
        JToken: JsonToken;
    begin
        TempPowerBISelectionElement.Init();

        // report GUID identifier
        JObj.SelectToken('id', JToken);
        Evaluate(TempPowerBISelectionElement.ID, JToken.AsValue().AsText());

        // report name
        JObj.SelectToken('name', JToken);
        TempPowerBISelectionElement.Name := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempPowerBISelectionElement.Name));

        // report embedding url; if the url is too long, handle gracefully but issue an error message to telemetry
        JObj.SelectToken('embedUrl', JToken);
        if JToken.IsValue() then
            if StrLen(JToken.AsValue().AsText()) > MaxStrLen(TempPowerBISelectionElement.EmbedUrl) then
                Session.LogMessage('0000BAV', StrSubstNo(UrlTooLongTelemetryMsg, StrLen(JToken.AsValue().AsText())), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
        TempPowerBISelectionElement.Validate(EmbedUrl,
            CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TempPowerBISelectionElement.EmbedUrl)));

        PowerBIReportConfiguration.Reset();
        if PowerBIReportConfiguration.Get(UserSecurityId(), TempPowerBISelectionElement.ID, EnglishContext) then begin
            // report enabled
            TempPowerBISelectionElement.Enabled := true;

            if PowerBIReportConfiguration.ReportEmbedUrl = '' then
                Session.LogMessage('0000FBW', MissingUrlErrorTelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
        end;

        TempPowerBISelectionElement.Type := TempPowerBISelectionElement.Type::Report;
        TempPowerBISelectionElement.WorkspaceName := TempWorkspacePowerBISelectionElement.Name;
        TempPowerBISelectionElement.WorkspaceID := TempWorkspacePowerBISelectionElement.ID;

        if not TempPowerBISelectionElement.Insert() then
            Session.LogMessage('0000F2D', FailedToInsertReportTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
    end;

    local procedure ParseReports(var TempPowerBISelectionElement: Record "Power BI Selection Element" temporary; JObj: JsonObject; EnglishContext: Text[30]; TempWorkspacePowerBISelectionElement: Record "Power BI Selection Element" temporary)
    var
        JToken: JsonToken;
        JArrayElement: JsonToken;
    begin
        if JObj.Get('value', JToken) then
            if JToken.IsArray() then begin
                foreach JArrayElement in JToken.AsArray() do
                    if JArrayElement.IsObject then begin
                        if not TryParseReport(TempPowerBISelectionElement, JArrayElement.AsObject(), EnglishContext, TempWorkspacePowerBISelectionElement) then
                            Session.LogMessage('0000FBX', ParseReportsWarningTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory())
                    end else
                        Session.LogMessage('0000B70', ParseReportsWarningTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
                exit;
            end;

        Session.LogMessage('0000B71', ParseReportsWarningTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
    end;

#if not CLEAN21
    [Scope('OnPrem')]
    [IntegrationEvent(false, false)]
    [Obsolete('Events to override the Power BI integration behavior are no longer supported.', '21.0')]
    procedure OnGetReportsAndWorkspaces(var TempPowerBISelectionElement: Record "Power BI Selection Element" temporary; EnglishContext: Text[30])
    begin
    end;
#endif
}