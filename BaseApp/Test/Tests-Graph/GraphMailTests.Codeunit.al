codeunit 138926 "Graph Mail Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [EMail]
    end;

    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        Assert: Codeunit Assert;
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        SecretNameTxt: Label 'MailerResourceId';

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestHasConfiguration()
    var
        GraphMail: Codeunit "Graph Mail";
    begin
        // Setup
        LibraryLowerPermissions.SetInvoiceApp;

        // Execute
        Initialize;

        // Verify
        Assert.IsTrue(GraphMail.HasConfiguration, 'Graph Mail still does not have configuration after configuring it.');

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestEnabled()
    var
        GraphMailSetup: Record "Graph Mail Setup";
    begin
        // Setup
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        GraphMailSetup.Insert();

        Assert.IsFalse(GraphMailSetup.IsEnabled, '');

        // Execute
        GraphMailSetup.Initialize(true);
        GraphMailSetup.Enabled := true;
        GraphMailSetup.Modify();

        // Verify
        Assert.IsTrue(GraphMailSetup.IsEnabled, '');

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestSetup()
    var
        GraphMailSetup: Record "Graph Mail Setup";
    begin
        // Setup
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // Execute
        CreateInvoiceInWeb(false);

        // Verify
        Assert.IsTrue(GraphMailSetup.IsEnabled, '');

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,GraphSetupModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestSetupDialog()
    var
        O365SetupEmail: Codeunit "O365 Setup Email";
        GraphMail: Codeunit "Graph Mail";
    begin
        // Setup
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // Execute
        O365SetupEmail.SetupEmail(true);

        // Verify
        Assert.IsTrue(GraphMail.IsEnabled, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestSending()
    var
        GraphMailSetup: Record "Graph Mail Setup";
    begin
        // Setup
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // Execute
        CreateInvoiceInWeb(true);

        // Verify
        Assert.IsTrue(GraphMailSetup.IsEnabled, '');

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('GraphSetupNoLicenseModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestSmtpSetupTriggeredWhenUserHasNoExchangeLicense()
    var
        O365SetupEmail: Codeunit "O365 Setup Email";
        MailManagement: Codeunit "Mail Management";
        GraphMail: Codeunit "Graph Mail";
    begin
        // Setup
        Initialize;
        EventSubscriberInvoicingApp.SetGraphEndpointSuffix('nomail');
        LibraryLowerPermissions.SetInvoiceApp;

        // Execute
        O365SetupEmail.SetupEmail(true);

        // Verify
        Assert.IsTrue(MailManagement.IsSMTPEnabled, 'SMTP is not configured');
        Assert.IsFalse(GraphMail.IsEnabled, 'Graph mail was configured when the user has no license');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailSetupWizardPageHandler')]
    [Scope('OnPrem')]
    procedure TestCanSetUpSMTPFromGraph()
    var
        O365SetupEmail: Codeunit "O365 Setup Email";
        GraphMailSetup: TestPage "Graph Mail Setup";
        BCO365EmailSetupWizard: TestPage "BC O365 Email Setup Wizard";
    begin
        // [SCENARIO] User can set up SMTP email from Graph email settings
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] User opens Graph settings
        GraphMailSetup.OpenEdit;
        Assert.IsTrue(GraphMailSetup.ShowSmtp.Visible, 'SMTP email setup control is not visible.');
        GraphMailSetup.Close;

        // [WHEN] User drills down on the SMTP setup label
        // In Test Suite, it's impossible to set CloseAction and Field.SETVALUE at the same time: executing handler logic here
        BCO365EmailSetupWizard.OpenEdit;
        BCO365EmailSetupWizard.EmailSettingsWizardPage."Email Provider".SetValue('Office 365');
        BCO365EmailSetupWizard.EmailSettingsWizardPage.FromAccount.SetValue('test@microsoft.com');
        BCO365EmailSetupWizard.EmailSettingsWizardPage.Password.SetValue('Microsoft');
        BCO365EmailSetupWizard.OK.Invoke;
        GraphMailSetup.OpenEdit;
        GraphMailSetup.ShowSmtp.DrillDown;

        // [THEN] SMTP setup is successful
        Assert.IsTrue(O365SetupEmail.SMTPEmailIsSetUp, 'SMTP email not set up correctly.');

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure MailManagementIsGraphEnabledWhenGraphSetupNotExistUT()
    var
        GraphMailSetup: Record "Graph Mail Setup";
        MailManagement: Codeunit "Mail Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 372077] Run IsGraphEnabled function of codeunit Mail Management in case Graph Setup does not exist and Azure Key Vault is not configured.
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp();

        // [GIVEN] Graph Mail Setup table is empty.
        GraphMailSetup.DeleteAll();
        AzureKeyVaultTestLibrary.ClearSecrets();

        // [WHEN] Run IsGraphEnabled function of codeunit Mail Management.
        // [THEN] Function returns False.
        Assert.IsFalse(MailManagement.IsGraphEnabled(), '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure MailManagementIsGraphEnabledWhenGraphSetupNotExistKeyVaultConfiguredUT()
    var
        GraphMailSetup: Record "Graph Mail Setup";
        MailManagement: Codeunit "Mail Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 372077] Run IsGraphEnabled function of codeunit Mail Management in case Graph Setup does not exist and Azure Key Vault is configured.
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp();

        // [GIVEN] Graph Mail Setup table is empty. Azure Key Vault is configured (inside Initialize).
        GraphMailSetup.DeleteAll();

        // [WHEN] Run IsGraphEnabled function of codeunit Mail Management.
        // [THEN] Function returns False.
        Assert.IsFalse(MailManagement.IsGraphEnabled(), '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure MailManagementIsGraphEnabledWhenGraphSetupExistsKeyVaultNotConfiguredUT()
    var
        GraphMailSetup: Record "Graph Mail Setup";
        MailManagement: Codeunit "Mail Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 372077] Run IsGraphEnabled function of codeunit Mail Management in case Graph Setup exists and enabled and Azure Key Vault is not configured.
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp();

        // [GIVEN] Graph Mail Setup exists and enabled, but Azure Vault Key is not configured.
        GraphMailSetup.Insert();
        EnableGraphMailSetup();
        AzureKeyVaultTestLibrary.ClearSecrets();

        // [WHEN] Run IsGraphEnabled function of codeunit Mail Management.
        // [THEN] Function returns False.
        Assert.IsFalse(MailManagement.IsGraphEnabled(), '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure MailManagementIsGraphEnabledWhenGraphSetupExistsKeyVaultConfiguredUT()
    var
        GraphMailSetup: Record "Graph Mail Setup";
        MailManagement: Codeunit "Mail Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 372077] Run IsGraphEnabled function of codeunit Mail Management in case Graph Setup exists and enabled and Azure Key Vault is configured.
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp();

        // [GIVEN] Graph Mail Setup exists and enabled, Azure Vault Key is configured.
        GraphMailSetup.Insert();
        EnableGraphMailSetup();

        // [WHEN] Run IsGraphEnabled function of codeunit Mail Management.
        // [THEN] Function returns True.
        Assert.IsTrue(MailManagement.IsGraphEnabled(), '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailSetupWizardPageHandler(var BCO365EmailSetupWizard: TestPage "BC O365 Email Setup Wizard")
    begin
    end;

    local procedure CreateInvoiceInWeb(SendInvoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        ItemPrice: Decimal;
    begin
        ItemPrice := LibraryRandom.RandDec(100, 2);

        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".Value(LibraryInvoicingApp.CreateCustomerWithEmail);
        BCO365SalesInvoice.Lines.New;
        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        BCO365SalesInvoice.Lines."Unit Price".SetValue(ItemPrice);

        SalesHeader.FindLast;

        LibraryVariableStorage.Enqueue(SendInvoice);
        BCO365SalesInvoice.Post.Invoke;

        if not SendInvoice then
            Assert.IsTrue(SalesHeader.Find, 'The draft invoice no longer exists, it may have been posted.')
        else
            Assert.IsFalse(SalesHeader.Find, 'The draft invoice was not posted');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GraphSetupModalPageHandler(var GraphMailSetup: TestPage "Graph Mail Setup")
    begin
        Assert.AreEqual('Megan Bowen', GraphMailSetup."Sender Name".Value, '');
        Assert.AreEqual('MeganB@M365x214355.onmicrosoft.com', GraphMailSetup."Sender Email".Value, '');

        GraphMailSetup.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GraphSetupNoLicenseModalPageHandler(var BCO365EmailSetupWizard: TestPage "BC O365 Email Setup Wizard")
    begin
        BCO365EmailSetupWizard.EmailSettingsWizardPage.FromAccount.Value('a@b.com');
        BCO365EmailSetupWizard.EmailSettingsWizardPage.Password.Value('password');
        BCO365EmailSetupWizard.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    var
        SendMail: Boolean;
    begin
        SendMail := LibraryVariableStorage.DequeueBoolean;

        if not SendMail then begin
            O365SalesEmailDialog.Cancel.Invoke;
            exit;
        end;

        O365SalesEmailDialog.SendToText.SetValue('test@microsoft.com');
        O365SalesEmailDialog.OK.Invoke;
    end;

    local procedure Initialize()
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        GraphMailSetup: Record "Graph Mail Setup";
        MockAzureKeyVaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        TestSecret: Text;
    begin
        EventSubscriberInvoicingApp.Clear;

        if AzureADMgtSetup.Delete then;
        if GraphMailSetup.Delete then;

        MockAzureKeyVaultSecretProvider := MockAzureKeyVaultSecretProvider.MockAzureKeyVaultSecretProvider;
        MockAzureKeyVaultSecretProvider.AddSecretMapping('AllowedApplicationSecrets', SecretNameTxt + ',SmtpSetup');
        MockAzureKeyVaultSecretProvider.AddSecretMapping(SecretNameTxt, 'TESTRESOURCE');

        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyVaultSecretProvider);
        AzureKeyVault.GetAzureKeyVaultSecret(SecretNameTxt, TestSecret);

        Assert.AreEqual('TESTRESOURCE', TestSecret, 'Could not configure keyvault');

        if IsInitialized then
            exit;

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify();

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);
        IsInitialized := true;
    end;

    local procedure Cleanup()
    var
        MockAzureKeyVaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        TestSecret: Text;
    begin
        MockAzureKeyVaultSecretProvider := MockAzureKeyVaultSecretProvider.MockAzureKeyVaultSecretProvider;
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyVaultSecretProvider);

        Assert.IsFalse(AzureKeyVault.GetAzureKeyVaultSecret(SecretNameTxt, TestSecret), 'Cleanup failed');
    end;

    local procedure EnableGraphMailSetup()
    var
        GraphMailSetup: Record "Graph Mail Setup";
    begin
        GraphMailSetup.Get();
        GraphMailSetup.Initialize(false);
        GraphMailSetup.Enabled := true;
        GraphMailSetup.Modify();
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

