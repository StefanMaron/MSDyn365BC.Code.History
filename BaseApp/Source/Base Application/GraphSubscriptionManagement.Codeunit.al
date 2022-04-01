#if not CLEAN18
#pragma warning disable
codeunit 5450 "Graph Subscription Management"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed. The functionality is not supported any more.';
    ObsoleteTag = '18.0';
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
        if WebhookSubscription.FindSet() then
            repeat
                if (WebhookSubscription.Endpoint = ResourceUrl) and
                   (WebhookSubscription."Company Name" = CompName)
                then begin
                    WebhookSubscription2.Get(WebhookSubscription."Subscription ID", WebhookSubscription.Endpoint);
                    WebhookSubscription2.Delete();
                end;
            until WebhookSubscription.Next() = 0;
    end;

    [Obsolete('This function will be removed, Graph Integration Record is not supported any more.', '18.0')]
    procedure GetDestinationRecordRef(var NAVRecordRef: RecordRef; WebhookNotification: Record "Webhook Notification"; TableID: Integer) Retrieved: Boolean
    var
    begin
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

    [Obsolete('This function will be removed, Graph Integration Record is not supported any more.', '18.0')]
    procedure UpdateGraphOnAfterDelete(var EntityRecordRef: RecordRef)
    begin
        exit;
    end;

    procedure UpdateGraphOnAfterInsert(var EntityRecordRef: RecordRef)
    begin
        exit;
    end;

    procedure UpdateGraphOnAfterModify(var EntityRecordRef: RecordRef)
    begin
        exit;
    end;

    local procedure CanScheduleSyncTasks() AllowBackgroundSessions: Boolean
    begin
        if TASKSCHEDULER.CanCreateTask then begin
            AllowBackgroundSessions := true;
            OnBeforeRunGraphSyncBackgroundSession(AllowBackgroundSessions);
        end;
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Subscription Management", 'OnScheduleSyncTask', '', false, false)]
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
#pragma warning restore

#endif