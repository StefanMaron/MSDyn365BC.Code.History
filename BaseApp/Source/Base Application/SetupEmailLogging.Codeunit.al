codeunit 1641 "Setup Email Logging"
{

    trigger OnRun()
    begin
    end;

    var
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
        ExchangeWebServicesClient: Codeunit "Exchange Web Services Client";
        ExchangePowerShellRunner: Codeunit "Exchange PowerShell Runner";
        PublicFoldersCreationProgressMsg: Label 'Public folder creation  @1@@@@@@@@@@@@@@@@@@';
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        Initialized: Boolean;
        AdminCredentialsRequiredErr: Label 'Could not create a public Exchange folder. Check if the credentials of the Exchange administrator are entered correctly.';
        EmailLoggingTelemetryCategoryTxt: Label 'AL Email Logging', Locked = true;
        CloseConnectionTxt: Label 'Close connection to Exchange.', Locked = true;
        InitializeConnectionTxt: Label 'Initialize connection to Exchange.', Locked = true;
        ConnectionNotInitializedTxt: Label 'Connection to Exchange is not initialized..', Locked = true;
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

    [TryFunction]
    [Scope('OnPrem')]
    procedure InitializeExchangePSConnection()
    var
        NetworkCredential: DotNet NetworkCredential;
    begin
        if not Initialized then begin
            SendTraceTag('0000BY5', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, InitializeConnectionTxt, DataClassification::SystemMetadata);

            if not ExchangePowerShellRunner.PromptForCredentials then begin
                SendTraceTag('0000BY6', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ConnectionNotInitializedTxt, DataClassification::SystemMetadata);
                Error(GetLastErrorText);
            end;
            ExchangePowerShellRunner.GetCredentials(TempOfficeAdminCredentials);
            ExchangePowerShellRunner.InitializePSRunner;

            NetworkCredential := NetworkCredential.NetworkCredential(TempOfficeAdminCredentials.Email,
                TempOfficeAdminCredentials.GetPassword);
            ExchangeWebServicesClient.InitializeOnServer(
              TempOfficeAdminCredentials.Email, GetDomainFromEmail(TempOfficeAdminCredentials.Email), NetworkCredential);
            ExchangeWebServicesClient.ValidateCredentialsOnServer;
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
            ExchangePowerShellRunner.AddParameter('Identity', StrSubstNo('\%1\', RootFolderName));
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
        ExchangePowerShellRunner.AddParameter('Path', StrSubstNo('\%1\', RootFolderName));
        ExchangePowerShellRunner.AddParameter('Mailbox', PublicMailBoxName);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Creation of new Storage public Folder /Root/Storage
        SendTraceTag('0000BY9', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CreateStoragePublicFolderTxt, DataClassification::SystemMetadata);
        Window.Update(1, 7000);
        ExchangePowerShellRunner.AddCommand('New-PublicFolder', true);
        ExchangePowerShellRunner.AddParameter('Name', StorageFolderName);
        ExchangePowerShellRunner.AddParameter('Path', StrSubstNo('\%1\', RootFolderName));
        ExchangePowerShellRunner.AddParameter('Mailbox', PublicMailBoxName);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Grant Queue public folder Mail Settings (email address)
        SendTraceTag('0000BY9', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CreatePublicFolderEmailSettingsTxt, DataClassification::SystemMetadata);
        Window.Update(1, 8000);
        QueueFolderPath := StrSubstNo('\%1\%2\', RootFolderName, QueueFolderName);
        StorageFolderPath := StrSubstNo('\%1\%2\', RootFolderName, StorageFolderName);
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
    procedure SetupEmailLoggingFolderMarketingSetup(RootFolderName: Text; QueueFolderName: Text; StorageFolderName: Text)
    var
        MarketingSetup: Record "Marketing Setup";
        TempExchangeFolder: Record "Exchange Folder" temporary;
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
        NetworkCredential: DotNet NetworkCredential;
    begin
        SendTraceTag('0000BYH', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, SetupEmailLoggingTxt, DataClassification::SystemMetadata);

        if not MarketingSetup.Get then begin
            SendTraceTag('0000BYI', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CannotFindMarketingSetupTxt, DataClassification::SystemMetadata);
            exit;
        end;

        ExchangePowerShellRunner.GetCredentials(TempOfficeAdminCredentials);
        NetworkCredential := NetworkCredential.NetworkCredential(TempOfficeAdminCredentials.Email,
            TempOfficeAdminCredentials.GetPassword);
        ExchangeWebServicesClient.InitializeOnServer(
          TempOfficeAdminCredentials.Email, GetDomainFromEmail(TempOfficeAdminCredentials.Email),
          NetworkCredential);
        ExchangeWebServicesClient.ValidateCredentialsOnServer;
        ExchangeWebServicesClient.GetPublicFolders(TempExchangeFolder);
        TempExchangeFolder.Get(StrSubstNo('\%1\', RootFolderName));
        ExchangeWebServicesClient.GetPublicFolders(TempExchangeFolder);
        TempExchangeFolder.Get(StrSubstNo('\%1\%2\', RootFolderName, QueueFolderName));
        TempExchangeFolder.CalcFields("Unique ID");
        MarketingSetup.SetQueueFolder(TempExchangeFolder);
        TempExchangeFolder.Get(StrSubstNo('\%1\%2\', RootFolderName, StorageFolderName));
        TempExchangeFolder.CalcFields("Unique ID");
        MarketingSetup.SetStorageFolder(TempExchangeFolder);
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
        WorkflowSetup.CreateJobQueueEntry(
          JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Email Logging Context Adapter",
          '',
          CreateDateTime(Today, Time + 60000),
          10);
    end;

    [Scope('OnPrem')]
    procedure ClosePSConnection()
    begin
        SendTraceTag('0000BYL', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, CloseConnectionTxt, DataClassification::SystemMetadata);
        if Initialized then
            ExchangePowerShellRunner.RemoveRemoteConnectionInformation;
        Initialized := false;
    end;
}

