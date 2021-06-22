codeunit 138925 "O365 Email Dialog Tests"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Email Dialog]
    end;

    var
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        InvoiceSentMsg: Label 'Your invoice is being sent.';
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        MailManagement: Codeunit "Mail Management";
        DocumentMailing: Codeunit "Document-Mailing";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        IsInitialized: Boolean;
        EstimateSentMsg: Label 'Your estimate is being sent.';
        InvoiceEmailSubjectTxt: Label 'Invoice from %1';
        EstimateEmailSubjectTxt: Label 'Estimate from %1';
        ModifyEmailParameter: Boolean;
        CancelEmail: Boolean;
        ConfirmConvertToInvoiceQst: Label 'Do you want to turn the estimate into a draft invoice?';
        TaxSetupNeededTxt: Label 'You haven''t set up tax information for your business.';
        EmailFailedNotifPrefixTxt: Label 'The last email about this document could not be sent';
        EmailFailedGenericMsg: Label 'The last email about this document could not be sent.';
        TestInvoiceSendingMsg: Label 'Your test invoice is being sent.';

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestDraftInvoiceDefaultEmailSubject()
    var
        CompanyName: Text;
    begin
        // [Scenario] Default subject of draft invoice
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] The company has a name
        CompanyName := SetCompanyName;

        // [WHEN] An invoice is sent
        SendInvoice(LibraryInvoicingApp.CreateInvoice);

        // [THEN] The subject of the draft invoice is "Invoice from <CompanyName>"
        Assert.AreEqual(StrSubstNo(InvoiceEmailSubjectTxt, CompanyName), EventSubscriberInvoicingApp.GetEmailSubject, '');
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,MessageHandler,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestSentInvoiceDefaultEmailSubject()
    var
        PostedInvoiceNo: Code[20];
        CompanyName: Text;
    begin
        // [Scenario] Default subject of sent invoice
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] The company has a name
        CompanyName := SetCompanyName;

        // [GIVEN] A posted invoice
        PostedInvoiceNo := SendInvoice(LibraryInvoicingApp.CreateInvoice);
        EventSubscriberInvoicingApp.Clear;

        // [WHEN] A sent invoice is sent
        ReSendInvoice(PostedInvoiceNo);

        // [THEN] The subject of the sent invoice is "Invoice from <CompanyName>"
        Assert.AreEqual(StrSubstNo(InvoiceEmailSubjectTxt, CompanyName), EventSubscriberInvoicingApp.GetEmailSubject, '');

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,EmailDialogModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestEstimateDefaultEmailSubject()
    var
        CompanyName: Text;
    begin
        // [Scenario] Default subject of estimates
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] The company has a name
        CompanyName := SetCompanyName;

        // [WHEN] An estimate is sent
        SendEstimate(LibraryInvoicingApp.CreateEstimate);

        // [THEN] The subject of the estimate is "Estimate from <CompanyName>"
        Assert.AreEqual(StrSubstNo(EstimateEmailSubjectTxt, CompanyName), EventSubscriberInvoicingApp.GetEmailSubject, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SubjectChangeEmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestDraftInvoiceModifiedEmailSubjectOnSendEmail()
    var
        EmailSubject: Text;
    begin
        // [Scenario] User modified email subject (draft invoice)
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] A draft invoice has been sent with a modified email subject
        EmailSubject := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(EmailSubject);
        SendInvoice(LibraryInvoicingApp.CreateInvoice);

        // [THEN] The sent email has the modfied subject
        Assert.AreEqual(EmailSubject, EventSubscriberInvoicingApp.GetEmailSubject, '');
    end;

    [Test]
    [HandlerFunctions('SubjectChangeEmailDialogModalPageHandler,MessageHandler,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestSentInvoiceModifiedEmailSubjectOnSendEmail()
    var
        PostedInvoiceNo: Code[20];
        EmailSubject: Text;
    begin
        // [Scenario] User modified email subject (sent invoice)
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] Sent invoice
        EmailSubject := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(EmailSubject);
        PostedInvoiceNo := SendInvoice(LibraryInvoicingApp.CreateInvoice);

        // [WHEN] The sent invoice has been sent with a modified email subject
        EmailSubject := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(EmailSubject);
        ReSendInvoice(PostedInvoiceNo);

        // [THEN] The sent email has the modfied subject
        Assert.AreEqual(EmailSubject, EventSubscriberInvoicingApp.GetEmailSubject, '');

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SubjectChangeEmailDialogModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestEstimateModifiedEmailSubjectOnSendEmail()
    var
        EmailSubject: Text;
    begin
        // [Scenario] User modified email subject (Estimate)
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] An estimate has been sent with a modified email subject
        EmailSubject := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(EmailSubject);
        SendEstimate(LibraryInvoicingApp.CreateEstimate);

        // [THEN] The sent email has the modfied subject
        Assert.AreEqual(EmailSubject, EventSubscriberInvoicingApp.GetEmailSubject, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SubjectChangeEmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestDraftInvoiceEmailSubjectChangedOnCancelSendEmail()
    var
        EmailSubject: Text;
        InvoiceNo: Code[20];
    begin
        // [Scenario] User modified email subject but did not send email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] User clicks send invoice, modifies subject and cancels sending
        CancelEmail := true;
        EmailSubject := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(EmailSubject);
        InvoiceNo := LibraryInvoicingApp.CreateInvoice;
        SendInvoice(InvoiceNo);

        // [WHEN] User send the invoice
        CancelEmail := false;
        ModifyEmailParameter := false;
        SendInvoice(InvoiceNo);

        // [THEN] The sent email has the modfied subject
        Assert.AreEqual(EmailSubject, EventSubscriberInvoicingApp.GetEmailSubject, '');
    end;

    [Test]
    [HandlerFunctions('SubjectChangeEmailDialogModalPageHandler,MessageHandler,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestSentInvoiceEmailSubjectChangedOnCancelSendEmail()
    var
        PostedInvoiceNo: Code[20];
        EmailSubject: Text;
    begin
        // [Scenario] User modified email subject of sent invoice but did not send email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] Sent invoice
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID);
        PostedInvoiceNo := SendInvoice(LibraryInvoicingApp.CreateInvoice);

        // [GIVEN] User clicks send invoice, modifies subject and cancels sending
        CancelEmail := true;
        EmailSubject := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(EmailSubject);
        ReSendInvoice(PostedInvoiceNo);

        // [WHEN] User resends the invoice
        CancelEmail := false;
        ModifyEmailParameter := false;
        ReSendInvoice(PostedInvoiceNo);

        // [THEN] The sent email has the modfied subject
        Assert.AreEqual(EmailSubject, EventSubscriberInvoicingApp.GetEmailSubject, '');

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,SubjectChangeEmailDialogModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestEstimateEmailSubjectChangedOnCancelSendEmail()
    var
        EmailSubject: Text;
        EstimateNo: Code[20];
    begin
        // [Scenario] User modified email subject but did not send email (Estimate)
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] User clicks send estimate, modifies subject and cancels sending
        CancelEmail := true;
        EmailSubject := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(EmailSubject);
        EstimateNo := LibraryInvoicingApp.CreateEstimate;
        SendEstimate(EstimateNo);

        // [WHEN] User sends the estimate
        CancelEmail := false;
        ModifyEmailParameter := false;
        SendEstimate(EstimateNo);

        // [THEN] The sent email has the modfied subject
        Assert.AreEqual(EmailSubject, EventSubscriberInvoicingApp.GetEmailSubject, '');
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,MessageHandler,ConfirmHandlerYes,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDefaultEstimateSubjectReplacedByDraftInvoiceSubject()
    var
        SalesHeader: Record "Sales Header";
        CompanyName: Text;
        EstimateNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [Scenario] Verify email subject of draft invoice after an estimate is sent
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] The company has a name
        CompanyName := SetCompanyName;

        // [GIVEN] An estimate
        EstimateNo := LibraryInvoicingApp.CreateEstimate;
        // [GIVEN] An estimate has been sent
        SendEstimate(EstimateNo);

        // [GIVEN] The Estimate has been transfered into a draft invoice
        SalesHeader.Get(SalesHeader."Document Type"::Quote, EstimateNo);
        InvoiceNo := CreateInvoiceFromEstimate(EstimateNo);

        // [WHEN] User sends the draft invoice
        SendInvoice(InvoiceNo);

        // [THEN] The subject of the draft invoice is "Invoice from <CompanyName>"
        Assert.AreEqual(StrSubstNo(InvoiceEmailSubjectTxt, CompanyName), EventSubscriberInvoicingApp.GetEmailSubject, '');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,MessageHandler,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDefaultEstimateSubjectReplacedBySentInvoiceSubject()
    var
        SalesHeader: Record "Sales Header";
        CompanyName: Text;
        EstimateNo: Code[20];
    begin
        // [Scenario] Verify email subject of sent invoice after an estimate is sent
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] The company has a name
        CompanyName := SetCompanyName;

        // [GIVEN] An estimate
        EstimateNo := LibraryInvoicingApp.CreateEstimate;
        // [GIVEN] An estimate has been sent
        SendEstimate(EstimateNo);

        // [WHEN] The Estimate is sent as a normal invoice
        SalesHeader.Get(SalesHeader."Document Type"::Quote, EstimateNo);
        SendInvoiceFromEstimate(EstimateNo);

        // [THEN] The subject of the draft invoice is "Invoice from <CompanyName>"
        Assert.AreEqual(StrSubstNo(InvoiceEmailSubjectTxt, CompanyName), EventSubscriberInvoicingApp.GetEmailSubject, '');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('SubjectChangeEmailDialogModalPageHandler,MessageHandler,ConfirmHandlerYes,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestModifiedEstimateSubjectReplacedByDraftInvoiceSubject()
    var
        SalesHeader: Record "Sales Header";
        CompanyName: Text;
        EmailSubject: Text;
        EstimateNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [Scenario] Verify email subject of draft invoice after an estimate is sent with modified subject
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] The company has a name
        CompanyName := SetCompanyName;

        // [GIVEN] An estimate
        EstimateNo := LibraryInvoicingApp.CreateEstimate;
        // [GIVEN] The estimate has been sent with modified email subject
        EmailSubject := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(EmailSubject);
        SendEstimate(EstimateNo);

        // [GIVEN] The estimate is turned into a draft invoice
        SalesHeader.Get(SalesHeader."Document Type"::Quote, EstimateNo);
        InvoiceNo := CreateInvoiceFromEstimate(EstimateNo);

        // [WHEN] The draft invoice is sent
        ModifyEmailParameter := false;
        SendInvoice(InvoiceNo);

        // [THEN] The subject of the draft invoice is "Invoice from <CompanyName>"
        Assert.AreEqual(StrSubstNo(InvoiceEmailSubjectTxt, CompanyName), EventSubscriberInvoicingApp.GetEmailSubject, '');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('SubjectChangeEmailDialogModalPageHandler,MessageHandler,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestModifiedEstimateSubjectReplacedBySentInvoiceSubject()
    var
        SalesHeader: Record "Sales Header";
        CompanyName: Text;
        EmailSubject: Text;
        EstimateNo: Code[20];
    begin
        // [Scenario] Verify email subject of sent invoice after an estimate is sent with modified subject
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] The company has a name
        CompanyName := SetCompanyName;

        // [GIVEN] An estimate
        EstimateNo := LibraryInvoicingApp.CreateEstimate;
        // [GIVEN] The estimate has been sent with modified email subject
        EmailSubject := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(EmailSubject);
        SendEstimate(EstimateNo);

        // [WHEN] The Estimate is sent as a normal invoice
        ModifyEmailParameter := false;
        SalesHeader.Get(SalesHeader."Document Type"::Quote, EstimateNo);
        SendInvoiceFromEstimate(EstimateNo);

        // [THEN] The subject of the draft invoice is "Invoice from <CompanyName>"
        Assert.AreEqual(StrSubstNo(InvoiceEmailSubjectTxt, CompanyName), EventSubscriberInvoicingApp.GetEmailSubject, '');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,AddressChangeEmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestDraftInvoiceModifiedEmailAddressOnSendEmail()
    var
        EmailAddress: Text;
    begin
        // [Scenario] User modified email address (draft invoice)
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] A draft invoice has been sent with a modified email address
        EmailAddress := GenerateEmailAddress;
        LibraryVariableStorage.Enqueue(EmailAddress);
        SendInvoice(LibraryInvoicingApp.CreateInvoice);

        // [THEN] The sent email has the modified address
        Assert.AreEqual(EmailAddress, EventSubscriberInvoicingApp.GetEmailAddress, '');
    end;

    [Test]
    [HandlerFunctions('AddressChangeEmailDialogModalPageHandler,MessageHandler,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestSentInvoiceModifiedEmailAddressOnSendEmail()
    var
        PostedInvoiceNo: Code[20];
        EmailAddress: Text;
    begin
        // [Scenario] User modified email address (sent invoice)
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] Sent invoice
        EmailAddress := GenerateEmailAddress;
        LibraryVariableStorage.Enqueue(EmailAddress);
        PostedInvoiceNo := SendInvoice(LibraryInvoicingApp.CreateInvoice);

        // [WHEN] The sent invoice has been sent with a modified email address
        EmailAddress := GenerateEmailAddress;
        LibraryVariableStorage.Enqueue(EmailAddress);
        ReSendInvoice(PostedInvoiceNo);

        // [THEN] The sent email has the modified address
        Assert.AreEqual(EmailAddress, EventSubscriberInvoicingApp.GetEmailAddress, '');

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,AddressChangeEmailDialogModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestEstimateModifiedEmailAddressOnSendEmail()
    var
        EmailAddress: Text;
    begin
        // [Scenario] User modified email address (Estimate)
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [WHEN] An estimate has been sent with a modified email address
        EmailAddress := GenerateEmailAddress;
        LibraryVariableStorage.Enqueue(EmailAddress);
        SendEstimate(LibraryInvoicingApp.CreateEstimate);

        // [THEN] The sent email has the modified address
        Assert.AreEqual(EmailAddress, EventSubscriberInvoicingApp.GetEmailAddress, '');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,AddressChangeEmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestDraftInvoiceEmailAddressChangedOnCancelSendEmail()
    var
        EmailAddress: Text;
        InvoiceNo: Code[20];
    begin
        // [Scenario] User modified email address but did not send email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] User clicks send invoice, modifies address and cancels sending
        CancelEmail := true;
        EmailAddress := GenerateEmailAddress;
        LibraryVariableStorage.Enqueue(EmailAddress);
        InvoiceNo := LibraryInvoicingApp.CreateInvoice;
        SendInvoice(InvoiceNo);

        // [WHEN] User send the invoice
        CancelEmail := false;
        ModifyEmailParameter := false;
        SendInvoice(InvoiceNo);

        // [THEN] The sent email has the modified address
        Assert.AreEqual(EmailAddress, EventSubscriberInvoicingApp.GetEmailAddress, '');
    end;

    [Test]
    [HandlerFunctions('AddressChangeEmailDialogModalPageHandler,MessageHandler,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestSentInvoiceEmailAddressChangedOnCancelSendEmail()
    var
        PostedInvoiceNo: Code[20];
        EmailAddress: Text;
    begin
        // [Scenario] User modified email address of sent invoice but did not send email
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] Sent invoice
        EmailAddress := GenerateEmailAddress;
        LibraryVariableStorage.Enqueue(EmailAddress);
        PostedInvoiceNo := SendInvoice(LibraryInvoicingApp.CreateInvoice);

        // [GIVEN] User clicks send invoice, modifies address and cancels sending
        CancelEmail := true;
        EmailAddress := GenerateEmailAddress;
        LibraryVariableStorage.Enqueue(EmailAddress);
        ReSendInvoice(PostedInvoiceNo);

        // [WHEN] User resends the invoice
        CancelEmail := false;
        ModifyEmailParameter := false;
        ReSendInvoice(PostedInvoiceNo);

        // [THEN] The sent email has the modified address
        Assert.AreEqual(EmailAddress, EventSubscriberInvoicingApp.GetEmailAddress, '');

        RecallPostedInvoiceNotification(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,AddressChangeEmailDialogModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestEstimateEmailAddressChangedOnCancelSendEmail()
    var
        EmailAddress: Text;
        EstimateNo: Code[20];
    begin
        // [Scenario] User modified email address but did not send email (Estimate)
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] User clicks send estimate, modifies addresss and cancels sending
        CancelEmail := true;
        EmailAddress := GenerateEmailAddress;
        LibraryVariableStorage.Enqueue(EmailAddress);
        EstimateNo := LibraryInvoicingApp.CreateEstimate;
        SendEstimate(EstimateNo);

        // [WHEN] User sends the estimate
        CancelEmail := false;
        ModifyEmailParameter := false;
        SendEstimate(EstimateNo);

        // [THEN] The sent email has the modified address
        Assert.AreEqual(EmailAddress, EventSubscriberInvoicingApp.GetEmailAddress, '');
    end;

    [Test]
    [HandlerFunctions('AddressChangeEmailDialogModalPageHandler,MessageHandler,ConfirmHandlerYes,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestModifiedEstimateEmailAddressReplacedByDraftInvoiceAddress()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        EmailAddress: Text;
        EstimateNo: Code[20];
        DraftInvoiceNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [Scenario] Verify email address of draft invoice after an estimate is sent with modified address
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] An estimate
        EstimateNo := LibraryInvoicingApp.CreateEstimate;

        // [GIVEN] The estimate has been sent with modified email address
        EmailAddress := GenerateEmailAddress;
        LibraryVariableStorage.Enqueue(EmailAddress);
        SendEstimate(EstimateNo);

        // [GIVEN] The estimate is turned into a draft invoice
        SalesHeader.Get(SalesHeader."Document Type"::Quote, EstimateNo);
        DraftInvoiceNo := CreateInvoiceFromEstimate(EstimateNo);

        // [WHEN] The draft invoice is sent
        ModifyEmailParameter := false;
        PostedInvoiceNo := SendInvoice(DraftInvoiceNo);

        // [THEN] The email address of the draft invoice is the customer email address
        SalesInvoiceHeader.Get(PostedInvoiceNo);
        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
        Assert.AreEqual(Customer."E-Mail", EventSubscriberInvoicingApp.GetEmailAddress, '');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('AddressChangeEmailDialogModalPageHandler,MessageHandler,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestModifiedEstimateEmailAddressReplacedBySentInvoiceAddress()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        EmailAddress: Text;
        EstimateNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [Scenario] Verify email address of sent invoice after an estimate is sent with modified address
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] An estimate
        EstimateNo := LibraryInvoicingApp.CreateEstimate;

        // [GIVEN] The estimate has been sent with modified email address
        EmailAddress := GenerateEmailAddress;
        LibraryVariableStorage.Enqueue(EmailAddress);
        SendEstimate(EstimateNo);

        // [WHEN] The Estimate is sent as a normal invoice
        ModifyEmailParameter := false;
        SalesHeader.Get(SalesHeader."Document Type"::Quote, EstimateNo);
        PostedInvoiceNo := SendInvoiceFromEstimate(EstimateNo);

        // [THEN] The email address of the draft invoice is the customer email address
        SalesInvoiceHeader.Get(PostedInvoiceNo);
        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
        Assert.AreEqual(Customer."E-Mail", EventSubscriberInvoicingApp.GetEmailAddress, '');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,BCO365TestSalesInvoicePageHandler,TestInvoiceEmailDialogModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSendTestInvoiceEmail()
    var
        O365SalesTestInvoiceTest: TestPage "O365 Sales Test Invoice Page";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] Create new test invoice
        O365SalesTestInvoiceTest.OpenEdit;
        O365SalesTestInvoiceTest."Create Test Invoice".Invoke;

        // [WHEN] User adds customer name and item and clicks on send test email
        OpenInvoice(BCO365SalesInvoice);
        Assert.AreNotEqual(0, StrPos(BCO365SalesInvoice.Caption, 'Test'), 'Caption should contain Test invoice');

        LibraryVariableStorage.Enqueue(TestInvoiceSendingMsg);

        // [THEN] User should see right subject and email body
        BCO365SalesInvoice.SendTest.Invoke;

        // [THEN] Recipient should be correct
        Assert.AreEqual(
          MailManagement.GetSenderEmailAddress,
          EventSubscriberInvoicingApp.GetEmailAddress, 'To Email address should be sender address');
    end;

    local procedure GenerateEmailAddress(): Text
    begin
        exit(StrSubstNo('%1@home.local', CopyStr(CreateGuid, 2, 8)));
    end;

    local procedure Initialize()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        O365DocumentSentHistory: Record "O365 Document Sent History";
    begin
        BindActiveDirectoryMockEvents;
        LibraryInvoicingApp.SetupEmail;
        EventSubscriberInvoicingApp.Clear;
        LibraryVariableStorage.AssertEmpty;
        Clear(CancelEmail);
        O365DocumentSentHistory.DeleteAll;
        ModifyEmailParameter := true;

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify;

        if IsInitialized then
            exit;

        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        IsInitialized := true;
    end;

    local procedure CreateInvoiceFromEstimate(EstimateNo: Code[20]): Code[20]
    begin
        LibraryVariableStorage.Enqueue(ConfirmConvertToInvoiceQst);
        exit(LibraryInvoicingApp.CreateInvoiceFromEstimate(EstimateNo));
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

    local procedure SendInvoice(InvoiceNo: Code[20]) PostedInvoiceNo: Code[20]
    begin
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoice(InvoiceNo);
    end;

    local procedure ReSendInvoice(PostedInvoiceNo: Code[20])
    begin
        if not CancelEmail then
            LibraryVariableStorage.Enqueue(InvoiceSentMsg);
        LibraryInvoicingApp.ReSendInvoice(PostedInvoiceNo);
    end;

    local procedure SendEstimate(EstimateNo: Code[20])
    begin
        if not CancelEmail then
            LibraryVariableStorage.Enqueue(EstimateSentMsg);
        LibraryInvoicingApp.SendEstimate(EstimateNo);
    end;

    local procedure SendInvoiceFromEstimate(EstimateNo: Code[20]): Code[20]
    var
        PostedInvoiceNo: Code[20];
    begin
        if not CancelEmail then
            LibraryVariableStorage.Enqueue(InvoiceSentMsg);
        PostedInvoiceNo := LibraryInvoicingApp.SendInvoiceFromEstimate(EstimateNo);
        exit(PostedInvoiceNo);
    end;

    local procedure SetCompanyName(): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get;
        CompanyInformation.Validate(Name, LibraryUtility.GenerateGUID);
        CompanyInformation.Modify(true);
        exit(CompanyInformation.Name);
    end;

    local procedure RecallPostedInvoiceNotification(InvoiceNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(InvoiceNo);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesInvoiceHeader);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        O365SalesEmailDialog.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SubjectChangeEmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        if ModifyEmailParameter then
            O365SalesEmailDialog.Subject.Value(LibraryVariableStorage.DequeueText);
        if CancelEmail then
            O365SalesEmailDialog.Cancel.Invoke
        else
            O365SalesEmailDialog.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AddressChangeEmailDialogModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    begin
        if ModifyEmailParameter then
            O365SalesEmailDialog.SendToText.Value(LibraryVariableStorage.DequeueText);
        if CancelEmail then
            O365SalesEmailDialog.Cancel.Invoke
        else
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

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    var
        ExpectedQuestion: Text;
    begin
        ExpectedQuestion := LibraryVariableStorage.DequeueText;
        Assert.AreEqual(ExpectedQuestion, Question, '');
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
    procedure SentNotificationHandler(var TheNotification: Notification): Boolean
    begin
        Assert.AreNotEqual(
          0,
          StrPos(TheNotification.Message, EmailFailedNotifPrefixTxt) +
          StrPos(TheNotification.Message, EmailFailedGenericMsg) +
          StrPos(TheNotification.Message, TaxSetupNeededTxt),
          'An unexpected notification was sent.'
          );
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
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
}

