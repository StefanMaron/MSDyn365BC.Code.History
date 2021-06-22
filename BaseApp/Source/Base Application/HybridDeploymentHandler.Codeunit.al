codeunit 6061 "Hybrid Deployment Handler"
{
    Permissions = TableData "Hybrid Deployment Setup" = rimd;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        DotNet_HybridDeployment: Codeunit DotNet_HybridDeployment;
        SourceProduct: Text;

    local procedure CanHandle(): Boolean
    var
        HybridDeploymentSetup: Record "Hybrid Deployment Setup";
    begin
        if not HybridDeploymentSetup.Get then begin
            HybridDeploymentSetup.Init();
            HybridDeploymentSetup.Insert();
        end;

        exit(HybridDeploymentSetup."Handler Codeunit ID" = CODEUNIT::"Hybrid Deployment Handler");
    end;

    [EventSubscriber(ObjectType::Codeunit, 6060, 'OnCreateIntegrationRuntime', '', false, false)]
    local procedure HandleCreateIntegrationRuntime(var InstanceId: Text)
    begin
        if not CanHandle then
            exit;

        InstanceId := DotNet_HybridDeployment.CreateIntegrationRuntime(SourceProduct);
    end;

    [EventSubscriber(ObjectType::Codeunit, 6060, 'OnDisableReplication', '', false, false)]
    local procedure HandleDisableReplication(var InstanceId: Text)
    begin
        if not CanHandle then
            exit;

        InstanceId := DotNet_HybridDeployment.DisableReplication(SourceProduct);
    end;

    [EventSubscriber(ObjectType::Codeunit, 6060, 'OnEnableReplication', '', false, false)]
    local procedure HandleEnableReplication(OnPremiseConnectionString: Text; DatabaseType: Text; IntegrationRuntimeName: Text; NotificationUrl: Text; ClientState: Text; SubscriptionId: Text; ServiceNotificationUrl: Text; ServiceClientState: Text; ServiceSubscriptionId: Text; var InstanceId: Text)
    begin
        if not CanHandle then
            exit;

        InstanceId :=
          DotNet_HybridDeployment.EnableReplication(
            SourceProduct, OnPremiseConnectionString, DatabaseType, IntegrationRuntimeName, NotificationUrl, ClientState, SubscriptionId,
            ServiceNotificationUrl, ServiceClientState, ServiceSubscriptionId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 6060, 'OnGetIntegrationRuntimeKeys', '', false, false)]
    local procedure HandleGetIntegrationRuntimeKeys(var InstanceId: Text)
    begin
        if not CanHandle then
            exit;

        InstanceId := DotNet_HybridDeployment.GetIntegrationRuntimeKey(SourceProduct);
    end;

    [EventSubscriber(ObjectType::Codeunit, 6060, 'OnGetReplicationRunStatus', '', false, false)]
    local procedure HandleGetReplicationRunStatus(var InstanceId: Text; RunId: Text)
    begin
        if not CanHandle then
            exit;

        InstanceId := DotNet_HybridDeployment.GetReplicationRunStatus(SourceProduct, RunId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 6060, 'OnGetRequestStatus', '', false, false)]
    local procedure HandleGetRequestStatus(InstanceId: Text; var JsonOutput: Text; var Status: Text)
    begin
        if not CanHandle then
            exit;

        Status := DotNet_HybridDeployment.GetRequestStatus(InstanceId, JsonOutput);
    end;

    [EventSubscriber(ObjectType::Codeunit, 6060, 'OnGetVersionInformation', '', false, false)]
    local procedure HandleGetVersionInformation(var InstanceId: Text)
    begin
        if not CanHandle then
            exit;

        InstanceId := DotNet_HybridDeployment.GetVersionInformation(SourceProduct);
    end;

    [EventSubscriber(ObjectType::Codeunit, 6060, 'OnInitialize', '', false, false)]
    local procedure HandleInitialize(SourceProductId: Text)
    begin
        if not CanHandle then
            exit;

        SourceProduct := SourceProductId;
        DotNet_HybridDeployment.Initialize;
    end;

    [EventSubscriber(ObjectType::Codeunit, 6060, 'OnPrepareTablesForReplication', '', false, false)]
    local procedure HandlePrepareTables()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not CanHandle then
            exit;

        if EnvironmentInfo.IsSaaS then
            exit;

        DotNet_HybridDeployment.PrepareTablesForReplication;
    end;

    [EventSubscriber(ObjectType::Codeunit, 6060, 'OnRegenerateIntegrationRuntimeKeys', '', false, false)]
    local procedure HandleRegenerateIntegrationRuntimeKeys(var InstanceId: Text)
    begin
        if not CanHandle then
            exit;

        InstanceId := DotNet_HybridDeployment.RegenerateIntegrationRuntimeKey(SourceProduct);
    end;

    [EventSubscriber(ObjectType::Codeunit, 6060, 'OnRunReplication', '', false, false)]
    local procedure HandleRunReplication(var InstanceId: Text; ReplicationType: Integer)
    begin
        if not CanHandle then
            exit;

        InstanceId := DotNet_HybridDeployment.RunReplication(SourceProduct, ReplicationType)
    end;

    [EventSubscriber(ObjectType::Codeunit, 6060, 'OnRunUpgrade', '', false, false)]
    local procedure HandleRunUpgrade(var InstanceId: Text)
    begin
        if not CanHandle then
            exit;

        InstanceId := DotNet_HybridDeployment.RunUpgrade(SourceProduct)
    end;

    [EventSubscriber(ObjectType::Codeunit, 6060, 'OnSetReplicationSchedule', '', false, false)]
    local procedure HandleSetReplicationSchedule(ReplicationFrequency: Text; DaysToRun: Text; TimeToRun: Time; Activate: Boolean; var InstanceId: Text)
    begin
        if not CanHandle then
            exit;

        InstanceId := DotNet_HybridDeployment.SetReplicationSchedule(SourceProduct, ReplicationFrequency, DaysToRun, TimeToRun, Activate);
    end;
}

