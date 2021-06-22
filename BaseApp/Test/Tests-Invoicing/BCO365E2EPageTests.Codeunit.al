codeunit 138940 "BC O365 E2E Page Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [E2E] [UI]
    end;

    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        DocumentMailing: Codeunit "Document-Mailing";
        MailManagement: Codeunit "Mail Management";
        LibraryUtility: Codeunit "Library - Utility";
        EmailProvider: Option "Office 365",Other;
        IsInitialized: Boolean;
        MarkedPaidMsg: Label 'Invoice payment was registered.';
        MarkedUnpaidMsg: Label 'Payment registration was removed.';
        MarkAsUnpaidConfirmQst: Label 'Cancel this payment registration?';
        CancelPostedInvoiceQst: Label 'The invoice will be canceled and a cancelation email will be sent to the customer.\ \Do you want to continue?';
        CancelPostedInvoiceMsg: Label 'The invoice has been canceled and an email has been sent to the customer.';
        CanceledTxt: Label 'Canceled';
        TestTxt: Label 'Test';
        CancelationEmailSubjectTxt: Label 'Your invoice has been canceled.';
        LastEmailFailedNotificationPrefixTxt: Label 'The last email about this document could not be sent';

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler,BCEmailSetupPageHandler')]
    [Scope('OnPrem')]
    procedure TestSendInvoiceInWeb()
    begin
        Init;
        LibraryE2EPlanPermissions.SetInvoicingUserPlan;

        // [GIVEN] A clean Invoicing App
        // [WHEN] User creates and sends a simple invoice, customer and item from the pages
        // [THEN] An invoice has been sent
        CreateAndSendInvoiceInWeb;
        LibraryNotificationMgt.ClearTemporaryNotificationContext;
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,EmailDialogModalPageHandler,BCEmailSetupPageHandler,MessageHandler,MarkAsPaidHandler,MarkAsUnpaidConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestMarkAsFullyPaidE2EInWeb()
    var
        PostedInvoiceNo: Code[20];
    begin
        Init;
        LibraryE2EPlanPermissions.SetInvoicingUserPlan;

        // [GIVEN] A clean Invoicing App
        // [GIVEN] User has created a customer and an item from the pages
        // [GIVEN] User has created and send a simple invoice
        PostedInvoiceNo := CreateAndSendInvoiceInWeb;

        // [WHEN] User marks the invoice as fully paid
        AddPaymentForInvoiceInWeb(PostedInvoiceNo, false);
        // [THEN] There is one payment for the invoice
        // [THEN] The invoice is closed
        VerifyNoPaymentsForInvoice(PostedInvoiceNo, 1, true);

        // [WHEN] User marks the invoice as unpaid
        // [THEN] There are no payments for the invoice
        // [THEN] The invoice is not closed
        RemoveLastPaymentForInvoiceInWeb(PostedInvoiceNo);
        VerifyNoPaymentsForInvoice(PostedInvoiceNo, 0, false);

        // [WHEN] User marks the invoice as fully paid again
        AddPaymentForInvoiceInWeb(PostedInvoiceNo, false);
        // [THEN] There is one payment for the invoice
        // [THEN] The invoice is closed
        VerifyNoPaymentsForInvoice(PostedInvoiceNo, 1, true);

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,BCEmailSetupPageHandler,MessageHandler,MarkAsPaidHandler,MarkAsUnpaidHandler,MarkAsUnpaidConfirmHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestMarkAsPartiallyPaidE2EInWeb()
    var
        PostedInvoiceNo: Code[20];
    begin
        Init;
        LibraryE2EPlanPermissions.SetInvoicingUserPlan;

        // [GIVEN] A clean Invoicing App
        // [GIVEN] User has created a customer and an item from the pages
        // [GIVEN] User has created and send a simple invoice
        PostedInvoiceNo := CreateAndSendInvoiceInWeb;

        // [WHEN] User makes 3 partial payments
        AddPaymentForInvoiceInWeb(PostedInvoiceNo, true);
        AddPaymentForInvoiceInWeb(PostedInvoiceNo, true);
        AddPaymentForInvoiceInWeb(PostedInvoiceNo, true);
        // [THEN] There are 3 partial payments for the invoice
        // [THEN] The invoice is not closed
        VerifyNoPaymentsForInvoice(PostedInvoiceNo, 3, false);

        // [WHEN] User removes the two last payments
        RemoveLastPaymentForInvoiceInWeb(PostedInvoiceNo);
        RemoveLastPaymentForInvoiceInWeb(PostedInvoiceNo);
        // [THEN] There is one payment for the invoice
        // [THEN] The invoice is not closed
        VerifyNoPaymentsForInvoice(PostedInvoiceNo, 1, false);

        // [WHEN] User marks the invoice as fully paid
        AddPaymentForInvoiceInWeb(PostedInvoiceNo, false);
        // [THEN] There are two payments for the invoice
        // [THEN] The invoice is closed
        VerifyNoPaymentsForInvoice(PostedInvoiceNo, 2, true);

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    // [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,BCEmailSetupPageHandler,MessageHandler,InvoiceCanceledConfirmHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestCancelSentInvoiceInWeb()
    var
        PostedInvoiceNo: Code[20];
    begin
        Init;
        LibraryE2EPlanPermissions.SetInvoicingUserPlan;

        // [GIVEN] A sent invoice
        PostedInvoiceNo := CreateAndSendInvoiceInWeb;

        // [WHEN] The invoice is cancelled
        CancelInvoiceInWeb(PostedInvoiceNo);

        // [THEN] The send email contains a message
        VerifyCancelEmailContent;

        // [THEN] The invoice status is marked as cancelled
        Assert.AreEqual(CanceledTxt, GetDocumentStatus(PostedInvoiceNo, true), '');

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,BCEmailSetupPageHandler,MessageHandler,InvoiceCanceledConfirmHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestCancelSentInvoiceWithoutEmailSetupInWeb()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        PostedInvoiceNo: Code[20];
    begin
        Init;
        LibraryE2EPlanPermissions.SetInvoicingUserPlan;

        // [GIVEN] A sent invoice
        PostedInvoiceNo := CreateAndSendInvoiceInWeb;

        // [GIVEN] Remove Email Setup
        SMTPMailSetup.DeleteAll;

        // [WHEN] The invoice is cancelled
        CancelInvoiceInWeb(PostedInvoiceNo);

        // [THEN] The invoice status is marked as cancelled
        Assert.AreEqual(CanceledTxt, GetDocumentStatus(PostedInvoiceNo, true), '');

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestExternalServiceInWebSettingPage()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        BCO365ServiceSettings: TestPage "BC O365 Service Settings";
        ServiceStatus: Boolean;
    begin
        Init;
        LibraryE2EPlanPermissions.SetInvoicingUserPlan;

        // [GIVEN] VAT Service is not configured
        // [WHEN] User opens the Setting page and enable and disable the VAT service
        // [THEN] Service is enabled and disabled accordingly
        VATRegNoSrvConfig.DeleteAll;
        Assert.IsTrue(VATRegNoSrvConfig.IsEmpty, 'Srv table should be empty');

        BCO365ServiceSettings.OpenView;
        Assert.IsFalse(VATRegNoSrvConfig.IsEmpty, 'Service should be initialized after openning the page');
        Assert.IsTrue(VATRegNoSrvConfig.FindFirst, 'Service should be initialized after openning the page');

        Evaluate(ServiceStatus, BCO365ServiceSettings.ViesEnabled.Value);
        Assert.IsTrue(ServiceStatus, 'Service should be enabled by default');

        BCO365ServiceSettings.ViesEnabled.Value(Format(false));
        VATRegNoSrvConfig.FindFirst;
        Assert.IsFalse(VATRegNoSrvConfig.Enabled, 'Service should be disabled');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestManuallyAddCountryNameQuotes()
    var
        CountryRegion: Record "Country/Region";
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
        PartialCountryName: Text;
        CustomerName: Text;
    begin
        Init;
        LibraryE2EPlanPermissions.SetInvoicingUserPlan;
        EventSubscriberInvoicingApp.SetRunJobQueueTasks(false);
        TaxDetail.ModifyAll("Tax Below Maximum", 5); // Avoid tax setup notification in US

        // [GIVEN] The user has some custom country codes and a customer
        CustomerName := LibraryInvoicingApp.CreateCustomer;
        LibraryInvoicingApp.CreateCountryRegion('MSWAYQ');
        LibraryInvoicingApp.CreateCountryRegion('NAVWAYQ');
        CountryRegion.Get('NAVWAYQ');
        PartialCountryName := CopyStr(CountryRegion.Name, 1, MaxStrLen(CountryRegion.Code));

        // [WHEN] The user creates a new quote and manually types the country name in the country field
        LibraryVariableStorage.Enqueue('Do you want to keep the new estimate?');
        LibraryVariableStorage.Enqueue(true);
        BCO365SalesQuote.OpenNew;
        BCO365SalesQuote."Sell-to Customer Name".SetValue(CustomerName);
        BCO365SalesQuote.CountryRegionCode.SetValue(PartialCountryName);
        BCO365SalesQuote.Close;

        // [THEN] The correct country is used for the quote
        SalesHeader.SetRange("Sell-to Customer Name", CustomerName);
        SalesHeader.FindFirst;
        Assert.AreEqual('NAVWAYQ', SalesHeader."Sell-to Country/Region Code", 'Unexpected country/region code.');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestManuallyAddCountryNameInvoice()
    var
        CountryRegion: Record "Country/Region";
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        PartialCountryName: Text;
        CustomerName: Text;
    begin
        Init;
        LibraryE2EPlanPermissions.SetInvoicingUserPlan;
        EventSubscriberInvoicingApp.SetRunJobQueueTasks(false);
        TaxDetail.ModifyAll("Tax Below Maximum", 5); // Avoid tax setup notification in US

        // [GIVEN] The user has some custom country codes and a customer
        CustomerName := LibraryInvoicingApp.CreateCustomer;
        LibraryInvoicingApp.CreateCountryRegion('MSWAYI');
        LibraryInvoicingApp.CreateCountryRegion('NAVWAYI');
        CountryRegion.Get('NAVWAYI');
        PartialCountryName := CopyStr(CountryRegion.Name, 1, MaxStrLen(CountryRegion.Code));

        // [WHEN] The user creates a new invoice and manually types the country name in the country field
        LibraryVariableStorage.Enqueue('Do you want to keep the new invoice?');
        LibraryVariableStorage.Enqueue(true);
        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".SetValue(CustomerName);
        BCO365SalesInvoice.CountryRegionCode.SetValue(PartialCountryName);
        BCO365SalesInvoice.Close;

        // [THEN] The correct country is used for the quote
        SalesHeader.SetRange("Sell-to Customer Name", CustomerName);
        SalesHeader.FindFirst;
        Assert.AreEqual('NAVWAYI', SalesHeader."Sell-to Country/Region Code", 'Unexpected country/region code.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyInvoiceAndQuoteAreNotSaved()
    var
        SalesHeader: Record "Sales Header";
        BCO365EstimateList: TestPage "BC O365 Estimate List";
        BCO365InvoiceList: TestPage "BC O365 Invoice List";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
    begin
        // [GIVEN] A Invoicing App user
        Init;
        LibraryE2EPlanPermissions.SetInvoicingUserPlan;

        // [WHEN] The user clicks 'New Invoice' in the invoice list and immediately closes the page
        BCO365InvoiceList.OpenEdit;
        BCO365SalesInvoice.Trap;
        BCO365InvoiceList._NEW_TEMP_.Invoke;
        BCO365SalesInvoice.Close;

        // [THEN] The invoice is not saved
        SalesHeader.SetRange("Sell-to Customer Name", '');
        Assert.RecordIsEmpty(SalesHeader);
        BCO365InvoiceList.Close;

        // [WHEN] The user clicks 'New Estimate' in the estimate list and immediately closes the page
        BCO365EstimateList.OpenEdit;
        BCO365SalesQuote.Trap;
        BCO365EstimateList._NEW_TEMP_.Invoke;
        BCO365SalesQuote.Close;

        // [THEN] The estimate is not saved
        SalesHeader.SetRange("Sell-to Customer Name", '');
        Assert.RecordIsEmpty(SalesHeader);
        BCO365EstimateList.Close;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestEstimateWithLongCustomerAndItem()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
        BCO365EstimateList: TestPage "BC O365 Estimate List";
        BCO365CustomerList: TestPage "BC O365 Customer List";
        BCO365ItemList: TestPage "BC O365 Item List";
        BCO365ItemCard: TestPage "BC O365 Item Card";
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
    begin
        // [GIVEN] A clean Invoicing App
        Init;
        LibraryE2EPlanPermissions.SetInvoicingUserPlan;

        // [WHEN] User creates a customer with very long name and email, and an item with very long description
        BCO365SalesCustomerCard.OpenNew;
        BCO365SalesCustomerCard.Name.Value := CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Customer.Name), 1),
            1, MaxStrLen(Customer.Name));
        Customer.SetRange(Name, BCO365SalesCustomerCard.Name.Value);
        BCO365SalesCustomerCard."E-Mail".Value := CopyStr(
            StrSubstNo('test@%1', LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Customer."E-Mail") - 5, 1)),
            1, MaxStrLen(Customer."E-Mail"));
        BCO365SalesCustomerCard.Close;
        BCO365ItemCard.OpenNew;
        BCO365ItemCard.Description.Value := CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Item.Description), 1),
            1, MaxStrLen(Item.Description));
        Item.SetRange(Description, BCO365ItemCard.Description.Value);
        BCO365ItemCard."Unit Price".Value := '42';
        BCO365ItemCard.Close;

        // [THEN] Customer and Item are inserted correctly and appear in the pages
        Customer.FindFirst;
        Item.FindFirst;
        BCO365CustomerList.OpenEdit;
        BCO365CustomerList.GotoRecord(Customer);
        BCO365CustomerList.Close;
        BCO365SalesCustomerCard.OpenEdit;
        BCO365SalesCustomerCard.GotoRecord(Customer);
        BCO365SalesCustomerCard.Close;
        BCO365ItemList.OpenEdit;
        BCO365ItemList.GotoRecord(Item);
        BCO365ItemList.Close;
        BCO365ItemCard.OpenEdit;
        BCO365ItemCard.GotoRecord(Item);
        BCO365ItemCard.Close;

        // [WHEN] User creates an estimate
        BCO365SalesQuote.OpenNew;
        BCO365SalesQuote."Sell-to Customer Name".Value := Customer.Name;
        BCO365SalesQuote.Lines.Description.Value := Item.Description;
        BCO365SalesQuote.Close;
        SalesHeader.SetRange("Sell-to Customer Name", Customer.Name);
        SalesHeader.FindFirst;

        // [THEN] The estimate pages open fine, and the estimate can be converted into an invoice
        BCO365EstimateList.OpenEdit;
        BCO365EstimateList.GotoKey(SalesHeader."Document Type"::Quote, SalesHeader."No.", false);
        BCO365EstimateList.Close;
        BCO365SalesQuote.OpenEdit;
        BCO365SalesQuote.GotoRecord(SalesHeader);
        LibraryVariableStorage.Enqueue('Do you want to turn the estimate into a draft invoice?');
        LibraryVariableStorage.Enqueue(true);
        BCO365SalesInvoice.Trap;
        BCO365SalesQuote.MakeToInvoice.Invoke;
        BCO365SalesInvoice.Close;

        SalesHeader.Reset;
        SalesHeader.SetRange("Sell-to Customer Name", Customer.Name);
        SalesHeader.FindFirst;
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,EmailDialogModalPageHandler,BCEmailSetupPageHandler')]
    [Scope('OnPrem')]
    procedure TestInvoiceWithLongCustomerAndItem()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        BCO365InvoiceList: TestPage "BC O365 Invoice List";
        BCO365CustomerList: TestPage "BC O365 Customer List";
        BCO365ItemList: TestPage "BC O365 Item List";
        BCO365ItemCard: TestPage "BC O365 Item Card";
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
    begin
        // [GIVEN] A clean Invoicing App
        Init;
        LibraryE2EPlanPermissions.SetInvoicingUserPlan;

        // [WHEN] User creates a customer with very long name and email, and an item with very long description
        BCO365SalesCustomerCard.OpenNew;
        BCO365SalesCustomerCard.Name.Value := CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Customer.Name), 1),
            1, MaxStrLen(Customer.Name));
        BCO365SalesCustomerCard."E-Mail".Value := CopyStr(
            StrSubstNo('test@%1', LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Customer."E-Mail") - 5, 1)),
            1, MaxStrLen(Customer."E-Mail"));
        BCO365SalesCustomerCard.Close;
        BCO365ItemCard.OpenNew;
        BCO365ItemCard.Description.Value := CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Item.Description), 1),
            1, MaxStrLen(Item.Description));
        Item.SetRange(Description, BCO365ItemCard.Description.Value);
        BCO365ItemCard."Unit Price".Value := '42';
        BCO365ItemCard.Close;

        // [THEN] Customer and Item are inserted correctly and appear in the pages
        Customer.FindFirst;
        Item.FindFirst;
        BCO365CustomerList.OpenEdit;
        BCO365CustomerList.GotoRecord(Customer);
        BCO365CustomerList.Close;
        BCO365SalesCustomerCard.OpenEdit;
        BCO365SalesCustomerCard.GotoRecord(Customer);
        BCO365SalesCustomerCard.Close;
        BCO365ItemList.OpenEdit;
        BCO365ItemList.GotoRecord(Item);
        BCO365ItemList.Close;
        BCO365ItemCard.OpenEdit;
        BCO365ItemCard.GotoRecord(Item);
        BCO365ItemCard.Close;

        // [WHEN] User creates an invoice
        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".Value := Customer.Name;
        BCO365SalesInvoice.Lines.Description.Value := Item.Description;
        BCO365SalesInvoice.Close;
        SalesHeader.SetRange("Sell-to Customer Name", Customer.Name);
        SalesHeader.FindFirst;

        // [THEN] The invoice pages open fine
        BCO365InvoiceList.OpenEdit;
        BCO365InvoiceList.GotoKey(SalesHeader."Document Type"::Invoice, SalesHeader."No.", false);
        BCO365InvoiceList.Close;
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoRecord(SalesHeader);

        // [WHEN] User posts the invoice
        BCO365SalesInvoice.Post.Invoke;

        // [THEN] Posting succeeds and the posted invoice can be opened in the pages
        SalesInvoiceHeader.SetRange("Sell-to Customer Name", Customer.Name);
        SalesInvoiceHeader.FindFirst;
        BCO365InvoiceList.OpenEdit;
        BCO365InvoiceList.GotoKey(SalesHeader."Document Type"::Invoice, SalesInvoiceHeader."No.", true);
        BCO365InvoiceList.Close;
        BCO365PostedSalesInvoice.OpenEdit;
        BCO365PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        BCO365PostedSalesInvoice.Close;

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesInvoiceHeader); // Document failed to send notification
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateItemInlineAndCard()
    var
        ItemFromCard: Record Item;
        ItemFromLine: Record Item;
        SalesLine: Record "Sales Line";
        InvoiceNo: Code[20];
    begin
        Init;
        ItemFromCard.DeleteAll;
        LibraryE2EPlanPermissions.SetInvoicingUserPlan;

        // [GIVEN] A clean Invoicing App
        // [WHEN] User creates an item from a sales line
        // [THEN] An invoice has been sent
        InvoiceNo := CreateInvoiceInWeb(LibraryUtility.GenerateGUID);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", InvoiceNo);
        SalesLine.FindFirst;

        ItemFromLine.Get(SalesLine."No.");

        // [WHEN] User creates an item from the item card
        ItemFromCard.SetRange(Description, LibraryInvoicingApp.CreateBcItem);
        ItemFromCard.FindFirst;
        ItemFromCard.Validate("Unit Price", ItemFromLine."Unit Price");
        ItemFromCard.Modify(true);

        // [THEN] The item properties must be the same
        Assert.AreNotEqual(ItemFromCard."No.", ItemFromLine."No.", 'Two distinct items should have been created');
        VerifyItemsMatch(ItemFromCard, ItemFromLine);

        LibraryNotificationMgt.ClearTemporaryNotificationContext;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,BCO365TestSalesInvoicePageHandler,TestInvoiceEmailDialogModalPageHandler,BCEmailSetupPageHandler')]
    [Scope('OnPrem')]
    procedure TestSendTestInvoiceEmail()
    var
        O365SalesTestInvoiceTest: TestPage "O365 Sales Test Invoice Page";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        BCO365InvoiceList: TestPage "BC O365 Invoice List";
        InvoiceNo: Code[20];
        TestInvoiceFound: Boolean;
    begin
        LibraryE2EPlanPermissions.SetInvoicingUserPlan;
        Init;

        // [GIVEN] Create new test invoice
        O365SalesTestInvoiceTest.OpenEdit;
        O365SalesTestInvoiceTest."Create Test Invoice".Invoke;
        InvoiceNo := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(InvoiceNo));
        LibraryVariableStorage.Enqueue(InvoiceNo);

        // [WHEN] User adds customer name and item and clicks on send test email
        OpenInvoice(BCO365SalesInvoice);
        Assert.AreNotEqual(0, StrPos(BCO365SalesInvoice.Caption, 'Test'), 'Caption should contain Test invoice');

        // [THEN] User should see right subject and email body
        BCO365SalesInvoice.SendTest.Invoke;

        // [THEN] The test invoice is shown in the invoice list and marked as 'Test'
        BCO365InvoiceList.OpenEdit;
        BCO365InvoiceList.First;

        repeat
            if (BCO365InvoiceList."No.".Value = InvoiceNo) and (BCO365InvoiceList."Outstanding Status".Value = TestTxt) then begin
                if TestInvoiceFound then
                    Assert.Fail('More then one test invoice found in list');
                TestInvoiceFound := true;
            end;
        until BCO365InvoiceList.Next = false;
        Assert.IsTrue(TestInvoiceFound, 'Test invoice not found in the invoice list.');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestInvoiceNumberForTestInvoice()
    var
        SalesHeader: Record "Sales Header";
        O365SalesTestInvoiceTest: TestPage "O365 Sales Test Invoice Page";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        CustomerName: Text[50];
        NextInvoiceNumberShown: Code[20];
    begin
        // [GIVEN] An invoicing user
        LibraryE2EPlanPermissions.SetInvoicingUserPlan;
        Init;

        // [WHEN] User creates a new test invoice
        O365SalesTestInvoiceTest.OpenEdit;
        BCO365SalesInvoice.Trap;
        O365SalesTestInvoiceTest."Create Test Invoice".Invoke;
        CustomerName := LibraryInvoicingApp.CreateCustomer;
        BCO365SalesInvoice."Sell-to Customer Name".Value := CustomerName;
        BCO365SalesInvoice.Lines.Description.Value := LibraryInvoicingApp.CreateItemWithPrice;
        NextInvoiceNumberShown := BCO365SalesInvoice.NextInvoiceNo.Value;
        BCO365SalesInvoice.Close;

        // [THEN] The invoice is a test invoice and the number is the draft invoice number
        SalesHeader.SetRange("Sell-to Customer Name", CustomerName);
        SalesHeader.FindFirst;
        Assert.IsTrue(SalesHeader.IsTest, 'IsTest should be true in the sales header');
        Assert.AreEqual(SalesHeader."No.", NextInvoiceNumberShown, 'The wrong number is shown in the test invoice page');

        // [WHEN] User opens the invoice again
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, SalesHeader."No.");
        NextInvoiceNumberShown := BCO365SalesInvoice.NextInvoiceNo.Value;
        BCO365SalesInvoice.Close;

        // [THEN] The number is still the draft invoice number and the invoice is still a test invoice
        SalesHeader.FindFirst;
        Assert.IsTrue(SalesHeader.IsTest, 'IsTest should be true in the sales header');
        Assert.AreEqual(SalesHeader."No.", NextInvoiceNumberShown, 'The wrong number is shown in the test invoice page');
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,BCEmailSetupPageHandler,MessageHandler,MarkAsPaidHandler,InvoiceCanceledConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInvoiceListFilters()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        BCO365EstimateList: TestPage "BC O365 Estimate List";
        BCO365InvoiceList: TestPage "BC O365 Invoice List";
        DraftInvoice1: Code[20];
        DraftInvoice2: Code[20];
        SentInvoice1: Code[20];
        SentInvoice2: Code[20];
        PaidInvoice1: Code[20];
        PaidInvoice2: Code[20];
        CanceledInvoice1: Code[20];
        CanceledInvoice2: Code[20];
        DraftEstimate1: Code[20];
        DraftEstimate2: Code[20];
        AcceptedEstimate1: Code[20];
        AcceptedEstimate2: Code[20];
        ExpiredEstimate1: Code[20];
        ExpiredEstimate2: Code[20];
    begin
        // [GIVEN] An invoicing user
        SalesHeader.DeleteAll;
        SalesInvoiceHeader.DeleteAll;
        LibraryE2EPlanPermissions.SetInvoicingUserPlan;
        Init;

        // [GIVEN] 2 draft invoices, 2 sent invoices, 2 paid invoices and 2 canceled invoices
        DraftInvoice1 := CreateInvoiceInWeb(LibraryUtility.GenerateGUID);
        DraftInvoice2 := CreateInvoiceInWeb(LibraryUtility.GenerateGUID);
        SentInvoice1 := CreateAndSendInvoiceInWeb;
        SentInvoice2 := CreateAndSendInvoiceInWeb;

        PaidInvoice1 := CreateAndSendInvoiceInWeb;
        AddPaymentForInvoiceInWeb(PaidInvoice1, false);
        PaidInvoice2 := CreateAndSendInvoiceInWeb;
        AddPaymentForInvoiceInWeb(PaidInvoice2, false);

        CanceledInvoice1 := CreateAndSendInvoiceInWeb;
        CancelInvoiceInWeb(CanceledInvoice1);
        CanceledInvoice2 := CreateAndSendInvoiceInWeb;
        CancelInvoiceInWeb(CanceledInvoice2);

        // [GIVEN] 2 draft estimates, 2 accepted estimates and 2 expired estimates
        DraftEstimate1 := LibraryInvoicingApp.CreateEstimate;
        DraftEstimate2 := LibraryInvoicingApp.CreateEstimate;
        AcceptedEstimate1 := LibraryInvoicingApp.CreateAcceptedEstimate;
        AcceptedEstimate2 := LibraryInvoicingApp.CreateAcceptedEstimate;
        ExpiredEstimate1 := LibraryInvoicingApp.CreateExpiredEstimate;
        ExpiredEstimate2 := LibraryInvoicingApp.CreateExpiredEstimate;

        // [WHEN] The invoice list is opened for all invoices
        // [THEN] 8 invoices are displayed and can be opened
        BCO365InvoiceList.OpenEdit;
        BCO365InvoiceList.First;
        Assert.AreEqual(DraftInvoice2, BCO365InvoiceList."No.".Value, 'Wrong invoice no. for draft invoice 2');
        BCO365InvoiceList.Next;
        Assert.AreEqual(DraftInvoice1, BCO365InvoiceList."No.".Value, 'Wrong invoice no. for draft invoice 1');
        BCO365InvoiceList.Next;
        Assert.AreEqual(CanceledInvoice2, BCO365InvoiceList."No.".Value, 'Wrong invoice no. for canceled invoice 2');
        BCO365InvoiceList.Next;
        Assert.AreEqual(CanceledInvoice1, BCO365InvoiceList."No.".Value, 'Wrong invoice no. for canceled invoice 1');
        BCO365InvoiceList.Next;
        Assert.AreEqual(PaidInvoice2, BCO365InvoiceList."No.".Value, 'Wrong invoice no. for paid invoice 2');
        BCO365InvoiceList.Next;
        Assert.AreEqual(PaidInvoice1, BCO365InvoiceList."No.".Value, 'Wrong invoice no. for paid invoice 1');
        BCO365InvoiceList.Next;
        Assert.AreEqual(SentInvoice2, BCO365InvoiceList."No.".Value, 'Wrong invoice no. for sent invoice 2');
        BCO365InvoiceList.Next;
        Assert.AreEqual(SentInvoice1, BCO365InvoiceList."No.".Value, 'Wrong invoice no. for sent invoice 1');

        // No more entries
        BCO365InvoiceList.Next;
        Assert.AreEqual(SentInvoice1, BCO365InvoiceList."No.".Value, 'Invoice list has more entries than expected');
        BCO365InvoiceList.Close;

        // [WHEN] The estimate list is opened for all estimates
        // [THEN] All the estimates are shown in the list
        BCO365EstimateList.OpenEdit;
        BCO365EstimateList.First;
        Assert.AreEqual(ExpiredEstimate2, BCO365EstimateList."No.".Value, 'Wrong estimate no. for expired estimate 2');
        BCO365EstimateList.Next;
        Assert.AreEqual(ExpiredEstimate1, BCO365EstimateList."No.".Value, 'Wrong estimate no. for expired estimate 1');
        BCO365EstimateList.Next;
        Assert.AreEqual(AcceptedEstimate2, BCO365EstimateList."No.".Value, 'Wrong estimate no. for accepted estimate 2');
        BCO365EstimateList.Next;
        Assert.AreEqual(AcceptedEstimate1, BCO365EstimateList."No.".Value, 'Wrong estimate no. for accepted estimate 1');
        BCO365EstimateList.Next;
        Assert.AreEqual(DraftEstimate2, BCO365EstimateList."No.".Value, 'Wrong estimate no. for draft estimate 2');
        BCO365EstimateList.Next;
        Assert.AreEqual(DraftEstimate1, BCO365EstimateList."No.".Value, 'Wrong estimate no. for draft estimate 1');

        // No more entries
        BCO365EstimateList.Next;
        Assert.AreEqual(DraftEstimate1, BCO365EstimateList."No.".Value, 'Estimate list has more entries than expected');
        BCO365EstimateList.Close;

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    local procedure AddPaymentForInvoiceInWeb(DocumentNo: Code[20]; PartialPayment: Boolean)
    var
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
    begin
        BCO365PostedSalesInvoice.OpenView;
        BCO365PostedSalesInvoice.GotoKey(DocumentNo);

        LibraryVariableStorage.Enqueue(PartialPayment);
        LibraryVariableStorage.Enqueue(MarkedPaidMsg);
        BCO365PostedSalesInvoice.MarkAsPaid.Invoke;
    end;

    local procedure CancelInvoiceInWeb(PostedInvoiceNo: Code[20])
    var
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
    begin
        Commit;
        BCO365PostedSalesInvoice.OpenView;
        BCO365PostedSalesInvoice.GotoKey(PostedInvoiceNo);

        LibraryVariableStorage.Enqueue(CancelPostedInvoiceMsg);
        BCO365PostedSalesInvoice.CancelInvoice.Invoke;
    end;

    local procedure CreateAndSendInvoiceInWeb() PostedInvoiceNo: Code[20]
    begin
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(LibraryInvoicingApp.CreateInvoice);

        // [THEN] The send email contains a message
        VerifyEmailContent(PostedInvoiceNo);
    end;

    local procedure CreateInvoiceInWeb(ItemDescription: Text[50]) InvoiceNo: Code[20]
    begin
        InvoiceNo := LibraryInvoicingApp.CreateInvoice;
        LibraryInvoicingApp.AddLineToInvoice(InvoiceNo, ItemDescription);
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

    local procedure RemoveLastPaymentForInvoiceInWeb(DocumentNo: Code[20])
    var
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
    begin
        BCO365PostedSalesInvoice.OpenView;
        BCO365PostedSalesInvoice.GotoKey(DocumentNo);

        LibraryVariableStorage.Enqueue(MarkedUnpaidMsg);
        BCO365PostedSalesInvoice.MarkAsUnpaid.Invoke;
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
        CustLedgerEntry.FindFirst;
        if IsClosed then begin
            Assert.AreNotEqual(0, CustLedgerEntry."Closed by Entry No.", 'Invoice should be closed.');
            CustLedgerEntry.Get(CustLedgerEntry."Closed by Entry No.");
        end else
            Assert.AreEqual(0, CustLedgerEntry."Closed by Entry No.", 'Invoice should not be closed.');
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
        SMTPMailSetup: Record "SMTP Mail Setup";
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        BindActiveDirectoryMockEvents;

        LibraryVariableStorage.AssertEmpty;
        SMTPMailSetup.DeleteAll;
        EventSubscriberInvoicingApp.Clear;
        ApplicationArea('#Invoicing');
        O365SalesInitialSetup.Get;

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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        O365SalesEmailDialog.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BCEmailSetupPageHandler(var BCO365EmailSetupWizard: TestPage "BC O365 Email Setup Wizard")
    begin
        with BCO365EmailSetupWizard.EmailSettingsWizardPage do begin
            "Email Provider".SetValue(EmailProvider::"Office 365");
            FromAccount.SetValue('test@microsoft.com');
            Password.SetValue('pass');
        end;

        BCO365EmailSetupWizard.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.AreEqual(ExpectedMessage, Question, '');
        Reply := LibraryVariableStorage.DequeueBoolean;
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

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.AreNotEqual(
          0,
          StrPos(Notification.Message, LastEmailFailedNotificationPrefixTxt),
          'Unexpected notification.'
          );
    end;

    local procedure VerifyItemsMatch(ItemFromCard: Record Item; ItemFromLine: Record Item)
    var
        TempLineFieldsToIgnore: Record "Field" temporary;
        ItemFromCardRecordRef: RecordRef;
        ItemFromLineRecordRef: RecordRef;
    begin
        ItemFromCardRecordRef.GetTable(ItemFromCard);
        ItemFromLineRecordRef.GetTable(ItemFromLine);
        TempLineFieldsToIgnore.DeleteAll;

        // Fields to ignore
        LibraryUtility.AddTempField(TempLineFieldsToIgnore, ItemFromCard.FieldNo("No."), DATABASE::Item);
        LibraryUtility.AddTempField(TempLineFieldsToIgnore, ItemFromCard.FieldNo(Id), DATABASE::Item);
        LibraryUtility.AddTempField(TempLineFieldsToIgnore, ItemFromCard.FieldNo(Description), DATABASE::Item);
        LibraryUtility.AddTempField(TempLineFieldsToIgnore, ItemFromCard.FieldNo("Search Description"), DATABASE::Item);
        LibraryUtility.AddTempField(TempLineFieldsToIgnore, ItemFromCard.FieldNo("Last Date Modified"), DATABASE::Item);
        LibraryUtility.AddTempField(TempLineFieldsToIgnore, ItemFromCard.FieldNo("Last Time Modified"), DATABASE::Item);
        LibraryUtility.AddTempField(TempLineFieldsToIgnore, ItemFromCard.FieldNo("Last DateTime Modified"), DATABASE::Item);

        // Fields must be set, but not equal
        Assert.AreNotEqual('', ItemFromCard."Search Description", '');
        Assert.AreNotEqual('', ItemFromLine."Search Description", '');

        Assert.RecordsAreEqualExceptCertainFields(ItemFromCardRecordRef, ItemFromLineRecordRef,
          TempLineFieldsToIgnore, 'Items created from card and sales line do not match');
    end;

    local procedure OpenInvoice(var BCO365SalesInvoice: TestPage "BC O365 Sales Invoice")
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvoiceNo);
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, InvoiceNo);
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoRecord(SalesHeader);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BCO365TestSalesInvoicePageHandler(var BCO365SalesInvoice: TestPage "BC O365 Sales Invoice")
    begin
        Assert.IsTrue(BCO365SalesInvoice.SendTest.Visible, 'Send draft is not visible on draft invoice before inserting customer');
        Assert.IsFalse(BCO365SalesInvoice.Post.Visible, 'Send invoice is visible on draft invoice before inserting customer');
        BCO365SalesInvoice."Sell-to Customer Name".Value(LibraryInvoicingApp.CreateCustomerWithEmail);
        BCO365SalesInvoice.Lines.New;
        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItemWithPrice);
        LibraryVariableStorage.Enqueue(BCO365SalesInvoice.NextInvoiceNo.Value);
        BCO365SalesInvoice.Close;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TestInvoiceEmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        Assert.AreEqual(
          MailManagement.GetSenderEmailAddress, O365SalesEmailDialog.FromAddressField.Value,
          'From address should be senders address in test invoice');

        // verify to address
        Assert.AreEqual(
          MailManagement.GetSenderEmailAddress, O365SalesEmailDialog.SendToText.Value,
          'To address should be senders address in test invoice');

        // verify subject and email body
        Assert.AreNotEqual(
          0, StrPos(O365SalesEmailDialog.Subject.Value, 'Test invoice'), 'Subject should contain test invoice in Email Dialog');
        Assert.AreNotEqual(
          0, StrPos(O365SalesEmailDialog.Body.Value, 'test invoice'), 'Email body should contain test invoice in Email Dialog');
        Assert.AreEqual(
          DocumentMailing.GetTestInvoiceEmailSubject,
          O365SalesEmailDialog.Subject.Value, 'Subject for test invoice is incorrect in Email Dialog');

        O365SalesEmailDialog.OK.Invoke;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

