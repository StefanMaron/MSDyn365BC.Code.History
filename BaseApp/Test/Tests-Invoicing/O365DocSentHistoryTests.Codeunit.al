codeunit 138958 "O365 Doc. Sent History Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Document Sent History]
    end;

    var
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        Assert: Codeunit Assert;
        EstimateSentMsg: Label 'Your estimate is being sent.';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        IsInitialized: Boolean;
        RoleCenterEmailErrorIDTxt: Label '{c3c760b9-6405-aaaa-b2a6-1affb70c38bf}';
        EmailFailedCheckSetupTxt: Label 'The last email about this document could not be sent. Check your email setup. If you turned on multi-factor authentication for the email address, you might need to set up an app password.';
        EmailFailedCustomCodeTxt: Label 'The last email about this document could not be sent. We received the following error code: ';
        EmailFailedCheckCustomerTxt: Label 'The last email about this document could not be sent. Check the recipient''s email address.';

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSendingQuoteCreatesNewHistoryEntry()
    var
        O365DocumentSentHistory: Record "O365 Document Sent History";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        EstimateNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A sales quote that has not yet been sent
        EstimateNo := LibraryInvoicingApp.CreateEstimate;
        O365DocumentSentHistory.SetRange("Document No.", EstimateNo);
        Assert.RecordCount(O365DocumentSentHistory, 0);

        // [WHEN] The user sends the sales quote
        LibraryVariableStorage.Enqueue(EstimateSentMsg);
        LibraryInvoicingApp.SendEstimate(EstimateNo);

        // [THEN] Exactly one document sent history entry is created
        O365DocumentSentHistory.SetRange("Document No.", EstimateNo);
        O365DocumentSentHistory.SetRange("Document Type", O365DocumentSentHistory."Document Type"::Quote);
        O365DocumentSentHistory.SetRange(Posted, false);

        Assert.RecordCount(O365DocumentSentHistory, 1);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostingInvoiceCreatesNewHistoryEntry()
    var
        O365DocumentSentHistory: Record "O365 Document Sent History";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        DraftInvoiceNo: Code[20];
        PostedInvNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A sales invoice that has not yet been sent
        DraftInvoiceNo := LibraryInvoicingApp.CreateInvoice;
        O365DocumentSentHistory.SetRange("Document No.", DraftInvoiceNo);
        Assert.RecordCount(O365DocumentSentHistory, 0);

        // [WHEN] The user sends the sales invoice
        PostedInvNo := LibraryInvoicingApp.SendInvoice(DraftInvoiceNo);

        // [THEN] Exactly one document sent history entry is created
        O365DocumentSentHistory.SetRange("Document No.", PostedInvNo);
        O365DocumentSentHistory.SetRange("Document Type", O365DocumentSentHistory."Document Type"::Invoice);
        O365DocumentSentHistory.SetRange(Posted, true);

        Assert.RecordCount(O365DocumentSentHistory, 1);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestFailureAppearsInQuote()
    var
        SalesHeader: Record "Sales Header";
        EstimateNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] A sales quote fails to send
        EstimateNo := CreateAndSendEstimateWithError('');

        // [THEN] The flow fields in the sales header report the correct values for the failure
        with SalesHeader do begin
            SetRange("Document Type", "Document Type"::Quote);
            SetRange("No.", EstimateNo);
            FindFirst;
            CalcFields("Last Email Sent Time", "Last Email Sent Status", "Sent as Email");
            Assert.IsFalse("Sent as Email", 'Should not be sent as email');
            Assert.AreNotEqual("Last Email Sent Time", 0DT, 'Email sent time is empty');
            Assert.AreEqual("Last Email Sent Status", "Last Email Sent Status"::Error, 'Job should have failed');
        end;

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestFailureAppearsInPostedInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedInvNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] A sales invoice fails to send
        PostedInvNo := CreateAndPostInvoiceWithError('');

        // [THEN] The flow fields in the posted sales header report the correct values for the failure
        with SalesInvoiceHeader do begin
            SetRange("No.", PostedInvNo);
            FindFirst;
            CalcFields("Last Email Sent Time", "Last Email Sent Status", "Sent as Email");
            Assert.IsFalse("Sent as Email", 'Should not be sent as email');
            Assert.AreNotEqual("Last Email Sent Time", 0DT, 'Email sent time is empty');
            Assert.AreEqual("Last Email Sent Status", "Last Email Sent Status"::Error, 'Job should have failed');
        end;

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSuccessAppearsInQuote()
    var
        SalesHeader: Record "Sales Header";
        EstimateNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] A sales quote is successfully sent
        EstimateNo := CreateAndSendEstimateSuccessfully;

        // [THEN] The flow fields in the sales header report the correct values for the success
        with SalesHeader do begin
            SetRange("Document Type", "Document Type"::Quote);
            SetRange("No.", EstimateNo);
            FindFirst;
            CalcFields("Last Email Sent Time", "Last Email Sent Status", "Sent as Email");
            Assert.IsTrue("Sent as Email", 'Should be sent as email');
            Assert.AreNotEqual("Last Email Sent Time", 0DT, 'Email sent time is empty');
            Assert.AreEqual("Last Email Sent Status", "Last Email Sent Status"::Finished, 'Job should have succeeded');
        end;

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestSuccessAppearsInPostedInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedInvNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] A sales invoice is succesfully sent
        PostedInvNo := CreateAndPostInvoiceSuccessfully;

        // [THEN] The flow fields in the posted sales header report the correct values for the success
        with SalesInvoiceHeader do begin
            SetRange("No.", PostedInvNo);
            FindFirst;
            CalcFields("Last Email Sent Time", "Last Email Sent Status", "Sent as Email");
            Assert.IsTrue("Sent as Email", 'Should be sent as email');
            Assert.AreNotEqual("Last Email Sent Time", 0DT, 'Email sent time is empty');
            Assert.AreEqual("Last Email Sent Status", "Last Email Sent Status"::Finished, 'Job should have succeeded');
        end;

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,SendErrorNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestFailureNotificationPostedInvoicePhon()
    var
        O365SalesDocument: Record "O365 Sales Document";
        O365PostedSalesInvoice: TestPage "O365 Posted Sales Invoice";
        O365SalesActivitiesRC: TestPage "O365 Sales Activities RC";
        PostedInvNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] A sales invoice fails to send
        PostedInvNo := CreateAndPostInvoiceWithError('');

        // [THEN] In the phone role center a notification is displayed: handler is called and ID saved
        O365SalesActivitiesRC.OpenView;
        Assert.AreEqual(
          UpperCase(LibraryVariableStorage.DequeueText), UpperCase(RoleCenterEmailErrorIDTxt),
          'The RC error notification is not displayed, or the ID has changed.');
        O365SalesActivitiesRC.Close;

        // [THEN] We also have a failed notification when opening invoice page on phone: handler is called and ID saved
        O365PostedSalesInvoice.OpenEdit;
        O365PostedSalesInvoice.GotoKey(PostedInvNo);
        Assert.IsFalse(
          IsNullGuid(LibraryVariableStorage.DequeueText), 'The error notification is not displayed in the invoice card page.');

        RecallPostedInvoiceNotification(PostedInvNo);
        LibraryNotificationMgt.RecallNotificationsForRecord(O365SalesDocument);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,MessageHandler,SendErrorNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestFailureNotificationEstimatePhone()
    var
        DummySalesHeader: Record "Sales Header";
        O365SalesDocument: Record "O365 Sales Document";
        O365SalesQuote: TestPage "O365 Sales Quote";
        O365SalesActivitiesRC: TestPage "O365 Sales Activities RC";
        EstimateNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] An estimate fails to send
        EstimateNo := CreateAndSendEstimateWithError('');

        // [THEN] In the phone role center a notification is displayed: handler is called and ID saved
        O365SalesActivitiesRC.OpenView;
        Assert.AreEqual(
          UpperCase(LibraryVariableStorage.DequeueText), UpperCase(RoleCenterEmailErrorIDTxt),
          'The RC error notification is not displayed, or the ID has changed.');
        O365SalesActivitiesRC.Close;

        // [THEN] We also have a failed notification when opening estimate page on phone: handler is called and ID saved
        O365SalesQuote.OpenEdit;
        O365SalesQuote.GotoKey(DummySalesHeader."Document Type"::Quote, EstimateNo);
        Assert.IsFalse(
          IsNullGuid(LibraryVariableStorage.DequeueText), 'The error notification is not displayed in the estimate card page.');

        RecallQuoteNotification(EstimateNo);
        LibraryNotificationMgt.RecallNotificationsForRecord(O365SalesDocument);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,SendErrorNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestFailureNotificationPostedInvoiceBC()
    var
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
        PostedInvNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] A sales invoice fails to send
        PostedInvNo := CreateAndPostInvoiceWithError('');

        // [THEN] We have a failed notification when opening invoice BC page: handler is called and ID saved
        BCO365PostedSalesInvoice.OpenEdit;
        BCO365PostedSalesInvoice.GotoKey(PostedInvNo);
        Assert.IsFalse(
          IsNullGuid(LibraryVariableStorage.DequeueText), 'The error notification is not displayed in the invoice card page.');

        RecallPostedInvoiceNotification(PostedInvNo);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,MessageHandler,SendErrorNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestFailureNotificationEstimateBC()
    var
        DummySalesHeader: Record "Sales Header";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
        EstimateNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] An estimate fails to send
        EstimateNo := CreateAndSendEstimateWithError('');

        // [THEN] We also have a failed notification when opening estimate BC page: handler is called and ID saved
        BCO365SalesQuote.OpenEdit;
        BCO365SalesQuote.GotoKey(DummySalesHeader."Document Type"::Quote, EstimateNo);
        Assert.IsFalse(
          IsNullGuid(LibraryVariableStorage.DequeueText), 'The error notification is not displayed in the estimate card page.');

        RecallQuoteNotification(EstimateNo);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestNoNotificationIfSuccessPostedInvoicePhone()
    var
        O365PostedSalesInvoice: TestPage "O365 Posted Sales Invoice";
        O365SalesActivitiesRC: TestPage "O365 Sales Activities RC";
        PostedInvNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] A sales invoice is successfully sent
        PostedInvNo := CreateAndPostInvoiceSuccessfully;

        // [THEN] In the phone role center no failed notification is displayed: handler is not called
        O365SalesActivitiesRC.OpenView;
        O365SalesActivitiesRC.Close;

        // [THEN] Opening the invoice page on phone does also display no notification: handler is not called
        O365PostedSalesInvoice.OpenEdit;
        O365PostedSalesInvoice.GotoKey(PostedInvNo);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestNoNotificationIfSuccessEstimatePhone()
    var
        DummySalesHeader: Record "Sales Header";
        O365SalesQuote: TestPage "O365 Sales Quote";
        O365SalesActivitiesRC: TestPage "O365 Sales Activities RC";
        EstimateNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] An estimate is successfully sent
        EstimateNo := CreateAndSendEstimateSuccessfully;

        // [THEN] In the phone role center no failed notification is displayed: handler is not called
        O365SalesActivitiesRC.OpenView;
        O365SalesActivitiesRC.Close;

        // [THEN] Opening the estimate page on phone does also display no notification: handler is not called
        O365SalesQuote.OpenEdit;
        O365SalesQuote.GotoKey(DummySalesHeader."Document Type"::Quote, EstimateNo);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestNoNotificationIfSuccessPostedInvoiceBC()
    var
        O365PostedSalesInvoice: TestPage "O365 Posted Sales Invoice";
        PostedInvNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] A sales invoice is successfully sent
        PostedInvNo := CreateAndPostInvoiceSuccessfully;

        // [THEN] Opening the invoice BC page displays no notification: handler is not called
        O365PostedSalesInvoice.OpenEdit;
        O365PostedSalesInvoice.GotoKey(PostedInvNo);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestNoNotificationIfSuccessEstimateBC()
    var
        DummySalesHeader: Record "Sales Header";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
        EstimateNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] An estimate is successfully sent
        EstimateNo := CreateAndSendEstimateSuccessfully;

        // [THEN] Opening the estimate BC page displays no notification: handler is not called
        BCO365SalesQuote.OpenEdit;
        BCO365SalesQuote.GotoKey(DummySalesHeader."Document Type"::Quote, EstimateNo);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,MessageHandler,OpenFailedDocumentListFromRCNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestClearOneDocumentNotificationRC()
    var
        O365DocumentSentHistory: Record "O365 Document Sent History";
        O365SalesDocument: Record "O365 Sales Document";
        O365SalesActivitiesRC: TestPage "O365 Sales Activities RC";
        BCO365SentDocumentsList: TestPage "BC O365 Sent Documents List";
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] More than one document fails to send, and the notification for one document is cleared on phone
        CreateAndPostInvoiceWithError('');
        CreateAndSendEstimateWithError('');
        CreateAndPostInvoiceWithError('');
        BCO365SentDocumentsList.Trap; // opened from handler
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue('Some documents could not be sent.');
        O365SalesActivitiesRC.OpenView;
        BCO365SentDocumentsList.Clear.Invoke;
        BCO365SentDocumentsList.Close;

        // [THEN] Flag for notifications are set correctly
        O365DocumentSentHistory.SetRange(NotificationCleared, false);
        O365DocumentSentHistory.SetRange("Job Last Status", O365DocumentSentHistory."Job Last Status"::Error);
        Assert.AreEqual(2, O365DocumentSentHistory.Count, 'Notifications not cleared correctly');

        LibraryNotificationMgt.RecallNotificationsForRecord(O365SalesDocument);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,MessageHandler,OpenFailedDocumentListFromRCNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestClearAllDocumentsNotificationsRC()
    var
        O365DocumentSentHistory: Record "O365 Document Sent History";
        O365SalesDocument: Record "O365 Sales Document";
        O365SalesActivitiesRC: TestPage "O365 Sales Activities RC";
        BCO365SentDocumentsList: TestPage "BC O365 Sent Documents List";
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] More than one document fails to send, and the notifications are cleared on phone
        CreateAndPostInvoiceWithError('');
        CreateAndPostInvoiceWithError('');
        CreateAndSendEstimateWithError('');
        BCO365SentDocumentsList.Trap; // opened from handler
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue('Some documents could not be sent.');
        O365SalesActivitiesRC.OpenView;
        BCO365SentDocumentsList.ClearAll.Invoke;
        BCO365SentDocumentsList.Close;

        // [THEN] Flag for notifications are set correctly
        O365DocumentSentHistory.SetRange(NotificationCleared, false);
        O365DocumentSentHistory.SetRange("Job Last Status", O365DocumentSentHistory."Job Last Status"::Error);
        Assert.AreEqual(0, O365DocumentSentHistory.Count, 'Notifications not cleared');

        LibraryNotificationMgt.RecallNotificationsForRecord(O365SalesDocument);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,OpenSetupEmailFromInvoiceNotificationHandler,BCEmailSetupModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationActionSetupEmail()
    var
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
        PostedInvNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] A sales invoice fails to send, and the Setup Email notification action is called from invoice page
        PostedInvNo := CreateAndPostInvoiceWithError('The server response was: 5.5.1 and the rest will be ignored');
        LibraryVariableStorage.Enqueue(3);
        LibraryVariableStorage.Enqueue(EmailFailedCheckSetupTxt);
        BCO365PostedSalesInvoice.OpenEdit;
        BCO365PostedSalesInvoice.GotoKey(PostedInvNo); // Notification handler calls action to setup email

        // [THEN] The email setup page is open
        // Modal page handler called for email setup
        RecallPostedInvoiceNotification(PostedInvNo);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,OpenSetupEmailFromInvoiceNotificationHandler,BCEmailSetupModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationActionSetupEmailAlternative()
    var
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
        PostedInvNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] A sales invoice fails to send, and the Setup Email notification action is called from invoice page
        PostedInvNo := CreateAndPostInvoiceWithError('The server response was: 5.7.57 and the rest will be ignored');
        LibraryVariableStorage.Enqueue(3);
        LibraryVariableStorage.Enqueue(EmailFailedCheckSetupTxt);
        BCO365PostedSalesInvoice.OpenEdit;
        BCO365PostedSalesInvoice.GotoKey(PostedInvNo); // Notification handler calls action to setup email

        // [THEN] The email setup page is open
        // Modal page handler called for email setup
        RecallPostedInvoiceNotification(PostedInvNo);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,OpenCustomerFromInvoiceNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationActionOpenCustomer()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        BCO365SalesCustomerCard: TestPage "BC O365 Sales Customer Card";
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
        PostedInvNo: Code[20];
    begin
        // [GIVEN] The user has set up an email and has some customers
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;
        LibraryInvoicingApp.CreateCustomer;
        LibraryInvoicingApp.CreateCustomer;

        // [WHEN] An invoice fails to send, and the Edit Customer notification action is called from invoice page
        PostedInvNo := CreateAndPostInvoiceWithError('The server response was: 5.1.6 and the rest will be ignored');
        BCO365SalesCustomerCard.Trap; // opened by handler
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue(EmailFailedCheckCustomerTxt);
        BCO365PostedSalesInvoice.OpenEdit;
        BCO365PostedSalesInvoice.GotoKey(PostedInvNo);

        // [THEN] The correct customer card page is open
        SalesInvoiceHeader.Get(PostedInvNo);
        Assert.AreEqual(SalesInvoiceHeader."Sell-to Customer Name", BCO365SalesCustomerCard.Name.Value, 'Wrong customer card is open.');

        RecallPostedInvoiceNotification(PostedInvNo);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,MessageHandler,ResendDocumentNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationActionResendQuote()
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
        EstimateNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] An estimate fails to send, and the Resend Now notification action is called from the estimate page
        EstimateNo := CreateAndSendEstimateWithError('The server response was: 7.8.9');

        // [THEN] The email can be resent from the notification
        EventSubscriberInvoicingApp.OverrideJobQueueResult(true);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(EmailFailedCustomCodeTxt + '7.8.9.');
        BCO365SalesQuote.OpenEdit; // calls notification handler, which calls email page handler
        BCO365SalesQuote.GotoKey(SalesHeader."Document Type"::Quote, EstimateNo);

        RecallQuoteNotification(EstimateNo);

        Cleanup;
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,ResendDocumentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestNotificationActionResendInvoice()
    var
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
        PostedInvNo: Code[20];
    begin
        // [GIVEN] The user has set up an email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] A sales estimate fails to send, and the Resend Now notification action is called from the estimate page
        PostedInvNo := CreateAndPostInvoiceWithError('The server response was: EmailSendingFailedBecauseYouTypedTheWrongEmailException');

        // [THEN] The email can be resent from the notification
        EventSubscriberInvoicingApp.OverrideJobQueueResult(true);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(EmailFailedCustomCodeTxt + 'EmailSendingFailedBecauseYouTypedTheWrongEmailException.');
        BCO365PostedSalesInvoice.OpenEdit; // calls notification handler, which calls email page handler
        BCO365PostedSalesInvoice.GotoKey(PostedInvNo);

        RecallPostedInvoiceNotification(PostedInvNo);

        Cleanup;
    end;

    local procedure Initialize()
    var
        O365DocumentSentHistory: Record "O365 Document Sent History";
        TaxDetail: Record "Tax Detail";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        BindActiveDirectoryMockEvents;

        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider;
        LibraryAzureKVMockMgmt.EnsureSecretNameIsAllowed('SmtpSetup');

        LibraryInvoicingApp.SetupEmail;
        EventSubscriberInvoicingApp.Clear;
        LibraryVariableStorage.AssertEmpty;
        O365DocumentSentHistory.DeleteAll;
        TaxDetail.ModifyAll("Tax Below Maximum", 5.0, true);

        LibraryNotificationMgt.ClearTemporaryNotificationContext;

        if IsInitialized then
            exit;

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        IsInitialized := true;
    end;

    local procedure Cleanup()
    begin
        EventSubscriberInvoicingApp.Clear;
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
    procedure BCEmailSetupModalPageHandler(var BCO365EmailSetupWizard: TestPage "BC O365 Email Setup Wizard")
    var
        EmailProvider: Option "Office 365",Other;
    begin
        with BCO365EmailSetupWizard.EmailSettingsWizardPage do begin
            "Email Provider".SetValue(EmailProvider::"Office 365");
            FromAccount.SetValue('test@microsoft.com');
            Password.SetValue('pass');
        end;

        BCO365EmailSetupWizard.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        if O365SalesEmailDialog.SendToText.Value = '' then
            O365SalesEmailDialog.SendToText.Value('invoicing@microsoft.com');
        O365SalesEmailDialog.OK.Invoke;
    end;

    local procedure CreateAndSendEstimateSuccessfully() EstimateNo: Code[20]
    begin
        EstimateNo := LibraryInvoicingApp.CreateEstimate;
        EventSubscriberInvoicingApp.OverrideJobQueueResult(true);
        LibraryVariableStorage.Enqueue(EstimateSentMsg);
        LibraryInvoicingApp.SendEstimate(EstimateNo);
    end;

    local procedure CreateAndSendEstimateWithError(EmailSendingError: Text) EstimateNo: Code[20]
    begin
        EstimateNo := LibraryInvoicingApp.CreateEstimate;
        EventSubscriberInvoicingApp.OverrideJobQueueResultWithError(EmailSendingError);
        LibraryVariableStorage.Enqueue(EstimateSentMsg);
        LibraryInvoicingApp.SendEstimate(EstimateNo);
    end;

    local procedure CreateAndPostInvoiceSuccessfully() PostedInvNo: Code[20]
    var
        DraftInvoiceNo: Code[20];
    begin
        DraftInvoiceNo := LibraryInvoicingApp.CreateInvoice;
        EventSubscriberInvoicingApp.OverrideJobQueueResult(true);
        PostedInvNo := LibraryInvoicingApp.SendInvoice(DraftInvoiceNo);
    end;

    local procedure CreateAndPostInvoiceWithError(EmailSendingError: Text) PostedInvNo: Code[20]
    var
        DraftInvoiceNo: Code[20];
    begin
        DraftInvoiceNo := LibraryInvoicingApp.CreateInvoice;
        EventSubscriberInvoicingApp.OverrideJobQueueResultWithError(EmailSendingError);
        PostedInvNo := LibraryInvoicingApp.SendInvoice(DraftInvoiceNo);
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable;
    end;

    local procedure RecallPostedInvoiceNotification(InvoiceNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(InvoiceNo);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesInvoiceHeader);
    end;

    local procedure RecallQuoteNotification(QuoteNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Quote, QuoteNo);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendErrorNotificationHandler(var TheNotification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Format(TheNotification.Id));
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure OpenFailedDocumentListFromRCNotificationHandler(var TheNotification: Notification): Boolean
    var
        O365DocumentSendMgt: Codeunit "O365 Document Send Mgt";
        ExpectedNumberOfActions: Integer;
        NotificationMessage: Text;
    begin
        ExpectedNumberOfActions := LibraryVariableStorage.DequeueInteger;
        NotificationMessage := TheNotification.Message;

        Assert.AreEqual(NotificationMessage, LibraryVariableStorage.DequeueText, 'Unexpected notification message.');

        while ExpectedNumberOfActions < 3 do begin // The maximum number of actions for notification is 3
            TheNotification.AddAction('Action', CODEUNIT::"O365 Document Send Mgt", 'ShowSendingFailedDocumentList');
            ExpectedNumberOfActions := ExpectedNumberOfActions + 1;
        end;

        asserterror TheNotification.AddAction('Action', CODEUNIT::"O365 Document Send Mgt", 'ClearNotificationsForAllDocumentsAction');

        O365DocumentSendMgt.ShowSendingFailedDocumentList(TheNotification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure OpenCustomerFromInvoiceNotificationHandler(var TheNotification: Notification): Boolean
    var
        O365DocumentSendMgt: Codeunit "O365 Document Send Mgt";
        ExpectedNumberOfActions: Integer;
        NotificationMessage: Text;
    begin
        ExpectedNumberOfActions := LibraryVariableStorage.DequeueInteger;
        NotificationMessage := TheNotification.Message;

        Assert.AreEqual(NotificationMessage, LibraryVariableStorage.DequeueText, 'Unexpected notification message.');

        while ExpectedNumberOfActions < 3 do begin // The maximum number of actions for notification is 3
            TheNotification.AddAction('Action', CODEUNIT::"O365 Document Send Mgt", 'OpenCustomerFromNotification');
            ExpectedNumberOfActions := ExpectedNumberOfActions + 1;
        end;

        asserterror TheNotification.AddAction('Action', CODEUNIT::"O365 Document Send Mgt", 'OpenCustomerFromNotification');

        O365DocumentSendMgt.OpenCustomerFromNotification(TheNotification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure OpenSetupEmailFromInvoiceNotificationHandler(var TheNotification: Notification): Boolean
    var
        O365DocumentSendMgt: Codeunit "O365 Document Send Mgt";
        ExpectedNumberOfActions: Integer;
        NotificationMessage: Text;
    begin
        ExpectedNumberOfActions := LibraryVariableStorage.DequeueInteger;
        NotificationMessage := TheNotification.Message;

        Assert.AreEqual(NotificationMessage, LibraryVariableStorage.DequeueText, 'Unexpected notification message.');

        while ExpectedNumberOfActions < 3 do begin // The maximum number of actions for notification is 3
            TheNotification.AddAction('Action', CODEUNIT::"O365 Document Send Mgt", 'OpenSetupEmailFromNotification');
            ExpectedNumberOfActions := ExpectedNumberOfActions + 1;
        end;

        asserterror TheNotification.AddAction('Action', CODEUNIT::"O365 Document Send Mgt", 'OpenSetupEmailFromNotification');

        O365DocumentSendMgt.OpenSetupEmailFromNotification(TheNotification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure ResendDocumentNotificationHandler(var TheNotification: Notification): Boolean
    var
        O365DocumentSentHistory: Record "O365 Document Sent History";
        O365DocumentSendMgt: Codeunit "O365 Document Send Mgt";
        ExpectedNumberOfActions: Integer;
        NotificationMessage: Text;
    begin
        ExpectedNumberOfActions := LibraryVariableStorage.DequeueInteger;
        NotificationMessage := TheNotification.Message;

        Assert.AreEqual(NotificationMessage, LibraryVariableStorage.DequeueText, 'Unexpected notification message.');

        while ExpectedNumberOfActions < 3 do begin // The maximum number of actions for notification is 3
            TheNotification.AddAction('Action', CODEUNIT::"O365 Document Send Mgt", 'ResendDocumentFromNotification');
            ExpectedNumberOfActions := ExpectedNumberOfActions + 1;
        end;

        asserterror TheNotification.AddAction('Action', CODEUNIT::"O365 Document Send Mgt", 'ResendDocumentFromNotification');

        O365DocumentSendMgt.ResendDocumentFromNotification(TheNotification);
        O365DocumentSentHistory.DeleteAll;
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
        exit(true);
    end;
}

