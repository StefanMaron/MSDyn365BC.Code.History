codeunit 5010 "Web Service Helper"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed once OData V3 is deprecated';
    ObsoleteTag = '18.0';

    var
        ODataV3DepricationDescriptionTok: Label 'OData V3';
        ODataV3DepricationTok: Label 'OData V3 is deprecated. Please use OData V4';
        DontShowAgainTok: Label 'Don''t show me again';
        ShowMoreLinkTok: Label 'Show more';

    [Scope('OnPrem')]
    internal procedure ODataV3DeprecationNotificationId(): Guid
    begin
        exit('bf80a838-8daf-44ad-a2f7-9ca86d8b2b46')
    end;

    [Scope('OnPrem')]
    internal procedure ODataV3DeprecationNotificationDefault(Enabled: Boolean)
    var
        MyNotifications: Record "My Notifications";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;
        MyNotifications.InsertDefault(
          ODataV3DeprecationNotificationId(), ODataV3DepricationDescriptionTok, ODataV3DepricationTok, true);
    end;

    [Scope('OnPrem')]
    internal procedure OdataV3DepricationNotificationShow(ODataV3DepricationNotification: Notification)
    begin
        ODataV3DepricationNotification.Id := ODataV3DeprecationNotificationId();
        ODataV3DepricationNotification.Recall();
        ODataV3DepricationNotification.Message(ODataV3DepricationTok);
        ODataV3DepricationNotification.AddAction(DontShowAgainTok, Codeunit::"Web Service Helper", 'DisableNotifications');
        ODataV3DepricationNotification.AddAction(ShowMoreLinkTok, Codeunit::"Web Service Helper", 'ODataV3DepricationNotificationShowMore');
        ODataV3DepricationNotification.Scope(NotificationScope::LocalScope);
        ODataV3DepricationNotification.Send();
    end;

    [Scope('OnPrem')]
    internal procedure DisableNotifications(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.Disable(Notification.Id);
    end;

    [Scope('OnPrem')]
    internal procedure ODataV3DepricationNotificationShowMore(Notification: Notification)
    begin
        Hyperlink('https://go.microsoft.com/fwlink/?linkid=2144416');
    end;
}