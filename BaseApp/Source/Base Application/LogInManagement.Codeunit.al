codeunit 40 LogInManagement
{
    Permissions = TableData "Company Information" = r,
                  TableData "G/L Entry" = r,
                  TableData "General Ledger Setup" = r,
                  TableData Customer = r,
                  TableData Vendor = r,
                  TableData Item = r,
                  TableData User = r,
                  TableData "User Time Register" = rimd,
                  TableData "My Customer" = rimd,
                  TableData "My Vendor" = rimd,
                  TableData "My Item" = rimd,
                  TableData "My Account" = rimd;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        PasswordChangeNeededErr: Label 'You must change the password before you can continue.';
        GLSetup: Record "General Ledger Setup";
        [SecurityFiltering(SecurityFilter::Filtered)]
        User: Record User;
        LogInWorkDate: Date;
        LogInDate: Date;
        LogInTime: Time;
        GLSetupRead: Boolean;

    [Scope('OnPrem')]
    procedure CompanyOpen()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        AzureADPlan: Codeunit "Azure AD Plan";
        CurrentDate: Date;
    begin
        OnShowTermsAndConditions();

#if not CLEAN20
        OnBeforeCompanyOpen();
#endif

        if GuiAllowed and (ClientTypeManagement.GetCurrentClientType() <> ClientType::Background) then
            LogInStart();

        if ClientTypeManagement.GetCurrentClientType() in [ClientType::Api, ClientType::ODataV4] then
            if GetCurrentDateInUserTimeZone(CurrentDate) then
                WorkDate := CurrentDate;

        AzureADPlan.CheckMixedPlans();

#if not CLEAN20
        OnAfterCompanyOpen();
#endif
    end;

    procedure CompanyClose()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        OnBeforeCompanyClose();
        if GuiAllowed or (ClientTypeManagement.GetCurrentClientType() in [ClientType::Web, ClientType::Phone, ClientType::Tablet]) then
            LogInEnd();
        OnAfterCompanyClose();
    end;

    local procedure LogInStart()
    var
        Language: Record "Windows Language";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        IdentityManagement: Codeunit "Identity Management";
        LanguageManagement: Codeunit Language;
    begin
        Language.SetRange("Localization Exist", true);
        Language.SetRange("Globally Enabled", true);
        Language."Language ID" := GlobalLanguage;

        if not Language.Find() then begin
            Language."Language ID" := WindowsLanguage;
            if not Language.Find() then
                Language."Language ID" := LanguageManagement.GetDefaultApplicationLanguageId();
        end;
        GlobalLanguage := Language."Language ID";

        // Check if the logged in user must change login before allowing access.
        if not User.IsEmpty() then begin
            if IdentityManagement.IsUserNamePasswordAuthentication() then begin
                User.SetRange("User Security ID", UserSecurityId());
                User.FindFirst();
                if User."Change Password" then begin
                    REPORT.Run(REPORT::"Change Password");
                    SelectLatestVersion();
                    User.FindFirst();
                    if User."Change Password" then
                        Error(PasswordChangeNeededErr);
                end;
            end;

            User.SetRange("User Security ID");
        end;

#if not CLEAN20
        OnBeforeLogInStart();
#endif

        UpdateUserPersonalization();

        LogInDate := Today;
        LogInTime := Time;
        LogInWorkDate := 0D;

        WorkDate := GetDefaultWorkDate();

        ApplicationAreaMgmtFacade.SetupApplicationArea();

#if not CLEAN20
        OnAfterLogInStart();
#endif
    end;

    local procedure LogInEnd()
    var
        UserSetup: Record "User Setup";
        UserTimeRegister: Record "User Time Register";
        LogOutDate: Date;
        LogOutTime: Time;
        Minutes: Integer;
        UserSetupFound: Boolean;
        RegisterTime: Boolean;
    begin
        if LogInDate = 0D then
            exit;

        if LogInWorkDate <> 0D then
            if LogInWorkDate = LogInDate then
                WorkDate := Today
            else
                WorkDate := LogInWorkDate;

        if UserId <> '' then begin
            if UserSetup.Get(UserId) then begin
                UserSetupFound := true;
                RegisterTime := UserSetup."Register Time";
                OnLogInEndOnAfterGetUserSetupRegisterTime(UserSetup);
            end;
            if not UserSetupFound then
                if GetGLSetup() then
                    RegisterTime := GLSetup."Register Time";
            if RegisterTime then begin
                LogOutDate := Today;
                LogOutTime := Time;
                if (LogOutDate > LogInDate) or (LogOutDate = LogInDate) and (LogOutTime > LogInTime) then
                    Minutes := Round((1440 * (LogOutDate - LogInDate)) + ((LogOutTime - LogInTime) / 60000), 1);
                if Minutes = 0 then
                    Minutes := 1;
                UserTimeRegister.Init();
                UserTimeRegister."User ID" := CopyStr(UserId(), 1, MaxStrLen(UserTimeRegister."User ID"));
                UserTimeRegister.Date := LogInDate;
                UserTimeRegister.LockTable();
                if UserTimeRegister.Find() then begin
                    UserTimeRegister.Minutes := UserTimeRegister.Minutes + Minutes;
                    UserTimeRegister.Modify();
                end else begin
                    UserTimeRegister.Minutes := Minutes;
                    UserTimeRegister.Insert();
                end;
            end;
        end;

#if not CLEAN20
        OnAfterLogInEnd();
#endif
    end;

#if not CLEAN20
    [Obsolete('No longer used, Company-Initialize runs on System Initialize''s event OnAfterLogin', '20.0')]
    procedure InitializeCompany()
    begin
        if not GLSetup.Get() then
            CODEUNIT.Run(CODEUNIT::"Company-Initialize");
    end;
#endif

    local procedure GetGLSetup(): Boolean
    begin
        if not GLSetupRead then
            GLSetupRead := GLSetup.Get();
        exit(GLSetupRead);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"G/L Entry", 'r')]
    procedure GetDefaultWorkDate(): Date
    var
        GLEntry: Record "G/L Entry";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        if CompanyInformationMgt.IsDemoCompany() then begin
            GLEntry.SetCurrentKey("Posting Date");
            if GLEntry.FindLast() then begin
                LogInWorkDate := NormalDate(GLEntry."Posting Date");
                exit(NormalDate(GLEntry."Posting Date"));
            end;
        end;

        exit(WorkDate());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'GetSystemIndicator', '', false, false)]
    local procedure GetSystemIndicator(var Text: Text[250]; var Style: Option Standard,Accent1,Accent2,Accent3,Accent4,Accent5,Accent6,Accent7,Accent8,Accent9)
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.Get() then;
        CompanyInformation.GetSystemIndicator(Text, Style);
    end;

    local procedure UpdateUserPersonalization()
    var
        UserPersonalization: Record "User Personalization";
        AllProfile: Record "All Profile";
        AllObjWithCaption: Record AllObjWithCaption;
        PermissionManager: Codeunit "Permission Manager";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not UserPersonalization.Get(UserSecurityId()) then
            exit;

        if AllProfile.Get(UserPersonalization.Scope, UserPersonalization."App ID", UserPersonalization."Profile ID") then begin
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
            AllObjWithCaption.SetRange("Object Subtype", 'RoleCenter');
            AllObjWithCaption.SetRange("Object ID", AllProfile."Role Center ID");
            if AllObjWithCaption.IsEmpty() then begin
                Clear(UserPersonalization."Profile ID");
                Clear(UserPersonalization."App ID");
                Clear(UserPersonalization.Scope);
                UserPersonalization.Modify();
                Commit();
            end;
        end else
            if EnvironmentInfo.IsSaaS() then begin
                AllProfile.Reset();
                PermissionManager.GetDefaultProfileID(UserSecurityId(), AllProfile);

                if not AllProfile.IsEmpty() then begin
                    UserPersonalization."Profile ID" := AllProfile."Profile ID";
                    UserPersonalization.Scope := AllProfile.Scope;
                    UserPersonalization."App ID" := AllProfile."App ID";
                    UserPersonalization.Modify();
                end else begin
                    Clear(UserPersonalization."Profile ID");
                    Clear(UserPersonalization."App ID");
                    Clear(UserPersonalization.Scope);
                    UserPersonalization.Modify();
                end;
            end;
    end;

    [TryFunction]
    local procedure GetCurrentDateInUserTimeZone(var CurrentDate: Date)
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        CurrentDate := DT2Date(TypeHelper.GetCurrentDateTimeInUserTimeZone());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterInitialization', '', false, false)]
    local procedure OnCompanyOpen()
    begin
        CompanyOpen();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyClose', '', false, false)]
    local procedure OnCompanyClose()
    begin
        CompanyClose();
    end;

#if not CLEAN20
    [IntegrationEvent(false, false)]
    [Obsolete('Replaced with OnAfterLogin in codeunit "System Initialization"', '20.0')]
    local procedure OnAfterLogInStart()
    begin
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced with OnAfterLogin in codeunit "System Initialization"', '20.0')]
    local procedure OnAfterLogInEnd()
    begin
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced with OnAfterLogin in codeunit "System Initialization"', '20.0')]
    local procedure OnBeforeLogInStart()
    begin
    end;

    [Obsolete('Replaced with OnAfterLogin in codeunit "System Initialization"', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCompanyOpen()
    begin
    end;

    [Obsolete('Replaced with OnAfterLogin in codeunit "System Initialization"', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCompanyOpen()
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCompanyClose()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCompanyClose()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogInEndOnAfterGetUserSetupRegisterTime(var UserSetup: Record "User Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowTermsAndConditions()
    begin
    end;
}

