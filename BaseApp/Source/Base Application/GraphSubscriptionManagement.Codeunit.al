codeunit 5450 "Graph Subscription Management"
{
    Permissions = TableData "Webhook Subscription" = rimd;

    trigger OnRun()
    var
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
        SyncMode: Option;
    begin
        SyncMode := SyncModeOption::Delta;
        CheckGraphSubscriptions(SyncMode);

        case SyncMode of
            SyncModeOption::Full:
                GraphSyncRunner.RunFullSync;
            SyncModeOption::Delta:
                GraphSyncRunner.RunDeltaSync;
        end;
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        SyncModeOption: Option Full,Delta;
        ChangeType: Option Created,Updated,Deleted,Missed;

    procedure AddOrUpdateGraphSubscription(var FirstTimeSync: Boolean; WebhookExists: Boolean; var WebhookSubscription: Record "Webhook Subscription"; EntityEndpoint: Text[250])
    var
        GraphSubscription: Record "Graph Subscription";
        WebhookManagement: Codeunit "Webhook Management";
    begin
        FirstTimeSync := FirstTimeSync or not WebhookExists;
        case true of
            not WebhookExists:
                CreateNewWebhookSubscription(GraphSubscription, WebhookSubscription, EntityEndpoint);
            not GraphSubscription.Get(WebhookSubscription."Subscription ID"):
                CreateNewGraphSubscription(GraphSubscription, WebhookSubscription, EntityEndpoint);
            GraphSubscription.NotificationUrl <> WebhookManagement.GetNotificationUrl:
                begin
                    if GraphSubscription.Delete then;
                    CreateNewGraphSubscription(GraphSubscription, WebhookSubscription, EntityEndpoint);
                end;
            else begin
                    GraphSubscription.ExpirationDateTime := CurrentDateTime + GetMaximumExpirationDateTimeOffset;
                    GraphSubscription.Type := GetGraphSubscriptionType;
                    if GraphSubscription.Modify then;
                end;
        end;
    end;

    procedure CleanExistingWebhookSubscription(ResourceUrl: Text[250]; CompName: Text[30])
    var
        WebhookSubscription: Record "Webhook Subscription";
        WebhookSubscription2: Record "Webhook Subscription";
    begin
        if WebhookSubscription.FindSet then
            repeat
                if (WebhookSubscription.Endpoint = ResourceUrl) and
                   (WebhookSubscription."Company Name" = CompName)
                then begin
                    WebhookSubscription2.Get(WebhookSubscription."Subscription ID", WebhookSubscription.Endpoint);
                    WebhookSubscription2.Delete();
                end;
            until WebhookSubscription.Next = 0;
    end;

    procedure GetDestinationRecordRef(var NAVRecordRef: RecordRef; WebhookNotification: Record "Webhook Notification"; TableID: Integer) Retrieved: Boolean
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        DestinationRecordId: RecordID;
    begin
        if GraphIntegrationRecord.FindRecordIDFromID(WebhookNotification."Resource ID", TableID, DestinationRecordId) then
            Retrieved := NAVRecordRef.Get(DestinationRecordId);
    end;

    procedure GetGraphSubscriptionType(): Text[250]
    begin
        exit('#Microsoft.OutlookServices.PushSubscription');
    end;

    procedure GetGraphSubscriptionCreatedChangeType(): Text[50]
    begin
        exit(Format(ChangeType::Created, 0, 0));
    end;

    procedure GetMaximumExpirationDateTimeOffset(): Integer
    begin
        // Maximum expiration datetime is 4230 minutes as documented in https://dev.office.com/blogs/Microsoft-Graph-webhooks-update-March-2016
        exit(4230 * 60 * 1000);
    end;

    procedure GetSourceRecordRef(var GraphRecordRef: RecordRef; WebhookNotification: Record "Webhook Notification"; IntegrationTableID: Integer) Retrieved: Boolean
    begin
        OnGetSourceRecordRef(GraphRecordRef, WebhookNotification, IntegrationTableID, Retrieved);
    end;

    procedure TraceCategory(): Text
    begin
        exit('AL SyncEngine');
    end;

    procedure UpdateGraphOnAfterDelete(var EntityRecordRef: RecordRef)
    var
        IntegrationRecordArchive: Record "Integration Record Archive";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        if EntityRecordRef.IsTemporary then
            exit;

        if ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Background then
            exit;

        if not GraphSyncRunner.IsGraphSyncEnabled then
            exit;

        if not IntegrationRecordArchive.FindByRecordId(EntityRecordRef.RecordId) then
            exit;

        if CanScheduleSyncTasks then
            TASKSCHEDULER.CreateTask(CODEUNIT::"Graph Sync. Runner - OnDelete", 0, true, CompanyName, 0DT, IntegrationRecordArchive.RecordId)
        else
            CODEUNIT.Run(CODEUNIT::"Graph Sync. Runner - OnDelete", IntegrationRecordArchive);
    end;

    procedure UpdateGraphOnAfterInsert(var EntityRecordRef: RecordRef)
    var
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        if EntityRecordRef.IsTemporary then
            exit;

        if not GraphSyncRunner.IsGraphSyncEnabled then
            exit;

        if not CanSyncOnInsert() then
            exit;

        if not GraphDataSetup.CanSyncRecord(EntityRecordRef) then
            exit;

        // When a record is inserted, schedule a sync after a short period of time
        RescheduleTask(CODEUNIT::"Graph Subscription Management", CODEUNIT::"Graph Delta Sync", 0, 10000);
    end;

    procedure UpdateGraphOnAfterModify(var EntityRecordRef: RecordRef)
    var
        IntegrationRecord: Record "Integration Record";
        GraphSyncRunner: Codeunit "Graph Sync. Runner";
    begin
        if EntityRecordRef.IsTemporary then
            exit;

        if ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Background then
            exit;

        if not GraphSyncRunner.IsGraphSyncEnabled then
            exit;

        if not IntegrationRecord.FindByRecordId(EntityRecordRef.RecordId) then
            exit;

        RescheduleTask(CODEUNIT::"Graph Sync. Runner - OnModify", 0, IntegrationRecord.RecordId, 10000);
        if not CanScheduleSyncTasks then
            CODEUNIT.Run(CODEUNIT::"Graph Sync. Runner - OnModify", IntegrationRecord);
    end;

    local procedure CanScheduleSyncTasks() AllowBackgroundSessions: Boolean
    begin
        if TASKSCHEDULER.CanCreateTask then begin
            AllowBackgroundSessions := true;
            OnBeforeRunGraphSyncBackgroundSession(AllowBackgroundSessions);
        end;
    end;

    local procedure CanSyncOnInsert() CanSync: Boolean
    begin
        CanSync := not GuiAllowed;
        OnCanSyncOnInsert(CanSync);
    end;

    local procedure CheckGraphSubscriptions(var SyncMode: Option)
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        FirstTimeSync: Boolean;
    begin
        GraphConnectionSetup.RegisterConnections;
        OnBeforeAddOrUpdateGraphSubscriptions(FirstTimeSync);
        if FirstTimeSync then
            SyncMode := SyncModeOption::Full
        else
            SyncMode := SyncModeOption::Delta;
    end;

    local procedure CreateNewGraphSubscription(var GraphSubscription: Record "Graph Subscription"; var WebhookSubscription: Record "Webhook Subscription"; EntityEndpoint: Text[250])
    begin
        if GraphSubscription.CreateGraphSubscription(GraphSubscription, EntityEndpoint) then
            if WebhookSubscription.Delete then
                if GraphSubscription.CreateWebhookSubscription(WebhookSubscription) then
                    Commit();
    end;

    local procedure CreateNewWebhookSubscription(var GraphSubscription: Record "Graph Subscription"; var WebhookSubscription: Record "Webhook Subscription"; EntityEndpoint: Text[250])
    begin
        if GraphSubscription.CreateGraphSubscription(GraphSubscription, EntityEndpoint) then
            if GraphSubscription.CreateWebhookSubscription(WebhookSubscription) then
                Commit();
    end;

    local procedure RescheduleTask(CodeunitID: Integer; FailureCodeunitID: Integer; RecordID: Variant; DelayMillis: Integer)
    var
        ScheduledTask: Record "Scheduled Task";
        NextTask: DateTime;
    begin
        NextTask := CurrentDateTime + DelayMillis;

        ScheduledTask.SetRange(Company, CompanyName);
        ScheduledTask.SetRange("Run Codeunit", CodeunitID);
        ScheduledTask.SetFilter("Not Before", '<%1', NextTask);

        if RecordID.IsRecordId then
            ScheduledTask.SetRange(Record, RecordID);

        if ScheduledTask.FindFirst then
            TASKSCHEDULER.CancelTask(ScheduledTask.ID);

        OnScheduleSyncTask(CodeunitID, FailureCodeunitID, NextTask, RecordID);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5450, 'OnScheduleSyncTask', '', false, false)]
    local procedure InvokeTaskSchedulerOnScheduleSyncTask(CodeunitID: Integer; FailureCodeunitID: Integer; NotBefore: DateTime; RecordID: Variant)
    begin
        if CanScheduleSyncTasks then begin
            if RecordID.IsRecordId then
                TASKSCHEDULER.CreateTask(CodeunitID, FailureCodeunitID, true, CompanyName, NotBefore, RecordID)
            else
                TASKSCHEDULER.CreateTask(CodeunitID, FailureCodeunitID, true, CompanyName, NotBefore);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddOrUpdateGraphSubscriptions(var FirstTimeSync: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunGraphSyncBackgroundSession(var AllowBackgroundSessions: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanSyncOnInsert(var CanSync: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceRecordRef(var GraphRecordRef: RecordRef; WebhookNotification: Record "Webhook Notification"; IntegrationTableID: Integer; var Retrieved: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnScheduleSyncTask(CodeunitID: Integer; FailureCodeunitID: Integer; NotBefore: DateTime; RecordID: Variant)
    begin
    end;
}

