codeunit 139311 "Setup Email Log Wizard Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Setup Email Logging Wizard]
    end;

    var
        Assert: Codeunit Assert;
        SetupShouldNotBeCompletedErr: Label 'Email Logging Setup status should not be completed';
        LibraryUtility: Codeunit "Library - Utility";
        NextShouldNotBeEnabledErr: Label 'Next should not be enabled at the end of the wizard';
        LibraryRandom: Codeunit "Library - Random";
        TableFieldShouldBeEmptyErr: Label 'Marketing Setup field %1 should be empty';

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenNotFinished()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        SetupEmailLogging: TestPage "Setup Email Logging";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The Email Logging Setup Wizard is run to the end but not finished
        RunWizardToCompletion(SetupEmailLogging);
        SetupEmailLogging.Close;

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"Setup Email Logging"), SetupShouldNotBeCompletedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenExitRightAway()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        SetupEmailLogging: TestPage "Setup Email Logging";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The Email Logging Setup Wizard wizard is exited right away
        SetupEmailLogging.Trap;
        PAGE.Run(PAGE::"Setup Email Logging");
        SetupEmailLogging.Close;

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"Setup Email Logging"), SetupShouldNotBeCompletedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardNotExitedWhenConfirmIsNo()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        SetupEmailLogging: TestPage "Setup Email Logging";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The Email Logging Setup Wizard is closed but closing is not confirmed
        SetupEmailLogging.Trap;
        PAGE.Run(PAGE::"Setup Email Logging");
        SetupEmailLogging.Close;

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"Setup Email Logging"), SetupShouldNotBeCompletedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyUserHasEnteredEmailAndPassword()
    var
        SetupEmailLogging: TestPage "Setup Email Logging";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The user does not enter an email address and password
        SetupEmailLogging.Trap;
        PAGE.Run(PAGE::"Setup Email Logging");
        SetupEmailLogging.ActionNext.Invoke; // Enter credentials page

        // [THEN] Next button is disabled on the credentials page
        Assert.IsFalse(SetupEmailLogging.ActionNext.Enabled, '!');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyStatusCompletedWhenFinished()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        BaseAppID: Codeunit "BaseApp ID";
        SetupEmailLogging: TestPage "Setup Email Logging";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The Email Logging Setup Wizard is completed
        RunWizardToCompletion(SetupEmailLogging);
        SetupEmailLogging.ActionFinish.Invoke;

        // [THEN] Status of the setup step is set to Completed
        Assert.IsTrue(AssistedSetup.IsComplete(BaseAppID.Get(), PAGE::"Setup Email Logging"), SetupShouldNotBeCompletedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupEmailLoggingClearMarketingSetup()
    var
        MarketingSetup: Record "Marketing Setup";
        SetupEmailLogging: Codeunit "Setup Email Logging";
        OutStream: OutStream;
        EmptyGUID: Guid;
    begin
        // [SCENARIO] Email Logging Setup tab fields from Marketing Setup are cleared during Setup Email Logging
        Initialize;

        // [GIVEN] All fields on Email Logging Setup tab of Marketing Setup are filled
        MarketingSetup.Get;
        MarketingSetup."Queue Folder Path" :=
          PadStr(LibraryUtility.GenerateRandomText(10), MaxStrLen(MarketingSetup."Queue Folder Path"));
        MarketingSetup."Queue Folder UID".CreateOutStream(OutStream);
        OutStream.WriteText(LibraryUtility.GenerateRandomAlphabeticText(5, 1));
        MarketingSetup."Storage Folder Path" :=
          PadStr(LibraryUtility.GenerateRandomAlphabeticText(5, 1), MaxStrLen(MarketingSetup."Storage Folder Path"));
        MarketingSetup."Storage Folder UID".CreateOutStream(OutStream);
        OutStream.WriteText(LibraryUtility.GenerateRandomAlphabeticText(5, 1));
        MarketingSetup."Exchange Account User Name" :=
          PadStr(LibraryUtility.GenerateRandomAlphabeticText(5, 1), MaxStrLen(MarketingSetup."Exchange Account User Name"));
        MarketingSetup."Exchange Service URL" :=
          PadStr(LibraryUtility.GenerateRandomAlphabeticText(5, 1), MaxStrLen(MarketingSetup."Exchange Service URL"));
        MarketingSetup."Autodiscovery E-Mail Address" :=
          PadStr(LibraryUtility.GenerateRandomAlphabeticText(5, 1), MaxStrLen(MarketingSetup."Autodiscovery E-Mail Address"));
        MarketingSetup."Email Batch Size" := LibraryRandom.RandInt(10);
        MarketingSetup.SetExchangeAccountPassword(LibraryUtility.GenerateRandomText(10));
        MarketingSetup.Modify;
        MarketingSetup.Get;

        // [WHEN] Setup Email Logging is run
        SetupEmailLogging.ClearEmailLoggingSetup(MarketingSetup);

        // [THEN] All fields are cleared
        Assert.AreEqual(
          '', MarketingSetup."Queue Folder Path",
          StrSubstNo(TableFieldShouldBeEmptyErr, MarketingSetup.FieldCaption("Queue Folder Path")));
        Assert.AreEqual(
          '', MarketingSetup."Storage Folder Path",
          StrSubstNo(TableFieldShouldBeEmptyErr, MarketingSetup.FieldCaption("Storage Folder Path")));
        Assert.AreEqual(
          '', MarketingSetup."Exchange Account User Name",
          StrSubstNo(TableFieldShouldBeEmptyErr, MarketingSetup.FieldCaption("Exchange Account User Name")));
        Assert.AreEqual(
          '', MarketingSetup."Exchange Service URL",
          StrSubstNo(TableFieldShouldBeEmptyErr, MarketingSetup.FieldCaption("Exchange Service URL")));
        Assert.AreEqual(
          '', MarketingSetup."Exchange Account User Name",
          StrSubstNo(TableFieldShouldBeEmptyErr, MarketingSetup.FieldCaption("Exchange Account User Name")));
        Assert.AreEqual(
          0, MarketingSetup."Email Batch Size",
          StrSubstNo(TableFieldShouldBeEmptyErr, MarketingSetup.FieldCaption("Email Batch Size")));
        Assert.AreEqual(
          EmptyGUID, MarketingSetup."Exchange Account Password Key",
          StrSubstNo(TableFieldShouldBeEmptyErr, MarketingSetup.FieldCaption("Exchange Account Password Key")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupEmailLoggingGetDomainFromEmail()
    var
        SetupEmailLogging: Codeunit "Setup Email Logging";
        Email: Text;
        Domain: Text;
    begin
        // [SCENARIO] Domain name should be selected from email address
        Initialize;

        // [GIVEN] Domain "Z" in Email address "B@Z"
        Domain := LibraryUtility.GenerateRandomAlphabeticText(5, 1);
        Email := LibraryUtility.GenerateRandomAlphabeticText(5, 1) + '@' + Domain;

        // [WHEN] GetDomainFromEmail function is run for Email "B@Z"
        // [THEN] The function returns "Z"
        Assert.AreEqual(Domain, SetupEmailLogging.GetDomainFromEmail(Email), '!');
    end;

    local procedure RunWizardToCompletion(var SetupEmailLogging: TestPage "Setup Email Logging")
    var
        SetupEmailLoggingPage: Page "Setup Email Logging";
    begin
        SetupEmailLogging.Trap;
        SetupEmailLoggingPage.SkipDeploymentToExchange(true);
        SetupEmailLoggingPage.Run;

        with SetupEmailLogging do begin
            ActionNext.Invoke; // Credentials page
            Email.SetValue(LibraryUtility.GenerateRandomText(10));
            Password.SetValue(LibraryUtility.GenerateRandomText(10));
            ActionNext.Invoke; // Public folders setup page
            ActionNext.Invoke; // Email rules setup page
            ActionNext.Invoke; // Final page
            Assert.IsFalse(ActionNext.Enabled, NextShouldNotBeEnabledErr);
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

