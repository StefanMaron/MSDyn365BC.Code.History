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

    [TryFunction]
    [Scope('OnPrem')]
    procedure InitializeExchangePSConnection()
    var
        NetworkCredential: DotNet NetworkCredential;
    begin
        if not Initialized then begin
            if not ExchangePowerShellRunner.PromptForCredentials then
                Error(GetLastErrorText);
            ExchangePowerShellRunner.GetCredentials(TempOfficeAdminCredentials);
            ExchangePowerShellRunner.InitializePSRunner;

            NetworkCredential := NetworkCredential.NetworkCredential(TempOfficeAdminCredentials.Email,
                TempOfficeAdminCredentials.GetPassword);
            ExchangeWebServicesClient.InitializeOnServer(
              TempOfficeAdminCredentials.Email, GetDomainFromEmail(TempOfficeAdminCredentials.Email), NetworkCredential);
            ExchangeWebServicesClient.ValidateCredentialsOnServer;
        end;
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
        Window.Open(PublicFoldersCreationProgressMsg);

        // Enabling Organization Customization to be able to add new Role Group
        Window.Update(1, 0);
        ExchangePowerShellRunner.AddCommand('Enable-OrganizationCustomization', true);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Add new Role Group for Public Folders
        Window.Update(1, 2000);
        ExchangePowerShellRunner.AddCommand('New-RoleGroup', true);
        ExchangePowerShellRunner.AddParameter('Name', 'Public Folders Management');
        ExchangePowerShellRunner.AddParameter('Roles', 'Public Folders');
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Add user as a member of created Role Group
        Window.Update(1, 3000);
        ExchangePowerShellRunner.AddCommand('Add-RoleGroupMember', true);
        ExchangePowerShellRunner.AddParameter('Identity', 'Public Folders Management');
        ExchangePowerShellRunner.AddParameter('Member', TempOfficeAdminCredentials.Email);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Creation of new Mail Box
        Window.Update(1, 4000);
        ExchangePowerShellRunner.AddCommand('New-Mailbox', true);
        ExchangePowerShellRunner.AddParameterFlag('PublicFolder');
        ExchangePowerShellRunner.AddParameter('Name', PublicMailBoxName);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Creation of new Root public Folder
        Window.Update(1, 5000);
        ExchangePowerShellRunner.AddCommand('New-PublicFolder', true);
        ExchangePowerShellRunner.AddParameter('Name', RootFolderName);
        ExchangePowerShellRunner.AddParameter('Mailbox', PublicMailBoxName);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        ExchangePowerShellRunner.GetResultEnumerator(Enum);

        // If returned nothing then check if folder already exists
        if not Enum.MoveNext then begin
            ExchangePowerShellRunner.ClearLog;
            ExchangePowerShellRunner.AddCommand('Get-PublicFolder', true);
            ExchangePowerShellRunner.AddParameter('Identity', StrSubstNo('\%1\', RootFolderName));
            ExchangePowerShellRunner.Invoke;
            ExchangePowerShellRunner.AwaitCompletion;

            ExchangePowerShellRunner.GetResultEnumerator(Enum);
            // If Public Folder does not exist then user has no admin rights
            if not Enum.MoveNext then begin
                ClosePSConnection;
                Error(AdminCredentialsRequiredErr);
            end;
        end;

        // Creation of new Queue public Folder /Root/Queue
        Window.Update(1, 6000);
        ExchangePowerShellRunner.AddCommand('New-PublicFolder', true);
        ExchangePowerShellRunner.AddParameter('Name', QueueFolderName);
        ExchangePowerShellRunner.AddParameter('Path', StrSubstNo('\%1\', RootFolderName));
        ExchangePowerShellRunner.AddParameter('Mailbox', PublicMailBoxName);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Creation of new Storage public Folder /Root/Storage
        Window.Update(1, 7000);
        ExchangePowerShellRunner.AddCommand('New-PublicFolder', true);
        ExchangePowerShellRunner.AddParameter('Name', StorageFolderName);
        ExchangePowerShellRunner.AddParameter('Path', StrSubstNo('\%1\', RootFolderName));
        ExchangePowerShellRunner.AddParameter('Mailbox', PublicMailBoxName);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Grant Queue public folder Mail Settings (email address)
        Window.Update(1, 8000);
        QueueFolderPath := StrSubstNo('\%1\%2\', RootFolderName, QueueFolderName);
        StorageFolderPath := StrSubstNo('\%1\%2\', RootFolderName, StorageFolderName);
        ExchangePowerShellRunner.AddCommand('Enable-MailPublicFolder', true);
        ExchangePowerShellRunner.AddParameter('Identity', QueueFolderPath);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        // Grant users to send email to mail enabled folder
        Window.Update(1, 9000);
        ExchangePowerShellRunner.AddCommand('Add-PublicFolderClientPermission', true);
        ExchangePowerShellRunner.AddParameter('Identity', QueueFolderPath);
        ExchangePowerShellRunner.AddParameter('AccessRights', 'CreateItems');
        ExchangePowerShellRunner.AddParameter('User', 'Anonymous');
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        ExchangePowerShellRunner.AddCommand('Add-PublicFolderClientPermission', true);
        ExchangePowerShellRunner.AddParameter('Identity', QueueFolderPath);
        ExchangePowerShellRunner.AddParameter('AccessRights', 'Owner');
        ExchangePowerShellRunner.AddParameter('User', TempOfficeAdminCredentials.Email);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        ExchangePowerShellRunner.AddCommand('Add-PublicFolderClientPermission', true);
        ExchangePowerShellRunner.AddParameter('Identity', StorageFolderPath);
        ExchangePowerShellRunner.AddParameter('AccessRights', 'Owner');
        ExchangePowerShellRunner.AddParameter('User', TempOfficeAdminCredentials.Email);
        ExchangePowerShellRunner.Invoke;
        ExchangePowerShellRunner.AwaitCompletion;

        Window.Close;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure CreateEmailLoggingRules(QueueEmailAddress: Text; IncomingRuleName: Text; OutgoingRuleName: Text)
    begin
        // Create new Transport Rule for Ingoing mail from outside organization
        if IncomingRuleName <> '' then begin
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
            ExchangePowerShellRunner.AddCommand('New-TransportRule', true);
            ExchangePowerShellRunner.AddParameter('Name', OutgoingRuleName);
            ExchangePowerShellRunner.AddParameter('FromScope', 'InOrganization');
            ExchangePowerShellRunner.AddParameter('SentToScope', 'NotInOrganization');
            ExchangePowerShellRunner.AddParameter('BlindCopyTo', QueueEmailAddress);
            ExchangePowerShellRunner.Invoke;
            ExchangePowerShellRunner.AwaitCompletion;
        end;
        ClosePSConnection;
    end;

    [Scope('OnPrem')]
    procedure ClearEmailLoggingSetup(var MarketingSetup: Record "Marketing Setup")
    begin
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
        if not MarketingSetup.Get then
            exit;

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
        ExchangePowerShellRunner.SetCredentials(Username, Password);
    end;

    procedure CreateEmailLoggingJobQueueSetup()
    var
        JobQueueEntry: Record "Job Queue Entry";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
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
        if Initialized then
            ExchangePowerShellRunner.RemoveRemoteConnectionInformation;
        Initialized := false;
    end;
}

