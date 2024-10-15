codeunit 4014 "Notification Handler"
{
    var
        UpgradeAvailableServiceTypeTxt: Label 'UpgradeAvailable', Locked = true;

    [EventSubscriber(ObjectType::Table, Database::"Webhook Notification", 'OnAfterInsertEvent', '', false, false)]
    local procedure HandleIntelligentCloudOnInsertWebhookNotification(var Rec: Record "Webhook Notification"; RunTrigger: Boolean)
    var
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
    begin
        SelectLatestVersion();

        case true of
            HybridCloudManagement.CanHandleServiceNotification(Rec."Subscription ID", ''):
                HandleServiceNotification(Rec);
            HybridCloudManagement.CanHandleNotification(Rec."Subscription ID", ''):
                HandleNotification(Rec);
        end;
    end;

    local procedure HandleNotification(var WebhookNotification: Record "Webhook Notification")
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
        NotificationStream: InStream;
        NotificationText: Text;
    begin
        WebhookNotification.Notification.CreateInStream(NotificationStream);
        NotificationStream.ReadText(NotificationText);

        ParseReplicationSummary(HybridReplicationSummary, NotificationText);
        HybridCloudManagement.OnReplicationRunCompleted(HybridReplicationSummary."Run ID", WebhookNotification."Subscription ID", NotificationText);
    end;

    local procedure HandleServiceNotification(var WebhookNotification: Record "Webhook Notification")
    var
        JsonManagement: Codeunit "JSON Management";
        NotificationStream: InStream;
        NotificationText: Text;
        ServiceType: Text;
    begin
        WebhookNotification.Notification.CreateInStream(NotificationStream);
        NotificationStream.ReadText(NotificationText);
        JsonManagement.InitializeObject(NotificationText);
        JsonManagement.GetStringPropertyValueByName('ServiceType', ServiceType);

        case ServiceType of
            UpgradeAvailableServiceTypeTxt:
                ProcessUpgradeAvailableNotification(NotificationText);
            else
                HandleNotification(WebhookNotification);
        end;
    end;

    local procedure GetExtensionRefreshErrorMessage(ExtensionRefreshTxt: Text): Text
    var
        HybridMessageManagement: Codeunit "Hybrid Message Management";
        JsonManagement: Codeunit "JSON Management";
        MessageCode: Text;
        ErrorMessage: Text;
        Value: Text;
    begin
        JsonManagement.InitializeObject(ExtensionRefreshTxt);
        if JsonManagement.GetStringPropertyValueByName('ErrorCode', MessageCode) then
            if MessageCode <> '' then
                ErrorMessage := HybridMessageManagement.ResolveMessageCode(CopyStr(MessageCode, 1, 10), '');

        if JsonManagement.GetStringPropertyValueByName('FailedExtensions', Value) then
            ErrorMessage += ' ' + Value;
        exit(ErrorMessage);
    end;

    procedure ParseReplicationSummary(var HybridReplicationSummary: Record "Hybrid Replication Summary"; NotificationText: Text)
    var
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
        HybridMessageManagement: Codeunit "Hybrid Message Management";
        JsonManagement: Codeunit "JSON Management";
        OutlookSynchTypeConv: Codeunit "Outlook Synch. Type Conv";
        Value: Text;
        Details: Text;
        MessageCode: Text;
    begin
        JsonManagement.InitializeObject(NotificationText);
        JsonManagement.GetStringPropertyValueByName('RunId', Value);

        if not HybridReplicationSummary.Get(Value) then begin
            HybridReplicationSummary.Init();
            HybridReplicationSummary."Run ID" := CopyStr(Value, 1, 50);
            HybridReplicationSummary.Insert();
        end;

        if JsonManagement.GetStringPropertyValueByName('StartTime', Value) then
            if Evaluate(HybridReplicationSummary."Start Time", Value) then
                HybridReplicationSummary."Start Time" := OutlookSynchTypeConv.UTC2LocalDT(HybridReplicationSummary."Start Time");

        if JsonManagement.GetStringPropertyValueByName('TriggerType', Value) then
            if not Evaluate(HybridReplicationSummary."Trigger Type", Value) then;

        if JsonManagement.GetStringPropertyValueByName('ReplicationType', Value) and (HybridReplicationSummary.ReplicationType = 0) then
            if not Evaluate(HybridReplicationSummary.ReplicationType, Value) then;

        if JsonManagement.GetStringPropertyValueByName('Status', Value) then
            if not Evaluate(HybridReplicationSummary.Status, Value) then;

        if JsonManagement.GetStringPropertyValueByName('Details', Details) or JsonManagement.GetStringPropertyValueByName('Code', MessageCode) then begin
            if MessageCode <> '' then
                Details := HybridMessageManagement.ResolveMessageCode(CopyStr(MessageCode, 1, 10), Details);

            if HybridReplicationSummary.Status = HybridReplicationSummary.Status::Completed then
                HybridReplicationSummary.SetDetails(Details);

            if HybridReplicationSummary.Status = HybridReplicationSummary.Status::Failed then
                if not TryParseErrors(HybridReplicationSummary, Details) then
                    HybridReplicationSummary.SetDetails(Details);
        end;

        if HybridReplicationSummary.Status = HybridReplicationSummary.Status::Completed then begin
            if JsonManagement.GetStringPropertyValueByName('ExtensionRefreshFailed', Value) then
                HybridReplicationSummary.AddDetails(GetExtensionRefreshErrorMessage(Value));

            if JsonManagement.GetStringPropertyValueByName('ExtensionRefreshUnexpectedError', Value) then
                HybridReplicationSummary.AddDetails(GetExtensionRefreshErrorMessage(Value));
        end;

        if HybridReplicationSummary.Status <> HybridReplicationSummary.Status::InProgress then
            HybridReplicationSummary."End Time" := CurrentDateTime();

        HybridReplicationSummary.Source := CopyStr(HybridCloudManagement.GetChosenProductName(), 1, 250);
        HybridReplicationSummary.Modify();
        Commit();
    end;

    local procedure ProcessUpgradeAvailableNotification(NotificationText: Text)
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        JsonManagement: Codeunit "JSON Management";
        Version: Text;
    begin
        JsonManagement.InitializeObject(NotificationText);
        JsonManagement.GetStringPropertyValueByName('Version', Version);

        IntelligentCloudSetup.SetLatestVersion(Version);
    end;

    local procedure ProcessUpgradeCompletedNotification(NotificationText: Text)
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        JsonManagement: Codeunit "JSON Management";
        HybridMessageManagement: Codeunit "Hybrid Message Management";
        RunId: Text;
        StartTime: Text;
        Details: Text;
        MessageCode: Text;
    begin
        JsonManagement.InitializeObject(NotificationText);
        JsonManagement.GetStringPropertyValueByName('RunId', RunId);
        JsonManagement.GetStringPropertyValueByName('StartTime', StartTime);
        JsonManagement.GetStringPropertyValueByName('Details', Details);
        JsonManagement.GetStringPropertyValueByName('Code', MessageCode);

        if not HybridReplicationSummary.Get(RunId) then begin
            HybridReplicationSummary.Init();
            HybridReplicationSummary."Run ID" := CopyStr(RunId, 1, 50);
            HybridReplicationSummary.Insert();
        end;

        Evaluate(HybridReplicationSummary."Start Time", StartTime);
        HybridReplicationSummary."End Time" := CurrentDateTime();
        HybridReplicationSummary.SetDetails(
            HybridMessageManagement.ResolveMessageCode(CopyStr(MessageCode, 1, 10), Details));
        HybridReplicationSummary.Modify();
    end;

    [TryFunction]
    local procedure TryParseErrors(var HybridReplicationSummary: Record "Hybrid Replication Summary"; Details: Text)
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        HybridDeployment: Codeunit "Hybrid Deployment";
        HybridMessageManagement: Codeunit "Hybrid Message Management";
        PipelineRunId: Text;
        Errors: Text;
        Status: Text;
    begin
        IntelligentCloudSetup.Get();
        HybridDeployment.Initialize(IntelligentCloudSetup."Product ID");
        if not TryParsePipelineRunId(Details, PipelineRunId) then
            PipelineRunId := HybridReplicationSummary."Run ID";

        HybridDeployment.GetReplicationRunStatus(PipelineRunId, Status, Errors);
        if not (Errors in ['', '[]']) then begin
            Errors := HybridMessageManagement.ResolveMessageCode('', Errors);
            HybridReplicationSummary.SetDetails(Errors);
        end else
            HybridReplicationSummary.SetDetails(Details);
    end;

    [TryFunction]
    local procedure TryParsePipelineRunId(Details: Text; var PipelineRunId: Text)
    var
        JSONManagement: Codeunit "JSON Management";
    begin
        JSONManagement.InitializeObject(Details);
        JSONManagement.GetStringPropertyValueByName('pipelineRunId', PipelineRunId)
    end;
}