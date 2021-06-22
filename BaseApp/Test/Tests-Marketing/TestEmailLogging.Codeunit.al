codeunit 139012 "Test Email Logging"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Marketing] [EMail Logging]
    end;

    var
        Assert: Codeunit Assert;
        EmailLoggingDispatcher: Codeunit "Email Logging Dispatcher";
        DefaultExchangeEndpointTxt: Label 'https://outlook.office365.com/EWS/Exchange.asmx';
        TestExchangeEndpointTxt: Label 'testendpoint.exchange';

    [Test]
    [Scope('OnPrem')]
    procedure TestIsContact()
    var
        SegLine: Record "Segment Line";
        Contact: Record Contact;
        Email: Text[80];
        ContactNo: Code[20];
        Result: Boolean;
    begin
        Contact.SetFilter("No.", '<>''''');
        Contact.SetFilter("Search E-Mail", '<>''''');
        Contact.FindFirst;

        ContactNo := Contact."No.";
        Email := Contact."Search E-Mail";

        Result := EmailLoggingDispatcher.IsContact(Email, SegLine);
        Assert.IsTrue(Result, 'Email does not belong to any of the contacts');
        Assert.AreEqual(ContactNo, SegLine."Contact No.", 'Setting segment contact details failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsContactAlt()
    var
        SegLine: Record "Segment Line";
        ContactAltAddr: Record "Contact Alt. Address";
        Email: Text[80];
        ContactNo: Code[20];
        Result: Boolean;
    begin
        ContactAltAddr.FindFirst;
        ContactNo := ContactAltAddr."Contact No.";
        if ContactAltAddr."Search E-Mail" = '' then begin
            ContactAltAddr."Search E-Mail" := 'xxlalt@candoxy.net';
            ContactAltAddr.Modify();
        end;

        Email := ContactAltAddr."Search E-Mail";

        Result := EmailLoggingDispatcher.IsContact(Email, SegLine);
        Assert.IsTrue(Result, 'Email does not belong to any of the alternative contacts.');
        Assert.AreEqual(ContactNo, SegLine."Contact No.", 'Setting segment contact details failed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsSalesperson()
    var
        SalesPersonPurchaser: Record "Salesperson/Purchaser";
        Result: Boolean;
        "Code": Code[10];
        Email: Text[80];
        SalesPersonCode: Code[20];
    begin
        SalesPersonPurchaser.SetFilter(Code, '<>''''');
        SalesPersonPurchaser.SetFilter("Search E-Mail", '<>''''');
        SalesPersonPurchaser.FindFirst;

        SalesPersonCode := SalesPersonPurchaser.Code;
        Email := SalesPersonPurchaser."Search E-Mail";
        Result := EmailLoggingDispatcher.IsSalesperson(Email, Code);
        Assert.IsTrue(Result, 'Email does not belong to any of the salespeople');
        Assert.AreEqual(SalesPersonCode, Code, 'Email does not belong to the expected sales person');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestInseringtInteractionLogEntry()
    var
        SegLine: Record "Segment Line";
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        SegLine.Init();
        EmailLoggingDispatcher.InsertInteractionLogEntry(SegLine, 99990);
        Assert.IsTrue(InteractionLogEntry.Get(99990), 'Inserting Interaction Log Entry failed');
        Assert.IsTrue(InteractionLogEntry."E-Mail Logged", 'Email not logged');
        InteractionLogEntry.Delete(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUpdatingSegLine()
    var
        SegLine: Record "Segment Line";
        DateTime: DotNet DateTime;
        Date: Date;
    begin
        SegLine.SetFilter("Segment No.", '<>''''');
        SegLine.SetFilter("Line No.", '>0');
        SegLine.FindFirst;

        DateTime := DateTime.Now;
        Date := DMY2Date(DateTime.Day, DateTime.Month, DateTime.Year);
        EmailLoggingDispatcher.UpdateSegLine(SegLine, 'GOLF', 'subject', DateTime, DateTime, 20);
        Assert.AreEqual(SegLine.Description, 'subject', 'Error setting description');
        Assert.AreEqual(SegLine.Date, Date, 'Error date');
        Assert.AreEqual(SegLine."Attachment No.", 20, 'Error setting att. no.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestSetupVerification()
    var
        MarketingSetup: Record "Marketing Setup";
        Stream: OutStream;
    begin
        MarketingSetup.Get();

        MarketingSetup."Queue Folder UID".CreateOutStream(Stream);
        Stream.WriteText('test value');
        MarketingSetup."Storage Folder UID".CreateOutStream(Stream);
        Stream.WriteText('test value 2');
        MarketingSetup."Autodiscovery E-Mail Address" := 'test@test.com';
        MarketingSetup."Email Logging Enabled" := true;
        MarketingSetup.Modify();

        EmailLoggingDispatcher.CheckSetup(MarketingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAttachmentRecordAlreadyExists()
    var
        Attachment: Record Attachment;
        AttachmentNo: Text;
        No: Integer;
    begin
        AttachmentNo := '1';
        Evaluate(No, AttachmentNo);
        Attachment.Init();
        Assert.IsTrue(EmailLoggingDispatcher.AttachmentRecordAlreadyExists(AttachmentNo, Attachment), 'Existing attachment not found');
        Assert.AreEqual(Attachment."No.", No, 'Expected Attachment No. not retrieved');

        Attachment.FindLast;
        AttachmentNo := StrSubstNo('%1%2', Attachment."No.", '0');
        Evaluate(No, AttachmentNo);
        Attachment.Init();
        Assert.IsFalse(EmailLoggingDispatcher.AttachmentRecordAlreadyExists(AttachmentNo, Attachment), 'Nonexisting attachment found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetSetErrorContext()
    var
        Context: Text;
    begin
        Context := 'Test Context 1';
        EmailLoggingDispatcher.SetErrorContext(Context);
        Assert.AreEqual(Context, EmailLoggingDispatcher.GetErrorContext, 'GetContext did not return what was in SetContext 1st time');

        Context := 'Test Context 2';
        EmailLoggingDispatcher.SetErrorContext(Context);
        Assert.AreEqual(Context, EmailLoggingDispatcher.GetErrorContext, 'GetContext did not return what was in SetContext 2nd time');

        Context := '';
        EmailLoggingDispatcher.SetErrorContext(Context);
        Assert.AreEqual(
          Context, EmailLoggingDispatcher.GetErrorContext, 'GetContext did not return empty string what was in SetContext 3rd time');

        Context := 'Test Context 3';
        EmailLoggingDispatcher.SetErrorContext(Context);
        Assert.AreEqual(Context, EmailLoggingDispatcher.GetErrorContext, 'GetContext did not return what was in SetContext 4th time');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestItemLinkedFromAttachment()
    var
        Attachment: Record Attachment;
        No: Integer;
        MessageId: Text;
        EntryId: Text;
    begin
        MessageId := 'AABBCCXX=';
        EntryId := 'AAXXCCDDFF==';

        No := 0;
        if Attachment.FindLast then
            No := Attachment."No." + 1;

        Attachment.Init();
        Attachment."No." := No;
        Attachment.SetMessageID(MessageId);
        Attachment.SetEntryID(EntryId);
        Attachment.Insert();

        Assert.IsTrue(
          EmailLoggingDispatcher.ItemLinkedFromAttachment(MessageId, Attachment),
          'ItemLinkedFromAttachment returned FALSE on existing MessageId');
        Assert.IsFalse(
          EmailLoggingDispatcher.ItemLinkedFromAttachment(EntryId, Attachment),
          'ItemLinkedFromAttachment returned TRUE on non-existing MessageId');

        Attachment.Delete();
        Assert.IsFalse(
          EmailLoggingDispatcher.ItemLinkedFromAttachment(MessageId, Attachment),
          'ItemLinkedFromAttachment returned TRUE after deletion of record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFolderBLOBs()
    var
        TempExchangeFolder: Record "Exchange Folder" temporary;
    begin
        TempExchangeFolder.Init();
        TempExchangeFolder.FullPath := 'path';
        TempExchangeFolder.SetUniqueID('idid');
        Assert.IsTrue(TempExchangeFolder."Unique ID".HasValue, 'UID BLOB not initialized');
        TempExchangeFolder.Insert();
        TempExchangeFolder.Get('path');
        Assert.AreEqual(TempExchangeFolder.GetUniqueID, 'idid', 'UID BLOB not retreived');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestMktSetupClearEmailLoggingSetup()
    var
        MarketingSetup: Record "Marketing Setup";
        MarketingSetupPage: Page "Marketing Setup";
        Stream: OutStream;
    begin
        MarketingSetup.Get();

        MarketingSetup."Autodiscovery E-Mail Address" := 'test@contoso.net';

        MarketingSetup."Queue Folder Path" := 'Some\Path';
        MarketingSetup."Queue Folder UID".CreateOutStream(Stream);
        Stream.WriteText('test value');

        MarketingSetup."Storage Folder Path" := 'Bar\Foo';
        MarketingSetup."Storage Folder UID".CreateOutStream(Stream);
        Stream.WriteText('test value 2');
        MarketingSetup."Autodiscovery E-Mail Address" := 'test@test.com';
        MarketingSetup."Email Logging Enabled" := true;
        MarketingSetup.Modify();

        MarketingSetup.Init();
        MarketingSetup.Get();
        Assert.IsTrue(MarketingSetup."Autodiscovery E-Mail Address" <> '', 'E-mail address is not set');

        Assert.IsTrue(MarketingSetup."Queue Folder Path" <> '', 'Queue Folder path is not set');
        Assert.IsTrue(MarketingSetup."Queue Folder UID".HasValue, 'Queue Folder UID is not set');

        Assert.IsTrue(MarketingSetup."Storage Folder Path" <> '', 'Storage Folder path is not set');
        Assert.IsTrue(MarketingSetup."Storage Folder UID".HasValue, 'Storage Folder UID is not set');

        Assert.IsTrue(MarketingSetup."Email Logging Enabled", 'Email Logging is not enabled');

        MarketingSetupPage.ClearEmailLoggingSetup(MarketingSetup);

        MarketingSetup.Init();
        MarketingSetup.Get();

        Assert.IsFalse(MarketingSetup."Autodiscovery E-Mail Address" <> '', 'E-mail address is not cleared');

        Assert.IsFalse(MarketingSetup."Queue Folder Path" <> '', 'Queue Folder path is not cleared');
        Assert.IsFalse(MarketingSetup."Queue Folder UID".HasValue, 'Queue Folder UID is not cleared');

        Assert.IsFalse(MarketingSetup."Storage Folder Path" <> '', 'Storage Folder path is not cleared');
        Assert.IsFalse(MarketingSetup."Storage Folder UID".HasValue, 'Storage Folder UID is not cleared');

        Assert.IsFalse(MarketingSetup."Email Logging Enabled", 'Email Logging is not disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckInteractionTemplateSetup()
    var
        InteractionTemplateSetup: Record "Interaction Template Setup";
        EmailLoggingDispatcher: Codeunit "Email Logging Dispatcher";
        EmptyText: Text;
        TmpEmailSetup: Code[10];
    begin
        InteractionTemplateSetup.Get();

        TmpEmailSetup := InteractionTemplateSetup."E-Mails";

        // Test negative scenario when field empty.
        InteractionTemplateSetup."E-Mails" := '';
        InteractionTemplateSetup.Modify();
        Assert.IsFalse(
          EmailLoggingDispatcher.CheckInteractionTemplateSetup(EmptyText),
          'Should fail validation when no value is found for the E-Mails field on Interaction Template Setup');

        // Test negative scenario when corresponding record cannot be found. This assumes that no Interaction Template exists in demo data called xxx.
        InteractionTemplateSetup."E-Mails" := 'INVALID';
        InteractionTemplateSetup.Modify();
        Assert.IsFalse(
          EmailLoggingDispatcher.CheckInteractionTemplateSetup(EmptyText),
          'Should fail validation when corresponding Interaction Template cannot be found.');

        // Test postitive scenario where validation should pass. This assumes that the corresponding Interaction Template exists in demo data.
        InteractionTemplateSetup."E-Mails" := TmpEmailSetup;
        InteractionTemplateSetup.Modify();

        Assert.IsTrue(
          EmailLoggingDispatcher.CheckInteractionTemplateSetup(EmptyText),
          'Should pass validation when E-Mails field set on Interaction Template Setup and this points to an existing Interaction Template.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmailLoggingAdapterOnEmptyEmailLoggingSetup()
    var
        MarketingSetup: Record "Marketing Setup";
        JobQueueEntry: Record "Job Queue Entry";
        BackupEmail: Text[250];
    begin
        MarketingSetup.Get();
        BackupEmail := MarketingSetup."Autodiscovery E-Mail Address";
        Clear(MarketingSetup."Autodiscovery E-Mail Address");
        MarketingSetup."Email Logging Enabled" := true;
        MarketingSetup.Modify();

        Commit();

        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid;

        Assert.IsFalse(CODEUNIT.Run(5065, JobQueueEntry), 'Expected COD5065 OnRun to fail');
        Assert.AreNotEqual('', GetLastErrorText, 'Expected LASTERRORTEXT to be non-empty string');

        MarketingSetup."Autodiscovery E-Mail Address" := BackupEmail;
        MarketingSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmailLoggingAdapterOnEmptyInteractionTemplateSetup()
    var
        InteractionTemplateSetup: Record "Interaction Template Setup";
        JobQueueEntry: Record "Job Queue Entry";
        TmpEmailSetup: Code[10];
    begin
        InteractionTemplateSetup.Get();

        TmpEmailSetup := InteractionTemplateSetup."E-Mails";

        InteractionTemplateSetup."E-Mails" := '';
        InteractionTemplateSetup.Modify();

        Commit();

        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid;

        Assert.IsFalse(CODEUNIT.Run(5065, JobQueueEntry), 'Expected COD5065 OnRun to fail');
        Assert.AreNotEqual('', GetLastErrorText, 'Expected LASTERRORTEXT to be non-empty string');

        InteractionTemplateSetup."E-Mails" := TmpEmailSetup;
        InteractionTemplateSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExchangeWebServiceEndpointEvent()
    var
        ExchangeWebServicesServer: Codeunit "Exchange Web Services Server";
        TestEmailLogging: Codeunit "Test Email Logging";
        ResultTxt: Text;
    begin
        // [SCENARIO 357110] Test Exchange Endpoint can be overriden by event
        BindSubscription(TestEmailLogging);
        // [WHEN] Invoke GetEndpoint
        ResultTxt := ExchangeWebServicesServer.GetEndpoint();
        UnbindSubscription(TestEmailLogging);
        // [THEN] Default endpoint is overriden in OnAfterGetProdEndpoint event
        Assert.AreEqual(TestExchangeEndpointTxt, ResultTxt, 'Wrong Exchange Endpoint');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExchangeWebServiceEndpointDefaultValue()
    var
        ExchangeWebServicesServer: Codeunit "Exchange Web Services Server";
        ResultTxt: Text;
    begin
        // [SCENARIO 357110] Test default exchange endpoint value when not overriden by event
        // [WHEN] Invoke GetEndpoint
        ResultTxt := ExchangeWebServicesServer.ProdEndpoint();
        // [THEN] Default endpoint value is returned
        Assert.AreEqual(DefaultExchangeEndpointTxt, ResultTxt, 'Wrong Exchange Endpoint');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exchange Web Services Server", 'OnAfterGetProdEndpoint', '', false, false)]
    local procedure OnAfterGetProdEndpoint(var ProdEndPointText: Text)
    begin
        ProdEndPointText := TestExchangeEndpointTxt;
    end;
}

