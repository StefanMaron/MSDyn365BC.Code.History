codeunit 132222 "Library - Notification Mgt."
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure RecallNotificationsForRecord(RecVarToRecall: Variant)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVarToRecall);
        RecallNotificationsForRecordID(RecRef.RecordId);
    end;

    [Scope('OnPrem')]
    procedure RecallNotificationsForRecordID(RecordIDToRecall: RecordID)
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.RecallNotificationsForRecord(RecordIDToRecall, false);
    end;

    procedure DisableAllNotifications()
    begin
        DisableImageAnalyzerNotifications();
    end;

    local procedure DisableImageAnalyzerNotifications()
    var
        NAVAppInstalledApp: Record "NAV App Installed App";
    begin
        NAVAppInstalledApp.SetRange("App ID", 'e868ad92-21b8-4e08-af2b-8975a8b06e04'); // IMAGE ANALYZER app ID
        if NAVAppInstalledApp.FindFirst() then
            DisableNotification('e54eb2c9-ebc2-4934-91d9-97af900e89b2',
              'Image Analysis notification name',
              'Image Analysis notification description');
    end;

    local procedure DisableNotification(NotificationGuid: Guid; NotificationName: Text[128]; NotificationDescription: Text)
    var
        MyNotifications: Record "My Notifications";
    begin
        if MyNotifications.Get(UserId, NotificationGuid) then begin
            MyNotifications.Enabled := false;
            MyNotifications.Modify(true);
        end else
            MyNotifications.InsertDefault(
              NotificationGuid,
              NotificationName,
              NotificationDescription,
              false);
    end;

    [Scope('OnPrem')]
    procedure DisableMyNotification(NotificationID: Guid)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(NotificationID, '', '', false);
        MyNotifications.Disable(NotificationID);
    end;

    [Scope('OnPrem')]
    procedure ClearTemporaryNotificationContext()
    var
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        TempNotificationContext.Reset();
        TempNotificationContext.DeleteAll();
    end;
}

