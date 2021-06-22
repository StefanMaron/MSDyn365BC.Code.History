codeunit 5457 "Graph Sync. - Contact"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This functionality will be removed. The API that it was integrating to was discontinued.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
    end;

    var
        IntegrationMappingCodeTxt: Label 'SyncGraphContact', Locked = true;
        InboundConnectionNameTxt: Label 'InboundContact', Locked = true;
        SubscriptionConnectionNameTxt: Label 'SubscribeContact', Locked = true;
        SynchronizeConnectionNameTxt: Label 'SynchronizeContact', Locked = true;
        RegisterConnectionsTxt: Label 'Registering connections for Contact.', Locked = true;
        FoundWebhookTxt: Label 'Found webhook subscription for Contact with id %1.', Locked = true;
        MissingWebhookTxt: Label 'Could not find webhook subscription for Contact with id %1.', Locked = true;
        FoundUncoupledGraphRecordTxt: Label 'Found and coupled uncoupled Contact record.', Locked = true;
        MissingUncoupledGraphRecordTxt: Label 'Could not locate Graph record for uncoupled Contact record.', Locked = true;
        GraphSubscriptionManagement: Codeunit "Graph Subscription Management";
        FullSyncTxt: Label 'Starting full Graph sync for Contact.', Locked = true;
        DeltaSyncTxt: Label 'Starting delta Graph sync for Contact.', Locked = true;

    local procedure CanHandleMapping(MappingCode: Code[20]): Boolean
    begin
        exit(UpperCase(MappingCode) = UpperCase(IntegrationMappingCodeTxt));
    end;

    local procedure EntityEndpoint(): Text[250]
    begin
        exit('https://outlook.office365.com/api/beta/users(''{SHAREDCONTACTS}'')/contacts');
    end;

    local procedure EntityListEndpoint(): Text[250]
    begin
        exit('https://outlook.office365.com/api/beta/users(''{SHAREDCONTACTS}'')/contactfolders(''sharedbusinesscontacts'')/contacts');
    end;

    local procedure GetEntityTableID(): Integer
    begin
        exit(DATABASE::Contact);
    end;

    local procedure GetInboundConnectionString(): Text
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
    begin
        exit(GraphConnectionSetup.ConstructConnectionString(EntityEndpoint, EntityListEndpoint, ResourceUri, ''));
    end;

    local procedure GetSubscriptionConnectionString(): Text
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
    begin
        exit(GraphConnectionSetup.ConstructConnectionString(SubscriptionEndpoint, SubscriptionEndpoint, ResourceUri, ''));
    end;

    local procedure GetSynchronizeConnectionString(): Text
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
    begin
        exit(GraphConnectionSetup.ConstructConnectionString(EntityEndpoint, EntityListEndpoint, ResourceUri, ''));
    end;

    local procedure GetWebhookSubscription(var WebhookSubscription: Record "Webhook Subscription"): Boolean
    var
        WebhookManagement: Codeunit "Webhook Management";
        EndpointRegex: DotNet Regex;
    begin
        GetWebhookSubscriptionEndpointRegex(EndpointRegex);
        exit(WebhookManagement.FindMatchingWebhookSubscriptionRegex(WebhookSubscription, EndpointRegex));
    end;

    local procedure GetWebhookSubscriptionEndpointRegex(EndpointRegex: DotNet Regex)
    var
        EndpointSearchString: DotNet String;
    begin
        EndpointSearchString := EndpointRegex.Escape(EntityListEndpoint);
        EndpointSearchString := EndpointSearchString.Replace('\{SHAREDCONTACTS}', '.*');
        EndpointSearchString := EndpointSearchString.Replace('/', '\/');
        EndpointSearchString := EndpointSearchString.Replace('''', '\''');

        EndpointRegex := EndpointRegex.Regex(Format(EndpointSearchString));
    end;

    local procedure ResourceUri(): Text
    begin
        exit('https://outlook.office365.com');
    end;

    local procedure SubscriptionEndpoint(): Text[250]
    begin
        exit('https://outlook.office365.com/api/beta/users(''{SHAREDCONTACTS}'')/subscriptions');
    end;

    local procedure SyncEnabled(): Boolean
    begin
        // API is discontinued
        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5455, 'OnAddIntegrationMapping', '', false, false)]
    local procedure OnAddContactIntegrationMapping(MappingCode: Code[20])
    var
        Contact: Record Contact;
        TempGraphContact: Record "Graph Contact" temporary;
        GraphDataSetup: Codeunit "Graph Data Setup";
    begin
        if not CanHandleMapping(MappingCode) then
            exit;

        // Add Graph Contact <=> Contact table mapping
        GraphDataSetup.AddIntegrationTableMapping(MappingCode, DATABASE::Contact, DATABASE::"Graph Contact",
          TempGraphContact.FieldNo(Id), TempGraphContact.FieldNo(LastModifiedDateTime), '', TempGraphContact.FieldNo(DeltaToken),
          TempGraphContact.FieldNo(ChangeKey), TempGraphContact.FieldNo(IsNavCreated));

        // Add Graph Contact <=> Contact field mapping
        GraphDataSetup.AddIntgrationFieldMapping(MappingCode, Contact.FieldNo("First Name"), TempGraphContact.FieldNo(GivenName), false);
        GraphDataSetup.AddIntgrationFieldMapping(MappingCode, Contact.FieldNo("Middle Name"), TempGraphContact.FieldNo(MiddleName), false);
        GraphDataSetup.AddIntgrationFieldMapping(MappingCode, Contact.FieldNo(Surname), TempGraphContact.FieldNo(Surname), false);
        GraphDataSetup.AddIntgrationFieldMapping(MappingCode, Contact.FieldNo(Initials), TempGraphContact.FieldNo(Initials), false);
        GraphDataSetup.AddIntgrationFieldMapping(MappingCode, Contact.FieldNo("Job Title"), TempGraphContact.FieldNo(JobTitle), false);
        GraphDataSetup.AddIntgrationFieldMapping(MappingCode, Contact.FieldNo("Company Name"),
          TempGraphContact.FieldNo(CompanyName), false);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5450, 'OnBeforeAddOrUpdateGraphSubscriptions', '', false, false)]
    local procedure OnBeforeAddOrUpdateGraphSubscription(var FirstTimeSync: Boolean)
    var
        WebhookSubscription: Record "Webhook Subscription";
        GraphSubscriptionMgt: Codeunit "Graph Subscription Management";
        WebhookExists: Boolean;
    begin
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, SubscriptionConnectionNameTxt, true);
        WebhookExists := GetWebhookSubscription(WebhookSubscription);
        GraphSubscriptionMgt.AddOrUpdateGraphSubscription(FirstTimeSync, WebhookExists, WebhookSubscription, EntityListEndpoint);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5455, 'OnCheckCanSyncRecord', '', false, false)]
    local procedure OnCheckCanSyncRecord(EntityRecordRef: RecordRef; var CanSyncRecord: Boolean; var Handled: Boolean)
    var
        Contact: Record Contact;
    begin
        if EntityRecordRef.Number <> GetEntityTableID then
            exit;

        if not SyncEnabled then
            exit;

        EntityRecordRef.SetTable(Contact);
        CanSyncRecord := not (Contact.Name in ['', ' ']);
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5455, 'OnCreateIntegrationMappings', '', false, false)]
    local procedure OnCreateContactIntegrationMappings()
    var
        GraphDataSetup: Codeunit "Graph Data Setup";
    begin
        GraphDataSetup.CreateIntegrationMapping(IntegrationMappingCodeTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5446, 'OnFindWebhookSubscription', '', false, false)]
    local procedure OnFindWebhookSubscription(var WebhookSubscription: Record "Webhook Subscription"; SubscriptionID: Text[150]; var IntegrationMappingCode: Code[20])
    begin
        if IntegrationMappingCode = '' then begin
            WebhookSubscription.SetRange("Subscription ID", SubscriptionID);
            if GetWebhookSubscription(WebhookSubscription) then begin
                Session.LogMessage('00001BF', FoundWebhookTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GraphSubscriptionManagement.TraceCategory);
                IntegrationMappingCode := IntegrationMappingCodeTxt
            end else begin
                Session.LogMessage('00001BG', MissingWebhookTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GraphSubscriptionManagement.TraceCategory);
                WebhookSubscription.SetRange("Subscription ID");
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5455, 'OnGetGraphRecord', '', false, false)]
    local procedure OnGetGraphRecord(var GraphRecordRef: RecordRef; DestinationGraphID: Text[250]; TableID: Integer; var Found: Boolean)
    var
        GraphContact: Record "Graph Contact";
    begin
        if Found then
            exit;
        if TableID <> GetEntityTableID then
            exit;

        if GraphContact.Get(DestinationGraphID) then begin
            GraphRecordRef.GetTable(GraphContact);
            Found := GraphContact.Id <> '';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5456, 'OnGetInboundConnectionName', '', false, false)]
    local procedure OnGetInboundConnectionName(TableID: Integer; var ConnectionName: Text)
    begin
        if TableID = GetEntityTableID then
            ConnectionName := InboundConnectionNameTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5456, 'OnGetInboundConnectionString', '', false, false)]
    local procedure OnGetInboundConnectionString(TableID: Integer; var ConnectionString: Text)
    begin
        if TableID = GetEntityTableID then
            ConnectionString := GetInboundConnectionString;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5455, 'OnGetInboundTableID', '', false, false)]
    local procedure OnGetInboundTableID(MappingCode: Code[20]; var TableID: Integer)
    begin
        if CanHandleMapping(MappingCode) then
            TableID := DATABASE::Contact;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5455, 'OnGetMappingCodeForTable', '', false, false)]
    local procedure OnGetMappingCode(TableID: Integer; var MappingCode: Code[20])
    begin
        if TableID = GetEntityTableID then
            MappingCode := IntegrationMappingCodeTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5450, 'OnGetSourceRecordRef', '', false, false)]
    local procedure OnGetSourceRecordRef(var GraphRecordRef: RecordRef; WebhookNotification: Record "Webhook Notification"; IntegrationTableID: Integer; var Retrieved: Boolean)
    var
        GraphContact: Record "Graph Contact";
    begin
        if IntegrationTableID = DATABASE::"Graph Contact" then
            if GraphContact.Get(WebhookNotification."Resource ID") then begin
                GraphRecordRef.GetTable(GraphContact);
                Retrieved := true;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5456, 'OnGetSubscriptionConnectionName', '', false, false)]
    local procedure OnGetSubscriptionConnectionName(TableID: Integer; var ConnectionName: Text)
    begin
        if TableID = GetEntityTableID then
            ConnectionName := SubscriptionConnectionNameTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5456, 'OnGetSubscriptionConnectionString', '', false, false)]
    local procedure OnGetSubscriptionConnectionString(TableID: Integer; var ConnectionString: Text)
    begin
        if TableID = GetEntityTableID then
            ConnectionString := GetSubscriptionConnectionString;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5456, 'OnGetSynchronizeConnectionName', '', false, false)]
    local procedure OnGetSynchronizeConnectionName(TableID: Integer; var ConnectionName: Text)
    begin
        if TableID = GetEntityTableID then
            ConnectionName := SynchronizeConnectionNameTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5456, 'OnGetSynchronizeConnectionString', '', false, false)]
    local procedure OnGetSynchronizeConnectionString(TableID: Integer; var ConnectionString: Text)
    begin
        if TableID = GetEntityTableID then
            ConnectionString := GetSynchronizeConnectionString;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5456, 'OnRegisterConnections', '', false, false)]
    local procedure OnRegisterConnections()
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
    begin
        Session.LogMessage('00001BH', RegisterConnectionsTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GraphSubscriptionManagement.TraceCategory);

        GraphConnectionSetup.RegisterConnectionForEntity(
          InboundConnectionNameTxt, GetInboundConnectionString,
          SubscriptionConnectionNameTxt, GetSubscriptionConnectionString,
          SynchronizeConnectionNameTxt, GetSynchronizeConnectionString);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5452, 'OnRunGraphDeltaSync', '', false, false)]
    local procedure OnRunContactDeltaSync()
    var
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        if SyncEnabled then begin
            Session.LogMessage('00001BI', DeltaSyncTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GraphSubscriptionManagement.TraceCategory);
            GraphSyncRunner.RunDeltaSyncForEntity(DATABASE::Contact);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5452, 'OnRunGraphFullSync', '', false, false)]
    local procedure OnRunContactFullSync()
    var
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        if SyncEnabled then begin
            Session.LogMessage('00001BJ', FullSyncTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GraphSubscriptionManagement.TraceCategory);
            GraphSyncRunner.RunFullSyncForEntity(DATABASE::Contact);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnFindUncoupledDestinationRecord', '', false, false)]
    local procedure OnFindUncoupledDestinationRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var DestinationIsDeleted: Boolean; var DestinationFound: Boolean)
    var
        GraphContact: Record "Graph Contact";
        IntegrationRecord: Record "Integration Record";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        GraphIntegrationId: Guid;
        GraphIntegrationIdValue: Text;
    begin
        if not CanHandleMapping(IntegrationTableMapping.Name) then
            exit;

        if not IntegrationRecord.FindByRecordId(SourceRecordRef.RecordId) then
            exit;

        if SourceRecordRef.Number = GetEntityTableID then begin
            if GraphContact.FindSet then
                repeat
                    GraphIntegrationIdValue := GraphCollectionMgtContact.GetNavIntegrationId(GraphContact.GetNavIntegrationIdString);
                    if Evaluate(GraphIntegrationId, GraphIntegrationIdValue) then
                        if IntegrationRecord."Integration ID" = GraphIntegrationId then begin
                            DestinationFound := true;
                            DestinationRecordRef.GetTable(GraphContact);
                            Session.LogMessage('00001BK', FoundUncoupledGraphRecordTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GraphSubscriptionManagement.TraceCategory);
                            exit;
                        end;
                until GraphContact.Next = 0;
        end;

        Session.LogMessage('00001BL', MissingUncoupledGraphRecordTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GraphSubscriptionManagement.TraceCategory);
    end;
}

