codeunit 9275 "My Settings"
{
    procedure SetExperienceToEssential(SelectedProfileID: Text[30])
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        if CompanyInformationMgt.IsDemoCompany() then
            if ExperienceTierSetup.Get(CompanyName) then
                if ExperienceTierSetup.Basic then
                    if (SelectedProfileID = TeamMemberTxt) or
                       (SelectedProfileID = AccountantTxt) or
                       (SelectedProfileID = ProjectManagerTxt)
                    then begin
                        Message(ExperienceMsg);
                        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
                    end;
    end;

#if not CLEAN19
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Settings", 'OnUserRoleCenterChange', '', false, false)]
    local procedure OnUserRoleCenterChange(NewAllProfile: Record "All Profile")
    var
        MySettings: Page "My Settings";
    begin
        MySettings.OnUserRoleCenterChange(NewAllProfile);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Settings", 'OnBeforeWorkdateChange', '', false, false)]
    local procedure OnBeforeWorkdateChange(OldWorkdate: Date; NewWorkdate: Date)
    var
        MySettings: Page "My Settings";
    begin
        MySettings.OnBeforeWorkdateChange(OldWorkdate, NewWorkdate);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Settings", 'OnBeforeLanguageChange', '', false, false)]
    local procedure OnBeforeLanguageChange(OldLanguageId: Integer; NewLanguageId: Integer)
    var
        MySettings: Page "My Settings";
    begin
        MySettings.OnBeforeLanguageChange(OldLanguageId, NewLanguageId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Settings", 'OnAfterQueryClosePage', '', false, false)]
    local procedure OnAfterQueryClosePage(NewLanguageID: Integer; NewLocaleID: Integer; NewTimeZoneID: Text[180]; NewCompany: Text; NewAllProfile: Record "All Profile")
    var
        MySettings: Page "My Settings";
    begin
        MySettings.OnAfterQueryClosePage(NewLanguageID, NewLocaleID, NewTimeZoneID, NewCompany, NewAllProfile);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Settings", 'OnBeforeOpenSettings', '', false, false)]
    local procedure OnBeforeOpenSettings(var Handled: Boolean)
    var
        UserSettings: Codeunit "User Settings";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        SettingsPageID: Integer;
    begin
        SettingsPageID := UserSettings.GetPageId();
        ConfPersonalizationMgt.OnBeforeOpenSettings(SettingsPageID, Handled);
    end;
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Settings", 'OnUpdateUserSettings', '', false, false)]
    local procedure OnUpdateUserSettings(OldSettings: Record "User Settings"; NewSettings: Record "User Settings")
    begin
        if OldSettings."Profile ID" <> NewSettings."Profile ID" then
            SetExperienceToEssential(NewSettings."Profile ID");
    end;

#if not CLEAN19
    internal procedure CheckPermissions(var UserPersonalization: Record "User Personalization")
    var
        AzureADUserManagement: Codeunit "Azure AD User Management";
    begin
        if (UserPersonalization.Count() > 1) or (UserPersonalization."User SID" <> UserSecurityId()) then
            if not AzureADUserManagement.IsUserTenantAdmin() then
                Error(NotEnoughPermissionsErr);
    end;

    internal procedure EditUserID(var UserPersonalization: Record "User Personalization"): Boolean
    var
        UserPersonalization2: Record "User Personalization";
        User: Record User;
        UserSelection: Codeunit "User Selection";
        UserAlreadyExistErr: Label '%1 %2 already exists.', Comment = '%1 = UserPersonalization TableCaption; %2 = UserID.';
    begin
        if not UserSelection.Open(User) then
            exit(false);

        if IsNullGuid(User."User Security ID") then
            exit(false);

        if User."User Security ID" <> UserPersonalization."User SID" then begin
            if UserPersonalization2.Get(User."User Security ID") then begin
                UserPersonalization2.CalcFields("User ID");
                Error(UserAlreadyExistErr, UserPersonalization.TableCaption, UserPersonalization2."User ID");
            end;

            UserPersonalization.Validate("User SID", User."User Security ID");
            UserPersonalization.CalcFields("User ID");
            UserPersonalization.CalcFields("Full Name");
            exit(true);
        end;
        exit(false);
    end;

    internal procedure EditProfileID(var UserPersonalization: Record "User Personalization")
    var
        AllProfileTable: Record "All Profile";
    begin
        if Page.RunModal(Page::"Available Roles", AllProfileTable) = Action::LookupOK then begin
            UserPersonalization."Profile ID" := AllProfileTable."Profile ID";
            UserPersonalization."App ID" := AllProfileTable."App ID";
            UserPersonalization.Scope := AllProfileTable.Scope;
            SetRestartRequiredIfChangeIsForCurrentUser(UserPersonalization);
            UserPersonalization.CalcFields("Role");
        end;
    end;

    internal procedure EditLanguage(var UserPersonalization: Record "User Personalization")
    var
        Language: Codeunit Language;
        OldLanguageID: Integer;
    begin
        OldLanguageID := UserPersonalization."Language ID";
        Language.LookupApplicationLanguageId(UserPersonalization."Language ID");

        if UserPersonalization."Language ID" <> OldLanguageID then begin
            UserPersonalization.Validate("Language ID", UserPersonalization."Language ID");
            SetRestartRequiredIfChangeIsForCurrentUser(UserPersonalization);
            UserPersonalization.CalcFields("Language Name");
        end;
    end;

    internal procedure EditRegion(var UserPersonalization: Record "User Personalization")
    var
        Language: Codeunit Language;
        OldLocaleID: Integer;
    begin
        OldLocaleID := UserPersonalization."Locale ID";
        Language.LookupWindowsLanguageId(UserPersonalization."Locale ID");

        if UserPersonalization."Locale ID" <> OldLocaleID then begin
            UserPersonalization.Validate("Locale ID", UserPersonalization."Locale ID");
            SetRestartRequiredIfChangeIsForCurrentUser(UserPersonalization);
            UserPersonalization.CalcFields(Region);
        end;
    end;

    internal procedure ValidateLanguageID(UserPersonalization: Record "User Personalization")
    var
        Language: Codeunit Language;
    begin
        Language.ValidateApplicationLanguageId(UserPersonalization."Language ID");
        SetRestartRequiredIfChangeIsForCurrentUser(UserPersonalization);
    end;

    internal procedure ValidateRegionID(UserPersonalization: Record "User Personalization")
    var
        Language: Codeunit Language;
    begin
        Language.ValidateWindowsLanguageId(UserPersonalization."Locale ID");
        SetRestartRequiredIfChangeIsForCurrentUser(UserPersonalization);
    end;

    internal procedure ValidateTimeZone(var UserPersonalization: Record "User Personalization")
    var
        TimeZoneSelection: Codeunit "Time Zone Selection";
    begin
        TimeZoneSelection.ValidateTimeZone(UserPersonalization."Time Zone");
        SetRestartRequiredIfChangeIsForCurrentUser(UserPersonalization);
    end;

    internal procedure HideExternalUsers(var UserPersonalization: Record "User Personalization")
    var
        EnvironmentInfo: Codeunit "Environment Information";
        OriginalFilterGroup: Integer;
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;

        OriginalFilterGroup := UserPersonalization.FilterGroup();
        UserPersonalization.FilterGroup := 2;
        UserPersonalization.CalcFields("License Type");
        UserPersonalization.SetFilter("License Type", '<>%1', UserPersonalization."License Type"::"External User");
        UserPersonalization.FilterGroup := OriginalFilterGroup;
    end;

    internal procedure SetRestartRequiredIfChangeIsForCurrentUser(UserPersonalization: Record "User Personalization")
    begin
        if ((UserSecurityId() = UserPersonalization."User SID") or IsNullGuid(UserPersonalization."User SID")) and (CompanyName = UserPersonalization.Company) then
            RequiresRestart := true;
    end;

    internal procedure IsRestartRequiredIfChangeIsForCurrentUser(): Boolean
    begin
        exit(RequiresRestart);
    end;

    internal procedure RestartSession()
    var
        UserPersonalization: Record "User Personalization";
        CurrentUserSessionSettings: SessionSettings;
        ProfileScope: Option System,Tenant;
    begin
        UserPersonalization.Get(UserSecurityId());

        CurrentUserSessionSettings.Init();
        CurrentUserSessionSettings.ProfileId := UserPersonalization."Profile ID";
        CurrentUserSessionSettings.ProfileAppId := UserPersonalization."App ID";
        CurrentUserSessionSettings.ProfileSystemScope := UserPersonalization.Scope = ProfileScope::System;
        CurrentUserSessionSettings.LanguageId := UserPersonalization."Language ID";
        CurrentUserSessionSettings.LocaleId := UserPersonalization."Locale ID";
        CurrentUserSessionSettings.Timezone := UserPersonalization."Time Zone";

        CurrentUserSessionSettings.RequestSessionUpdate(true);
    end;
#endif

    var
        RequiresRestart: Boolean;
        AccountantTxt: Label 'ACCOUNTANT', Comment = 'Please translate all caps';
        ProjectManagerTxt: Label 'PROJECT MANAGER', Comment = 'Please translate all caps';
        TeamMemberTxt: Label 'TEAM MEMBER', Comment = 'Please translate all caps';
        ExperienceMsg: Label 'You are changing to a Role Center that has more functionality. To display the full functionality for this role, your Experience setting will be set to Essential.';
#if not CLEAN19
        NotEnoughPermissionsErr: Label 'You cannot access settings for other users.';
#endif
}