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
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
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
        Content, BodyContent : Text;
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
        Content, BodyContent : Text;
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
}

