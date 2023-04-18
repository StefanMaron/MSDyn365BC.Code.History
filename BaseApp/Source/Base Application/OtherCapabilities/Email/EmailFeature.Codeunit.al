// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
/// <summary>
/// Provides functionality to determine whether the email enhancements have been enabled.
/// </summary>
codeunit 8895 "Email Feature"
{
#if not CLEAN20
    Access = Public;
    ObsoleteState = Pending;
    ObsoleteReason = 'No longer relevant as the email enhancements are always enabled.';
    ObsoleteTag = '20.0';

    /// <summary>
    /// Checks if the feature has been enabled for all users. 
    /// </summary>
    // <returns>True</returns>
    [Obsolete('The email enhancements are permenantly enabled.', '20.0')]
    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;
#else
    Access = Internal;
#endif

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    local procedure AddEmailAccountsToServiceConnections(var ServiceConnection: Record "Service Connection")
    var
        EmailAccounts: Record "Email Account";
        EmailAccount: Codeunit "Email Account";
        EmailAccountsPage: Page "Email Accounts";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(EmailAccounts); // So that it's not empty RecordId

        ServiceConnection.Status := ServiceConnection.Status::Enabled;
        if not EmailAccount.IsAnyAccountRegistered() then
            ServiceConnection.Status := ServiceConnection.Status::Disabled;

        ServiceConnection.InsertServiceConnection(
            ServiceConnection, RecRef.RecordId, EmailAccountsPage.Caption(), '', Page::"Email Accounts");
    end;

#if not CLEAN20
    [Obsolete('Warning is never shown as the email enhancement is permenantly enabled.', '20.0')]
    procedure ShowWarningNotification()
    begin
        exit; // The email feature is enabled, no need to show anything.
    end;
#endif

}