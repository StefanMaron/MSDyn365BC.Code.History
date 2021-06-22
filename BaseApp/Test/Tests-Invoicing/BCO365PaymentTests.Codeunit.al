codeunit 138961 "BC O365 Payment Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Payment Terms]
    end;

    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        EmailProvider: Option "Office 365",Other;
        IsInitialized: Boolean;
        MarkedPaidMsg: Label 'Invoice payment was registered.';
        PreviousPaymentMethodCode: Code[10];
        DefaultPaymentTermsCode: Code[10];
        PaymentTermsDays: Integer;
        CannotRemoveDefaultPaymentTermsErr: Label 'You cannot remove the default payment terms.';
        TaxSetupNeededMsg: Label 'You haven''t set up tax information for your business.';
        UnhandledNotificationErr: Label 'Unhandled notification: %1.';
        MarkAsUnpaidConfirmQst: Label 'Cancel this payment registration?';
        MarkedUnpaidMsg: Label 'Payment registration was removed.';

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,BCEmailSetupPageHandler,MessageHandler,MarkAsPaidHandler,NotificationHandler,O365PaymentMethodListHandler,O365PaymentMethodCardHandler')]
    [Scope('OnPrem')]
    procedure RegisterPaymentRemembersLastPaymentRegistered()
    var
        PostedInvoiceNo: Code[20];
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A clean Invoicing App
        // [GIVEN] User has created a customer and an item from the pages
        // [GIVEN] User has created and send a simple invoice
        PostedInvoiceNo := CreateAndSendInvoice;

        // [WHEN] User pays the invoice with a new payment method
        Clear(PreviousPaymentMethodCode);
        AddPaymentForInvoice(PostedInvoiceNo);

        // [THEN] The next payment will by default have this value set
        // [WHEN] A payment is made for another payment method
        AddPaymentForInvoice(PostedInvoiceNo);

        // [THEN] The next payment will by default have this value set
        AddPaymentForInvoice(PostedInvoiceNo);

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('O365PaymentTermsCardHandler')]
    [Scope('OnPrem')]
    procedure NewPaymentTermsHasDescription()
    var
        PaymentTerms: Record "Payment Terms";
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] A new payment term is created
        PAGE.RunModal(PAGE::"BC O365 Payment Terms Card");

        // [THEN] That new payment term has a description equal to the code
        PaymentTerms.Get(DefaultPaymentTermsCode);
        Assert.AreEqual(DefaultPaymentTermsCode, PaymentTerms.GetDescriptionInCurrentLanguage, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,O365PaymentTermsListHandler,O365PaymentTermsCardHandler')]
    [Scope('OnPrem')]
    procedure DefaultPaymentTermsUsedOnNewInvoiceExistingCustomer()
    var
        BCO365Settings: TestPage "BC O365 Settings";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        CustomerName: Text;
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A customer
        CustomerName := LibraryInvoicingApp.CreateCustomer;

        // [WHEN] Default Payment terms is changed
        BCO365Settings.OpenEdit;
        BCO365Settings.Payments.PaymentTermsCode.AssistEdit;
        BCO365Settings.Close;

        // [THEN] A new invoice for an existing customer uses the existing payment terms
        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".Value(CustomerName);
        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        Assert.AreEqual(DefaultPaymentTermsCode, BCO365SalesInvoice."Payment Terms Code".Value, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,O365PaymentTermsListHandler,O365PaymentTermsCardHandler')]
    [Scope('OnPrem')]
    procedure DefaultPaymentTermsUsedOnNewInvoiceNewCustomer()
    var
        BCO365Settings: TestPage "BC O365 Settings";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] Default Payment terms is changed
        BCO365Settings.OpenEdit;
        BCO365Settings.Payments.PaymentTermsCode.AssistEdit;
        BCO365Settings.Close;

        // [THEN] A new invoice for a new customer uses the existing payment terms
        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".Value(LibraryInvoicingApp.CreateCustomer);
        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        Assert.AreEqual(DefaultPaymentTermsCode, BCO365SalesInvoice."Payment Terms Code".Value, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,O365PaymentTermsCardHandler')]
    [Scope('OnPrem')]
    procedure ModifyCodeForAlreadyAppliedPaymentTermsAndSendInvoice()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        BCO365Settings: TestPage "BC O365 Settings";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        BCO365PaymentTermsCard: Page "BC O365 Payment Terms Card";
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A new invoice for a new customer uses the existing payment terms
        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".Value(LibraryInvoicingApp.CreateCustomer);
        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        O365SalesInitialSetup.Get();
        Assert.AreEqual(
          O365SalesInitialSetup."Default Payment Terms Code", BCO365SalesInvoice."Payment Terms Code".Value,
          'Default payment terms is not assigned correctly to the invoice');
        BCO365SalesInvoice.Close;

        // [WHEN] Default Payment terms code is changed
        PaymentTerms.Get(O365SalesInitialSetup."Default Payment Terms Code");
        BCO365PaymentTermsCard.SetPaymentTerms(PaymentTerms);
        BCO365PaymentTermsCard.RunModal;
        Assert.AreNotEqual(DefaultPaymentTermsCode, PaymentTerms.Code, 'Payment terms code was not updated');

        // [THEN] The settings page is updated to reflect the new code
        BCO365Settings.OpenEdit;
        Assert.AreEqual(
          DefaultPaymentTermsCode, BCO365Settings.Payments.PaymentTermsCode.Value,
          'Default payment terms is not updated correctly');
        BCO365Settings.Close;

        // [THEN] The invoice is updated to reflect the new code
        SalesHeader.FindLast;
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoRecord(SalesHeader);
        Assert.AreEqual(
          DefaultPaymentTermsCode, BCO365SalesInvoice."Payment Terms Code".Value,
          'Default payment terms is not updated correctly on the invoice');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,O365PaymentTermsListHandler,O365PaymentTermsCardHandler')]
    [Scope('OnPrem')]
    procedure ModifyPaymentTermsDaysCalculation()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        PaymentTerms: Record "Payment Terms";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        BCO365PaymentTermsCard: Page "BC O365 Payment Terms Card";
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] Due date is changed for the default payment terms
        O365SalesInitialSetup.Get();
        PaymentTerms.Get(O365SalesInitialSetup."Default Payment Terms Code");
        BCO365PaymentTermsCard.SetPaymentTerms(PaymentTerms);
        BCO365PaymentTermsCard.RunModal;

        // [WHEN] An invoice is created
        // [THEN] the new due date is used
        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".Value(LibraryInvoicingApp.CreateCustomer);
        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        Assert.AreEqual(
          CalcDate(StrSubstNo('+%1D', PaymentTermsDays), WorkDate), BCO365SalesInvoice."Due Date".AsDate,
          'Due date is not updated correctly');

        // [WHEN] The payment terms on the invoice is changed
        // [THEN] the new due date is used
        BCO365SalesInvoice."Payment Terms Code".AssistEdit;
        Assert.AreEqual(
          CalcDate(StrSubstNo('+%1D', PaymentTermsDays), WorkDate), BCO365SalesInvoice."Due Date".AsDate,
          'Due date is not updated correctly');
        BCO365SalesInvoice.Close;
    end;

    [Test]
    [HandlerFunctions('O365PaymentMethodCardHandler,O365PaymentTermsCardHandler,EmailDialogModalPageHandler,BCEmailSetupPageHandler,MessageHandler,MarkAsPaidHandler,NotificationHandler,MarkAsUnpaidConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenameDefaultAndPerformStandardScenario()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        BCO365PaymentTermsCard: Page "BC O365 Payment Terms Card";
        BCO365PaymentMethodCard: Page "BC O365 Payment Method Card";
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
        PostedInvoiceNo: Code[20];
        ExistingCustomerName: Text[50];
        ExistingInvoiceNo: Code[20];
        ExistingPostedInvoiceNo: Code[20];
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        O365SalesInitialSetup.Get();
        PreviousPaymentMethodCode := O365SalesInitialSetup."Default Payment Method Code";

        // [GIVEN] An existing customer
        ExistingCustomerName := LibraryInvoicingApp.CreateCustomerWithEmail;

        // [GIVEN] An existing posted invoice
        ExistingPostedInvoiceNo := CreateAndSendInvoice;

        // [GIVEN] An existing payment
        AddPaymentForInvoice(ExistingPostedInvoiceNo);

        // [GIVEN] An existing draft invoice
        ExistingInvoiceNo := LibraryInvoicingApp.CreateInvoice;

        // [WHEN] The default payment term and payment method is renamed through the card but not selected
        PaymentTerms.Get(O365SalesInitialSetup."Default Payment Terms Code");
        BCO365PaymentTermsCard.SetPaymentTerms(PaymentTerms);
        BCO365PaymentTermsCard.RunModal;
        PaymentMethod.Get(O365SalesInitialSetup."Default Payment Method Code");
        BCO365PaymentMethodCard.SetPaymentMethod(PaymentMethod);
        BCO365PaymentMethodCard.RunModal;

        // [THEN] The existing customer can be opened with no errors
        BCO365SalesCustomerCard.OpenEdit;
        Customer.SetRange(Name, ExistingCustomerName);
        Customer.FindFirst;
        BCO365SalesCustomerCard.GotoRecord(Customer);
        BCO365SalesCustomerCard.Close;

        // [WHEN] The existing posted invoice can be opened with no errors
        BCO365PostedSalesInvoice.OpenView;
        BCO365PostedSalesInvoice.GotoKey(ExistingPostedInvoiceNo);

        // [WHEN] The existing payment can be cancelled with no errors
        LibraryVariableStorage.Enqueue(MarkedUnpaidMsg);
        BCO365PostedSalesInvoice.MarkAsUnpaid.Invoke;

        // [WHEN] The existing posted invoice can be paid with no errors
        AddPaymentForInvoice(ExistingPostedInvoiceNo);

        // [WHEN] The existing draft invoice can be opened with no errors
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, ExistingInvoiceNo);
        BCO365SalesInvoice.Close;

        // [WHEN] An invoice for an existing customer can be send and paid with no errors
        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".Value(ExistingCustomerName);
        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        BCO365SalesInvoice.Lines."Unit Price".SetValue(100.59);
        BCO365SalesInvoice.Close;
        SalesHeader.FindLast;
        AddPaymentForInvoice(LibraryInvoicingApp.SendInvoice(SalesHeader."No."));

        // [WHEN] An invoice for a new customer can be send and paid with no errors
        PostedInvoiceNo := CreateAndSendInvoice;
        AddPaymentForInvoice(PostedInvoiceNo);

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('O365PaymentMethodCardHandler,O365PaymentTermsCardHandler,EmailDialogModalPageHandler,BCEmailSetupPageHandler,MessageHandler,MarkAsPaidHandler,NotificationHandler,MarkAsUnpaidConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenameNonDefaultAndPerformStandardScenario()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        BCO365PaymentTermsCard: Page "BC O365 Payment Terms Card";
        BCO365PaymentMethodCard: Page "BC O365 Payment Method Card";
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
        PostedInvoiceNo: Code[20];
        ExistingCustomerName: Text[50];
        ExistingInvoiceNo: Code[20];
        ExistingPostedInvoiceNo: Code[20];
        OldDefaultPaymentMethodCode: Code[10];
        OldDefaultPaymentTermsCode: Code[10];
        ExpectedDefaultPaymentMethodCode: Code[10];
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;
        O365SalesInitialSetup.Get();
        PreviousPaymentMethodCode := O365SalesInitialSetup."Default Payment Method Code";

        // [GIVEN] An existing customer
        ExistingCustomerName := LibraryInvoicingApp.CreateCustomerWithEmail;

        // [GIVEN] An existing posted invoice
        ExistingPostedInvoiceNo := CreateAndSendInvoice;

        // [GIVEN] An existing payment
        AddPaymentForInvoice(ExistingPostedInvoiceNo);

        // [GIVEN] An existing draft invoice
        ExistingInvoiceNo := LibraryInvoicingApp.CreateInvoice;

        // [WHEN] The default payment term and payment method is renamed through the card but not selected
        O365SalesInitialSetup.Get();

        OldDefaultPaymentMethodCode := O365SalesInitialSetup."Default Payment Method Code";
        OldDefaultPaymentTermsCode := O365SalesInitialSetup."Default Payment Terms Code";

        // First change the default before editing
        PaymentMethod.SetFilter(Code, '<>%1', OldDefaultPaymentMethodCode);
        PaymentMethod.SetRange("Use for Invoicing", true);
        PaymentMethod.FindFirst;
        O365SalesInitialSetup.UpdateDefaultPaymentMethod(PaymentMethod.Code);
        ExpectedDefaultPaymentMethodCode := PaymentMethod.Code;
        PaymentTerms.SetFilter(Code, '<>%1', OldDefaultPaymentTermsCode);
        PaymentTerms.FindFirst;
        O365SalesInitialSetup.UpdateDefaultPaymentTerms(PaymentTerms.Code);

        // Next rename payment terms and methods
        PaymentTerms.Get(OldDefaultPaymentTermsCode);
        BCO365PaymentTermsCard.SetPaymentTerms(PaymentTerms);
        BCO365PaymentTermsCard.RunModal;
        PaymentMethod.Get(OldDefaultPaymentMethodCode);
        BCO365PaymentMethodCard.SetPaymentMethod(PaymentMethod);
        BCO365PaymentMethodCard.RunModal;

        // Set expected default payment method
        PreviousPaymentMethodCode := ExpectedDefaultPaymentMethodCode;

        // [THEN] The existing customer can be opened with no errors
        BCO365SalesCustomerCard.OpenEdit;
        Customer.SetRange(Name, ExistingCustomerName);
        Customer.FindFirst;
        BCO365SalesCustomerCard.GotoRecord(Customer);
        BCO365SalesCustomerCard.Close;

        // [WHEN] The existing posted invoice can be opened with no errors
        BCO365PostedSalesInvoice.OpenView;
        BCO365PostedSalesInvoice.GotoKey(ExistingPostedInvoiceNo);

        // [WHEN] The existing payment can be cancelled with no errors
        LibraryVariableStorage.Enqueue(MarkedUnpaidMsg);
        BCO365PostedSalesInvoice.MarkAsUnpaid.Invoke;

        // [WHEN] The existing posted invoice can be paid with no errors
        AddPaymentForInvoice(ExistingPostedInvoiceNo);

        // [WHEN] The existing draft invoice can be opened with no errors
        BCO365SalesInvoice.OpenEdit;
        BCO365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, ExistingInvoiceNo);
        BCO365SalesInvoice.Close;

        // [WHEN] An invoice for an existing customer can be send and paid with no errors
        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".Value(ExistingCustomerName);
        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        BCO365SalesInvoice.Lines."Unit Price".SetValue(100.59);
        BCO365SalesInvoice.Close;
        SalesHeader.FindLast;
        AddPaymentForInvoice(LibraryInvoicingApp.SendInvoice(SalesHeader."No."));

        // [WHEN] An invoice for a new customer can be send and paid with no errors
        PostedInvoiceNo := CreateAndSendInvoice;
        AddPaymentForInvoice(PostedInvoiceNo);

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler,BCEmailSetupPageHandler')]
    [Scope('OnPrem')]
    procedure CanSendInvoiceAfterDeletingPaymentTerms()
    var
        PaymentTerms: Record "Payment Terms";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] All but the default payment term is deleted
        O365SalesInitialSetup.Get();
        PaymentTerms.SetFilter(Code, '<>%1', O365SalesInitialSetup."Default Payment Terms Code");
        PaymentTerms.DeleteAll(true);

        // [THEN] An invoice can be sent
        CreateAndSendInvoice;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure CannotDeleteDefaultPaymentTerms()
    var
        PaymentTerms: Record "Payment Terms";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] Removing the default payment term
        // [THEN] An error is thrown
        O365SalesInitialSetup.Get();
        PaymentTerms.Get(O365SalesInitialSetup."Default Payment Terms Code");
        asserterror PaymentTerms.Delete(true);
        Assert.ExpectedError(CannotRemoveDefaultPaymentTermsErr);
    end;

    local procedure AddPaymentForInvoice(DocumentNo: Code[20])
    var
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
    begin
        BCO365PostedSalesInvoice.OpenView;
        BCO365PostedSalesInvoice.GotoKey(DocumentNo);

        LibraryVariableStorage.Enqueue(MarkedPaidMsg);
        BCO365PostedSalesInvoice.MarkAsPaid.Invoke;
    end;

    local procedure CreateAndSendInvoice() PostedInvoiceNo: Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        InvoiceNo: Code[20];
    begin
        BCO365SalesInvoice.OpenNew;
        BCO365SalesInvoice."Sell-to Customer Name".Value(LibraryInvoicingApp.CreateCustomerWithEmail);

        BCO365SalesInvoice.Lines.Description.Value(LibraryInvoicingApp.CreateItem);
        BCO365SalesInvoice.Lines."Unit Price".SetValue(LibraryRandom.RandDec(100, 2));

        SalesHeader.FindLast;
        InvoiceNo := SalesHeader."No.";

        BCO365SalesInvoice.Post.Invoke;

        SalesInvoiceHeader.SetRange("Pre-Assigned No.", InvoiceNo);
        SalesInvoiceHeader.FindFirst;
        PostedInvoiceNo := SalesInvoiceHeader."No.";
    end;

    local procedure Initialize()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        BindActiveDirectoryMockEvents;

        LibraryVariableStorage.AssertEmpty;
        SMTPMailSetup.DeleteAll();
        EventSubscriberInvoicingApp.Clear;
        ApplicationArea('#Invoicing');
        O365SalesInitialSetup.Get();
        Clear(PreviousPaymentMethodCode);
        Clear(DefaultPaymentTermsCode);
        Clear(PaymentTermsDays);

        if IsInitialized then
            exit;

        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider;
        LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify();

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
        AmountReceived: Decimal;
    begin
        if PreviousPaymentMethodCode = '' then
            O365MarkAsPaid.PaymentMethod.AssistEdit;
        Assert.AreEqual(PreviousPaymentMethodCode, O365MarkAsPaid.PaymentMethod.Value, '');
        Evaluate(AmountReceived, O365MarkAsPaid.AmountReceived.Value);
        O365MarkAsPaid.AmountReceived.SetValue(AmountReceived / 10);
        O365MarkAsPaid.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure MarkAsUnpaidConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(MarkAsUnpaidConfirmQst, Question, '');
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure O365PaymentMethodListHandler(var O365PaymentMethodList: TestPage "O365 Payment Method List")
    begin
        O365PaymentMethodList._NEW_TEMP_.Invoke;
        O365PaymentMethodList.GotoKey(PreviousPaymentMethodCode);
        O365PaymentMethodList.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure O365PaymentMethodCardHandler(var BCO365PaymentMethodCard: TestPage "BC O365 Payment Method Card")
    begin
        PreviousPaymentMethodCode := LibraryUtility.GenerateGUID;
        BCO365PaymentMethodCard.PaymentMethodCode.Value(PreviousPaymentMethodCode);
        BCO365PaymentMethodCard.PaymentMethodDescription.Value(LibraryUtility.GenerateGUID);
        BCO365PaymentMethodCard.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure O365PaymentTermsListHandler(var O365PaymentTermsList: TestPage "O365 Payment Terms List")
    begin
        if DefaultPaymentTermsCode = '' then
            O365PaymentTermsList._NEW_TEMP_.Invoke;
        O365PaymentTermsList.GotoKey(DefaultPaymentTermsCode);
        O365PaymentTermsList.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure O365PaymentTermsCardHandler(var BCO365PaymentTermsCard: TestPage "BC O365 Payment Terms Card")
    begin
        DefaultPaymentTermsCode := LibraryUtility.GenerateGUID;
        PaymentTermsDays := LibraryRandom.RandInt(10);
        BCO365PaymentTermsCard.PaymentTermsCode.Value(DefaultPaymentTermsCode);
        BCO365PaymentTermsCard.Days.SetValue(PaymentTermsDays);
        BCO365PaymentTermsCard.OK.Invoke;
    end;

    local procedure RecallPostedInvoiceNotification(InvoiceNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(InvoiceNo);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesInvoiceHeader);
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
    procedure NotificationHandler(var TheNotification: Notification): Boolean
    begin
        if StrPos(TheNotification.Message, 'The last email about this document could not be sent') <> 0 then
            exit;
        if TheNotification.Message = TaxSetupNeededMsg then
            exit;
        Error(UnhandledNotificationErr, TheNotification.Message);
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

