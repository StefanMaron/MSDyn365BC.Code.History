// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
/// <summary>
/// Provides functionality to determine whether the email enhancements have been enabled.
/// </summary>
codeunit 8895 "Email Feature"
{
    Access = Public;

    // >>> Disable email feature
    [EventSubscriber(ObjectType::Page, Page::"Email Accounts", 'OnOpenPageEvent', '', false, false)]
    local procedure DisableEmailAccounts()
    begin
        EmailFeatureDisabled();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Email Account Wizard", 'OnOpenPageEvent', '', false, false)]
    local procedure DisableEmailAccountWizard()
    begin
        EmailFeatureDisabled();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Email Editor", 'OnOpenPageEvent', '', false, false)]
    local procedure DisableEmailEditor()
    begin
        EmailFeatureDisabled();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Email Outbox", 'OnOpenPageEvent', '', false, false)]
    local procedure DisableEmailOutbox()
    begin
        EmailFeatureDisabled();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sent Emails", 'OnOpenPageEvent', '', false, false)]
    local procedure DisableSentEmails()
    begin
        EmailFeatureDisabled();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Email Scenario Setup", 'OnOpenPageEvent', '', false, false)]
    local procedure DisableEmailScenarios()
    begin
        EmailFeatureDisabled();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Feature Management", 'OnBeforeValidateEvent', 'EnabledFor', false, false)]
    local procedure DisableEmailFeature(var Rec: Record "Feature Key");
    begin
        if (Rec.ID = EmailFeatureKeyTxt) and (Rec.Enabled = Rec.Enabled::"All Users") then begin
            Message(FeatureCommingSoonMsg);
            Error('');
        end;
    end;

    local procedure EmailFeatureDisabled()
    begin
        Message(CommingSoonMsg);
        Error('');
    end;

    var
        CommingSoonMsg: Label 'Coming soon. This page is part of the enhanced email capabilities we''re working on. For now, you must use SMTP to send email messages.';
        FeatureCommingSoonMsg: Label 'Coming soon. We''re working on the enhanced email capabilities. For now, you must use SMTP to send email messages.';
    // <<< end

    var
        EmailFeatureKeyTxt: Label 'EmailHandlingImprovements', Locked = true;

    /// <summary>
    /// Checks if the feature has been enabled for all users. 
    /// </summary>
    // <returns>True if the feature has been enabled; otherwise - false.</returns>
    procedure IsEnabled(): Boolean
    var
        FeatureKey: Record "Feature Key";
    begin
        if FeatureKey.Get(EmailFeatureKeyTxt) then
            exit(FeatureKey.Enabled = FeatureKey.Enabled::"All Users");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    local procedure AddEmailAccountsToServiceConnections(var ServiceConnection: Record "Service Connection")
    var
        EmailAccounts: Record "Email Account";
        EmailAccount: Codeunit "Email Account";
        EmailAccountsPage: Page "Email Accounts";
        RecRef: RecordRef;
    begin
        if not IsEnabled() then
            exit;

        RecRef.GetTable(EmailAccounts); // So that it's not empty RecordId

        ServiceConnection.Status := ServiceConnection.Status::Enabled;
        if not EmailAccount.IsAnyAccountRegistered() then
            ServiceConnection.Status := ServiceConnection.Status::Disabled;

        ServiceConnection.InsertServiceConnection(
            ServiceConnection, RecRef.RecordId, EmailAccountsPage.Caption(), '', Page::"Email Accounts");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Email Accounts", 'OnOpenPageEvent', '', false, false)]
    local procedure ShowWarningOnOpenEmailAccounts()
    begin
        ShowWarning();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Email Account Wizard", 'OnOpenPageEvent', '', false, false)]
    local procedure ShowWarningOnOpenEmailAccountWizard()
    begin
        ShowWarning();
    end;

    local procedure ShowWarning()
    var
        FeatureKey: Record "Feature Key";
        FeatureManagement: Page "Feature Management";
        Notification: Notification;
    begin
        if IsEnabled() then
            exit; // The email feature is enabled, no need to show anything.

        Notification.Id := GetWarningNotificationId();
        Notification.Message := StrSubstNo(EmailFeatureNotEnabledTxt, FeatureManagement.Caption());

        if FeatureKey.WritePermission() then
            Notification.AddAction(StrSubstNo(OpenPageTxt, FeatureManagement.Caption()), Codeunit::"Email Feature", 'OpenFeatureManagement');

        Notification.Scope := NotificationScope::LocalScope;
        Notification.Send();
    end;

    internal procedure OpenFeatureManagement(Notification: Notification)
    var
        FeatureKey: Record "Feature Key";
    begin
        if FeatureKey.Get(EmailFeatureKeyTxt) then;
        Page.Run(Page::"Feature Management", FeatureKey);
    end;

    local procedure GetWarningNotificationId(): Guid
    begin
        exit('5e4c111a-30fa-4adf-9abb-87eb10754728');
    end;

    var
        OpenPageTxt: Label 'Open %1 page', Comment = '%1 = page caption';
        EmailFeatureNotEnabledTxt: Label 'Welcome to the updated email capabilities in Business Central. Before you can get started, your administrator must go to the %1 page and turn on the new capabilities. Until then, the accounts you add will not be used for scenarios such as sending documents, notifications, and inviting external accountants.', Comment = '%1 = page caption';
}