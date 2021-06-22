codeunit 135060 "Document Mailing Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Email] [Stream] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        MailingJobCategoryCodeTok: Label 'SENDINV', Comment = 'Must be max. 10 chars and no spacing. (Send Invoice)';
        CannotSendEmailErr: Label 'You cannot send the email.\Verify that the email settings are correct.', Locked = true;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestEmailFileFromStream()
    var
        TempEmailItem: Record "Email Item" temporary;
        TempBlob: Codeunit "Temp Blob";
        DocumentMailing: Codeunit "Document-Mailing";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        InStream: InStream;
        VariableVariant: Variant;
        Content: Text;
        Name: Text;
    begin
        // [SCENARIO] A File can be attached to an email using a Stream
        BindSubscription(DocumentMailingTests);
        Clear(LibraryVariableStorage);

        // [GIVEN] A Stream with some content
        InitializeStream('Some content', TempBlob);
        TempBlob.CreateInStream(InStream);

        // [WHEN] The function EmailFileFromStream is called
        Clear(DocumentMailing);
        DocumentMailing.EmailFileFromStream(InStream, 'new file.pdf', 'a nice body', 'a nice subject', 'someone@somewhere.com', true, 0);

        // [THEN] A temp file with the stream content is created
        DocumentMailingTests.GetLibraryVariableStorage(LibraryVariableStorage);
        LibraryVariableStorage.Dequeue(VariableVariant);
        TempEmailItem := VariableVariant;
        Content := LibraryVariableStorage.DequeueText();
        Name := LibraryVariableStorage.DequeueText();
        Assert.AreEqual('Some content', Content, 'Content was expected to be Some content');
        Assert.AreEqual('new file.pdf', Name, 'Attachment Name was expected to be new file.pdf');

        // [THEN] The email items fields have been filled correctly
        Assert.AreEqual('a nice body', TempEmailItem.GetBodyText(), 'Body was expected to be a nice body');
        Assert.AreEqual('a nice subject', TempEmailItem.Subject, 'Subject was expected to be a nice subject');
        Assert.AreEqual('someone@somewhere.com', TempEmailItem."Send to", 'Send to was expected to be someone@somewhere.com');

        // [THEN] The right values are set
        VerifyValues();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestEmailHtmlFromStream()
    var
        TempEmailItem: Record "Email Item" temporary;
        TempBlob: Codeunit "Temp Blob";
        DocumentMailing: Codeunit "Document-Mailing";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        InStream: InStream;
        VariableVariant: Variant;
        Content: Text;
        Name: Text;
    begin
        // [SCENARIO] A HTML File can be attached to an email using a Stream
        BindSubscription(DocumentMailingTests);

        // [GIVEN] A Stream with some content
        InitializeStream('Some content', TempBlob);
        TempBlob.CreateInStream(InStream);

        // [WHEN] The function EmailFileFromStream is called
        Clear(DocumentMailing);
        asserterror DocumentMailing.EmailHtmlFromStream(InStream, 'someone@somewhere.com', 'a nice subject', true, 0);
        Assert.AreEqual(GetLastErrorText, CannotSendEmailErr, 'Error was expected.');

        // [THEN] A temp file with the stream content is created
        DocumentMailingTests.GetLibraryVariableStorage(LibraryVariableStorage);
        LibraryVariableStorage.Dequeue(VariableVariant);
        TempEmailItem := VariableVariant;
        Content := LibraryVariableStorage.DequeueText();
        Name := LibraryVariableStorage.DequeueText();

        // [THEN] The email items fields have been filled correctly
        Assert.AreEqual('someone@somewhere.com', TempEmailItem."Send to", 'Send to was expected to be someone@somewhere.com');
        Assert.AreEqual('a nice subject', TempEmailItem.Subject, 'Subject was expected to be a nice subject');

        // [THEN] The right values are set
        VerifyValues();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler')]
    [Scope('OnPrem')]
    procedure DocumentSendingProfile_MultiInvoices_Email_BackgroundSMTPSetup() // To be removed together with deprecated SMTP objects
    var
        LibraryEmailFeature: Codeunit "Library - Email Feature";
    begin
        LibraryEmailFeature.SetEmailFeatureEnabled(false);
        DocumentSendingProfile_MultiInvoices_Email_Background_Internal();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler')]
    [Scope('OnPrem')]
    procedure DocumentSendingProfile_MultiInvoices_Email_Background()
    var
        LibraryEmailFeature: Codeunit "Library - Email Feature";
    begin
        LibraryEmailFeature.SetEmailFeatureEnabled(true);
        DocumentSendingProfile_MultiInvoices_Email_Background_Internal();
    end;

    procedure DocumentSendingProfile_MultiInvoices_Email_Background_Internal()
    var
        Customer: array[2] of Record Customer;
        SalesHeader: array[2, 2] of Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        TestClientTypeMgtSubscriber: Codeunit "Test Client Type Subscriber";
        LibrarySMTPMailHandler: Codeunit "Library - SMTP Mail Handler";
        LibraryWorkflow: Codeunit "Library - Workflow";
        ConnectorMock: Codeunit "Connector Mock";
        EmailFeature: Codeunit "Email Feature";
        IndexCustomer: Integer;
        IndexSalesInvoice: Integer;
    begin
        // [SCENARIO 340331] Job Queue sending posted sales invoices by email must log errors happened in SMTP mail codeunit
        Initialize();
        SetupDefaultEmailSendingProfile(DocumentSendingProfile);
        JobQueueEntry.SetRange("Job Queue Category Code", MailingJobCategoryCodeTok);
        JobQueueEntry.DeleteAll();

        for IndexCustomer := 1 to ArrayLen(Customer) do begin
            LibrarySales.CreateCustomer(Customer[IndexCustomer]);
            Customer[IndexCustomer].Validate("Document Sending Profile", DocumentSendingProfile.Code);
            Customer[IndexCustomer].Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
            Customer[IndexCustomer].Modify(true);

            for IndexSalesInvoice := 1 to ArrayLen(SalesHeader[IndexCustomer]) do begin
                LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[IndexCustomer] [IndexSalesInvoice], Customer[IndexCustomer]."No.");
                LibrarySales.PostSalesDocument(SalesHeader[IndexCustomer] [IndexSalesInvoice], true, true);
            end;
        end;

        LibraryVariableStorage.Enqueue(3); // Use Default Document Sending Profile
        SalesInvoiceHeader.SetFilter("Sell-to Customer No.", StrSubstNo('%1|%2', Customer[1]."No.", Customer[2]."No."));
        SalesInvoiceHeader.FindSet();

        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);
        if EmailFeature.IsEnabled() then begin
            LibraryWorkflow.SetUpEmailAccount();
            ConnectorMock.FailOnSend(true);
        end;
        SalesInvoiceHeader.SendRecords();

        TestClientTypeMgtSubscriber.SetClientType(CLIENTTYPE::Background);
        BindSubscription(TestClientTypeMgtSubscriber);

        if not EmailFeature.IsEnabled() then begin
            LibrarySMTPMailHandler.SetSenderAddress(LibraryUtility.GenerateRandomEmail());
            LibrarySMTPMailHandler.SetSenderName(LibraryUtility.GenerateGUID());
            BindSubscription(LibrarySMTPMailHandler);
        end;

        Assert.RecordCount(JobQueueEntry, ArrayLen(SalesHeader));
        JobQueueEntry.FindSet();
        repeat
            CODEUNIT.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);
            Assert.IsFalse(IsNullGuid(JobQueueEntry."Error Message Register Id"), 'Email error must be registered');
        until JobQueueEntry.Next() = 0;

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Document Mailing Tests");
        LibraryVariableStorage.Clear();
        InitializeSmtpSetup();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Document Mailing Tests");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Document Mailing Tests");
    end;

    procedure GetLibraryVariableStorage(var LibraryVariableStorageResult: Codeunit "Library - Variable Storage")
    begin
        LibraryVariableStorageResult := LibraryVariableStorage;
    end;

    [EventSubscriber(ObjectType::Codeunit, 260, 'OnBeforeSendEmail', '', false, false)]
    local procedure OnBeforeSendEmail(var TempEmailItem: Record "Email Item" temporary; IsFromPostedDoc: Boolean; PostedDocNo: Code[20]; HideDialog: Boolean; ReportUsage: Integer)
    var
        Attachments: Codeunit "Temp Blob List";
        Attachment: Codeunit "Temp Blob";
        AttachemntNames: List of [Text];
        InStream: InStream;
        AttachmentContent: Text;
        AttachmentName: Text;
    begin
        LibraryVariableStorage.Enqueue(TempEmailItem);
        TempEmailItem.GetAttachments(Attachments, AttachemntNames);
        if Attachments.Count() > 0 then begin
            AttachmentName := AttachemntNames.Get(1);
            Attachments.Get(1, Attachment);
            Attachment.CreateInStream(InStream);
            InStream.Read(AttachmentContent);
        end;
        LibraryVariableStorage.Enqueue(AttachmentContent);
        LibraryVariableStorage.Enqueue(AttachmentName);
        LibraryVariableStorage.Enqueue(IsFromPostedDoc);
        LibraryVariableStorage.Enqueue(PostedDocNo);
        LibraryVariableStorage.Enqueue(HideDialog);
        LibraryVariableStorage.Enqueue(ReportUsage);
    end;

    local procedure InitializeStream(Content: Text; var TempBlob: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(Content);
    end;

    local procedure InitializeSmtpSetup()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
    begin
        SMTPMailSetup.DeleteAll();

        SMTPMailSetup.Init();
        SMTPMailSetup."SMTP Server" := LibraryUtility.GenerateGUID();
        SMTPMailSetup."SMTP Server Port" := 25;
        SMTPMailSetup.Insert();
    end;

    local procedure SetupDefaultEmailSendingProfile(var DocumentSendingProfile: Record "Document Sending Profile")
    begin
        with DocumentSendingProfile do begin
            DeleteAll();

            Init();
            Code := LibraryUtility.GenerateGUID();
            "E-Mail" := "E-Mail"::"Yes (Use Default Settings)";
            Printer := Printer::No;
            Disk := Disk::No;
            "Electronic Document" := "Electronic Document"::No;
            Insert();
        end;
    end;

    local procedure VerifyValues()
    begin
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'IsFromPostedDoc was expected to be false');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'PostedDocNo was expected to be empty');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'HideDialog was expected to be true');
        Assert.AreEqual(0, LibraryVariableStorage.DequeueInteger(), 'ReportUsage was expected to be 0');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SelectSendingOptionsStrMenuHandler(MenuOptions: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;
}

