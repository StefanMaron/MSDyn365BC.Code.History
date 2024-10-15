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
        LibraryWorkflow: Codeunit "Library - Workflow";
        PassWordTxt: Label 'pAssWord1';
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        MailManagement: Codeunit "Mail Management";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"O365 Test Email Setup");
        LibraryWorkflow.SetUpEmailAccount();

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
    procedure TestSetupIsTriggeredIfEmptyEmail()
    var
        SalesHeader: Record "Sales Header";
        O365SalesInvoice: TestPage "O365 Sales Invoice";
    begin
        // [GIVEN] Standard invoicing SMTP setup with empty email and password
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

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
        O365SalesInvoice: TestPage "O365 Sales Invoice";
    begin
        // [GIVEN] Standard invoicing SMTP setup with non-empty email a password
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] Trying to send an invoice
        CreateNewInvoice(SalesHeader);
        O365SalesInvoice.OpenEdit;
        O365SalesInvoice.GotoRecord(SalesHeader);
        O365SalesInvoice.Post.Invoke;

        // [THEN] The email wizard does not show up, but the send email interface does
        // Note: handler is called
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSetupIsTriggeredIfEmptyEmailInWeb()
    var
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] Standard invoicing SMTP setup with empty email and password
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] Trying to send an invoice
        CreateNewInvoice(SalesHeader);
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoRecord(SalesHeader);

        // [THEN] The email wizard is open; if closed, an error is triggered
        // Note: handler is called
        BCO365SalesInvoice.Post.Invoke;
        Assert.ExpectedError('');

        TaxArea.FindFirst();
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
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] Standard invoicing SMTP setup with non-empty email a password
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] Trying to send an invoice
        CreateNewInvoice(SalesHeader);
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoRecord(SalesHeader);
        BCO365SalesInvoice.Post.Invoke;

        // [THEN] The email wizard does not show up, but the send email interface does
        // Note: handler is called

        TaxArea.FindFirst();
        LibraryNotificationMgt.RecallNotificationsForRecord(TaxArea);
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
        O365SalesEmailDialog.Run();

        Assert.IsFalse(O365SalesEmailDialogTestPage.Body.Visible, 'Email body is visible');

        O365SalesEmailDialogTestPage.Trap;
        O365SalesEmailDialog.SetValues(DummyVar, TempEmailItem);
        O365SalesEmailDialog.Run();

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
        O365SalesEmailDialog.Run();

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
        SalesHeader.FindFirst();
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

