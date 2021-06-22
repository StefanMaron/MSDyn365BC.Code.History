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
        ExchangeTelemetryCategoryTxt: Label 'AL Exchange', Locked = true;
        TryInitializeWithEmailTxt: Label 'Trying to initialize the service with email.', Locked = true;
        TryInitializeWithCredentialsTxt: Label 'Trying to initialize the service with credentials.', Locked = true;
        InitializedWithOAuthTokenTxt: Label 'The service is initialized with OAuth token.', Locked = true;
        InitializedWithCertificateTxt: Label 'The service is initialized with certificate.', Locked = true;
        InitializedWithCredentialsTxt: Label 'The service is initialized with credentials.', Locked = true;
        NotInitializedWithCredentialsTxt: Label 'The service is not initialized with credentials.', Locked = true;
        TryAutodiscoverEndpointTxt: Label 'Try to autodiscover endpoint.', Locked = true;
        PromptForCredentialsTxt: Label 'Prompt for credentials.', Locked = true;
        UserFoundTxt: Label 'User is found.', Locked = true;
        CredentialsRequiredTxt: Label 'Credentials are required.', Locked = true;
        CredentialsPromptCancelledTxt: Label 'Credentials prmpt is cancelled.', Locked = true;
        ImpersonateUserTxt: Label 'Impersonate user.', Locked = true;
        DeployAddInTxt: Label 'Deploy add-in.', Locked = true;
        DeploySampleEmailsTxt: Label 'Deploy sample emails.', Locked = true;
        SampleEmailsDeployedTxt: Label 'sample emails are deployed.', Locked = true;
        ValidCredentialsTxt: Label 'The provided email address and password are valid Office 365 or Exchange credentials.', Locked = true;
        InvalidCredentialsTxt: Label 'The provided email address and password are not valid Office 365 or Exchange credentials.', Locked = true;
        NoMailboxTxt: Label 'An Office 365 or Exchange mailbox could not be found for this account.', Locked = true;
        ToSpecifiedEmailTxt: Label 'Recipient email is the specified email.', Locked = true;
        ToUserEmailTxt: Label 'Recipient email is the user email.', Locked = true;
        FromContactEmailTxt: Label 'Sender email is the contact email.', Locked = true;
        FromSalesEmailTxt: Label 'Sender email is the sales email.', Locked = true;

    [TryFunction]
    local procedure Initialize(AuthenticationEmail: Text[80])
    var
        ExchangeServiceSetup: Record "Exchange Service Setup";
        AzureADMgt: Codeunit "Azure AD Mgt.";
        AccessToken: Text;
    begin
        SendTraceTag('0000BX8', ExchangeTelemetryCategoryTxt, Verbosity::Normal, TryInitializeWithEmailTxt, DataClassification::SystemMetadata);

        AccessToken := AzureADMgt.GetAccessToken(AzureADMgt.GetO365Resource, AzureADMgt.GetO365ResourceName, false);

        if AccessToken <> '' then begin
            ExchangeWebServicesServer.InitializeWithOAuthToken(AccessToken, ExchangeWebServicesServer.GetEndpoint);
            if ValidateCredentials then begin
                SendTraceTag('0000BX9', ExchangeTelemetryCategoryTxt, Verbosity::Normal, InitializedWithOAuthTokenTxt, DataClassification::SystemMetadata);
                exit;
            end;
        end;

        ExchangeServiceSetup.Get();
        with ExchangeServiceSetup do
            ExchangeWebServicesServer.InitializeWithCertificate("Azure AD App. ID", "Azure AD App. Cert. Thumbprint",
              "Azure AD Auth. Endpoint", "Exchange Service Endpoint", "Exchange Resource Uri");

        ExchangeWebServicesServer.SetImpersonatedIdentity(AuthenticationEmail);
        Initialized := true;

        SendTraceTag('0000BYR', ExchangeTelemetryCategoryTxt, Verbosity::Normal, InitializedWithCertificateTxt, DataClassification::SystemMetadata);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure InitializeServiceWithCredentials(Email: Text[80]; Password: Text)
    var
        WebCredentials: DotNet WebCredentials;
        ProgressWindow: Dialog;
        ErrorText: Text;
    begin
        SendTraceTag('0000BXA', ExchangeTelemetryCategoryTxt, Verbosity::Normal, TryInitializeWithCredentialsTxt, DataClassification::SystemMetadata);

        WebCredentials := WebCredentials.WebCredentials(Email, Password);

        ProgressWindow.Open('#1');
        ProgressWindow.Update(1, AutodiscoverMsg);

        // Production O365 endpoint
        Initialized := ExchangeWebServicesServer.Initialize(Email, ExchangeWebServicesServer.GetEndpoint, WebCredentials, false) and
          ValidateCredentials;
        ErrorText := GetLastErrorText;

        // Autodiscover endpoint (can be slow)
        if not Initialized then begin
            SendTraceTag('0000BXB', ExchangeTelemetryCategoryTxt, Verbosity::Normal, TryAutodiscoverEndpointTxt, DataClassification::SystemMetadata);
            Initialized := ExchangeWebServicesServer.Initialize(Email, '', WebCredentials, true) and ValidateCredentials;
            ErrorText := GetLastErrorText;
        end;

        ProgressWindow.Close;

        if not Initialized then begin
            SendTraceTag('0000BXC', ExchangeTelemetryCategoryTxt, Verbosity::Warning, NotInitializedWithCredentialsTxt, DataClassification::SystemMetadata);
            Error(ErrorText);
        end;

        SendTraceTag('0000BXD', ExchangeTelemetryCategoryTxt, Verbosity::Normal, InitializedWithCredentialsTxt, DataClassification::SystemMetadata);
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
        SendTraceTag('0000BXE', ExchangeTelemetryCategoryTxt, Verbosity::Normal, PromptForCredentialsTxt, DataClassification::SystemMetadata);

        TempOfficeAdminCredentials.Init();
        TempOfficeAdminCredentials.Insert();

        User.SetRange("User Name", UserId);
        if User.FindFirst then begin
            SendTraceTag('0000BXF', ExchangeTelemetryCategoryTxt, Verbosity::Normal, UserFoundTxt, DataClassification::SystemMetadata);
            TempOfficeAdminCredentials.Email := User."Authentication Email";
            TempOfficeAdminCredentials.Modify();
        end;

        if CredentialsRequired(TempOfficeAdminCredentials.Email) or (TempOfficeAdminCredentials.Email = '') then begin
            SendTraceTag('0000BXG', ExchangeTelemetryCategoryTxt, Verbosity::Normal, CredentialsRequiredTxt, DataClassification::SystemMetadata);
            ClearLastError;
            repeat
                if PAGE.RunModal(PAGE::"Office 365 Credentials", TempOfficeAdminCredentials) <> ACTION::LookupOK then begin
                    SendTraceTag('0000BXH', ExchangeTelemetryCategoryTxt, Verbosity::Normal, CredentialsPromptCancelledTxt, DataClassification::SystemMetadata);
                    exit(false);
                end;
            until InitializeServiceWithCredentials(TempOfficeAdminCredentials.Email, TempOfficeAdminCredentials.GetPassword);
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ImpersonateUser(Email: Text[80])
    begin
        SendTraceTag('0000BXI', ExchangeTelemetryCategoryTxt, Verbosity::Normal, ImpersonateUserTxt, DataClassification::SystemMetadata);

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
        SendTraceTag('0000BXJ', ExchangeTelemetryCategoryTxt, Verbosity::Normal, DeployAddInTxt, DataClassification::SystemMetadata);

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
        SendTraceTag('0000BXK', ExchangeTelemetryCategoryTxt, Verbosity::Normal, DeploySampleEmailsTxt, DataClassification::SystemMetadata);

        if EmailAddress <> '' then begin
            SendTraceTag('0000BXL', ExchangeTelemetryCategoryTxt, Verbosity::Normal, ToSpecifiedEmailTxt, DataClassification::SystemMetadata);
            RecipientEmail := EmailAddress
        end else begin
            User.SetRange("User Name", UserId);
            if User.FindFirst then begin
                SendTraceTag('0000BXM', ExchangeTelemetryCategoryTxt, Verbosity::Normal, ToUserEmailTxt, DataClassification::SystemMetadata);
                RecipientEmail := User."Authentication Email";
            end;
        end;

        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        if ContactBusinessRelation.FindFirst then begin
            if Contact.Get(ContactBusinessRelation."Contact No.") then begin
                if Contact."E-Mail" <> '' then begin
                    SendTraceTag('0000BXN', ExchangeTelemetryCategoryTxt, Verbosity::Normal, FromContactEmailTxt, DataClassification::SystemMetadata);
                    FromEmail := Contact."E-Mail";
                end;
            end
        end;

        if FromEmail = '' then begin
            FromEmail := SalesEmailAddrTxt;
            SendTraceTag('0000BYS', ExchangeTelemetryCategoryTxt, Verbosity::Normal, FromSalesEmailTxt, DataClassification::SystemMetadata);
        end;

        HTMlBody := OfficeAddinSampleEmails.GetHTMLSampleMsg;
        ExchangeWebServicesServer.SaveHTMLEmailToInbox(StrSubstNo(WelcomeSubjectTxt, PRODUCTNAME.Marketing), HTMlBody,
          FromEmail, StrSubstNo(WelcomeEmailFromNameTxt, PRODUCTNAME.Full), RecipientEmail);

        SendTraceTag('0000BXO', ExchangeTelemetryCategoryTxt, Verbosity::Normal, SampleEmailsDeployedTxt, DataClassification::SystemMetadata);
    end;

    [TryFunction]
    local procedure ValidateCredentials()
    begin
        if not ExchangeWebServicesServer.ValidCredentials then begin
            if StrPos(GetLastErrorText, '401') > 0 then begin
                SendTraceTag('0000BXP', ExchangeTelemetryCategoryTxt, Verbosity::Warning, InvalidCredentialsTxt, DataClassification::SystemMetadata);
                Error(InvalidCredentialsErr);
            end;
            SendTraceTag('0000BXQ', ExchangeTelemetryCategoryTxt, Verbosity::Warning, NoMailboxTxt, DataClassification::SystemMetadata);
            Error(NoMailboxErr);
        end;
        SendTraceTag('0000BXR', ExchangeTelemetryCategoryTxt, Verbosity::Normal, ValidCredentialsTxt, DataClassification::SystemMetadata);
    end;
}

