codeunit 49 GlobalTriggerManagement
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000002, 'GetGlobalTableTriggerMask', '', false, false)]
    local procedure GetGlobalTableTriggerMask(TableID: Integer; var TableTriggerMask: Integer)
    begin
        OnAfterGetGlobalTableTriggerMask(TableID, TableTriggerMask);
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000002, 'OnGlobalInsert', '', false, false)]
    local procedure OnGlobalInsert(RecRef: RecordRef)
    begin
        OnAfterOnGlobalInsert(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000002, 'OnGlobalModify', '', false, false)]
    local procedure OnGlobalModify(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        OnAfterOnGlobalModify(RecRef, xRecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000002, 'OnGlobalDelete', '', false, false)]
    local procedure OnGlobalDelete(RecRef: RecordRef)
    begin
        OnAfterOnGlobalDelete(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000002, 'OnGlobalRename', '', false, false)]
    local procedure OnGlobalRename(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        OnAfterOnGlobalRename(RecRef, xRecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000002, 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure GetDatabaseTableTriggerSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        IntegrationManagement: Codeunit "Integration Management";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ChangeLogMgt: Codeunit "Change Log Management";
        APIWebhookNotificationMgt: Codeunit "API Webhook Notification Mgt.";
    begin
        ChangeLogMgt.GetDatabaseTableTriggerSetup(TableId, OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename);
        IntegrationManagement.GetDatabaseTableTriggerSetup(TableId, OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename);
        CRMIntegrationManagement.GetDatabaseTableTriggerSetup(TableId, OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename);
        APIWebhookNotificationMgt.GetDatabaseTableTriggerSetup(TableId, OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename);
        OnAfterGetDatabaseTableTriggerSetup(TableId, OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename);
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000002, 'OnDatabaseInsert', '', false, false)]
    local procedure OnDatabaseInsert(RecRef: RecordRef)
    var
        IntegrationManagement: Codeunit "Integration Management";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ChangeLogMgt: Codeunit "Change Log Management";
        APIWebhookNotificationMgt: Codeunit "API Webhook Notification Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDatabaseInsert(RecRef, IsHandled);
        if IsHandled then
            exit;

        ChangeLogMgt.LogInsertion(RecRef);
        IntegrationManagement.OnDatabaseInsert(RecRef);
        CRMIntegrationManagement.OnDatabaseInsert(RecRef);
        APIWebhookNotificationMgt.OnDatabaseInsert(RecRef);
        OnAfterOnDatabaseInsert(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000002, 'OnDatabaseModify', '', false, false)]
    local procedure OnDatabaseModify(RecRef: RecordRef)
    var
        IntegrationManagement: Codeunit "Integration Management";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ChangeLogMgt: Codeunit "Change Log Management";
        APIWebhookNotificationMgt: Codeunit "API Webhook Notification Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDatabaseModify(RecRef, IsHandled);
        if IsHandled then
            exit;

        ChangeLogMgt.LogModification(RecRef);
        IntegrationManagement.OnDatabaseModify(RecRef);
        CRMIntegrationManagement.OnDatabaseModify(RecRef);
        APIWebhookNotificationMgt.OnDatabaseModify(RecRef);
        OnAfterOnDatabaseModify(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000002, 'OnDatabaseDelete', '', false, false)]
    local procedure OnDatabaseDelete(RecRef: RecordRef)
    var
        IntegrationManagement: Codeunit "Integration Management";
        ChangeLogMgt: Codeunit "Change Log Management";
        APIWebhookNotificationMgt: Codeunit "API Webhook Notification Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDatabaseDelete(RecRef, IsHandled);
        if IsHandled then
            exit;

        ChangeLogMgt.LogDeletion(RecRef);
        IntegrationManagement.OnDatabaseDelete(RecRef);
        APIWebhookNotificationMgt.OnDatabaseDelete(RecRef);
        OnAfterOnDatabaseDelete(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000002, 'OnDatabaseRename', '', false, false)]
    local procedure OnDatabaseRename(RecRef: RecordRef; xRecRef: RecordRef)
    var
        IntegrationManagement: Codeunit "Integration Management";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ChangeLogMgt: Codeunit "Change Log Management";
        APIWebhookNotificationMgt: Codeunit "API Webhook Notification Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDatabaseRename(RecRef, xRecRef, IsHandled);
        if IsHandled then
            exit;

        ChangeLogMgt.LogRename(RecRef, xRecRef);
        IntegrationManagement.OnDatabaseRename(RecRef, xRecRef);
        CRMIntegrationManagement.OnDatabaseRename(RecRef, xRecRef);
        APIWebhookNotificationMgt.OnDatabaseRename(RecRef, xRecRef);
        OnAfterOnDatabaseRename(RecRef, xRecRef);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGlobalTableTriggerMask(TableID: Integer; var TableTriggerMask: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnGlobalInsert(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnGlobalModify(RecRef: RecordRef; xRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnGlobalDelete(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnGlobalRename(RecRef: RecordRef; xRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDatabaseTableTriggerSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnDatabaseInsert(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnDatabaseModify(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnDatabaseDelete(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnDatabaseRename(RecRef: RecordRef; xRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDatabaseInsert(RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDatabaseModify(RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDatabaseDelete(RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDatabaseRename(RecRef: RecordRef; xRecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;
}

