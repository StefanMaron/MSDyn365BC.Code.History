codeunit 9170 "Conf./Personalization Mgt."
{
    var
        BusinessManagerProfileIDTxt: Label 'BUSINESS MANAGER', Locked = true;
        DeleteConfigurationChangesQst: Label 'This will delete all user-made customization changes for this profile. It will not clear the customizations coming from your extensions.\\Do you want to continue?';
        DeletePersonalizationChangesQst: Label 'This will delete all personalization changes made by this user.  Do you want to continue?';
        NoDisableProfileErr: Label 'You cannot disable the profile that is used as default.';
        CannotDeleteDefaultProfileErr: Label 'You cannot delete the profile that is used as default.';
        CannotDeleteDefaultUserProfileErr: Label 'You cannot delete this profile because it is set up as a default profile for one or more users or user groups.';
        CannotDisableDefaultUserProfileErr: Label 'You cannot disable this profile because it is set up as a default profile for one or more users or user groups.';
        AllProfileCustomizationsDeletedSuccessfullyMsg: Label 'All customizations for profile "%1" have been deleted successfully.', Comment = '%1 = profile caption';
        ThereAreProfilesWithDuplicateIdMsg: Label 'Another profile has the same ID as this one. This can cause ambiguity in the system. Give this or the other profile another ID before you customize them. Contact your Microsoft partner for further assistance.';
        NoCurrentProfileErr: Label 'Could not find a profile for the current user.';
        FileDoesNotExistErr: Label 'The file %1 does not exist.', Comment = '%1 File Path';
        UrlConfigureParameterTxt: Label 'customize', Locked = true;
        UrlProfileParameterTxt: Label 'profile', Locked = true;
        CouldNotExportProfilesErr: Label 'Cannot export the profiles because one or more of them contain an error.';
        ExportProfilesWithWarningsQst: Label 'There is an error in one or more of the profiles that you are exporting. You can export the profiles anyway, but you should fix the errors before you import them. Typically, import fails for profiles with errors.';
        CouldNotCopyProfileErr: Label 'The profile could not be copied.';
        ConfigurationPersonalizationCategoryTxt: Label 'AL Conf/Pers', Locked = true;
        DefaultRoleCenterIdentifiedTxt: Label 'Returning role center %1 as default.', Locked = true;

    procedure DefaultRoleCenterID(): Integer
    var
        EnvironmentInfo: Codeunit "Environment Information";
        RoleCenterID: Integer;
        AzureADPlan: Codeunit "Azure AD Plan";
    begin
        if EnvironmentInfo.IsSaaS then
            if AzureADPlan.TryGetAzureUserPlanRoleCenterId(RoleCenterID, UserSecurityId) then;

        if RoleCenterID = 0 then
            RoleCenterID := PAGE::"Business Manager Role Center"; // BUSINESS MANAGER

        OnAfterGetDefaultRoleCenter(RoleCenterID);
        Session.LogMessage('0000DUJ', StrSubstNo(DefaultRoleCenterIdentifiedTxt, RoleCenterID), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', ConfigurationPersonalizationCategoryTxt);

        exit(RoleCenterID);
    end;

    procedure GetCurrentProfile(var AllProfile: Record "All Profile")
    begin
        if GetCurrentProfileNoError(AllProfile) then
            if not AllProfile.IsEmpty() then
                if AllProfile."Profile ID" <> '' then
                    exit;

        Error(NoCurrentProfileErr);
    end;

    procedure GetCurrentProfileNoError(var AllProfile: Record "All Profile"): Boolean
    var
        UserPersonalization: Record "User Personalization";
    begin
        // Try to find the current profile, otherwise it means we are using the default one for this user (coming from Azure or from demodata)
        if UserPersonalization.Get(UserSecurityId) then
            if UserPersonalization."Profile ID" <> '' then
                exit(AllProfile.Get(UserPersonalization.Scope, UserPersonalization."App ID", UserPersonalization."Profile ID"));

        exit(TryGetDefaultProfileForCurrentUser(AllProfile));
    end;

    [TryFunction]
    procedure TryGetDefaultProfileForCurrentUser(var AllProfile: Record "All Profile")
    var
        PermissionManager: Codeunit "Permission Manager";
    begin
        PermissionManager.GetDefaultProfileID(UserSecurityId(), AllProfile);
    end;

    procedure IsCurrentProfile(Scope: Option; AppID: Guid; ProfileID: Code[30]): Boolean
    var
        AllProfile: Record "All Profile";
    begin
        if not GetCurrentProfileNoError(AllProfile) then
            exit(false);

        exit((AllProfile.Scope = Scope) and (AllProfile."App ID" = AppID) and (AllProfile."Profile ID" = ProfileID));
    end;

    procedure SetCurrentProfile(AllProfile: Record "All Profile")
    var
        UserPersonalization: Record "User Personalization";
        PrevAllProfile: Record "All Profile";
    begin
        if UserPersonalization.Get(UserSecurityId) then begin
            if PrevAllProfile.Get(UserPersonalization.Scope, UserPersonalization."App ID", UserPersonalization."Profile ID") then;
            UserPersonalization."Profile ID" := AllProfile."Profile ID";
            UserPersonalization.Scope := AllProfile.Scope;
            UserPersonalization."App ID" := AllProfile."App ID";
            UserPersonalization.Modify(true);
        end else begin
            UserPersonalization.Init();
            UserPersonalization."User SID" := UserSecurityId;
            UserPersonalization."Profile ID" := AllProfile."Profile ID";
            UserPersonalization.Scope := AllProfile.Scope;
            UserPersonalization."App ID" := AllProfile."App ID";
            UserPersonalization.Insert(true);
        end;

        OnProfileChanged(PrevAllProfile, AllProfile);
    end;

    procedure CopyProfileWithUserInput(SourceAllProfile: Record "All Profile"; var DestinationAllProfile: Record "All Profile")
    var
        CopyProfile: Page "Copy Profile";
    begin
        if not GuiAllowed() then
            Error('');

        CopyProfile.SetSourceAllProfile(SourceAllProfile);
        if CopyProfile.RunModal() in [Action::LookupOK, Action::OK] then
            CopyProfile.GetDestinationAllProfile(DestinationAllProfile);
    end;

    procedure CopyProfile(AllProfile: Record "All Profile"; NewProfileID: Code[30]; NewProfileCaption: Text[100]; var NewAllProfile: Record "All Profile")
    var
        NavDesignerALFunctions: DotNet NavDesignerALFunctions;
        NavDesignerALCopyResponse: DotNet NavDesignerALCopyResponse;
        CopyFailedErrorInfo: ErrorInfo;
        EmptyGuid: Guid;
    begin
        NavDesignerALCopyResponse := NavDesignerALFunctions.CopyProfile(AllProfile."Profile ID", AllProfile."App ID", NewProfileID, NewProfileCaption);
        if not NavDesignerALCopyResponse.Success then
            Error(CouldNotCopyProfileErr);

        if not NewAllProfile.Get(NewAllProfile.Scope::Tenant, EmptyGuid, NewProfileID) then begin // This call should never fail
            CopyFailedErrorInfo.DataClassification := DataClassification::SystemMetadata;
            CopyFailedErrorInfo.ErrorType := ErrorType::Internal;
            CopyFailedErrorInfo.Verbosity := Verbosity::Error;
            CopyFailedErrorInfo.Message := CouldNotCopyProfileErr;
            Error(CopyFailedErrorInfo);
        end;

        OnAfterCopyProfile(AllProfile, NewAllProfile);
    end;

#if not CLEAN19
    [Obsolete('Use function "GetAppName" from Codeunit "Extension Management".', '19.0')]
    procedure ResolveAppNameFromAppId(AppId: Guid) AppName: Text
    var
        ExtensionManagement: Codeunit "Extension Management";
    begin
        exit(ExtensionManagement.GetAppName(AppId));
    end;
#endif

    procedure ClearProfileConfiguration(AllProfile: Record "All Profile")
    var
        TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
    begin
        if not Confirm(DeleteConfigurationChangesQst) then
            exit;

        TenantProfilePageMetadata.SetRange("Profile ID", AllProfile."Profile ID");
        TenantProfilePageMetadata.SetRange("App ID", AllProfile."App ID");
        TenantProfilePageMetadata.SetRange(Owner, TenantProfilePageMetadata.Owner::Tenant);
        TenantProfilePageMetadata.DeleteAll(true);

        Message(AllProfileCustomizationsDeletedSuccessfullyMsg, AllProfile.Caption);
    end;

    procedure ClearUserPersonalization(User: Record "User Personalization")
    var
        UserMetadata: Record "User Metadata";
        UserPageMetadata: Record "User Page Metadata";
    begin
        if not Confirm(DeletePersonalizationChangesQst) then
            exit;

        UserMetadata.SetRange("User SID", User."User SID");
        UserMetadata.DeleteAll(true);

        UserPageMetadata.SetRange("User SID", User."User SID");
        UserPageMetadata.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure ChangeDefaultRoleCenter(AllProfile: Record "All Profile")
    begin
        SetOtherProfilesAsNonDefault(AllProfile);
    end;

    procedure ValidateDeleteProfile(AllProfile: Record "All Profile")
    var
        UserPersonalization: Record "User Personalization";
        UserGroup: Record "User Group";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateDeleteProfile(AllProfile, IsHandled);
        if IsHandled then
            exit;

        if AllProfile."Default Role Center" then
            Error(CannotDeleteDefaultProfileErr);

        UserPersonalization.SetRange("Profile ID", AllProfile."Profile ID");
        UserPersonalization.SetRange("App ID", AllProfile."App ID");
        UserPersonalization.SetRange(Scope, AllProfile.Scope);

        if not UserPersonalization.IsEmpty() then
            Error(CannotDeleteDefaultUserProfileErr);

        UserGroup.SetRange("Default Profile ID", AllProfile."Profile ID");
        UserGroup.SetRange("Default Profile App ID", AllProfile."App ID");
        UserGroup.SetRange("Default Profile Scope", AllProfile.Scope);

        if not UserGroup.IsEmpty() then
            Error(CannotDeleteDefaultUserProfileErr);
    end;

    procedure ValidateDisableProfile(AllProfile: Record "All Profile")
    var
        UserPersonalization: Record "User Personalization";
        UserGroup: Record "User Group";
    begin
        if AllProfile."Default Role Center" then
            Error(NoDisableProfileErr);

        UserPersonalization.SetRange("Profile ID", AllProfile."Profile ID");
        UserPersonalization.SetRange("App ID", AllProfile."App ID");
        UserPersonalization.SetRange(Scope, AllProfile.Scope);

        if not UserPersonalization.IsEmpty() then
            Error(CannotDisableDefaultUserProfileErr);

        UserGroup.SetRange("Default Profile ID", AllProfile."Profile ID");
        UserGroup.SetRange("Default Profile App ID", AllProfile."App ID");
        UserGroup.SetRange("Default Profile Scope", AllProfile.Scope);

        if not UserGroup.IsEmpty() then
            Error(CannotDisableDefaultUserProfileErr);
    end;

    procedure FilterToInstalledLanguages(var WindowsLanguage: Record "Windows Language")
    begin
        // Filter is the same used by the Select Language dialog in the Windows client
        WindowsLanguage.SetRange("Globally Enabled", true);
        WindowsLanguage.SetRange("Localization Exist", true);
        WindowsLanguage.SetFilter("Language ID", '<> %1', 1034);
        WindowsLanguage.FindSet();
    end;

#if not CLEAN19
#pragma warning disable AA0139
    [Obsolete('Please use the method "ValidateTimeZone" from codeunit "Time Zone Selection".', '19.0')]
    procedure ValidateTimeZone(var TimeZoneText: Text)
    var
        TimeZoneSelection: Codeunit "Time Zone Selection";
    begin
        TimeZoneSelection.ValidateTimeZone(TimeZoneText);
    end;

    [Obsolete('Please use the method "LookupTimeZone" from codeunit "Time Zone Selection".', '19.0')]
    procedure LookupTimeZone(var TimeZoneText: Text): Boolean
    var
        TimeZoneSelection: Codeunit "Time Zone Selection";
    begin
        exit(TimeZoneSelection.LookupTimeZone(TimeZoneText));
    end;
#pragma warning restore
#endif

    procedure DownloadProfileConfigurationPackage()
    var
        FileManagement: Codeunit "File Management";
        Designer: DotNet NavDesignerALFunctions;
        NavDesignerALProfileExportResponse: DotNet NavDesignerALProfileExportResponse;
        profileConfigurationOutStream: OutStream;
        TempFile: File;
        ServerTempFileName: Text;
    begin
        ServerTempFileName := FileManagement.ServerTempFileName('profiles');
        TempFile.Create(ServerTempFileName);
        TempFile.CreateOutStream(profileConfigurationOutStream);

        NavDesignerALProfileExportResponse := Designer.GenerateProfileConfigurationPackageZip(profileConfigurationOutStream);
        if not NavDesignerALProfileExportResponse.Success then begin
            if not NavDesignerALProfileExportResponse.ProposeForceExport then
                Error(CouldNotExportProfilesErr);

            if not Confirm(ExportProfilesWithWarningsQst) then
                exit;

            NavDesignerALProfileExportResponse := Designer.ForceGenerateProfileConfigurationPackageZip(profileConfigurationOutStream);
            if not NavDesignerALProfileExportResponse.Success then
                Error(CouldNotExportProfilesErr);
        end;

        FileManagement.DownloadHandler(ServerTempFileName, '', '', '', 'profiles.zip');
        FileManagement.DeleteServerFile(ServerTempFileName);
    end;

    [Obsolete('Use new NavDesignerALFunctions.CopyProfile functionality to copy profiles which also handles copying page metadata.', '18.0')]
    procedure CopyProfilePageMetadata(OldAllProfile: Record "All Profile"; NewAllProfile: Record "All Profile")
    var
        TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
        NewTenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
    begin
        if (OldAllProfile.Scope = OldAllProfile.Scope::Tenant) and
           (NewAllProfile.Scope = NewAllProfile.Scope::Tenant)
        then begin
            TenantProfilePageMetadata.SetRange("Profile ID", OldAllProfile."Profile ID");
            TenantProfilePageMetadata.SetRange("App ID", OldAllProfile."App ID");
            if TenantProfilePageMetadata.FindSet() then
                repeat
                    TenantProfilePageMetadata.CalcFields("Page Metadata", "Page AL");

                    NewTenantProfilePageMetadata.Init();
                    NewTenantProfilePageMetadata.Copy(TenantProfilePageMetadata);
                    NewTenantProfilePageMetadata."Profile ID" := NewAllProfile."Profile ID";
                    NewTenantProfilePageMetadata.Owner := NewTenantProfilePageMetadata.Owner::Tenant;
                    NewTenantProfilePageMetadata."App ID" := NewAllProfile."App ID";
                    NewTenantProfilePageMetadata.Insert();
                until TenantProfilePageMetadata.Next() = 0;
        end;
    end;

#if not CLEAN19
    [Obsolete('Use function "GetPageId" from codeunit "User Settings" instead.', '19.0')]
    procedure GetSettingsPageID(): Integer
    var
        UserSettings: Codeunit "User Settings";
    begin
        exit(UserSettings.GetPageId());
    end;
#endif

    procedure RaiseOnOpenRoleCenterEvent()
    begin
        OnRoleCenterOpen;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Default Role Center", 'OnBeforeGetDefaultRoleCenter', '', false, false)]
    local procedure SetDefaultRoleCenterId(var RoleCenterId: Integer; var Handled: Boolean)
    begin
        RoleCenterId := DefaultRoleCenterID;
    end;

#if not CLEAN19
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Settings", 'OnBeforeOpenSettings', '', false, false)]
    local procedure OpenSettings(var Handled: Boolean)
    var
        SettingsPageID: Integer;
    begin
        SettingsPageID := GetSettingsPageID();
        OnBeforeOpenSettings(SettingsPageID, Handled);
    end;
#endif

    [Scope('OnPrem')]
    procedure SetOtherProfilesAsNonDefault(NewDefaultAllProfile: Record "All Profile")
    var
        OtherAllProfile: Record "All Profile";
    begin
        OtherAllProfile.SetRange("Default Role Center", true);

        // Could use a filter on SystemId, but AllProfile is a virtual table and the current implementation does not allow that
        OtherAllProfile.FilterGroup(-1); // Cross-column filter
        OtherAllProfile.SetFilter("Profile ID", '<>%1', NewDefaultAllProfile."Profile ID");
        OtherAllProfile.SetFilter("App ID", '<>%1', NewDefaultAllProfile."App ID");
        OtherAllProfile.SetFilter(Scope, '<>%1', NewDefaultAllProfile.Scope);

        // Also, AllProfile does not support ModifyAll
        if OtherAllProfile.FindSet() then
            repeat
                OtherAllProfile."Default Role Center" := false;
                OtherAllProfile.Modify();
            until OtherAllProfile.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ChangePersonalizationForUserGroupMembers(UserGroupCode: Code[20]; OldProfileID: Code[30]; NewProfileID: Code[30])
    var
        UserGroupMember: Record "User Group Member";
        UserPersonalization: Record "User Personalization";
    begin
        UserGroupMember.SetRange("User Group Code", UserGroupCode);
        if UserGroupMember.FindSet() then begin
            repeat
                UserPersonalization.Get(UserGroupMember."User Security ID");
                if (UserPersonalization."Profile ID" = OldProfileID) and
                   (not UserHasOtherUserGroupsSupportingProfile(UserGroupMember."User Security ID", OldProfileID, UserGroupCode))
                then begin
                    UserPersonalization.Validate("Profile ID", NewProfileID);
                    UserPersonalization.Modify(true);
                end;
            until UserGroupMember.Next() = 0
        end;
    end;

    local procedure UserHasOtherUserGroupsSupportingProfile(UserSecurityID: Guid; ProfileID: Code[30]; UserGroupCode: Code[20]): Boolean
    var
        UserGroupMember: Record "User Group Member";
        UserGroup: Record "User Group";
    begin
        UserGroupMember.SetRange("User Security ID", UserSecurityID);
        UserGroupMember.SetFilter("User Group Code", '<>%1', UserGroupCode);
        if UserGroupMember.FindSet() then begin
            repeat
                if UserGroup.Get(UserGroupMember."User Group Code") and
                   (UserGroup."Default Profile ID" = ProfileID)
                then
                    exit(true);
            until UserGroupMember.Next() = 0;
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ExtractZipFile(ZipFilePath: Text; DestinationFolder: Text)
    var
        FileManagement: Codeunit "File Management";
        Zip: DotNet ZipFileExtensions;
        ZipFile: DotNet ZipFile;
        ServerFileHelper: DotNet File;
        ZipArchive: DotNet ZipArchive;
        ZipArchiveMode: DotNet ZipArchiveMode;
    begin
        FileManagement.IsAllowedPath(ZipFilePath, false);

        if not ServerFileHelper.Exists(ZipFilePath) then
            Error(FileDoesNotExistErr, ZipFilePath);

        // Create directory if it doesn't exist
        FileManagement.ServerCreateDirectory(DestinationFolder);

        ZipArchive := ZipFile.Open(ZipFilePath, ZipArchiveMode.Read);
        Zip.ExtractToDirectory(ZipArchive, DestinationFolder);
        if not IsNull(ZipArchive) then
            ZipArchive.Dispose;
    end;

    procedure GetProfileConfigurationUrlForWeb(AllProfile: Record "All Profile"): Text
    var
        UriBuilder: Codeunit "Uri Builder";
        Uri: Codeunit Uri;
    begin
        UriBuilder.Init(GetUrl(ClientType::Web));

        UriBuilder.AddQueryFlag(UrlConfigureParameterTxt);
        UriBuilder.AddQueryParameter(UrlProfileParameterTxt, AllProfile."Profile ID");

        UriBuilder.GetUri(Uri);
        exit(Uri.GetAbsoluteUri());
    end;

    procedure CanDeleteProfile(AllProfile: Record "All Profile"): Boolean
    begin
        exit(IsNullGuid(AllProfile."App ID"));
    end;

    procedure GetProfileUrlParameterForEvaluationCompany(): Text
    var
        DotNetUri: Codeunit DotNet_Uri;
    begin
        exit(StrSubstNo('%1=%2', UrlProfileParameterTxt, DotNetUri.EscapeDataString(BusinessManagerProfileIDTxt)));
    end;

    procedure OpenProfileCustomizationUrl(AllProfile: Record "All Profile")
    begin
        if IsProfileIdAmbiguous(AllProfile) then
            Error(ThereAreProfilesWithDuplicateIdMsg);

        Hyperlink(GetProfileConfigurationUrlForWeb(AllProfile));
    end;

    procedure IsProfileIdAmbiguous(AllProfile: Record "All Profile"): Boolean
    var
        OtherAllProfile: Record "All Profile";
        EmptyGuid: Guid;
    begin
        OtherAllProfile.SetRange("Profile ID", AllProfile."Profile ID");
        OtherAllProfile.SetFilter("App ID", '<>%1', AllProfile."App ID");

        // We have ambiguity if there are two profiles with the same ID.
        // Except if one of them is user-created, in which case that one has precedence and the ambiguity is resolved.
        if (OtherAllProfile.Count() > 0) and (AllProfile."App ID" <> EmptyGuid) then
            exit(true);

        exit(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tenant Profile Extension", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteProfileExtension(var Rec: Record "Tenant Profile Extension"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        GenerateCustomizationSymbolsAfterDelete(Rec."Base Profile ID", Rec."Base Profile App ID");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tenant Profile Page Metadata", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteTenantProfilePageMetadata(var Rec: Record "Tenant Profile Page Metadata"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        GenerateCustomizationSymbolsAfterDelete(Rec."Profile ID", Rec."App ID");
    end;

    [Scope('OnPrem')]
    local procedure GenerateCustomizationSymbolsAfterDelete(ProfileID: Text; ProfileAppID: GUID)
    var
        NavDesignerALFunctions: DotNet NavDesignerALFunctions;
    begin
        // This function catches exceptions inside it, so it should never error out
        NavDesignerALFunctions.RecompileProfileConfiguration(ProfileID, ProfileAppID)
    end;

    // Events

    [IntegrationEvent(false, false)]
    local procedure OnProfileChanged(PrevAllProfile: Record "All Profile"; CurrentAllProfile: Record "All Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyProfile(var AllProfile: Record "All Profile"; NewAllProfile: Record "All Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDefaultRoleCenter(var DefaultRoleCenterID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoleCenterOpen()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Settings", 'OnGetDefaultProfile', '', false, false)]
    local procedure OnGetDefaultProfile(var AllProfile: Record "All Profile")
    begin
        TryGetDefaultProfileForCurrentUser(AllProfile)
    end;

#if not CLEAN19
    [IntegrationEvent(false, false)]
    [Obsolete('Use the event OnBeforeOpenSettings from Codeunit User Settings instead.', '19.0')]
    procedure OnBeforeOpenSettings(var SettingsPageID: Integer; var Handled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDeleteProfile(AllProfile: Record "All Profile"; var IsHandled: Boolean)
    begin
    end;
}
