codeunit 139309 "Email Setup Wizard Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Email Setup Wizard]
    end;

    var
        Assert: Codeunit Assert;
        EmailPasswordMissingErr: Label 'Please enter a valid email address and password.';
        EmailProvider: Option "Office 365",Other;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenNotFinished()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        EmailSetupWizard: TestPage "Email Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The Email Setup Wizard is run to the end but not finished
        RunWizardToCompletion(EmailSetupWizard);
        EmailSetupWizard.Close;

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"Email Setup Wizard"), 'Email Setup status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenExitRightAway()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        EmailSetupWizard: TestPage "Email Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The Email Setup Wizard wizard is exited right away
        EmailSetupWizard.Trap;
        PAGE.Run(PAGE::"Email Setup Wizard");
        EmailSetupWizard.Close;

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"Email Setup Wizard"), 'Email Setup status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardNotExitedWhenConfirmIsNo()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        EmailSetupWizard: TestPage "Email Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The Email Setup Wizard is closed but closing is not confirmed
        EmailSetupWizard.Trap;
        PAGE.Run(PAGE::"Email Setup Wizard");
        EmailSetupWizard.Close;

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"Email Setup Wizard"), 'Email Setup status should not be completed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUserHasEnteredEmailAndPassword()
    var
        EmailSetupWizard: TestPage "Email Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The user does not enter an email address and password
        EmailSetupWizard.Trap;
        PAGE.Run(PAGE::"Email Setup Wizard");
        with EmailSetupWizard do begin
            ActionNext.Invoke; // Choose email provider page
            "Email Provider".SetValue(EmailProvider::"Office 365");
            ActionNext.Invoke; // Enter credentials page
            asserterror ActionNext.Invoke;
        end;

        // [THEN] An error is thrown
        Assert.ExpectedError(EmailPasswordMissingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyStatusCompletedWhenFinished()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        EmailSetupWizard: TestPage "Email Setup Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The Email Setup Wizard is completed
        RunWizardToCompletion(EmailSetupWizard);
        EmailSetupWizard.ActionFinish.Invoke;

        // [THEN] Status of the setup step is set to Completed
        Assert.IsTrue(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"Email Setup Wizard"), 'Email Setup status should be completed.');
    end;

    local procedure RunWizardToCompletion(var EmailSetupWizard: TestPage "Email Setup Wizard")
    begin
        EmailSetupWizard.Trap;
        PAGE.Run(PAGE::"Email Setup Wizard");

        with EmailSetupWizard do begin
            ActionNext.Invoke; // Choose email provider page
            ActionBack.Invoke; // Welcome page
            ActionNext.Invoke; // Choose email provider page
            "Email Provider".SetValue(EmailProvider::"Office 365");
            ActionNext.Invoke; // Enter credentials page
            Email.SetValue('test@test.com');
            Password.SetValue('test1234');
            ActionNext.Invoke; // That's it page
            Assert.IsFalse(ActionNext.Enabled, 'Next should not be enabled at the end of the wizard');
        end;
    end;

    local procedure Initialize()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        AssistedSetupTestLibrary.DeleteAll();
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider;
        LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');
        AssistedSetupTestLibrary.CallOnRegister();
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
}

