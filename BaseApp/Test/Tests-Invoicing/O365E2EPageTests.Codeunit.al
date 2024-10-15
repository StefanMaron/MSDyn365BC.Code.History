#if not CLEAN21
codeunit 138910 "O365 E2E Page Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [E2E] [UI]
    end;

    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        LibraryWorkflow: Codeunit "Library - Workflow";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        EmailProvider: Option "Office 365",Other;
        IsInitialized: Boolean;
        MarkedPaidMsg: Label 'Invoice payment was registered.';
        MarkedUnpaidMsg: Label 'Payment registration was removed.';
        MarkAsUnpaidConfirmQst: Label 'Cancel this payment registration?';
        HasEmailSetupBeenCalled: Boolean;
        ItemDescription: Text[100];
        ItemPrice: Decimal;
        CustomerName: Text[100];
        CancelPostedInvoiceQst: Label 'The invoice will be canceled and a cancelation email will be sent to the customer.\ \Do you want to continue?';
        CancelPostedInvoiceMsg: Label 'The invoice has been canceled and an email has been sent to the customer.';
        CanceledTxt: Label 'Canceled';
        SetRecipientEmailAddress: Boolean;
        CancelationEmailSubjectTxt: Label 'Your invoice has been canceled.';
        SetupTaxInFirstInvoiceWizard: Boolean;
        TaxableTxt: Label 'TAXABLE', Locked = true;
        PaymentTermsErr: Label '1M(8D) should not be on the page.';
        TotalInvoiceAmountNegativeErr: Label 'The total amount for the invoice must be 0 or greater.';
        ProcessDraftInvoiceInstructionTxt: Label 'Do you want to keep the new invoice?';
        CustomerCreatedMsg: Label 'We added %1 to your customer list.';
        CustomerHasBeenBlockedMsg: Label 'The customer has been blocked for further business.';
        BlockQst: Label 'The customer could not be deleted as there are one or more documents for the customer.\ \Do you want to block the customer for further business?';
        TaxSetupNeededMsg: Label 'You haven''t set up tax information for your business.';
        UnhandledNotificationErr: Label 'Unhandled notification: %1.';

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestCannotSendInvoiceWithNegativeAmount()
    var
        DummySalesHeader: Record "Sales Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        ErrorMessages: TestPage "Error Messages";
        InvoiceNo: Code[20];
    begin
        // [GIVEN] A clean Invoicing App
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] User creates an invoice with total negative amount
        InvoiceNo := LibraryInvoicingApp.CreateInvoiceWithItemPriceExclTax(LibraryRandom.RandDecInRange(-100, -1, 2));

        // [WHEN] Send the Invoice
        ErrorMessages.Trap();
        LibraryInvoicingApp.SendInvoice(InvoiceNo);

        // [THEN] An error message about Total Amount sign is shown in "Error Messages" page
        Assert.ExpectedMessage(TotalInvoiceAmountNegativeErr, ErrorMessages.Description.Value);
        ErrorMessages.Close();

        // [WHEN] User corrects the amount to be positive
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoKey(DummySalesHeader."Document Type"::Invoice, InvoiceNo);
        BCO365SalesInvoice.Lines."Unit Price".Value := Format(LibraryRandom.RandDecInRange(0, 100, 2));
        BCO365SalesInvoice.Close();

        // [THEN] Sending succeeds
        LibraryInvoicingApp.SendInvoice(InvoiceNo);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestCreateCustomer()
    var
        Customer: Record Customer;
    begin
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A clean Invoicing App
        // [WHEN] User opens the customer card and types in a name
        // [THEN] A customer has been created
        Customer.SetRange(Name, LibraryInvoicingApp.CreateCustomer);
        Assert.RecordCount(Customer, 1);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestCreateItem()
    var
        Item: Record Item;
    begin
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A clean Invoicing App
        // [WHEN] User opens the item card and types in a description
        // [THEN] An item has been created
        Item.SetRange(Description, LibraryInvoicingApp.CreateItem);
        Assert.RecordCount(Item, 1);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestSendInvoice()
    begin
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A clean Invoicing App
        // [WHEN] User creates and sends a simple invoice, customer and item from the pages
        // [THEN] An invoice has been sent
        CreateAndSendInvoice;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestSendInvoiceForPhoneByTypingName()
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A clean Invoicing App
        // [WHEN] User creates and sends a simple invoice, customer and item from the pages
        // [THEN] An invoice has been sent
        BCO365SalesInvoice.OpenNew();
        BCO365SalesInvoice.PhoneSellToCustomerName.Value(LibraryInvoicingApp.CreateCustomerWithEmail);

        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        BCO365SalesInvoice.Lines."Unit Price".SetValue(100.0);

        SalesHeader.SetRange("Sell-to Customer Name", BCO365SalesInvoice."Sell-to Customer Name".Value);
        SalesHeader.FindFirst();

        BCO365SalesInvoice.Close();

        Assert.AreNotEqual(LibraryInvoicingApp.SendInvoice(SalesHeader."No."), '', 'Invoice could not be sent');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler,LookupCustomerHandler')]
    [Scope('OnPrem')]
    procedure TestSendInvoiceForPhoneByClickingDropDown()
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A clean Invoicing App
        // [WHEN] User creates and sends a simple invoice, customer and item from the pages
        // [THEN] An invoice has been sent
        BCO365SalesInvoice.OpenNew();
        BCO365SalesInvoice.PhoneSellToCustomerName.Lookup;
        Assert.AreNotEqual(BCO365SalesInvoice.PhoneSellToCustomerName.Value, '', 'Customer has not been set');

        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        BCO365SalesInvoice.Lines."Unit Price".SetValue(100.0);

        SalesHeader.SetRange("Sell-to Customer Name", BCO365SalesInvoice."Sell-to Customer Name".Value);
        SalesHeader.FindFirst();

        BCO365SalesInvoice.Close();

        Assert.AreNotEqual(LibraryInvoicingApp.SendInvoice(SalesHeader."No."), '', 'Invoice could not be sent');
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,MessageHandler,MarkAsPaidHandler,MarkAsUnpaidConfirmHandler,EmailFailedSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestMarkAsFullyPaidE2E()
    var
        PostedInvoiceNo: Code[20];
    begin
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A clean Invoicing App
        // [GIVEN] User has created a customer and an item from the pages
        // [GIVEN] User has created and send a simple invoice
        PostedInvoiceNo := CreateAndSendInvoice;

        // [WHEN] User marks the invoice as fully paid
        AddPaymentForInvoice(PostedInvoiceNo, false);
        // [THEN] There is one payment for the invoice
        // [THEN] The invoice is closed
        VerifyNoPaymentsForInvoice(PostedInvoiceNo, 1, true);

        // [WHEN] User marks the invoice as unpaid
        // [THEN] There are no payments for the invoice
        // [THEN] The invoice is not closed
        RemoveLastPaymentForInvoice(PostedInvoiceNo);
        VerifyNoPaymentsForInvoice(PostedInvoiceNo, 0, false);

        // [WHEN] User marks the invoice as fully paid again
        AddPaymentForInvoice(PostedInvoiceNo, false);
        // [THEN] There is one payment for the invoice
        // [THEN] The invoice is closed
        VerifyNoPaymentsForInvoice(PostedInvoiceNo, 1, true);

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,MessageHandler,MarkAsPaidHandler,MarkAsUnpaidHandler,MarkAsUnpaidConfirmHandler,EmailFailedSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestMarkAsPartiallyPaidE2E()
    var
        PostedInvoiceNo: Code[20];
    begin
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A clean Invoicing App
        // [GIVEN] User has created a customer and an item from the pages
        // [GIVEN] User has created and send a simple invoice
        PostedInvoiceNo := CreateAndSendInvoice;

        // [WHEN] User makes 3 partial payments
        AddPaymentForInvoice(PostedInvoiceNo, true);
        AddPaymentForInvoice(PostedInvoiceNo, true);
        AddPaymentForInvoice(PostedInvoiceNo, true);
        // [THEN] There are 3 partial payments for the invoice
        // [THEN] The invoice is not closed
        VerifyNoPaymentsForInvoice(PostedInvoiceNo, 3, false);

        // [WHEN] User removes the two last payments
        RemoveLastPaymentForInvoice(PostedInvoiceNo);
        RemoveLastPaymentForInvoice(PostedInvoiceNo);
        // [THEN] There is one payment for the invoice
        // [THEN] The invoice is not closed
        VerifyNoPaymentsForInvoice(PostedInvoiceNo, 1, false);

        // [WHEN] User marks the invoice as fully paid
        AddPaymentForInvoice(PostedInvoiceNo, false);
        // [THEN] There are two payments for the invoice
        // [THEN] The invoice is closed
        VerifyNoPaymentsForInvoice(PostedInvoiceNo, 2, true);

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,MessageHandler,MarkAsPaidHandler,FirstInvoiceWizardHandler,EmailFailedSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestFirstInvoiceE2E()
    var
        TaxArea: Record "Tax Area";
        InvoiceNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A clean Invoicing App
        // [GIVEN] User logs in and the First Invoice Wizard is shown
        // [WHEN] User finishes the first invoice wizard
        PAGE.RunModal(PAGE::"O365 First Invoice Wizard");

        // [THEN] An item, customer and invoice has been created
        InvoiceNo := FindLastInvoiceNo;
        TaxArea.SetRange("Country/Region", TaxArea."Country/Region"::CA);
        TaxArea.FindFirst();
        VerifyInvoiceCustomerAndItem(InvoiceNo);
        VerifyInvoiceTax(InvoiceNo, TaxArea);

        // [WHEN] The invoice generated from the first invoice wizard is sent
        SetRecipientEmailAddress := true;
        PostedInvoiceNo := SendInvoice(InvoiceNo);

        // [THEN] There are no error and correct amounts are applied
        VerifyPostedInvoice(PostedInvoiceNo, TaxArea);

        // [WHEN] User marks the invoice as fully paid
        AddPaymentForInvoice(PostedInvoiceNo, false);
        // [THEN] There is one payment for the invoice
        // [THEN] The invoice is closed
        VerifyNoPaymentsForInvoice(PostedInvoiceNo, 1, true);

        // [WHEN] A new customer, item and invoice is created and sent
        CreateAndSendInvoice;

        // [THEN] No errors occurs
        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,MessageHandler,InvoiceCanceledConfirmHandler,EmailFailedSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestCancelSentInvoice()
    var
        PostedInvoiceNo: Code[20];
    begin
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A sent invoice
        PostedInvoiceNo := CreateAndSendInvoice;

        // [WHEN] The invoice is cancelled
        CancelInvoice(PostedInvoiceNo);

        // [THEN] The send email contains a message
        VerifyCancelEmailContent;

        // [THEN] The invoice status is marked as cancelled
        Assert.AreEqual(CanceledTxt, GetDocumentStatus(PostedInvoiceNo, true), '');

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestSetupEmailFromAdvancedSettings()
    begin
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A clean Invoicing App
        // [GIVEN] The user set up Email from the settings pages
        LibraryWorkflow.SetUpEmailAccount();

        // [WHEN] User creates and sends a simple invoice
        // [THEN] No Email setup dialog appears and it has been successfully sent
        CreateAndSendInvoice;
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,MessageHandler,MarkAsPaidHandler,FirstInvoiceWizardHandler,EmailFailedSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestFirstInvoiceWithTaxE2E()
    var
        SalesTaxSetupWizard: Record "Sales Tax Setup Wizard";
        TaxArea: Record "Tax Area";
        InvoiceNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A clean Invoicing App
        // [GIVEN] User logs in and the First Invoice Wizard is shown
        // [WHEN] User finishes the first invoice wizard, having set up tax
        SetRecipientEmailAddress := true;
        SetupTaxInFirstInvoiceWizard := true;
        PAGE.RunModal(PAGE::"O365 First Invoice Wizard");

        // [THEN] An item, customer and invoice has been created with correct amounts
        InvoiceNo := FindLastInvoiceNo;
        SalesTaxSetupWizard.FindFirst();
        TaxArea.Get(SalesTaxSetupWizard."Tax Area Code");
        VerifyInvoiceCustomerAndItem(InvoiceNo);
        VerifyInvoiceTax(InvoiceNo, TaxArea);

        // [WHEN] The invoice generated from the first invoice wizard is sent
        PostedInvoiceNo := SendInvoice(InvoiceNo);
        // [THEN] There are no error and correct amounts are applied
        VerifyPostedInvoice(PostedInvoiceNo, TaxArea);

        // [WHEN] User marks the invoice as fully paid
        AddPaymentForInvoice(PostedInvoiceNo, false);
        // [THEN] There is one payment for the invoice
        // [THEN] The invoice is closed
        VerifyNoPaymentsForInvoice(PostedInvoiceNo, 1, true);

        // [WHEN] A new customer, item and invoice is created and sent
        CreateAndSendInvoice;

        // [THEN] No errors occurs
        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,FirstInvoiceWizardHandler,EmailFailedSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestFirstInvoiceWithTaxChangeTaxSettingsE2E()
    var
        SalesTaxSetupWizard: Record "Sales Tax Setup Wizard";
        TaxArea: Record "Tax Area";
        InvoiceNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A clean Invoicing App
        // [GIVEN] User logs in and the First Invoice Wizard is shown
        // [GIVEN] User finishes the first invoice wizard, having set up tax
        SetRecipientEmailAddress := true;
        SetupTaxInFirstInvoiceWizard := true;
        PAGE.RunModal(PAGE::"O365 First Invoice Wizard");

        // [GIVEN] Tax has been set up through the settings menu
        SetupTaxFromSettingsMenu;

        // [THEN] An item, customer and invoice has been created with correct amounts
        InvoiceNo := FindLastInvoiceNo;
        SalesTaxSetupWizard.FindFirst();
        TaxArea.Get(SalesTaxSetupWizard."Tax Area Code");
        VerifyInvoiceCustomerAndItem(InvoiceNo);
        VerifyInvoiceTax(InvoiceNo, TaxArea);

        // [WHEN] The invoice generated from the first invoice wizard is sent
        PostedInvoiceNo := SendInvoice(InvoiceNo);
        // [THEN] There are no error and correct amounts are applied
        VerifyPostedInvoice(PostedInvoiceNo, TaxArea);

        // [WHEN] A new customer, item and invoice is created and sent
        PostedInvoiceNo := CreateAndSendInvoice;

        // [THEN] There are no error and correct amounts are applied
        VerifyPostedInvoice(PostedInvoiceNo, TaxArea);

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,EmailFailedSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestSendInvoiceWithTax()
    var
        SalesTaxSetupWizard: Record "Sales Tax Setup Wizard";
        TaxArea: Record "Tax Area";
        PostedInvoiceNo: Code[20];
    begin
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A clean Invoicing App
        // [GIVEN] Tax has been set up through the settings menu
        SetupTaxFromSettingsMenu;

        // [WHEN] User creates and sends a simple invoice, customer and item from the pages
        // [THEN] An invoice has been sent
        PostedInvoiceNo := CreateAndSendInvoice;

        // [THEN] There are no error and correct amounts are applied
        SalesTaxSetupWizard.FindFirst();
        TaxArea.Get(SalesTaxSetupWizard."Tax Area Code");
        VerifyPostedInvoice(PostedInvoiceNo, TaxArea);

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,EmailFailedSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestCreateInvoiceWithoutTaxThenAddTax()
    var
        TaxArea: Record "Tax Area";
        InvoiceNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A clean Invoicing App

        // [GIVEN] An invoice has been created
        InvoiceNo := CreateInvoice;
        TaxArea.SetRange("Country/Region", TaxArea."Country/Region"::CA);
        TaxArea.FindFirst();
        VerifyInvoiceTax(InvoiceNo, TaxArea);

        // [WHEN] Tax has been changed
        SetupTaxFromSettingsMenu;

        // [THEN] Tax has also been updated in the invoice
        VerifyInvoiceTax(InvoiceNo, TaxArea);

        // [WHEN] The invoice is posted
        SetRecipientEmailAddress := true;
        PostedInvoiceNo := SendInvoice(InvoiceNo);

        // [THEN] The posted invoice contains correct amounts (including VAT)
        VerifyPostedInvoice(PostedInvoiceNo, TaxArea);

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,EmailFailedSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestCreateInvoiceWithTaxThenChangeTax()
    var
        SalesTaxSetupWizard: Record "Sales Tax Setup Wizard";
        TaxArea: Record "Tax Area";
        PostedInvoiceNo: Code[20];
    begin
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A clean Invoicing App
        // [GIVEN] Tax has been set up through the settings menu
        SetupTaxFromSettingsMenu;

        // [WHEN] User creates and sends a simple invoice, customer and item from the pages
        // [THEN] An invoice has been sent
        PostedInvoiceNo := CreateAndSendInvoice;

        // [THEN] There are no error and correct amounts are applied
        SalesTaxSetupWizard.FindFirst();
        TaxArea.Get(SalesTaxSetupWizard."Tax Area Code");
        VerifyPostedInvoice(PostedInvoiceNo, TaxArea);

        // [WHEN] User changes tax in the Tax Setup page
        TaxArea.Get(ChangeTaxFromSettingsMenu);

        // [WHEN] User creates and sends a simple invoice, customer and item from the pages
        // [THEN] An invoice has been sent
        PostedInvoiceNo := CreateAndSendInvoice;

        // [THEN] There are no error and correct amounts are applied
        VerifyPostedInvoice(PostedInvoiceNo, TaxArea);

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestPaymentTerms()
    var
        PaymentTermsPage: TestPage "O365 Payment Terms List";
    begin
        // The correct payment terms should be shown to the user on the payment term list
        Init();
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] Payment Terms List page is run.
        PaymentTermsPage.OpenView;

        // [THEN] 1Month/8% Days should not be in the pages data
        PaymentTermsPage.FILTER.SetFilter(Description, '1 Month/2% 8 days');
        Assert.IsFalse(PaymentTermsPage.First, PaymentTermsErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SendNotificationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerDeleteFromLookupBC()
    var
        Customer: Record Customer;
        O365SalesManagement: Codeunit "O365 Sales Management";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        Init();

        // [GIVEN] Invoicing app user creates a new invoice
        LibraryLowerPermissions.SetInvoiceApp;
        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);
        BCO365SalesInvoice.OpenNew();

        // [WHEN] User looks up customer name, creates a new customer and then decides to delete it
        CustomerName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)), 1, MaxStrLen(Customer.Name));
        BCO365SalesCustomerCard.OpenNew();
        BCO365SalesCustomerCard.Name.Value := CustomerName;
        Customer.SetRange(Name, CustomerName);
        Customer.FindFirst();
        O365SalesManagement.BlockOrDeleteCustomerAndDeleteContact(Customer);

        // [THEN] The customer is deleted
        Customer.SetRange(Name, CustomerName);
        asserterror Customer.FindFirst();

        // [WHEN] The user manually inserts the customer name
        LibraryVariableStorage.Enqueue(StrSubstNo(CustomerCreatedMsg, CustomerName));
        BCO365SalesInvoice."Sell-to Customer Name".Value := CustomerName;

        // [THEN] A customer is created and no error is thrown
        Assert.AreEqual(BCO365SalesInvoice."Sell-to Customer Name".Value, CustomerName, 'Customer name is not kept.');
        LibraryVariableStorage.Enqueue(ProcessDraftInvoiceInstructionTxt);
        LibraryVariableStorage.Enqueue(true);
        BCO365SalesInvoice.Close();

        // [WHEN] The customer has open invoices and the customer is deleted
        Customer.SetRange(Name, CustomerName);
        Assert.RecordCount(Customer, 1);
        Customer.FindFirst();
        Customer.TestField(Blocked, Customer.Blocked::" ");
        BCO365SalesCustomerCard.OpenEdit;
        BCO365SalesCustomerCard.GotoRecord(Customer);
        LibraryVariableStorage.Enqueue(BlockQst);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(CustomerHasBeenBlockedMsg);
        O365SalesManagement.BlockOrDeleteCustomerAndDeleteContact(Customer);

        // [THEN] Customer is blocked
        Customer.SetRange(Name, CustomerName);
        Assert.RecordCount(Customer, 1);
        Customer.FindFirst();
        Assert.AreEqual(Customer.Blocked, Customer.Blocked::All, 'Customer is not realy blocked.');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure AddPaymentForInvoice(DocumentNo: Code[20]; PartialPayment: Boolean)
    var
        O365PostedSalesInvoice: TestPage "O365 Posted Sales Invoice";
    begin
        O365PostedSalesInvoice.OpenView;
        O365PostedSalesInvoice.GotoKey(DocumentNo);

        LibraryVariableStorage.Enqueue(PartialPayment);
        LibraryVariableStorage.Enqueue(MarkedPaidMsg);
        O365PostedSalesInvoice.MarkAsPaid.Invoke;
    end;

    local procedure CancelInvoice(PostedInvoiceNo: Code[20])
    var
        O365PostedSalesInvoice: TestPage "O365 Posted Sales Invoice";
    begin
        Commit();
        O365PostedSalesInvoice.OpenView;
        O365PostedSalesInvoice.GotoKey(PostedInvoiceNo);

        LibraryVariableStorage.Enqueue(CancelPostedInvoiceMsg);
        O365PostedSalesInvoice.CancelInvoice.Invoke;
    end;

    local procedure CreateAndSendInvoice() PostedInvoiceNo: Code[20]
    begin
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(CreateInvoice);

        // [THEN] The send email contains a message
        VerifyEmailContent(PostedInvoiceNo);
    end;

    local procedure CreateInvoice() InvoiceNo: Code[20]
    begin
        ItemPrice := LibraryRandom.RandDec(100, 2);
        InvoiceNo := LibraryInvoicingApp.CreateInvoiceWithItemPriceExclTax(ItemPrice);
    end;

    local procedure FindLastInvoiceNo(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FindLast();
        exit(SalesHeader."No.");
    end;

    local procedure GetDocumentStatus(DocumentNo: Code[20]; Posted: Boolean): Text
    var
        DummyO365SalesDocument: Record "O365 Sales Document";
        O365SalesDocumentList: TestPage "O365 Sales Document List";
    begin
        O365SalesDocumentList.OpenView;
        O365SalesDocumentList.GotoKey(DummyO365SalesDocument."Document Type"::Invoice, DocumentNo, Posted);
        exit(O365SalesDocumentList."Outstanding Status".Value);
    end;

    local procedure PriceTextToDecimal(PriceText: Text) Price: Decimal
    begin
        Evaluate(Price, DelChr(PriceText, '=', DelChr(PriceText, '=', '0123456789.,')));
    end;

    local procedure RemoveLastPaymentForInvoice(DocumentNo: Code[20])
    var
        O365PostedSalesInvoice: TestPage "O365 Posted Sales Invoice";
    begin
        O365PostedSalesInvoice.OpenView;
        O365PostedSalesInvoice.GotoKey(DocumentNo);

        LibraryVariableStorage.Enqueue(MarkedUnpaidMsg);
        O365PostedSalesInvoice.MarkAsUnpaid.Invoke;
    end;

    local procedure SendInvoice(InvoiceNo: Code[20]) PostedInvoiceNo: Code[20]
    begin
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(InvoiceNo);

        // [THEN] The send email contains a message
        VerifyEmailContent(PostedInvoiceNo);
    end;

    local procedure SetupTaxFromSettingsMenu(): Code[20]
    var
        TaxArea: Record "Tax Area";
        O365TaxSettingsCard: TestPage "O365 Tax Settings Card";
        TaxAreaCode: Code[20];
    begin
        TaxArea.SetRange("Country/Region", TaxArea."Country/Region"::CA);
        TaxArea.FindFirst();
        TaxAreaCode := TaxArea.Code;
        O365TaxSettingsCard.OpenEdit;
        O365TaxSettingsCard.GotoKey(TaxAreaCode);
        O365TaxSettingsCard.Default.DrillDown;
        exit(TaxAreaCode);
    end;

    local procedure ChangeTaxFromSettingsMenu(): Code[20]
    var
        TaxArea: Record "Tax Area";
        O365TaxSettingsCard: TestPage "O365 Tax Settings Card";
        TaxAreaCode: Code[20];
    begin
        TaxArea.SetRange("Country/Region", TaxArea."Country/Region"::CA);
        TaxArea.FindLast();
        TaxAreaCode := TaxArea.Code;
        O365TaxSettingsCard.OpenEdit;
        O365TaxSettingsCard.GotoKey(TaxAreaCode);
        O365TaxSettingsCard.Default.DrillDown;
        exit(TaxAreaCode);
    end;

    local procedure RecallPostedInvoiceNotification(InvoiceNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(InvoiceNo);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesInvoiceHeader);
    end;

    local procedure VerifyNoPaymentsForInvoice(DocumentNo: Code[20]; NoOfPayments: Integer; IsClosed: Boolean)
    var
        TempO365PaymentHistoryBuffer: Record "O365 Payment History Buffer" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        TempO365PaymentHistoryBuffer.FillPaymentHistory(DocumentNo);
        Assert.RecordCount(TempO365PaymentHistoryBuffer, NoOfPayments);

        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        if IsClosed then begin
            Assert.AreNotEqual(0, CustLedgerEntry."Closed by Entry No.", 'Invoice should be closed.');
            CustLedgerEntry.Get(CustLedgerEntry."Closed by Entry No.");
        end else
            Assert.AreEqual(0, CustLedgerEntry."Closed by Entry No.", 'Invoice should not be closed.');
    end;

    local procedure VerifyInvoiceTax(InvoiceNo: Code[20]; TaxArea: Record "Tax Area")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        O365SalesInvoice: TestPage "O365 Sales Invoice";
        O365SalesInvoiceLineCard: TestPage "O365 Sales Invoice Line Card";
        TempTaxRate: Text;
        TaxRate: Decimal;
    begin
        O365SalesInvoice.OpenView;
        O365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, InvoiceNo);
        SalesLine.SetRange("Document No.", InvoiceNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.FindFirst();
        O365SalesInvoiceLineCard.OpenEdit;
        O365SalesInvoiceLineCard.GotoRecord(SalesLine);

        Assert.AreEqual(Round(ItemPrice + ItemPrice * TaxDetail.GetSalesTaxRate(TaxArea.Code, TaxableTxt, WorkDate(), true) / 100, 0.01),
          PriceTextToDecimal(O365SalesInvoice."Amount Including VAT".Value), 'The amount of the unsent invoice is incorrect.');

        TempTaxRate := O365SalesInvoiceLineCard.TaxRate.Value;
        TempTaxRate := CopyStr(TempTaxRate, 1, (StrLen(TempTaxRate) - 1));
        Evaluate(TaxRate, TempTaxRate);
        Assert.AreEqual(TaxDetail.GetSalesTaxRate(TaxArea.Code, TaxableTxt, WorkDate(), true),
          TaxRate, 'The tax rate of the unsent invoice is incorrect.');

        O365SalesInvoiceLineCard.Close();
    end;

    local procedure VerifyInvoiceCustomerAndItem(InvoiceNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        O365SalesInvoice: TestPage "O365 Sales Invoice";
    begin
        // Verify customer name
        O365SalesInvoice.OpenView;
        O365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, InvoiceNo);
        Assert.AreEqual(CustomerName, O365SalesInvoice."Sell-to Customer Name".Value, 'Wrong customer name.');

        // Verify item
        Assert.AreEqual(ItemDescription, O365SalesInvoice.Lines.Description.Value, 'Wrong item description.');
    end;

    local procedure VerifyPostedInvoice(PostedInvoiceNo: Code[20]; TaxArea: Record "Tax Area")
    var
        TaxDetail: Record "Tax Detail";
        O365PostedSalesInvoice: TestPage "O365 Posted Sales Invoice";
    begin
        O365PostedSalesInvoice.OpenView;
        O365PostedSalesInvoice.GotoKey(PostedInvoiceNo);
        Assert.AreEqual(
          Round(ItemPrice + ItemPrice * TaxDetail.GetSalesTaxRate(TaxArea.Code, TaxableTxt, WorkDate(), true) / 100, 0.01),
          PriceTextToDecimal(O365PostedSalesInvoice."Amount Including VAT".Value), 'The sent invoice contains an invalid price');
    end;

    [Scope('OnPrem')]
    procedure VerifyCancelEmailContent()
    var
        EmailSubject: Text;
        EmailBody: Text;
    begin
        EmailSubject := EventSubscriberInvoicingApp.GetEmailSubject;
        EmailBody := EventSubscriberInvoicingApp.GetEmailBody;

        Assert.AreNotEqual(0, StrLen(EmailBody), 'There should be an email body for canceled invoices.');
        Assert.AreEqual(CancelationEmailSubjectTxt, EmailSubject, '');
    end;

    [Scope('OnPrem')]
    procedure VerifyEmailContent(DocumentNo: Code[20])
    var
        DummySalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentMailing: Codeunit "Document-Mailing";
        EmailSubject: Text;
        EmailBody: Text;
    begin
        EmailSubject := EventSubscriberInvoicingApp.GetEmailSubject;
        EmailBody := EventSubscriberInvoicingApp.GetEmailBody;

        Assert.IsTrue(StrLen(EmailBody) > 1024, 'There is no Email body for the sent invoice.');
        Assert.AreEqual(
          DocumentMailing.GetEmailSubject(DocumentNo, DummySalesInvoiceHeader.GetDefaultEmailDocumentName, 2),
          EmailSubject, '');
    end;

    local procedure Init()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        CompanyInformation: Record "Company Information";
        SalesTaxSetupWizard: Record "Sales Tax Setup Wizard";
    begin
        BindActiveDirectoryMockEvents;

        LibraryVariableStorage.AssertEmpty;
        SalesTaxSetupWizard.DeleteAll();
        Clear(CustomerName);
        Clear(ItemDescription);
        Clear(ItemPrice);
        Clear(HasEmailSetupBeenCalled);
        Clear(SetRecipientEmailAddress);
        Clear(SetupTaxInFirstInvoiceWizard);
        ApplicationArea('#Invoicing');

        if IsInitialized then
            exit;

        if not O365C2GraphEventSettings.Get() then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify();

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        WorkDate(Today);

        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := 'CA';
        CompanyInformation.Modify();

        IsInitialized := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        if SetRecipientEmailAddress then
            O365SalesEmailDialog.SendToText.Value('test@microsoft.com');
        O365SalesEmailDialog.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.AreEqual(ExpectedMessage, Message, '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MarkAsPaidHandler(var O365MarkAsPaid: TestPage "O365 Mark As Paid")
    var
        PartialPayment: Variant;
        PartialPaymentBool: Boolean;
        AmountReceived: Decimal;
    begin
        LibraryVariableStorage.Dequeue(PartialPayment);
        PartialPaymentBool := PartialPayment;
        if PartialPaymentBool then begin
            Evaluate(AmountReceived, O365MarkAsPaid.AmountReceived.Value);
            O365MarkAsPaid.AmountReceived.SetValue(AmountReceived / 10);
        end;
        O365MarkAsPaid.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MarkAsUnpaidHandler(var O365PaymentHistoryList: TestPage "O365 Payment History List")
    begin
        O365PaymentHistoryList.Last;
        O365PaymentHistoryList.MarkAsUnpaid.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure MarkAsUnpaidConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(MarkAsUnpaidConfirmQst, Question, '');
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure InvoiceCanceledConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(CancelPostedInvoiceQst, Question, '');
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FirstInvoiceWizardHandler(var O365FirstInvoiceWizard: TestPage "O365 First Invoice Wizard")
    begin
        // Welcome page
        CustomerName := LibraryUtility.GenerateGUID();
        ItemDescription := LibraryUtility.GenerateGUID();
        ItemPrice := LibraryRandom.RandDec(100, 2);
        O365FirstInvoiceWizard.ActionCreateInvoice.Invoke;
        O365FirstInvoiceWizard.CustomerName.Value(CustomerName);
        O365FirstInvoiceWizard.ActionNext.Invoke; // First item
        O365FirstInvoiceWizard.ItemDescription.Value(ItemDescription);
        O365FirstInvoiceWizard.ItemPrice.SetValue(ItemPrice);
        O365FirstInvoiceWizard.ActionNext.Invoke; // show the tax
        if SetupTaxInFirstInvoiceWizard then
            O365FirstInvoiceWizard.TaxAreaCode.SetValue(SetupTaxFromSettingsMenu);
        O365FirstInvoiceWizard.ActionNext.Invoke; // Voila
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LookupCustomerHandler(var BCO365ContactLookup: TestPage "BC O365 Contact Lookup")
    var
        Contact: Record Contact;
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
        CustomerName: Text;
    begin
        BCO365SalesCustomerCard.Trap;
        BCO365ContactLookup._NEW_TEMP_.Invoke;
        CustomerName := LibraryUtility.GenerateGUID();
        BCO365SalesCustomerCard.Name.Value(CustomerName);
        BCO365SalesCustomerCard."E-Mail".Value('test@microsoft.com');
        BCO365SalesCustomerCard.Close();
        Contact.SetRange(Name, CustomerName);
        Contact.FindFirst();
        BCO365ContactLookup.GotoRecord(Contact);
        BCO365ContactLookup.OK.Invoke;
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure EmailFailedSendNotificationHandler(var TheNotification: Notification): Boolean
    begin
        if StrPos(TheNotification.Message, 'The last email about this document could not be sent') <> 0 then
            exit;
        if TheNotification.Message = TaxSetupNeededMsg then
            exit;
        Error(UnhandledNotificationErr, TheNotification.Message);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var TargetNotification: Notification): Boolean
    begin
        Assert.AreEqual(TargetNotification.Message, LibraryVariableStorage.DequeueText, 'Unexpected notification message');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText, Question, '');
        Reply := LibraryVariableStorage.DequeueBoolean;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}
#endif
