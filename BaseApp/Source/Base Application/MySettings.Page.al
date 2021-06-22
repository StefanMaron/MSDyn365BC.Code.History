page 9176 "My Settings"
{
    // Contains various system-wide settings which are personal to an individual user.
    // Styled as a StandardDialog which is ideal for presenting a single field. Once more fields are added,
    // this page should be converted to a Card page.

    AdditionalSearchTerms = 'company,role center,work date,role';
    ApplicationArea = All;
    Caption = 'My Settings';
    PageType = StandardDialog;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Control14)
            {
                ShowCaption = false;
                field(UserRoleCenter; GetProfileName)
                {
                    ApplicationArea = All;
                    AssistEdit = true;
                    Caption = 'Role';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the role that defines your home page with links to the most common tasks.';

                    trigger OnAssistEdit()
                    var
                        AllProfile: Record "All Profile";
                        RolecenterSelectorMgt: Codeunit "Rolecenter Selector Mgt.";
                        RoleCenterOverview: Page "Role Center Overview";
                        UserPersonalizationCard: Page "User Personalization Card";
                    begin
                        if RolecenterSelectorMgt.IsRolecenterSelectorEnabled(UserId) then begin
                            RoleCenterOverview.SetSelectedProfile(ProfileScope, ProfileAppID, ProfileID);
                            RoleCenterOverview.DelaySessionUpdateRequest;
                            if RoleCenterOverview.RunModal = ACTION::OK then
                                RoleCenterOverview.GetSelectedProfile(ProfileScope, ProfileAppID, ProfileID);
                        end else begin
                            if AllProfile.Get(ProfileScope, ProfileAppID, ProfileID) then;
                            if PAGE.RunModal(PAGE::"Available Roles", AllProfile) = ACTION::LookupOK then begin
                                ProfileID := AllProfile."Profile ID";
                                ProfileAppID := AllProfile."App ID";
                                ProfileScope := AllProfile.Scope;
                            end;
                        end;

                        OnUserRoleCenterChange(AllProfile);
                        UserPersonalizationCard.SetExperienceToEssential(ProfileID);
                    end;
                }
                field(Company; CompanyDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Company';
                    Editable = false;
                    ToolTip = 'Specifies the database company that you work in. You must sign out and then sign in again for the change to take effect.';

                    trigger OnAssistEdit()
                    var
                        SelectedCompany: Record Company;
                        AllowedCompanies: Page "Allowed Companies";
                        IsSetupInProgress: Boolean;
                    begin
                        AllowedCompanies.Initialize;

                        if SelectedCompany.Get(CompanyName) then
                            AllowedCompanies.SetRecord(SelectedCompany);

                        AllowedCompanies.LookupMode(true);

                        if AllowedCompanies.RunModal = ACTION::LookupOK then begin
                            AllowedCompanies.GetRecord(SelectedCompany);
                            OnCompanyChange(SelectedCompany.Name, IsSetupInProgress);
                            if IsSetupInProgress then begin
                                VarCompany := CompanyName;
                                Message(StrSubstNo(CompanySetUpInProgressMsg, SelectedCompany.Name, PRODUCTNAME.Short));
                            end else
                                VarCompany := SelectedCompany.Name;
                            SetCompanyDisplayName;
                        end;
                    end;
                }
                field(NewWorkdate; NewWorkdate)
                {
                    ApplicationArea = All;
                    Caption = 'Work Date';
                    ToolTip = 'Specifies the date that will be entered on transactions, typically today''s date. This change only affects the date on new transactions. Changes to this field will only be valid for the current session.';

                    trigger OnValidate()
                    begin
                        if NewWorkdate <> WorkDate then
                            OnBeforeWorkdateChange(WorkDate, NewWorkdate);

                        WorkDate := NewWorkdate;
                    end;
                }
                field(Locale2; GetLocale)
                {
                    ApplicationArea = All;
                    Caption = 'Region';
                    ToolTip = 'Specifies the regional settings, such as date and numeric format, on all devices. You must sign out and then sign in again for the change to take effect.';
                    Visible = RunningOnSaaS;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Use field Locale instead';
                    ObsoleteTag = '15.2';

                    trigger OnAssistEdit()
                    var
                        Language: Codeunit Language;
                    begin
                        Language.LookupWindowsLanguageId(LocaleID);
                    end;
                }
                field(Language2; GetLanguage)
                {
                    ApplicationArea = All;
                    Caption = 'Language';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the display language, on all devices. You must sign out and then sign in again for the change to take effect.';
                    Visible = RunningOnSaaS;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Use field Language instead';
                    ObsoleteTag = '15.2';

                    trigger OnAssistEdit()
                    var
                        Language: Codeunit Language;
                    begin
                        Language.LookupApplicationLanguageId(LanguageID);
                    end;
                }
                group("Region & Language")
                {
                    Caption = 'Region & Language';
                    Visible = not RunningOnSaaS;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Group will be removed. NB: Only group, not fields in group!';
                    ObsoleteTag = '15.2';

                    field(Locale; GetLocale)
                    {
                        ApplicationArea = All;
                        Caption = 'Region';
                        ToolTip = 'Specifies the regional settings, such as date and numeric format, on all devices. You must sign out and then sign in again for the change to take effect.';
                        Visible = not RunningOnSaaS;

                        trigger OnAssistEdit()
                        var
                            Language: Codeunit Language;
                        begin
                            Language.LookupWindowsLanguageId(LocaleID);
                        end;
                    }
                    field(Language; GetLanguage)
                    {
                        ApplicationArea = All;
                        Caption = 'Language';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the display language, on all devices. You must sign out and then sign in again for the change to take effect.';
                        Visible = not RunningOnSaaS;

                        trigger OnAssistEdit()
                        var
                            Language: Codeunit Language;
                        begin
                            Language.LookupApplicationLanguageId(LanguageID);
                        end;
                    }
                }
                field(TimeZone; GetTimeZone)
                {
                    ApplicationArea = All;
                    Caption = 'Time Zone';
                    ToolTip = 'Specifies the time zone that you work in. You must sign out and then sign in again for the change to take effect.';

                    trigger OnAssistEdit()
                    var
                        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
                    begin
                        ConfPersonalizationMgt.LookupTimeZone(TimeZoneID);
                    end;
                }
                field(RoleCenterOverviewEnabled; RoleCenterOverviewEnabled)
                {
                    ApplicationArea = All;
                    Caption = 'Enable Role Center Overview';
                    Visible = IsNotOnMobile AND ShowRoleCenterOverviewEnabledField;

                    trigger OnValidate()
                    var
                        RolecenterSelectorMgt: Codeunit "Rolecenter Selector Mgt.";
                    begin
                        RolecenterSelectorMgt.SetShowStateFromUserPreference(UserId, RoleCenterOverviewEnabled);
                    end;
                }
                field(MyNotificationsLbl; MyNotificationsLbl)
                {
                    ApplicationArea = All;
                    Caption = 'Notifications';
                    Editable = false;
                    ToolTip = 'Specifies the notifications that can be enabled by the user.';
                    Visible = IsNotOnMobile;

                    trigger OnDrillDown()
                    begin
                        PAGE.RunModal(PAGE::"My Notifications");
                    end;
                }
                field(LastLoginInfo; GetLastLoginInfo)
                {
                    ApplicationArea = All;
                    Caption = 'LastLoginInfo';
                    Editable = false;
                    ShowCaption = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        RunningOnSaaS := EnvironmentInfo.IsSaaS;
        IsNotOnMobile := ClientTypeManagement.GetCurrentClientType <> CLIENTTYPE::Phone;
        ShowRoleCenterOverviewEnabledField := false;
    end;

    trigger OnOpenPage()
    var
        UserPersonalization: Record "User Personalization";
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
        RolecenterSelectorMgt: Codeunit "Rolecenter Selector Mgt.";
    begin
        with UserPersonalization do begin
            Get(UserSecurityId);
            ProfileID := "Profile ID";
            ProfileAppID := "App ID";
            ProfileScope := Scope;
            LanguageID := "Language ID";
            LocaleID := "Locale ID";
            TimeZoneID := "Time Zone";
            if CompanyName <> Company then begin
                VarCompany := CompanyName;
                // Mark that the company is changed
                IsCompanyChanged := true
            end else
                VarCompany := Company;
            NewWorkdate := WorkDate;
            SetCompanyDisplayName;
        end;
        if RoleCenterNotificationMgt.IsEvaluationNotificationClicked then begin
            // change notification state from Clicked to Enabled in order to avoid appearing a new notification
            // on this page after decline of terms & conditions in the 30 days trial wizard
            RoleCenterNotificationMgt.EnableEvaluationNotification;
            Commit();
        end;
        RoleCenterOverviewEnabled := RolecenterSelectorMgt.GetShowStateFromUserPreference(UserId);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        AllProfile: Record "All Profile";
        TenantLicenseState: Codeunit "Tenant License State";
        UserPersonalization: Record "User Personalization";
        sessionSetting: SessionSettings;
        AnythingUpdated: Boolean;
        WasEvaluation: Boolean;
    begin
        if CloseAction <> ACTION::Cancel then begin
            with UserPersonalization do begin
                Get(UserSecurityId);

                if ("Language ID" <> LanguageID) or
                   ("Locale ID" <> LocaleID) or
                   ("Time Zone" <> TimeZoneID) or
                   (Company <> VarCompany) or IsCompanyChanged or
                   ("Profile ID" <> ProfileID) or
                   ("App ID" <> ProfileAppID) or
                   (Scope <> ProfileScope)
                then begin
                    AnythingUpdated := true;
                    sessionSetting.Init();

                    if Company <> VarCompany then begin
                        WasEvaluation := TenantLicenseState.IsEvaluationMode();
                        sessionSetting.Company := VarCompany;
                    end;

                    if ("Profile ID" <> ProfileID) or
                        ("App ID" <> ProfileAppID) or
                        (Scope <> ProfileScope)
                    then begin
                        sessionSetting.ProfileId := ProfileID;
                        sessionSetting.ProfileAppId := ProfileAppID;
                        sessionSetting.ProfileSystemScope := ProfileScope = ProfileScope::System;
                    end;

                    if "Language ID" <> LanguageID then begin
                        OnBeforeLanguageChange("Language ID", LanguageID);
                        sessionSetting.LanguageId := LanguageID;
                    end;

                    if "Locale ID" <> LocaleID then
                        sessionSetting.LocaleId := LocaleID;

                    if "Time Zone" <> TimeZoneID then
                        sessionSetting.Timezone := TimeZoneID;
                end;
            end;

            if WasEvaluation and TenantLicenseState.IsTrialMode() then
                Message(StrSubstNo(TrialStartMsg, PRODUCTNAME.Marketing));

            if AllProfile.Get(ProfileScope, ProfileAppID, ProfileID) then;
            OnAfterQueryClosePage(LanguageID, LocaleID, TimeZoneID, VarCompany, AllProfile);

            if AnythingUpdated then
                sessionSetting.RequestSessionUpdate(true);
        end;
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        LanguageID: Integer;
        LocaleID: Integer;
        TimeZoneID: Text[180];
        VarCompany: Text;
        NewWorkdate: Date;
        ProfileID: Code[30];
        RunningOnSaaS: Boolean;
        MyNotificationsLbl: Label 'Change when I receive notifications.';
        IsNotOnMobile: Boolean;
        CompanyDisplayName: Text[250];
        ProfileAppID: Guid;
        ProfileScope: Option System,Tenant;
        CompanySetUpInProgressMsg: Label 'Company %1 was just created, and we are still setting it up for you.\This may take up to 10 minutes, so take a short break before you begin to use %2.', Comment = '%1 - a company name,%2 - our product name';
        TrialStartMsg: Label 'We''re glad you''ve chosen to explore %1!\\Your session will restart to activate the new settings.', Comment = '%1 - our product name';
        IsCompanyChanged: Boolean;
        [InDataSet]
        RoleCenterOverviewEnabled: Boolean;
        ShowRoleCenterOverviewEnabledField: Boolean;
        MyLastLoginLbl: Label 'Your last sign in was on %1.', Comment = '%1 - a date time object';

    local procedure GetLanguage(): Text
    begin
        exit(GetWindowsLanguageNameFromID(LanguageID));
    end;

    local procedure GetWindowsLanguageNameFromID(ID: Integer): Text
    var
        Language: Codeunit Language;
    begin
        exit(Language.GetWindowsLanguageName(ID));
    end;

    local procedure GetLocale(): Text
    begin
        exit(GetWindowsLanguageNameFromID(LocaleID));
    end;

    local procedure GetTimeZone(): Text
    var
        TimeZone: Record "Time Zone";
    begin
        TimeZone.SetRange(ID, TimeZoneID);
        if TimeZone.FindFirst then
            exit(TimeZone."Display Name");
    end;

    local procedure GetProfileName() ProfileName: Text
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        // If current profile has been changed, then find it and update the description; else, get the default
        if not AllProfile.Get(ProfileScope, ProfileAppID, ProfileID) then
            if ConfPersonalizationMgt.TryGetDefaultProfileForCurrentUser(AllProfile) then;

        ProfileName := AllProfile.Caption;
    end;

    local procedure GetLastLoginInfo(): Text
    var
        UserLoginTimeTracker: Codeunit "User Login Time Tracker";
        LastLoginDateTime: DateTime;
    begin
        LastLoginDateTime := UserLoginTimeTracker.GetPenultimateLoginDateTime;
        if LastLoginDateTime <> 0DT then
            exit(StrSubstNo(MyLastLoginLbl, LastLoginDateTime));

        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCompanyChange(NewCompanyName: Text; var IsSetupInProgress: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUserRoleCenterChange(NewAllProfile: Record "All Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterQueryClosePage(NewLanguageID: Integer; NewLocaleID: Integer; NewTimeZoneID: Text[180]; NewCompany: Text; NewAllProfile: Record "All Profile")
    begin
    end;

    local procedure SetCompanyDisplayName()
    var
        SelectedCompany: Record Company;
        AllowedCompanies: Page "Allowed Companies";
    begin
        if SelectedCompany.Get(VarCompany) then
            CompanyDisplayName := AllowedCompanies.GetCompanyDisplayNameDefaulted(SelectedCompany)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLanguageChange(OldLanguageId: Integer; NewLanguageId: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWorkdateChange(OldWorkdate: Date; NewWorkdate: Date)
    begin
    end;
}

