/// <summary>
/// The purpose of this codeunit is to notify users with only Global Administration role that their capabilities in Business Central are limited. 
/// </summary>
codeunit 1444 "Global Admin Notifier"
{
    Access = Internal;

    var
        NotificationIdTxt: Label '73e599ef-135f-44da-9fa5-00d3fe3ba32c', Locked = true;
        MessageMsg: Label 'You are assigned to the Global Administrator role in Business Central but you are not assigned to a product license.';
        ActionTxt: Label 'Learn more';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Role Center Notification Mgt.", 'OnBeforeShowNotifications', '', false, false)]
    local procedure SendGlobalAdminNotification()
    var
        GlobalAdminNotification: Notification;
    begin
        if not IsUserGlobalAdminOnly() then
            exit;

        GlobalAdminNotification.Id := NotificationIdTxt;
        GlobalAdminNotification.Message := MessageMsg;
        GlobalAdminNotification.AddAction(ActionTxt, Codeunit::"Global Admin Notifier", 'DetailedMessage');
        GlobalAdminNotification.Send();

        Session.LogMessage('0000C0T', 'Notification was sent to user.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Global Admin Notification');
    end;

    internal procedure DetailedMessage(var Notification: Notification)
    begin
        Session.LogMessage('0000C0U', 'User clicked on notification action.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Global Admin Notification');

        Page.RunModal(Page::"Global Admin Message");
    end;

    // checks if the current user has only the Global Admin plan assigned
    local procedure IsUserGlobalAdminOnly(): Boolean
    var
        PlanIds: Codeunit "Plan Ids";
        UsersInPlans: Query "Users In Plans";
        IsUserGlobalAdmin: Boolean;
        DoesUserHaveOtherPlans: Boolean;
    begin
        UsersInPlans.SetFilter(User_Security_ID, UserSecurityId());

        if not UsersInPlans.Open() then
            exit(false);

        while UsersInPlans.Read() do
            if (UsersInPlans.Plan_ID = PlanIds.GetInternalAdminPlanId()) then
                IsUserGlobalAdmin := true
            else
                DoesUserHaveOtherPlans := true;

        exit(IsUserGlobalAdmin and (not DoesUserHaveOtherPlans));
    end;
}
