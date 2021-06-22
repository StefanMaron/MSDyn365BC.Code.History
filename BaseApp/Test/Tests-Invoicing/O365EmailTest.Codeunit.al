codeunit 138908 "O365 Email Test"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Email Setup] [UT]
    end;

    var
        O365EmailSetup: Record "O365 Email Setup";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyInsertingMultipleCCRecipients()
    begin
        // [SCENARIO] User can add multiple CC recipients in email settings
        Initialize;
        LibraryLowerPermissions.SetO365Basic;
        // [WHEN] The user adds multiple CC recipients
        InsertRecipient('CC1@test.com', O365EmailSetup.RecipientType::CC);
        InsertRecipient('CC2@test.com', O365EmailSetup.RecipientType::CC);

        // [THEN] The CC recipients are added and can be fetched in semicolon seperated list, without an ending semicolon
        Assert.AreNotEqual('CC1@test.com;CC2@test.com;', O365EmailSetup.GetCCAddressesFromO365EmailSetup, 'Inserting multiple CC failed');
        Assert.AreEqual('CC1@test.com;CC2@test.com', O365EmailSetup.GetCCAddressesFromO365EmailSetup, 'Inserting multiple CC failed.');
        Assert.AreEqual('', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, 'Inserting multiple CC failed; BCC affected.');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyInsertingMultipleBCCRecipients()
    begin
        // [SCENARIO] User can add multiple BCC recipients in email settings
        Initialize;
        LibraryLowerPermissions.SetO365Basic;
        // [WHEN] The user adds multiple BCC recipients
        InsertRecipient('BCC1@test.com', O365EmailSetup.RecipientType::BCC);
        InsertRecipient('BCC2@test.com', O365EmailSetup.RecipientType::BCC);

        // [THEN] The BCC recipients are added and can be fetched in semicolon seperated list, without an ending semicolon
        Assert.AreNotEqual('BCC1@test.com;BCC2@test.com;', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, 'Inserting multiple BCC failed');
        Assert.AreEqual('BCC1@test.com;BCC2@test.com', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, 'Inserting multiple BCC failed.');
        Assert.AreEqual('', O365EmailSetup.GetCCAddressesFromO365EmailSetup, 'Inserting multiple BCC failed; CC affected.');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyDeletingCCRecipient()
    begin
        // [SCENARIO] User can delete CC recipient in email settings
        Initialize;
        LibraryLowerPermissions.SetO365Basic;
        // [GIVEN] A CC recipient and a BCC recipient setup in email settings
        InsertRecipient('BCC1@test.com', O365EmailSetup.RecipientType::BCC);
        InsertRecipient('CC1@test.com', O365EmailSetup.RecipientType::CC);

        // [WHEN] The user deletes CC recipient
        DeleteRecipient('CC1@test.com', O365EmailSetup.RecipientType::CC);

        // [THEN] CC recipient should be deleted and BCC recipient should not be affected
        Assert.AreEqual('', O365EmailSetup.GetCCAddressesFromO365EmailSetup, 'Deleting CC failed');
        Assert.AreEqual('BCC1@test.com', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, 'Deleting CC failed;BCC affected');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyDeletingBCCRecipient()
    begin
        // [SCENARIO] User can delete BCC recipient in email settings
        Initialize;
        LibraryLowerPermissions.SetO365Basic;
        // [GIVEN] A CC recipient and a BCC recipient setup in email settings
        InsertRecipient('CC1@test.com', O365EmailSetup.RecipientType::CC);
        InsertRecipient('BCC1@test.com', O365EmailSetup.RecipientType::BCC);

        // [WHEN] The user deletes BCC recipient
        DeleteRecipient('BCC1@test.com', O365EmailSetup.RecipientType::BCC);

        // [THEN] BCC recipient should be deleted and CC recipient should not be affected
        Assert.AreEqual('', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, 'Deleting BCC failed');
        Assert.AreEqual('CC1@test.com', O365EmailSetup.GetCCAddressesFromO365EmailSetup, 'Deleting BCC failed;CC affected');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyCCDeletedWhenSettingEmailToEmpty()
    begin
        // [SCENARIO] User can delete CC recipient in email settings by setting their email to empty
        Initialize;
        LibraryLowerPermissions.SetO365Basic;

        // [GIVEN] A CC recipient and a BCC recipient setup in email settings
        InsertRecipient('BCC1@test.com', O365EmailSetup.RecipientType::BCC);
        InsertRecipient('CC1@test.com', O365EmailSetup.RecipientType::CC);

        // [WHEN] The user sets the CC email to empty
        GetRecipient('CC1@test.com', O365EmailSetup.RecipientType::CC);
        O365EmailSetup.Validate(Email, '');

        // [THEN] CC recipient should be deleted and BCC recipient should not be affected
        Assert.IsFalse(O365EmailSetup.Find, 'CC record still exists');
        Assert.AreEqual('', O365EmailSetup.GetCCAddressesFromO365EmailSetup, 'Deleting CC failed');
        Assert.AreEqual('BCC1@test.com', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, 'Deleting CC failed;BCC affected');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyModifingCCRecipient()
    begin
        // [SCENARIO] User can modify CC recipient in email settings
        Initialize;
        LibraryLowerPermissions.SetO365Basic;
        // [GIVEN] An CC recipient in email settings
        InsertRecipient('CC@test.com', O365EmailSetup.RecipientType::CC);

        // [WHEN] CC recipient email is modified
        GetRecipient('CC@test.com', O365EmailSetup.RecipientType::CC);
        ModifyRecipient('ModifiedCC@test.com');

        // [THEN] Email field is modified and Code field is set to modified email
        Assert.AreNotEqual('CC@test.com', O365EmailSetup.GetCCAddressesFromO365EmailSetup, 'Modifying CC Failed');
        Assert.AreEqual('ModifiedCC@test.com', O365EmailSetup.GetCCAddressesFromO365EmailSetup, 'Modifying CC Failed');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyModifingBCCRecipient()
    begin
        // [SCENARIO] User can modify BCC recipient in email settings
        Initialize;
        LibraryLowerPermissions.SetO365Basic;
        // [GIVEN] An BCC recipient in email settings
        InsertRecipient('BCC2@test.com', O365EmailSetup.RecipientType::BCC);

        // [WHEN] BCC recipient email is modified
        GetRecipient('BCC2@test.com', O365EmailSetup.RecipientType::BCC);
        ModifyRecipient('ModifiedBCC2@test.com');

        // [THEN] Email field is modified and Code field is set to modified email
        Assert.AreNotEqual('BCC2@test.com', O365EmailSetup.GetCCAddressesFromO365EmailSetup, 'Modifying CC Failed');
        Assert.AreEqual('ModifiedBCC2@test.com', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, 'Modifying BCC Failed');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyInsertingSameRecipientinCCandBCC()
    begin
        // [SCENARIO] User can insert same recipient in CC and BCC email settings
        Initialize;
        LibraryLowerPermissions.SetO365Basic;
        // [GIVEN] An CC recipient in email settings
        InsertRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::CC);
        InsertRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::BCC);

        // [THEN] Users exists in both CC and BCC lists
        Assert.AreEqual('ForBoth1@test.com', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, '');
        Assert.AreEqual('ForBoth1@test.com', O365EmailSetup.GetCCAddressesFromO365EmailSetup, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyDeletingSameRecipientfromCCandBCC()
    begin
        // [SCENARIO] User can delete same recipient in CC and BCC email settings
        Initialize;
        LibraryLowerPermissions.SetO365Basic;
        // [GIVEN] A same recipient in CC and BCC email settings
        InsertRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::CC);
        InsertRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::BCC);

        // [WHEN] User deletes the recipient from CC list
        DeleteRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::CC);

        // [THEN] CC recipient is deleted and BCC recipient remains intact.
        Assert.AreEqual('', O365EmailSetup.GetCCAddressesFromO365EmailSetup, '');
        Assert.AreEqual('ForBoth1@test.com', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, '');

        // [WHEN] User deletes the recipient from BCC list
        DeleteRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::BCC);

        // [THEN] CC recipient is deleted and BCC recipient remains intact.
        Assert.AreEqual('', O365EmailSetup.GetCCAddressesFromO365EmailSetup, '');
        Assert.AreEqual('', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyModifingSameRecipientinCCandBCC()
    begin
        // [SCENARIO] User can modify same recipient in CC and BCC email settings
        Initialize;
        LibraryLowerPermissions.SetO365Basic;
        // [GIVEN] A same recipient in CC and BCC email setting
        InsertRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::CC);
        InsertRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::BCC);

        // [WHEN] User modifies the recipient from CC list
        GetRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::CC);
        ModifyRecipient('ModifiedForBoth1@test.com');

        // [THEN] CC recipient is modified and BCC recipient remains intact.
        Assert.AreEqual('ModifiedForBoth1@test.com', O365EmailSetup.GetCCAddressesFromO365EmailSetup, '');
        Assert.AreEqual('ForBoth1@test.com', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, '');

        // [WHEN] User modifies the recipient from BCC list
        GetRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::BCC);
        ModifyRecipient('ModifiedForBoth1@test.com');

        // [THEN] BCC recipient is modified and CC recipient remains intact.
        Assert.AreEqual('ModifiedForBoth1@test.com', O365EmailSetup.GetCCAddressesFromO365EmailSetup, '');
        Assert.AreEqual('ModifiedForBoth1@test.com', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyFromAddressSetCorrectlyFromUserIdWithSender()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        MailManagement: Codeunit "Mail Management";
        BCO365EmailAccountSettings: TestPage "BC O365 Email Account Settings";
    begin
        // [SCENARIO] User sets a user id of the format "user\sender", the user id and sender are set correctly
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A user has an email of the form "user\sender"
        BCO365EmailAccountSettings.OpenEdit;
        BCO365EmailAccountSettings."Email Provider".SetValue('Office 365');
        BCO365EmailAccountSettings.FromAccount.SetValue('testuser@domain.com\testsender@domain.com');
        BCO365EmailAccountSettings.Password.SetValue('TestPassword');
        BCO365EmailAccountSettings.Close;

        // [THEN] The user reopens the settings the from account is the same
        BCO365EmailAccountSettings.OpenEdit;
        Assert.AreEqual('testuser@domain.com\testsender@domain.com', BCO365EmailAccountSettings.FromAccount.Value, '');

        // [THEN] Finding the from address it is the testsender
        Assert.AreEqual('testsender@domain.com', MailManagement.GetSenderEmailAddress, '');

        // [THEN] The User Id is set to testuser
        SMTPMailSetup.Get();
        Assert.AreEqual('testuser@domain.com', SMTPMailSetup."User ID", '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyFromAddressSetCorrectlyFromUserId()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        MailManagement: Codeunit "Mail Management";
        BCO365EmailAccountSettings: TestPage "BC O365 Email Account Settings";
    begin
        // [SCENARIO] User sets a user id of the format user@domain, the user id and sender are set correctly
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A user has an email of the form user@domain
        BCO365EmailAccountSettings.OpenEdit;
        BCO365EmailAccountSettings."Email Provider".SetValue('Office 365');
        BCO365EmailAccountSettings.FromAccount.SetValue('testuser@domain.com');
        BCO365EmailAccountSettings.Password.SetValue('TestPassword');
        BCO365EmailAccountSettings.Close;

        // [THEN] Finding the from address it is the testuser
        Assert.AreEqual('testuser@domain.com', MailManagement.GetSenderEmailAddress, '');

        // [THEN] The user reopens the settings the from account is the same
        BCO365EmailAccountSettings.OpenEdit;
        Assert.AreEqual('testuser@domain.com', BCO365EmailAccountSettings.FromAccount.Value, '');

        // [THEN] The User Id is set to testuser
        SMTPMailSetup.Get();
        Assert.AreEqual('testuser@domain.com', SMTPMailSetup."User ID", '');
    end;

    local procedure Initialize()
    begin
        O365EmailSetup.Reset();
        O365EmailSetup.DeleteAll();
    end;

    local procedure InsertRecipient(Email: Text[80]; RecipientType: Option)
    begin
        O365EmailSetup.Reset();
        O365EmailSetup.Init();
        O365EmailSetup.Email := Email;
        O365EmailSetup.RecipientType := RecipientType;
        O365EmailSetup.Insert(true);
    end;

    local procedure ModifyRecipient(Email: Text[80])
    begin
        O365EmailSetup.Email := Email;
        O365EmailSetup.Modify(true);
    end;

    local procedure DeleteRecipient(Email: Text[80]; RecipientType: Option)
    begin
        GetRecipient(Email, RecipientType);
        O365EmailSetup.Delete(true);
    end;

    local procedure GetRecipient(Email: Text[80]; RecipientType: Option)
    begin
        O365EmailSetup.SetCurrentKey(Email, RecipientType);
        O365EmailSetup.SetRange(Email, Email);
        O365EmailSetup.SetRange(RecipientType, RecipientType);
        O365EmailSetup.FindFirst;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

