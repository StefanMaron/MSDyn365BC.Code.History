codeunit 5441 "Graph Sync. - Business Profile"
{

    trigger OnRun()
    var
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        if GraphSyncRunner.IsGraphSyncEnabled and SyncEnabled then
            GraphSyncRunner.RunDeltaSyncForEntity(DATABASE::"Company Information");
    end;

    var
        IntegrationMappingCodeTxt: Label 'SyncGraphBizProfile', Locked = true;
        InboundConnectionNameTxt: Label 'InboundBusinessProfile', Locked = true;
        SubscriptionConnectionNameTxt: Label 'SubscribeBusinessProfile', Locked = true;
        SynchronizeConnectionNameTxt: Label 'SynchronizeBusinessProfile', Locked = true;
        BusinessProfileReadWriteRoleTxt: Label 'BusinessProfiles-Internal.ReadWrite', Locked = true;
        EnablingBusinessProfileSyncTxt: Label 'Enabling Business Profile sync.', Locked = true;
        DisablingBusinessProfileSyncTxt: Label 'Disabling Business Profile sync.', Locked = true;
        GraphSubscriptionManagement: Codeunit "Graph Subscription Management";
        FoundUncoupledBusinessProfileTxt: Label 'Found uncoupled record for Business Profile.', Locked = true;
        MissingUncoupledBusinessProfileTxt: Label 'Could not find uncoupled record for Business Profile.', Locked = true;
        FullSyncTxt: Label 'Starting full Graph sync for Business Profile.', Locked = true;
        DeltaSyncTxt: Label 'Starting delta Graph sync for Business Profile.', Locked = true;

    local procedure CanHandleMapping(MappingCode: Code[20]): Boolean
    begin
        exit(UpperCase(MappingCode) = UpperCase(IntegrationMappingCodeTxt));
    end;

    local procedure EntityEndpoint(): Text[250]
    begin
        exit('https://outlook.office365.com/SmallBusiness/api/v1/users(''{SHAREDCONTACTS}'')/BusinessProfiles');
    end;

    local procedure EntityListEndpoint(): Text[250]
    begin
        exit('https://outlook.office365.com/SmallBusiness/api/v1/users(''{SHAREDCONTACTS}'')/BusinessProfiles');
    end;

    local procedure GetEntityTableID(): Integer
    begin
        exit(DATABASE::"Company Information");
    end;

    local procedure GetInboundConnectionString() ConnectionString: Text
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
    begin
        ConnectionString := GraphConnectionSetup.ConstructConnectionString(EntityEndpoint, EntityListEndpoint,
            ResourceUri, BusinessProfileReadWriteRoleTxt);
    end;

    local procedure GetSubscriptionConnectionString(): Text
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
    begin
        exit(GraphConnectionSetup.ConstructConnectionString(SubscriptionEndpoint, SubscriptionEndpoint,
            ResourceUri, BusinessProfileReadWriteRoleTxt));
    end;

    local procedure GetSynchronizeConnectionString(): Text
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
    begin
        exit(GraphConnectionSetup.ConstructConnectionString(EntityEndpoint, EntityListEndpoint,
            ResourceUri, BusinessProfileReadWriteRoleTxt));
    end;

    local procedure MapField(FieldNo: Integer; IntegrationFieldNo: Integer; ValidateField: Boolean)
    var
        GraphDataSetup: Codeunit "Graph Data Setup";
    begin
        GraphDataSetup.AddIntgrationFieldMapping(IntegrationMappingCodeTxt, FieldNo, IntegrationFieldNo, ValidateField);
    end;

    local procedure ResourceUri(): Text
    begin
        exit('https://outlook.office365.com');
    end;

    local procedure SubscriptionEndpoint(): Text[250]
    begin
        exit('');
    end;

    local procedure SyncEnabled(): Boolean
    var
        CompanyInformation: Record "Company Information";
    begin
        exit(CompanyInformation.Get and CompanyInformation."Sync with O365 Bus. profile");
    end;

    [EventSubscriber(ObjectType::Table, 5079, 'OnBeforeModifyEvent', '', false, false)]
    local procedure EnableBusinessProfileSyncOnEnableGraphSync(var Rec: Record "Marketing Setup"; var xRec: Record "Marketing Setup"; RunTrigger: Boolean)
    var
        CompanyInformation: Record "Company Information";
        GraphIntBusinessProfile: Codeunit "Graph Int - Business Profile";
    begin
        if not RunTrigger or Rec.IsTemporary then
            exit;

        if xRec.Find and (Rec."Sync with Microsoft Graph" <> xRec."Sync with Microsoft Graph") then begin
            CompanyInformation.LockTable();
            CompanyInformation.Get();
            if Rec."Sync with Microsoft Graph" and not CompanyInformation.IsSyncEnabledForOtherCompany then begin
                SendTraceTag(
                  '00001B8', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal,
                  EnablingBusinessProfileSyncTxt, DATACLASSIFICATION::SystemMetadata);
                CompanyInformation."Sync with O365 Bus. profile" := true;
                CompanyInformation.Modify();
            end else begin
                SendTraceTag(
                  '00001B9', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal,
                  DisablingBusinessProfileSyncTxt, DATACLASSIFICATION::SystemMetadata);
                CompanyInformation."Sync with O365 Bus. profile" := false;
                CompanyInformation.Modify();
                GraphIntBusinessProfile.UpdateCompanyBusinessProfileId('');
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnFindUncoupledDestinationRecord', '', false, false)]
    local procedure GetCompanyInformationOnFindUncoupledDestinationRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var DestinationIsDeleted: Boolean; var DestinationFound: Boolean)
    var
        CompanyInformation: Record "Company Information";
        GraphBusinessProfile: Record "Graph Business Profile";
    begin
        if CanHandleMapping(IntegrationTableMapping.Name) then begin
            if SourceRecordRef.Number = DATABASE::"Graph Business Profile" then begin
                CompanyInformation.Get();
                DestinationRecordRef.GetTable(CompanyInformation);
                DestinationFound := true;
            end else
                if GraphBusinessProfile.FindFirst then begin// Only one Graph Business Profile record, so take the first one if it is there
                    DestinationRecordRef.GetTable(GraphBusinessProfile);
                    DestinationFound := true;
                end;

            if DestinationFound then
                SendTraceTag(
                  '00001BA', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal,
                  FoundUncoupledBusinessProfileTxt, DATACLASSIFICATION::SystemMetadata)
            else
                SendTraceTag(
                  '00001BB', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal,
                  MissingUncoupledBusinessProfileTxt, DATACLASSIFICATION::SystemMetadata);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5455, 'OnAddIntegrationMapping', '', false, false)]
    local procedure OnAddBusinessProfileIntegrationMapping(MappingCode: Code[20])
    var
        CompanyInformation: Record "Company Information";
        TempGraphBusinessProfile: Record "Graph Business Profile" temporary;
        GraphDataSetup: Codeunit "Graph Data Setup";
    begin
        if not CanHandleMapping(MappingCode) then
            exit;

        // Add Graph Business Profile <=> Company information table mapping
        GraphDataSetup.AddIntegrationTableMapping(MappingCode, DATABASE::"Company Information", DATABASE::"Graph Business Profile",
          TempGraphBusinessProfile.FieldNo(Id), TempGraphBusinessProfile.FieldNo(LastModifiedDate), '', 0,
          TempGraphBusinessProfile.FieldNo(ETag), 0);

        // Add Graph Business Profile <=> Company Information field mapping
        MapField(CompanyInformation.FieldNo(Name), TempGraphBusinessProfile.FieldNo(Name), false);
        MapField(CompanyInformation.FieldNo("Country/Region Code"), TempGraphBusinessProfile.FieldNo(CountryCode), true);
        MapField(CompanyInformation.FieldNo("VAT Registration No."), TempGraphBusinessProfile.FieldNo("Tax Id"), false);
        MapField(CompanyInformation.FieldNo("Industrial Classification"), TempGraphBusinessProfile.FieldNo(Industry), false);
        MapField(CompanyInformation.FieldNo("Brand Color Value"), TempGraphBusinessProfile.FieldNo(BrandColor), true);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5452, 'OnCheckAuxiliarySyncEnabled', '', false, false)]
    local procedure OnCheckAuxiliarySyncEnabled(var AuxSyncEnabled: Boolean)
    begin
        if AuxSyncEnabled then
            exit;
        AuxSyncEnabled := SyncEnabled;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5455, 'OnCreateIntegrationMappings', '', false, false)]
    local procedure OnCreateBusinessProfileIntegrationMappings()
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphIntBusinessProfile: Codeunit "Graph Int - Business Profile";
    begin
        GraphDataSetup.CreateIntegrationMapping(IntegrationMappingCodeTxt);
        GraphIntegrationRecord.SetRange("Table ID", GetEntityTableID);
        if GraphIntegrationRecord.FindFirst then
            GraphIntBusinessProfile.UpdateCompanyBusinessProfileId(GraphIntegrationRecord."Graph ID");
    end;

    [EventSubscriber(ObjectType::Codeunit, 5446, 'OnFindWebhookSubscription', '', false, false)]
    local procedure OnFindWebhookSubscription(var WebhookSubscription: Record "Webhook Subscription"; SubscriptionID: Text[150]; var IntegrationMappingCode: Code[20])
    begin
        if IntegrationMappingCode = '' then
            if WebhookSubscription.Get(SubscriptionID, EntityListEndpoint) then
                IntegrationMappingCode := IntegrationMappingCodeTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5455, 'OnGetGraphRecord', '', false, false)]
    local procedure OnGetGraphRecord(var GraphRecordRef: RecordRef; DestinationGraphID: Text[250]; TableID: Integer; var Found: Boolean)
    var
        GraphBusinessProfile: Record "Graph Business Profile";
    begin
        if Found then
            exit;
        if TableID <> GetEntityTableID then
            exit;

        if GraphBusinessProfile.Get(DestinationGraphID) then begin
            GraphRecordRef.GetTable(GraphBusinessProfile);
            Found := GraphBusinessProfile.Id <> '';
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
            TableID := GetEntityTableID;
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
        GraphBusinessProfile: Record "Graph Business Profile";
    begin
        if IntegrationTableID = DATABASE::"Graph Business Profile" then
            if GraphBusinessProfile.Get(WebhookNotification."Resource ID") then begin
                GraphRecordRef.GetTable(GraphBusinessProfile);
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

    [EventSubscriber(ObjectType::Codeunit, 5451, 'OnBeforeSynchronizationStart', '', false, false)]
    local procedure OnIgnoreSyncBasedOnChangekey(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        CompanyInformation: Record "Company Information";
        GraphIntegrationRecord: Record "Graph Integration Record";
        GraphBusinessProfile: Record "Graph Business Profile";
        DestinationGraphID: Text[250];
    begin
        if IgnoreRecord then
            exit;

        if SourceRecordRef.Number = GetEntityTableID then
            if not GraphIntegrationRecord.FindIDFromRecordID(CompanyInformation.RecordId, DestinationGraphID) then
                IgnoreRecord := true
            else
                if not GraphBusinessProfile.Get(DestinationGraphID) then begin
                    GraphIntegrationRecord.RemoveCouplingToGraphID(DestinationGraphID, DATABASE::"Company Information");
                    if GraphBusinessProfile.FindFirst then
                        GraphIntegrationRecord.CoupleRecordIdToGraphID(CompanyInformation.RecordId, GraphBusinessProfile.Id);
                end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5456, 'OnRegisterConnections', '', false, false)]
    local procedure OnRegisterConnections()
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
    begin
        GraphConnectionSetup.RegisterConnectionForEntity(
          InboundConnectionNameTxt, GetInboundConnectionString,
          SubscriptionConnectionNameTxt, GetSubscriptionConnectionString,
          SynchronizeConnectionNameTxt, GetSynchronizeConnectionString);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5452, 'OnRunGraphDeltaSync', '', false, false)]
    local procedure OnRunBusinessProfileDeltaSync()
    var
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        if SyncEnabled then begin
            SendTraceTag(
              '00001BC', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal, DeltaSyncTxt, DATACLASSIFICATION::SystemMetadata);
            GraphSyncRunner.RunDeltaSyncForEntity(GetEntityTableID);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5452, 'OnRunGraphFullSync', '', false, false)]
    local procedure OnRunBusinessProfileFullSync()
    var
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        if SyncEnabled then begin
            SendTraceTag(
              '00001BD', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Normal, FullSyncTxt, DATACLASSIFICATION::SystemMetadata);
            GraphSyncRunner.RunFullSyncForEntity(GetEntityTableID);
        end;
    end;

    [EventSubscriber(ObjectType::Table, 79, 'OnAfterModifyEvent', '', false, false)]
    local procedure UpdateGraphOnAfterCompanyInformationModify(var Rec: Record "Company Information"; var xRec: Record "Company Information"; RunTrigger: Boolean)
    var
        GraphSubscriptionManagement: Codeunit "Graph Subscription Management";
        EntityRecordRef: RecordRef;
    begin
        if RunTrigger and SyncEnabled then begin
            EntityRecordRef.GetTable(Rec);
            GraphSubscriptionManagement.UpdateGraphOnAfterModify(EntityRecordRef);
        end;
    end;
}

