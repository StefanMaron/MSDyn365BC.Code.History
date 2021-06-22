codeunit 139314 "CRM Connection Wizard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Wizard]
    end;

    var
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPermissions: Codeunit "Library - Permissions";
        Assert: Codeunit Assert;
        InitialCRMUrlTxt: Label 'https://test.crm.dynamics.com', Locked = true;
        CorrectConnectionStringTxt: Label 'https://test.api.crm.dynamics.com/XRMServices/2011/Organization.svc';
        WrongConnectionStringErr: Label 'Wrong connection string generated';
        EmailAndServerAddressEmptyErr: Label 'The Integration User Email and Server Address fields must not be empty.';
        EnabledTxt: Label 'Enabled';
        CheckedTxt: Label 'Checked';
        VisibleTxt: Label 'Visible';
        ShouldBeErr: Label '%1 should be %2';
        ShouldNotBeErr: Label '%1 should not be %2';
        DynamicsCRMURLEmptyErr: Label 'You must specify the URL of your %1 solution.';
        ConfirmCredentialsDomainQst: Label 'The administrator user account and the integration user account appear to be from different domains. Are you sure that the credentials are correct?';
        WrongConfirmationErr: Label 'Wrong confirmation dialog text';
        WizardShouldNotBeClosedErr: Label 'Wizard should not be closed';
        EmptySynchUserCredentialsErr: Label 'You must specify the credentials for the user account for synchronization with %1.';
        WrongAdminCredentialsErr: Label 'Enter valid %1 administrator credentials.';
        ButtonTxt: Label 'Button';
        AllCredentialsRequiredErr: Label 'A %1 URL, user name and password are required to enable a connection.';
        TheRowDoesNotExistErr: Label 'The row does not exist';
        CryptographyManagement: Codeunit "Cryptography Management";
        CRMProductName: Codeunit "CRM Product Name";

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenNotFinished()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The CRM Connection Setup Wizard is run to the end but not finished
        RunWizardToCompletion(CRMConnectionSetupWizard);
        CRMConnectionSetupWizard.Close;

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"CRM Connection Setup Wizard"), 'CRM Connection Setup status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenExitRightAway()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The CRM Connection Setup Wizard wizard is exited right away
        CRMConnectionSetupWizard.Trap;
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");
        CRMConnectionSetupWizard.Close;

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"CRM Connection Setup Wizard"), 'CRM Connection Setup status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardNotExitedWhenConfirmIsNo()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The CRM Connection Setup Wizard is closed but closing is not confirmed
        CRMConnectionSetupWizard.Trap;
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");
        CRMConnectionSetupWizard.Close;

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"CRM Connection Setup Wizard"), 'CRM Connection Setup status should not be completed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyStatusCompletedWhenFinished()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The CRM Connection Setup Wizard is completed
        RunWizardToCompletion(CRMConnectionSetupWizard);
        CRMConnectionSetupWizard.ActionFinish.Invoke;

        // [THEN] Status of the setup step is set to Completed
        Assert.IsTrue(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"CRM Connection Setup Wizard"), 'CRM Connection Setup status should be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardWithExistedSetup()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [GIVEN] CRM Connection Setup already exists
        CreateCRMConnectionSetup(CRMConnectionSetup);
        // [WHEN] The CRM Connection Setup Wizard is closed but closing is not confirmed
        CRMConnectionSetupWizard.Trap;
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");

        // [THEN] Wizard "Server Address" = CRM Connection Setup."Server Address"
        CRMConnectionSetupWizard.ActionNext.Invoke;
        Assert.AreEqual(
          CRMConnectionSetup."Server Address", CRMConnectionSetupWizard.ServerAddress.Value, 'Values must be the same');
        // [THEN] Wizard "Email" = CRM Connection Setup."User Name"
        CRMConnectionSetupWizard.ActionNext.Invoke;
        Assert.AreEqual(
          CRMConnectionSetup."User Name", CRMConnectionSetupWizard.Email.Value, 'Values must be the same');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardEmptyCRMServerAddress()
    var
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO 180150] CRM Connection Wizard does not allow empty CRM URL server address
        Initialize;

        // [GIVEN] CRM Connection Setup Wizard is opened
        CRMConnectionSetupWizard.Trap;
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");

        // [WHEN] User does not fill Dynamics CRM URL and press Next
        CRMConnectionSetupWizard.ServerAddress.SetValue('');
        asserterror CRMConnectionSetupWizard.ActionNext.Invoke;

        // [THEN] Error message appears that Dynamics CRM URL should not be empty
        Assert.ExpectedError(StrSubstNo(DynamicsCRMURLEmptyErr, CRMProductName.SHORT));
    end;

    [Test]
    [HandlerFunctions('ConfirmNoCheckHandler,CRMAdminCredentialsModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyWizardDiffUsersDomainConfirmDialogNo()
    var
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO 180150] CRM Connection Wizard warning about different domains of sync and admin users is cancelled
        Initialize;

        // [GIVEN] CRM Connection Setup Wizard is opened
        // [GIVEN] Sync user = X@abc.com
        CRMConnectionSetupWizard.Trap;
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");

        CRMConnectionSetupWizard.ServerAddress.SetValue('https://test.dynamics.com');
        CRMConnectionSetupWizard.ActionNext.Invoke;
        CRMConnectionSetupWizard.Email.SetValue('abc@abc.com');
        CRMConnectionSetupWizard.Password.SetValue('***');
        // [WHEN] Finish pressed and user enters admin user = A@def.com;
        CRMConnectionSetupWizard.ActionFinish.Invoke;

        // [THEN] Confirmation Dialog warning about different domains of sync and admin users appear
        // [WHEN] No is pressed
        // [THEN] Final page of Wizard open
        Assert.IsTrue(CRMConnectionSetupWizard.Email.Visible, WizardShouldNotBeClosedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardWithExistedSetupCommonFieldsFalse()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO 180150] If common CRM Connection Setup fields are disabled then Wizard shows them as editable
        Initialize;

        // [GIVEN] CRM Connection Setup already exists
        // [GIVEN] Solution Imported = FALSE, Enable CRM Connection = FALSE, Sales Order Integration = FALSE
        CreateCRMConnectionSetup(CRMConnectionSetup);
        CRMConnectionSetup."Is Enabled" := false;
        CRMConnectionSetup."Is CRM Solution Installed" := false;
        CRMConnectionSetup."Is S.Order Integration Enabled" := false;
        CRMConnectionSetup.Modify;

        // [GIVEN] CRM Connection Setup Wizard is opened
        CRMConnectionSetupWizard.Trap;
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");
        CRMConnectionSetupWizard.ActionNext.Invoke;

        // [GIVEN] User password, Admin Email and password filled
        CRMConnectionSetupWizard.ActionNext.Invoke;
        CRMConnectionSetupWizard.Password.SetValue('ABC');

        // [WHEN] When final page of wizard opened
        CRMConnectionSetupWizard.ActionNext.Invoke;

        // [THEN] Import CRM Solution = FALSE and user can change it
        Assert.IsTrue(
          CRMConnectionSetupWizard.ImportCRMSolution.Enabled,
          StrSubstNo(ShouldBeErr, CRMConnectionSetupWizard.ImportCRMSolution.Caption, EnabledTxt));
        CRMConnectionSetupWizard.ImportCRMSolution.AssertEquals(true);

        // [THEN] Enable CRM Connection = FALSE and user can change it
        Assert.IsTrue(
          CRMConnectionSetupWizard.EnableCRMConnection.Enabled,
          StrSubstNo(ShouldBeErr, CRMConnectionSetupWizard.EnableCRMConnection.Caption, EnabledTxt));
        CRMConnectionSetupWizard.EnableCRMConnection.AssertEquals(true);

        // [THEN] EnableSalesOrderIntegration = FALSE and user can change it
        Assert.IsTrue(
          CRMConnectionSetupWizard.EnableSalesOrderIntegration.Enabled,
          StrSubstNo(ShouldBeErr, CRMConnectionSetupWizard.EnableSalesOrderIntegration.Caption, EnabledTxt));
        CRMConnectionSetupWizard.EnableSalesOrderIntegration.AssertEquals(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardWithExistedSetupCommonFieldsTrue()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO 180150] If common CRM Connection Setup fields are enabled then Wizard shows them as non-editable
        Initialize;

        // [GIVEN] CRM Connection Setup already exists
        // [GIVEN] Solution Imported = TRUE, Enable CRM Connection = TRUE, Sales Order Integration = TRUE
        CreateCRMConnectionSetup(CRMConnectionSetup);
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup."Is CRM Solution Installed" := true;
        CRMConnectionSetup."Is S.Order Integration Enabled" := true;
        CRMConnectionSetup.Modify;

        // [GIVEN] CRM Connection Setup Wizard is opened
        CRMConnectionSetupWizard.Trap;
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");
        CRMConnectionSetupWizard.ActionNext.Invoke;

        // [GIVEN] User password, Admin Email and password filled
        CRMConnectionSetupWizard.ActionNext.Invoke;
        CRMConnectionSetupWizard.Password.SetValue('ABC');

        // [WHEN] When final page of wizard opened
        CRMConnectionSetupWizard.ActionNext.Invoke;

        // [THEN] Import CRM Solution = TRUE and user cannot change it
        Assert.IsFalse(
          CRMConnectionSetupWizard.ImportCRMSolution.Enabled,
          StrSubstNo(ShouldNotBeErr, CRMConnectionSetupWizard.ImportCRMSolution.Caption, EnabledTxt));
        CRMConnectionSetupWizard.ImportCRMSolution.AssertEquals(true);

        // [THEN] Enable CRM Connection = TRUE and user cannot change it
        Assert.IsFalse(
          CRMConnectionSetupWizard.EnableCRMConnection.Enabled,
          StrSubstNo(ShouldNotBeErr, CRMConnectionSetupWizard.EnableCRMConnection.Caption, EnabledTxt));
        CRMConnectionSetupWizard.EnableCRMConnection.AssertEquals(true);

        // [THEN] EnableSalesOrderIntegration = True and user cannot change it
        Assert.IsFalse(
          CRMConnectionSetupWizard.EnableSalesOrderIntegration.Enabled,
          StrSubstNo(ShouldNotBeErr, CRMConnectionSetupWizard.EnableSalesOrderIntegration.Caption, EnabledTxt));
        CRMConnectionSetupWizard.EnableSalesOrderIntegration.AssertEquals(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,UsersCancelSelectionModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardODataUserCancelUserSelection()
    var
        User: Record User;
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO 180150] Select NAV OData User and cancel selection of user
        Initialize;

        // [GIVEN] User with no generated Access Key
        CreateUser(User, false);

        // [GIVEN] CRM Connection Wizard fields filled and on final page
        RunWizardToCompletion(CRMConnectionSetupWizard);

        // [WHEN] NAV OData user Lookup and does not select any user
        CRMConnectionSetupWizard.NAVODataUsername.Lookup;

        // [THEN] NAV OData User is not filled and NAV OData Access Key is empty
        CRMConnectionSetupWizard.NAVODataUsername.AssertEquals('');
        CRMConnectionSetupWizard.NAVODataAccesskey.AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,UsersModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardODataUserWithGeneratedKey()
    var
        User: Record User;
        IdentityManagement: Codeunit "Identity Management";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
        WebServiceKey: Text;
    begin
        // [SCENARIO 180150] Select NAV OData User with already assigned Access Key
        Initialize;

        // [GIVEN] User "U1" with already generated Access Key = "AK"
        CreateUser(User, true);
        WebServiceKey := IdentityManagement.GetWebServicesKey(User."User Security ID");

        // [GIVEN] CRM Connection Wizard fields filled and on final page
        RunWizardToCompletion(CRMConnectionSetupWizard);
        LibraryVariableStorage.Enqueue(User."User Security ID");

        // [WHEN] NAV OData user Lookup and select user
        CRMConnectionSetupWizard.NAVODataUsername.Lookup;

        // [THEN] NAV OData User = "U1" and NAV OData Access Key = "AK"
        CRMConnectionSetupWizard.NAVODataUsername.AssertEquals(User."User Name");
        CRMConnectionSetupWizard.NAVODataAccesskey.AssertEquals(WebServiceKey);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,UsersModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardODataUserUnselectPublishItemAvailability()
    var
        User: Record User;
        IdentityManagement: Codeunit "Identity Management";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
        WebServiceKey: Text;
    begin
        // [SCENARIO 180150] Unselect Publish Item Availability on CRM Connection Wizard
        Initialize;

        // [GIVEN] User "U1" with already generated Access Key = "AK"
        CreateUser(User, true);
        WebServiceKey := IdentityManagement.GetWebServicesKey(User."User Security ID");

        // [GIVEN] CRM Connection Wizard fields filled and on final page
        RunWizardToCompletion(CRMConnectionSetupWizard);
        LibraryVariableStorage.Enqueue(User."User Security ID");

        // [GIVEN] NAV OData User and Access Key are filled
        CRMConnectionSetupWizard.NAVODataUsername.Lookup;
        CRMConnectionSetupWizard.NAVODataUsername.AssertEquals(User."User Name");
        CRMConnectionSetupWizard.NAVODataAccesskey.AssertEquals(WebServiceKey);

        // [WHEN] Publish Item Availability Service is unchecked
        CRMConnectionSetupWizard.PublishItemAvailabilityService.SetValue(false);

        // [THEN] NAV OData User = '' and NAV OData Access Key = ''
        CRMConnectionSetupWizard.NAVODataUsername.AssertEquals('');
        CRMConnectionSetupWizard.NAVODataAccesskey.AssertEquals('');

        // [THEN] NAV OData User and NAV OData Access Key fields are not enabled
        Assert.IsFalse(
          CRMConnectionSetupWizard.NAVODataUsername.Enabled,
          StrSubstNo(ShouldNotBeErr, CRMConnectionSetupWizard.NAVODataUsername.Caption, EnabledTxt));
        Assert.IsFalse(
          CRMConnectionSetupWizard.NAVODataAccesskey.Enabled,
          StrSubstNo(ShouldNotBeErr, CRMConnectionSetupWizard.NAVODataAccesskey.Caption, EnabledTxt));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,UsersModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardODataUserWithGeneratedKeySAAS()
    var
        User: Record User;
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        IdentityManagement: Codeunit "Identity Management";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
        WebServiceKey: Text;
    begin
        // [SCENARIO 180150] When NAV on SAAS and User selects User other current - fill Access key
        Initialize;

        // [GIVEN] User "U1" with already generated Access Key = "AK"
        CreateUser(User, true);
        WebServiceKey := IdentityManagement.GetWebServicesKey(User."User Security ID");

        // [GIVEN] CRM Connection Wizard fields filled and on final page
        RunWizardToCompletion(CRMConnectionSetupWizard);
        LibraryVariableStorage.Enqueue(User."User Security ID");

        // [GIVEN] Run as SAAS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] User is selected
        CRMConnectionSetupWizard.NAVODataUsername.Lookup;
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [THEN] Access Key = "AK"
        CRMConnectionSetupWizard.NAVODataUsername.AssertEquals(User."User Name");
        CRMConnectionSetupWizard.NAVODataAccesskey.AssertEquals(WebServiceKey);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyWizardActionBack()
    var
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO 180150] User press back to return to previous Wizard page
        Initialize;

        // [GIVEN] CRM Connection Wizard is opened
        CRMConnectionSetupWizard.OpenEdit;

        // [GIVEN] Second page of Wizard is opened
        CRMConnectionSetupWizard.ServerAddress.SetValue('https://test.dynamics.com');
        CRMConnectionSetupWizard.ActionNext.Invoke;
        Assert.IsTrue(
          CRMConnectionSetupWizard.Email.Visible,
          StrSubstNo(ShouldBeErr, CRMConnectionSetupWizard.Email.Caption, VisibleTxt));

        // [WHEN] User press Back
        CRMConnectionSetupWizard.ActionBack.Invoke;

        // [THEN] First page of Wizard is opened.
        Assert.IsFalse(
          CRMConnectionSetupWizard.Email.Visible,
          StrSubstNo(ShouldNotBeErr, CRMConnectionSetupWizard.Email.Caption, VisibleTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyWizardActionAdvanced()
    var
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO 197282] Advanced action button appears on second page of Wizard
        Initialize;

        // [WHEN] CRM Connection Wizard is opened
        CRMConnectionSetupWizard.OpenEdit;

        // [THEN] Advanced action button is disabled
        Assert.IsFalse(
          CRMConnectionSetupWizard.ActionAdvanced.Visible,
          StrSubstNo(ShouldNotBeErr, ButtonTxt, VisibleTxt));

        // [WHEN] Second page of Wizard is opened
        CRMConnectionSetupWizard.ServerAddress.SetValue('https://test.dynamics.com');
        CRMConnectionSetupWizard.ActionNext.Invoke;

        // [THEN] Advanced action button is enabled
        Assert.IsTrue(
          CRMConnectionSetupWizard.ActionAdvanced.Visible,
          StrSubstNo(ShouldBeErr, ButtonTxt, VisibleTxt));

        // [WHEN] User presses on button "Advanced"
        CRMConnectionSetupWizard.ActionAdvanced.Invoke;

        // [THEN] Button "Simple" is visible
        Assert.IsTrue(
          CRMConnectionSetupWizard.ActionSimple.Visible,
          StrSubstNo(ShouldBeErr, ButtonTxt, VisibleTxt));

        // [WHEN] User presses on button "Simple"
        CRMConnectionSetupWizard.ActionSimple.Invoke;

        // [THEN] Button "Advanced" is visible
        Assert.IsTrue(
          CRMConnectionSetupWizard.ActionAdvanced.Visible,
          StrSubstNo(ShouldBeErr, ButtonTxt, VisibleTxt));

        // [WHEN] User press "Back" button
        CRMConnectionSetupWizard.ActionBack.Invoke;

        // [THEN] Both "Advanced" and "Simple" buttons not visible
        Assert.IsFalse(
          CRMConnectionSetupWizard.ActionAdvanced.Visible,
          StrSubstNo(ShouldNotBeErr, ButtonTxt, VisibleTxt));
        Assert.IsFalse(
          CRMConnectionSetupWizard.ActionSimple.Visible,
          StrSubstNo(ShouldNotBeErr, ButtonTxt, VisibleTxt));

        // [WHEN] User press "Back" button
        CRMConnectionSetupWizard.ActionNext.Invoke;

        // [THEN] "Advanced" is Visible, "Simple" - not visible
        Assert.IsTrue(
          CRMConnectionSetupWizard.ActionAdvanced.Visible,
          StrSubstNo(ShouldBeErr, ButtonTxt, VisibleTxt));
        Assert.IsFalse(
          CRMConnectionSetupWizard.ActionSimple.Visible,
          StrSubstNo(ShouldNotBeErr, ButtonTxt, VisibleTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyWizardEmptySynchUserCredentialsError()
    var
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO 197282] If synch user credentials not filled user cannot finish Wizard
        Initialize;

        // [GIVEN] CRM Connection Wizard is opened, synch user credentials not filled
        CRMConnectionSetupWizard.OpenEdit;
        CRMConnectionSetupWizard.ServerAddress.SetValue('https://test.dynamics.com');
        CRMConnectionSetupWizard.ActionNext.Invoke;

        // [WHEN] Finish action button is invoked
        asserterror CRMConnectionSetupWizard.ActionFinish.Invoke;

        // [THEN] Error message appears stating user should fill synch user credentials
        Assert.ExpectedError(StrSubstNo(EmptySynchUserCredentialsErr, CRMProductName.SHORT));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,CRMAdminCredentialsModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyWizardWrongAdminCredentialsError()
    var
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO 198614] CRM Connection Wizard shows error message on incorrect admin credentials
        Initialize;

        // [GIVEN] CRM Connection Setup Wizard is opened
        // [GIVEN] Dynamics CRM URL = 'https://test.dynamics.com'
        CRMConnectionSetupWizard.Trap;
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");

        CRMConnectionSetupWizard.ServerAddress.SetValue('https://test.dynamics.com');
        CRMConnectionSetupWizard.ActionNext.Invoke;
        CRMConnectionSetupWizard.Email.SetValue('abc@abc.com');
        CRMConnectionSetupWizard.Password.SetValue('***');

        // [WHEN] Finish pressed
        asserterror CRMConnectionSetupWizard.ActionFinish.Invoke;

        // [THEN] Error message appears stating that entered admin credentials are wrong
        Assert.ExpectedError(StrSubstNo(WrongAdminCredentialsErr, CRMProductName.SHORT));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMConnectionSetupCheckConnectRequiredFields()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Error message apprears when user email or server address are empty
        Initialize;
        asserterror CRMIntegrationManagement.CheckConnectRequiredFields(LibraryUtility.GenerateRandomText(10), '');
        Assert.ExpectedError(EmailAndServerAddressEmptyErr);
        asserterror CRMIntegrationManagement.CheckConnectRequiredFields('', LibraryUtility.GenerateRandomText(10));
        Assert.ExpectedError(EmailAndServerAddressEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMConnectionSetupConstructConnectionString()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Construct CRM connection string from user CRM URL
        Initialize;
        Assert.AreEqual(
          CorrectConnectionStringTxt, CRMIntegrationManagement.ConstructConnectionStringForSolutionImport(InitialCRMUrlTxt),
          WrongConnectionStringErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMConnectionSetupEnableCRMConnectionFromWizard()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        TempCRMConnectionSetup: Record "CRM Connection Setup" temporary;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] EnableCRMConnectionFromWizard() should execute on the context record
        Initialize;

        // [GIVEN] real CRMConnectionSetup has all credentials set
        CRMConnectionSetup.Init;
        CRMConnectionSetup."Server Address" := 'https://somedomain.dynamics.com';
        CRMConnectionSetup."User Name" := 'user@test.net';
        CRMConnectionSetup.SetPassword('password');
        CRMConnectionSetup.Insert;
        // [WHEN] EnableCRMConnectionFromWizard() on a empty CRMConnectionSetup
        TempCRMConnectionSetup.Insert;
        asserterror TempCRMConnectionSetup.EnableCRMConnectionFromWizard;
        // [THEN] Error: 'All credentials required to enable connection'
        Assert.ExpectedError(StrSubstNo(AllCredentialsRequiredErr, CRMProductName.SHORT));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMConnectionSetupUpdateFromWizard()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        TempCRMConnectionSetup: Record "CRM Connection Setup" temporary;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] UpdateFromWizard() should set credentials on the context record
        Initialize;
        CRMConnectionSetup."Server Address" := 'https://somedomain.dynamics.com';
        CRMConnectionSetup."User Name" := 'user@test.net';

        // [WHEN] UpdateFromWizard() on the temp record
        TempCRMConnectionSetup.UpdateFromWizard(CRMConnectionSetup, 'password');
        // [THEN] The temp record got set
        Assert.IsTrue(TempCRMConnectionSetup.Get, 'temp record should exist');
        TempCRMConnectionSetup.TestField("User Password Key");
        TempCRMConnectionSetup.TestField("Server Address", CRMConnectionSetup."Server Address");
        TempCRMConnectionSetup.TestField("User Name", CRMConnectionSetup."User Name");
        // [THEN] The real record is not inserted
        Assert.IsFalse(CRMConnectionSetup.Get, 'real record should not exist');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure CRMConnectionWizardFinishShouldUpdateRealRecord()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Step Finish should update the real record
        Initialize;
        LibraryCRMIntegration.ResetEnvironment;
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateCRMOrganization;

        // [GIVEN] CRM Connection Setup Wizard is opened
        CRMConnectionSetupWizard.OpenNew;
        // [GIVEN] Fill Office365 parameters
        CRMConnectionSetupWizard.ServerAddress.SetValue('@@test@@');
        CRMConnectionSetupWizard.ActionNext.Invoke;
        CRMConnectionSetupWizard.Password.SetValue('***');
        CRMConnectionSetupWizard.ActionNext.Invoke;
        CRMConnectionSetupWizard.ImportCRMSolution.SetValue(Format(false));

        // [WHEN] Finish pressed
        CRMConnectionSetupWizard.ActionFinish.Invoke;

        // [THEN] CRM Connection Setup, where password is set, connection is enabled
        CRMConnectionSetup.Get;
        CRMConnectionSetup.TestField("User Password Key");
        CRMConnectionSetup.TestField("Is Enabled");
        Assert.ExpectedMessage('Url', CRMConnectionSetup.GetConnectionString);
        // [THEN] SO integration is enabled
        CRMConnectionSetup.RefreshDataFromCRM;
        CRMConnectionSetup.TestField("Is S.Order Integration Enabled");
        // [THEN] user mapping is disabled
        CRMConnectionSetup.TestField("Is User Mapping Required", false);
        CRMConnectionSetup.TestField("Is User Mapped To CRM User", false);
        // [THEN] By Default "Proxy Version" = 9
        CRMConnectionSetup.TestField("Proxy Version", 9);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure CRMConnectionWizardCheckModifyCRMConnectionURL()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        Address: Text[250];
    begin
        // [FEATURE] [UT]
        // [SCENARIO] CRM Connection URL should comply with rules
        Initialize;

        // [GIVEN] Empty CRM Connection URL
        Address := '';
        // [WHEN] The URL is checked
        CRMIntegrationManagement.CheckModifyCRMConnectionURL(Address);
        // [THEN] The returned URL is empty
        Assert.AreEqual('', Address, WrongConnectionStringErr);
        // [GIVEN] CRM Connection URL = 'test.dynamics.com'
        Address := 'test.dynamics.com';
        // [WHEN] The URL is checked
        CRMIntegrationManagement.CheckModifyCRMConnectionURL(Address);
        // [THEN] The returned URL = 'https://test.dynamics.com'
        Assert.AreEqual('https://test.dynamics.com', Address, WrongConnectionStringErr);

        // [GIVEN] CRM Connection URL = 'http://test.com'
        Address := 'http://test1.com';
        // [WHEN] The URL is checked
        CRMIntegrationManagement.CheckModifyCRMConnectionURL(Address);
        // [THEN] Error message that security connection (https) is required
        Assert.AreEqual('http://test1.com', Address, WrongConnectionStringErr);

        // [GIVEN] CRM Connection URL = 'http://test.com:555/myOrg'
        Address := 'http://test2.com:555/myOrg';
        // [WHEN] The URL is checked
        CRMIntegrationManagement.CheckModifyCRMConnectionURL(Address);
        // [THEN] Error message that security connection (https) is required
        Assert.AreEqual('http://test2.com:555/myOrg', Address, WrongConnectionStringErr);

        // [GIVEN] CRM Connection URL = 'http://test.com:555/myOrg'
        Address := 'http://test3.com/myOrg';
        // [WHEN] The URL is checked
        CRMIntegrationManagement.CheckModifyCRMConnectionURL(Address);
        // [THEN] Error message that security connection (https) is required
        Assert.AreEqual('http://test3.com', Address, WrongConnectionStringErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMConnectionWizardItemAvailabilityWebservice()
    var
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO] 'Publish Item Availability' value depends on 'Import Solution' value.

        // [GIVEN] A newly setup company
        Initialize;

        // [GIVEN] The CRM Connection Setup Wizard is run to the finish step
        CRMConnectionSetupWizard.Trap;
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");
        with CRMConnectionSetupWizard do begin
            ServerAddress.SetValue('https://test.dynamics.com');
            ActionNext.Invoke; // Credentials page
            Email.SetValue('test@test.com');
            Password.SetValue('test1234');

            // [GIVEN] 'Import Solution' is unchecked
            ImportCRMSolution.SetValue(false);

            // [GIVEN] 'Publish Item Availability' is not enabled and unchecked
            Assert.IsFalse(
              PublishItemAvailabilityService.AsBoolean,
              StrSubstNo(ShouldNotBeErr, PublishItemAvailabilityService.Caption, CheckedTxt));
            Assert.IsFalse(
              PublishItemAvailabilityService.Enabled,
              StrSubstNo(ShouldNotBeErr, PublishItemAvailabilityService.Caption, CheckedTxt));

            // [WHEN] 'Import Solution' is checked
            ImportCRMSolution.SetValue(true);

            // [THEN] 'Publish Item Availability' is enabled and checked
            Assert.IsTrue(
              PublishItemAvailabilityService.AsBoolean,
              StrSubstNo(ShouldBeErr, PublishItemAvailabilityService.Caption, CheckedTxt));
            Assert.IsTrue(
              PublishItemAvailabilityService.Enabled,
              StrSubstNo(ShouldBeErr, PublishItemAvailabilityService.Caption, CheckedTxt));
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,CRMSystemUsersPageHandler')]
    [Scope('OnPrem')]
    procedure CRMConnectionWizardCRMUsersListOpened()
    var
        CRMSystemuser: array[4] of Record "CRM Systemuser";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [SCENARIO 208299] After CRM Connection wizard is finished user can see the list of CRM Users to couple them
        Initialize;
        LibraryCRMIntegration.ResetEnvironment;
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateCRMOrganization;

        // [GIVEN] CRM System User "CSU"
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser[1]);
        CRMSystemuser[1].IsLicensed := true;
        CRMSystemuser[1].IsIntegrationUser := false;
        CRMSystemuser[1].IsDisabled := false;
        CRMSystemuser[1].Modify;
        LibraryVariableStorage.Enqueue(CRMSystemuser[1].SystemUserId);
        LibraryVariableStorage.Enqueue(CRMSystemuser[1].InternalEMailAddress);

        // [GIVEN] CRM System User "NotLicensedUser" with IsLicensed = FALSE;
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser[2]);
        CRMSystemuser[2].IsLicensed := false;
        CRMSystemuser[2].Modify;
        LibraryVariableStorage.Enqueue(CRMSystemuser[2].SystemUserId);

        // [GIVEN] CRM System User "IntegrationUser" with IsIntegrationUser = TRUE;
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser[3]);
        CRMSystemuser[3].IsIntegrationUser := true;
        CRMSystemuser[3].Modify;
        LibraryVariableStorage.Enqueue(CRMSystemuser[3].SystemUserId);

        // [GIVEN] CRM System User "IsDisabledUser" with IsDisabled = TRUE;
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser[4]);
        CRMSystemuser[4].IsDisabled := true;
        CRMSystemuser[4].Modify;
        LibraryVariableStorage.Enqueue(CRMSystemuser[4].SystemUserId);

        // [WHEN] CRM Connection Wizard is finished
        CRMConnectionSetupWizard.OpenNew;
        CRMConnectionSetupWizard.ServerAddress.SetValue('@@test@@');
        CRMConnectionSetupWizard.ActionNext.Invoke;
        CRMConnectionSetupWizard.Password.SetValue('***');
        CRMConnectionSetupWizard.ActionNext.Invoke;
        CRMConnectionSetupWizard.ImportCRMSolution.SetValue(Format(false));
        CRMConnectionSetupWizard.ActionFinish.Invoke;

        // [THEN] User is asked if he want to map CRM User to SalesPersons
        // [THEN] After confirmation list of CRM Users is opened
        // [THEN] CSU CRM Systemuser is visible in the CRM Systemuser page list
        // [THEN] CRM Systemusers "NotLicensedUser", "IntegrationUser", "IsDisabledUser" not shown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMConnectionWizardAllowsAnyServerAddressNoSetup()
    var
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
        Email: Text;
    begin
        // [SCENARIO 211412] CRM Connection Wizard allow entering email for CRM server address not containing 'dynamics.com'
        Initialize;

        // [GIVEN] CRM Connection Setup Wizard is opened
        // [GIVEN] Server address = "https://crm.abc.com"

        CRMConnectionSetupWizard.Trap;
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");
        CRMConnectionSetupWizard.ServerAddress.SetValue('https://crm.abc.com');
        Email := 'abc@abc.com';
        CRMConnectionSetupWizard.ActionNext.Invoke;

        // [WHEN] Sync user email entered
        CRMConnectionSetupWizard.Email.SetValue(Email);

        // [THEN] No error appear
        CRMConnectionSetupWizard.Email.AssertEquals(Email);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMConnectionWizardAllowsAnyServerAddressSetupExists()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
        Email: Text;
    begin
        // [SCENARIO 211819] CRM Connection Wizard allow entering email for CRM server address not containing 'dynamics.com' when setup already exists
        Initialize;

        // [GIVEN] CRM Connection Setup exists and "Authentication Type" = AD
        CRMConnectionSetup.Init;
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::AD;
        CRMConnectionSetup.Insert;

        // [GIVEN] CRM Connection Setup Wizard is opened
        // [GIVEN] Server address = "https://crm.abc.com"
        CRMConnectionSetupWizard.Trap;
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");
        CRMConnectionSetupWizard.ServerAddress.SetValue('https://crm.abc.com');
        Email := 'abc@abc.com';
        CRMConnectionSetupWizard.ActionNext.Invoke;

        // [WHEN] Sync user email entered
        CRMConnectionSetupWizard.Email.SetValue(Email);

        // [THEN] No error appear
        CRMConnectionSetupWizard.Email.AssertEquals(Email);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure CRMConnectionWizardCheck8SDKVersion()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO 234755] Check selected sdk version 8 copied to connection setup
        Initialize;
        LibraryCRMIntegration.ResetEnvironment;
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateCRMOrganization;

        // [GIVEN] CRM Connection Setup Wizard is opened
        CRMConnectionSetupWizard.OpenNew;
        // [GIVEN] Fill Office365 parameters, SDK Version = 8
        CRMConnectionSetupWizard.ServerAddress.SetValue('@@test@@');
        CRMConnectionSetupWizard.ActionNext.Invoke;
        CRMConnectionSetupWizard.Password.SetValue('***');
        CRMConnectionSetupWizard.ActionNext.Invoke;
        CRMConnectionSetupWizard.ImportCRMSolution.SetValue(Format(false));
        CRMConnectionSetupWizard.SDKVersion.SetValue(8);
        // [WHEN] Finish pressed
        CRMConnectionSetupWizard.ActionFinish.Invoke;

        // [THEN] CRM Connection Setup has "Proxy Version" = 8
        CRMConnectionSetup.Get;
        CRMConnectionSetup.TestField("Proxy Version", 8);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure CRMConnectionWizardCheck9SDKVersion()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard";
    begin
        // [FEATURE] [Multiple SDK]
        // [SCENARIO 234755] SDK Version '8' can be changed to '9'
        Initialize;
        LibraryCRMIntegration.ResetEnvironment;
        LibraryCRMIntegration.ConfigureCRM;
        LibraryCRMIntegration.CreateCRMOrganization;

        // [GIVEN] CRM Connection Setup Wizard is opened
        CRMConnectionSetupWizard.OpenNew;
        // [GIVEN] Fill Office365 parameters
        CRMConnectionSetupWizard.ServerAddress.SetValue('@@test@@');
        CRMConnectionSetupWizard.ActionNext.Invoke;
        CRMConnectionSetupWizard.Password.SetValue('***');
        CRMConnectionSetupWizard.ActionNext.Invoke;
        CRMConnectionSetupWizard.ImportCRMSolution.SetValue(Format(false));
        // [GIVEN] SDK Version 9 is selected
        // First selected 8 as 9 is default value
        CRMConnectionSetupWizard.SDKVersion.SetValue(8);
        CRMConnectionSetupWizard.SDKVersion.SetValue(9);
        // [WHEN] Finish pressed
        CRMConnectionSetupWizard.ActionFinish.Invoke;

        // [THEN] CRM Connection Setup has "Proxy Version" = 9
        CRMConnectionSetup.Get;
        CRMConnectionSetup.TestField("Proxy Version", 9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_UpdateFromWizardSetOffice365AuthType()
    var
        TempCRMConnectionSetup: Record "CRM Connection Setup" temporary;
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 211819] UpdateFromWizard should set "Authentication Type" = Office365 by default
        Initialize;
        TempCRMConnectionSetup.Init;
        TempCRMConnectionSetup.Insert;

        // [WHEN] UpdateFromWizard is run
        CRMConnectionSetup.UpdateFromWizard(TempCRMConnectionSetup, '***');

        // [THEN] CRM Connection Setup "Authentication Type" = Office365 by default
        Assert.AreEqual(
          CRMConnectionSetup."Authentication Type"::Office365, CRMConnectionSetup."Authentication Type",
          StrSubstNo(ShouldBeErr, CRMConnectionSetup.FieldCaption("Authentication Type"), 'Office365'));
    end;

    local procedure Initialize()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        CRMConnectionSetup: Record "CRM Connection Setup";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        LibraryVariableStorage.Clear;
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider;
        LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
        CRMConnectionSetup.DeleteAll;
    end;

    local procedure RunWizardToCompletion(var CRMConnectionSetupWizard: TestPage "CRM Connection Setup Wizard")
    begin
        CRMConnectionSetupWizard.Trap;
        PAGE.Run(PAGE::"CRM Connection Setup Wizard");

        with CRMConnectionSetupWizard do begin
            ServerAddress.SetValue('https://test.dynamics.com');
            ActionNext.Invoke; // Credentials page
            Email.SetValue('test@test.com');
            Password.SetValue('test1234');
            ImportCRMSolution.SetValue(false);
            EnableSalesOrderIntegration.SetValue(false);
            EnableCRMConnection.SetValue(false);
            Assert.IsFalse(ActionNext.Enabled, 'Next should not be enabled at the end of the wizard');
        end;
    end;

    local procedure CreateCRMConnectionSetup(var CRMConnectionSetup: Record "CRM Connection Setup")
    begin
        CRMConnectionSetup.DeleteAll;

        CRMConnectionSetup.Init;
        CRMConnectionSetup."Server Address" := 'https://test.dynamics.com';
        CRMConnectionSetup."User Name" := 'test@test.com';
        CRMConnectionSetup.Insert;
    end;

    local procedure CreateUser(var User: Record User; GenerateNewKey: Boolean)
    var
        IdentityManagement: Codeunit "Identity Management";
    begin
        LibraryPermissions.CreateWindowsUser(User, UserId);
        IdentityManagement.ClearWebServicesKey(User."User Security ID");
        if GenerateNewKey then
            IdentityManagement.CreateWebServicesKeyNoExpiry(User."User Security ID");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
        if Question <> CryptographyManagement.GetEncryptionIsNotActivatedQst then
            Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoCheckHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if Question <> CryptographyManagement.GetEncryptionIsNotActivatedQst then
            Assert.AreEqual(ConfirmCredentialsDomainQst, Question, WrongConfirmationErr);
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYesNoForUsers(Question: Text[1024]; var Reply: Boolean)
    var
        User: Record User;
    begin
        Reply := not User.IsEmpty;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UsersModalPageHandler(var Users: TestPage Users)
    var
        User: Record User;
        GUIDVAR: Variant;
        UserSecurityId: Guid;
    begin
        LibraryVariableStorage.Dequeue(GUIDVAR);
        UserSecurityId := GUIDVAR;
        User.Get(UserSecurityId);
        Users.GotoRecord(User);
        Users.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UsersCancelSelectionModalPageHandler(var Users: TestPage Users)
    begin
        Users.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMAdminCredentialsModalPageHandler(var CRMAdministratorCredentials: TestPage "Dynamics CRM Admin Credentials")
    begin
        CRMAdministratorCredentials.Email.SetValue('abc@def.com');
        CRMAdministratorCredentials.Password.SetValue('abc');
        CRMAdministratorCredentials.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CRMSystemUsersPageHandler(var CRMSystemuserList: TestPage "CRM Systemuser List")
    var
        CRMGuidVAR: Variant;
        CRMGuid: Guid;
        InternalEmailAddress: Text;
    begin
        LibraryVariableStorage.Dequeue(CRMGuidVAR);
        CRMGuid := CRMGuidVAR;
        CRMSystemuserList.GotoKey(CRMGuid);
        InternalEmailAddress := LibraryVariableStorage.DequeueText;
        Assert.AreEqual(
          InternalEmailAddress, CRMSystemuserList.InternalEMailAddress.Value,
          StrSubstNo(ShouldBeErr, CRMSystemuserList.InternalEMailAddress.Caption, InternalEmailAddress));

        LibraryVariableStorage.Dequeue(CRMGuidVAR);
        CRMGuid := CRMGuidVAR;
        asserterror CRMSystemuserList.GotoKey(CRMGuid);
        Assert.ExpectedError(TheRowDoesNotExistErr);

        LibraryVariableStorage.Dequeue(CRMGuidVAR);
        CRMGuid := CRMGuidVAR;
        asserterror CRMSystemuserList.GotoKey(CRMGuid);
        Assert.ExpectedError(TheRowDoesNotExistErr);

        LibraryVariableStorage.Dequeue(CRMGuidVAR);
        CRMGuid := CRMGuidVAR;
        asserterror CRMSystemuserList.GotoKey(CRMGuid);
        Assert.ExpectedError(TheRowDoesNotExistErr);

        CRMSystemuserList.OK.Invoke;
    end;
}

