codeunit 135060 "Document Mailing Tests"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Email] [Stream] [UT]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestEmailFileFromStream()
    var
        TempEmailItem: Record "Email Item" temporary;
        TempBlob: Codeunit "Temp Blob";
        DocumentMailing: Codeunit "Document-Mailing";
        FileManagement: Codeunit "File Management";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        InStream: InStream;
        VariableVariant: Variant;
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
        LibraryVariableStorage.Dequeue(VariableVariant);
        TempEmailItem := VariableVariant;
        VerifyEmailContents('Some content', TempEmailItem."Attachment File Path");

        // [THEN] The email items fields have been filled correctly
        Assert.AreEqual('new file.pdf', TempEmailItem."Attachment Name", 'Attachment Name was expected to be new file.pdf');
        Assert.AreEqual('a nice body', TempEmailItem.GetBodyText, 'Body was expected to be a nice body');
        Assert.AreEqual('a nice subject', TempEmailItem.Subject, 'Subject was expected to be a nice subject');
        Assert.AreEqual('someone@somewhere.com', TempEmailItem."Send to", 'Send to was expected to be someone@somewhere.com');

        // [THEN] The right values are set
        VerifyValues;

        // Clean up
        FileManagement.DeleteServerFile(TempEmailItem."Attachment File Path");

        UnbindSubscription(DocumentMailingTests);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestEmailHtmlFromStream()
    var
        TempEmailItem: Record "Email Item" temporary;
        TempBlob: Codeunit "Temp Blob";
        DocumentMailing: Codeunit "Document-Mailing";
        FileManagement: Codeunit "File Management";
        DocumentMailingTests: Codeunit "Document Mailing Tests";
        InStream: InStream;
        VariableVariant: Variant;
    begin
        // [SCENARIO] A HTML File can be attached to an email using a Stream
        BindSubscription(DocumentMailingTests);
        Clear(LibraryVariableStorage);

        // [GIVEN] A Stream with some content
        InitializeStream('Some content', TempBlob);
        TempBlob.CreateInStream(InStream);

        // [WHEN] The function EmailFileFromStream is called
        Clear(DocumentMailing);
        DocumentMailing.EmailHtmlFromStream(InStream, 'someone@somewhere.com', 'a nice subject', true, 0);

        // [THEN] A temp file with the stream content is created
        LibraryVariableStorage.Dequeue(VariableVariant);
        TempEmailItem := VariableVariant;
        VerifyEmailContents('Some content', TempEmailItem."Body File Path");

        // [THEN] The email items fields have been filled correctly
        Assert.AreEqual('someone@somewhere.com', TempEmailItem."Send to", 'Send to was expected to be someone@somewhere.com');
        Assert.AreEqual('a nice subject', TempEmailItem.Subject, 'Subject was expected to be a nice subject');

        // [THEN] The right values are set
        VerifyValues;

        // Clean up
        FileManagement.DeleteServerFile(TempEmailItem."Body File Path");

        UnbindSubscription(DocumentMailingTests);
    end;

    [EventSubscriber(ObjectType::Codeunit, 260, 'OnBeforeSendEmail', '', false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeSendEmail(var TempEmailItem: Record "Email Item" temporary; IsFromPostedDoc: Boolean; PostedDocNo: Code[20]; HideDialog: Boolean; ReportUsage: Integer)
    begin
        LibraryVariableStorage.Enqueue(TempEmailItem);
        LibraryVariableStorage.Enqueue(IsFromPostedDoc);
        LibraryVariableStorage.Enqueue(PostedDocNo);
        LibraryVariableStorage.Enqueue(HideDialog);
        LibraryVariableStorage.Enqueue(ReportUsage);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure InitializeStream(Content: Text; var TempBlob: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(Content);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure VerifyEmailContents(Content: Text; FilePath: Text)
    var
        TempFile: File;
        Instream: InStream;
    begin
        TempFile.Open(FilePath);
        TempFile.CreateInStream(Instream);
        Instream.ReadText(Content);
        Assert.AreEqual('Some content', Content, 'Content was expected to be Some content');
        TempFile.Close;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure VerifyValues()
    begin
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, 'IsFromPostedDoc was expected to be false');
        Assert.AreEqual('', LibraryVariableStorage.DequeueText, 'PostedDocNo was expected to be empty');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'HideDialog was expected to be true');
        Assert.AreEqual(0, LibraryVariableStorage.DequeueInteger, 'ReportUsage was expected to be 0');
    end;
}

