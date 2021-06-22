codeunit 5323 "Exchange Add-in Setup"
{

    trigger OnRun()
    begin
    end;

    var
        ExchangeWebServicesServer: Codeunit "Exchange Web Services Server";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        Initialized: Boolean;
        InvalidCredentialsErr: Label 'The provided email address and password are not valid Office 365 or Exchange credentials.';
        NoMailboxErr: Label 'An Office 365 or Exchange mailbox could not be found for this account.';
        AutodiscoverMsg: Label 'Searching for your mailbox.';
        WelcomeSubjectTxt: Label 'Welcome to %1 - your Business Inbox in Outlook is ready!', Comment = '%1 - Application name';
        WelcomeEmailFromNameTxt: Label '%1 Admin', Comment = '%1 - Application Name';
        SalesEmailAddrTxt: Label 'admin@contoso.com', Locked = true;

    [TryFunction]
    local procedure Initialize(AuthenticationEmail: Text[80])
    var
        ExchangeServiceSetup: Record "Exchange Service Setup";
        AzureADMgt: Codeunit "Azure AD Mgt.";
        AccessToken: Text;
    begin
        AccessToken := AzureADMgt.GetAccessToken(AzureADMgt.GetO365Resource, AzureADMgt.GetO365ResourceName, false);

        if AccessToken <> '' then begin
            ExchangeWebServicesServer.InitializeWithOAuthToken(AccessToken, ExchangeWebServicesServer.GetEndpoint);
            if ValidateCredentials then
                exit;
        end;

        ExchangeServiceSetup.Get();
        with ExchangeServiceSetup do
            ExchangeWebServicesServer.InitializeWithCertificate("Azure AD App. ID", "Azure AD App. Cert. Thumbprint",
              "Azure AD Auth. Endpoint", "Exchange Service Endpoint", "Exchange Resource Uri");

        ExchangeWebServicesServer.SetImpersonatedIdentity(AuthenticationEmail);
        Initialized := true;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure InitializeServiceWithCredentials(Email: Text[80]; Password: Text)
    var
        WebCredentials: DotNet WebCredentials;
        ProgressWindow: Dialog;
        ErrorText: Text;
    begin
        WebCredentials := WebCredentials.WebCredentials(Email, Password);

        ProgressWindow.Open('#1');
        ProgressWindow.Update(1, AutodiscoverMsg);

        // Production O365 endpoint
        Initialized := ExchangeWebServicesServer.Initialize(Email, ExchangeWebServicesServer.GetEndpoint, WebCredentials, false) and
          ValidateCredentials;
        ErrorText := GetLastErrorText;

        // Autodiscover endpoint (can be slow)
        if not Initialized then begin
            Initialized := ExchangeWebServicesServer.Initialize(Email, '', WebCredentials, true) and ValidateCredentials;
            ErrorText := GetLastErrorText;
        end;

        ProgressWindow.Close;

        if not Initialized then
            Error(ErrorText);
    end;

    [Scope('OnPrem')]
    procedure CredentialsRequired(AuthenticationEmail: Text[80]) Required: Boolean
    begin
        Required := not Initialize(AuthenticationEmail);
    end;

    [Scope('OnPrem')]
    procedure PromptForCredentials(): Boolean
    var
        User: Record User;
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
    begin
        TempOfficeAdminCredentials.Init();
        TempOfficeAdminCredentials.Insert();

        User.SetRange("User Name", UserId);
        if User.FindFirst then begin
            TempOfficeAdminCredentials.Email := User."Authentication Email";
            TempOfficeAdminCredentials.Modify();
        end;

        if CredentialsRequired(TempOfficeAdminCredentials.Email) or (TempOfficeAdminCredentials.Email = '') then begin
            ClearLastError;
            repeat
                if PAGE.RunModal(PAGE::"Office 365 Credentials", TempOfficeAdminCredentials) <> ACTION::LookupOK then
                    exit(false);
            until InitializeServiceWithCredentials(TempOfficeAdminCredentials.Email, TempOfficeAdminCredentials.GetPassword);
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ImpersonateUser(Email: Text[80])
    begin
        if not Initialized then
            Initialize(Email);

        ExchangeWebServicesServer.SetImpersonatedIdentity(Email);
    end;

    procedure SampleEmailsAvailable(): Boolean
    var
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        exit(CompanyInformationMgt.IsDemoCompany and EnvironmentInfo.IsSaaS);
    end;

    [Scope('OnPrem')]
    procedure DeployAddin(OfficeAddin: Record "Office Add-in")
    var
        UserPreference: Record "User Preference";
        InstructionMgt: Codeunit "Instruction Mgt.";
        Stream: DotNet MemoryStream;
        Encoding: DotNet UTF8Encoding;
        ManifestText: Text;
    begin
        AddinManifestManagement.GenerateManifest(OfficeAddin, ManifestText);
        Encoding := Encoding.UTF8Encoding;
        Stream := Stream.MemoryStream(Encoding.GetBytes(ManifestText));
        ExchangeWebServicesServer.InstallApp(Stream);

        UserPreference.SetRange("Instruction Code", InstructionMgt.OfficeUpdateNotificationCode);
        UserPreference.SetRange("User ID", UserId);
        UserPreference.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure DeployAddins(var OfficeAddin: Record "Office Add-in")
    begin
        if OfficeAddin.GetAddins then
            repeat
                DeployAddin(OfficeAddin);
            until OfficeAddin.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure DeploySampleEmails(EmailAddress: Text)
    var
        User: Record User;
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
        OfficeAddinSampleEmails: Codeunit "Office Add-In Sample Emails";
        RecipientEmail: Text;
        FromEmail: Text;
        HTMlBody: Text;
    begin
        if EmailAddress <> '' then
            RecipientEmail := EmailAddress
        else begin
            User.SetRange("User Name", UserId);
            if User.FindFirst then
                RecipientEmail := User."Authentication Email";
        end;

        FromEmail := SalesEmailAddrTxt;
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        if ContactBusinessRelation.FindFirst then begin
            if Contact.Get(ContactBusinessRelation."Contact No.") then begin
                if Contact."E-Mail" <> '' then
                    FromEmail := Contact."E-Mail";
            end
        end;

        HTMlBody := OfficeAddinSampleEmails.GetHTMLSampleMsg;
        ExchangeWebServicesServer.SaveHTMLEmailToInbox(StrSubstNo(WelcomeSubjectTxt, PRODUCTNAME.Marketing), HTMlBody,
          FromEmail, StrSubstNo(WelcomeEmailFromNameTxt, PRODUCTNAME.Full), RecipientEmail);
    end;

    [TryFunction]
    local procedure ValidateCredentials()
    begin
        if not ExchangeWebServicesServer.ValidCredentials then begin
            if StrPos(GetLastErrorText, '401') > 0 then
                Error(InvalidCredentialsErr);
            Error(NoMailboxErr);
        end;
    end;
}

