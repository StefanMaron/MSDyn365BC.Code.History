codeunit 139022 "SMTP Page Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        Assert: Codeunit "Assert";
        LibraryUtility: Codeunit "Library - Utility";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetupThroughKeyVaultSetupTest()
    var
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
        SMTP: Codeunit "SMTP Mail";
    begin
        // [SCENARIO] If a SMTP setup exists in the Key Vault, then that setup is used if no other setup exists

        // [GIVEN] No setup exists
        SMTP.Initialize();
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider;
        LibraryAzureKVMockMgmt.UseAzureKeyvaultSecretProvider;
        SMTPMailSetup.DeleteAll();
        Assert.IsFalse(SMTP.IsEnabled, 'SMTP Setup was not empty.');

        // [GIVEN] Some SMTP setup key vault secrets
        LibraryAzureKVMockMgmt.AddMockAzureKeyvaultSecretProviderMapping('AllowedApplicationSecrets', 'SmtpSetup');
        LibraryAzureKVMockMgmt.AddMockAzureKeyvaultSecretProviderMappingFromFile(
          'SmtpSetup',
          LibraryUtility.GetInetRoot + '\App\Test\Files\AzureKeyVaultSecret\SMTPSetupSecret.txt');

        LibraryAzureKVMockMgmt.UseAzureKeyvaultSecretProvider;

        // [WHEN] It is checked whether SMTP is set up
        // [THEN] The SMTP setup from the key vault is used
        Assert.IsTrue(SMTP.IsEnabled, 'SMTP was not set up.');

        // Tear down key vault mock after use
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider;
        LibraryAzureKVMockMgmt.UseAzureKeyvaultSecretProvider;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMail_ValidateOtherEmailAddressTest()
    var
        SMTPUserSpecifiedAddress: TestPage "SMTP User-Specified Address";
    begin
        SMTPUserSpecifiedAddress.OpenEdit();
        SMTPUserSpecifiedAddress.EmailAddressField.Value := 'a@b';
        SMTPUserSpecifiedAddress.EmailAddressField.Value := 'vlabtst1@microsoft.com';
        asserterror SMTPUserSpecifiedAddress.EmailAddressField.Value := 'ab.c';
        asserterror SMTPUserSpecifiedAddress.EmailAddressField.Value := ' ';
        asserterror SMTPUserSpecifiedAddress.EmailAddressField.Value := 'a#b()´Š¢´Š¢c';
        asserterror SMTPUserSpecifiedAddress.EmailAddressField.Value := 'a@b@c';
        SMTPUserSpecifiedAddress.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMail_ActionToggleTest()
    var
        SMTPMailSetupPage: TestPage "SMTP Mail Setup";
    begin
        SMTPMailSetupClear();

        SMTPMailSetupPage.OpenEdit();
        Assert.IsFalse(SMTPMailSetupPage.SendTestMail.Enabled(), 'Action should be disabled when empty record.');
        SMTPMailSetupPage."SMTP Server".Value := 'localhost';
        Assert.IsTrue(SMTPMailSetupPage.SendTestMail.Enabled(), 'Action should be enabled when Server is set.');
        SMTPMailSetupPage."SMTP Server".Value := '';
        Assert.IsFalse(SMTPMailSetupPage.SendTestMail.Enabled(), 'Action should be disabled when Server is cleared.');
        SMTPMailSetupPage.Close();
    end;

    [Test]
    [HandlerFunctions('HandleUserSpecifiedAddressPage')]
    [Scope('OnPrem')]
    procedure TestMail_GetOtherEmailAddressTest()
    var
        SMTPUserSpecifiedAddress: Page "SMTP User-Specified Address";
        Address: Text;
    begin
        SMTPUserSpecifiedAddress.RunModal;
        Address := SMTPUserSpecifiedAddress.GetEmailAddress;
        Assert.AreEqual('test@microsoft.com', Address, 'Wrong Email address returned from page.');
    end;

    [Test]
    [HandlerFunctions('HandleEmailAddressChoiceDialogByProceeding')]
    [Scope('OnPrem')]
    procedure TestMail_SendTestThroughPage()
    var
        SMTPMailSetupPage: TestPage "SMTP Mail Setup";
        SMTP: Codeunit "SMTP Mail";
    begin
        BindActiveDirectoryMockEvents();
        SMTP.Initialize();
        SMTPMailSetupInitialize();
        SMTPMailSetupBasicAuth();

        // This is the only test where we invoke Test Mail through the page.
        SMTPMailSetupPage.OpenEdit();
        SMTPMailSetupPage.SendTestMail.Invoke();
        SMTPMailSetupPage.Close();

        LibraryNotificationMgt.RecallNotificationsForRecord(SMTPMailSetup);
    end;

    [Test]
    [HandlerFunctions('HandleEmailAddressChoiceDialogByPrompting,HandleUserSpecifiedAddressPage')]
    [Scope('OnPrem')]
    procedure TestMail_FailedSendAfterPromptingForEmailAddressTest()
    var
        SMTP: Codeunit "SMTP Mail";
    begin
        BindActiveDirectoryMockEvents();
        SMTP.Initialize();
        SMTPMailSetupInitialize();
        SMTPMailSetupBasicAuth();

        asserterror CODEUNIT.Run(CODEUNIT::"SMTP Test Mail");

        LibraryNotificationMgt.RecallNotificationsForRecord(SMTPMailSetup);
    end;

    [Test]
    [HandlerFunctions('HandleEmailAddressChoiceDialogByCancelling,HandleConfirm')]
    [Scope('OnPrem')]
    procedure TestMail_ChoiceOfEmailsTest()
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        SMTP: Codeunit "SMTP Mail";
    begin
        BindActiveDirectoryMockEvents();
        SMTP.Initialize();
        SMTPMailSetupInitialize();

        if not CryptographyManagement.IsEncryptionEnabled then
            CryptographyManagement.EnableEncryption(FALSE);

        CreateUser;
        SMTPMailSetup.Get();
        SMTPMailSetup.Authentication := SMTPMailSetup.Authentication::Basic;
        SMTPMailSetup."User ID" := 'test1@test.com';
        SMTPMailSetup.SetPassword('password');
        SMTPMailSetup.Modify();

        CODEUNIT.Run(CODEUNIT::"SMTP Test Mail");
        CryptographyManagement.DisableEncryption(true);
    end;

    [Test]
    [HandlerFunctions('HandleEmailAddressChoiceDialogByPrompting,HandleUserSpecifiedAddressPageByCancelling')]
    [Scope('OnPrem')]
    procedure TestMail_NoSendIfValidAddressButCancelDialogTest()
    var
        SMTP: Codeunit "SMTP Mail";
    begin
        BindActiveDirectoryMockEvents();
        SMTP.Initialize();
        SMTPMailSetupInitialize();

        CODEUNIT.Run(CODEUNIT::"SMTP Test Mail");
    end;

    local procedure SMTPMailSetupInitialize()
    begin
        SMTPMailSetupClear();

        // Add a new test record
        SMTPMailSetup.Init();
        SMTPMailSetup."SMTP Server" := 'localhost';
        SMTPMailSetup."SMTP Server Port" := 9999;
        SMTPMailSetup.Authentication := SMTPMailSetup.Authentication::Anonymous;
        SMTPMailSetup.Insert();
        Commit();
    end;

    local procedure SMTPMailSetupBasicAuth()
    begin
        SMTPMailSetup."User ID" := 'test@microsoft.com';
        SMTPMailSetup.Authentication := SMTPMailSetup.Authentication::Basic;
        SMTPMailSetup.Modify();
        Commit();
    end;

    local procedure SMTPMailSetupClear()
    begin
        // Clear all old records
        SMTPMailSetup.DeleteAll();
        Commit();
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable;
    end;

    [Normal]
    local procedure CreateUser()
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserId);
        if not User.FindFirst then begin
            User.Reset();
            User.Init();
            User."User Security ID" := CreateGuid;
            User."User Name" := UserId;
            User."Authentication Email" := 'test2@test.com';
            User.Insert();
        end else begin
            User."Authentication Email" := 'test2@test.com';
            User.Modify();
        end;
        Commit();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure HandleEmailAddressChoiceDialogByProceeding(Options: Text; var Choice: Integer; Instructions: Text)
    begin
        // Choice #1 is the Email Address obtained from Active Directory.
        Choice := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleUserSpecifiedAddressPage(var SMTPUserSpecifiedAddress: Page "SMTP User-Specified Address"; var Response: Action)
    begin
        SMTPUserSpecifiedAddress.SetEmailAddress('test@microsoft.com');
        Response := ACTION::OK;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HandleConfirm(Message: Text[1024]; var Reply: Boolean)
    begin
        case true of
            StrPos(Message, 'Do you want to save the encryption key?') <> 0:
                Reply := false;
            StrPos(Message, 'Enabling encryption will generate an encryption key') <> 0:
                Reply := true;
            StrPos(Message, 'Disabling encryption will decrypt the encrypted data') <> 0:
                Reply := true;
            else
                Reply := false;
        end;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure HandleEmailAddressChoiceDialogByCancelling(Options: Text; var Choice: Integer; Instruction: Text)
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        Assert.IsTrue(
          StrPos(Options, 'test1@test.com') > 0,
          StrSubstNo('Cannot find expected address "test1@test.com" in "%1".', Options));
        Assert.IsTrue(
          StrPos(Options, 'test2@test.com') > 0,
          StrSubstNo('Cannot find expected address "test2@test.com" in "%1".', Options));
        Assert.IsTrue(
          StrPos(Options, 'Other...') > 0,
          StrSubstNo('Cannot find Other option in "%1".', Options));
        if not EnvironmentInfo.IsSaaS then
            Assert.IsTrue(
              StrPos(Options, '@microsoft.com') > 0,
              StrSubstNo('Cannot find the current user''s Email Address ending in "@microsoft.com" in "%1".', Options));
        Choice := 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleUserSpecifiedAddressPageByCancelling(var SMTPUserSpecifiedAddress: Page "SMTP User-Specified Address"; var Response: Action)
    begin
        SMTPUserSpecifiedAddress.SetEmailAddress('test@microsoft.com');
        Response := ACTION::Cancel;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure HandleEmailAddressChoiceDialogByPrompting(Options: Text; var Choice: Integer; Instructions: Text)
    begin
        // Choice #4 is where the user selects to specify his own Email Address.
        Choice := 4;
    end;
}