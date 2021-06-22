codeunit 139310 "Exchange Setup Wizard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Exchange Setup Wizard]
    end;

    var
        Assert: Codeunit Assert;
        EmailPasswordMissingErr: Label 'Please enter a valid email address and password.';
        LibraryAzureADAuthFlow: Codeunit "Library - Azure AD Auth Flow";
        DeploymentModeOption: Option User,Organization;
        UsernamePasswordMissingErr: Label 'Please enter a valid domain username and password.';
        OAuthInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenNotFinished()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        ExchangeSetupWizard: TestPage "Exchange Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The Exchange Setup Wizard is run to the end but not finished
        RunWizardToCompletion(ExchangeSetupWizard);
        ExchangeSetupWizard.Close;

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"Exchange Setup Wizard"), 'Exchange Setup status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenExitRightAway()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        ExchangeSetupWizard: TestPage "Exchange Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The Exchange Setup Wizard wizard is exited right away
        ExchangeSetupWizard.Trap;
        PAGE.Run(PAGE::"Exchange Setup Wizard");
        ExchangeSetupWizard.Close;

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"Exchange Setup Wizard"), 'Exchange Setup status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardNotExitedWhenConfirmIsNo()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        ExchangeSetupWizard: TestPage "Exchange Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The Exchange Setup Wizard is closed but closing is not confirmed
        ExchangeSetupWizard.Trap;
        PAGE.Run(PAGE::"Exchange Setup Wizard");
        ExchangeSetupWizard.Close;

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"Exchange Setup Wizard"), 'Exchange Setup status should not be completed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUserHasEnteredEmailAndPassword()
    var
        ExchangeSetupWizard: TestPage "Exchange Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The user does not enter an email address and password
        ExchangeSetupWizard.Trap;
        PAGE.Run(PAGE::"Exchange Setup Wizard");
        with ExchangeSetupWizard do begin
            ActionNext.Invoke; // Setup for page
            DeploymentMode.SetValue(DeploymentModeOption::Organization);
            ActionNext.Invoke; // Use O365 page
            UseO365.SetValue(true);
            ActionNext.Invoke; // Enter credentials page
            asserterror ActionNext.Invoke;
        end;

        // [THEN] An error is thrown
        Assert.ExpectedError(EmailPasswordMissingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUserHasEnteredOnPremUserAndPassword()
    var
        ExchangeSetupWizard: TestPage "Exchange Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The user does not enter an email address and password
        ExchangeSetupWizard.Trap;
        PAGE.Run(PAGE::"Exchange Setup Wizard");
        with ExchangeSetupWizard do begin
            ActionNext.Invoke; // Setup for page
            DeploymentMode.SetValue(DeploymentModeOption::Organization);
            ActionNext.Invoke; // Use O365 page
            UseO365.SetValue(false);
            ActionNext.Invoke; // Enter credentials page
            asserterror ActionNext.Invoke;
        end;

        // [THEN] An error is thrown
        Assert.ExpectedError(UsernamePasswordMissingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnPremDeployUnavailableInSaaS()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        ExchangeSetupWizard: TestPage "Exchange Setup Wizard";
    begin
        // [GIVEN] A new company setup in SaaS
        Initialize;
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] The user chooses to perform an on-prem organization deploy 
        ExchangeSetupWizard.Trap;
        PAGE.Run(PAGE::"Exchange Setup Wizard");
        with ExchangeSetupWizard do begin
            ActionNext.Invoke; // Setup for page
            DeploymentMode.SetValue(DeploymentModeOption::Organization);
            ActionNext.Invoke; // Use O365 page

            // [THEN] An error is thrown when the user unchecks the O365 box
            asserterror UseO365.SetValue(false);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyBackShowsCorrectCredentialPrompt()
    var
        ExchangeSetupWizard: TestPage "Exchange Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The user does not enter an email address and password
        ExchangeSetupWizard.Trap;
        PAGE.Run(PAGE::"Exchange Setup Wizard");
        with ExchangeSetupWizard do begin
            ActionNext.Invoke; // Setup for page
            DeploymentMode.SetValue(DeploymentModeOption::Organization);
            ActionNext.Invoke; // Use O365 page
            UseO365.SetValue(false);
            ActionNext.Invoke; // Enter credentials page
            ExchangeUserName.SetValue('domain\test');
            ExchangePassword.SetValue('testpass');
            ExchangeEndpoint.SetValue('http://mail.cronus.com/PowerShell');
            ActionNext.Invoke; // Go to finish page
            ActionBack.Invoke; // Back to credential page
            ActionBack.Invoke; // Back to O365 page
            ActionBack.Invoke; // Back to deploy type page
            DeploymentMode.SetValue(DeploymentModeOption::User);
            ActionNext.Invoke; // Go to credential page

            // [THEN] The email and password fields are visible
            Assert.IsTrue(Email.Visible, 'Email credential field not visible.');
            Assert.IsTrue(Password.Visible, 'Password credential field not visible.');
            Assert.IsFalse(ExchangeEndpoint.Visible, 'Expected Exchange endpoint field to be hidden.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyStatusCompletedWhenFinished()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        ExchangeSetupWizard: TestPage "Exchange Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The Exchange Setup Wizard is completed
        RunWizardToCompletion(ExchangeSetupWizard);
        ExchangeSetupWizard.ActionFinish.Invoke;

        // [THEN] Status of the setup step is set to Completed
        Assert.IsTrue(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"Exchange Setup Wizard"), 'Exchange Setup status should be completed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUserNotPromptedForEmailAndPasswordWithToken()
    var
        ExchangeAddinSetup: Codeunit "Exchange Add-in Setup";
        ExchangeSetupWizard: TestPage "Exchange Setup Wizard";
    begin
        // [SCENARIO] User is not prompted for email and password when a token is available.

        // [GIVEN] An access token is available for the user.
        Initialize;
        InitializeOAuth(true);

        // [WHEN] The user runs the Exchange Setup Wizard page.
        ExchangeSetupWizard.Trap;
        PAGE.Run(PAGE::"Exchange Setup Wizard");
        with ExchangeSetupWizard do begin
            ActionNext.Invoke; // Setup for page
            DeploymentMode.SetValue(DeploymentModeOption::User);
            ActionNext.Invoke; // Receive sample email message page

            // [THEN] Email and Password fields are not displayed and Setup Emails is displayed
            Assert.IsFalse(Email.Visible, 'Email is visible');
            Assert.IsFalse(Password.Visible, 'Password is visble');
            if ExchangeAddinSetup.SampleEmailsAvailable then
                Assert.IsTrue(SetupEmails.Visible, 'Setup emails is not visible');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGettingStartedNoPromptForEmailAndPasswordWithToken()
    var
        ExchangeAddinSetup: Codeunit "Exchange Add-in Setup";
    begin
        // [SCENARIO] During the Getting Started Wizard the user is not prompted for email and password when a token is available.

        // [GIVEN] An access token is available for the user.
        Initialize;
        InitializeOAuth(true);

        // [WHEN] The user runs the Exchange Add-in Setup.
        ExchangeAddinSetup.PromptForCredentials;

        // [THEN] User is not prompted for Office 365 Credentials.
    end;

    local procedure RunWizardToCompletion(var ExchangeSetupWizard: TestPage "Exchange Setup Wizard")
    var
        ExchangeSetupWizardPage: Page "Exchange Setup Wizard";
    begin
        ExchangeSetupWizard.Trap;
        ExchangeSetupWizardPage.SkipDeploymentToExchange(true);
        ExchangeSetupWizardPage.Run;

        with ExchangeSetupWizard do begin
            ActionNext.Invoke; // Setup for page
            ActionBack.Invoke; // Welcome page
            ActionNext.Invoke; // Setup for page
            DeploymentMode.SetValue(DeploymentModeOption::Organization);
            ActionNext.Invoke; // O365 selection page
            UseO365.SetValue(false);
            ActionNext.Invoke; // Enter credentials page
            Email.SetValue('test@test.com');
            Password.SetValue('test1234');
            ActionNext.Invoke; // Receive sample email message page
            ActionNext.Invoke; // That's it page
            Assert.IsFalse(ActionNext.Enabled, 'Next should not be enabled at the end of the wizard');
        end;
    end;

    local procedure Initialize()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider;
        LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure InitializeOAuth(CachedTokenAvailable: Boolean)
    var
        LibraryO365Sync: Codeunit "Library - O365 Sync";
    begin
        Clear(LibraryAzureADAuthFlow);
        LibraryAzureADAuthFlow.SetTokenAvailable(false); // Never invoking authorization dialog, so dont expose token from auth code.
        LibraryAzureADAuthFlow.SetCachedTokenAvailable(CachedTokenAvailable);
        BindSubscription(LibraryAzureADAuthFlow);
        SetAuthFlowProvider(CODEUNIT::"Library - Azure AD Auth Flow");

        if OAuthInitialized then
            exit;

        LibraryO365Sync.SetupNavUser;

        OAuthInitialized := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure SetAuthFlowProvider(ProviderCodeunit: Integer)
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
        AzureADAppSetup: Record "Azure AD App Setup";
    begin
        AzureADMgtSetup.Get;
        AzureADMgtSetup."Auth Flow Codeunit ID" := ProviderCodeunit;
        AzureADMgtSetup.Modify;

        with AzureADAppSetup do
            if not Get then begin
                Init;
                "Redirect URL" := 'http://dummyurl:1234/Main_Instance1/WebClient/OAuthLanding.htm';
                "App ID" := CreateGuid;
                SetSecretKey(CreateGuid);
                Insert;
            end;
    end;
}

