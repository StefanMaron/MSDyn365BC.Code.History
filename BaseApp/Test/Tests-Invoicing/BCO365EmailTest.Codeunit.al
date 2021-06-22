codeunit 138960 "BC O365 Email Test"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Email Setup] [UT]
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        IsInitialized: Boolean;
        RemoveConfirmQst: Label 'Do you want to remove the address?';

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyInsertingMultipleCCRecipients()
    var
        O365EmailSetup: Record "O365 Email Setup";
    begin
        // [SCENARIO] User can add multiple CC recipients in email settings
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;
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
    var
        O365EmailSetup: Record "O365 Email Setup";
    begin
        // [SCENARIO] User can add multiple BCC recipients in email settings
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;
        // [WHEN] The user adds multiple BCC recipients
        InsertRecipient('BCC1@test.com', O365EmailSetup.RecipientType::BCC);
        InsertRecipient('BCC2@test.com', O365EmailSetup.RecipientType::BCC);

        // [THEN] The BCC recipients are added and can be fetched in semicolon seperated list, without an ending semicolon
        Assert.AreNotEqual('BCC1@test.com;BCC2@test.com;', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, 'Inserting multiple BCC failed');
        Assert.AreEqual('BCC1@test.com;BCC2@test.com', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, 'Inserting multiple BCC failed.');
        Assert.AreEqual('', O365EmailSetup.GetCCAddressesFromO365EmailSetup, 'Inserting multiple BCC failed; CC affected.');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,ConfirmDeleteRecipientHandler')]
    [Scope('OnPrem')]
    procedure VerifyDeletingCCRecipient()
    var
        O365EmailSetup: Record "O365 Email Setup";
    begin
        // [SCENARIO] User can delete CC recipient in email settings
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;
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
    [HandlerFunctions('VerifyNoNotificationsAreSend,ConfirmDeleteRecipientHandler')]
    [Scope('OnPrem')]
    procedure VerifyDeletingBCCRecipient()
    var
        O365EmailSetup: Record "O365 Email Setup";
    begin
        // [SCENARIO] User can delete BCC recipient in email settings
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;
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
    procedure VerifyModifingCCRecipient()
    var
        O365EmailSetup: Record "O365 Email Setup";
    begin
        // [SCENARIO] User can modify CC recipient in email settings
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;
        // [GIVEN] An CC recipient in email settings
        InsertRecipient('CC@test.com', O365EmailSetup.RecipientType::CC);

        // [WHEN] CC recipient email is modified
        ModifyRecipient('CC@test.com', O365EmailSetup.RecipientType::CC, 'ModifiedCC@test.com');

        // [THEN] Email field is modified and Code field is set to modified email
        Assert.AreNotEqual('CC@test.com', O365EmailSetup.GetCCAddressesFromO365EmailSetup, 'Modifying CC Failed');
        Assert.AreEqual('ModifiedCC@test.com', O365EmailSetup.GetCCAddressesFromO365EmailSetup, 'Modifying CC Failed');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyModifingBCCRecipient()
    var
        O365EmailSetup: Record "O365 Email Setup";
    begin
        // [SCENARIO] User can modify BCC recipient in email settings
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;
        // [GIVEN] An BCC recipient in email settings
        InsertRecipient('BCC2@test.com', O365EmailSetup.RecipientType::BCC);

        // [WHEN] BCC recipient email is modified
        ModifyRecipient('BCC2@test.com', O365EmailSetup.RecipientType::BCC, 'ModifiedBCC2@test.com');

        // [THEN] Email field is modified and Code field is set to modified email
        Assert.AreNotEqual('BCC2@test.com', O365EmailSetup.GetCCAddressesFromO365EmailSetup, 'Modifying CC Failed');
        Assert.AreEqual('ModifiedBCC2@test.com', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, 'Modifying BCC Failed');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure VerifyInsertingSameRecipientinCCandBCC()
    var
        O365EmailSetup: Record "O365 Email Setup";
    begin
        // [SCENARIO] User can insert same recipient in CC and BCC email settings
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;
        // [GIVEN] An CC recipient in email settings
        InsertRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::CC);
        InsertRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::BCC);

        // [THEN] Users exists in both CC and BCC lists
        Assert.AreEqual('ForBoth1@test.com', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, '');
        Assert.AreEqual('ForBoth1@test.com', O365EmailSetup.GetCCAddressesFromO365EmailSetup, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,ConfirmDeleteRecipientHandler')]
    [Scope('OnPrem')]
    procedure VerifyDeletingSameRecipientfromCCandBCC()
    var
        O365EmailSetup: Record "O365 Email Setup";
    begin
        // [SCENARIO] User can delete same recipient in CC and BCC email settings
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;
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
    var
        O365EmailSetup: Record "O365 Email Setup";
    begin
        // [SCENARIO] User can modify same recipient in CC and BCC email settings
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;
        // [GIVEN] A same recipient in CC and BCC email setting
        InsertRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::CC);
        InsertRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::BCC);

        // [WHEN] User modifies the recipient from CC list
        ModifyRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::CC, 'ModifiedForBoth1@test.com');

        // [THEN] CC recipient is modified and BCC recipient remains intact.
        Assert.AreEqual('ModifiedForBoth1@test.com', O365EmailSetup.GetCCAddressesFromO365EmailSetup, '');
        Assert.AreEqual('ForBoth1@test.com', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, '');

        // [WHEN] User modifies the recipient from BCC list
        ModifyRecipient('ForBoth1@test.com', O365EmailSetup.RecipientType::BCC, 'ModifiedForBoth1@test.com');

        // [THEN] BCC recipient is modified and CC recipient remains intact.
        Assert.AreEqual('ModifiedForBoth1@test.com', O365EmailSetup.GetCCAddressesFromO365EmailSetup, '');
        Assert.AreEqual('ModifiedForBoth1@test.com', O365EmailSetup.GetBCCAddressesFromO365EmailSetup, '');
    end;

    local procedure Initialize()
    var
        O365EmailSetup: Record "O365 Email Setup";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        O365EmailSetup.Reset;
        O365EmailSetup.DeleteAll;

        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider;
        LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');

        EventSubscriberInvoicingApp.Clear;

        if IsInitialized then
            exit;

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);
        IsInitialized := true;
    end;

    local procedure InsertRecipient(Email: Text[80]; RecipientType: Option)
    var
        BCO365Settings: TestPage "BC O365 Settings";
    begin
        BCO365Settings.OpenEdit;
        BCO365Settings."Email settings".New;
        BCO365Settings."Email settings".Email.Value(Email);
        BCO365Settings."Email settings".RecipientType.SetValue(RecipientType);
        BCO365Settings.Close;
    end;

    local procedure ModifyRecipient(OldEmail: Text[80]; OldRecipientType: Option; Email: Text[80])
    var
        BCO365Settings: TestPage "BC O365 Settings";
    begin
        BCO365Settings.OpenEdit;
        BCO365Settings."Email settings".GotoKey(GetRecipientCode(OldEmail, OldRecipientType), OldRecipientType);
        BCO365Settings."Email settings".Email.Value(Email);
        BCO365Settings.Close;
    end;

    local procedure DeleteRecipient(Email: Text[80]; RecipientType: Option)
    var
        O365EmailSetup: Record "O365 Email Setup";
    begin
        O365EmailSetup.SetCurrentKey(Email, RecipientType);
        O365EmailSetup.SetRange(Email, Email);
        O365EmailSetup.SetRange(RecipientType, RecipientType);
        O365EmailSetup.FindFirst;
        O365EmailSetup.Delete(true);
    end;

    local procedure GetRecipientCode(Email: Text[80]; RecipientType: Option): Text[80]
    var
        O365EmailSetup: Record "O365 Email Setup";
    begin
        O365EmailSetup.SetCurrentKey(Email, RecipientType);
        O365EmailSetup.SetRange(Email, Email);
        O365EmailSetup.SetRange(RecipientType, RecipientType);
        O365EmailSetup.FindFirst;
        exit(O365EmailSetup.Code);
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmDeleteRecipientHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(Question, RemoveConfirmQst, 'Unexpected Confirm question.');

        Reply := true;
    end;
}

