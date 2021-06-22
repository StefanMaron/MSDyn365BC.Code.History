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
        LibraryUtility: Codeunit "Library - Utility";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        LibraryRandom: Codeunit "Library - Random";
        SetupShouldNotBeCompletedErr: Label 'Email Logging Setup status should not be completed';
        NextShouldNotBeEnabledErr: Label 'Next should not be enabled at the end of the wizard';
        TableFieldShouldBeEmptyErr: Label 'Marketing Setup field %1 should be empty';
        EmptyClientIdErr: Label 'You must specify the Azure Active Directory ID.';
        EmptyClientSecretErr: Label 'You must specify the Azure Active Directory application secret.';

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenExitRightAway()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        SetupEmailLoggingPage: TestPage "Setup Email Logging";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The Email Logging Setup Wizard wizard is exited right away
        SetupEmailLoggingPage.Trap();
        PAGE.Run(PAGE::"Setup Email Logging");
        SetupEmailLoggingPage.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(PAGE::"Setup Email Logging"), SetupShouldNotBeCompletedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardNotExitedWhenConfirmIsNo()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        SetupEmailLoggingPage: TestPage "Setup Email Logging";
    begin
        // [GIVEN] A newly setup company
        Initialize;

        // [WHEN] The Email Logging Setup Wizard is closed but closing is not confirmed
        SetupEmailLoggingPage.Trap();
        PAGE.Run(PAGE::"Setup Email Logging");
        SetupEmailLoggingPage.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(PAGE::"Setup Email Logging"), SetupShouldNotBeCompletedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,HyperlinkHandler')]
    [Scope('OnPrem')]
    procedure VerifyNavigateToSignPageSaaS()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        SetupEmailLoggingPage: TestPage "Setup Email Logging";
    begin
        // [GIVEN] A newly setup company
        Initialize();
        // [GIVEN] In SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] User opens the assisted setup wizard
        SetupEmailLoggingPage.Trap();
        Page.Run(Page::"Setup Email Logging");
        // [THEN] Button Next is disabled
        Assert.IsFalse(SetupEmailLoggingPage.ActionNext.Enabled(), 'Action Next must be disabled.');
        // [THEN] Help link is enabled
        Assert.IsTrue(SetupEmailLoggingPage.HelpLink.Enabled(), 'Help link must be enabled.');
        // [THEN] Checkbox is disabled
        Assert.IsFalse(SetupEmailLoggingPage.ManualSetupDone.Editable(), 'Checkbox Manual Setup Done must be not editable.');

        // [WHEN] User clicks the help link
        SetupEmailLoggingPage.HelpLink.Drilldown();
        // [THEN] Button Next is disabled
        Assert.IsFalse(SetupEmailLoggingPage.ActionNext.Enabled(), 'Action Next must be disabled.');
        // [THEN] Checkbox is enabled
        Assert.IsTrue(SetupEmailLoggingPage.ManualSetupDone.Editable(), 'Checkbox Manual Setup Done must be editable.');

        // [WHEN] User confirms that manulal setup is done
        SetupEmailLoggingPage.ManualSetupDone.SetValue(true);
        // [THEN] Button Next is enabled
        Assert.IsTrue(SetupEmailLoggingPage.ActionNext.Enabled(), 'Action Next must be enabled.');

        // [WHEN] User clicks Next
        SetupEmailLoggingPage.ActionNext.Invoke();
        // [THEN] Button Next is disabled
        Assert.IsFalse(SetupEmailLoggingPage.ActionNext.Enabled(), 'Action Next must be disabled.');
        // [THEN] Sign-in link is visible and enabled
        Assert.IsTrue(SetupEmailLoggingPage.SignInAdminLink.Visible(), 'Sign-in link must be visible.');
        Assert.IsTrue(SetupEmailLoggingPage.SignInAdminLink.Enabled(), 'Sign-in link must be enabled.');

        // [WHEN] User closes the assisted setup wizard
        SetupEmailLoggingPage.Close();
        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(PAGE::"Setup Email Logging"), SetupShouldNotBeCompletedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,HyperlinkHandler,ClientCredentialsModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyNavigateToSignPageOnPrem()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        SetupEmailLoggingPage: TestPage "Setup Email Logging";
    begin
        // [GIVEN] A newly setup company
        Initialize();
        // [GIVEN] On-Prem
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] User opens the assisted setup wizard
        SetupEmailLoggingPage.Trap();
        Page.Run(Page::"Setup Email Logging");
        // [THEN] Button Next is disabled
        Assert.IsFalse(SetupEmailLoggingPage.ActionNext.Enabled(), 'Action Next must be disabled.');
        // [THEN] Help link is enabled
        Assert.IsTrue(SetupEmailLoggingPage.HelpLink.Enabled(), 'Help link must be enabled.');
        // [THEN] Checkbox is disabled
        Assert.IsFalse(SetupEmailLoggingPage.ManualSetupDone.Editable(), 'Checkbox Manual Setup Done must be not editable.');

        // [WHEN] User clicks the help link
        SetupEmailLoggingPage.HelpLink.Drilldown();
        // [THEN] Button Next is disabled
        Assert.IsFalse(SetupEmailLoggingPage.ActionNext.Enabled(), 'Action Next must be disabled.');
        // [THEN] Checkbox is disabled
        Assert.IsTrue(SetupEmailLoggingPage.ManualSetupDone.Editable(), 'Checkbox Manual Setup Done must be editable.');

        // [WHEN] User confirmed that manulal setup is done
        SetupEmailLoggingPage.ManualSetupDone.SetValue(true);
        // [THEN] Button Next is enabled
        Assert.IsTrue(SetupEmailLoggingPage.ActionNext.Enabled(), 'Action Next must be enabled.');

        // [WHEN] User clicks Next
        SetupEmailLoggingPage.ActionNext.Invoke();
        // [THEN] Button Next is disabled
        Assert.IsTrue(SetupEmailLoggingPage.ActionNext.Enabled(), 'Action Next must be enabled.');
        // [THEN] Sign-in link is visible and enabled
        Assert.IsTrue(SetupEmailLoggingPage.ClientCredentialsLink.Visible(), 'Client credentials link must be visible.');
        Assert.IsTrue(SetupEmailLoggingPage.ClientCredentialsLink.Enabled(), 'Client credentials link must be enabled.');

        // [WHEN] User clicks the client credentials link
        SetupEmailLoggingPage.ClientCredentialsLink.Drilldown();
        // [THEN] The page is opened

        // [WHEN] User fills all the fields on the client credentials page and closes the page
        // [THEN] Button Next is enabled
        Assert.IsTrue(SetupEmailLoggingPage.ActionNext.Enabled(), 'Action Next must be enabled.');

        // [WHEN] User clicks Next
        SetupEmailLoggingPage.ActionNext.Invoke();
        // [THEN] Sign-in link is visible and enabled
        Assert.IsTrue(SetupEmailLoggingPage.SignInAdminLink.Visible(), 'Sign-in link must be visible.');
        Assert.IsTrue(SetupEmailLoggingPage.SignInAdminLink.Enabled(), 'Sign-in link must be enabled.');

        // [WHEN] User closes the assisted setup wizard
        SetupEmailLoggingPage.Close();
        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(AssistedSetup.IsComplete(PAGE::"Setup Email Logging"), SetupShouldNotBeCompletedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyClientCredentialsClientIdMandatory()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        ExchangeClientCredentialsPage: TestPage "Exchange Client Credentials";
    begin
        // [GIVEN] A newly setup company
        Initialize();
        // [GIVEN] On-Prem
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] User opens the Exchange Client Credentials page
        TempNameValueBuffer.Insert();
        ExchangeClientCredentialsPage.Trap();
        Page.Run(Page::"Exchange Client Credentials", TempNameValueBuffer);

        // [WHEN] User fills all the fields except Client Secret and clicks OK
        ExchangeClientCredentialsPage.ClientId.SetValue('');
        ExchangeClientCredentialsPage.ClientSecret.SetValue(LibraryUtility.GenerateRandomAlphabeticText(5, 1));
        ExchangeClientCredentialsPage.RedirectURL.SetValue(LibraryUtility.GenerateRandomAlphabeticText(5, 1));
        asserterror ExchangeClientCredentialsPage.OK().Invoke();
        // [THEN] Error about empty Client ID
        Assert.ExpectedError(EmptyClientIdErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyClientCredentialsClientSecretMandatory()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        ExchangeClientCredentialsPage: TestPage "Exchange Client Credentials";
    begin
        // [GIVEN] A newly setup company
        Initialize();
        // [GIVEN] On-Prem
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] User opens the Exchange Client Credentials page
        TempNameValueBuffer.Insert();
        ExchangeClientCredentialsPage.Trap();
        Page.Run(Page::"Exchange Client Credentials", TempNameValueBuffer);

        // [WHEN] User fills all the fields except Client Secret and clicks OK
        ExchangeClientCredentialsPage.ClientId.SetValue(LibraryUtility.GenerateRandomAlphabeticText(5, 1));
        ExchangeClientCredentialsPage.ClientSecret.SetValue('');
        ExchangeClientCredentialsPage.RedirectURL.SetValue(LibraryUtility.GenerateRandomAlphabeticText(5, 1));
        asserterror ExchangeClientCredentialsPage.OK().Invoke();
        // [THEN] Error about empty Client Secret
        Assert.ExpectedError(EmptyClientSecretErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyClientCredentialsRedirectUrlOptional()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        ExchangeClientCredentialsPage: TestPage "Exchange Client Credentials";
    begin
        // [GIVEN] A newly setup company
        Initialize();
        // [GIVEN] On-Prem
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] User opens the Exchange Client Credentials page
        TempNameValueBuffer.Insert();
        ExchangeClientCredentialsPage.Trap();
        Page.Run(Page::"Exchange Client Credentials", TempNameValueBuffer);

        // [WHEN] User fills all the fields except Redirect URL and clicks OK
        ExchangeClientCredentialsPage.ClientId.SetValue(LibraryUtility.GenerateRandomAlphabeticText(5, 1));
        ExchangeClientCredentialsPage.ClientSecret.SetValue(LibraryUtility.GenerateRandomAlphabeticText(5, 1));
        ExchangeClientCredentialsPage.RedirectURL.SetValue('');
        ExchangeClientCredentialsPage.OK().Invoke();
        // [THEN] No errors
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyClearEmailLoggingFromMarketingSetupWhenDisabled()
    var
        MarketingSetup: Record "Marketing Setup";
        MarketingSetupPage: TestPage "Marketing Setup";
        SetupEmailLoggingPage: TestPage "Setup Email Logging";
    begin
        // [GIVEN] All fields on Email Logging Setup tab of Marketing Setup are filled, email logging is disabled
        FillEmailLoggingFields(false);

        // [WHEN] User opens Marketing Setup page
        MarketingSetupPage.Trap();
        Page.Run(Page::"Marketing Setup");
        // [THEN] Action Clear Email Logging Setup is enabled
        Assert.IsTrue(MarketingSetupPage."Clear EmailLogging Setup".Enabled(), 'Action Clear Email Logging Setup must be enabled.');

        // [WHEN] User invokes Clear Email Logging Setup action
        MarketingSetupPage."Clear EmailLogging Setup".Invoke();
        // [THEN] All fields on the page are cleared
        Assert.AreEqual('', MarketingSetupPage."Autodiscovery E-Mail Address".Value(), 'Autodiscovery E-Mail Address must be empty.');
        Assert.AreEqual('', MarketingSetupPage."Exchange Service URL".Value(), 'Exchange Service URL must be empty.');
        Assert.AreEqual('', MarketingSetupPage."Queue Folder Path".Value(), 'Queue Folder Path must be empty.');
        Assert.AreEqual('', MarketingSetupPage."Storage Folder Path".Value(), 'Storage Folder Path must be empty.');
        Assert.AreEqual(0, MarketingSetupPage."Email Batch Size".AsInteger(), 'Email Batch Size must be zero.');

        // [WHEN] User closes the page
        MarketingSetupPage.Close();
        // [THEN] All fields in the record are cleared
        MarketingSetup.Get();
        VerifyEmailLoggingFieldsEmpty(MarketingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCannotClearEmailLoggingFromMarketingSetupWhenEnabled()
    var
        MarketingSetup: Record "Marketing Setup";
        MarketingSetupPage: TestPage "Marketing Setup";
    begin
        // [GIVEN] All fields on Email Logging Setup tab of Marketing Setup are filled,  email logging is enabled
        FillEmailLoggingFields(true);

        // [WHEN] User opens Marketing Setup page
        MarketingSetupPage.Trap();
        Page.Run(Page::"Marketing Setup");

        // [THEN] Action Clear Email Logging Setup is disabled
        Assert.IsFalse(MarketingSetupPage."Clear EmailLogging Setup".Enabled(), 'Action Clear Email Logging Setup must be disabled.');

        MarketingSetupPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,AssistedSetupModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyRunAssistedSetupFromMarketingSetupWhenDisabled()
    var
        MarketingSetup: Record "Marketing Setup";
        MarketingSetupPage: TestPage "Marketing Setup";
        SetupEmailLoggingPage: TestPage "Setup Email Logging";
    begin
        // [GIVEN] All fields on Email Logging Setup tab of Marketing Setup are filled, email logging is disabled
        FillEmailLoggingFields(false);

        // [WHEN] User opens Marketing Setup page
        MarketingSetupPage.Trap();
        Page.Run(Page::"Marketing Setup");

        // [THEN] Action Email Logging Assisted Setup is enabled
        Assert.IsTrue(MarketingSetupPage."Email Logging Assisted Setup".Enabled(), 'Action Email Logging Assisted Setup must be enabled.');

        // [WHEN] User runs the Assisted Setup Wizard through the action
        SetupEmailLoggingPage.Trap();
        MarketingSetupPage."Email Logging Assisted Setup".Invoke();
        // [THEN] The Assisted Setup Wizard page is opened
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCannotRunAssistedSetupFromMarketingSetupWhenEnabled()
    var
        MarketingSetup: Record "Marketing Setup";
        MarketingSetupPage: TestPage "Marketing Setup";
    begin
        // [GIVEN] All fields on Email Logging Setup tab of Marketing Setup are filled,  email logging is enabled
        FillEmailLoggingFields(true);

        // [WHEN] User opens Marketing Setup page
        MarketingSetupPage.Trap();
        Page.Run(Page::"Marketing Setup");

        // [THEN] Action Email Logging Assisted Setup is disabled
        Assert.IsFalse(MarketingSetupPage."Email Logging Assisted Setup".Enabled(), 'Action Email Logging Assisted Setup must be disabled.');

        MarketingSetupPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupEmailLoggingClearMarketingSetup()
    var
        MarketingSetup: Record "Marketing Setup";
        SetupEmailLogging: Codeunit "Setup Email Logging";
    begin
        // [SCENARIO] Email Logging Setup tab fields from Marketing Setup are cleared during Setup Email Logging
        Initialize;

        // [GIVEN] All fields on Email Logging Setup tab of Marketing Setup are filled
        FillEmailLoggingFields(false);
        MarketingSetup.Get();

        // [WHEN] Setup Email Logging is run
        SetupEmailLogging.ClearEmailLoggingSetup(MarketingSetup);

        // [THEN] All fields are cleared
        VerifyEmailLoggingFieldsEmpty(MarketingSetup);
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

    local procedure FillEmailLoggingFields(Enabled: Boolean)
    var
        MarketingSetup: Record "Marketing Setup";
        SetupEmailLogging: Codeunit "Setup Email Logging";
        OutStream: OutStream;
    begin
        MarketingSetup.Get();
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
        MarketingSetup."Exchange Redirect URL" :=
            PadStr(LibraryUtility.GenerateRandomAlphabeticText(5, 1), MaxStrLen(MarketingSetup."Exchange Redirect URL"));
        MarketingSetup."Exchange Client Id" :=
            PadStr(LibraryUtility.GenerateRandomAlphabeticText(5, 1), MaxStrLen(MarketingSetup."Exchange Client Id"));
        MarketingSetup.SetExchangeClientSecret(LibraryUtility.GenerateRandomText(10));
        MarketingSetup.SetExchangeTenantId(LibraryUtility.GenerateRandomText(10));
        MarketingSetup."Email Logging Enabled" := Enabled;
        MarketingSetup.Modify();
    end;

    local procedure VerifyEmailLoggingFieldsEmpty(var MarketingSetup: Record "Marketing Setup")
    var
        EmptyGUID: Guid;
    begin
        Assert.AreEqual(
      '', MarketingSetup."Queue Folder Path",
      StrSubstNo(TableFieldShouldBeEmptyErr, MarketingSetup.FieldCaption("Queue Folder Path")));
        Assert.AreEqual(
          '', MarketingSetup."Storage Folder Path",
          StrSubstNo(TableFieldShouldBeEmptyErr, MarketingSetup.FieldCaption("Storage Folder Path")));
        Assert.AreEqual(
          '', MarketingSetup."Autodiscovery E-Mail Address",
          StrSubstNo(TableFieldShouldBeEmptyErr, MarketingSetup.FieldCaption("Autodiscovery E-Mail Address")));
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
        Assert.AreEqual(
          '', MarketingSetup."Exchange Redirect URL",
          StrSubstNo(TableFieldShouldBeEmptyErr, MarketingSetup.FieldCaption("Exchange Redirect URL")));
        Assert.AreEqual(
          '', MarketingSetup."Exchange Client Id",
          StrSubstNo(TableFieldShouldBeEmptyErr, MarketingSetup.FieldCaption("Exchange Client Id")));
        Assert.AreEqual(
          EmptyGUID, MarketingSetup."Exchange Client Secret Key",
          StrSubstNo(TableFieldShouldBeEmptyErr, MarketingSetup.FieldCaption("Exchange Client Secret Key")));
        Assert.AreEqual(
          EmptyGUID, MarketingSetup."Exchange Tenant Id Key",
          StrSubstNo(TableFieldShouldBeEmptyErr, MarketingSetup.FieldCaption("Exchange Tenant Id Key")));
        Assert.IsFalse(MarketingSetup."Email Logging Enabled",
          StrSubstNo(TableFieldShouldBeEmptyErr, MarketingSetup.FieldCaption("Email Logging Enabled")));
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

    [HyperlinkHandler]
    [Scope('OnPrem')]
    procedure HyperlinkHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssistedSetupModalPageHandler(var SetupEmailLoggingPage: TestPage "Setup Email Logging")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ClientCredentialsModalPageHandler(var ExchangeClientCredentialsPage: TestPage "Exchange Client Credentials")
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        ExchangeClientCredentialsPage.ClientId.SetValue(LibraryUtility.GenerateRandomAlphabeticText(5, 1));
        ExchangeClientCredentialsPage.ClientSecret.SetValue(LibraryUtility.GenerateRandomAlphabeticText(5, 1));
        ExchangeClientCredentialsPage.RedirectURL.SetValue(LibraryUtility.GenerateRandomAlphabeticText(5, 1));
        ExchangeClientCredentialsPage.OK().Invoke();
    end;
}

