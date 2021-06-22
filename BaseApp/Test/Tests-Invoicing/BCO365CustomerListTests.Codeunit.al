codeunit 138943 "BC O365 Customer List Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Customer] [UI]
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        Assert: Codeunit Assert;
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        IsInitialized: Boolean;
        UnblockCustomerQst: Label 'Are you sure you want to unblock the customer for further business?';

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestNormalInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO] Verify customer totals are updated correctly for normal invoices
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [GIVEN] A posted invoice
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(LibraryInvoicingApp.CreateInvoice);
        SalesInvoiceHeader.Get(PostedInvoiceNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] The customer list is opened
        // [THEN] The outstanding reflect the amount in the invoice, while overdue is zero
        VerifyCustomerTotals(
          SalesInvoiceHeader."Sell-to Customer No.",
          SalesInvoiceHeader."Amount Including VAT",// Outstanding
          0);// Overdue

        LibraryNotificationMgt.ClearTemporaryNotificationContext;
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,DocumentDateInThePastNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestInvoiceDueToday()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RecVar: Variant;
    begin
        // [SCENARIO] Verify customer totals are updated correctly for invoices due today
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [GIVEN] A posted invoice with due date today
        SalesInvoiceHeader.Get(SendInvoice(WorkDate));
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] The customer list is opened
        // [THEN] The outstanding reflect the amount in the invoice, while overdue is zero
        VerifyCustomerTotals(
          SalesInvoiceHeader."Sell-to Customer No.",
          SalesInvoiceHeader."Amount Including VAT",// Outstanding
          0);// Overdue

        LibraryVariableStorage.Dequeue(RecVar);
        LibraryNotificationMgt.RecallNotificationsForRecord(RecVar);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,InvoiceSentMessageHandler,DocumentDateInThePastNotificationHandler,MarkAsPaidHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestInvoiceDueYesterday()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RecVar: Variant;
    begin
        // [SCENARIO] Verify customer totals are updated correctly for invoices due in the past
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [GIVEN] A posted invoice with due date yesterday
        SalesInvoiceHeader.Get(SendInvoice(WorkDate - 1));
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] The customer list is opened
        // [THEN] The outstanding, overdue and total sales reflect those in the invoice
        VerifyCustomerTotals(
          SalesInvoiceHeader."Sell-to Customer No.",
          SalesInvoiceHeader."Amount Including VAT",// Outstanding
          SalesInvoiceHeader."Amount Including VAT");// Overdue

        // [WHEN] The invoice is paid
        AddPaymentForInvoiceInWeb(SalesInvoiceHeader."No.");

        // [THEN] The outstanding and overdue is zero
        VerifyCustomerTotals(
          SalesInvoiceHeader."Sell-to Customer No.",
          0,// Outstanding
          0);// Overdue

        LibraryVariableStorage.Dequeue(RecVar);
        LibraryNotificationMgt.RecallNotificationsForRecord(RecVar);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesInvoiceHeader);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBlockedCustomerinList()
    var
        Customer: Record Customer;
        BCO365CustomerList: TestPage "BC O365 Customer List";
    begin
        // [FEATURE] [Blocked]
        // [SCENARIO] Given that a customer has been blocked, When the customer list is displayed, Then that customer record is visible and "blocked" is clearly visible
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [GIVEN] A blocked customer
        LibraryInvoicingApp.CreateBlockedCustomer(Customer);

        // [WHEN] The customer list is opened
        // [THEN] The blocked status is reflected correctly
        BCO365CustomerList.OpenView;
        BCO365CustomerList.GotoRecord(Customer);
        Assert.AreEqual(Customer.FieldCaption(Blocked), BCO365CustomerList.BlockedStatus.Value, 'Wrong customer status');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestBlockedCustomerinCard()
    var
        Customer: Record Customer;
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
    begin
        // [FEATURE] [Blocked]
        // [SCENARIO] Given that a customer is blocked, When the customer page is displayed, Then a check mark "Blocked" is displayed. If C1 unblocks, a pop up is displayed asking if C1 is really sure.
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [GIVEN] A blocked customer
        LibraryInvoicingApp.CreateBlockedCustomer(Customer);

        // [WHEN] The customer card is opened
        // [THEN] Then a editable check mark "Blocked" is displayed
        BCO365SalesCustomerCard.OpenView;
        BCO365SalesCustomerCard.GotoRecord(Customer);
        Assert.IsTrue(BCO365SalesCustomerCard.BlockedStatus.Visible, 'Blocked field is not visible on customer card');

        // [WHEN] C1 unblocks the customer
        LibraryVariableStorage.Enqueue(UnblockCustomerQst);
        BCO365SalesCustomerCard.BlockedStatus.SetValue(false);

        // [THEN] A pop up is displayed (in handler)
        BCO365SalesCustomerCard.Close;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestContactIsRecreatedWhenCustomerIsUnblocked()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
    begin
        // [FEATURE] [Blocked]
        // [SCENARIO] Given that a customer is blocked, When C1 unblocks, the contact is recreated.
        LibraryLowerPermissions.SetInvoiceApp;
        Initialize;

        // [GIVEN] A blocked customer
        LibraryInvoicingApp.CreateBlockedCustomer(Customer);

        // [WHEN] The customer card is opened
        // [THEN] Then a editable check mark "Blocked" is displayed
        BCO365SalesCustomerCard.OpenView;
        BCO365SalesCustomerCard.GotoRecord(Customer);
        Assert.IsTrue(BCO365SalesCustomerCard.BlockedStatus.Visible, 'Blocked field is not visible on customer card');

        // [WHEN] C1 unblocks the customer
        LibraryVariableStorage.Enqueue(UnblockCustomerQst);
        BCO365SalesCustomerCard.BlockedStatus.SetValue(false);

        // [THEN] A pop up is displayed (in handler)

        // [THEN] Contact is recreated
        Assert.IsTrue(Contact.Get(FindContactNoByCustomer(Customer."No.")), 'Contact is not created for unblocked customer');
    end;

    local procedure Initialize()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        EventSubscriberInvoicingApp.Clear;
        LibraryInvoicingApp.SetupEmail;
        LibraryVariableStorage.Clear;
        if IsInitialized then
            exit;

        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider;
        LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify;

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        WorkDate(Today);

        IsInitialized := true;
    end;

    local procedure VerifyCustomerTotals(CustomerNo: Code[20]; Outstanding: Decimal; Overdue: Decimal)
    var
        BCO365CustomerList: TestPage "BC O365 Customer List";
    begin
        BCO365CustomerList.OpenView;
        BCO365CustomerList.GotoKey(CustomerNo);
        Assert.AreEqual(Outstanding, BCO365CustomerList."Balance (LCY)".AsDEcimal, 'Wrong outstanding amount');
        Assert.AreEqual(Overdue, BCO365CustomerList.OverdueAmount.AsDEcimal, 'Wrong overdue amount');
        Assert.AreEqual('', BCO365CustomerList.BlockedStatus.Value, 'Wrong customer status');
    end;

    local procedure SendInvoice(DueDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        InvoiceNo: Code[20];
    begin
        InvoiceNo := LibraryInvoicingApp.CreateInvoice;
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, InvoiceNo);
        BCO365SalesInvoice."Document Date".SetValue(DueDate - 5);
        BCO365SalesInvoice."Due Date".SetValue(DueDate);
        BCO365SalesInvoice.Close;
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, InvoiceNo);
        LibraryVariableStorage.Enqueue(SalesHeader);
        exit(LibraryInvoicingApp.SendInvoice(InvoiceNo));
    end;

    local procedure AddPaymentForInvoiceInWeb(DocumentNo: Code[20])
    var
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
    begin
        BCO365PostedSalesInvoice.OpenView;
        BCO365PostedSalesInvoice.GotoKey(DocumentNo);
        BCO365PostedSalesInvoice.MarkAsPaid.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        O365SalesEmailDialog.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure InvoiceSentMessageHandler(Message: Text[1024])
    begin
        exit;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure DocumentDateInThePastNotificationHandler(var TheNotification: Notification): Boolean
    begin
        exit(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MarkAsPaidHandler(var O365MarkAsPaid: TestPage "O365 Mark As Paid")
    begin
        O365MarkAsPaid.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText, Question, 'Incorrect confirm question');
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText, Question, 'Incorrect confirm question');
        Reply := false;
    end;

    local procedure FindContactNoByCustomer(CustomerNo: Code[20]): Code[20]
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, CustomerNo);
        exit(ContBusRel."Contact No.");
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var TheNotification: Notification): Boolean
    begin
    end;
}

