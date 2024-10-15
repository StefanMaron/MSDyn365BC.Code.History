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
        LibraryService: Codeunit "Library - Service";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;
        IsMailManagementOnBeforeIsEnabledActive: Boolean;
        MailingJobCategoryCodeTok: Label 'SENDINV', Comment = 'Must be max. 10 chars and no spacing. (Send Invoice)';
        CannotSendEmailErr: Label 'You cannot send the email.\Verify that the email settings are correct.', Locked = true;
        JobQueueEntryParameterString: Label '%1|%2|%3|%4|%5|%6|%7', Comment = '%1 - ReportUsage, %2 - DocNo, %3 - DocName, %4 - CustNo, %5 - DocumentNo FieldNo';
        KeepDraftOrDiscardPageQst: Label 'The email has not been sent.';
        PeppolFormatNameTxt: Label 'PEPPOL', Locked = true;
        ModalCount: Integer;

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
    [HandlerFunctions('ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestEmailFileWithBodyStreamAndPostedDocNo()
    var
        TempEmailItem: Record "Email Item" temporary;
        TempBlob: Codeunit "Temp Blob";
        DocumentMailing: Codeunit "Document-Mailing";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        FileManagement: Codeunit "File Management";
        RelatedRecord: RecordRef;
        SourceTables, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
        InStream: InStream;
        VariableVariant: Variant;
        Content: Text;
        Name: Text;
    begin
        // [SCENARIO] An email can be sent where the email body is given as a stream
        BindSubscription(DocumentMailingTests);
        Clear(LibraryVariableStorage);

        // [GIVEN] A Stream with some content
        InitializeStream('Some content', TempBlob);
        TempBlob.CreateInStream(InStream);

        // [AND] A Related record and a receiver record
        RelatedRecord.Open(Database::"Sales Invoice Header");
        RelatedRecord.FindLast();
        SourceTables.Add(Database::"Sales Invoice Header");
        SourceIDs.Add(RelatedRecord.Field(RelatedRecord.SystemIdNo).Value());
        SourceRelationTypes.Add(Enum::"Email Relation Type"::"Primary Source".AsInteger());

        // [WHEN] The EmailFile is called with an Instream as the body of the email
        Clear(DocumentMailing);
        DocumentMailing.EmailFile(Instream, 'new file.pdf', InStream, '', 'someone@somewhere.com', 'EmailDocName', true, -1, SourceTables, SourceIDs, SourceRelationTypes);

        // [THEN] A temp file with the content is created
        DocumentMailingTests.GetLibraryVariableStorage(LibraryVariableStorage);
        LibraryVariableStorage.Dequeue(VariableVariant);
        TempEmailItem := VariableVariant;
        Content := LibraryVariableStorage.DequeueText();
        Name := LibraryVariableStorage.DequeueText();
        Assert.AreEqual('new file.pdf', Name, 'Attachment Name was expected to be new file.pdf');

        // [THEN] A Body File exists
        Assert.IsTrue(FileManagement.ServerFileExists(TempEmailItem."Body File Path"), 'Body file does not exist.');

        // [And] The other values are set correctly
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'IsFromPostedDoc was expected to be false');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'PostedDocNo was expected to be empty');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'HideDialog was expected to be true');
        Assert.AreEqual(-1, LibraryVariableStorage.DequeueInteger(), 'ReportUsage was expected to be -1');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestEmailFileWithBodyStream()
    var
        TempEmailItem: Record "Email Item" temporary;
        TempBlob: Codeunit "Temp Blob";
        DocumentMailing: Codeunit "Document-Mailing";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        FileManagement: Codeunit "File Management";
        RelatedRecord: RecordRef;
        SourceTables, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
        InStream: InStream;
        VariableVariant: Variant;
        Content: Text;
        Name: Text;
    begin
        // [SCENARIO] An email can be sent where the email body is given as a stream
        BindSubscription(DocumentMailingTests);
        Clear(LibraryVariableStorage);

        // [GIVEN] A Stream with some content
        InitializeStream('Some content', TempBlob);
        TempBlob.CreateInStream(InStream);

        // [AND] A Related record and a receiver record
        RelatedRecord.Open(Database::"Sales Invoice Header");
        RelatedRecord.FindLast();
        SourceTables.Add(Database::"Sales Invoice Header");
        SourceIDs.Add(RelatedRecord.Field(RelatedRecord.SystemIdNo).Value());
        SourceRelationTypes.Add(Enum::"Email Relation Type"::"Primary Source".AsInteger());

        // [WHEN] The EmailFile is called with an Instream as the body of the email
        Clear(DocumentMailing);
        DocumentMailing.EmailFile(InStream, 'new file.pdf', InStream, 'subject', 'someone@somewhere.com', true, Enum::"Email Scenario"::Default, SourceTables, SourceIDs, SourceRelationTypes);

        // [THEN] A temp file with the content is created
        DocumentMailingTests.GetLibraryVariableStorage(LibraryVariableStorage);
        LibraryVariableStorage.Dequeue(VariableVariant);
        TempEmailItem := VariableVariant;
        Content := LibraryVariableStorage.DequeueText();
        Name := LibraryVariableStorage.DequeueText();
        Assert.AreEqual('new file.pdf', Name, 'Attachment Name was expected to be new file.pdf');

        // [THEN] A Body File exists
        Assert.IsTrue(FileManagement.ServerFileExists(TempEmailItem."Body File Path"), 'Body file does not exist.');

        // [And] The other values are set correctly
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'IsFromPostedDoc was expected to be false');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'PostedDocNo was expected to be empty');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'HideDialog was expected to be true');
        Assert.AreEqual(-1, LibraryVariableStorage.DequeueInteger(), 'ReportUsage was expected to be -1');
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
        Assert.AreEqual(CannotSendEmailErr, GetLastErrorText(), 'Error was expected.');

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
    procedure ShouldSendToCustDirectlyUTWhenDocumentLayoutHasEmail()
    var
        Customer: Record Customer;
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        PostedInvoiceNo: Code[20];
        SendEmailManually: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 421871] Run ShouldSendToCustDirectly() procedure of Report Selections table on Posted Sales Invoice when Customer's email is blank and email from Document Layout is not blank.
        Initialize();

        // [GIVEN] Customer with blank Email. Document Layout with Usage "Invoice" and Email "abc@abc.com" for this Customer.
        LibrarySales.CreateCustomer(Customer);
        UpdateEmailOnCustomer(Customer, '');
        LibrarySales.CreateCustomerDocumentLayout(
            Customer."No.", "Report Selection Usage"::"S.Invoice", Report::"Standard Sales - Invoice", '', LibraryUtility.GenerateRandomEmail());

        // [GIVEN] Posted Sales Invoice for this Customer.
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(PostedInvoiceNo);

        // [WHEN] Run ShouldSendToCustDirectly() procedure of Report Selections table on Posted Sales Invoice.
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(true);
        BindSubscription(DocumentMailingTests);
        SendEmailManually := ReportSelections.ShouldSendToCustDirectly("Report Selection Usage"::"S.Invoice", SalesInvoiceHeader, SalesInvoiceHeader."Sell-to Customer No.");
        UnbindSubscription(DocumentMailingTests);

        // [THEN] ShouldSendToCustDirectly() procedure returned false, because email address returned by GetEmailAddress() was not blank.
        Assert.IsFalse(SendEmailManually, 'ShouldSendToCustDirectly() must return false');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler')]
    procedure SendPurchaseOrderWhenDocumentLayoutHasEmailAndEmailUseDefaultSettings()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobQueueEntry: Record "Job Queue Entry";
        DocumentSendingProfile: Record "Document Sending Profile";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
    begin
        // [SCENARIO 421871] Send Purchase Order when Vendor's email is blank, email from Document Layout is not blank and Document Sending Profile has E-Mail = "Yes (Use Default Settings)".
        Initialize();
        JobQueueEntry.SetRange("Job Queue Category Code", MailingJobCategoryCodeTok);
        JobQueueEntry.DeleteAll();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)".
        SetupDefaultEmailSendingProfile(DocumentSendingProfile);

        // [GIVEN] Vendor with blank Email. Document Layout with Usage "P.Order" and Email "abc@abc.com" for this Vendor.
        LibraryPurchase.CreateVendor(Vendor);
        UpdateEmailOnVendor(Vendor, '');
        LibraryPurchase.CreateVendorDocumentLayout(
            Vendor."No.", "Report Selection Usage"::"P.Order", Report::"Standard Purchase - Order", '', LibraryUtility.GenerateRandomEmail());

        // [GIVEN] Purchase Order for this Vendor.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemNo(), 100, 10);

        // [WHEN] Send Purchase Order.
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(true);
        BindSubscription(DocumentMailingTests);
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.SendRecords();
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(false);
        UnbindSubscription(DocumentMailingTests);

        // [THEN] Email Editor page is not shown and email is sent silently using Job Queue Entry.
        VerifyMailingJobQueueEntryPurchaseOrder(PurchaseHeader, "Report Selection Usage"::"P.Order");
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,EmailEditorCheckAndDiscardModalPageHandler,ConfirmHandlerTrue,KeepDraftOrDiscardStrMenuHandler')]
    procedure SendPurchaseOrderWhenBlankEmailInDocumentLayoutAndEmailUseDefaultSettings()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentSendingProfile: Record "Document Sending Profile";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        ConnectorMock: Codeunit "Connector Mock";
    begin
        // [SCENARIO 421871] Send Purchase Order when Vendor's email and email from Document Layout are blank and Document Sending Profile has E-Mail = "Yes (Use Default Settings)".
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();
        ConnectorMock.FailOnSend(true);

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)".
        SetupDefaultEmailSendingProfile(DocumentSendingProfile);

        // [GIVEN] Vendor with blank Email. Document Layout with Usage "P.Order" and with blank Email for this Vendor.
        LibraryPurchase.CreateVendor(Vendor);
        UpdateEmailOnVendor(Vendor, '');
        LibraryPurchase.CreateVendorDocumentLayout(
            Vendor."No.", "Report Selection Usage"::"P.Order", Report::"Standard Purchase - Order", '', '');

        // [GIVEN] Purchase Order "103032" for this Vendor.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemNo(), 100, 10);

        // [WHEN] Send Purchase Order.
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(true);
        BindSubscription(DocumentMailingTests);
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.SendRecords();
        DocumentMailingTests.SetMailManagementOnBeforeIsEnabledActive(false);
        UnbindSubscription(DocumentMailingTests);

        // [THEN] Email Editor page is shown, it has Subject "Cronus - Purchase Order 103032" and blank To field (recipient).
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'Recipient must be blank');
        Assert.ExpectedMessage(PurchaseHeader."No.", LibraryVariableStorage.DequeueText()); // subject must contain Purchase Order No.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler')]
    procedure SendPostedServiceCreditMemoInBackgroundConfirmDefaultProfileUsingDefaultSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Service Credit Memo when Select sending options = "ConfirmDefault" Document Sending Profile using default settings, E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, false);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendPostedServiceCreditMemo(true, 2, 4, 2, 2);

        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendPostedServiceCreditMemoInForegroundConfirmDefaultProfileUsingPromptForSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Service Credit Memo when Select sending options = "ConfirmDefault" Document Sending Profile using prompt for settings, E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, false);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendPostedServiceCreditMemo(false, 2, 4, 2, 2);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler')]
    procedure SendPostedServiceCreditMemoInBackgroundConfirmDefaultProfileUsingDefaultSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Service Credit Memo when Select sending options = "ConfirmDefault" Document Sending Profile using default settings, E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, true);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendPostedServiceCreditMemo(true, 3, 2, 2, 1);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendPostedServiceCreditMemoInForegroundConfirmDefaultProfileUsingPromptForSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Service Credit Memo when Select sending options = "ConfirmDefault" Document Sending Profile using prompt for settings, E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, true);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendPostedServiceCreditMemo(false, 3, 2, 2, 1);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler')]
    procedure SendPostedServiceCreditMemoInBackgroundUseDefaultProfileUsingDefaultSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Service Credit Memo when Select sending options = "UseDefaultProfile" Document Sending Profile using default settings, E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, false);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendPostedServiceCreditMemo(true, 2, 4, 2, 2);

        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendPostedServiceCreditMemoInForegroundUseDefaultProfileUsingPromptForSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Service Credit Memo when Select sending options = "UseDefaultProfile" Document Sending Profile using prompt for settings, E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, false);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendPostedServiceCreditMemo(false, 2, 4, 2, 2);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler')]
    procedure SendPostedServiceCreditMemoInBackgroundUseDefaultProfileUsingDefaultSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Service Credit Memo when Select sending options = "UseDefaultProfile" Document Sending Profile using default settings, E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, true);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendPostedServiceCreditMemo(true, 3, 2, 2, 1);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendPostedServiceCreditMemoInForegroundUseDefaultProfileUsingPromptForSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Service Credit Memo when Select sending options = "UseDefaultProfile" Document Sending Profile using prompt for settings, E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, true);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendPostedServiceCreditMemo(false, 3, 2, 2, 1);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    local procedure SendPostedServiceCreditMemo(RunJQ: Boolean; InvoicesCount: Integer; JQCount: Integer; CustomersCount: Integer; EmailCount: Integer)
    var
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustomerNo: Text;
        CustomerNos, CustomerEmails : List of [Text];
        Count: Integer;
        StrBuilder: TextBuilder;
    begin
        // [GIVEN] Customers with email
        for Count := 1 to CustomersCount do begin
            CreateCustomerWithEmail(Customer);
            CustomerNos.Add(Customer."No.");
            CustomerEmails.Add(Customer."E-Mail");
        end;

        // [GIVEN] Posted Service Credit Memos for above customers
        for Count := 1 to CustomersCount do begin
            CustomerNos.Get(Count, CustomerNo);
            Customer.Get(CustomerNo);
            CreateMultipleServiceDocumentForCustomer(Customer, Enum::"Service Document Type"::"Credit Memo", InvoicesCount);
            StrBuilder.Append(CustomerNo + '|');
        end;
        ServiceCrMemoHeader.SetFilter("Bill-to Customer No.", StrBuilder.ToText().TrimEnd('|'));
        ServiceCrMemoHeader.FindSet();
        Assert.RecordCount(ServiceCrMemoHeader, InvoicesCount * CustomersCount);

        // [WHEN] Send Posted Service Credit Memos
        ServiceCrMemoHeader.SendRecords();

        if RunJQ then begin
            // [THEN] "Document-Mailing" JQs will be created
            JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Document-Mailing");
            Assert.IsTrue(JobQueueEntry.FindSet(), 'No job queue entry for document-mailing found');
            Assert.RecordCount(JobQueueEntry, JQCount);

            // [WHEN] The "Document-Mailing" JQ will run and send the email
            repeat
                Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);
            until JobQueueEntry.Next() = 0;
        end;

        ValidateAfterSending(CustomerEmails, JQCount, EmailCount);
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler')]
    procedure SendPurchaseOrderInBackgroundConfirmDefaultProfileUsingDefaultSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Order when Select sending options = "ConfirmDefault" Document Sending Profile using default settings, E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, false);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendPurchaseOrder(true, 2, 4, 2, 2);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendPurchaseOrderInForegroundConfirmDefaultProfileUsingPromptForSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Order when Select sending options = "ConfirmDefault" Document Sending Profile using prompt for settings, E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, false);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendPurchaseOrder(false, 2, 4, 2, 2);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler')]
    procedure SendPurchaseOrderInBackgroundConfirmDefaultProfileUsingDefaultSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Order when Select sending options = "ConfirmDefault" Document Sending Profile using default settings, E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, true);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendPurchaseOrder(true, 3, 2, 2, 1);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendPurchaseOrderInForegroundConfirmDefaultProfileUsingPromptForSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Order when Select sending options = "ConfirmDefault" Document Sending Profile using prompt for settings, E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, true);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendPurchaseOrder(false, 3, 2, 2, 1);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler')]
    procedure SendPurchaseOrderInBackgroundUseDefaultProfileUsingDefaultSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Order when Select sending options = "UseDefaultProfile" Document Sending Profile using default settings, E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, false);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendPurchaseOrder(true, 2, 4, 2, 2);

        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendPurchaseOrderInForegroundUseDefaultProfileUsingPromptForSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Order when Select sending options = "UseDefaultProfile" Document Sending Profile using prompt for settings, E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, false);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendPurchaseOrder(false, 2, 4, 2, 2);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler')]
    procedure SendPurchaseOrderInBackgroundUseDefaultProfileUsingDefaultSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Order when Select sending options = "UseDefaultProfile" Document Sending Profile using default settings, E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, true);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendPurchaseOrder(true, 3, 2, 2, 1);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendPurchaseOrderInForegroundUseDefaultProfileUsingPromptForSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Order when Select sending options = "UseDefaultProfile" Document Sending Profile using prompt for settings, E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, true);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendPurchaseOrder(false, 3, 2, 2, 1);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    local procedure SendPurchaseOrder(RunJQ: Boolean; InvoicesCount: Integer; JQCount: Integer; VendorCount: Integer; EmailCount: Integer)
    var
        Vendor: Record Vendor;
        JobQueueEntry: Record "Job Queue Entry";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Text;
        VendorNos, VendorEmails : List of [Text];
        Count: Integer;
        StrBuilder: TextBuilder;
    begin
        // [GIVEN] Vendors with email
        for Count := 1 to VendorCount do begin
            CreateVendorWithEmail(Vendor);
            VendorNos.Add(Vendor."No.");
            VendorEmails.Add(Vendor."E-Mail");
        end;

        // [GIVEN] Purchase Quotes for above Vendors
        for Count := 1 to VendorCount do begin
            VendorNos.Get(Count, VendorNo);
            Vendor.Get(VendorNo);
            CreateMultiplePurchaseOrderForVendor(Vendor, InvoicesCount);
            StrBuilder.Append(VendorNo + '|');
        end;
        PurchaseHeader.SetFilter("Buy-from Vendor No.", StrBuilder.ToText().TrimEnd('|'));
        PurchaseHeader.FindSet();
        Assert.RecordCount(PurchaseHeader, InvoicesCount * VendorCount);

        // [WHEN] Send Purchase Orders
        PurchaseHeader.SendRecords();

        if RunJQ then begin
            // [THEN] "Document-Mailing" JQs will be created
            JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Document-Mailing");
            Assert.IsTrue(JobQueueEntry.FindSet(), 'No job queue entry for document-mailing found');
            Assert.RecordCount(JobQueueEntry, JQCount);

            // [WHEN] The "Document-Mailing" JQ will run and send the email
            repeat
                Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);
            until JobQueueEntry.Next() = 0;
        end;

        ValidateAfterSending(VendorEmails, JQCount, EmailCount);
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler')]
    procedure SendPurchaseQuoteInBackgroundConfirmDefaultProfileUsingDefaultSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Quote when Select sending options = "ConfirmDefault" Document Sending Profile using default settings, E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, false);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendPurchaseQuote(true, 2, 4, 2, 2);

        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendPurchaseQuoteInForegroundConfirmDefaultProfileUsingPromptForSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Quote when Select sending options = "ConfirmDefault" Document Sending Profile using prompt for settings, E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, false);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendPurchaseQuote(false, 2, 4, 2, 2);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler')]
    procedure SendPurchaseQuoteInBackgroundConfirmDefaultProfileUsingDefaultSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Quote when Select sending options = "ConfirmDefault" Document Sending Profile using default settings, E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, true);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendPurchaseQuote(true, 3, 2, 2, 1);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendPurchaseQuoteInForegroundConfirmDefaultProfileUsingPromptForSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Quote when Select sending options = "ConfirmDefault" Document Sending Profile using prompt for settings, E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, true);

        // [GIVEN] Selecting sending options uses the confirm the profile option
        LibraryVariableStorage.Enqueue(1); // ConfirmDefault

        SendPurchaseQuote(false, 3, 2, 2, 1);
        Assert.AreEqual(1, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler')]
    procedure SendPurchaseQuoteInBackgroundUseDefaultProfileUsingDefaultSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Quote when Select sending options = "UseDefaultProfile" Document Sending Profile using default settings, E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, false);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendPurchaseQuote(true, 2, 4, 2, 2);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendPurchaseQuoteInForegroundUseDefaultProfileUsingPromptForSettingsAndPdfAndNotCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Quote when Select sending options = "UseDefaultProfile" Document Sending Profile using prompt for settings, E-Mail Attachment = "PDF" and Combine Email Documents = false.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is not set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, false);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendPurchaseQuote(false, 2, 4, 2, 2);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler')]
    procedure SendPurchaseQuoteInBackgroundUseDefaultProfileUsingDefaultSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Quote when Select sending options = "UseDefaultProfile" Document Sending Profile using default settings, E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, true);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendPurchaseQuote(true, 3, 2, 2, 1);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsStrMenuHandler,EmailEditorSendModalPageHandler')]
    procedure SendPurchaseQuoteInForegroundUseDefaultProfileUsingPromptForSettingsAndPdfAndCombineEmails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [SCENARIO] Send Posted Purchase Quote when Select sending options = "UseDefaultProfile" Document Sending Profile using prompt for settings, E-Mail Attachment = "PDF" and Combine Email Documents = true.
        Initialize();
        LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] Default Document Sending Profile with E-Mail = "Yes (Prompt for settings)", E-Mail Attachment = "PDF", E-Mail Format = PEPPOL; Combine Email Documents is set.
        SetupDefaultEmailSendingProfile(
            DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)", "Document Sending Profile Attachment Type"::PDF, PeppolFormatNameTxt, true);

        // [GIVEN] Selecting sending options uses the default profile option
        LibraryVariableStorage.Enqueue(3); // UseDefaultProfile

        SendPurchaseQuote(false, 3, 2, 2, 1);
        Assert.AreEqual(0, ModalCount, 'SelectSendingOptions modal did not open the correct number of times');
    end;

    local procedure SendPurchaseQuote(RunJQ: Boolean; InvoicesCount: Integer; JQCount: Integer; VendorCount: Integer; EmailCount: Integer)
    var
        Vendor: Record Vendor;
        JobQueueEntry: Record "Job Queue Entry";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Text;
        VendorNos, VendorEmails : List of [Text];
        Count: Integer;
        StrBuilder: TextBuilder;
    begin
        // [GIVEN] Vendors with email
        for Count := 1 to VendorCount do begin
            CreateVendorWithEmail(Vendor);
            VendorNos.Add(Vendor."No.");
            VendorEmails.Add(Vendor."E-Mail");
        end;

        // [GIVEN] Purchase Quotes for above Vendors
        for Count := 1 to VendorCount do begin
            VendorNos.Get(Count, VendorNo);
            Vendor.Get(VendorNo);
            CreateMultiplePurchaseQuoteForVendor(Vendor, InvoicesCount);
            StrBuilder.Append(VendorNo + '|');
        end;
        PurchaseHeader.SetFilter("Buy-from Vendor No.", StrBuilder.ToText().TrimEnd('|'));
        PurchaseHeader.FindSet();
        Assert.RecordCount(PurchaseHeader, InvoicesCount * VendorCount);

        // [WHEN] Send created Purchase Quotes
        PurchaseHeader.SendRecords();

        if RunJQ then begin
            // [THEN] "Document-Mailing" JQs will be created
            JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Document-Mailing");
            Assert.IsTrue(JobQueueEntry.FindSet(), 'No job queue entry for document-mailing found');
            Assert.RecordCount(JobQueueEntry, JQCount);

            // [WHEN] The "Document-Mailing" JQ will run and send the email
            repeat
                Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);
            until JobQueueEntry.Next() = 0;
        end;

        ValidateAfterSending(VendorEmails, JQCount, EmailCount);
    end;

    local procedure ValidateOnlyOneToRecipientAndGetRecipient(var EmailMessage: Codeunit "Email Message"): Text
    var
        Recipients: List of [Text];
        Recipient: Text;
    begin
        // Validate "Cc" recipients
        EmailMessage.GetRecipients(Enum::"Email Recipient Type"::"Cc", Recipients);
        Assert.AreEqual(0, Recipients.Count(), 'Email was sent to a Cc recipient');

        // Validate "Bcc" recipients
        EmailMessage.GetRecipients(Enum::"Email Recipient Type"::"Bcc", Recipients);
        Assert.AreEqual(0, Recipients.Count(), 'Email was sent to a Bcc recipient');

        // Validate "To" recipients
        EmailMessage.GetRecipients(Enum::"Email Recipient Type"::"To", Recipients);

        Assert.AreEqual(1, Recipients.Count(), 'More than one recipient');
        Recipients.Get(1, Recipient);
        exit(Recipient);
    end;

    local procedure ValidateAfterSending(Emails: List of [Text]; TotalEmailCount: Integer; PerEntityEmailCount: Integer)
    var
        EmailOutbox: Record "Email Outbox";
        SentEmail: Record "Sent Email";
        EmailMessage: Codeunit "Email Message";
        RecipientsCount: Dictionary of [Text, Integer];
        Email: Text;
        Count: Integer;
    begin
        // [THEN] One email should have been sent to the above created customer
        Assert.RecordCount(EmailOutbox, 0);
        Assert.RecordCount(SentEmail, TotalEmailCount);

        // [THEN] Email sent is only sent to customer
        SentEmail.FindSet();
        repeat
            EmailMessage.Get(SentEmail.GetMessageId());
            Email := ValidateOnlyOneToRecipientAndGetRecipient(EmailMessage);
            if not RecipientsCount.Get(Email, Count) then
                Count := 0;
            RecipientsCount.Set(Email, Count + 1);

            // [THEN] Email only has one attachment and is pdf
            ValidateEmailAttachmentsOnlyPdf(EmailMessage, 1);
        until SentEmail.Next() = 0;

        foreach Email in RecipientsCount.Keys() do begin
            Assert.IsTrue(Emails.Contains(Email), 'Email was sent to someone unexpected');
            Assert.AreEqual(PerEntityEmailCount, RecipientsCount.Get(Email), 'The number of emails sent to recipient do not match');
        end;
    end;

    local procedure ValidateEmailAttachmentsOnlyPdf(var EmailMessage: Codeunit "Email Message"; Count: Integer)
    var
        AttachmentCount: Integer;
    begin
        Assert.IsTrue(EmailMessage.Attachments_First(), 'No email attachments');
        repeat
            AttachmentCount += 1;
            Assert.IsSubstring(EmailMessage.Attachments_GetName(), '.pdf');
        until EmailMessage.Attachments_Next() = 0;
        Assert.AreEqual(AttachmentCount, Count, 'More than one email attachment found');
    end;

    local procedure CreateCustomerWithEmail(var Customer: Record Customer) Email: Text[80]
    begin
        Email := LibraryUtility.GenerateRandomEmail();

        LibrarySales.CreateCustomerWithAddress(Customer);
        Customer."E-Mail" := Email;
        Customer.Modify();
    end;

    local procedure CreateVendorWithEmail(var Vendor: Record Vendor) Email: Text[80]
    begin
        Email := LibraryUtility.GenerateRandomEmail();

        LibraryPurchase.CreateVendorWithAddress(Vendor);
        Vendor."E-Mail" := Email;
        Vendor.Modify();
    end;

    local procedure CreateMultipleSalesInvoicesForCustomer(Customer: Record Customer; InvoicesCount: Integer)
    var
        SalesHeader: Record "Sales Header";
        No: Integer;
    begin
        for No := 1 to InvoicesCount do begin
            LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
            SetYourReferenceToSalesHeader(SalesHeader);
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end;
    end;

    local procedure CreateMultipleSalesCreditMemoForCustomer(Customer: Record Customer; CreditMemoCount: Integer)
    var
        SalesHeader: Record "Sales Header";
        No: Integer;
    begin
        for No := 1 to CreditMemoCount do begin
            LibrarySales.CreateSalesCreditMemoForCustomerNo(SalesHeader, Customer."No.");
            SetYourReferenceToSalesHeader(SalesHeader);
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end;
    end;

    local procedure CreateMultipleServiceDocumentForCustomer(Customer: Record Customer; ServiceDocumentType: Enum "Service Document Type"; TotalCount: Integer)
    var
        ServiceHeader: Record "Service Header";
        No: Integer;
    begin
        for No := 1 to TotalCount do begin
            LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, ServiceDocumentType, Customer."No.");
            LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        end;
    end;

    local procedure CreateMultiplePurchaseOrderForVendor(Vendor: Record Vendor; CreditMemoCount: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        No: Integer;
    begin
        for No := 1 to CreditMemoCount do
            LibraryPurchase.CreatePurchaseOrderForVendorNo(PurchaseHeader, Vendor."No.");
    end;

    local procedure CreateMultiplePurchaseQuoteForVendor(Vendor: Record Vendor; CreditMemoCount: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        No: Integer;
    begin
        for No := 1 to CreditMemoCount do
            LibraryPurchase.CreatePurchaseQuoteForVendor(PurchaseHeader, Vendor."No.");
    end;

    local procedure Initialize()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        EmailOutbox: Record "Email Outbox";
        SentEmail: Record "Sent Email";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Document Mailing Tests");
        LibraryVariableStorage.Clear();

        DocumentSendingProfile.DeleteAll();
        EmailOutbox.DeleteAll();
        SentEmail.DeleteAll();
        JobQueueEntry.DeleteAll();

        ModalCount := 0;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Document Mailing Tests");

        SetAllowBlankPaymentInfo();
        SetupBankInfoOnCompany();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Document Mailing Tests");
    end;

    procedure GetLibraryVariableStorage(var LibraryVariableStorageResult: Codeunit "Library - Variable Storage")
    begin
        LibraryVariableStorageResult := LibraryVariableStorage;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnBeforeSendEmail', '', false, false)]
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mail Management", 'OnBeforeIsEnabled', '', false, false)]
    local procedure SetEmailingEnabledOnBeforeIsEnabled(OutlookSupported: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
        if not IsMailManagementOnBeforeIsEnabledActive then
            exit;

        OutlookSupported := false;
        Result := true;
        IsHandled := true;
    end;

    procedure SetMailManagementOnBeforeIsEnabledActive(IsActive: Boolean)
    begin
        IsMailManagementOnBeforeIsEnabledActive := IsActive;
    end;

    local procedure InitializeStream(Content: Text; var TempBlob: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(Content);
    end;

    local procedure InsertPeppolElectronicFormat()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CountryRegion: Record "Country/Region";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        ElectronicDocumentFormat.DeleteAll();
        ElectronicDocumentFormat.InsertElectronicFormat(
            PeppolFormatNameTxt, PeppolFormatNameTxt, Codeunit::"Exp. Sales Inv. PEPPOL BIS3.0", 0,
            ElectronicDocumentFormat.Usage::"Sales Invoice".AsInteger());

        CountryRegion.SetRange("VAT Scheme", '');
        CountryRegion.ModifyAll("VAT Scheme", CountryRegion.Code);

        VATPostingSetup.SetRange("Tax Category", '');
        VATPostingSetup.ModifyAll("Tax Category", 'AA');
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
            Default := true;
            Insert();
        end;
    end;

    local procedure SetupDefaultEmailSendingProfile(EmailType: Option; EmailAttachment: Enum "Document Sending Profile Attachment Type"; EmailFormatCode: Code[20]; CombineEmails: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        DocumentSendingProfile.DeleteAll();

        DocumentSendingProfile.Init();
        DocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile.Printer := DocumentSendingProfile.Printer::No;
        DocumentSendingProfile."E-Mail" := EmailType;
        DocumentSendingProfile."E-Mail Attachment" := EmailAttachment;
        DocumentSendingProfile."E-Mail Format" := EmailFormatCode;
        DocumentSendingProfile."Combine Email Documents" := CombineEmails;
        DocumentSendingProfile.Disk := DocumentSendingProfile.Disk::No;
        DocumentSendingProfile."Electronic Document" := DocumentSendingProfile."Electronic Document"::No;
        DocumentSendingProfile.Default := true;
        DocumentSendingProfile.Insert();
    end;

    local procedure SetAllowBlankPaymentInfo()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Allow Blank Payment Info." := true;
        CompanyInformation.Modify();
    end;

    local procedure SetVatRegistrationNoToCustomer(var Customer: Record Customer)
    begin
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(Customer."Country/Region Code");
        Customer.Modify(true);
    end;

    local procedure SetYourReferenceToSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Your Reference", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);
    end;

    local procedure SetupBankInfoOnCompany()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInfo.Validate(Name, LibraryUtility.GenerateGUID());
        CompanyInfo.Validate(IBAN, 'GB29NWBK60161331926819');
        CompanyInfo.Validate("SWIFT Code", 'MIDLGB22Z0K');
        CompanyInfo.Validate("Bank Branch No.", '1234');
        CompanyInfo.Validate(GLN, '1234567890128');
        CompanyInfo.Modify(true);
    end;

    local procedure UpdateEmailOnCustomer(var Customer: Record Customer; EmailAddress: Text[80])
    begin
        Customer.Validate("E-Mail", EmailAddress);
        Customer.Modify(true);
    end;

    local procedure UpdateEmailOnVendor(var Vendor: Record Vendor; EmailAddress: Text[80])
    begin
        Vendor.Validate("E-Mail", EmailAddress);
        Vendor.Modify(true);
    end;

    local procedure VerifyValues()
    begin
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'IsFromPostedDoc was expected to be false');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'PostedDocNo was expected to be empty');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'HideDialog was expected to be true');
        Assert.AreEqual(0, LibraryVariableStorage.DequeueInteger(), 'ReportUsage was expected to be 0');
    end;

    local procedure VerifyMailingJobQueueEntrySalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"; ReportSelectionUsage: Enum "Report Selection Usage")
    var
        JobQueueEntry: Record "Job Queue Entry";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        ParameterString: Text;
        DocName: Text[150];
    begin
        DocName := ReportDistributionManagement.GetFullDocumentTypeText(SalesInvoiceHeader);
        ParameterString := StrSubstNo(JobQueueEntryParameterString, ReportSelectionUsage.AsInteger(), SalesInvoiceHeader."No.", DocName, SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader.FieldNo("No."), '', '');
        JobQueueEntry.SetRange("Record ID to Process", SalesInvoiceHeader.RecordId());
        JobQueueEntry.FindFirst();

        JobQueueEntry.TestField("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.TestField("Object ID to Run", Codeunit::"Document-Mailing");
        JobQueueEntry.TestField("Job Queue Category Code", MailingJobCategoryCodeTok);
        JobQueueEntry.TestField("Parameter String", ParameterString);
    end;

    local procedure VerifyMailingJobQueueEntryPurchaseOrder(PurchaseHeader: Record "Purchase Header"; ReportSelectionUsage: Enum "Report Selection Usage")
    var
        JobQueueEntry: Record "Job Queue Entry";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        ParameterString: Text;
        DocName: Text[150];
    begin
        DocName := ReportDistributionMgt.GetFullDocumentTypeText(PurchaseHeader);
        ParameterString := StrSubstNo(JobQueueEntryParameterString, ReportSelectionUsage.AsInteger(), PurchaseHeader."No.", DocName, PurchaseHeader."Buy-from Vendor No.", PurchaseHeader.FieldNo("No."), '', 'Vendor');
        JobQueueEntry.SetRange("Record ID to Process", PurchaseHeader.RecordId());
        JobQueueEntry.FindFirst();

        JobQueueEntry.TestField("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.TestField("Object ID to Run", Codeunit::"Document-Mailing");
        JobQueueEntry.TestField("Job Queue Category Code", MailingJobCategoryCodeTok);
        JobQueueEntry.TestField("Parameter String", ParameterString);
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

    [ModalPageHandler]
    procedure SelectSendingOptionsOKModalPageHandler(var SelectSendingOptions: TestPage "Select Sending Options")
    begin
        SelectSendingOptions.OK().Invoke();
        ModalCount += 1;
    end;

    [ModalPageHandler]
    procedure EmailEditorCheckAndDiscardModalPageHandler(var EmailEditor: TestPage "Email Editor")
    begin
        LibraryVariableStorage.Enqueue(EmailEditor.ToField.Value);
        LibraryVariableStorage.Enqueue(EmailEditor.SubjectField.Value);
        EmailEditor.Discard.Invoke();
    end;

    [ModalPageHandler]
    procedure EmailEditorCheckAttachmentNameModalPageHandler(var EmailEditor: TestPage "Email Editor")
    begin
        LibraryVariableStorage.Enqueue(EmailEditor.Attachments.FileName.Value);
        EmailEditor.Discard.Invoke();
    end;

    [StrMenuHandler]
    procedure KeepDraftOrDiscardStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Assert.AreEqual(KeepDraftOrDiscardPageQst, Instruction, '');
        Choice := 2;    // discard email
    end;

    [ModalPageHandler]
    procedure EmailEditorSendModalPageHandler(var EmailEditor: TestPage "Email Editor")
    begin
        EmailEditor.Send.Invoke();
    end;
}

