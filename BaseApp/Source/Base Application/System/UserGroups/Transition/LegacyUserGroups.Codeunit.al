#if not CLEAN22
namespace System.Security.AccessControl;

using System.Environment.Configuration;


/// <summary>
/// Provides functionality to determine whether the user group enhancements have been enabled.
/// </summary>
codeunit 9842 "Legacy User Groups"
{
    Access = Public;
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] User groups functionality is deprecated. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    ObsoleteTag = '22.0';

    var
        UserGroupFeatureKeyTxt: Label 'HideLegacyUserGroups', Locked = true;
        CannotEnableTheFeatureErr: Label 'Can''t enable the feature, because there are still user groups defined in the system.';
        ConfirmConvertUserGroupsQst: Label 'There are still user groups defined in the system. Do you want to run the user group conversion guide?';
        CannotAddUserGroupsErr: Label 'User groups can''t be created, use permission sets directly or security groups instead. To keep using user groups, switch off ''%1'' on the Feature Management page.', Comment = '%1 = the name of the feature switch, i. e. Feature: Convert user group permissions.';
        CannotAddUserGroupsTitleErr: Label 'Can''t add a new user group';
        FeatureSwitchEnabledUserGroupsPresentNotificationTxt: Label 'User groups functionality is disabled in your system, but you still have user groups defined. Disable ''%1'' and enable it again to convert user group permissions.', Comment = '%1 = the name of the feature switch, i. e. Feature: Convert user group permissions.';
        FeatureSwitchDisabledUserGroupsPresentNotificationTxt: Label 'User groups will be removed in a future release. You can convert user group permissions by enabling ''%1''.', Comment = '%1 = the name of the feature switch, i. e. Feature: Convert user group permissions.';
        FeatureSwitchEnabledNoUserGroupsNotificationTxt: Label 'User groups functionality is disabled in your system. If you want to use extensions that depend on user groups, you need to disable ''%1''.', Comment = '%1 = the name of the feature switch, i. e. Feature: Convert user group permissions.';
        FeatureSwitchDisabledNoUserGroupsNotificationTxt: Label 'User groups will be removed in a future release. You have no user groups defined, enable ''%1'' to hide fields, pages, and other UI elements related to use and management of user groups.', Comment = '%1 = the name of the feature switch, i. e. Feature: Convert user group permissions.';
        OpenFeatureManagementTok: Label 'Open Feature Management', Comment = 'Feature Management is the name of the page in BC';
        NotificationIdLbl: Label 'db6d3070-841f-46c8-9b05-b39621fc347b', Locked = true;

    /// <summary>
    /// Checks if user group UI elements are visible and user groups functionality is enabled. 
    /// </summary>
    // <returns>True if user group UI elements are visible, otherwise false.</returns>
    procedure UiElementsVisible(): Boolean
    var
        FeatureKey: Record "Feature Key";
    begin
        if FeatureKey.Get(UserGroupFeatureKeyTxt) then
            exit(not (FeatureKey.Enabled = FeatureKey.Enabled::"All Users"));

        exit(true);
    end;

    internal procedure SendUserGroupsNotification()
    var
        FeatureKey: Record "Feature Key";
        UserGroup: Record "User Group";
        UserGroupsNotification: Notification;
        FeatureSwitchEnabled: Boolean;
        FeatureSwitchName: Text;
    begin
        FeatureKey.Get(UserGroupFeatureKeyTxt);
        FeatureSwitchEnabled := FeatureKey.Enabled = FeatureKey.Enabled::"All Users";
        FeatureSwitchName := FeatureKey.Description;

        UserGroupsNotification.Id := NotificationIdLbl;

        if FeatureSwitchEnabled then begin
            if UserGroup.IsEmpty() then
                UserGroupsNotification.Message(StrSubstNo(FeatureSwitchEnabledNoUserGroupsNotificationTxt, FeatureSwitchName))
            else
                UserGroupsNotification.Message(StrSubstNo(FeatureSwitchEnabledUserGroupsPresentNotificationTxt, FeatureSwitchName));
        end else
            if UserGroup.IsEmpty() then
                UserGroupsNotification.Message(StrSubstNo(FeatureSwitchDisabledNoUserGroupsNotificationTxt, FeatureSwitchName))
            else
                UserGroupsNotification.Message(StrSubstNo(FeatureSwitchDisabledUserGroupsPresentNotificationTxt, FeatureSwitchName));

        UserGroupsNotification.AddAction(OpenFeatureManagementTok, Codeunit::"Legacy User Groups", 'OpenFeatureManagementNotification');
        UserGroupsNotification.Scope := NotificationScope::LocalScope;
        UserGroupsNotification.Send();
    end;

    internal procedure OpenFeatureManagementNotification(Notification: Notification)
    begin
        OpenFeatureManagement();
    end;

    internal procedure OpenFeatureManagementError(var Error: ErrorInfo)
    begin
        OpenFeatureManagement();
    end;

    local procedure OpenFeatureManagement()
    var
        FeatureKey: Record "Feature Key";
        FeatureManagement: Page "Feature Management";
    begin
        FeatureKey.SetRange(ID, UserGroupFeatureKeyTxt);
        FeatureManagement.SetTableView(FeatureKey);
        FeatureManagement.Run();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Feature Key", 'OnBeforeModifyEvent', '', false, false)]
    local procedure RunTransitionWizardBeforeHidingUserGroups(var Rec: Record "Feature Key"; var xRec: Record "Feature Key")
    var
        UserGroup: Record "User Group";
    begin
        if Rec.ID <> UserGroupFeatureKeyTxt then
            exit;

        if not ((xRec.Enabled = xRec.Enabled::None) and (Rec.Enabled = Rec.Enabled::"All Users")) then
            exit; // the admin is not trying to disable user groups

        if UserGroup.IsEmpty() then
            exit;

        if GuiAllowed() then begin
            if not Confirm(ConfirmConvertUserGroupsQst) then
                Error(CannotEnableTheFeatureErr);

            Commit();
            Page.RunModal(Page::"User Groups Migration Guide");
        end;

        if not UserGroup.IsEmpty() then
            Error(CannotEnableTheFeatureErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"User Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure CheckFeatureSwitchOnBeforeUserGroupInsert(var Rec: Record "User Group")
    begin
        CheckUserGroupInsertAllowed();
    end;

    internal procedure CheckUserGroupInsertAllowed()
    var
        FeatureKey: Record "Feature Key";
        CannotAddUserGroupErrorInfo: ErrorInfo;
    begin
        if FeatureKey.Get(UserGroupFeatureKeyTxt) and (FeatureKey.Enabled = FeatureKey.Enabled::"All Users") then begin
            CannotAddUserGroupErrorInfo.Message := StrSubstNo(CannotAddUserGroupsErr, FeatureKey.Description);
            CannotAddUserGroupErrorInfo.DataClassification := DataClassification::SystemMetadata;
            CannotAddUserGroupErrorInfo.Verbosity := Verbosity::Error;
            CannotAddUserGroupErrorInfo.ErrorType := ErrorType::Client;
            CannotAddUserGroupErrorInfo.Title := CannotAddUserGroupsTitleErr;
            CannotAddUserGroupErrorInfo.AddAction(OpenFeatureManagementTok, Codeunit::"Legacy User Groups", 'OpenFeatureManagementError');
            Error(CannotAddUserGroupErrorInfo);
        end
    end;
}
#endif