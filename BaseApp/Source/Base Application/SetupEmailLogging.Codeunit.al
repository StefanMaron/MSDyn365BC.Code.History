codeunit 1641 "Setup Email Logging"
{

    trigger OnRun()
    begin
    end;

    var
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
        ExchangePowerShellRunner: Codeunit "Exchange PowerShell Runner";
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        PublicFoldersCreationProgressMsg: Label 'Public folder creation  @1@@@@@@@@@@@@@@@@@@';
        Initialized: Boolean;
        AdminCredentialsRequiredErr: Label 'Could not create a public Exchange folder. Check if the credentials of the Exchange administrator are entered correctly.';
        EmailLoggingTelemetryCategoryTxt: Label 'AL Email Logging', Locked = true;
        CloseConnectionTxt: Label 'Close connection to Exchange.', Locked = true;
        InitializeConnectionTxt: Label 'Initialize connection to Exchange.', Locked = true;
        ConnectionNotInitializedTxt: Label 'Connection to Exchange is not initialized.', Locked = true;
        ConnectionAlreadyInitializedTxt: Label 'Connection to Exchange has already been initialized.', Locked = true;
        CreatePublicFoldersTxt: Label 'Create Exchange public folders.', Locked = true;
        PublicFoldersCreatedTxt: Label 'Exchange public folders are created.', Locked = true;
        CreateEmailLoggingRulesTxt: Label 'Create email logging rules.', Locked = true;
        CreateEmailLoggingIncomingRuleTxt: Label 'Create email logging incoming rule.', Locked = true;
        CreateEmailLoggingOutgoingRuleTxt: Label 'Create email logging outgoing rule.', Locked = true;
        EmailLoggingRulesCreatedTxt: Label 'Email logging rules are created.', Locked = true;
        ClearEmailLoggingSetupTxt: Label 'Clear email logging setup.', Locked = true;
        SetDeployCredentialsTxt: Label 'Set deploy credentials.', Locked = true;
        CreateEmailLoggingJobTxt: Label 'Create email logging job.', Locked = true;
        DeleteEmailLoggingJobTxt: Label 'Delete email logging job.', Locked = true;
        SetupEmailLoggingTxt: Label 'Setup email logging.', Locked = true;
        CannotFindMarketingSetupTxt: Label 'Cannot find marketing setup record.', Locked = true;
        EnableOrganizationCustomizationTxt: Label 'Enabling organization customization to be able to add new role group.', Locked = true;
        AddRoleGroupForPublicFoldersTxt: Label 'Add new role group for public folders.', Locked = true;
        AddUserAsMemberOfRoleGroupTxt: Label 'Add user as a member of created role group.', Locked = true;
        CreateNewMailBoxTxt: Label 'Creation of new mail box.', Locked = true;
        CreateNewPublicRootFolderTxt: Label 'Creation of new root public folder.', Locked = true;
        AdminCredentialsRequiredTxt: Label 'Admin credentials are required.', Locked = true;
        CheckIfFolderAlreadyExistsTxt: Label 'Check if folder already exists.', Locked = true;
        CreateQueuePublicFolderTxt: Label 'Creation of new queue public folder.', Locked = true;
        CreateStoragePublicFolderTxt: Label 'Creation of new storage public folder.', Locked = true;
        CreatePublicFolderEmailSettingsTxt: Label 'Creation of queue public folder email settings.', Locked = true;
        AddPublicFolderClientPermissionTxt: Label 'Add public folder client permission.', Locked = true;
        MissingClientIdOrSecretErr: Label 'The client ID or client secret have not been initialized.';
        MissingClientIdTelemetryTxt: Label 'The client ID has not been initialized.', Locked = true;
        MissingClientSecretTelemetryTxt: Label 'The client secret has not been initialized.', Locked = true;
        InitializedClientIdTelemetryTxt: Label 'The client ID has been initialized.', Locked = true;
        InitializedClientSecretTelemetryTxt: Label 'The client secret has been initialized.', Locked = true;
        EmailLoggingClientIdAKVSecretNameLbl: Label 'emaillogging-clientid', Locked = true;
        EmailLoggingClientSecretAKVSecretNameLbl: Label 'emaillogging-clientsecret', Locked = true;
        TenantOAuthAuthorityUrlLbl: Label 'https://login.microsoftonline.com/%1/oauth2', Locked = true;
        CommonOAuthAuthorityUrlLbl: Label 'https://login.microsoftonline.com/common/oauth2', Locked = true;
        ResourceUrlLbl: Label 'https://outlook.office.com', Locked = true;
        ClientCredentialsAccessTokenErr: Label 'No client credentials access token received', Locked = true;
        AccessTokenErrMsg: Label 'Failed to acquire an access token.';
        AuthTokenOrCodeNotReceivedErr: Label 'No access token or authorization error code received.', Locked = true;
        AdminAccessTokenReceivedTxt: Label 'Admin access token has been received.', Locked = true;
        ClientAccessTokenReceivedTxt: Label 'Client access token has been received.', Locked = true;
        AcquireAccessTokenTxt: Label 'Asquire access token.', Locked = true;
        IgnoredClientCredentialsTxt: Label 'Ignored client credentials.', Locked = true;
        InvalidClientCredentialsTxt: Label 'Invalid client credentials.', Locked = true;
        EmptyRedirectUrlTxt: Label 'Redirect URL is empty, the default URL will be used.', Locked = true;
        RootFolderPathTemplateTxt: Label '\%1\', Locked = true;
        PublicFolderPathTemplateTxt: Label '\%1\%2\', Locked = true;
        FolderDoesNotExistErr: Label 'The specified Exchange folder does not exist.';
        FolderDoesNotExistTxt: Label 'Exchange folder %1 (%2) does not exist.', Locked = true;
        SetupEmailLoggingTitleTxt: Label 'Set up email logging';
        SetupEmailLoggingHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115467', Locked = true;
        VideoUrlSetupEmailLoggingTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843360', Locked = true;
        SetupEmailLoggingDescriptionTxt: Label 'Track email exchanges between your sales team and customers and prospects, and then turning them into actionable opportunities.';
        EmptyAccessTokenTxt: Label 'Access token is empty.', Locked = true;
        TenantIdExtractedTxt: Label 'Tenant ID %1 has been extracted from token.', Locked = true;
        CannotExtractTenantIdTxt: Label 'Cannot extract tenant ID from token %1.', Locked = true;
        CannotExtractTenantIdErr: Label 'Cannot extract tenant ID from the access token.';

    [TryFunction]
    [Scope('OnPrem')]
    procedure InitializeExchangePSConnection()
    var
        ExchangeWebServicesClient: Codeunit "Exchange Web Services Client";
        NetworkCredential: DotNet NetworkCredential;
    begin
        if not Initialized then begin
            SendTraceTag('0000BY5', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, InitializeConnectionTxt, DataClassification::SystemMetadata);

            if not ExchangePowerShellRunner.PromptForCredentials() then begin
                SendTraceTag('0000BY6', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ConnectionNotInitializedTxt, DataClassification::SystemMetadata);
                Error(GetLastErrorText);
            end;
            ExchangePowerShellRunner.GetCredentials(TempOfficeAdminCredentials);
            ExchangePowerShellRunner.InitializePSRunner();

            NetworkCredential := NetworkCredential.NetworkCredential(TempOfficeAdminCredentials.Email,
                TempOfficeAdminCredentials.GetPassword());
            ExchangeWebServicesClient.InitializeOnServer(
              TempOfficeAdminCredentials.Email, GetDomainFromEmail(TempOfficeAdminCredentials.Email), NetworkCredential);
            ExchangeWebServicesClient.ValidateCredentialsOnServer();
        end else
            SendTraceTag('0000BY7', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ConnectionAlreadyInitializedTxt, DataClassification::SystemMetadata);

        Initialized := true;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure CreatePublicFolders(PublicMailBoxName: Text; RootFolderName: Text; QueueFolderName: Text; StorageFolderName: Text)
    var
        Enum: DotNet IEnumerator;
        Window: Dialog;
        QueueFolderPath: Text;
        StorageFolderPath: Text;
    begin
        SendTraceTag('0000BY8', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CreatePublicFoldersTxt, DataClassification::SystemMetadata);

        Window.Open(PublicFoldersCreationProgressMsg);

        // Enabling Organization Customization to be able to add new Role Group
        SendTraceTag('0000BYT', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, EnableOrganizationCustomizationTxt, DataClassification::SystemMetadata);
        Window.Update(1, 0);
        ExchangePowerShellRunner.AddCommand('Enable-OrganizationCustomization', true);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Add new Role Group for Public Folders
        SendTraceTag('0000BYU', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, AddRoleGroupForPublicFoldersTxt, DataClassification::SystemMetadata);
        Window.Update(1, 2000);
        ExchangePowerShellRunner.AddCommand('New-RoleGroup', true);
        ExchangePowerShellRunner.AddParameter('Name', 'Public Folders Management');
        ExchangePowerShellRunner.AddParameter('Roles', 'Public Folders');
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Add user as a member of created Role Group
        SendTraceTag('0000BYV', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, AddUserAsMemberOfRoleGroupTxt, DataClassification::SystemMetadata);
        Window.Update(1, 3000);
        ExchangePowerShellRunner.AddCommand('Add-RoleGroupMember', true);
        ExchangePowerShellRunner.AddParameter('Identity', 'Public Folders Management');
        ExchangePowerShellRunner.AddParameter('Member', TempOfficeAdminCredentials.Email);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Creation of new Mail Box
        SendTraceTag('0000BYW', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CreateNewMailBoxTxt, DataClassification::SystemMetadata);
        Window.Update(1, 4000);
        ExchangePowerShellRunner.AddCommand('New-Mailbox', true);
        ExchangePowerShellRunner.AddParameterFlag('PublicFolder');
        ExchangePowerShellRunner.AddParameter('Name', PublicMailBoxName);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Creation of new Root public Folder
        SendTraceTag('0000BYX', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CreateNewPublicRootFolderTxt, DataClassification::SystemMetadata);
        Window.Update(1, 5000);
        ExchangePowerShellRunner.AddCommand('New-PublicFolder', true);
        ExchangePowerShellRunner.AddParameter('Name', RootFolderName);
        ExchangePowerShellRunner.AddParameter('Mailbox', PublicMailBoxName);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        ExchangePowerShellRunner.GetResultEnumerator(Enum);

        // If returned nothing then check if folder already exists
        if not Enum.MoveNext then begin
            SendTraceTag('0000BY9', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CheckIfFolderAlreadyExistsTxt, DataClassification::SystemMetadata);
            ExchangePowerShellRunner.ClearLog;
            ExchangePowerShellRunner.AddCommand('Get-PublicFolder', true);
            ExchangePowerShellRunner.AddParameter('Identity', StrSubstNo(RootFolderPathTemplateTxt, RootFolderName));
            ExchangePowerShellRunner.Invoke;
            ExchangePowerShellRunner.AwaitCompletion;

            ExchangePowerShellRunner.GetResultEnumerator(Enum);
            // If Public Folder does not exist then user has no admin rights
            if not Enum.MoveNext then begin
                SendTraceTag('0000BYA', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, AdminCredentialsRequiredTxt, DataClassification::SystemMetadata);
                ClosePSConnection;
                Error(AdminCredentialsRequiredErr);
            end;
        end;

        // Creation of new Queue public Folder /Root/Queue
        SendTraceTag('0000BY9', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CreateQueuePublicFolderTxt, DataClassification::SystemMetadata);
        Window.Update(1, 6000);
        ExchangePowerShellRunner.AddCommand('New-PublicFolder', true);
        ExchangePowerShellRunner.AddParameter('Name', QueueFolderName);
        ExchangePowerShellRunner.AddParameter('Path', StrSubstNo(RootFolderPathTemplateTxt, RootFolderName));
        ExchangePowerShellRunner.AddParameter('Mailbox', PublicMailBoxName);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Creation of new Storage public Folder /Root/Storage
        SendTraceTag('0000BY9', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CreateStoragePublicFolderTxt, DataClassification::SystemMetadata);
        Window.Update(1, 7000);
        ExchangePowerShellRunner.AddCommand('New-PublicFolder', true);
        ExchangePowerShellRunner.AddParameter('Name', StorageFolderName);
        ExchangePowerShellRunner.AddParameter('Path', StrSubstNo(RootFolderPathTemplateTxt, RootFolderName));
        ExchangePowerShellRunner.AddParameter('Mailbox', PublicMailBoxName);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Grant Queue public folder Mail Settings (email address)
        SendTraceTag('0000BY9', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CreatePublicFolderEmailSettingsTxt, DataClassification::SystemMetadata);
        Window.Update(1, 8000);
        QueueFolderPath := StrSubstNo(PublicFolderPathTemplateTxt, RootFolderName, QueueFolderName);
        StorageFolderPath := StrSubstNo(PublicFolderPathTemplateTxt, RootFolderName, StorageFolderName);
        ExchangePowerShellRunner.AddCommand('Enable-MailPublicFolder', true);
        ExchangePowerShellRunner.AddParameter('Identity', QueueFolderPath);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Grant users to send email to mail enabled folder
        SendTraceTag('0000BY9', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, AddPublicFolderClientPermissionTxt, DataClassification::SystemMetadata);
        Window.Update(1, 9000);
        ExchangePowerShellRunner.AddCommand('Add-PublicFolderClientPermission', true);
        ExchangePowerShellRunner.AddParameter('Identity', QueueFolderPath);
        ExchangePowerShellRunner.AddParameter('AccessRights', 'CreateItems');
        ExchangePowerShellRunner.AddParameter('User', 'Anonymous');
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        SendTraceTag('0000BYY', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, AddPublicFolderClientPermissionTxt, DataClassification::SystemMetadata);
        ExchangePowerShellRunner.AddCommand('Add-PublicFolderClientPermission', true);
        ExchangePowerShellRunner.AddParameter('Identity', QueueFolderPath);
        ExchangePowerShellRunner.AddParameter('AccessRights', 'Owner');
        ExchangePowerShellRunner.AddParameter('User', TempOfficeAdminCredentials.Email);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        SendTraceTag('0000BYZ', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, AddPublicFolderClientPermissionTxt, DataClassification::SystemMetadata);
        ExchangePowerShellRunner.AddCommand('Add-PublicFolderClientPermission', true);
        ExchangePowerShellRunner.AddParameter('Identity', StorageFolderPath);
        ExchangePowerShellRunner.AddParameter('AccessRights', 'Owner');
        ExchangePowerShellRunner.AddParameter('User', TempOfficeAdminCredentials.Email);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        Window.Close;

        SendTraceTag('0000BYB', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, PublicFoldersCreatedTxt, DataClassification::SystemMetadata);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure CreateEmailLoggingRules(QueueEmailAddress: Text; IncomingRuleName: Text; OutgoingRuleName: Text)
    begin
        SendTraceTag('0000BYC', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CreateEmailLoggingRulesTxt, DataClassification::SystemMetadata);

        // Create new Transport Rule for Ingoing mail from outside organization
        if IncomingRuleName <> '' then begin
            SendTraceTag('0000BYD', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CreateEmailLoggingIncomingRuleTxt, DataClassification::SystemMetadata);
            ExchangePowerShellRunner.AddCommand('New-TransportRule', true);
            ExchangePowerShellRunner.AddParameter('Name', IncomingRuleName);
            ExchangePowerShellRunner.AddParameter('FromScope', 'NotInOrganization');
            ExchangePowerShellRunner.AddParameter('SentToScope', 'InOrganization');
            ExchangePowerShellRunner.AddParameter('BlindCopyTo', QueueEmailAddress);
            ExchangePowerShellRunner.Invoke;
            ExchangePowerShellRunner.AwaitCompletion;
        end;

        // Create new Transport Rule for Outgoing mail to outside organization
        if OutgoingRuleName <> '' then begin
            SendTraceTag('0000BYE', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CreateEmailLoggingOutgoingRuleTxt, DataClassification::SystemMetadata);
            ExchangePowerShellRunner.AddCommand('New-TransportRule', true);
            ExchangePowerShellRunner.AddParameter('Name', OutgoingRuleName);
            ExchangePowerShellRunner.AddParameter('FromScope', 'InOrganization');
            ExchangePowerShellRunner.AddParameter('SentToScope', 'NotInOrganization');
            ExchangePowerShellRunner.AddParameter('BlindCopyTo', QueueEmailAddress);
            ExchangePowerShellRunner.Invoke;
            ExchangePowerShellRunner.AwaitCompletion;
        end;
        ClosePSConnection;

        SendTraceTag('0000BYF', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, EmailLoggingRulesCreatedTxt, DataClassification::SystemMetadata);
    end;

    [Scope('OnPrem')]
    procedure ClearEmailLoggingSetup(var MarketingSetup: Record "Marketing Setup")
    begin
        SendTraceTag('0000BYG', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ClearEmailLoggingSetupTxt, DataClassification::SystemMetadata);

        Clear(MarketingSetup."Queue Folder Path");
        if MarketingSetup."Queue Folder UID".HasValue then
            Clear(MarketingSetup."Queue Folder UID");

        Clear(MarketingSetup."Storage Folder Path");
        if MarketingSetup."Storage Folder UID".HasValue then
            Clear(MarketingSetup."Storage Folder UID");

        Clear(MarketingSetup."Exchange Account User Name");
        Clear(MarketingSetup."Exchange Service URL");
        Clear(MarketingSetup."Autodiscovery E-Mail Address");
        Clear(MarketingSetup."Email Batch Size");

        if not IsNullGuid(MarketingSetup."Exchange Account Password Key") then
            IsolatedStorageManagement.Delete(MarketingSetup."Exchange Account Password Key", DATASCOPE::Company);
        Clear(MarketingSetup."Exchange Account Password Key");

        MarketingSetup.Modify();
        Commit();
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure SetupEmailLoggingFolderMarketingSetup(RootFolderName: Text; QueueFolderName: Text; StorageFolderName: Text)
    var
        MarketingSetup: Record "Marketing Setup";
        TempExchangeFolder: Record "Exchange Folder" temporary;
        ExchangeWebServicesClient: Codeunit "Exchange Web Services Client";
        OAuthCredentials: DotNet OAuthCredentials;
        Token: Text;
    begin
        SendTraceTag('0000BYH', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, SetupEmailLoggingTxt, DataClassification::SystemMetadata);

        if not MarketingSetup.Get then begin
            SendTraceTag('0000BYI', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CannotFindMarketingSetupTxt, DataClassification::SystemMetadata);
            exit;
        end;

        GetClientCredentialsAccessToken(MarketingSetup.GetExchangeTenantId(), Token);
        OAuthCredentials := OAuthCredentials.OAuthCredentials(Token);
        ExchangeWebServicesClient.InitializeOnServerWithImpersonation(
          TempOfficeAdminCredentials.Email, GetDomainFromEmail(TempOfficeAdminCredentials.Email), OAuthCredentials);
        ExchangeWebServicesClient.ValidateCredentialsOnServer();
        ExchangeWebServicesClient.GetPublicFolders(TempExchangeFolder);
        TempExchangeFolder.Get(StrSubstNo(RootFolderPathTemplateTxt, RootFolderName));
        ExchangeWebServicesClient.GetPublicFolders(TempExchangeFolder);
        TempExchangeFolder.Get(StrSubstNo(PublicFolderPathTemplateTxt, RootFolderName, QueueFolderName));
        TempExchangeFolder.CalcFields("Unique ID");
        MarketingSetup.SetQueueFolder(TempExchangeFolder);
        TempExchangeFolder.Get(StrSubstNo(PublicFolderPathTemplateTxt, RootFolderName, StorageFolderName));
        TempExchangeFolder.CalcFields("Unique ID");
        MarketingSetup.SetStorageFolder(TempExchangeFolder);
    end;

    [Scope('OnPrem')]
    procedure GetExchangeFolder(var ExchangeWebServicesClient: Codeunit "Exchange Web Services Client"; var ExchangeFolder: Record "Exchange Folder"; FoldersCaption: Text): Boolean
    var
        ExchangeFoldersPage: Page "Exchange Folders";
        FolderID: Text;
    begin
        ExchangeFoldersPage.Initialize(ExchangeWebServicesClient, FoldersCaption);
        ExchangeFoldersPage.LookupMode(true);
        if Action::LookupOK = ExchangeFoldersPage.RunModal() then begin
            ExchangeFoldersPage.GetRecord(ExchangeFolder);
            FolderID := ExchangeFolder.ReadUniqueID();
            if not ExchangeWebServicesClient.FolderExists(FolderID) then begin
                SendTraceTag('0000D9L', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, StrSubstNo(FolderDoesNotExistTxt, FolderID, ExchangeFolder.FullPath), DataClassification::CustomerContent);
                Error(FolderDoesNotExistErr);
            end;
            exit(true);
        end;
        exit(false);
    end;

    procedure GetDomainFromEmail(Email: Text): Text
    begin
        exit(DelStr(Email, 1, StrPos(Email, '@')));
    end;

    procedure SetDeployCredentials(Username: Text[80]; Password: Text[30])
    begin
        SendTraceTag('0000BYJ', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, SetDeployCredentialsTxt, DataClassification::SystemMetadata);
        ExchangePowerShellRunner.SetCredentials(Username, Password);
    end;

    procedure CreateEmailLoggingJobQueueSetup()
    var
        JobQueueEntry: Record "Job Queue Entry";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        SendTraceTag('0000BYK', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CreateEmailLoggingJobTxt, DataClassification::SystemMetadata);

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Email Logging Context Adapter");
        JobQueueEntry.DeleteTasks();

        WorkflowSetup.CreateJobQueueEntry(
          JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Email Logging Context Adapter",
          '',
          CreateDateTime(Today, Time + 60000),
          10);
    end;

    [Scope('OnPrem')]
    procedure DeleteEmailLoggingJobQueueSetup()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SendTraceTag('0000CIO', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, DeleteEmailLoggingJobTxt, DataClassification::SystemMetadata);
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Email Logging Context Adapter");
        JobQueueEntry.DeleteTasks();
    end;

    [Scope('OnPrem')]
    procedure ClosePSConnection()
    begin
        SendTraceTag('0000BYL', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CloseConnectionTxt, DataClassification::SystemMetadata);
        if Initialized then
            ExchangePowerShellRunner.RemoveRemoteConnectionInformation;
        Initialized := false;
    end;

    [Scope('OnPrem')]
    procedure PromptClientCredentials(var ClientId: Text[250]; var ClientSecret: Text[250]; var RedirectURL: Text[2048]): Boolean
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        AzureADMgt: Codeunit "Azure AD Mgt.";
    begin
        TempNameValueBuffer.ID := 1;
        TempNameValueBuffer.Name := ClientId;
        TempNameValueBuffer.Value := ClientSecret;
        if RedirectURL = '' then
            TempNameValueBuffer."Value Long" := AzureADMgt.GetDefaultRedirectUrl()
        else
            TempNameValueBuffer."Value Long" := RedirectURL;
        TempNameValueBuffer.Insert();
        Commit();
        if Page.RunModal(Page::"Exchange Client Credentials", TempNameValueBuffer) <> Action::LookupOK then begin
            SendTraceTag('0000CIH', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, IgnoredClientCredentialsTxt, DataClassification::SystemMetadata);
            exit(false);
        end;
        if (TempNameValueBuffer.Name = '') or (TempNameValueBuffer.Value = '') then begin
            SendTraceTag('0000CII', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, InvalidClientCredentialsTxt, DataClassification::SystemMetadata);
            exit(false);
        end;
        if TempNameValueBuffer."Value Long" = '' then
            SendTraceTag('0000CL6', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, EmptyRedirectUrlTxt, DataClassification::SystemMetadata);

        ClientId := TempNameValueBuffer.Name;
        ClientSecret := TempNameValueBuffer.Value;
        RedirectURL := TempNameValueBuffer."Value Long";
        exit(true);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure PromptAdminConsent(var AccessToken: Text)
    begin
        PromptAdminConsent('', '', '', AccessToken);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure PromptAdminConsent(ClientId: Text; ClientSecret: Text; RedirectURL: Text; var AccessToken: Text)
    var
        OAuth2: Codeunit OAuth2;
        PromptInteraction: Enum "Prompt Interaction";
        AuthError: Text;
    begin
        if (ClientId = '') or (ClientSecret = '') then begin
            ClientId := GetClientId();
            ClientSecret := GetClientSecret();
        end;
        if RedirectURL = '' then
            RedirectURL := GetRedirectURL();

        SendTraceTag('0000D9M', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, AcquireAccessTokenTxt, DataClassification::SystemMetadata);
        OAuth2.AcquireTokenByAuthorizationCode(
                    ClientId,
                    ClientSecret,
                    CommonOAuthAuthorityUrlLbl,
                    RedirectURL,
                    ResourceUrlLbl,
                    PromptInteraction::Consent, AccessToken, AuthError
                );
        if AccessToken = '' then begin
            if AuthError <> '' then
                SendTraceTag('0000CFA', EmailLoggingTelemetryCategoryTxt, Verbosity::Error, AuthError, DataClassification::SystemMetadata)
            else
                SendTraceTag('0000CFB', EmailLoggingTelemetryCategoryTxt, Verbosity::Error, AuthTokenOrCodeNotReceivedErr, DataClassification::SystemMetadata);
            Error(AccessTokenErrMsg);
        end;
        SendTraceTag('0000D9N', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, AdminAccessTokenReceivedTxt, DataClassification::SystemMetadata);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetClientCredentialsAccessToken(TenantId: Text; var AccessToken: Text)
    begin
        GetClientCredentialsAccessToken('', '', '', TenantId, AccessToken);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetClientCredentialsAccessToken(ClientId: Text; ClientSecret: Text; RedirectURL: Text; TenantId: Text; var AccessToken: Text)
    var
        OAuth2: Codeunit OAuth2;
    begin
        if (ClientId = '') or (ClientSecret = '') then begin
            ClientId := GetClientId();
            ClientSecret := GetClientSecret();
        end;
        if RedirectURL = '' then
            RedirectURL := GetRedirectURL();

        OAuth2.AcquireTokenWithClientCredentials(
                    ClientId,
                    ClientSecret,
                    StrSubstNo(TenantOAuthAuthorityUrlLbl, TenantId),
                    RedirectURL,
                    ResourceUrlLbl,
                    AccessToken
                );
        if AccessToken = '' then begin
            SendTraceTag('0000CFC', EmailLoggingTelemetryCategoryTxt, Verbosity::Error, ClientCredentialsAccessTokenErr, DataClassification::SystemMetadata);
            Error(AccessTokenErrMsg);
        end;
        SendTraceTag('0000D9O', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ClientAccessTokenReceivedTxt, DataClassification::SystemMetadata);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure ExtractTenantIdFromAccessToken(var TenantId: Text; AccessToken: Text)
    begin
        if AccessToken <> '' then begin
            if TryExtractTenantIdFromAccessToken(TenantId, AccessToken) then begin
                if TenantId <> '' then begin
                    SendTraceTag('0000D9P', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, StrSubstNo(TenantIdExtractedTxt, TenantId), DataClassification::CustomerContent);
                    exit;
                end;
                SendTraceTag('0000CR1', EmailLoggingTelemetryCategoryTxt, Verbosity::Error, StrSubstNo(CannotExtractTenantIdTxt, AccessToken), DataClassification::CustomerContent);
            end else
                SendTraceTag('0000CR2', EmailLoggingTelemetryCategoryTxt, Verbosity::Error, StrSubstNo(CannotExtractTenantIdTxt, AccessToken), DataClassification::CustomerContent)
        end else
            SendTraceTag('0000CR3', EmailLoggingTelemetryCategoryTxt, Verbosity::Error, EmptyAccessTokenTxt, DataClassification::SystemMetadata);

        Error(CannotExtractTenantIdErr);
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure TryExtractTenantIdFromAccessToken(var TenantId: Text; AccessToken: Text)
    var
        JwtSecurityTokenHandler: DotNet JwtSecurityTokenHandler;
        JwtSecurityToken: DotNet JwtSecurityToken;
    begin
        JwtSecurityTokenHandler := JwtSecurityTokenHandler.JwtSecurityTokenHandler();
        JwtSecurityToken := JwtSecurityTokenHandler.ReadToken(AccessToken);
        JwtSecurityToken.Payload().TryGetValue('tid', TenantId);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetClientId(): Text
    var
        MarketingSetup: Record "Marketing Setup";
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInformation: Codeunit "Environment Information";
        ClientId: Text;
    begin
        if EnvironmentInformation.IsSaaS() then
            if not AzureKeyVault.GetAzureKeyVaultSecret(EmailLoggingClientIdAKVSecretNameLbl, ClientId) then
                SendTraceTag('0000CFD', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MissingClientIdTelemetryTxt, DataClassification::SystemMetadata)
            else begin
                SendTraceTag('0000CMD', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, InitializedClientIdTelemetryTxt, DataClassification::SystemMetadata);
                exit(ClientId);
            end;

        if MarketingSetup.Get() then begin
            ClientId := MarketingSetup."Exchange Client Id";
            if ClientId <> '' then begin
                SendTraceTag('0000CME', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, InitializedClientIdTelemetryTxt, DataClassification::SystemMetadata);
                exit(ClientId);
            end;
        end;

        OnGetEmailLoggingClientId(ClientId);
        if ClientId <> '' then begin
            SendTraceTag('0000CMF', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, InitializedClientIdTelemetryTxt, DataClassification::SystemMetadata);
            exit(ClientId);
        end;

        SendTraceTag('0000D9Q', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MissingClientIdTelemetryTxt, DataClassification::SystemMetadata);
        Error(MissingClientIdOrSecretErr);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetClientSecret(): Text
    var
        MarketingSetup: Record "Marketing Setup";
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInformation: Codeunit "Environment Information";
        ClientSecret: Text;
    begin
        if EnvironmentInformation.IsSaaS() then
            if not AzureKeyVault.GetAzureKeyVaultSecret(EmailLoggingClientSecretAKVSecretNameLbl, ClientSecret) then
                SendTraceTag('0000CFE', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MissingClientSecretTelemetryTxt, DataClassification::SystemMetadata)
            else begin
                SendTraceTag('0000CMG', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, InitializedClientSecretTelemetryTxt, DataClassification::SystemMetadata);
                exit(ClientSecret);
            end;

        if MarketingSetup.Get() then begin
            ClientSecret := MarketingSetup.GetExchangeClientSecret();
            if ClientSecret <> '' then begin
                SendTraceTag('0000CMH', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, InitializedClientSecretTelemetryTxt, DataClassification::SystemMetadata);
                exit(ClientSecret);
            end;
        end;

        OnGetEmailLoggingClientSecret(ClientSecret);
        if ClientSecret <> '' then begin
            SendTraceTag('0000CMI', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, InitializedClientSecretTelemetryTxt, DataClassification::SystemMetadata);
            exit(ClientSecret);
        end;

        SendTraceTag('0000D9R', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, MissingClientSecretTelemetryTxt, DataClassification::SystemMetadata);
        Error(MissingClientIdOrSecretErr);
    end;

    [Scope('OnPrem')]
    procedure RegisterAssistedSetup()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Language: Codeunit Language;
        ModuleInfo: ModuleInfo;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        CurrentGlobalLanguage: Integer;
    begin
        if AssistedSetup.Exists(Page::"Setup Email Logging") then
            exit;

        CurrentGlobalLanguage := GLOBALLANGUAGE;
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        AssistedSetup.Add(ModuleInfo.Id(), Page::"Setup Email Logging", SetupEmailLoggingTitleTxt, AssistedSetupGroup::ApprovalWorkflows, VideoUrlSetupEmailLoggingTxt, VideoCategory::ApprovalWorkflows, SetupEmailLoggingHelpTxt, SetupEmailLoggingDescriptionTxt);
        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        AssistedSetup.AddTranslation(Page::"Setup Email Logging", Language.GetDefaultApplicationLanguageId(), SetupEmailLoggingTitleTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetRedirectURL(): Text
    var
        MarketingSetup: Record "Marketing Setup";
        EnvironmentInformation: Codeunit "Environment Information";
        RedirectURL: Text;
    begin
        if EnvironmentInformation.IsSaaS() then
            exit(RedirectURL);

        if MarketingSetup.Get() then
            RedirectURL := MarketingSetup."Exchange Redirect URL";

        if RedirectURL = '' then
            OnGetEmailLoggingRedirectURL(RedirectURL);

        exit(RedirectURL);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEmailLoggingClientId(var ClientId: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEmailLoggingClientSecret(var ClientSecret: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEmailLoggingRedirectURL(var RedirectURL: Text)
    begin
    end;
}

