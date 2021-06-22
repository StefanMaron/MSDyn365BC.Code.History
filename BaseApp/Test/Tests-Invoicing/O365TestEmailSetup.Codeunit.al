codeunit 138900 "O365 Test Email Setup"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Email Setup]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        PassWordTxt: Label 'pAssWord1';
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        MailManagement: Codeunit "Mail Management";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"O365 Test Email Setup");

        SMTPMailSetup.DeleteAll();

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify();

        EventSubscriberInvoicingApp.Clear;
        EventSubscriberInvoicingApp.SetClientType(CLIENTTYPE::Phone);

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"O365 Test Email Setup");

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"O365 Test Email Setup");
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestFirstSetupNoTestEmail()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        User: Record User;
        O365EmailAccountSettings: TestPage "O365 Email Account Settings";
    begin
        // [GIVEN] No prior email setup (smtp)
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] User opens settings page and closes it
        O365EmailAccountSettings.OpenEdit;
        O365EmailAccountSettings.Close;

        // [THEN] A setup record is created with proper O365 settings
        SMTPMailSetup.Get();
        AssertO365DefaultSettings(SMTPMailSetup);
        Assert.AreEqual('', SMTPMailSetup.GetPassword, '');
        if User.Get(UserSecurityId) then;
        Assert.AreEqual(User."Authentication Email", SMTPMailSetup."User ID", '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestModifyUserPassword()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        SMTPMail: Codeunit "SMTP Mail";
        O365EmailAccountSettings: TestPage "O365 Email Account Settings";
    begin
        // [GIVEN] Existing email setup (smtp)
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        SMTPMailSetup.Init();
        SMTPMail.ApplyOffice365Smtp(SMTPMailSetup);
        SMTPMailSetup.Insert();

        // [WHEN] User opens settings page and enters user id and password
        O365EmailAccountSettings.OpenEdit;
        O365EmailAccountSettings."User ID".SetValue(UserId + '@' + UserId);
        O365EmailAccountSettings.EmailPassword.SetValue(PassWordTxt);
        O365EmailAccountSettings.Close;

        // [THEN] The setup record is created with proper O365 settings and credentials
        SMTPMailSetup.Get();
        AssertO365DefaultSettings(SMTPMailSetup);
        Assert.AreEqual(UserId + '@' + UserId, SMTPMailSetup."User ID", '');
        Assert.AreEqual(PassWordTxt, SMTPMailSetup.GetPassword, '');
    end;

    local procedure AssertO365DefaultSettings(SMTPMailSetup: Record "SMTP Mail Setup")
    var
        SMTPMail: Codeunit "SMTP Mail";
    begin
        Assert.IsTrue(SMTPMailSetup."Secure Connection", '');
        Assert.AreEqual(SMTPMail.GetDefaultSmtpAuthType, SMTPMailSetup.Authentication, '');
        Assert.AreEqual(SMTPMail.GetO365SmtpServer, SMTPMailSetup."SMTP Server", '');
        Assert.AreEqual(SMTPMail.GetDefaultSmtpPort, SMTPMailSetup."SMTP Server Port", '');
    end;

    [Test]
    [HandlerFunctions('EmailSetupModalPageHandler,VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSetupIsTriggeredIfEmptyEmail()
    var
        SalesHeader: Record "Sales Header";
        O365EmailAccountSettings: TestPage "O365 Email Account Settings";
        O365SalesInvoice: TestPage "O365 Sales Invoice";
    begin
        // [GIVEN] Standard invoicing SMTP setup with empty email and password
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        O365EmailAccountSettings.OpenEdit;
        O365EmailAccountSettings."User ID".SetValue('');
        O365EmailAccountSettings.EmailPassword.SetValue('');
        O365EmailAccountSettings.Close;

        // [WHEN] Trying to send an invoice
        CreateNewInvoice(SalesHeader);
        O365SalesInvoice.OpenEdit;
        O365SalesInvoice.GotoRecord(SalesHeader);

        // [THEN] The email wizard is open; if closed, an error is triggered
        // Note: handler is called
        O365SalesInvoice.Post.Invoke;
        Assert.ExpectedError('');
    end;

    [Test]
    [HandlerFunctions('SendEmailModalPageHandler,VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSetupIsNotTriggeredIfNonEmptyEmail()
    var
        SalesHeader: Record "Sales Header";
        LibraryUtility: Codeunit "Library - Utility";
        O365EmailAccountSettings: TestPage "O365 Email Account Settings";
        O365SalesInvoice: TestPage "O365 Sales Invoice";
    begin
        // [GIVEN] Standard invoicing SMTP setup with non-empty email a password
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        O365EmailAccountSettings.OpenEdit;
        O365EmailAccountSettings."User ID".SetValue('test@test.test');
        O365EmailAccountSettings.EmailPassword.SetValue(LibraryUtility.GenerateRandomText(10));
        O365EmailAccountSettings.Close;

        // [WHEN] Trying to send an invoice
        CreateNewInvoice(SalesHeader);
        O365SalesInvoice.OpenEdit;
        O365SalesInvoice.GotoRecord(SalesHeader);
        O365SalesInvoice.Post.Invoke;

        // [THEN] The email wizard does not show up, but the send email interface does
        // Note: handler is called
    end;

    [Test]
    [HandlerFunctions('EmailSetupModalPageHandler,VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSetupIsTriggeredIfEmptyEmailInWeb()
    var
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        O365EmailAccountSettings: TestPage "O365 Email Account Settings";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] Standard invoicing SMTP setup with empty email and password
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        O365EmailAccountSettings.OpenEdit;
        O365EmailAccountSettings."User ID".SetValue('');
        O365EmailAccountSettings.EmailPassword.SetValue('');
        O365EmailAccountSettings.Close;

        // [WHEN] Trying to send an invoice
        CreateNewInvoice(SalesHeader);
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoRecord(SalesHeader);

        // [THEN] The email wizard is open; if closed, an error is triggered
        // Note: handler is called
        BCO365SalesInvoice.Post.Invoke;
        Assert.ExpectedError('');

        TaxArea.FindFirst;
        LibraryNotificationMgt.RecallNotificationsForRecord(TaxArea);
    end;

    [Test]
    [HandlerFunctions('SendEmailModalPageHandler,VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSetupIsNotTriggeredIfNonEmptyEmailInWeb()
    var
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        LibraryUtility: Codeunit "Library - Utility";
        O365EmailAccountSettings: TestPage "O365 Email Account Settings";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] Standard invoicing SMTP setup with non-empty email a password
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        O365EmailAccountSettings.OpenEdit;
        O365EmailAccountSettings."User ID".SetValue('test@test.test');
        O365EmailAccountSettings.EmailPassword.SetValue(LibraryUtility.GenerateRandomText(10));
        O365EmailAccountSettings.Close;

        // [WHEN] Trying to send an invoice
        CreateNewInvoice(SalesHeader);
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoRecord(SalesHeader);
        BCO365SalesInvoice.Post.Invoke;

        // [THEN] The email wizard does not show up, but the send email interface does
        // Note: handler is called

        TaxArea.FindFirst;
        LibraryNotificationMgt.RecallNotificationsForRecord(TaxArea);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSmtpEmailChosenByDefault()
    var
        UserSetup: Record "User Setup";
        User: Record User;
        SMTPMailSetup: Record "SMTP Mail Setup";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope; // Data set up by sync-daemon
        Initialize();

        // [GIVEN] User setup has been created with an email
        UserSetup."User ID" := UserId;
        UserSetup."E-Mail" := 'userSetupEmail@cronusus.com';
        UserSetup.Insert();

        // [GIVEN] User has been created with a contact and authentication email
        User."User Security ID" := CreateGuid;
        User."Contact Email" := 'userContactEmail@cronusus.com';
        User."Authentication Email" := 'userAuthenticationEmail@cronusus.com';
        User.Insert();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] SMTP has been set up with an email
        SMTPMailSetup.Authentication := SMTPMailSetup.Authentication::Basic;
        SMTPMailSetup."User ID" := 'smtpMailSetupUserID@cronusus.com';
        SMTPMailSetup."SMTP Server" := 'cronusus.com';
        SMTPMailSetup.Insert();

        // [WHEN] Finding the sender email address to user for emails
        // [THEN] The SMTP email is chosen
        MailManagement.IsEnabled;
        Assert.AreEqual(
          'smtpMailSetupUserID@cronusus.com',
          MailManagement.GetSenderEmailAddress,
          'The SMTP email address was not chosen as sender');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestEmailBodyVisibility()
    var
        TempEmailItem: Record "Email Item" temporary;
        O365SalesEmailDialog: Page "O365 Sales Email Dialog";
        O365SalesEmailDialogTestPage: TestPage "O365 Sales Email Dialog";
        DummyVar: Variant;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365Basic;
        O365SalesEmailDialogTestPage.Trap;
        O365SalesEmailDialog.HideBody;
        TempEmailItem.SetBodyText('this is a test');
        TempEmailItem.Insert();
        O365SalesEmailDialog.SetValues(DummyVar, TempEmailItem);
        O365SalesEmailDialog.Run;

        Assert.IsFalse(O365SalesEmailDialogTestPage.Body.Visible, 'Email body is visible');

        O365SalesEmailDialogTestPage.Trap;
        O365SalesEmailDialog.SetValues(DummyVar, TempEmailItem);
        O365SalesEmailDialog.Run;

        Assert.AreEqual(O365SalesEmailDialogTestPage.Body.Value, 'this is a test', 'incorrect email body is shown');
    end;

    [Test]
    [HandlerFunctions('EmailPreviewModalPageHandler,VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestEmailBodyContent()
    var
        TempEmailItem: Record "Email Item" temporary;
        O365SalesEmailDialog: Page "O365 Sales Email Dialog";
        O365SalesEmailDialogTestPage: TestPage "O365 Sales Email Dialog";
        DummyVar: Variant;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365Basic;
        O365SalesEmailDialogTestPage.Trap;
        TempEmailItem.SetBodyText('<html>this is a test</html>');
        TempEmailItem.Insert();
        O365SalesEmailDialog.SetValues(DummyVar, TempEmailItem);
        O365SalesEmailDialog.Run;

        O365SalesEmailDialogTestPage.ShowEmailContentLbl.DrillDown;
    end;

    local procedure CreateNewInvoice(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, 10);

        SalesHeader.SetFilter("Sell-to Customer No.", Customer."No.");
        SalesHeader.FindFirst;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailSetupModalPageHandler(var BCO365EmailSetupWizard: Page "BC O365 Email Setup Wizard"; var Response: Action)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailPreviewModalPageHandler(var O365EmailPreview: Page "O365 Email Preview"; var Response: Action)
    begin
        Assert.AreEqual('<html>this is a test</html>', O365EmailPreview.GetBodyText, 'incorrect html body');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SendEmailModalPageHandler(var O365SalesEmailDialog: Page "O365 Sales Email Dialog"; var Result: Action)
    begin
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.AreEqual(1, StrPos(TheNotification.Message, 'You haven''t set up tax information for your business.'),
          StrSubstNo('Unexpected notification was thrown: %1', TheNotification.Message));
    end;
}

