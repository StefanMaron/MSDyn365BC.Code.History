#if not CLEAN21
codeunit 138944 "BC O365 Tax Tests"
{
    Subtype = Test;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
#pragma warning disable AS0072
    ObsoleteTag = '21.0';
#pragma warning restore AS0072

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Simplified] [Tax]
    end;

    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        TestProxyNotifMgtExt: Codeunit "Test Proxy Notif. Mgt. Ext.";
        IsInitialized: Boolean;
        TaxSetupNeededMsg: Label 'You haven''t set up tax information for your business.';
        ItemPrice: Decimal;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,BCO365TestSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationDoesNotAppearInTestInvoiceWhenTaxIsNotSet()
    var
        SalesHeader: Record "Sales Header";
        O365SalesTestInvoicePage: TestPage "O365 Sales Test Invoice Page";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] A clean Invoicing App with no tax setup
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] User creates a simple invoice for the first time and adds a customer
        O365SalesTestInvoicePage.OpenEdit;
        O365SalesTestInvoicePage."Create Test Invoice".Invoke;

        // [THEN] a notification does not appear for tax setup pops up (handler), send test action is vsible and draft no. is visible

        // Open test invoice in edit mode
        SalesHeader.FindLast();
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoRecord(SalesHeader);

        // [THEN] a notification does not appear

        LibraryNotificationMgt.ClearTemporaryNotificationContext;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,BCO365TestSalesInvoicePageHandler,TaxSetupModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestCardOpensWhenTaxLiableIsSetOnTestInvoice()
    var
        SalesHeader: Record "Sales Header";
        O365SalesTestInvoicePage: TestPage "O365 Sales Test Invoice Page";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] A clean Invoicing App with no tax setup
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] User creates a simple invoice for the first time and adds a customer (handler)
        O365SalesTestInvoicePage.OpenEdit;
        O365SalesTestInvoicePage."Create Test Invoice".Invoke;

        // [WHEN] Open test invoice in edit mode
        SalesHeader.FindLast();
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoRecord(SalesHeader);

        // [WHEN] User sets tax liable to true
        BCO365SalesInvoice."Tax Liable".SetValue(true);

        // [THEN] The tax setup card is opened (handler)

        // [WHEN] User select another customer
        BCO365SalesInvoice."Sell-to Customer Name".Value(LibraryInvoicingApp.CreateCustomer);

        // [THEN] Tax liable is set
        Assert.AreEqual(true, BCO365SalesInvoice."Tax Liable".AsBoolean, 'Tax liable state should be persisted once user changes it');

        LibraryNotificationMgt.ClearTemporaryNotificationContext;
    end;

    [Test]
    [HandlerFunctions('SendTaxSetupNeededNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationInInvoiceWhenTaxIsNotSet()
    var
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] A clean Invoicing App with no tax setup
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] User creates a simple invoice for the first time and adds a customer
        ItemPrice := LibraryRandom.RandDec(100, 2);
        BCO365SalesInvoice.OpenNew();
        BCO365SalesInvoice."Sell-to Customer Name".Value(LibraryInvoicingApp.CreateCustomer);
        BCO365SalesInvoice.Lines.New;
        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        BCO365SalesInvoice.Lines."Unit Price".SetValue(ItemPrice);

        // [THEN] a notification for tax setup pops up (handler)

        LibraryNotificationMgt.ClearTemporaryNotificationContext;
    end;

    [Test]
    [HandlerFunctions('SendTaxSetupNeededNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationInEstimateWhenTaxIsNotSet()
    var
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
    begin
        // [GIVEN] A clean Invoicing App with no tax setup
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] User creates a simple estimate for the first time and adds a customer
        ItemPrice := LibraryRandom.RandDec(100, 2);
        BCO365SalesQuote.OpenNew();
        BCO365SalesQuote."Sell-to Customer Name".Value(LibraryInvoicingApp.CreateCustomer);
        BCO365SalesQuote.Lines.New;
        BCO365SalesQuote.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        BCO365SalesQuote.Lines."Unit Price".SetValue(ItemPrice);

        // [THEN] a notification for tax setup pops up (handler)

        LibraryNotificationMgt.ClearTemporaryNotificationContext;
    end;

    [Test]
    [HandlerFunctions('SendTaxSetupNeededNotificationHandler,TaxSetupModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestDrilldownOnTaxRate()
    var
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] A clean Invoicing App with no tax setup
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] User creates a simple invoice for the first time and adds a customer
        ItemPrice := LibraryRandom.RandDec(100, 2);
        BCO365SalesInvoice.OpenNew();
        BCO365SalesInvoice."Sell-to Customer Name".Value(LibraryInvoicingApp.CreateCustomer);
        BCO365SalesInvoice.Lines.New;
        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        BCO365SalesInvoice.Lines."Unit Price".SetValue(ItemPrice);

        // [THEN] A notification for tax setup pops up (handler)
        // [THEN] A drilldown for tax rate should appear, that opens the tax setup card (handler)
        BCO365SalesInvoice.TaxAreaDescription.DrillDown;

        LibraryNotificationMgt.ClearTemporaryNotificationContext;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendTaxSetupNeededNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
        Assert.AreEqual(TaxSetupNeededMsg,
          LibraryVariableStorage.DequeueText,
          'Unexpected notificaiton message');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TaxSetupModalPageHandler(var BCO365TaxSettingsCard: TestPage "BC O365 Tax Settings Card")
    begin
        BCO365TaxSettingsCard.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BCO365TestSalesInvoicePageHandler(var BCO365SalesInvoice: TestPage "BC O365 Sales Invoice")
    begin
        Assert.IsTrue(BCO365SalesInvoice.SendTest.Visible, 'Send draft is not visible on draft invoice before inserting customer');
        Assert.IsFalse(BCO365SalesInvoice.Post.Visible, 'Send invoice is visible on draft invoice before inserting customer');
        BCO365SalesInvoice."Sell-to Customer Name".Value(LibraryInvoicingApp.CreateCustomer);
        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        Assert.IsTrue(BCO365SalesInvoice.NextInvoiceNo.Visible, 'Draft No. should be visible in test invoice');
        Assert.AreNotEqual(BCO365SalesInvoice.NextInvoiceNo.Value, '', 'Draft No. should be visible in test invoice');
        BCO365SalesInvoice.Close();
    end;

    local procedure Init()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
    begin
        LibraryVariableStorage.AssertEmpty;
        Clear(ItemPrice);
        EventSubscriberInvoicingApp.Clear();
        ApplicationArea('#Invoicing');
        O365SalesInitialSetup.Get();

        if IsInitialized then
            exit;

        if not O365C2GraphEventSettings.Get() then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify();

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);
        BindSubscription(TestProxyNotifMgtExt);

        WorkDate(Today);
        IsInitialized := true;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}
#endif