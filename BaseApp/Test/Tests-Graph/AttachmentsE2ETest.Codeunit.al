codeunit 135545 "Attachments E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Attachment]
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryERM: Codeunit "Library - ERM";
        AttachmentServiceNameTxt: Label 'attachments';
        GLEntryAttachmentServiceNameTxt: Label 'generalLedgerEntryAttachments';
        InvoiceServiceNameTxt: Label 'salesInvoices';
        PurchaseInvoiceServiceNameTxt: Label 'purchaseInvoices';
        ActionPostTxt: Label 'Microsoft.NAV.post';
        EmptyJSONErr: Label 'The JSON should not be blank.';
        WrongPropertyValueErr: Label 'Incorrect property value for %1.';
        CreateIncomingDocumentErr: Label 'Cannot create incoming document.';
        CannotChangeIDErr: Label 'The id cannot be changed.', Locked = true;
        CannotModifyKeyFieldErr: Label 'You cannot change the value of the key field %1.', Locked = true;
        LibraryPurchase: Codeunit "Library - Purchase";

    [Test]
    [Scope('OnPrem')]
    procedure TestGetJournalLineAttachments()
    var
        DocumentRecordRef: RecordRef;
        AttachmentId: array[2] of Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve all records from the Attachments API.
        // [GIVEN] 2 Attachments in the Incoming Document Attachment table
        CreateGenJournalLine(DocumentRecordRef);
        CreateAttachments(DocumentRecordRef, AttachmentId);
        Commit();

        // [WHEN] A GET request is made to the Attachment API.
        TargetURL := CreateAttachmentsURLWithFilter(GetDocumentId(DocumentRecordRef));
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The 2 Attachments should exist in the response
        GetAndVerifyIDFromJSON(ResponseText, AttachmentId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetGLEntryAttachments()
    var
        DocumentRecordRef: RecordRef;
        AttachmentId: array[2] of Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve all records from the Attachments API.
        // [GIVEN] 2 Attachments in the Incoming Document Attachment table
        CreateGLEntry(DocumentRecordRef);
        CreateAttachments(DocumentRecordRef, AttachmentId);
        Commit();

        // [WHEN] A GET request is made to the Attachment API.
        TargetURL := CreateGLEntryAttachmentsURLWithFilter(Format(GetGLEntryNo(DocumentRecordRef)));
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The 2 Attachments should exist in the response
        GetAndVerifyIDFromJSON(ResponseText, AttachmentId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPostedInvoiceAttachments()
    var
        DocumentRecordRef: RecordRef;
        AttachmentId: array[2] of Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve all records from the Attachments API.
        // [GIVEN] 2 Attachments in the Incoming Document Attachment table
        CreatePostedSalesInvoice(DocumentRecordRef);
        CreateAttachments(DocumentRecordRef, AttachmentId);
        Commit();

        // [WHEN] A GET request is made to the Attachment API.
        TargetURL := CreateAttachmentsURLWithFilter(GetDocumentId(DocumentRecordRef));
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The 2 Attachments should exist in the response
        GetAndVerifyIDFromJSON(ResponseText, AttachmentId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetDraftInvoiceAttachments()
    var
        DocumentRecordRef: RecordRef;
        AttachmentId: array[2] of Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve all records from the Attachments API.
        // [GIVEN] 2 Attachments in the Incoming Document Attachment table
        CreateDraftSalesInvoice(DocumentRecordRef);
        CreateAttachments(DocumentRecordRef, AttachmentId);
        Commit();

        // [WHEN] A GET request is made to the Attachment API.
        TargetURL := CreateAttachmentsURLWithFilter(GetDocumentId(DocumentRecordRef));
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The 2 Attachments should exist in the response
        GetAndVerifyIDFromJSON(ResponseText, AttachmentId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPostedPurchaseInvoiceAttachments()
    var
        DocumentRecordRef: RecordRef;
        AttachmentId: array[2] of Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve all records from the Attachments API.
        // [GIVEN] 2 Attachments in the Incoming Document Attachment table
        CreatePostedPurchaseInvoice(DocumentRecordRef);
        CreateAttachments(DocumentRecordRef, AttachmentId);
        Commit();

        // [WHEN] A GET request is made to the Attachment API.
        TargetURL := CreateAttachmentsURLWithFilter(GetDocumentId(DocumentRecordRef));
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The 2 Attachments should exist in the response
        GetAndVerifyIDFromJSON(ResponseText, AttachmentId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetDraftPurchaseInvoiceAttachments()
    var
        DocumentRecordRef: RecordRef;
        AttachmentId: array[2] of Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve all records from the Attachments API.
        // [GIVEN] 2 Attachments in the Incoming Document Attachment table
        CreateDraftPurchaseInvoice(DocumentRecordRef);
        CreateAttachments(DocumentRecordRef, AttachmentId);
        Commit();

        // [WHEN] A GET request is made to the Attachment API.
        TargetURL := CreateAttachmentsURLWithFilter(GetDocumentId(DocumentRecordRef));
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The 2 Attachments should exist in the response
        GetAndVerifyIDFromJSON(ResponseText, AttachmentId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetQuoteAttachments()
    var
        DocumentRecordRef: RecordRef;
        AttachmentId: array[2] of Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve all records from the Attachments API.
        // [GIVEN] 2 Attachments in the Incoming Document Attachment table
        CreateSalesQuote(DocumentRecordRef);
        CreateAttachments(DocumentRecordRef, AttachmentId);
        Commit();

        // [WHEN] A GET request is made to the Attachment API.
        TargetURL := CreateAttachmentsURLWithFilter(GetDocumentId(DocumentRecordRef));
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The 2 Attachment should exist in the response
        GetAndVerifyIDFromJSON(ResponseText, AttachmentId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetJournalLineAttachment()
    var
        DocumentRecordRef: RecordRef;
        AttachmentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve the Attachment record from the Attachment API.
        // [GIVEN] Attachment exists in the Incoming Document Attachment table
        CreateGenJournalLine(DocumentRecordRef);
        AttachmentId := CreateAttachment(DocumentRecordRef);
        Commit();

        // [WHEN] A GET request is made to the Attachment API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithTwoKeyFields(
            GetDocumentId(DocumentRecordRef), AttachmentId, PAGE::"Attachments Entity", AttachmentServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The Attachment should exist in the response
        LibraryGraphMgt.VerifyGUIDFieldInJson(ResponseText, 'id', AttachmentId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetGLEntryAttachment()
    var
        DocumentRecordRef: RecordRef;
        AttachmentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve the Attachment record from the Attachment API.
        // [GIVEN] Attachment exists in the Incoming Document Attachment table
        CreateGLEntry(DocumentRecordRef);
        AttachmentId := CreateAttachment(DocumentRecordRef);
        Commit();

        // [WHEN] A GET request is made to the Attachment API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithTwoKeyFields(
            Format(GetGLEntryNo(DocumentRecordRef)), AttachmentId, PAGE::"G/L Entry Attachments Entity", GLEntryAttachmentServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The Attachment should exist in the response
        LibraryGraphMgt.VerifyGUIDFieldInJson(ResponseText, 'id', AttachmentId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPostedInvoiceAttachment()
    var
        DocumentRecordRef: RecordRef;
        AttachmentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve the Attachment record from the Attachment API.
        // [GIVEN] Attachment exists in the Incoming Document Attachment table
        CreatePostedSalesInvoice(DocumentRecordRef);
        AttachmentId := CreateAttachment(DocumentRecordRef);
        Commit();

        // [WHEN] A GET request is made to the Attachment API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithTwoKeyFields(
            GetDocumentId(DocumentRecordRef), AttachmentId, PAGE::"Attachments Entity", AttachmentServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The Attachment should exist in the response
        LibraryGraphMgt.VerifyGUIDFieldInJson(ResponseText, 'id', AttachmentId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetDraftInvoiceAttachment()
    var
        DocumentRecordRef: RecordRef;
        AttachmentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve the Attachment record from the Attachment API.
        // [GIVEN] Attachment exists in the Incoming Document Attachment table
        CreateDraftSalesInvoice(DocumentRecordRef);
        AttachmentId := CreateAttachment(DocumentRecordRef);
        Commit();

        // [WHEN] A GET request is made to the Attachment API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithTwoKeyFields(
            GetDocumentId(DocumentRecordRef), AttachmentId, PAGE::"Attachments Entity", AttachmentServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The Attachment should exist in the response
        LibraryGraphMgt.VerifyGUIDFieldInJson(ResponseText, 'id', AttachmentId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetQuoteAttachment()
    var
        DocumentRecordRef: RecordRef;
        AttachmentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve the Attachment record from the Attachment API.
        // [GIVEN] Attachment exists in the Incoming Document Attachment table
        CreateSalesQuote(DocumentRecordRef);
        AttachmentId := CreateAttachment(DocumentRecordRef);
        Commit();

        // [WHEN] A GET request is made to the Attachment API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithTwoKeyFields(
            GetDocumentId(DocumentRecordRef), AttachmentId, PAGE::"Attachments Entity", AttachmentServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The Attachment should exist in the response
        LibraryGraphMgt.VerifyGUIDFieldInJson(ResponseText, 'id', AttachmentId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateGenJournalLineAttachmentBinaryContent()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecordRef: RecordRef;
        AttachmentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
        ExpectedBase64Content: Text;
        ActualBase64Content: Text;
    begin
        // [SCENARIO] User can update linked attachment binary content through the Attachment API.
        // [GIVEN] A linked attachment exists
        CreateGenJournalLine(DocumentRecordRef);
        AttachmentId := CreateAttachment(DocumentRecordRef);
        GenerateRandomBinaryContent(TempBlob);
        ExpectedBase64Content := BlobToBase64String(TempBlob);
        Commit();

        // [WHEN] A PATCH request is made to the Attachment API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithTwoKeyFieldsAndSubpage(
            GetDocumentId(DocumentRecordRef), AttachmentId, PAGE::"Attachments Entity", AttachmentServiceNameTxt, 'content');
        LibraryGraphMgt.BinaryUpdateToWebServiceAndCheckResponseCode(TargetURL, TempBlob, 'PATCH', ResponseText, 204);

        // [THEN] The Attachment should exist in the response
        Assert.AreEqual('', ResponseText, 'Response should be empty');

        // [THEN] The content is correctly updated.
        IncomingDocumentAttachment.SetRange(Id, AttachmentId);
        IncomingDocumentAttachment.FindFirst;
        ActualBase64Content := GetAttachmentBase64Content(IncomingDocumentAttachment);
        Assert.AreEqual(ExpectedBase64Content, ActualBase64Content, 'Wrong content');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateGLEntryAttachmentBinaryContent()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecordRef: RecordRef;
        AttachmentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
        ExpectedBase64Content: Text;
        ActualBase64Content: Text;
    begin
        // [SCENARIO] User can update linked attachment binary content through the Attachment API.
        // [GIVEN] A linked attachment exists
        CreateGLEntry(DocumentRecordRef);
        AttachmentId := CreateAttachment(DocumentRecordRef);
        GenerateRandomBinaryContent(TempBlob);
        ExpectedBase64Content := BlobToBase64String(TempBlob);
        Commit();

        // [WHEN] A PATCH request is made to the Attachment API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithTwoKeyFieldsAndSubpage(
            Format(GetGLEntryNo(DocumentRecordRef)),
            AttachmentId, PAGE::"G/L Entry Attachments Entity", GLEntryAttachmentServiceNameTxt, 'content');
        LibraryGraphMgt.BinaryUpdateToWebServiceAndCheckResponseCode(TargetURL, TempBlob, 'PATCH', ResponseText, 204);

        // [THEN] The Attachment should exist in the response
        Assert.AreEqual('', ResponseText, 'Response should be empty');

        // [THEN] The content is correctly updated.
        IncomingDocumentAttachment.SetRange(Id, AttachmentId);
        IncomingDocumentAttachment.FindFirst;
        ActualBase64Content := GetAttachmentBase64Content(IncomingDocumentAttachment);
        Assert.AreEqual(ExpectedBase64Content, ActualBase64Content, 'Wrong content');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateJournalLineAttachment()
    var
        DocumentRecordRef: RecordRef;
    begin
        CreateGenJournalLine(DocumentRecordRef);
        TestCreateAttachment(DocumentRecordRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateGLEntryAttachment()
    var
        DocumentRecordRef: RecordRef;
    begin
        CreateGLEntry(DocumentRecordRef);
        TestCreateGLEAttachment(DocumentRecordRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePostedInvoiceAttachment()
    var
        DocumentRecordRef: RecordRef;
    begin
        CreatePostedSalesInvoice(DocumentRecordRef);
        TestCreateAttachment(DocumentRecordRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDraftInvoiceAttachment()
    var
        DocumentRecordRef: RecordRef;
    begin
        CreateDraftSalesInvoice(DocumentRecordRef);
        TestCreateAttachment(DocumentRecordRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePostedPurchaseInvoiceAttachment()
    var
        DocumentRecordRef: RecordRef;
    begin
        CreatePostedPurchaseInvoice(DocumentRecordRef);
        TestCreateAttachment(DocumentRecordRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDraftPurchaseInvoiceAttachment()
    var
        DocumentRecordRef: RecordRef;
    begin
        CreateDraftPurchaseInvoice(DocumentRecordRef);
        TestCreateAttachment(DocumentRecordRef);
    end;

    [Normal]
    local procedure TestCreateAttachment(var DocumentRecordRef: RecordRef)
    var
        TempIncomingDocumentAttachment: Record "Incoming Document Attachment" temporary;
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocument: Record "Incoming Document";
        TempBlob: Codeunit "Temp Blob";
        DocumentId: Guid;
        AttachmentId: Text;
        ResponseText: Text;
        TargetURL: Text;
        AttachmentJSON: Text;
    begin
        // [SCENARIO] Create an Attachment through a POST method and check if it was created
        // [GIVEN] The user has constructed an Attachment JSON object to send to the service.
        FindOrCreateIncomingDocument(DocumentRecordRef, IncomingDocument);
        DocumentId := GetDocumentId(DocumentRecordRef);
        CreateIncomingDocumentAttachment(IncomingDocument, TempIncomingDocumentAttachment);
        TempBlob.FromRecord(TempIncomingDocumentAttachment, TempIncomingDocumentAttachment.FieldNo(Content));
        AttachmentJSON := GetAttachmentJSON(DocumentId, TempIncomingDocumentAttachment, false);
        Commit();

        // [WHEN] The user posts the JSON to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Attachments Entity", AttachmentServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, AttachmentJSON, ResponseText);
        // [WHEN] The user uploads binary content to the attachment
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'id', AttachmentId);
        TargetURL := LibraryGraphMgt.CreateTargetURLWithTwoKeyFieldsAndSubpage(
            DocumentId, AttachmentId, PAGE::"Attachments Entity", AttachmentServiceNameTxt, 'content');
        LibraryGraphMgt.BinaryUpdateToWebServiceAndCheckResponseCode(TargetURL, TempBlob, 'PATCH', ResponseText, 204);

        // [THEN] The Attachment has been created in the database.
        LibraryGraphMgt.VerifyIDFieldInJson(ResponseText, 'id');
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'id', AttachmentId);
        IncomingDocumentAttachment.SetFilter(Id, AttachmentId);
        IncomingDocumentAttachment.FindFirst;

        if IncomingDocument.Posted then begin
            Assert.AreEqual(IncomingDocument."Document No.", IncomingDocumentAttachment."Document No.", '');
            Assert.AreEqual(IncomingDocument."Posting Date", IncomingDocumentAttachment."Posting Date", '');
        end;
        Assert.AreEqual(GetAttachmentBase64Content(IncomingDocumentAttachment), BlobToBase64String(TempBlob), 'Wrong Content');
    end;

    [Normal]
    local procedure TestCreateGLEAttachment(var DocumentRecordRef: RecordRef)
    var
        TempIncomingDocumentAttachment: Record "Incoming Document Attachment" temporary;
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocument: Record "Incoming Document";
        TempBlob: Codeunit "Temp Blob";
        GLEntryNo: Integer;
        AttachmentId: Text;
        ResponseText: Text;
        TargetURL: Text;
        AttachmentJSON: Text;
    begin
        // [SCENARIO] Create an Attachment through a POST method and check if it was created
        // [GIVEN] The user has constructed an Attachment JSON object to send to the service.
        FindOrCreateIncomingDocument(DocumentRecordRef, IncomingDocument);
        GLEntryNo := GetGLEntryNo(DocumentRecordRef);
        CreateIncomingDocumentAttachment(IncomingDocument, TempIncomingDocumentAttachment);
        TempBlob.FromRecord(TempIncomingDocumentAttachment, TempIncomingDocumentAttachment.FieldNo(Content));
        AttachmentJSON := GetGLEntryAttachmentJSON(GLEntryNo, TempIncomingDocumentAttachment, false);
        Commit();

        // [WHEN] The user posts the JSON to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"G/L Entry Attachments Entity", GLEntryAttachmentServiceNameTxt);
        LibraryGraphMgt.PostToWebService(TargetURL, AttachmentJSON, ResponseText);
        // [WHEN] The user uploads binary content to the attachment
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'id', AttachmentId);
        TargetURL := LibraryGraphMgt.CreateTargetURLWithTwoKeyFieldsAndSubpage(
            Format(GLEntryNo), AttachmentId, PAGE::"G/L Entry Attachments Entity", GLEntryAttachmentServiceNameTxt, 'content');
        LibraryGraphMgt.BinaryUpdateToWebServiceAndCheckResponseCode(TargetURL, TempBlob, 'PATCH', ResponseText, 204);

        // [THEN] The Attachment has been created in the database.
        LibraryGraphMgt.VerifyIDFieldInJson(ResponseText, 'id');
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'id', AttachmentId);
        IncomingDocumentAttachment.SetFilter(Id, AttachmentId);
        IncomingDocumentAttachment.FindFirst;

        if IncomingDocument.Posted then begin
            Assert.AreEqual(IncomingDocument."Document No.", IncomingDocumentAttachment."Document No.", '');
            Assert.AreEqual(IncomingDocument."Posting Date", IncomingDocumentAttachment."Posting Date", '');
        end;
        Assert.AreEqual(GetAttachmentBase64Content(IncomingDocumentAttachment), BlobToBase64String(TempBlob), 'Wrong Content');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateQuoteAttachment()
    var
        DocumentRecordRef: RecordRef;
    begin
        CreateSalesQuote(DocumentRecordRef);
        TestCreateAttachment(DocumentRecordRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteJournalLineAttachment()
    var
        DocumentRecordRef: RecordRef;
    begin
        CreateGenJournalLine(DocumentRecordRef);
        TestDeleteAttachment(DocumentRecordRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteGLEntryAttachment()
    var
        DocumentRecordRef: RecordRef;
    begin
        CreateGLEntry(DocumentRecordRef);
        TestDeleteGLEAttachment(DocumentRecordRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletePostedInvoiceAttachment()
    var
        DocumentRecordRef: RecordRef;
    begin
        CreatePostedSalesInvoice(DocumentRecordRef);
        TestDeleteAttachment(DocumentRecordRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteDraftInvoiceAttachment()
    var
        DocumentRecordRef: RecordRef;
    begin
        CreateDraftSalesInvoice(DocumentRecordRef);
        TestDeleteAttachment(DocumentRecordRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletePostedPurchaseInvoiceAttachment()
    var
        DocumentRecordRef: RecordRef;
    begin
        CreatePostedPurchaseInvoice(DocumentRecordRef);
        TestDeleteAttachment(DocumentRecordRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteDraftPurchaseInvoiceAttachment()
    var
        DocumentRecordRef: RecordRef;
    begin
        CreateDraftPurchaseInvoice(DocumentRecordRef);
        TestDeleteAttachment(DocumentRecordRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteQuoteAttachment()
    var
        DocumentRecordRef: RecordRef;
    begin
        CreateSalesQuote(DocumentRecordRef);
        TestDeleteAttachment(DocumentRecordRef);
    end;

    [Normal]
    local procedure TestDeleteAttachment(var DocumentRecordRef: RecordRef)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        DocumentId: Guid;
        AttachmentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can delete an Attachment by making a DELETE request.
        // [GIVEN] An Attachment exists.
        DocumentId := GetDocumentId(DocumentRecordRef);
        AttachmentId := CreateAttachment(DocumentRecordRef);
        Commit();

        // [WHEN] The user makes a DELETE request to the endpoint for the Attachment.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithTwoKeyFields(
            DocumentId, AttachmentId, PAGE::"Attachments Entity", AttachmentServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] The response is empty.
        Assert.AreEqual('', ResponseText, 'DELETE response should be empty.');

        // [THEN] The Attachment is no longer in the database.
        IncomingDocumentAttachment.SetRange(Id, AttachmentId);
        Assert.IsFalse(IncomingDocumentAttachment.FindFirst, 'The attachment should be deleted.');
    end;

    [Normal]
    local procedure TestDeleteGLEAttachment(var DocumentRecordRef: RecordRef)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        GLEntryNo: Integer;
        AttachmentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can delete an Attachment by making a DELETE request.
        // [GIVEN] An Attachment exists.
        GLEntryNo := GetGLEntryNo(DocumentRecordRef);
        AttachmentId := CreateAttachment(DocumentRecordRef);
        Commit();

        // [WHEN] The user makes a DELETE request to the endpoint for the Attachment.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithTwoKeyFields(
            Format(GLEntryNo), AttachmentId, PAGE::"G/L Entry Attachments Entity", GLEntryAttachmentServiceNameTxt);
        LibraryGraphMgt.DeleteFromWebService(TargetURL, '', ResponseText);

        // [THEN] The response is empty.
        Assert.AreEqual('', ResponseText, 'DELETE response should be empty.');

        // [THEN] The Attachment is no longer in the database.
        IncomingDocumentAttachment.SetRange(Id, AttachmentId);
        Assert.IsFalse(IncomingDocumentAttachment.FindFirst, 'The attachment should be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTransferAttachmentFromDraftToPostedInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        DocumentRecordRef: RecordRef;
        DocumentId: Guid;
        AttachmentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The Attachment is transferred from a Draft Invoice the to Posted Invoice after posting.
        // [GIVEN] A draft sales invoice exists.
        CreateDraftSalesInvoice(DocumentRecordRef);
        DocumentId := GetDocumentId(DocumentRecordRef);

        // [GIVEN] An attacment is linked to the draft invoice.
        AttachmentId := CreateAttachment(DocumentRecordRef);
        Commit();

        // [WHEN] The invoice is posted through the Invoices API.
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(DocumentId, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt, ActionPostTxt);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 204);

        // [THEN] The Attachment exists and is correctly linked to the posted invoice.
        IncomingDocumentAttachment.SetRange(Id, AttachmentId);
        IncomingDocumentAttachment.FindFirst;
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", DocumentId);
        SalesInvoiceHeader.FindFirst;
        DocumentRecordRef.GetTable(SalesInvoiceHeader);
        FindIncomingDocument(DocumentRecordRef, IncomingDocument);
        Assert.AreEqual(SalesInvoiceHeader."No.", IncomingDocument."Document No.", 'Wrong Document No.');
        Assert.AreEqual(IncomingDocument."Document Type", IncomingDocument."Document Type"::"Sales Invoice", 'Wrong Document Type.');
        Assert.AreEqual(SalesInvoiceHeader.RecordId, IncomingDocument."Related Record ID", 'Wrong Related Record ID.');
        Assert.AreEqual(IncomingDocument."Entry No.", IncomingDocumentAttachment."Incoming Document Entry No.", 'Wrong Entry No.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTransferAttachmentFromDraftToPostedPurchaseInvoice()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        DocumentRecordRef: RecordRef;
        DocumentId: Guid;
        AttachmentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The Attachment is transferred from a Draft Invoice the to Posted Invoice after posting.
        // [GIVEN] A draft sales invoice exists.
        CreateDraftPurchaseInvoice(DocumentRecordRef);
        DocumentId := GetDocumentId(DocumentRecordRef);

        // [GIVEN] An attacment is linked to the draft invoice.
        AttachmentId := CreateAttachment(DocumentRecordRef);
        Commit();

        // [WHEN] The invoice is posted through the Invoices API.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            DocumentId, PAGE::"Purchase Invoice Entity", PurchaseInvoiceServiceNameTxt, ActionPostTxt);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 204);

        // [THEN] The Attachment exists and is correctly linked to the posted invoice.
        IncomingDocumentAttachment.SetRange(Id, AttachmentId);
        IncomingDocumentAttachment.FindFirst;
        PurchInvHeader.SetRange("Draft Invoice SystemId", DocumentId);
        PurchInvHeader.FindFirst;
        DocumentRecordRef.GetTable(PurchInvHeader);
        FindIncomingDocument(DocumentRecordRef, IncomingDocument);
        Assert.AreEqual(PurchInvHeader."No.", IncomingDocument."Document No.", 'Wrong Document No.');
        Assert.AreEqual(IncomingDocument."Document Type", IncomingDocument."Document Type"::"Purchase Invoice", 'Wrong Document Type.');
        Assert.AreEqual(PurchInvHeader.RecordId, IncomingDocument."Related Record ID", 'Wrong Related Record ID.');
        Assert.AreEqual(IncomingDocument."Entry No.", IncomingDocumentAttachment."Incoming Document Entry No.", 'Wrong Entry No.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLinkedAttachmentFileNameChangeKeepsOtherFieldsUnchanged()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        DocumentRecordRef: RecordRef;
        DocumentId: Guid;
        AttachmentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
        JSONBody: Text;
        FileName: Text;
        OldBase64Content: Text;
        NewBase64Content: Text;
    begin
        // [SCENARIO] Changing an attachment file name keeps other fields unchanged
        // [GIVEN] A sales quote exists.
        CreateSalesQuote(DocumentRecordRef);
        DocumentId := GetDocumentId(DocumentRecordRef);

        // [GIVEN] A linked attachment exists.
        AttachmentId := CreateAttachment(DocumentRecordRef);
        IncomingDocumentAttachment.SetRange(Id, AttachmentId);
        IncomingDocumentAttachment.FindFirst;
        OldBase64Content := GetAttachmentBase64Content(IncomingDocumentAttachment);
        Commit();

        // [WHEN] The user changes the attachment file name by making a PATCH request
        FileName := StrSubstNo('%1.txt', FormatGuid(CreateGuid));
        JSONBody := StrSubstNo('{"fileName":"%1"}', FileName);
        TargetURL := LibraryGraphMgt.CreateTargetURLWithTwoKeyFields(
            DocumentId, AttachmentId, PAGE::"Attachments Entity", AttachmentServiceNameTxt);
        LibraryGraphMgt.PatchToWebService(TargetURL, JSONBody, ResponseText);

        // [THEN] The response text contains the new file name, other fields are not changed.
        VerifyPropertyInJSON(ResponseText, 'fileName', FileName);
        LibraryGraphMgt.VerifyGUIDFieldInJson(ResponseText, 'parentId', DocumentId);

        // [THEN] The attachment content is not changed.
        IncomingDocumentAttachment.SetRange(Id, AttachmentId);
        IncomingDocumentAttachment.FindFirst;
        NewBase64Content := GetAttachmentBase64Content(IncomingDocumentAttachment);
        Assert.AreEqual(OldBase64Content, NewBase64Content, 'Attachment content has been changed.');

        // [THEN] The response matches the attachment record in the database.
        VerifyAttachmentProperties(ResponseText, IncomingDocumentAttachment, NewBase64Content);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLinkedAttachmentContentChangeKeepsOtherFieldsUnchanged()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecordRef: RecordRef;
        DocumentId: Guid;
        AttachmentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
        OldFileName: Text;
        NewFileName: Text;
    begin
        // [SCENARIO] Changing an attachment content keeps other fields unchanged
        // [GIVEN] A draft sales invoice exists.
        CreateDraftSalesInvoice(DocumentRecordRef);
        DocumentId := GetDocumentId(DocumentRecordRef);

        // [GIVEN] A linked attachment exists.
        AttachmentId := CreateAttachment(DocumentRecordRef);
        IncomingDocumentAttachment.SetRange(Id, AttachmentId);
        IncomingDocumentAttachment.FindFirst;
        OldFileName := NameAndExtensionToFileName(IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension");
        TempBlob.FromRecord(IncomingDocumentAttachment, IncomingDocumentAttachment.FieldNo(Content));
        Commit();

        // [WHEN] The user changes the attachment content by making a PATCH request
        TargetURL := LibraryGraphMgt.CreateTargetURLWithTwoKeyFieldsAndSubpage(
            DocumentId, AttachmentId, PAGE::"Attachments Entity", AttachmentServiceNameTxt, 'content');
        LibraryGraphMgt.BinaryUpdateToWebServiceAndCheckResponseCode(TargetURL, TempBlob, 'PATCH', ResponseText, 204);

        // [THEN] The attachment name is not changed in the database.
        IncomingDocumentAttachment.SetRange(Id, AttachmentId);
        IncomingDocumentAttachment.FindFirst;
        NewFileName := NameAndExtensionToFileName(IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension");
        Assert.AreEqual(OldFileName, NewFileName, 'Attachment file name has been changed.');

        // [THEN] The attachment remains linked to the correct document.
        DocumentRecordRef.Find;
        FindIncomingDocument(DocumentRecordRef, IncomingDocument);
        Assert.AreEqual(DocumentRecordRef.RecordId, IncomingDocument."Related Record ID", 'The attachment is linked to a wrong document.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLinkedAttachmentIdChangeNotAllowed()
    var
        DocumentRecordRef: RecordRef;
        AttachmentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
        JSONBody: Text;
    begin
        // [SCENARIO] User cannot change the linked attachment ID by making a PATCH request to the Attachments API
        // [GIVEN] A sales quote exists.
        CreateSalesQuote(DocumentRecordRef);

        // [GIVEN] A linked attachment exists.
        AttachmentId := CreateAttachment(DocumentRecordRef);
        Commit();

        // [WHEN] The user changes the attachment ID by making a PATCH request
        TargetURL := LibraryGraphMgt.CreateTargetURLWithTwoKeyFields(
            GetDocumentId(DocumentRecordRef), AttachmentId, PAGE::"Attachments Entity", AttachmentServiceNameTxt);
        JSONBody := StrSubstNo('{"id":"%1"}', FormatGuid(CreateGuid));
        asserterror LibraryGraphMgt.PatchToWebService(TargetURL, JSONBody, ResponseText);

        // [THEN] Cannot change the attchment ID, expect error 400
        Assert.ExpectedError('400');
        Assert.ExpectedError(CannotChangeIDErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLinkedAttachmentDocumentIdChangeNotAllowed()
    var
        DocumentRecordRef: array[2] of RecordRef;
        DocumentId: array[2] of Guid;
        AttachmentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
        JSONBody: Text;
    begin
        // [SCENARIO] User cannot change the attachment ID by making a PATCH request to the Attachments API
        // [GIVEN] Two documents exist.
        CreateSalesQuote(DocumentRecordRef[1]);
        CreateDraftSalesInvoice(DocumentRecordRef[2]);
        DocumentId[1] := GetDocumentId(DocumentRecordRef[1]);
        DocumentId[2] := GetDocumentId(DocumentRecordRef[2]);

        // [GIVEN] An attachment is linked to the first document.
        AttachmentId := CreateAttachment(DocumentRecordRef[1]);
        Commit();

        // [WHEN] The user changes the document ID by making a PATCH request
        TargetURL := LibraryGraphMgt.CreateTargetURLWithTwoKeyFields(
            DocumentId[1], AttachmentId, PAGE::"Attachments Entity", AttachmentServiceNameTxt);
        JSONBody := StrSubstNo('{"parentId":"%1"}', FormatGuid(DocumentId[2]));
        asserterror LibraryGraphMgt.PatchToWebService(TargetURL, JSONBody, ResponseText);

        // [THEN] Cannot change the document ID, expect error 400
        Assert.ExpectedError('400');
        Assert.ExpectedError(StrSubstNo(CannotModifyKeyFieldErr, 'parentId'));
    end;

    local procedure CreateDraftSalesInvoice(var DocumentRecordRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        DocumentRecordRef.GetTable(SalesHeader);
    end;

    local procedure CreatePostedSalesInvoice(var DocumentRecordRef: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        InvoiceCode: Code[20];
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        InvoiceCode := LibrarySales.PostSalesDocument(SalesHeader, false, true);
        SalesInvoiceHeader.Get(InvoiceCode);
        DocumentRecordRef.GetTable(SalesInvoiceHeader);
    end;

    local procedure CreateDraftPurchaseInvoice(var DocumentRecordRef: RecordRef)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        DocumentRecordRef.GetTable(PurchaseHeader);
    end;

    local procedure CreatePostedPurchaseInvoice(var DocumentRecordRef: RecordRef)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        InvoiceCode: Code[20];
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        InvoiceCode := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        PurchInvHeader.Get(InvoiceCode);
        DocumentRecordRef.GetTable(PurchInvHeader);
    end;

    local procedure CreateSalesQuote(var DocumentRecordRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateSalesQuoteHeader(SalesHeader, Customer);
        DocumentRecordRef.GetTable(SalesHeader);
    end;

    local procedure CreateGenJournalLine(var DocumentRecordRef: RecordRef)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", 1);
        DocumentRecordRef.GetTable(GenJournalLine);
    end;

    local procedure CreateGLEntry(var DocumentRecordRef: RecordRef)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
    begin
        LibraryERM.CreateAndPostTwoGenJourLinesWithSameBalAccAndDocNo(GenJournalLine,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting, 1);
        GLEntry.SetCurrentKey("Entry No.");
        GLEntry.SetAscending("Entry No.", false);
        GLEntry.FindFirst;
        DocumentRecordRef.GetTable(GLEntry);
    end;

    local procedure CreateAttachments(var DocumentRecordRef: RecordRef; var AttachmentId: array[2] of Guid)
    var
        "Count": Integer;
    begin
        for Count := 1 to 2 do
            AttachmentId[Count] := CreateAttachment(DocumentRecordRef);
    end;

    local procedure GetDocumentId(var DocumentRecordRef: RecordRef): Guid
    var
        DummySalesHeader: Record "Sales Header";
        DataTypeManagement: Codeunit "Data Type Management";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        IdFieldRef: FieldRef;
        Id: Guid;
    begin
        case DocumentRecordRef.Number of
            database::"Sales Invoice Header":
                begin
                    DocumentRecordRef.SetTable(SalesInvoiceHeader);
                    exit(SalesInvoiceHeader."Draft Invoice SystemId");
                end;
            Database::"Purch. Inv. Header":
                begin
                    DocumentRecordRef.SetTable(PurchInvHeader);
                    exit(PurchInvHeader."Draft Invoice SystemId");
                end;
            Database::"Gen. Journal Line":
                begin
                    Evaluate(Id, Format(DocumentRecordRef.Field(DocumentRecordRef.SystemIdNo()).Value()));
                    exit(Id);
                end;
        end;

        if DataTypeManagement.FindFieldByName(DocumentRecordRef, IdFieldRef, DummySalesHeader.FieldName(Id)) then
            Evaluate(Id, Format(IdFieldRef.Value));
        exit(Id);
    end;

    local procedure GetGLEntryNo(var DocumentRecordRef: RecordRef): Integer
    var
        DummyGLEntry: Record "G/L Entry";
        DataTypeManagement: Codeunit "Data Type Management";
        EntryNoFieldRef: FieldRef;
        EntryNo: Integer;
    begin
        if DataTypeManagement.FindFieldByName(DocumentRecordRef, EntryNoFieldRef, DummyGLEntry.FieldName("Entry No.")) then
            Evaluate(EntryNo, Format(EntryNoFieldRef.Value));
        exit(EntryNo);
    end;

    local procedure IsPostedDocument(var DocumentRecordRef: RecordRef): Boolean
    begin
        exit(
          (DocumentRecordRef.Number = DATABASE::"Sales Invoice Header") or (DocumentRecordRef.Number = DATABASE::"Purch. Inv. Header"));
    end;

    local procedure IsGeneralJournalLine(var DocumentRecordRef: RecordRef): Boolean
    begin
        exit(DocumentRecordRef.Number = DATABASE::"Gen. Journal Line");
    end;

    local procedure IsPurchaseInvoice(var DocumentRecordRef: RecordRef): Boolean
    begin
        if DocumentRecordRef.Number = DATABASE::"Purch. Inv. Header" then
            exit(true);
        if DocumentRecordRef.Number = DATABASE::"Purchase Header" then
            exit(true);
        exit(false);
    end;

    local procedure IsGLEntry(var DocumentRecordRef: RecordRef): Boolean
    begin
        exit(DocumentRecordRef.Number = DATABASE::"G/L Entry");
    end;

    local procedure FindIncomingDocument(var DocumentRecordRef: RecordRef; var IncomingDocument: Record "Incoming Document"): Boolean
    begin
        if IsPostedDocument(DocumentRecordRef) or IsGLEntry(DocumentRecordRef) then
            exit(IncomingDocument.FindByDocumentNoAndPostingDate(DocumentRecordRef, IncomingDocument));
        exit(IncomingDocument.FindFromIncomingDocumentEntryNo(DocumentRecordRef, IncomingDocument));
    end;

    local procedure FindOrCreateIncomingDocument(var DocumentRecordRef: RecordRef; var IncomingDocument: Record "Incoming Document"): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        if FindIncomingDocument(DocumentRecordRef, IncomingDocument) then
            exit(true);

        IncomingDocument.Init();
        IncomingDocument."Related Record ID" := DocumentRecordRef.RecordId;

        if DocumentRecordRef.Number = DATABASE::"Sales Invoice Header" then begin
            DocumentRecordRef.SetTable(SalesInvoiceHeader);
            IncomingDocument.Description := CopyStr(SalesInvoiceHeader."Sell-to Customer Name", 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Sales Invoice";
            IncomingDocument."Document No." := SalesInvoiceHeader."No.";
            IncomingDocument."Posting Date" := SalesInvoiceHeader."Posting Date";
            IncomingDocument.Insert(true);
            IncomingDocument.Find;
            exit(true);
        end;

        if IsGeneralJournalLine(DocumentRecordRef) then begin
            DocumentRecordRef.SetTable(GenJournalLine);
            IncomingDocument.Description := CopyStr(GenJournalLine.Description, 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::Journal;
            IncomingDocument.Insert(true);
            GenJournalLine."Incoming Document Entry No." := IncomingDocument."Entry No.";
            GenJournalLine.Modify();
            DocumentRecordRef.GetTable(GenJournalLine);
            exit(true);
        end;

        if IsGLEntry(DocumentRecordRef) then begin
            DocumentRecordRef.SetTable(GLEntry);
            IncomingDocument.Description := CopyStr(GLEntry.Description, 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document No." := GLEntry."Document No.";
            IncomingDocument."Posting Date" := GLEntry."Posting Date";
            IncomingDocument.Status := IncomingDocument.Status::Posted;
            IncomingDocument.Posted := true;
            IncomingDocument.Insert(true);
            exit(true);
        end;

        if DocumentRecordRef.Number = DATABASE::"Sales Header" then begin
            DocumentRecordRef.SetTable(SalesHeader);
            IncomingDocument.Description := CopyStr(SalesHeader."Sell-to Customer Name", 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Sales Invoice";
            IncomingDocument."Document No." := SalesHeader."No.";
            IncomingDocument.Insert(true);
            IncomingDocument.Find;
            SalesHeader.Find;
            SalesHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
            SalesHeader.Modify();
            DocumentRecordRef.GetTable(SalesHeader);
            exit(true);
        end;

        if IsPurchaseInvoice(DocumentRecordRef) and IsPostedDocument(DocumentRecordRef) then begin
            DocumentRecordRef.SetTable(PurchInvHeader);
            IncomingDocument.Description := CopyStr(PurchInvHeader."Buy-from Vendor Name", 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Purchase Invoice";
            IncomingDocument."Document No." := PurchInvHeader."No.";
            IncomingDocument."Posting Date" := PurchInvHeader."Posting Date";
            IncomingDocument."Posted Date-Time" := CurrentDateTime;
            IncomingDocument.Status := IncomingDocument.Status::Posted;
            IncomingDocument.Posted := true;
            IncomingDocument.Insert(true);
            exit(true);
        end;

        if DocumentRecordRef.Number = DATABASE::"Purchase Header" then begin
            DocumentRecordRef.SetTable(PurchaseHeader);
            IncomingDocument.Description := CopyStr(PurchaseHeader."Buy-from Vendor Name", 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Purchase Invoice";
            IncomingDocument."Document No." := PurchaseHeader."No.";
            IncomingDocument.Insert(true);
            PurchaseHeader.Find;
            PurchaseHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
            PurchaseHeader.Modify();
            DocumentRecordRef.GetTable(PurchaseHeader);
            exit(true);
        end;
    end;

    local procedure CreateAttachment(var DocumentRecordRef: RecordRef): Guid
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        if not FindOrCreateIncomingDocument(DocumentRecordRef, IncomingDocument) then
            Error(CreateIncomingDocumentErr);

        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);
        IncomingDocumentAttachment.Insert(true);
        exit(IncomingDocumentAttachment.Id);
    end;

    local procedure CreateIncomingDocumentAttachment(var IncomingDocument: Record "Incoming Document"; var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        LastUsedIncomingDocumentAttachment: Record "Incoming Document Attachment";
        OutStream: OutStream;
        LineNo: Integer;
    begin
        LastUsedIncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        if not LastUsedIncomingDocumentAttachment.FindLast then
            LineNo := 10000
        else
            LineNo := LastUsedIncomingDocumentAttachment."Line No." + 10000;

        IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment."Incoming Document Entry No." := IncomingDocument."Entry No.";
        IncomingDocumentAttachment."Line No." := LineNo;
        IncomingDocumentAttachment.Name :=
          CopyStr(FormatGuid(CreateGuid), 1, MaxStrLen(IncomingDocumentAttachment.Name));
        IncomingDocumentAttachment.Type := IncomingDocumentAttachment.Type::Other;
        IncomingDocumentAttachment."File Extension" := 'txt';
        IncomingDocumentAttachment.Content.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(FormatGuid(CreateGuid));
    end;

    [Normal]
    local procedure GetAndVerifyIDFromJSON(ResponseText: Text; Id: array[2] of Guid)
    var
        JSON: array[2] of Text;
    begin
        Assert.IsTrue(
          LibraryGraphMgt
          .GetObjectsFromJSONResponse(
            ResponseText, 'id', FormatGuid(Id[1]), FormatGuid(Id[2]), JSON[1], JSON[2]),
          'Could not find the Attachment in JSON');
    end;

    local procedure GetAttachmentJSON(DocumentId: Guid; var IncomingDocumentAttachment: Record "Incoming Document Attachment"; IncludeID: Boolean) AttachmentJSON: Text
    var
        TempBlob: Codeunit "Temp Blob";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        FileName: Text;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);
        TempBlob.FromRecord(IncomingDocumentAttachment, IncomingDocumentAttachment.FieldNo(Content));
        JSONManagement.AddJPropertyToJObject(JsonObject, 'parentId', FormatGuid(DocumentId));

        if IncludeID then
            JSONManagement.AddJPropertyToJObject(JsonObject, 'id', FormatGuid(IncomingDocumentAttachment.Id));

        FileName := NameAndExtensionToFileName(IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension");
        JSONManagement.AddJPropertyToJObject(JsonObject, 'fileName', FileName);
        AttachmentJSON := JSONManagement.WriteObjectToString;
    end;

    local procedure GetGLEntryAttachmentJSON(GLEntryNo: Integer; var IncomingDocumentAttachment: Record "Incoming Document Attachment"; IncludeID: Boolean) AttachmentJSON: Text
    var
        TempBlob: Codeunit "Temp Blob";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        FileName: Text;
    begin
        JSONManagement.InitializeEmptyObject;
        JSONManagement.GetJSONObject(JsonObject);
        TempBlob.FromRecord(IncomingDocumentAttachment, IncomingDocumentAttachment.FieldNo(Content));
        JSONManagement.AddJPropertyToJObject(JsonObject, 'generalLedgerEntryNumber', Format(GLEntryNo));

        if IncludeID then
            JSONManagement.AddJPropertyToJObject(JsonObject, 'id', FormatGuid(IncomingDocumentAttachment.Id));

        FileName := NameAndExtensionToFileName(IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension");
        JSONManagement.AddJPropertyToJObject(JsonObject, 'fileName', FileName);
        AttachmentJSON := JSONManagement.WriteObjectToString;
    end;

    local procedure GetAttachmentBase64Content(var IncomingDocumentAttachment: Record "Incoming Document Attachment") Base64Content: Text
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob.FromRecord(IncomingDocumentAttachment, IncomingDocumentAttachment.FieldNo(Content));
        Base64Content := BlobToBase64String(TempBlob);
    end;

    local procedure VerifyPropertyInJSON(JSON: Text; PropertyName: Text; ExpectedValue: Text)
    var
        PropertyValue: Text;
    begin
        LibraryGraphMgt.GetObjectIDFromJSON(JSON, PropertyName, PropertyValue);
        Assert.AreEqual(ExpectedValue, PropertyValue, StrSubstNo(WrongPropertyValueErr, PropertyName));
    end;

    local procedure VerifyAttachmentProperties(AttachmentJSON: Text; var IncomingDocumentAttachment: Record "Incoming Document Attachment"; ExpectedBase64Content: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
    begin
        Assert.AreNotEqual('', AttachmentJSON, EmptyJSONErr);
        if not IsNullGuid(IncomingDocumentAttachment.Id) then
            LibraryGraphMgt.VerifyGUIDFieldInJson(AttachmentJSON, 'id', IncomingDocumentAttachment.Id);
        FileName := NameAndExtensionToFileName(IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension");
        VerifyPropertyInJSON(AttachmentJSON, 'fileName', FileName);
        TempBlob.FromRecord(IncomingDocumentAttachment, IncomingDocumentAttachment.FieldNo(Content));
        VerifyPropertyInJSON(AttachmentJSON, 'byteSize', Format(TempBlob.Length, 0, 9));
        if ExpectedBase64Content <> '' then
            Assert.AreEqual(ExpectedBase64Content, GetAttachmentBase64Content(IncomingDocumentAttachment), 'Wrong content.');
    end;

    local procedure FormatGuid(Value: Guid): Text
    begin
        exit(LowerCase(LibraryGraphMgt.StripBrackets(Format(Value, 0, 9))));
    end;

    local procedure GenerateRandomBinaryContent(var TempBlob: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(FormatGuid(CreateGuid));
    end;

    local procedure BlobToBase64String(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InStream: InStream;
        Convert: DotNet Convert;
        MemoryStream: DotNet MemoryStream;
        Base64String: Text;
    begin
        if not TempBlob.HasValue then
            exit('');
        TempBlob.CreateInStream(InStream);
        MemoryStream := MemoryStream.MemoryStream;
        CopyStream(MemoryStream, InStream);
        Base64String := Convert.ToBase64String(MemoryStream.ToArray);
        MemoryStream.Close;
        exit(Base64String);
    end;

    local procedure CreateAttachmentsURLWithFilter(DocumentIdFilter: Guid): Text
    var
        TargetURL: Text;
        UrlFilter: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Attachments Entity", AttachmentServiceNameTxt);

        UrlFilter := '$filter=parentId eq ' + LibraryGraphMgt.StripBrackets(Format(DocumentIdFilter));

        if StrPos(TargetURL, '?') <> 0 then
            TargetURL := TargetURL + '&' + UrlFilter
        else
            TargetURL := TargetURL + '?' + UrlFilter;

        exit(TargetURL);
    end;

    local procedure CreateGLEntryAttachmentsURLWithFilter(GLEntryNoFilter: Text): Text
    var
        TargetURL: Text;
        UrlFilter: Text;
    begin
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"G/L Entry Attachments Entity", GLEntryAttachmentServiceNameTxt);

        UrlFilter := '$filter=generalLedgerEntryNumber eq ' + GLEntryNoFilter;

        if StrPos(TargetURL, '?') <> 0 then
            TargetURL += '&' + UrlFilter
        else
            TargetURL += '?' + UrlFilter;

        exit(TargetURL);
    end;

    local procedure NameAndExtensionToFileName(Name: Text[250]; Extension: Text[30]): Text[250]
    begin
        if Extension <> '' then
            exit(StrSubstNo('%1.%2', Name, Extension));
        exit(Name);
    end;
}

