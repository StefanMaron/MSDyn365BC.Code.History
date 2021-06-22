codeunit 130232 "Test Proxy Notif. Mgt. Ext."
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 130231, 'OnCheckIgnoringNotification', '', false, false)]
    local procedure SetIgnoreOnCheckIgnoringNotification(NotificationID: Guid; var Ignore: Boolean)
    begin
    end;
}

