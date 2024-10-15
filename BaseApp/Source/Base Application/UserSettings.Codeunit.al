codeunit 9174 "User Settings"
{
    trigger OnRun()
    begin

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
        if PAGE.RunModal(PAGE::"Available Roles", AllProfileTable) = ACTION::LookupOK then begin
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
        ConfPersMgt: Codeunit "Conf./Personalization Mgt.";
        TimeZoneTmp: Text;
    begin
        TimeZoneTmp := UserPersonalization."Time Zone";
        ConfPersMgt.ValidateTimeZone(TimeZoneTmp);
        UserPersonalization."Time Zone" := CopyStr(TimeZoneTmp, 1, 180);
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

    var
        RequiresRestart: Boolean;
}