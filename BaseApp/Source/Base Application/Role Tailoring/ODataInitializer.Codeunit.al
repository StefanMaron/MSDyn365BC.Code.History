codeunit 1738 "OData Initializer"
{
    Access = Internal;
    ObsoleteState = Pending;
    ObsoleteReason = 'This will become part of platform.';
    ObsoleteTag = '17.2';

    var
        EnvironmentInfo: Codeunit "Environment Information";
        CategoryTxt: Label 'Data initialization', Locked = true;
        NoTokenTxt: Label 'Access token could not be retrieved.', Locked = true;
        MetadataEndpointCallFailedTxt: Label 'Metadata endpoint call failed.', Locked = true;
        CallingEndpointTxt: Label 'Calling endpoint %1 with correlation id %2', Locked = true;
        BearerTxt: Label 'Bearer %1', Locked = true;

    trigger OnRun()
    begin
        CallMetadataEndpoint();
    end;

    [NonDebuggable]
    local procedure CallMetadataEndpoint()
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        UrlHelper: Codeunit "Url Helper";
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        TempBlob: Codeunit "Temp Blob";
        ResponseInStream: InStream;
        Token: Text;
        Endpoint: Text;
        CorrelationId: Guid;
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;

        Endpoint := GetUrl(CLIENTTYPE::ODataV4) + '/$metadata';
        Token := AzureAdMgt.GetAccessToken(UrlHelper.GetFixedEndpointWebServiceUrl(), '', false);
        if Token = '' then begin
            Session.LogMessage('0000E51', NoTokenTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
            exit;
        end;

        TempBlob.CreateInStream(ResponseInStream);
        CorrelationId := CreateGuid();
        Session.LogMessage('0000E53', StrSubstNo(CallingEndpointTxt, Endpoint, CorrelationId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);

        HttpWebRequestMgt.Initialize(Endpoint);
        HttpWebRequestMgt.SetMethod('GET');
        HttpWebRequestMgt.AddHeader('Authorization', StrSubstNo(BearerTxt, Token));
        HttpWebRequestMgt.AddHeader('x-ms-correlation-id', CorrelationId);
        if not HttpWebRequestMgt.GetResponseStream(ResponseInStream) then
            Session.LogMessage('0000E52', MetadataEndpointCallFailedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::LogInManagement, 'OnAfterLogInEnd', '', false, false)]
    local procedure OnAfterLogInEnd()
    var
        ODataInitializedStatus: Record "OData Initialized Status";
        moduleInfo: ModuleInfo;
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;

        if not TaskScheduler.CanCreateTask() then
            exit;

        if not NavApp.GetCurrentModuleInfo(moduleInfo) then
            exit;

        if not (ODataInitializedStatus.ReadPermission() and ODataInitializedStatus.WritePermission()) then
            exit;

        if ODataInitializedStatus.FindFirst() and (ODataInitializedStatus."Initialized version" = Format(moduleInfo.AppVersion())) then
            exit;

        // Make sure we only call this initialization once
        ODataInitializedStatus."Initialized version" := Format(moduleInfo.AppVersion());
        if ODataInitializedStatus.IsEmpty() then
            ODataInitializedStatus.Insert()
        else
            ODataInitializedStatus.Modify();

        TaskScheduler.CreateTask(Codeunit::"OData Initializer", 0, true, CompanyName(), CurrentDateTime() + 60 * 1000); // Run codeunit in 1 minute
    end;
}
