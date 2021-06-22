codeunit 138946 "BC Test Invoice"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Sales] [Invoice] [UI]
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        CannotSendTestInvoiceErr: Label 'You cannot send a test invoice.';

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceVisibilityFromGettingStarted()
    var
        SalesHeader: Record "Sales Header";
        O365SetupMgmt: Codeunit "O365 Setup Mgmt";
    begin
        // [GIVEN] A clean Invoicing App
        Init;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The users have no documents
        SalesHeader.DeleteAll();

        // [THEN] Users see the test invoice button
        Assert.IsTrue(O365SetupMgmt.ShowCreateTestInvoice, 'Test invoice button is visible from Getting Started window.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceNonVisibilityFromGettingStarted()
    var
        O365SetupMgmt: Codeunit "O365 Setup Mgmt";
    begin
        // [GIVEN] A clean Invoicing App
        Init;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] The users have some documents
        LibraryInvoicingApp.CreateInvoice;

        // [THEN] Users doesn't see the test invoice button
        Assert.IsFalse(O365SetupMgmt.ShowCreateTestInvoice, 'Test invoice button is not visible from Getting Started window.');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,BCO365TestSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreateTestInvoice()
    var
        O365SalesTestInvoiceTest: TestPage "O365 Sales Test Invoice Page";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        LibraryLowerPermissions.SetInvoiceApp;
        Init;

        // [GIVEN] Create new test invoice
        O365SalesTestInvoiceTest.OpenEdit;
        O365SalesTestInvoiceTest."Create Test Invoice".Invoke;

        // [WHEN] The invoice page is re-opened
        OpenInvoice(BCO365SalesInvoice);

        // [THEN] The send test invoice action is visible
        Assert.IsTrue(BCO365SalesInvoice.SendTest.Visible, 'Send draft is not visible on draft invoice after inserting customer');
        Assert.IsFalse(BCO365SalesInvoice.Post.Visible, 'Send invoice is visible on draft invoice after reopening page');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,BCO365NormalSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CreateNormalInvoice()
    var
        O365SalesTestInvoiceTest: TestPage "O365 Sales Test Invoice Page";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        LibraryLowerPermissions.SetInvoiceApp;
        Init;

        // [GIVEN] Create new normal invoice
        O365SalesTestInvoiceTest.OpenEdit;
        O365SalesTestInvoiceTest."Create Normal Invoice".Invoke;

        // [WHEN] The invoice page is re-opened
        OpenInvoice(BCO365SalesInvoice);

        // [THEN] The send test invoice action is visible
        Assert.IsTrue(BCO365SalesInvoice.Post.Visible, 'Send is not visible on draft invoice after inserting customer');
        Assert.IsFalse(BCO365SalesInvoice.SendTest.Visible, 'Send draft invoice is visible on draft invoice after reopening page');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,BCO365TestSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure SendTestInvoice()
    var
        SalesHeader: Record "Sales Header";
        O365SalesTestInvoiceTest: TestPage "O365 Sales Test Invoice Page";
    begin
        LibraryLowerPermissions.SetInvoiceApp;
        Init;

        // [GIVEN] Create new test invoice
        O365SalesTestInvoiceTest.OpenEdit;
        O365SalesTestInvoiceTest."Create Test Invoice".Invoke;

        // [WHEN] This invoice is posted
        // [THEN] An error is thrown, posting a test invoice is not allowed
        SalesHeader.FindLast;
        asserterror CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);
        Assert.ExpectedError(CannotSendTestInvoiceErr);
    end;

    local procedure OpenInvoice(var BCO365SalesInvoice: TestPage "BC O365 Sales Invoice")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.FindLast;
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoRecord(SalesHeader);
    end;

    local procedure Init()
    begin
        if IsInitialized then
            exit;

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        IsInitialized := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BCO365TestSalesInvoicePageHandler(var BCO365SalesInvoice: TestPage "BC O365 Sales Invoice")
    begin
        Assert.IsTrue(BCO365SalesInvoice.SendTest.Visible, 'Send draft is not visible on draft invoice before inserting customer');
        Assert.IsFalse(BCO365SalesInvoice.Post.Visible, 'Send invoice is visible on draft invoice before inserting customer');
        BCO365SalesInvoice."Sell-to Customer Name".Value(LibraryInvoicingApp.CreateCustomer);
        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        Assert.IsTrue(BCO365SalesInvoice.SendTest.Visible, 'Send draft is not visible on draft invoice after inserting customer');
        Assert.IsFalse(BCO365SalesInvoice.Post.Visible, 'Send invoice is visible on draft invoice after inserting customer');
        BCO365SalesInvoice.Close;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BCO365NormalSalesInvoicePageHandler(var BCO365SalesInvoice: TestPage "BC O365 Sales Invoice")
    begin
        Assert.IsTrue(BCO365SalesInvoice.Post.Visible, 'Send is not visible on draft invoice before inserting customer');
        Assert.IsFalse(BCO365SalesInvoice.SendTest.Visible, 'Send draft invoice is visible on draft invoice before inserting customer');
        BCO365SalesInvoice."Sell-to Customer Name".Value(LibraryInvoicingApp.CreateCustomer);
        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        Assert.IsTrue(BCO365SalesInvoice.Post.Visible, 'Send is not visible on draft invoice after inserting customer');
        Assert.IsFalse(BCO365SalesInvoice.SendTest.Visible, 'Send draft invoice is visible on draft invoice after inserting customer');
        BCO365SalesInvoice.Close;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

