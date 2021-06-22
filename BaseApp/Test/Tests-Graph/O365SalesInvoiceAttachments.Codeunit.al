codeunit 138914 "O365 Sales Invoice Attachments"
{
    // The order of taking picture and importing file matters, as a new incoming document has to be created by the first attachment.

    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Picture] [Attachment] [UI]
    end;

    var
        Assert: Codeunit Assert;
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
        LibraryUtility: Codeunit "Library - Utility";
        AttachmentsTxt: Label 'Attachments (%1)';
        AddAttachmentTxt: Label 'Add attachment';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        ContactUsFullTxt: Label 'Questions? Contact us at %1 or %2.', Comment = '%1 = phone number, %2 = email';
        ContactUsShortTxt: Label 'Questions? Contact us at %1.', Comment = '%1 = phone number or email';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInvoicingApp: Codeunit "Library - Invoicing App";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        EventSubscriberInvoicingApp: Codeunit "EventSubscriber Invoicing App";
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        IsInitialized: Boolean;
        SecretNameTxt: Label 'MailerResourceId';
        EmailSizeAboveMaxErr: Label 'The total size of the attachments exceeds the maximum limit (3 MB). Remove some to be able to send your document.', Comment = '%1=the total size allowed for all the attachments, e.g. "25 MB"';

    [Scope('OnPrem')]
    procedure TestAttachmentSizeWarningDraft()
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
    begin
        // [GIVEN] A new sales invoice is created with no attachments
        Initialize();
        SetupGraphEmail();
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, LibraryInvoicingApp.CreateInvoice);

        // [THEN]  No error or warning is created
        OpenAndCloseAttachmentListForDraft(SalesHeader);

        // [WHEN] Attachments are added and total size exceeds the threshold
        LibraryInvoicingApp.AddAttachmentToSalesHeader(SalesHeader, 1024 * 4);// >4 MB

        // [THEN] User gets a warning and cannot send the invoice
        LibraryVariableStorage.Enqueue(EmailSizeAboveMaxErr);
        OpenAndCloseAttachmentListForDraft(SalesHeader);
        BCO365SalesInvoice.OpenEdit();
        BCO365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, SalesHeader."No.");
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(EmailSizeAboveMaxErr);
        BCO365SalesInvoice.Post.Invoke(); // Platform treats errors thrown OnQueryClosePage as messages
        Assert.ExpectedError(EmailSizeAboveMaxErr);

        // [WHEN] The user removes an attachment
        RemoveAttachmentForSalesHeader(SalesHeader."Incoming Document Entry No.");

        // [THEN] No more warnings are thrown
        OpenAndCloseAttachmentListForDraft(SalesHeader);
        LibraryVariableStorage.Enqueue(true);
        BCO365SalesInvoice.Post.Invoke();
        LibraryVariableStorage.AssertEmpty();

        CleanupGraphEmail();
    end;

    [Test]
    [HandlerFunctions('EmailFailedNotificationHandler,EmailModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestAttachmentSizeWarningEstimate()
    var
        SalesHeader: Record "Sales Header";
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
    begin
        // [GIVEN] A new sales invoice is created with no attachments
        Initialize();
        LibraryLowerPermissions.SetInvoiceApp;
        SetupGraphEmail();
        SalesHeader.Get(SalesHeader."Document Type"::Quote, LibraryInvoicingApp.CreateEstimate);

        // [THEN]  No error or warning is created
        OpenAndCloseAttachmentListForEstimates(SalesHeader);

        // [WHEN] Attachments are added and total size exceeds the threshold
        LibraryInvoicingApp.AddAttachmentToSalesHeader(SalesHeader, 1024 * 4);// >2 MB

        // [THEN] User gets a warning and cannot send the estimate
        LibraryVariableStorage.Enqueue(EmailSizeAboveMaxErr);
        OpenAndCloseAttachmentListForEstimates(SalesHeader);
        BCO365SalesQuote.OpenEdit();
        BCO365SalesQuote.GotoKey(SalesHeader."Document Type"::Quote, SalesHeader."No.");
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(EmailSizeAboveMaxErr);
        BCO365SalesQuote.EmailQuote.Invoke(); // Platform treats errors thrown OnQueryClosePage as messages
        Assert.ExpectedError(EmailSizeAboveMaxErr);

        // [WHEN] The user removes an attachment
        RemoveAttachmentForSalesHeader(SalesHeader."Incoming Document Entry No.");

        // [THEN] No more warnings are thrown
        OpenAndCloseAttachmentListForEstimates(SalesHeader);
        LibraryVariableStorage.AssertEmpty();

        CleanupGraphEmail();
    end;

    [Scope('OnPrem')]
    procedure TestAttachmentSizeWarningPosted()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
    begin
        // [GIVEN] A new sales invoice is created with no attachments
        Initialize();
        SetupGraphEmail();
        LibraryVariableStorage.Enqueue(true);
        SalesInvoiceHeader.Get(LibraryInvoicingApp.SendInvoice(LibraryInvoicingApp.CreateInvoice));

        // [THEN]  No error or warning is created
        OpenAndCloseAttachmentListForPosted(SalesInvoiceHeader);

        // [WHEN] Attachments are added and total size exceeds the threshold
        LibraryInvoicingApp.AddAttachmentToPostedInvoice(SalesInvoiceHeader, 1024 * 4);// >2 MB

        // [THEN] User gets a warning
        LibraryVariableStorage.Enqueue(EmailSizeAboveMaxErr);
        OpenAndCloseAttachmentListForPosted(SalesInvoiceHeader);

        // [THEN] User cannot re-send the invoice
        BCO365PostedSalesInvoice.OpenEdit();
        BCO365PostedSalesInvoice.GotoKey(SalesInvoiceHeader."No.");
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(EmailSizeAboveMaxErr);
        BCO365PostedSalesInvoice.Send.Invoke(); // Platform treats errors thrown OnQueryClosePage as messages
        Assert.ExpectedError(EmailSizeAboveMaxErr);

        // [WHEN] The user removes an attachment
        RemoveAttachmentForPosted(SalesInvoiceHeader."No.", SalesInvoiceHeader."Posting Date");

        // [THEN] No more warnings are thrown
        OpenAndCloseAttachmentListForPosted(SalesInvoiceHeader);
        LibraryVariableStorage.AssertEmpty();

        CleanupGraphEmail();
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestImportThenPictureOnPostedInv()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        O365PostedSalesInvoiceTestPage: TestPage "O365 Posted Sales Invoice";
    begin
        // [GIVEN] A new sales invoice is created and posted
        Initialize();
        InitForPostedInvoice(O365PostedSalesInvoiceTestPage, SalesInvoiceHeader);

        // [WHEN] User imports file and page refreshes
        ImportFileAsAttachmentForPosted(SalesInvoiceHeader."No.", SalesInvoiceHeader."Posting Date");
        O365PostedSalesInvoiceTestPage.GotoRecord(SalesInvoiceHeader);
        // [THEN] Exactly one attachment is found
        Assert.AreEqual(
          StrSubstNo(AttachmentsTxt, 1), O365PostedSalesInvoiceTestPage.NoOfAttachments.Value,
          'Imported file not correctly handled as first attachment, or wrong label.');

        // [WHEN] User takes picture and page refreshes
        AddTakenPictureAsAttachmentForPosted(SalesInvoiceHeader."No.", SalesInvoiceHeader."Posting Date");
        O365PostedSalesInvoiceTestPage.GotoRecord(SalesInvoiceHeader);
        // [THEN] One more attachment is found
        Assert.AreEqual(
          StrSubstNo(AttachmentsTxt, 2), O365PostedSalesInvoiceTestPage.NoOfAttachments.Value,
          'Added picture not correctly handled as second attachment, or wrong label.');
        O365PostedSalesInvoiceTestPage.Close;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestPictureThenImportOnPostedInv()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        O365PostedSalesInvoiceTestPage: TestPage "O365 Posted Sales Invoice";
    begin
        // [GIVEN] A new sales invoice is created and posted
        Initialize();
        InitForPostedInvoice(O365PostedSalesInvoiceTestPage, SalesInvoiceHeader);

        // [WHEN] User takes picture and page refreshes
        AddTakenPictureAsAttachmentForPosted(SalesInvoiceHeader."No.", SalesInvoiceHeader."Posting Date");
        O365PostedSalesInvoiceTestPage.GotoRecord(SalesInvoiceHeader);
        // [THEN] Exactly one attachment is found
        Assert.AreEqual(
          StrSubstNo(AttachmentsTxt, 1), O365PostedSalesInvoiceTestPage.NoOfAttachments.Value,
          'Added picture not correctly handled as first attachment, or wrong label.');

        // [WHEN] User imports file and page refreshes
        ImportFileAsAttachmentForPosted(SalesInvoiceHeader."No.", SalesInvoiceHeader."Posting Date");
        O365PostedSalesInvoiceTestPage.GotoRecord(SalesInvoiceHeader);
        // [THEN] One more attachment is found
        Assert.AreEqual(
          StrSubstNo(AttachmentsTxt, 2), O365PostedSalesInvoiceTestPage.NoOfAttachments.Value,
          'Imported file not correctly handled as second attachment, or wrong label.');
        O365PostedSalesInvoiceTestPage.Close;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestImportThenPictureOnDraftInv()
    var
        SalesHeader: Record "Sales Header";
        O365SalesInvoiceTestPage: TestPage "O365 Sales Invoice";
        O365SalesDocAttachmentsTestPage: TestPage "O365 Sales Doc. Attachments";
    begin
        // [GIVEN] A new draft sales invoice is created
        Initialize();
        InitForDraftInvoice(O365SalesInvoiceTestPage, SalesHeader);

        // [WHEN] User imports file and page refreshes
        O365SalesDocAttachmentsTestPage.Trap; // call the page to perform some initialization
        O365SalesInvoiceTestPage.NoOfAttachments.DrillDown;
        O365SalesDocAttachmentsTestPage.Close;
        SalesHeader.FindFirst;
        ImportFileAsAttachmentForDraft(SalesHeader."Incoming Document Entry No.");
        O365SalesInvoiceTestPage.GotoRecord(SalesHeader);
        // [THEN] Exactly one attachment is found
        Assert.AreEqual(
          StrSubstNo(AttachmentsTxt, 1), O365SalesInvoiceTestPage.NoOfAttachments.Value,
          'Imported file not correctly handled as first attachment, or wrong label.');

        // [WHEN] User takes picture and page refreshes
        AddTakenPictureAsAttachmentForDraft(SalesHeader."Incoming Document Entry No.");
        SalesHeader.FindFirst;
        O365SalesInvoiceTestPage.GotoRecord(SalesHeader);
        // [THEN] One more attachment is found
        Assert.AreEqual(
          StrSubstNo(AttachmentsTxt, 2), O365SalesInvoiceTestPage.NoOfAttachments.Value,
          'Added picture not correctly handled as second attachment, or wrong label.');
        O365SalesInvoiceTestPage.Close;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestPictureThenImportOnDraftInv()
    var
        SalesHeader: Record "Sales Header";
        O365SalesInvoiceTestPage: TestPage "O365 Sales Invoice";
        O365SalesDocAttachmentsTestPage: TestPage "O365 Sales Doc. Attachments";
    begin
        // [GIVEN] A new sales invoice is created
        Initialize();
        InitForDraftInvoice(O365SalesInvoiceTestPage, SalesHeader);

        // [WHEN] User takes picture and page refreshes
        O365SalesDocAttachmentsTestPage.Trap; // call the page to perform some initialization
        O365SalesInvoiceTestPage.NoOfAttachments.DrillDown;
        O365SalesDocAttachmentsTestPage.Close;
        SalesHeader.FindFirst;
        AddTakenPictureAsAttachmentForDraft(SalesHeader."Incoming Document Entry No.");
        O365SalesInvoiceTestPage.GotoRecord(SalesHeader);
        // [THEN] Exactly one attachment is found
        Assert.AreEqual(
          StrSubstNo(AttachmentsTxt, 1), O365SalesInvoiceTestPage.NoOfAttachments.Value,
          'Added picture not correctly handled as first attachment, or wrong label.');

        // [WHEN] User imports file and page refreshes
        ImportFileAsAttachmentForDraft(SalesHeader."Incoming Document Entry No.");
        SalesHeader.FindFirst;
        O365SalesInvoiceTestPage.GotoRecord(SalesHeader);
        // [THEN] One more attachment is found
        Assert.AreEqual(
          StrSubstNo(AttachmentsTxt, 2), O365SalesInvoiceTestPage.NoOfAttachments.Value,
          'Imported file not correctly handled as second attachment, or wrong label.');
        O365SalesInvoiceTestPage.Close;
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure CompanyInfoGetContactUsTextFull()
    var
        CompanyInformation: Record "Company Information";
        ContactUsText: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 211222] CompanyInfo.GetContactUsText returns sentence with phone and email when both are filled in
        Initialize();

        // [GIVEN] Company information Phone No. = PPP
        CompanyInformation."Phone No." :=
          LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("Phone No."), DATABASE::"Company Information");
        // [GIVEN] Company information E-Mail = EEE
        CompanyInformation."E-Mail" :=
          LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("E-Mail"), DATABASE::"Company Information");
        CompanyInformation.Modify();

        // [WHEN] Funciton CompanyInformation.GetContactUsText is being run
        ContactUsText := CompanyInformation.GetContactUsText;

        // [THEN] Result = 'Qustions? Contact us at PPP or EEE'
        VerifyContactUsText(
          StrSubstNo(ContactUsFullTxt, CompanyInformation."Phone No.", CompanyInformation."E-Mail"),
          ContactUsText);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure CompanyInfoGetContactUsTextPhoneOnly()
    var
        CompanyInformation: Record "Company Information";
        ContactUsText: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 211222] CompanyInfo.GetContactUsText returns sentence with phone when it is filled in and email is empty
        Initialize();

        // [GIVEN] Company information Phone No. = PPP
        CompanyInformation."Phone No." :=
          LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("Phone No."), DATABASE::"Company Information");
        // [GIVEN] Company information E-Mail is empty
        CompanyInformation."E-Mail" := '';
        CompanyInformation.Modify();

        // [WHEN] Funciton CompanyInformation.GetContactUsText is being run
        ContactUsText := CompanyInformation.GetContactUsText;

        // [THEN] Result = 'Qustions? Contact us at PPP'
        VerifyContactUsText(
          StrSubstNo(ContactUsShortTxt, CompanyInformation."Phone No."),
          ContactUsText);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure CompanyInfoGetContactUsTextEmailOnly()
    var
        CompanyInformation: Record "Company Information";
        ContactUsText: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 211222] CompanyInfo.GetContactUsText returns sentence with email when it is filled in and phone is empty
        Initialize();

        // [GIVEN] Company information Phone No. is empty
        CompanyInformation."Phone No." := '';
        // [GIVEN] Company information E-Mail = EEE
        CompanyInformation."E-Mail" :=
          LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("E-Mail"), DATABASE::"Company Information");
        CompanyInformation.Modify();

        // [WHEN] Funciton CompanyInformation.GetContactUsText is being run
        ContactUsText := CompanyInformation.GetContactUsText;

        // [THEN] Result = 'Qustions? Contact us at EEE'
        VerifyContactUsText(
          StrSubstNo(ContactUsShortTxt, CompanyInformation."E-Mail"),
          ContactUsText);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure CompanyInfoGetContactUsTextEmpty()
    var
        CompanyInformation: Record "Company Information";
        ContactUsText: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 211222] CompanyInfo.GetContactUsText returns empty value when both phone and email are empty
        Initialize();

        // [GIVEN] Company information Phone No. is empty
        CompanyInformation."Phone No." := '';
        // [GIVEN] Company information E-Mail is empty
        CompanyInformation."E-Mail" := '';
        CompanyInformation.Modify();

        // [WHEN] Funciton CompanyInformation.GetContactUsText is being run
        ContactUsText := CompanyInformation.GetContactUsText;

        // [THEN] Result is empty value
        VerifyContactUsText('', ContactUsText);
    end;

    local procedure Initialize()
    var
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        TaxDetail: Record "Tax Detail";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"O365 Sales Invoice Attachments");

        EventSubscriberInvoicingApp.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"Company Information");

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify();

        EventSubscriberInvoicingApp.SetRunJobQueueTasks(false);
        EventSubscriberInvoicingApp.SetAppId('INV');
        BindSubscription(EventSubscriberInvoicingApp);

        TaxDetail.ModifyAll("Tax Below Maximum", 5); // Avoid tax setup notification in US
    end;

    local procedure CreateAndPostNewInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, 10);
        LibrarySmallBusiness.PostSalesInvoice(SalesHeader);

        SalesInvoiceHeader.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure MakeEmptyFile(FileNameIn: Text) FileNameOut: Text
    var
        File: File;
    begin
        if not File.Create(FileNameIn) then
            Assert.Fail('Unable to create file.');

        FileNameOut := FileNameIn;
    end;

    local procedure CreateNewDraftInvoice(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, 10);

        SalesHeader.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure ImportFileAsAttachmentForDraft(IncomingDocumentNo: Integer)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileMgt: Codeunit "File Management";
        SystemIOFile: DotNet File;
        FileName: Text;
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocumentNo);
        IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment."Incoming Document Entry No." := IncomingDocumentNo;

        FileName := FileMgt.ServerTempFileName('.jpg');

        SystemIOFile.WriteAllText(FileName, '.jpg');

        ImportAttachmentIncDoc.ImportAttachment(IncomingDocumentAttachment, FileName);
        IncomingDocumentAttachment.Name := LibraryUtility.GenerateGUID;

        IncomingDocumentAttachment.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure AddTakenPictureAsAttachmentForDraft(IncomingDocumentNo: Integer)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileMgt: Codeunit "File Management";
        SystemIOFile: DotNet File;
        FileName: Text;
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocumentNo);

        FileName := FileMgt.ServerTempFileName('.jpg');

        SystemIOFile.WriteAllText(FileName, '.jpg');

        ImportAttachmentIncDoc.ProcessAndUploadPicture(FileName, IncomingDocumentAttachment);
    end;

    [Scope('OnPrem')]
    procedure ImportFileAsAttachmentForPosted(DocumentNo: Code[20]; PostingDate: Date)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileMgt: Codeunit "File Management";
        SystemIOFile: DotNet File;
        FileName: Text;
    begin
        IncomingDocumentAttachment.SetRange("Document No.", DocumentNo);
        IncomingDocumentAttachment.SetRange("Posting Date", PostingDate);
        IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment."Document No." := DocumentNo;
        IncomingDocumentAttachment."Posting Date" := PostingDate;

        FileName := FileMgt.ServerTempFileName('.jpg');

        SystemIOFile.WriteAllText(FileName, '.jpg');

        ImportAttachmentIncDoc.ImportAttachment(IncomingDocumentAttachment, FileName);
        IncomingDocumentAttachment.Name := LibraryUtility.GenerateGUID;

        IncomingDocumentAttachment.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure AddTakenPictureAsAttachmentForPosted(DocumentNo: Code[20]; PostingDate: Date)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileMgt: Codeunit "File Management";
        SystemIOFile: DotNet File;
        FileName: Text;
    begin
        IncomingDocumentAttachment.SetRange("Document No.", DocumentNo);
        IncomingDocumentAttachment.SetRange("Posting Date", PostingDate);

        FileName := FileMgt.ServerTempFileName('.jpg');

        SystemIOFile.WriteAllText(FileName, '.jpg');

        ImportAttachmentIncDoc.ProcessAndUploadPicture(FileName, IncomingDocumentAttachment);
    end;

    local procedure InitForDraftInvoice(var O365SalesInvoiceTestPage: TestPage "O365 Sales Invoice"; var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.DeleteAll();
        CreateNewDraftInvoice(SalesHeader);
        O365SalesInvoiceTestPage.OpenEdit();
        O365SalesInvoiceTestPage.GotoRecord(SalesHeader);

        // No default attachments to the invoice
        Assert.AreEqual(
          AddAttachmentTxt, O365SalesInvoiceTestPage.NoOfAttachments.Value, 'At least one attachment in new draft invoice, or wrong label.');
    end;

    local procedure InitForPostedInvoice(var O365PostedSalesInvoiceTestPage: TestPage "O365 Posted Sales Invoice"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader.DeleteAll();
        CreateAndPostNewInvoice(SalesInvoiceHeader);
        O365PostedSalesInvoiceTestPage.OpenEdit();
        O365PostedSalesInvoiceTestPage.GotoRecord(SalesInvoiceHeader);

        // No default attachments to the invoice
        Assert.AreEqual(
          AddAttachmentTxt, O365PostedSalesInvoiceTestPage.NoOfAttachments.Value,
          'At least one attachment in new posted invoice, or wrong label.');
    end;

    local procedure VerifyContactUsText(ExpectedContactUsText: Text; ActualContactUsText: Text)
    begin
        Assert.AreEqual(ExpectedContactUsText, ActualContactUsText, 'Invalid ContactUsText');
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure EmailFailedNotificationHandler(var TheNotification: Notification): Boolean
    begin
        Assert.IsTrue(
          StrPos(TheNotification.Message, 'The last email about this document could not be sent.') > 0,
          StrSubstNo('Unexpected notification: %1', TheNotification.Message));
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
    procedure EmailModalPageHandler(var O365SalesEmailDialog: TestPage "O365 Sales Email Dialog")
    var
        SendMail: Boolean;
    begin
        SendMail := LibraryVariableStorage.DequeueBoolean;

        if not SendMail then begin
            O365SalesEmailDialog.Cancel.Invoke();
            exit;
        end;

        O365SalesEmailDialog.SendToText.SetValue('test@microsoft.com');
        O365SalesEmailDialog.OK.Invoke();
    end;

    local procedure SetupGraphEmail()
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
        GraphMailSetup: Record "Graph Mail Setup";
        MockAzureKeyVaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        TestSecret: Text;
    begin
        if AzureADMgtSetup.Delete then;
        if GraphMailSetup.Delete then;

        MockAzureKeyVaultSecretProvider := MockAzureKeyVaultSecretProvider.MockAzureKeyVaultSecretProvider;
        MockAzureKeyVaultSecretProvider.AddSecretMapping('AllowedApplicationSecrets',
          StrSubstNo('%1,%2', SecretNameTxt, 'SmtpSetup'));
        MockAzureKeyVaultSecretProvider.AddSecretMapping(SecretNameTxt, 'TESTRESOURCE');

        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyVaultSecretProvider);
        AzureKeyVault.GetAzureKeyVaultSecret(SecretNameTxt, TestSecret);

        Assert.AreEqual('TESTRESOURCE', TestSecret, 'Could not configure keyvault');

        GraphMailSetup.Insert();
        GraphMailSetup.Initialize(true);
        GraphMailSetup.Enabled := true;
        GraphMailSetup.Modify();
    end;

    local procedure CleanupGraphEmail()
    var
        MockAzureKeyVaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        TestSecret: Text;
    begin
        MockAzureKeyVaultSecretProvider := MockAzureKeyVaultSecretProvider.MockAzureKeyVaultSecretProvider;
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyVaultSecretProvider);

        Assert.IsFalse(AzureKeyVault.GetAzureKeyVaultSecret(SecretNameTxt, TestSecret), 'Cleanup failed');
    end;

    [Scope('OnPrem')]
    procedure RemoveAttachmentForPosted(DocumentNo: Code[20]; PostingDate: Date)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        IncomingDocumentAttachment.SetRange("Document No.", DocumentNo);
        IncomingDocumentAttachment.SetRange("Posting Date", PostingDate);
        IncomingDocumentAttachment.FindFirst;
        IncomingDocumentAttachment.Delete(true);
    end;

    [Scope('OnPrem')]
    procedure RemoveAttachmentForSalesHeader(IncomingDocumentNo: Integer)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocumentNo);
        IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment.FindFirst;
        IncomingDocumentAttachment.Delete(true);
    end;

    local procedure OpenAndCloseAttachmentListForDraft(SalesHeader: Record "Sales Header")
    var
        BCO365SalesInvoice: TestPage "BC O365 Sales Invoice";
        O365SalesDocAttachments: TestPage "O365 Sales Doc. Attachments";
    begin
        BCO365SalesInvoice.OpenEdit();
        BCO365SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, SalesHeader."No.");
        O365SalesDocAttachments.Trap;
        BCO365SalesInvoice.NoOfAttachments.DrillDown;
        O365SalesDocAttachments.Close;
        BCO365SalesInvoice.Close;
    end;

    local procedure OpenAndCloseAttachmentListForPosted(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        BCO365PostedSalesInvoice: TestPage "BC O365 Posted Sales Invoice";
        O365PostedSalesInvAtt: TestPage "O365 Posted Sales Inv. Att.";
    begin
        BCO365PostedSalesInvoice.OpenEdit();
        BCO365PostedSalesInvoice.GotoKey(SalesInvoiceHeader."No.");
        O365PostedSalesInvAtt.Trap;
        BCO365PostedSalesInvoice.NoOfAttachments.DrillDown;
        O365PostedSalesInvAtt.Close;
        BCO365PostedSalesInvoice.Close;
    end;

    local procedure OpenAndCloseAttachmentListForEstimates(SalesHeader: Record "Sales Header")
    var
        BCO365SalesQuote: TestPage "BC O365 Sales Quote";
        O365SalesDocAttachments: TestPage "O365 Sales Doc. Attachments";
    begin
        BCO365SalesQuote.OpenEdit();
        BCO365SalesQuote.GotoKey(SalesHeader."Document Type"::Quote, SalesHeader."No.");
        O365SalesDocAttachments.Trap;
        BCO365SalesQuote.NoOfAttachmentsValueTxt.DrillDown;
        O365SalesDocAttachments.Close;
        BCO365SalesQuote.Close;
    end;
}

