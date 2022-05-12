#if not CLEAN20
codeunit 9250 "XBRL Deprecation Notification"
{
    ObsoleteTag = '20.0';
    ObsoleteReason = 'This codeunit handles showing the XBRL deprecation notification, used on the XBRL pages that will now be deprecated. If you need to show this notification elsewhere, please create your custom notification instead.';
    ObsoleteState = Pending;

    procedure Show()
    var
        MyNotifications: Record "My Notifications";
        DeprecationNotification: Notification;
    begin
        if not MyNotifications.IsEnabled(NotificationIdTok) then
            exit;
        DeprecationNotification.Id(NotificationIdTok);
        DeprecationNotification.Message(NotificationMsg);
        DeprecationNotification.AddAction(DontShowAgainMsg, Codeunit::"XBRL Deprecation Notification", 'DisableNotification');
        DeprecationNotification.AddAction(LearnMoreMsg, Codeunit::"XBRL Deprecation Notification", 'LearnMore');
        DeprecationNotification.Send();
    end;

    procedure LearnMore(DeprecationNotification: Notification)
    begin
        Hyperlink(LearnMoreUrlTxt);
    end;

    procedure DisableNotification(DeprecationNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(NotificationIdTok) then
            MyNotifications.InsertDefault(NotificationIdTok, NotificationMsg, '', false);
    end;

    var
        NotificationIdTok: Label 'c880c623-80c4-4af7-a97c-3c05eca84e14', Locked = True;
        NotificationMsg: Label 'Support for XBRL reporting will be removed in a coming release.';
        DontShowAgainMsg: Label 'Don''t show again';
        LearnMoreMsg: Label 'Learn more';
        LearnMoreUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2185951';
}
#endif