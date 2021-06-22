codeunit 5457 "Graph Sync. - Contact"
{

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
        UpdatingGraphRecordTxt: Label 'Updating record for table %1 in Graph.', Locked = true;
        DeletingGraphRecordTxt: Label 'Deleting record for table %1 in Graph.', Locked = true;
        InsertingGraphRecordTxt: Label 'Inserting record for table %1 in Graph.', Locked = true;
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
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        exit(MarketingSetup.Get and MarketingSetup."Sync with Microsoft Graph");
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
                SendTraceTag(
                  '00001BF', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal, FoundWebhookTxt, DATACLASSIFICATION::SystemMetadata);
                IntegrationMappingCode := IntegrationMappingCodeTxt
            end else begin
                SendTraceTag(
                  '00001BG', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal,
                  MissingWebhookTxt, DATACLASSIFICATION::SystemMetadata);
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
        SendTraceTag(
          '00001BH', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal,
          RegisterConnectionsTxt, DATACLASSIFICATION::SystemMetadata);

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
            SendTraceTag(
              '00001BI', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal, DeltaSyncTxt, DATACLASSIFICATION::SystemMetadata);
            GraphSyncRunner.RunDeltaSyncForEntity(DATABASE::Contact);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5452, 'OnRunGraphFullSync', '', false, false)]
    local procedure OnRunContactFullSync()
    var
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        if SyncEnabled then begin
            SendTraceTag(
              '00001BJ', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal, FullSyncTxt, DATACLASSIFICATION::SystemMetadata);
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
                            SendTraceTag(
                              '00001BK', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal,
                              FoundUncoupledGraphRecordTxt, DATACLASSIFICATION::SystemMetadata);
                            exit;
                        end;
                until GraphContact.Next = 0;
        end;

        SendTraceTag(
          '00001BL', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal,
          MissingUncoupledGraphRecordTxt, DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Table, 5050, 'OnAfterDeleteEvent', '', false, false)]
    local procedure UpdateGraphOnAfterContactDelete(var Rec: Record Contact; RunTrigger: Boolean)
    var
        GraphSubscriptionManagement: Codeunit "Graph Subscription Management";
        EntityRecordRef: RecordRef;
    begin
        if SyncEnabled then begin
            EntityRecordRef.GetTable(Rec);
            SendTraceTag(
              '00001BM', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal,
              StrSubstNo(DeletingGraphRecordTxt, EntityRecordRef.Number), DATACLASSIFICATION::SystemMetadata);
            GraphSubscriptionManagement.UpdateGraphOnAfterDelete(EntityRecordRef);
        end;
    end;

    [EventSubscriber(ObjectType::Table, 5050, 'OnAfterInsertEvent', '', false, false)]
    local procedure UpdateGraphOnAfterContactInsert(var Rec: Record Contact; RunTrigger: Boolean)
    var
        GraphSubscriptionManagement: Codeunit "Graph Subscription Management";
        EntityRecordRef: RecordRef;
    begin
        if SyncEnabled then begin
            EntityRecordRef.GetTable(Rec);
            SendTraceTag(
              '00001P5', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal,
              StrSubstNo(InsertingGraphRecordTxt, EntityRecordRef.Number), DATACLASSIFICATION::SystemMetadata);
            GraphSubscriptionManagement.UpdateGraphOnAfterInsert(EntityRecordRef);
        end;
    end;

    [EventSubscriber(ObjectType::Table, 5050, 'OnAfterModifyEvent', '', false, false)]
    local procedure UpdateGraphOnAfterContactModify(var Rec: Record Contact; var xRec: Record Contact; RunTrigger: Boolean)
    var
        GraphSubscriptionManagement: Codeunit "Graph Subscription Management";
        EntityRecordRef: RecordRef;
    begin
        if SyncEnabled then begin
            EntityRecordRef.GetTable(Rec);
            SendTraceTag(
              '00001BN', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal,
              StrSubstNo(UpdatingGraphRecordTxt, EntityRecordRef.Number), DATACLASSIFICATION::SystemMetadata);
            GraphSubscriptionManagement.UpdateGraphOnAfterModify(EntityRecordRef);
        end;
    end;
}

