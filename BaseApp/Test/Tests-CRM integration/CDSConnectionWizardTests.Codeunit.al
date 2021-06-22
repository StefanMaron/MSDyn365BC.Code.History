codeunit 139194 "CDS Connection Wizard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [cds Integration] [Wizard]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CryptographyManagement: Codeunit "Cryptography Management";
        CDSEnvironmentURLEmptyErr: Label 'You must specify the URL of your CDS environment.';
        VisibleTxt: Label 'Visible';
        ShouldBeErr: Label '%1 should be %2', Comment = '%1=filed name, %2=visibility';
        ShouldNotBeErr: Label '%1 should not be %2', Comment = '%1=filed name, %2=visibility';
        ButtonTxt: Label 'Button';
        WrongCredentialsErr: Label 'A URL, user name and password are required.';
        WrongConnectionStringErr: Label 'Wrong connection string generated';
        MustUseHttpsErr: Label 'The application is set up to support secure connections (HTTPS) to the CDS environment only. You cannot use HTTP.';

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenNotFinished()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The CDS Connection Setup Wizard is run to the end but not finished
        RunWizardToCompletion(CDSConnectionSetupWizard);
        CDSConnectionSetupWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(PAGE::"CDS Connection Setup Wizard"), 'CDS Connection Setup status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenExitRightAway()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The CDS Connection Setup Wizard wizard is exited right away
        CDSConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CDS Connection Setup Wizard");
        CDSConnectionSetupWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(PAGE::"CDS Connection Setup Wizard"), 'CDS Connection Setup status should not be completed.');
    end;

    //[Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardNotExitedWhenConfirmIsNo()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The CDS Connection Setup Wizard is closed but closing is not confirmed
        CDSConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CDS Connection Setup Wizard");
        CDSConnectionSetupWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(PAGE::"CDS Connection Setup Wizard"), 'CDS Connection Setup status should not be completed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardEmptyCDSServerAddress()
    var
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
    begin
        // [SCENARIO 180150] CDS Connection Wizard does not allow empty CDS URL server address
        Initialize();

        // [GIVEN] cds Connection Setup Wizard is opened
        CDSConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CDS Connection Setup Wizard");

        // [WHEN] User does not fill CDS Environment URL and press Next
        CDSConnectionSetupWizard.ServerAddress.SetValue('');
        asserterror CDSConnectionSetupWizard.ActionNext.Invoke();

        // [THEN] Error message appears that CDS Environment URL should not be empty
        Assert.ExpectedError(CDSEnvironmentURLEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyWizardActionBack()
    var
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
    begin
        // [SCENARIO 180150] User press back to return to previous Wizard page
        Initialize();

        // [GIVEN] CDS Connection Wizard is opened
        CDSConnectionSetupWizard.OpenEdit();

        // [GIVEN] Second page of Wizard is opened
        CDSConnectionSetupWizard.ServerAddress.SetValue('https://test.dynamics.com');
        CDSConnectionSetupWizard.ActionNext.Invoke();
        Assert.IsTrue(
          CDSConnectionSetupWizard.Email.Visible(),
          StrSubstNo(ShouldBeErr, CDSConnectionSetupWizard.Email.Caption(), VisibleTxt));

        // [WHEN] User press Back
        CDSConnectionSetupWizard.ActionBack.Invoke();

        // [THEN] First page of Wizard is opened.
        Assert.IsFalse(
          CDSConnectionSetupWizard.Email.Visible(),
          StrSubstNo(ShouldNotBeErr, CDSConnectionSetupWizard.Email.Caption(), VisibleTxt));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyWizardEmptyCredentialsError()
    var
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
    begin
        // [SCENARIO 197282] If credentials not filled user cannot finish Wizard
        Initialize();

        // [GIVEN] CDS Connection Wizard is opened, credentials not filled
        CDSConnectionSetupWizard.OpenEdit();
        CDSConnectionSetupWizard.ServerAddress.SetValue('https://test.dynamics.com');
        CDSConnectionSetupWizard.ActionNext.Invoke();

        // [WHEN] Finish action button is invoked
        asserterror CDSConnectionSetupWizard.ActionFinish.Invoke();

        // [THEN] Error message appears stating user should fill synch user credentials
        Assert.ExpectedError(WrongCredentialsErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure CDSConnectionWizardCheckModifyCDSConnectionURL()
    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        Address: Text[250];
    begin
        // [FEATURE] [UT]
        // [SCENARIO] CDS Connection URL should comply with rules
        Initialize();

        // [GIVEN] Empty CDS Connection URL
        Address := '';
        // [WHEN] The URL is checked
        CDSIntegrationImpl.CheckModifyConnectionURL(Address);
        // [THEN] The returned URL is empty
        Assert.AreEqual('', Address, WrongConnectionStringErr);
        // [GIVEN] CDS Connection URL = 'test.dynamics.com'
        Address := 'test.dynamics.com';
        // [WHEN] The URL is checked
        CDSIntegrationImpl.CheckModifyConnectionURL(Address);
        // [THEN] The returned URL = 'https://test.dynamics.com'
        Assert.AreEqual('https://test.dynamics.com', Address, WrongConnectionStringErr);

        // [GIVEN] CDS Connection URL = 'http://test.com'
        Address := 'http://test1.com';
        // [WHEN] The URL is checked
        asserterror CDSIntegrationImpl.CheckModifyConnectionURL(Address);
        // [THEN] Error message that security connection (https) is required
        Assert.ExpectedError(MustUseHttpsErr);

        // [GIVEN] CDS Connection URL = 'http://test.com:555/myOrg'
        Address := 'https://test2.com:555/myOrg';
        // [WHEN] The URL is checked
        CDSIntegrationImpl.CheckModifyConnectionURL(Address);
        // [THEN] Error message that security connection (https) is required
        Assert.AreEqual('https://test2.com:555/myOrg', Address, WrongConnectionStringErr);

        // [GIVEN] CDS Connection URL = 'http://test.com:555/myOrg'
        Address := 'https://test3.com/myOrg';
        // [WHEN] The URL is checked
        CDSIntegrationImpl.CheckModifyConnectionURL(Address);
        // [THEN] Error message that security connection (https) is required
        Assert.AreEqual('https://test3.com', Address, WrongConnectionStringErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CDSConnectionWizardAllowsAnyServerAddressNoSetup()
    var
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
        Email: Text;
    begin
        // [SCENARIO 211412] CDS Connection Wizard allow entering email for CDS server address not containing 'dynamics.com'
        Initialize();

        // [GIVEN] CDS Connection Setup Wizard is opened
        // [GIVEN] Server address = "https://cds.abc.com"

        CDSConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CDS Connection Setup Wizard");
        CDSConnectionSetupWizard.ServerAddress.SetValue('https://cds.abc.com');
        Email := 'abc@abc.com';
        CDSConnectionSetupWizard.ActionNext.Invoke();

        // [WHEN] Sync user email entered
        CDSConnectionSetupWizard.Email.SetValue(Email);

        // [THEN] No error appear
        CDSConnectionSetupWizard.Email.AssertEquals(Email);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CDSConnectionWizardAllowsAnyServerAddressSetupExists()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard";
        Email: Text;
    begin
        // [SCENARIO 211819] CDS Connection Wizard allow entering email for CDS server address not containing 'dynamics.com' when setup already exists
        Initialize();

        // [GIVEN] CDS Connection Setup exists and "Authentication Type" = AD
        CDSConnectionSetup.Init();
        CDSConnectionSetup."Authentication Type" := CDSConnectionSetup."Authentication Type"::AD;
        CDSConnectionSetup.Insert();

        // [GIVEN] CDS Connection Setup Wizard is opened
        // [GIVEN] Server address = "https://cds.abc.com"
        CDSConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CDS Connection Setup Wizard");
        CDSConnectionSetupWizard.ServerAddress.SetValue('https://cds.abc.com');
        Email := 'abc@abc.com';
        CDSConnectionSetupWizard.ActionNext.Invoke();

        // [WHEN] Sync user email entered
        CDSConnectionSetupWizard.Email.SetValue(Email);

        // [THEN] No error appear
        CDSConnectionSetupWizard.Email.AssertEquals(Email);
    end;

    local procedure Initialize()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        LibraryVariableStorage.Clear();
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider();
        LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
        CDSConnectionSetup.DeleteAll();
    end;

    local procedure RunWizardToCompletion(var CDSConnectionSetupWizard: TestPage "CDS Connection Setup Wizard")
    begin
        CDSConnectionSetupWizard.Trap();
        PAGE.Run(PAGE::"CDS Connection Setup Wizard");

        with CDSConnectionSetupWizard do begin
            ServerAddress.SetValue('https://test.dynamics.com');
            ActionNext.Invoke(); // Credentials page
            Email.SetValue('test@test.com');
            Password.SetValue('test1234');
            Assert.IsFalse(ActionNext.Enabled(), 'Next should not be enabled at the end of the wizard');
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
        if Question <> CryptographyManagement.GetEncryptionIsNotActivatedQst() then
            Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}