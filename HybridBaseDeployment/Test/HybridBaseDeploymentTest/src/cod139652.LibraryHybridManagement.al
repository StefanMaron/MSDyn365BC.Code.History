codeunit 139652 "Library - Hybrid Management"
{
    EventSubscriberInstance = Manual;

    var
        TestJsonOutput: Text;
        ProductId: Text;
        ExpectedRunId: Text;
        ExpectedProduct: Text;
        ExpectedErrors: Text;
        ExpectedStatus: Text;
        DiagnosticRunsEnabled: Boolean;
        TableMappingEnabled: Boolean;
        ActualReplicationType: Integer;
        TestRuntimeNameTxt: Label 'TestRuntimeName';
        TestPrimaryKeyTxt: Label 'TestPrimaryKey';
        TestProductIdTxt: Label 'TestProductId', Locked = true;
        TestProductNameTxt: Label 'Test Product Name', Locked = true;
        TestSecondaryKeyTxt: Label 'TestSecondaryKey';
        TestTrackingIdTxt: Label 'TestTrackingID';
        TestDeployedVersionTxt: Label 'V1.0', Locked = true;
        TestLatestVersionTxt: Label 'V2.0', Locked = true;

    local procedure CanHandle(): Boolean
    var
        HybridDeploymentSetup: Record "Hybrid Deployment Setup";
    begin
        if HybridDeploymentSetup.Get() then
            exit(HybridDeploymentSetup."Handler Codeunit ID" = Codeunit::"Library - Hybrid Management");

        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnCreateIntegrationRuntime', '', false, false)]
    local procedure HandleCreateIntegrationRuntime(var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;

        TestJsonOutput := StrSubstNo('{ "Name": "%1", "PrimaryKey": "%2", "SecondaryKey": "%2" }', TestRuntimeNameTxt, TestPrimaryKeyTxt);
        InstanceId := TestTrackingIdTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnGetRequestStatus', '', false, false)]
    local procedure HandleGetRequestStatus(InstanceId: Text; var JsonOutput: Text; var status: Text)
    begin
        if not CanHandle() then
            exit;

        JsonOutput := TestJsonOutput;
        Status := 'Completed';

        TestJsonOutput := '';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnInitialize', '', false, false)]
    local procedure HandleInitialize(SourceProductId: Text)
    begin
        if not CanHandle() then
            exit;

        ProductId := SourceProductId;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnSetReplicationSchedule', '', false, false)]
    local procedure HandleSetReplicationSchedule(ReplicationFrequency: Text; DaysToRun: Text; TimeToRun: Time; Activate: Boolean; var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;
        InstanceId := TestTrackingIdTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnEnableReplication', '', false, false)]
    local procedure HandleEnableReplication(OnPremiseConnectionString: Text; DatabaseType: Text; IntegrationRuntimeName: Text; NotificationUrl: Text; ClientState: Text; SubscriptionId: Text; ServiceNotificationUrl: Text; ServiceClientState: Text; ServiceSubscriptionId: Text; var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;

        IntegrationRuntimeName := TestRuntimeNameTxt;
        InstanceId := TestTrackingIdTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnGetIntegrationRuntimeKeys', '', false, false)]
    local procedure HandleGetIntegrationKey(var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;
        InstanceId := TestTrackingIdTxt;
        TestJsonOutput := StrSubstNo('{ "PrimaryKey": "%1", "SecondaryKey": "%2" }', TestPrimaryKeyTxt, TestSecondaryKeyTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Hybrid Deployment", 'OnRunReplication', '', false, false)]
    local procedure HandleRunReplicationNow(var InstanceId: Text; ReplicationType: Integer)
    begin
        if not CanHandle() then
            exit;
        TestJsonOutput := '{ "RunId": "' + ExpectedRunId + '", "ReplicationType": ' + Format(ReplicationType) + ' }';
        ActualReplicationType := ReplicationType;
        InstanceId := TestTrackingIdTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Hybrid Deployment", 'OnDisableReplication', '', false, false)]
    local procedure HandleDisableReplication(var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;
        InstanceId := TestTrackingIdTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Hybrid Deployment", 'OnGetReplicationRunStatus', '', false, false)]
    local procedure HandleGetReplicationRunStatus(var InstanceId: Text; RunId: Text)
    begin
        if not CanHandle() then
            exit;

        InstanceId := TestTrackingIdTxt;
        TestJsonOutput := StrSubstNo('{ "ReplicationRunId": "%1", "Status": "%2", "Errors": { "$values": [ %3 ] } }', RunId, ExpectedStatus, ExpectedErrors);
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Hybrid Deployment", 'OnRegenerateIntegrationRuntimeKeys', '', false, false)]
    local procedure HandleRegenerateIntegrationKey(var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;
        InstanceId := TestTrackingIdTxt;
        TestJsonOutput := StrSubstNo('{ "PrimaryKey": "%1", "SecondaryKey": "%2" }', TestPrimaryKeyTxt, TestSecondaryKeyTxt);
    end;


    [EventSubscriber(ObjectType::Codeunit, codeunit::"Hybrid Deployment", 'OnGetVersionInformation', '', false, false)]
    local procedure HandleOnGetVersionInformation(var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;
        InstanceId := TestTrackingIdTxt;
        TestJsonOutput := StrSubstNo('{ "DeployedVersion": "%1", "LatestVersion": "%2" }', TestDeployedVersionTxt, TestLatestVersionTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Hybrid Deployment", 'OnRunUpgrade', '', false, false)]
    local procedure HandleOnRunUpgrade(var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;
        InstanceId := TestTrackingIdTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnGetHybridProductName', '', false, false)]
    local procedure HandleCreateCompanies(ProductId: Text; var ProductName: Text)
    begin
        if not CanHandle() then
            exit;

        if ProductId = ExpectedProduct then
            ProductName := ExpectedProduct;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnGetHybridProductType', '', false, false)]
    local procedure HandleOnGetHybridProductType(var HybridProductType: Record "Hybrid Product Type")
    begin
        if not HybridProductType.Get(GetTestProductId()) then begin
            HybridProductType.Init();
            HybridProductType."App ID" := CreateGuid();
            HybridProductType."Display Name" := CopyStr(GetTestProductName(), 1, 250);
            HybridProductType.ID := CopyStr(GetTestProductId(), 1, 250);
            HybridProductType.Insert(true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnGetHybridProductName', '', false, false)]
    local procedure HandleGetHybridProductName(ProductId: Text; var ProductName: Text)
    begin
        if ProductId = ExpectedProduct then
            ProductName := ExpectedProduct;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnCanSetupIntelligentCloud', '', false, false)]
    local procedure HandleCanSetupIntelligentCloud(var CanSetup: Boolean)
    begin
        CanSetup := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnCanCreateCompanies', '', false, false)]
    local procedure HandleCanCreateCompanies(var CanCreateCompanies: Boolean)
    begin
        CanCreateCompanies := false;
    end;

    procedure GetActualReplicationType(): Integer
    begin
        exit(ActualReplicationType);
    end;

    procedure GetNotificationPayload(SubscriptionId: Text; var RunId: Text; var StartTime: DateTime; var TriggerType: Text; AdditionalPropertiesJson: Text) Payload: Text
    var
        HybridDeploymentSummary: Record "Hybrid Replication Summary";
    begin
        Payload := GetNotificationPayload(SubscriptionId, RunId, StartTime, TriggerType, HybridDeploymentSummary.ReplicationType::Normal, AdditionalPropertiesJson);
    end;

    procedure GetNotificationPayload(SubscriptionId: Text; var RunId: Text; var StartTime: DateTime; var TriggerType: Text; ReplicationType: Integer; AdditionalPropertiesJson: Text) Payload: Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        if RunId = '' then
            RunId := CreateGuid();

        if StartTime = 0DT then
            StartTime := TypeHelper.GetCurrUTCDateTime();

        if TriggerType = '' then
            TriggerType := 'Manual';

        Payload := '{' +
                        '"@odata.type": "#Microsoft.Dynamics.NAV.Hybrid.Notification",' +
                        '"SubscriptionId": "' + SubscriptionId + '",' +
                        '"ChangeType": "Changed",' +
                        '"RunId": "' + RunId + '",' +
                        '"StartTime": "' + Format(StartTime, 0, 9) + '",' +
                        '"ReplicationType": ' + Format(ReplicationType) + ',' +
                        '"TriggerType": "' + TriggerType + '"' + AdditionalPropertiesJson +
                    '}';
    end;

    procedure GetServiceNotificationPayload(ServiceSubscriptionId: Text; ServiceType: Text; Version: Text) Payload: Text
    begin
        Payload := '{' +
                        '"@odata.type": "#Microsoft.Dynamics.NAV.Hybrid.Notification",' +
                        '"SubscriptionId": "' + ServiceSubscriptionId + '",' +
                        '"ServiceType": "' + ServiceType + '",' +
                        '"Version": "' + Version + '",' +
                    '}';
    end;

    procedure SetExpectedRunId(var NewRunId: Text)
    begin
        SetExpectedValue(NewRunId, ExpectedRunId);
    end;

    procedure SetExpectedProduct(var NewProduct: Text)
    begin
        SetExpectedValue(NewProduct, ExpectedProduct);
    end;

    procedure SetExpectedStatus(var NewStatus: Text; var NewErrors: Text)
    begin
        SetExpectedValue(NewStatus, ExpectedStatus);
        SetExpectedValue(NewErrors, ExpectedErrors);
    end;

    local procedure SetExpectedValue(var NewExpected: Text; var Expected: Text)
    begin
        if NewExpected = '' then
            NewExpected := CreateGuid();

        Expected := NewExpected;
    end;

    procedure GetTestProductId() TestProductId: Text
    begin
        TestProductId := TestProductIdTxt;
    end;

    procedure GetTestProductName() TestProductName: Text
    begin
        TestProductName := TestProductNameTxt;
    end;

    procedure SetDiagnosticRunsEnabled(Enabled: Boolean)
    begin
        DiagnosticRunsEnabled := Enabled;
    end;

    procedure SetTableMappingEnabled(Enabled: Boolean)
    begin
        TableMappingEnabled := Enabled;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Intelligent Cloud Management", 'CanRunDiagnostic', '', false, false)]
    local procedure CanRunDiagnostic(var CanRun: Boolean)
    begin
        CanRun := CanRun or DiagnosticRunsEnabled;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Intelligent Cloud Management", 'CanMapCustomTables', '', false, false)]
    local procedure CanMapTables(var Enabled: Boolean)
    begin
        Enabled := Enabled or TableMappingEnabled;
    end;
}