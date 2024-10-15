codeunit 134776 "Document Attachment Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Document attachment feature test for TAB1173 / COD1173]
        // Call Init and tear down for every unit test, in that way we clean up data on each test run.
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryJob: Codeunit "Library - Job";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ReportSelectionUsage: Enum "Report Selection Usage";
        RecallNotifications: Boolean;
        NoContentErr: Label 'The selected file has no content. Please choose another file.';
        DuplicateErr: Label 'This file is already attached to the document. Please choose another file.';
        PrintedToAttachmentTxt: Label 'The document has been printed to attachments.';
        NoSaveToPDFReportTxt: Label 'There are no reports which could be saved to PDF for this document.';
        isInitialized: Boolean;
        ConfirmConvertToOrderQst: Label 'Do you want to convert the quote to an order?';
        DeleteAttachmentsConfirmQst: Label 'Do you want to delete the attachments for this document?';
        ConfirmOpeningNewOrderAfterQuoteToOrderQst: Label 'Do you want to open the new order?';
        AttachedDateInvalidErr: Label 'Attached date is invalid';

    [Test]
    [Scope('OnPrem')]
    procedure EnsureSaveAttachmentErrorWhenFileHasNoContent()
    var
        Customer: Record Customer;
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Test save attachment function (TAB1173) on empty file name.

        // [GIVEN] Empty file [content is empty]
        // [WHEN] Save attachment function is called
        // [THEN] No content error happens.
        // Initialize
        Initialize();
        DocumentAttachment.Init();

        RecRef.GetTable(Customer);

        CreateTempBLOBWithText(TempBlob, '');
        asserterror DocumentAttachment.SaveAttachment(RecRef, 'EmptyFile.txt', TempBlob);
        Assert.ExpectedError(NoContentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureSaveAttachmentOfTypeImage()
    var
        Customer: Record Customer;
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Test save attachment function (TAB1173) on an file type of image.

        // [GIVEN] Image file
        // [WHEN] Save attachment function is called
        // [THEN] No errors. Verfiy document attachment properties on sucessful save
        // Initialize
        Initialize();
        DocumentAttachment.Init();

        RecRef.GetTable(Customer);

        CreateTempBLOBWithImageOfType(TempBlob, 'jpeg');
        DocumentAttachment.SaveAttachment(RecRef, 'image.jpeg', TempBlob);

        // Verify FileType is set to image
        Assert.AreEqual('Image', Format(DocumentAttachment."File Type"::Image), 'File type is not equal to image.');

        // Verify user security id
        Assert.AreEqual(UserSecurityId(), DocumentAttachment."Attached By", 'AttachedBy is not eqal to USERSECURITYID');

        // Verify file type
        Assert.AreEqual(1, DocumentAttachment."File Type", 'File type is not image.');

        // Verify file name
        Assert.AreEqual('image', DocumentAttachment."File Name", 'File name is not image.');

        // Verify table ID
        Assert.AreEqual(DATABASE::Customer, DocumentAttachment."Table ID", Format('Table Id does not match with %1', DATABASE::Customer));

        // Verify record no
        Assert.AreEqual(Customer."No.", DocumentAttachment."No.", 'No. does not match with' + Customer."No.");

        // Verify attached date
        Assert.IsTrue(DocumentAttachment."Attached Date" > 0DT, 'Missing attach date');

        // Verify doc ref id is not null
        Assert.IsTrue(DocumentAttachment."Document Reference ID".HasValue, 'Document reference ID is null.');

        // Verify doc flow
        Assert.IsFalse(DocumentAttachment."Document Flow Sales", 'Document flow Sales is true.');

        Assert.IsFalse(DocumentAttachment."Document Flow Service", 'Document flow Service is true.');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RelatedAttachmentsHandler,CloseEmailEditorHandler')]
    procedure EnsureRelatedAttachmentIsFound()
    var
        DocumentAttachment: Record "Document Attachment";
        PurchaseHeader: Record "Purchase Header";
        Email: Codeunit Email;
        EmailMessage: Codeunit "Email Message";
        RecRef: RecordRef;
        EmailEditorPage: TestPage "Email Editor";
    begin
        // [SCENARIO] Ensure that event OnFindRelatedAttachments finds the related attachment

        // [GIVEN] A purchase order exists with a vendor no and an attachment
        Initialize();
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        RecRef.GetTable(PurchaseHeader);
        CreateDocumentAttachment(DocumentAttachment, RecRef, 'foo.jpeg');

        // [GIVEN] The purchase order is added to an email as a related source
        EmailMessage.Create('', '', '', true);
        Email.SaveAsDraft(EmailMessage);
        Email.AddRelation(EmailMessage, DATABASE::"Purchase Header", PurchaseHeader.SystemId, Enum::"Email Relation Type"::"Primary Source", Enum::"Email Relation Origin"::"Compose Context");

        // [WHEN] Opening the Email Related Attachments page
        EmailEditorPage.Trap();
        Email.OpenInEditor(EmailMessage);
        EmailEditorPage.Attachments.SourceAttachments.Invoke();

        // [THEN] The Email Related Attachments page contains the attachment from the purchase order (verified in RelatedAttachmentsHandler)
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RelatedAttachmentsHandler,CloseEmailEditorHandler')]
    procedure EnsureRelatedAttachmentIsFoundWithDuplicateNumber()
    var
        DocumentAttachment: Record "Document Attachment";
        PurchaseHeader: Record "Purchase Header";
        LocalVendor: Record Vendor;
        Email: Codeunit Email;
        EmailMessage: Codeunit "Email Message";
        RecRef: RecordRef;
        EmailEditorPage: TestPage "Email Editor";
    begin
        // [SCENARIO] Ensure that event OnFindRelatedAttachments finds the correct attachment when the No. of two records are the same.

        // [GIVEN] A purchase order exists with a vendor no and an attachment
        Initialize();
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        RecRef.GetTable(PurchaseHeader);
        CreateDocumentAttachment(DocumentAttachment, RecRef, 'foo.jpeg');

        // [GIVEN] A vendor with the same No. and an attachment
        LocalVendor.Init();
        LocalVendor."No." := PurchaseHeader."No.";
        LocalVendor.Insert();

        RecRef.GetTable(LocalVendor);
        CreateDocumentAttachment(DocumentAttachment, RecRef, 'bar.jpeg');

        // [GIVEN] The purchase order is added to an email as a related source
        EmailMessage.Create('', '', '', true);
        Email.SaveAsDraft(EmailMessage);
        Email.AddRelation(EmailMessage, DATABASE::"Purchase Header", PurchaseHeader.SystemId, Enum::"Email Relation Type"::"Primary Source", Enum::"Email Relation Origin"::"Compose Context");

        // [WHEN] Opening the Email Related Attachments page
        EmailEditorPage.Trap();
        Email.OpenInEditor(EmailMessage);
        EmailEditorPage.Attachments.SourceAttachments.Invoke();

        // [THEN] The Email Related Attachments page only contains the attachment from the purchase order (verified in RelatedAttachmentsHandler)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureDuplicateFileWithSameNameAndExtIsNotSavedIfDisabled()
    var
        Customer: Record Customer;
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Ensure duplicate file name with same extension is not saved if duplicates are disabled. For example saving 'test.jpeg' twice is NOT allowed.

        // [GIVEN] Two Image files
        // [WHEN] Save attachment function is called twice
        // [THEN] Duplicate file error is shown.
        // Initialize
        Initialize();
        DocumentAttachment.Init();
        CreateTempBLOBWithImageOfType(TempBlob, 'jpeg');

        RecRef.GetTable(Customer);

        // Save first time
        DocumentAttachment.SaveAttachment(RecRef, 'test.jpeg', TempBlob);

        // Save second time
        asserterror DocumentAttachment.SaveAttachment(RecRef, 'test.jpeg', TempBlob, false);
        Assert.ExpectedError(DuplicateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureDuplicateFileWithSameNameAndExtIsSavedIfEnabled()
    var
        Customer: Record Customer;
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachment2: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Ensure duplicate file name with same extension is saved if duplicates are enabled. For example saving 'test.jpeg' a second time should rename the filename to 'test (1).jpeg'.

        // [GIVEN] Two Image files
        // [WHEN] Save attachment function is called twice
        // [THEN] Second attachment has been renamed.
        // Initialize
        Initialize();
        DocumentAttachment.DeleteAll();
        DocumentAttachment.Init();
        DocumentAttachment2.Init();
        CreateTempBLOBWithImageOfType(TempBlob, 'jpeg');

        RecRef.GetTable(Customer);

        // Save first attachment
        DocumentAttachment.SaveAttachment(RecRef, 'test.jpeg', TempBlob);

        // Save second attachment
        DocumentAttachment2.SaveAttachment(RecRef, 'test.jpeg', TempBlob);

        // Only two attachments exists
        Assert.AreEqual(2, DocumentAttachment.Count(), 'There does not exist exactly two attachments.');

        // First attachment has original name
        DocumentAttachment.SetRange("File Name", 'test');
        Assert.IsTrue(DocumentAttachment.FindFirst(), 'No attachment with the original filename exists.');

        // Second attachment has been renamed to 'test (1).jpeg'
        DocumentAttachment.SetRange("File Name", 'test (1)');
        Assert.IsTrue(DocumentAttachment.FindFirst(), 'No attachment with the renamed filename exists.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureDuplicateFileWithSameNameAndDifferentExtSaved()
    var
        Customer: Record Customer;
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Ensure duplicate file name with same name but different extension saved. For example saving 'test.jpeg' and 'test.png' should be allowed.

        // [GIVEN] Two Image files
        // [WHEN] Save attachment function is called twice
        // [THEN] Both files are saved.
        // Initialize
        Initialize();
        DocumentAttachment.Init();

        RecRef.GetTable(Customer);

        CreateTempBLOBWithImageOfType(TempBlob, 'jpeg');

        // Save first file (test.jpeg)
        DocumentAttachment.SaveAttachment(RecRef, 'test.jpeg', TempBlob);
        Clear(DocumentAttachment);

        // Create and save a png file (test.png)
        DocumentAttachment.Init();
        CreateTempBLOBWithImageOfType(TempBlob, 'png');
        DocumentAttachment.SaveAttachment(RecRef, 'test.png', TempBlob);
        Clear(DocumentAttachment);

        DocumentAttachment.SetRange("Table ID", DATABASE::Customer);
        DocumentAttachment.SetRange("No.", Customer."No.");
        DocumentAttachment.SetRange("File Name", 'test');

        // Assert there are 2 files saved
        Assert.AreEqual(2, DocumentAttachment.Count, 'Duplicate file with same name but different extension was not saved.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureAttachDocDeletedWhenVendorIsDeleted()
    var
        DocumentAttachment: Record "Document Attachment";
        localVendor: Record Vendor;
        RecRef: RecordRef;
    begin
        // [SCENARIO] Ensure attached documents for a vendor can be deleted.
        // [GIVEN] Two attached documents for a vendor
        // [WHEN] DeleteDocAttachments is called on COD1173
        // [THEN] All the attached documents are deleted for vendor.
        // Initialize
        Initialize();
        localVendor.Init();
        localVendor."No." := '22';
        localVendor.Insert();

        RecRef.GetTable(localVendor);
        CreateDocumentAttachment(DocumentAttachment, RecRef, 'foo.jpeg');
        CreateDocumentAttachment(DocumentAttachment, RecRef, 'bar.jpeg');

        DocumentAttachment.SetRange("Table ID", DATABASE::Vendor);
        DocumentAttachment.SetRange("No.", localVendor."No.");

        // Assert there are 2 files saved
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');

        // Call delete
        localVendor.Delete();

        // Assert all files for this vendor are deleted.
        Assert.AreEqual(0, DocumentAttachment.Count, 'Zero attachments were expected.');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('QuoteToOrderConfirmHandler')]
    procedure EnsureAttachDocCounterUpdatesWhenQuoteConvertedToOrder()
    var
        Customer: Record Customer;
        SalesHeaderQuote: Record "Sales Header";
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
        SalesQuotes: TestPage "Sales Quotes";
        FinalDocAttachedAcount: Integer;
    begin
        // [SCENARIO] Ensure that Documents Attachment factbox shows blank when quote is converted to order

        Initialize();

        // [GIVEN] Create quote
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeaderQuote, Customer."No.");

        // [GIVEN] Two attached documents for the quote
        RecRef.GetTable(SalesHeaderQuote);
        CreateDocumentAttachment(DocumentAttachment, RecRef, 'foo.jpeg');
        CreateDocumentAttachment(DocumentAttachment, RecRef, 'bar.jpeg');

        // [WHEN] The sales quotes list is open- navigate to the created quote 
        SalesQuotes.OpenView();
        while SalesQuotes."No.".Value() <> SalesHeaderQuote."No." do
            if not SalesQuotes.Next() then
                break;

        // [THEN] The number of attachments is shown as 2
        Assert.AreEqual(2, SalesQuotes."Attached Documents".Documents.AsInteger(), '2 attachments should have been visible.');

        // [WHEN] Quote is converted to order
        SalesQuotes.MakeOrder.Invoke();

        // [THEN] Sales quote selected is a different one
        Assert.AreNotEqual(SalesHeaderQuote."No.", SalesQuotes."No.".Value(), 'Different sales quote selected.');

        // [THEN] The number of attachments is updated
        FinalDocAttachedAcount := 0;
        if SalesQuotes."No.".Value() <> '' then begin
            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Table ID", Database::"Sales Header");
            DocumentAttachment.SetRange("Document Type", SalesHeaderQuote."Document Type"::Quote);
            DocumentAttachment.SetRange("No.", SalesQuotes."No.".Value());
            FinalDocAttachedAcount := DocumentAttachment.Count();
        end;
        Assert.AreEqual(FinalDocAttachedAcount, SalesQuotes."Attached Documents".Documents.AsInteger(), 'Attachments count should match quote.');
    end;

    local procedure CreateDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; RecRef: RecordRef; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        DocumentAttachment.Init();
        CreateTempBLOBWithImageOfType(TempBlob, 'jpeg');
        DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);
        Clear(DocumentAttachment);
    end;

    [Test]
    [HandlerFunctions('ListResourceFlow')]
    [Scope('OnPrem')]
    procedure TestDocAttachResource()
    var
        Resource: Record Resource;
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Ensure that the doc flow fields are hidden for various master records.

        // [GIVEN] A Resource Record.
        // Initialize
        Initialize();
        LibraryResource.CreateResourceNew(Resource);
        RecRef.GetTable(Resource);

        // [WHEN] The DocumentAttachmentDetails window opens.
        // [THEN] 0 flow fields are visible.
        DocumentAttachmentDetails.OpenForRecRef(RecRef);
        DocumentAttachmentDetails.RunModal();
    end;

    [Test]
    [HandlerFunctions('ListItemFlow')]
    [Scope('OnPrem')]
    procedure TestDocAttachItem()
    var
        LocalItem: Record Item;
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Ensure that both doc flow fields are visible for Items.

        // [GIVEN] An Item Record.

        // Initialize
        Initialize();
        LocalItem.Init();
        LocalItem."No." := '2';
        LocalItem.Insert();

        RecRef.GetTable(LocalItem);

        // [WHEN] The DocumentAttachmentDetails window opens.
        // [THEN] 2 flow fields are visible and editable.
        DocumentAttachmentDetails.OpenForRecRef(RecRef);
        DocumentAttachmentDetails.RunModal();

        LocalItem.Delete();
    end;

    [Test]
    [HandlerFunctions('ListSalesFlow')]
    [Scope('OnPrem')]
    procedure TestDocAttachSalesLine()
    var
        LocalSalesLine: Record "Sales Line";
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Ensure that the sales doc flow fields is visible.

        // [GIVEN] A Sales Line record.
        // Initialize
        Initialize();
        LocalSalesLine.Init();
        LocalSalesLine."Document No." := '2';
        LocalSalesLine."Line No." := 1000;
        LocalSalesLine.Insert();

        RecRef.GetTable(LocalSalesLine);

        // [WHEN] The DocumentAttachmentDetails window opens.
        // [THEN] the sales doc flow fields is visible and editable.

        DocumentAttachmentDetails.OpenForRecRef(RecRef);
        DocumentAttachmentDetails.RunModal();

        LocalSalesLine.Delete();
    end;

    [Test]
    [HandlerFunctions('ListPurchFlow')]
    [Scope('OnPrem')]
    procedure TestDocAttachPurchaseLine()
    var
        LocalPurchaseLine: Record "Purchase Line";
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Ensure that the purch doc flow fields is visible.

        // [GIVEN] A Purch Line record.
        // Initialize
        Initialize();
        LocalPurchaseLine.Init();
        LocalPurchaseLine."No." := '2';
        LocalPurchaseLine."Line No." := 1000;
        LocalPurchaseLine.Insert();

        RecRef.GetTable(LocalPurchaseLine);

        // [WHEN] The DocumentAttachmentDetails window opens.
        // [THEN] the purch doc flow fields is visible and editable.
        DocumentAttachmentDetails.OpenForRecRef(RecRef);
        DocumentAttachmentDetails.RunModal();

        LocalPurchaseLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocAttachSalesOrder()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Ensure that documents from the customer/Item flow to the Sales Order.

        // Initialize
        Initialize();

        // [GIVEN] A Customer with two attachments, one marked to flow
        LibrarySales.CreateCustomer(Customer);
        RecRef.GetTable(Customer);

        CreateDocAttach(RecRef, 'cust1.jpeg', false, true);
        CreateDocAttach(RecRef, 'cust2.jpeg', false, false);

        // [GIVEN] An Item with two attacments, one marked to flow
        LibraryInventory.CreateItem(Item);
        RecRef.GetTable(Item);

        CreateDocAttach(RecRef, 'item1.jpeg', false, true);
        CreateDocAttach(RecRef, 'item2.jpeg', false, false);

        // [WHEN] The a sales order is created.
        CreateSalesDoc(SalesHeader, SalesLine, Customer, Item, SalesHeader."Document Type"::Order);

        // [THEN] the sales header has one attachment.
        CheckDocAttachments(DATABASE::"Sales Header", 1, SalesHeader."No.", SalesHeader."Document Type".AsInteger(), 'cust1');

        // [THEN] the sales line has one attachment.
        CheckDocAttachments(DATABASE::"Sales Line", 1, SalesLine."Document No.", SalesLine."Document Type".AsInteger(), 'item1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocAttachPurchaseOrder()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Ensure that documents from the Vendor/Item flow to the Purchase Order.

        // Initialize
        Initialize();

        // [GIVEN] A Vendor with two attachments, one marked to flow
        LibraryPurchase.CreateVendor(Vendor);
        RecRef.GetTable(Vendor);

        CreateDocAttach(RecRef, 'vend1.jpeg', true, true);
        CreateDocAttach(RecRef, 'vend2.jpeg', false, false);

        // [GIVEN] An Item with two attacments, one marked to flow
        LibraryInventory.CreateItem(Item);
        RecRef.GetTable(Item);

        CreateDocAttach(RecRef, 'item1.jpeg', true, true);
        CreateDocAttach(RecRef, 'item2.jpeg', false, true);

        // [WHEN] The a purchase order is created.
        CreatePurchDoc(PurchaseHeader, PurchaseLine, Vendor, Item, PurchaseHeader."Document Type"::Order);

        // [THEN] the purchase header has one attachment.

        CheckDocAttachments(DATABASE::"Purchase Header", 1, PurchaseHeader."No.", PurchaseHeader."Document Type".AsInteger(), 'vend1');

        // [THEN] the purchase line has one attachment.

        CheckDocAttachments(DATABASE::"Purchase Line", 1, PurchaseLine."Document No.", PurchaseLine."Document Type".AsInteger(), 'item1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureDocAttachFlowFromSalesQuoteToSalesOrder()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeaderQuote: Record "Sales Header";
        SalesLineForQuote: Record "Sales Line";
        RecRef: RecordRef;
        QuoteNo: Code[20];
        OrderNo: Code[20];
    begin
        // [SCENARIO] Ensuring attached docs for sales quote flow to sales order

        // Initialize
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        RecRef.GetTable(Customer);

        // [GIVEN] A sales quote with attachments in header and line item
        LibraryInventory.CreateItem(Item);
        CreateSalesDoc(SalesHeaderQuote, SalesLineForQuote, Customer, Item, SalesHeaderQuote."Document Type"::Quote);

        // Attach docs to quote header and sales line
        Clear(RecRef);
        RecRef.GetTable(SalesHeaderQuote);
        CreateDocAttach(RecRef, 'salesquote.jpeg', false, false);

        Clear(RecRef);
        RecRef.GetTable(SalesLineForQuote);
        CreateDocAttach(RecRef, 'salesline.jpeg', false, false);

        // [WHEN] Order is created from a sales quote
        QuoteNo := SalesHeaderQuote."No.";
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", SalesHeaderQuote);

        // Find the sales order created
        // Assert quote is converted to order
        SalesHeaderQuote.SetRange("Bill-to Customer No.", Customer."No.");
        SalesHeaderQuote.SetRange("Quote No.", QuoteNo);
        Assert.IsTrue(SalesHeaderQuote.FindFirst(), 'Sales order was created from quote.');
        Assert.AreEqual(SalesHeaderQuote."Document Type"::Order, SalesHeaderQuote."Document Type",
          'Sales quote is not converted to sales order');
        Assert.AreEqual(QuoteNo, SalesHeaderQuote."Quote No.", 'Sales order does not have expected quote number.');

        OrderNo := SalesHeaderQuote."No.";

        // [THEN] Assert docs are flown to sales order
        CheckDocAttachments(DATABASE::"Sales Header", 1, OrderNo, SalesHeaderQuote."Document Type"::Order.AsInteger(), 'salesquote');

        // [THEN] the sales line has one attachment for sales order
        CheckDocAttachments(DATABASE::"Sales Line", 1, OrderNo, SalesHeaderQuote."Document Type"::Order.AsInteger(), 'salesline');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureDocAttachFlowFromSalesQuoteToSalesInvoice()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
        QuoteNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] Ensuring attached docs for Sales Quote flow to Sales Invoice

        // Initialize
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        RecRef.GetTable(Customer);

        // [GIVEN] A Sales Quote with attachments in header and line item
        LibraryInventory.CreateItem(Item);
        CreateSalesDoc(SalesHeader, SalesLine, Customer, Item, SalesHeader."Document Type"::Quote);

        // Attach docs to quote header and sales line
        Clear(RecRef);
        RecRef.GetTable(SalesHeader);
        CreateDocAttach(RecRef, 'salesquote', false, false);

        Clear(RecRef);
        RecRef.GetTable(SalesLine);
        CreateDocAttach(RecRef, 'salesline', false, false);

        // [WHEN] Sales Invoice is created from a Sales Quote
        QuoteNo := SalesHeader."No.";
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Invoice", SalesHeader);

        // Find the Sales Invoice created
        // Assert sales quote is converted to sales invoice
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.SetRange("Quote No.", QuoteNo);
        Assert.IsTrue(SalesHeader.FindFirst(), 'Sales Invoice was not created from Sales Quote.');
        Assert.AreEqual(SalesHeader."Document Type"::Invoice, SalesHeader."Document Type",
          'Sales quote is not converted to sales invoice');
        Assert.AreEqual(QuoteNo, SalesHeader."Quote No.", 'Sales Invoice does not have expected Sales Quote number.');

        InvoiceNo := SalesHeader."No.";

        // [THEN] Assert docs are flown to Sales Invoice
        CheckDocAttachments(DATABASE::"Sales Header", 1, InvoiceNo, SalesHeader."Document Type"::Invoice.AsInteger(), 'salesquote');

        // [THEN] the sales line should have one document attachment for sales invoice
        CheckDocAttachments(DATABASE::"Sales Line", 1, InvoiceNo, SalesHeader."Document Type"::Invoice.AsInteger(), 'salesline');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('GetShipmentLinesPageHandler')]
    procedure EnsureDocAttachFlowFromSalesShipmentToSalesInvoice()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeaderOrder: Record "Sales Header";
        SalesLineOrder: Record "Sales Line";
        RecordRef: RecordRef;
        SalesInvoicePage: TestPage "Sales Invoice";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] Ensuring attached docs on Posted Sales Shipment flow to Sales Invoice when using 'Get Shipment Lines'

        // Initialize
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        RecordRef.GetTable(Customer);

        // [GIVEN] Create Sales Order with Item line
        LibraryInventory.CreateItem(Item);
        CreateSalesDoc(SalesHeaderOrder, SalesLineOrder, Customer, Item, SalesHeaderOrder."Document Type"::Order);

        // [GIVEN] Attach document to Sales Order header
        Clear(RecordRef);
        RecordRef.GetTable(SalesHeaderOrder);
        CreateDocAttach(RecordRef, 'SalesOrder.jpeg', false, false);

        // [GIVEN] Attach document to 1st Sales Order line 
        Clear(RecordRef);
        RecordRef.GetTable(SalesLineOrder);
        CreateDocAttach(RecordRef, 'SalesLine.jpeg', false, false);

        // [GIVEN] Post Sales Shipment from Sales Order
        SalesHeaderOrder.Ship := true;
        Codeunit.Run(Codeunit::"Sales-Post", SalesHeaderOrder);

        // [GIVEN] Create Sales Invoice
        SalesInvoicePage.OpenNew();
        SalesInvoicePage."Sell-to Customer Name".SetValue(Customer."No.");
        Evaluate(InvoiceNo, SalesInvoicePage."No.".Value);

        // [WHEN] Use 'Get Shipment Lines' to insert lines
        SalesInvoicePage.SalesLines.GetShipmentLines.Invoke(); // opens modal page "Get Shipment Lines", and handler clicks OK

        // [WHEN] Repeat use 'Get Shipment Lines' to check it will run multiple times - inserts new line with attachment
        SalesInvoicePage.SalesLines.GetShipmentLines.Invoke(); // opens modal page "Get Shipment Lines", and handler clicks OK

        // [THEN] Assert attached documents are flown to Sales Invoice (one attachment)
        CheckDocAttachments(Database::"Sales Header", 1, InvoiceNo, SalesHeaderOrder."Document Type"::Invoice.AsInteger(), 'SalesOrder');

        // [THEN] Assert Sales Invoice lines have two document attachments (one per each line inserted from Sales Order)
        CheckDocAttachments(Database::"Sales Line", 2, InvoiceNo, SalesHeaderOrder."Document Type"::Invoice.AsInteger(), 'SalesLine');
    end;

    [ModalPageHandler]
    procedure GetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('GetReceiptLinesPageHandler')]
    procedure EnsureDocAttachFlowFromPurchaseReceiptToPurchaseInvoice()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        RecordRef: RecordRef;
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO] Ensuring attached docs on Posted Purchase Receipt flow to Purchase Invoice when using 'Get Receipt Lines'

        // Initialize
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        RecordRef.GetTable(Vendor);

        // [GIVEN] Create Purchase Order with Item line
        LibraryInventory.CreateItem(Item);
        CreatePurchDoc(PurchaseHeaderOrder, PurchaseLineOrder, Vendor, Item, PurchaseHeaderOrder."Document Type"::Order);

        // [GIVEN] Attach document to Purchase Order header
        Clear(RecordRef);
        RecordRef.GetTable(PurchaseHeaderOrder);
        CreateDocAttach(RecordRef, 'PurchaseOrder.jpeg', false, false);

        // [GIVEN] Attach document to 1st Purchase Order line 
        Clear(RecordRef);
        RecordRef.GetTable(PurchaseLineOrder);
        CreateDocAttach(RecordRef, 'PurchaseLine.jpeg', false, false);

        // [GIVEN] Post Purchase Receipt from Purchase Order
        PurchaseHeaderOrder.Receive := true;
        Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeaderOrder);

        // [GIVEN] Create Purchase Invoice
        PurchaseInvoicePage.OpenNew();
        PurchaseInvoicePage."Buy-from Vendor Name".SetValue(Vendor."No.");
        Evaluate(InvoiceNo, PurchaseInvoicePage."No.".Value);

        // [WHEN] Use 'Get Receipt Lines' to insert lines
        PurchaseInvoicePage.PurchLines.GetReceiptLines.Invoke(); // opens modal page "Get Receipt Lines", and handler clicks OK

        // [WHEN] Repeat use 'Get Receipt Lines' to check it will run multiple times - inserts new line with attachment
        PurchaseInvoicePage.PurchLines.GetReceiptLines.Invoke(); // opens modal page "Get Receipt Lines", and handler clicks OK

        // [THEN] Assert attached documents are flown to Purchase Invoice (one attachment)
        CheckDocAttachments(Database::"Purchase Header", 1, InvoiceNo, PurchaseHeaderOrder."Document Type"::Invoice.AsInteger(), 'PurchaseOrder');

        // [THEN] Assert Purchase Invoice lines have two document attachments (one per each line inserted from Purchase Order)
        CheckDocAttachments(Database::"Purchase Line", 2, InvoiceNo, PurchaseHeaderOrder."Document Type"::Invoice.AsInteger(), 'PurchaseLine');
    end;

    [ModalPageHandler]
    procedure GetReceiptLinesPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    begin
        GetReceiptLines.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocAttachFlowFromPurchQuoteToPurchOrder()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RecRef: RecordRef;
        QuoteNo: Code[20];
        OrderNo: Code[20];
    begin
        // [SCENARIO] Ensuring attached docs for purch quote flow to purch order

        // Initialize
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        RecRef.GetTable(Vendor);

        // [GIVEN] A purch quote with attachments in header and line item
        LibraryInventory.CreateItem(Item);
        CreatePurchDoc(PurchaseHeader, PurchaseLine, Vendor, Item, PurchaseHeader."Document Type"::Quote);

        // Attach docs to quote header and line
        Clear(RecRef);
        RecRef.GetTable(PurchaseHeader);
        CreateDocAttach(RecRef, 'purchquote.jpeg', false, false);

        Clear(RecRef);
        RecRef.GetTable(PurchaseLine);
        CreateDocAttach(RecRef, 'purchline.jpeg', false, false);

        // [WHEN] Order is created from a quote
        QuoteNo := PurchaseHeader."No.";
        CODEUNIT.Run(CODEUNIT::"Purch.-Quote to Order", PurchaseHeader);

        // Find the purch order created
        // Assert quote is converted to order
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.SetRange("Quote No.", QuoteNo);
        Assert.IsTrue(PurchaseHeader.FindFirst(), 'Purch order was not created from quote.');
        Assert.AreEqual(PurchaseHeader."Document Type"::Order, PurchaseHeader."Document Type",
          'Purch quote is not converted to purch order');
        Assert.AreEqual(QuoteNo, PurchaseHeader."Quote No.", 'Purch order does not have expected quote number.');

        OrderNo := PurchaseHeader."No.";

        // [THEN] Assert docs are flown to purch order
        CheckDocAttachments(DATABASE::"Purchase Header", 1, OrderNo, PurchaseHeader."Document Type"::Order.AsInteger(), 'purchquote');

        // [THEN] the sales line has one attachment for purch order
        CheckDocAttachments(DATABASE::"Purchase Line", 1, OrderNo, PurchaseHeader."Document Type"::Order.AsInteger(), 'purchline');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocAttachFlowFromPurchBlanketToPurchOrder()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RecRef: RecordRef;
        OrderNo: Code[20];
    begin
        // [SCENARIO] Ensuring attached docs for purch blanket flow to purch order

        // Initialize
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        RecRef.GetTable(Vendor);

        // [GIVEN] A purch quote with attachments in header and line item
        LibraryInventory.CreateItem(Item);
        CreatePurchDoc(PurchaseHeader, PurchaseLine, Vendor, Item, PurchaseHeader."Document Type"::"Blanket Order");

        // Attach docs to blanket header and line
        Clear(RecRef);
        RecRef.GetTable(PurchaseHeader);
        CreateDocAttach(RecRef, 'purchblanket.jpeg', false, false);

        Clear(RecRef);
        RecRef.GetTable(PurchaseLine);
        CreateDocAttach(RecRef, 'purchblanketline.jpeg', false, false);

        // [WHEN] Order is created from a blanket
        CODEUNIT.Run(CODEUNIT::"Blanket Purch. Order to Order", PurchaseHeader);

        // Find the purch order created
        // Assert quote is converted to order
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.FindFirst();

        OrderNo := PurchaseHeader."No.";

        // [THEN] Assert docs are flown to purch order
        CheckDocAttachments(DATABASE::"Purchase Header", 1, OrderNo, PurchaseHeader."Document Type"::Order.AsInteger(), 'purchblanket');

        // [THEN] the purch line has one attachment for purch order
        CheckDocAttachments(DATABASE::"Purchase Line", 1, OrderNo, PurchaseHeader."Document Type"::Order.AsInteger(), 'purchblanketline');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocAttachFlowFromVendorToPurchInvoice()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Ensuring attached docs for vendor and item flow to purch invoice

        // Initialize
        Initialize();

        // Create attachment for Vendor record.
        Clear(RecRef);
        LibraryPurchase.CreateVendor(Vendor);
        RecRef.GetTable(Vendor);
        CreateDocAttach(RecRef, 'vendortopurchinvoiceheader.jpeg', true, false);

        // Create attachment for Item record.
        Clear(RecRef);
        LibraryInventory.CreateItem(Item);
        RecRef.GetTable(Item);
        CreateDocAttach(RecRef, 'itemtopurchinvoiceline.jpeg', true, false);

        // Create purch invoice
        CreatePurchDoc(PurchaseHeader, PurchaseLine, Vendor, Item, PurchaseHeader."Document Type"::Invoice);

        // Assert purchase header is created with the expected vendor No. and Document Type as Invoice.
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        Assert.IsTrue(PurchaseHeader.FindFirst(), 'Purch invoice was not created with the expected vendor No.');
        Assert.AreEqual(PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Document Type",
          'Unexpected Document Type for Purchase Header');

        // Assert purchase line is created with the expected Purchase header Document No. and Item No.
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.IsTrue(PurchaseLine.FindFirst(), 'Purchase line not created for Purchase header');
        Assert.AreEqual(PurchaseLine."Document Type"::Invoice, PurchaseLine."Document Type", 'Unexpected Document Type for Purchase Line');
        Assert.AreEqual(Item."No.", PurchaseLine."No.", 'Unexpected Item No. in Purchase Line');

        // [THEN] Assert docs are flown to purch invoice at the header level
        CheckDocAttachments(
          DATABASE::"Purchase Header", 1, PurchaseHeader."No.", PurchaseHeader."Document Type"::Invoice.AsInteger(), 'vendortopurchinvoiceheader');

        // [THEN] Assert docs are flown to purch invoice at the item line level
        CheckDocAttachments(
          DATABASE::"Purchase Line", 1, PurchaseLine."Document No.", PurchaseHeader."Document Type"::Invoice.AsInteger(), 'itemtopurchinvoiceline');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocAttachDoesNotFlowInPurchaseForGLAccountsWithSameNoAsItem()
    var
        Item: Record Item;
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Ensure that documents from the item do not flow to the purchase line if a GL account with the same no as the item is used

        // Initialize
        Initialize();

        // [GIVEN] An Item with two attachments, one marked to flow
        LibraryInventory.CreateItem(Item);
        RecRef.GetTable(Item);

        CreateDocAttach(RecRef, 'item1.jpeg', true, false);
        CreateDocAttach(RecRef, 'item2.jpeg', false, false);

        // [GIVEN] A GL Account with the same no as the item is created
        CopyGLAccountToNewNo(LibraryERM.CreateGLAccountWithPurchSetup(), Item."No.", GLAccount);

        // [GIVEN] A purchase invoice header is created
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // [WHEN] A purchase line with the GL account is inserted
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);

        // [THEN] The purchase line has no attachments.
        AssertNoAttachmentsExist(Database::"Purchase Line", PurchaseLine."Document No.", Enum::"Attachment Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocAttachDoesNotFlowInSalesForGLAccountsWithSameNoAsItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Ensure that documents from the item do not flow to the sales line if a GL account with the same no as the item is used

        // Initialize
        Initialize();

        // [GIVEN] An Item with two attachments, one marked to flow
        LibraryInventory.CreateItem(Item);
        RecRef.GetTable(Item);

        CreateDocAttach(RecRef, 'item1.jpeg', false, true);
        CreateDocAttach(RecRef, 'item2.jpeg', false, false);

        // [GIVEN] A GL Account with the same no as the item is created
        CopyGLAccountToNewNo(LibraryERM.CreateGLAccountWithSalesSetup(), Item."No.", GLAccount);

        // [GIVEN] A sales order is created.
        LibrarySales.CreateSalesOrder(SalesHeader);

        // [WHEN] A sales line with the GL account is inserted
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);

        // [THEN] The sales line has no attachment.
        AssertNoAttachmentsExist(Database::"Sales Line", SalesLine."Document No.", Enum::"Attachment Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowPostDocAttachEnabledCustomerLedgerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentAttachment: Record "Document Attachment";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [FEATURE] [Attachments] [UI]
        // [SCENARIO 271044] Action "Show Posted Document Attachment" on the page Customer Ledger Entries enabled if attachment exist for posted Sales invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(CreatePostSalesInvoice(LibrarySales.CreateCustomerNo()));

        // [GIVEN] Add attachment to Sales invoice
        CreateSalesInvoiceHeaderDocumentAttachment(DocumentAttachment, SalesInvoiceHeader);

        // [WHEN] Customer Ledger Entries page is being opened for posted sales invoice
        FindCustLedgEntry(CustLedgerEntry, SalesInvoiceHeader."No.", SalesInvoiceHeader."Sell-to Customer No.");
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));

        // [THEN] Action "Show Posted Document Attachment" is enabled
        Assert.IsTrue(
          CustomerLedgerEntries.ShowDocumentAttachment.Enabled(),
          'Action must be enabled');
    end;

    [Test]
    [HandlerFunctions('DocumentAttachmentDetailsMPH')]
    [Scope('OnPrem')]
    procedure ShowPostDocAttachCustomerLedgerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentAttachment: Record "Document Attachment";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [FEATURE] [Attachments] [UI]
        // [SCENARIO 271044] Action "Show Posted Document Attachment" on the page Customer Ledger Entries opens Attached Document page for sales invoice header
        Initialize();

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(CreatePostSalesInvoice(LibrarySales.CreateCustomerNo()));

        // [GIVEN] Add attachment to sales invoice with file name "FILE"
        CreateSalesInvoiceHeaderDocumentAttachment(DocumentAttachment, SalesInvoiceHeader);

        // [GIVEN] Open Customer Ledger Entries page with posted sales invoice entry
        FindCustLedgEntry(CustLedgerEntry, SalesInvoiceHeader."No.", SalesInvoiceHeader."Sell-to Customer No.");
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));

        // [WHEN] Action "Show Posted Document Attachment" is being choosen
        CustomerLedgerEntries.ShowDocumentAttachment.Invoke();

        // [THEN] Page Document Attachment Details opened with file name = "FILE"
        Assert.AreEqual(
          DocumentAttachment."File Name",
          LibraryVariableStorage.DequeueText(),
          'Invalid file name');
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntryCheckShowDocAttachMPH')]
    [Scope('OnPrem')]
    procedure ShowPostDocAttachEnabledApplyCustomerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentAttachment: Record "Document Attachment";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [FEATURE] [Attachments] [UI]
        // [SCENARIO 271044] Action "Show Posted Document Attachment" on the page Apply Customer Entries enabled if attachment exist for posted sales invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(CreatePostSalesInvoice(LibrarySales.CreateCustomerNo()));

        // [GIVEN] Add attachment to sales invoice
        CreateSalesInvoiceHeaderDocumentAttachment(DocumentAttachment, SalesInvoiceHeader);

        // [GIVEN] Posted Sales Cr. Memo
        SalesCrMemoHeader.Get(CreatePostSalesCrMemo(SalesInvoiceHeader."Sell-to Customer No."));

        // [GIVEN] Open Customer Ledger Entries page for posted credit memo
        FindCustLedgEntry(CustLedgerEntry, SalesCrMemoHeader."No.", SalesInvoiceHeader."Sell-to Customer No.");
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));

        // [WHEN] Choose Apply Entries
        CustomerLedgerEntries."Apply Entries".Invoke();

        // [THEN] Action "Show Posted Document Attachment" for sales invoice is enabled
        Assert.IsTrue(
          LibraryVariableStorage.DequeueBoolean(),
          'Action must be enabled');
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntryChooseShowDocAttachMPH,DocumentAttachmentDetailsMPH')]
    [Scope('OnPrem')]
    procedure ShowPostDocAttachApplyCustomerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentAttachment: Record "Document Attachment";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [FEATURE] [Attachments] [UI]
        // [SCENARIO 271044] Action "Show Posted Document Attachment" on the page Apply Customer Entries  opens Attached Document page for sales invoice header
        Initialize();

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(CreatePostSalesInvoice(LibrarySales.CreateCustomerNo()));

        // [GIVEN] Add attachment to sales invoice with file name "FILE"
        CreateSalesInvoiceHeaderDocumentAttachment(DocumentAttachment, SalesInvoiceHeader);

        // [GIVEN] Posted Sales Cr. Memo
        SalesCrMemoHeader.Get(CreatePostSalesCrMemo(SalesInvoiceHeader."Sell-to Customer No."));

        // [GIVEN] Open Customer Ledger Entries page for posted credit memo
        FindCustLedgEntry(CustLedgerEntry, SalesInvoiceHeader."No.", SalesInvoiceHeader."Sell-to Customer No.");
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));

        // [GIVEN] Choose Apply Entries
        CustomerLedgerEntries."Apply Entries".Invoke();

        // [WHEN] Action "Show Posted Document Attachment" is being choosen
        CustomerLedgerEntries.ShowDocumentAttachment.Invoke();

        // [THEN] Page Document Attachment Details opened with file name = "FILE"
        Assert.AreEqual(
          DocumentAttachment."File Name",
          LibraryVariableStorage.DequeueText(),
          'Invalid file name');
    end;

    [Test]
    [HandlerFunctions('AppliedCustomerEntriesCheckShowDocAttachPH')]
    [Scope('OnPrem')]
    procedure ShowPostDocAttachEnabledAppliedCustomerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentAttachment: Record "Document Attachment";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [FEATURE] [Attachments] [UI]
        // [SCENARIO 271044] Action "Show Posted Document Attachment" on the page Applied Customer Entries enabled if attachment exist for posted sales invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(CreatePostSalesInvoice(LibrarySales.CreateCustomerNo()));

        // [GIVEN] Add attachment to sales invoice
        CreateSalesInvoiceHeaderDocumentAttachment(DocumentAttachment, SalesInvoiceHeader);

        // [GIVEN] Posted Sales Cr. Memo
        SalesCrMemoHeader.Get(CreatePostSalesCrMemo(SalesInvoiceHeader."Sell-to Customer No."));

        // [GIVEN] Apply credit memo to invoice
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::"Credit Memo",
          CustLedgerEntry."Document Type"::Invoice,
          SalesCrMemoHeader."No.",
          SalesInvoiceHeader."No.");

        // [GIVEN] Open Customer Ledger Entries page with posted credit memo
        FindCustLedgEntry(CustLedgerEntry, SalesCrMemoHeader."No.", SalesCrMemoHeader."Sell-to Customer No.");
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));

        // [WHEN] Open applied entries page
        CustomerLedgerEntries.AppliedEntries.Invoke();

        // [THEN] Action "Show Posted Document Attachment" for sales invoice is enabled
        Assert.IsTrue(
          LibraryVariableStorage.DequeueBoolean(),
          'Action must be enabled');
    end;

    [Test]
    [HandlerFunctions('AppliedCustomerEntriesChooseShowDocAttachPH,DocumentAttachmentDetailsMPH')]
    [Scope('OnPrem')]
    procedure ShowPostDocAttachAppliedCustomerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentAttachment: Record "Document Attachment";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [FEATURE] [Attachments] [UI]
        // [SCENARIO 271044] Action "Show Posted Document Attachment" on the page Applied Customer Entries opens Attached Document page for sales invoice header
        Initialize();

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(CreatePostSalesInvoice(LibrarySales.CreateCustomerNo()));

        // [GIVEN] Add attachment to sales invoice
        CreateSalesInvoiceHeaderDocumentAttachment(DocumentAttachment, SalesInvoiceHeader);

        // [GIVEN] Posted Sales Cr. Memo
        SalesCrMemoHeader.Get(CreatePostSalesCrMemo(SalesInvoiceHeader."Sell-to Customer No."));

        // [GIVEN] Apply credit memo to invoice
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::"Credit Memo",
          CustLedgerEntry."Document Type"::Invoice,
          SalesCrMemoHeader."No.",
          SalesInvoiceHeader."No.");

        // [GIVEN] Open Customer Ledger Entries page with posted credit memo
        FindCustLedgEntry(CustLedgerEntry, SalesCrMemoHeader."No.", SalesCrMemoHeader."Sell-to Customer No.");
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));

        // [WHEN] Open applied entries page and action "Show Posted Document Attachment" is being choosen
        CustomerLedgerEntries.AppliedEntries.Invoke();

        // [THEN] Page Document Attachment Details opened with file name = "FILE"
        Assert.AreEqual(
          DocumentAttachment."File Name",
          LibraryVariableStorage.DequeueText(),
          'Invalid file name');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowPostDocAttachEnabledVendorLedgerEntries()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentAttachment: Record "Document Attachment";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [FEATURE] [Attachments] [UI]
        // [SCENARIO 271044] Action "Show Posted Document Attachment" on the page Vendor Ledger Entries enabled if attachment exist for posted purchase invoice
        Initialize();

        // [GIVEN] Posted Purchase Invoice
        PurchInvHeader.Get(CreatePostPurchaseInvoice(LibraryPurchase.CreateVendorNo()));

        // [GIVEN] Add attachment to purchase invoice
        CreatePurchaseInvoiceHeaderDocumentAttachment(DocumentAttachment, PurchInvHeader);

        // [WHEN] Vendor Ledger Entries page is being opened for posted purchase invoice
        FindVendLedgEntry(VendorLedgerEntry, PurchInvHeader."No.", PurchInvHeader."Buy-from Vendor No.");
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(VendorLedgerEntry."Entry No."));

        // [THEN] Action "Show Posted Document Attachment" is enabled
        Assert.IsTrue(
          VendorLedgerEntries.ShowDocumentAttachment.Enabled(),
          'Action must be enabled');
    end;

    [Test]
    [HandlerFunctions('DocumentAttachmentDetailsMPH')]
    [Scope('OnPrem')]
    procedure ShowPostDocAttachVendorLedgerEntries()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentAttachment: Record "Document Attachment";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [FEATURE] [Attachments] [UI]
        // [SCENARIO 271044] Action "Show Posted Document Attachment" on the page Vendor Ledger Entries opens Attached Document page for purchase invoice header
        Initialize();

        // [GIVEN] Posted Purchase Invoice
        PurchInvHeader.Get(CreatePostPurchaseInvoice(LibraryPurchase.CreateVendorNo()));

        // [GIVEN] Add attachment to purchase invoice
        CreatePurchaseInvoiceHeaderDocumentAttachment(DocumentAttachment, PurchInvHeader);

        // [WHEN] Vendor Ledger Entries page is being opened for posted purchase invoice
        FindVendLedgEntry(VendorLedgerEntry, PurchInvHeader."No.", PurchInvHeader."Buy-from Vendor No.");
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(VendorLedgerEntry."Entry No."));

        // [WHEN] Action "Show Posted Document Attachment" is being choosen
        VendorLedgerEntries.ShowDocumentAttachment.Invoke();

        // [THEN] Page Document Attachment Details opened with file name = "FILE"
        Assert.AreEqual(
          DocumentAttachment."File Name",
          LibraryVariableStorage.DequeueText(),
          'Invalid file name');
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntryCheckShowDocAttachMPH')]
    [Scope('OnPrem')]
    procedure ShowPostDocAttachEnabledApplyVendorEntries()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DocumentAttachment: Record "Document Attachment";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [FEATURE] [Attachments] [UI]
        // [SCENARIO 271044] Action "Show Posted Document Attachment" on the page Apply Vendor Entries enabled if attachment exist for posted purchase invoice
        Initialize();

        // [GIVEN] Posted Purchase Invoice
        PurchInvHeader.Get(CreatePostPurchaseInvoice(LibraryPurchase.CreateVendorNo()));

        // [GIVEN] Add attachment to purchase invoice
        CreatePurchaseInvoiceHeaderDocumentAttachment(DocumentAttachment, PurchInvHeader);

        // [GIVEN] Posted Purchase Cr. Memo
        PurchCrMemoHdr.Get(CreatePostPurchaseCrMemo(PurchInvHeader."Buy-from Vendor No."));

        // [GIVEN] Open Vendor Ledger Entries page for posted credit memo
        FindVendLedgEntry(VendorLedgerEntry, PurchCrMemoHdr."No.", PurchInvHeader."Buy-from Vendor No.");
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(VendorLedgerEntry."Entry No."));

        // [WHEN] Choose Apply Entries
        VendorLedgerEntries.ActionApplyEntries.Invoke();

        // [THEN] Action "Show Posted Document Attachment" for purchase invoice is enabled
        Assert.IsTrue(
          LibraryVariableStorage.DequeueBoolean(),
          'Action must be enabled');
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntryChooseShowDocAttachMPH,DocumentAttachmentDetailsMPH')]
    [Scope('OnPrem')]
    procedure ShowPostDocAttachApplyVendorEntries()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DocumentAttachment: Record "Document Attachment";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [FEATURE] [Attachments] [UI]
        // [SCENARIO 271044] Action "Show Posted Document Attachment" on the page Apply Vendor Entries  opens Attached Document page for purchase invoice header
        Initialize();

        // [GIVEN] Posted Purchase Invoice
        PurchInvHeader.Get(CreatePostPurchaseInvoice(LibraryPurchase.CreateVendorNo()));

        // [GIVEN] Add attachment to purchase invoice
        CreatePurchaseInvoiceHeaderDocumentAttachment(DocumentAttachment, PurchInvHeader);

        // [GIVEN] Posted Purchase Cr. Memo
        PurchCrMemoHdr.Get(CreatePostPurchaseCrMemo(PurchInvHeader."Buy-from Vendor No."));

        // [GIVEN] Open Vendor Ledger Entries page for posted credit memo
        FindVendLedgEntry(VendorLedgerEntry, PurchCrMemoHdr."No.", PurchInvHeader."Buy-from Vendor No.");
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(VendorLedgerEntry."Entry No."));

        // [WHEN] Choose Apply Entries
        VendorLedgerEntries.ActionApplyEntries.Invoke();

        // [WHEN] Action "Show Posted Document Attachment" is being choosen
        VendorLedgerEntries.ShowDocumentAttachment.Invoke();

        // [THEN] Page Document Attachment Details opened with file name = "FILE"
        Assert.AreEqual(
          DocumentAttachment."File Name",
          LibraryVariableStorage.DequeueText(),
          'Invalid file name');
    end;

    [Test]
    [HandlerFunctions('AppliedVendorEntriesCheckShowDocAttachPH')]
    [Scope('OnPrem')]
    procedure ShowPostDocAttachEnabledAppliedVendorEntries()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DocumentAttachment: Record "Document Attachment";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [FEATURE] [Attachments] [UI]
        // [SCENARIO 271044] Action "Show Posted Document Attachment" on the page Applied Vendor Entries enabled if attachment exist for posted purchase invoice
        Initialize();

        // [GIVEN] Posted Purchase Invoice
        PurchInvHeader.Get(CreatePostPurchaseInvoice(LibraryPurchase.CreateVendorNo()));

        // [GIVEN] Add attachment to purchase invoice
        CreatePurchaseInvoiceHeaderDocumentAttachment(DocumentAttachment, PurchInvHeader);

        // [GIVEN] Posted Purchase Cr. Memo
        PurchCrMemoHdr.Get(CreatePostPurchaseCrMemo(PurchInvHeader."Buy-from Vendor No."));

        // [GIVEN] Apply credit memo to invoice
        LibraryERM.ApplyVendorLedgerEntries(
          VendorLedgerEntry."Document Type"::"Credit Memo",
          VendorLedgerEntry."Document Type"::Invoice,
          PurchCrMemoHdr."No.",
          PurchInvHeader."No.");

        // [GIVEN] Open Vendor Ledger Entries page with posted credit memo
        FindVendLedgEntry(VendorLedgerEntry, PurchCrMemoHdr."No.", PurchInvHeader."Buy-from Vendor No.");
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(VendorLedgerEntry."Entry No."));

        // [WHEN] Open applied entries page
        VendorLedgerEntries.AppliedEntries.Invoke();

        // [THEN] Action "Show Posted Document Attachment" for purchase invoice is enabled
        Assert.IsTrue(
          LibraryVariableStorage.DequeueBoolean(),
          'Action must be enabled');
    end;

    [Test]
    [HandlerFunctions('AppliedVendorEntriesChooseShowDocAttachPH,DocumentAttachmentDetailsMPH')]
    [Scope('OnPrem')]
    procedure ShowPostDocAttachAppliedVendorEntries()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DocumentAttachment: Record "Document Attachment";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [FEATURE] [Attachments] [UI]
        // [SCENARIO 271044] Action "Show Posted Document Attachment" on the page Applied Vendor Entries opens Attached Document page for purchase invoice header
        Initialize();

        // [GIVEN] Posted Purchase Invoice
        PurchInvHeader.Get(CreatePostPurchaseInvoice(LibraryPurchase.CreateVendorNo()));

        // [GIVEN] Add attachment to purchase invoice
        CreatePurchaseInvoiceHeaderDocumentAttachment(DocumentAttachment, PurchInvHeader);

        // [GIVEN] Posted Purchase Cr. Memo
        PurchCrMemoHdr.Get(CreatePostPurchaseCrMemo(PurchInvHeader."Buy-from Vendor No."));

        // [GIVEN] Apply credit memo to invoice
        LibraryERM.ApplyVendorLedgerEntries(
          VendorLedgerEntry."Document Type"::"Credit Memo",
          VendorLedgerEntry."Document Type"::Invoice,
          PurchCrMemoHdr."No.",
          PurchInvHeader."No.");

        // [GIVEN] Open Vendor Ledger Entries page with posted credit memo
        FindVendLedgEntry(VendorLedgerEntry, PurchCrMemoHdr."No.", PurchInvHeader."Buy-from Vendor No.");
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(VendorLedgerEntry."Entry No."));

        // [WHEN] Open applied entries page and action "Show Posted Document Attachment" is being choosen
        VendorLedgerEntries.AppliedEntries.Invoke();

        // [THEN] Page Document Attachment Details opened with file name = "FILE"
        Assert.AreEqual(
          DocumentAttachment."File Name",
          LibraryVariableStorage.DequeueText(),
          'Invalid file name');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureAttachmentsAreRetainedWhenCustomerNoIsChanged()
    var
        Customer: Record Customer;
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Test to ensure that attachments for a customer are kept after change in [No.] which is a primary key
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Customer with an attachment
        RecRef.GetTable(Customer);
        CreateDocAttach(RecRef, 'cust1.jpeg', false, true);
        CreateDocAttach(RecRef, 'cust2.jpeg', false, false);

        // [WHEN] No. is changed
        Customer.Rename('T');

        // [THEN] No errors. Verfiy document attachments are retained with all the properties
        DocumentAttachment.Init();
        DocumentAttachment.SetRange("Table ID", RecRef.Number());
        DocumentAttachment.SetRange("No.", 'T');
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');
        DocumentAttachment.FindFirst();
        Assert.AreEqual(DocumentAttachment."File Name", 'cust1', 'First file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for first attachment.');
        Assert.IsTrue(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for first attachment.');
        DocumentAttachment.FindLast();
        Assert.AreEqual(DocumentAttachment."File Name", 'cust2', 'Second file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for second attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for second attachment.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureAttachmentsAreRetainedWhenVendorNoIsChanged()
    var
        Vendor: Record Vendor;
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Test to ensure that attachments for a Vendor are kept after change in [No.] which is a primary key
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Vendor with an attachment
        RecRef.GetTable(Vendor);
        CreateDocAttach(RecRef, 'ven1.jpeg', false, true);
        CreateDocAttach(RecRef, 'ven2.jpeg', false, false);

        // [WHEN] No. is changed
        Vendor.Rename('T');

        // [THEN] No errors. Verfiy document attachments are retained with all the properties
        DocumentAttachment.Init();
        DocumentAttachment.SetRange("Table ID", RecRef.Number());
        DocumentAttachment.SetRange("No.", 'T');
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');
        DocumentAttachment.FindFirst();
        Assert.AreEqual(DocumentAttachment."File Name", 'ven1', 'First file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for first attachment.');
        Assert.IsTrue(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for first attachment.');
        DocumentAttachment.FindLast();
        Assert.AreEqual(DocumentAttachment."File Name", 'ven2', 'Second file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for second attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for second attachment.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureAttachmentsAreRetainedWhenItemNoIsChanged()
    var
        Item: Record Item;
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Test to ensure that attachments for a Item are kept after change in [No.] which is a primary key
        Initialize();
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Item with an attachment
        RecRef.GetTable(Item);
        CreateDocAttach(RecRef, 'item1.jpeg', false, true);
        CreateDocAttach(RecRef, 'item2.jpeg', false, false);

        // [WHEN] No. is changed
        Item.Rename('T');

        // [THEN] No errors. Verfiy document attachments are retained with all the properties
        DocumentAttachment.Init();
        DocumentAttachment.SetRange("Table ID", RecRef.Number());
        DocumentAttachment.SetRange("No.", 'T');
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');
        DocumentAttachment.FindFirst();
        Assert.AreEqual(DocumentAttachment."File Name", 'item1', 'First file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for first attachment.');
        Assert.IsTrue(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for first attachment.');
        DocumentAttachment.FindLast();
        Assert.AreEqual(DocumentAttachment."File Name", 'item2', 'Second file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for second attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for second attachment.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureAttachmentsAreRetainedWhenEmployeeNoIsChanged()
    var
        Employee: Record Employee;
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Test to ensure that attachments for a Employee are kept after change in [No.] which is a primary key
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);

        // [GIVEN] Employee with an attachment
        RecRef.GetTable(Employee);
        CreateDocAttach(RecRef, 'emp1.jpeg', false, true);
        CreateDocAttach(RecRef, 'emp2.jpeg', false, false);

        // [WHEN] No. is changed
        Employee.Rename('T');

        // [THEN] No errors. Verfiy document attachments are retained with all the properties
        DocumentAttachment.Init();
        DocumentAttachment.SetRange("Table ID", RecRef.Number());
        DocumentAttachment.SetRange("No.", 'T');
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');
        DocumentAttachment.FindFirst();
        Assert.AreEqual(DocumentAttachment."File Name", 'emp1', 'First file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for first attachment.');
        Assert.IsTrue(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for first attachment.');
        DocumentAttachment.FindLast();
        Assert.AreEqual(DocumentAttachment."File Name", 'emp2', 'Second file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for second attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for second attachment.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureAttachmentsAreRetainedWhenFixAssetNoIsChanged()
    var
        FixedAsset: Record "Fixed Asset";
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Test to ensure that attachments for a Fixed Asset are kept after change in [No.] which is a primary key
        Initialize();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);

        // [GIVEN] Fixed Asset with an attachment
        RecRef.GetTable(FixedAsset);
        CreateDocAttach(RecRef, 'fa1.jpeg', false, true);
        CreateDocAttach(RecRef, 'fa2.jpeg', false, false);

        // [WHEN] No. is changed
        FixedAsset.Rename('T');

        // [THEN] No errors. Verfiy document attachments are retained with all the properties
        DocumentAttachment.Init();
        DocumentAttachment.SetRange("Table ID", RecRef.Number());
        DocumentAttachment.SetRange("No.", 'T');
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');
        DocumentAttachment.FindFirst();
        Assert.AreEqual(DocumentAttachment."File Name", 'fa1', 'First file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for first attachment.');
        Assert.IsTrue(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for first attachment.');
        DocumentAttachment.FindLast();
        Assert.AreEqual(DocumentAttachment."File Name", 'fa2', 'Second file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for second attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for second attachment.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureAttachmentsAreRetainedWhenResourceNoIsChanged()
    var
        Resource: Record Resource;
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Test to ensure that attachments for a Resource are kept after change in [No.] which is a primary key
        Initialize();
        LibraryResource.CreateResourceNew(Resource);

        // [GIVEN] Resource with an attachment
        RecRef.GetTable(Resource);
        CreateDocAttach(RecRef, 're1.jpeg', false, true);
        CreateDocAttach(RecRef, 're2.jpeg', false, false);

        // [WHEN] No. is changed
        Resource.Rename('T');

        // [THEN] No errors. Verfiy document attachments are retained with all the properties
        DocumentAttachment.Init();
        DocumentAttachment.SetRange("Table ID", RecRef.Number());
        DocumentAttachment.SetRange("No.", 'T');
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');
        DocumentAttachment.FindFirst();
        Assert.AreEqual(DocumentAttachment."File Name", 're1', 'First file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for first attachment.');
        Assert.IsTrue(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for first attachment.');
        DocumentAttachment.FindLast();
        Assert.AreEqual(DocumentAttachment."File Name", 're2', 'Second file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for second attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for second attachment.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureAttachmentsAreRetainedWhenJobNoIsChanged()
    var
        Job: Record Job;
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Test to ensure that attachments for a Job are kept after change in [No.] which is a primary key
        Initialize();
        LibraryJob.CreateJob(Job);

        // [GIVEN] Job with an attachment
        RecRef.GetTable(Job);
        CreateDocAttach(RecRef, 'job1.jpeg', false, true);
        CreateDocAttach(RecRef, 'job2.jpeg', false, false);

        // [WHEN] No. is changed
        Job.Rename('T');

        // [THEN] No errors. Verfiy document attachments are retained with all the properties
        DocumentAttachment.Init();
        DocumentAttachment.SetRange("Table ID", RecRef.Number());
        DocumentAttachment.SetRange("No.", 'T');
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');
        DocumentAttachment.FindFirst();
        Assert.AreEqual(DocumentAttachment."File Name", 'job1', 'First file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for first attachment.');
        Assert.IsTrue(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for first attachment.');
        DocumentAttachment.FindLast();
        Assert.AreEqual(DocumentAttachment."File Name", 'job2', 'Second file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for second attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for second attachment.');
    end;


    [Test]
    [HandlerFunctions('PrintedToAttachmentNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesQuotePrintToAttachment()
    var
        SalesHeader: Record "Sales Header";
        DocumentAttachment: Record "Document Attachment";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Sales Quote]
        // [SCENARIO 278831] "Print to attachment" action on sales quote page makes new "Document Attachment" record 
        Initialize();

        // [GIVEN] Sales quote with "Document No." = "1001" opened in the Sales Quote Card page
        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader, LibrarySales.CreateCustomerNo());
        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", SalesHeader."No.");
        // [WHEN] "Print to attachment" function is called
        SalesQuote.AttachAsPDF.Invoke();

        // [THEN] New document attachment created with "Document Flow Sales" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type".AsInteger());
        DocumentAttachment.TestField("Document Flow Sales", true);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Standard Sales - Quote", SalesHeader."No."));

        // [THEN] Notification "Document has been printed to attachments." displayed
        Assert.AreEqual(PrintedToAttachmentTxt, LibraryVariableStorage.DequeueText(), 'Unexpected notification.');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FindUniqueFileName_Sunshine()
    var
        DocumentAttachment: Record "Document Attachment";
        FileName: Text;
    begin
        // [FEATURE] [UT] [Print to Attachment]
        // [SCENARIO 278831] Function FindUniqueFileName returns same FileName if it is already unique for document attachment for the Sales Quote
        Initialize();

        // [GIVEN] No document attachments
        DocumentAttachment.DeleteAll();
        // [WHEN] Function FindUniqueFileName is called with FileName = "Quote_1001"
        // [THEN] It returns same value "Quote_1001"
        FileName := 'Quote_1001';
        Assert.AreEqual(StrSubstNo('%1.pdf', FileName), DocumentAttachment.FindUniqueFileName(FileName, 'pdf'), 'Invalid file name value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FindUniqueFileName_FileNameAlreadyExists()
    var
        DocumentAttachment: Record "Document Attachment";
        SalesHeader: Record "Sales Header";
        FileName: Text;
    begin
        // [FEATURE] [UT] [Print to Attachment]
        // [SCENARIO 278831] Function FindUniqueFileName returns proper FileName when requested FileName already exists for document attachment for the Sales Quote
        Initialize();

        // [GIVEN] Document Attachment record with "File Name"  = "Quote_1001"
        MockDocumentAttachment(DocumentAttachment, Database::"Sales Header", '1001', SalesHeader."Document Type"::Quote, 'Quote_1001', 'pdf');
        // [WHEN] Function FindUniqueFileName is called with FileName = "Quote_1001"
        // [THEN] It returns value "Quote_1001 (1).pdf"
        FileName := 'Quote_1001';
        Assert.AreEqual(StrSubstNo('%1 (1).pdf', FileName), DocumentAttachment.FindUniqueFileName(FileName, 'pdf'), 'Invalid file name value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FindUniqueFileName_SecondFileNameVersionAlreadyExists()
    var
        DocumentAttachment: Record "Document Attachment";
        SalesHeader: Record "Sales Header";
        FileName: Text;
    begin
        // [FEATURE] [UT] [Print to Attachment]
        // [SCENARIO 278831] Function FindUniqueFileName returns proper FileName when requested FileName and the next version (Quote_1001 (1)) already exist for document attachment for the Sales Quote
        Initialize();

        // [GIVEN] Document Attachment record with "File Name"  = "Quote_1001"
        MockDocumentAttachment(DocumentAttachment, Database::"Sales Header", '1001', SalesHeader."Document Type"::Quote, 'Quote_1001', 'pdf');
        // [GIVEN] Document Attachment record with "File Name"  = "Quote_1001 (1)"
        MockDocumentAttachment(DocumentAttachment, Database::"Sales Header", '1001', SalesHeader."Document Type"::Quote, 'Quote_1001 (1)', 'pdf');
        // [WHEN] Function FindUniqueFileName is called with FileName = "Quote_1001"
        // [THEN] It returns value "Quote_1001 (2).pdf"
        FileName := 'Quote_1001';
        Assert.AreEqual(StrSubstNo('%1 (2).pdf', FileName), DocumentAttachment.FindUniqueFileName(FileName, 'pdf'), 'Invalid file name value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuotePrintToAttachment()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentAttachment: Record "Document Attachment";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Purchase Quote]
        // [SCENARIO 278831] "Print to attachment" action on purchase quote page makes new "Document Attachment" record 
        Initialize();

        // [GIVEN] Purchase quote with "Document No." = "1001" opened in the Purchase Quote Card page
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);
        PurchaseQuote.OpenEdit();
        PurchaseQuote.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [WHEN] "Print to attachment" function is called
        PurchaseQuote.AttachAsPDF.Invoke();

        // [THEN] New document attachment created with "Document Flow Purchase" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Purchase Header", PurchaseHeader."No.", PurchaseHeader."Document Type".AsInteger());
        DocumentAttachment.TestField("Document Flow Purchase", true);

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteForVendorPrintToAttachment()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentAttachment: Record "Document Attachment";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Purchase Quote]
        // [SCENARIO 278831] "Print to attachment" action on purchase quote page makes an attachment of report which is set up for particular vendor
        Initialize();

        // [GIVEN] Purchase quote for vendor "V" with "Document No." = "1001" opened in the Purchase Quote Card page
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);
        PurchaseQuote.OpenEdit();
        PurchaseQuote.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [GIVEN] Vendor "V" have a report selection setup to print qoute with report 204
        CreateCustomReportSelection(Database::Vendor, PurchaseHeader."Pay-to Vendor No.", ReportSelectionUsage::"P.Quote", Report::"Purchase - Quote");
        // [WHEN] "Print to attachment" function is called
        PurchaseQuote.AttachAsPDF.Invoke();

        // [THEN] New document attachment created with "File Name" = "204 Purchase Quote 1001"
        FindDocumentAttachment(DocumentAttachment, Database::"Purchase Header", PurchaseHeader."No.", PurchaseHeader."Document Type".AsInteger());
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Purchase - Quote", PurchaseHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('SalesOrderMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPrintToAttachmentOrderConfirmation()
    var
        SalesHeader: Record "Sales Header";
        DocumentAttachment: Record "Document Attachment";
        DocPrint: Codeunit "Document-Print";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Sales Order]
        // [SCENARIO 278831] "Print to attachment" for sales order makes new "Document Attachment" record with Order Confirmation report
        Initialize();

        // [GIVEN] Sales order
        LibrarySales.CreateSalesOrder(SalesHeader);

        // [WHEN] "Print to attachment" function is called with "Order Confirmation" strmenu choice
        LibraryVariableStorage.Enqueue("Sales Order Print Option"::"Order Confirmation");
        SalesHeader.SetRecFilter();
        DocPrint.PrintSalesOrderToDocumentAttachment(SalesHeader, DocPrint.GetSalesOrderPrintToAttachmentOption(SalesHeader));

        // [THEN] New document attachment created with "Document Flow Sales" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type"::Order.AsInteger());
        DocumentAttachment.TestField("Document Flow Sales", true);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Standard Sales - Order Conf.", SalesHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesOrderMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPrintToAttachmentPickInstruction()
    var
        SalesHeader: Record "Sales Header";
        DocumentAttachment: Record "Document Attachment";
        DocPrint: Codeunit "Document-Print";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Sales Order]
        // [SCENARIO 278831] "Print to attachment" for sales order makes new "Document Attachment" record with Pick Instruction report
        Initialize();

        // [GIVEN] Sales order
        LibrarySales.CreateSalesOrder(SalesHeader);

        // [WHEN] "Print to attachment" function is called with "Pick Instruction" strmenu choice
        LibraryVariableStorage.Enqueue("Sales Order Print Option"::"Pick Instruction");
        SalesHeader.SetRecFilter();
        DocPrint.PrintSalesOrderToDocumentAttachment(SalesHeader, DocPrint.GetSalesOrderPrintToAttachmentOption((SalesHeader)));

        // [THEN] New document attachment created with "Document Flow Sales" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type"::Order.AsInteger());
        DocumentAttachment.TestField("Document Flow Sales", true);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Pick Instruction", SalesHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesOrderMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPrintToAttachmentProFormaInvoice()
    var
        SalesHeader: Record "Sales Header";
        DocumentAttachment: Record "Document Attachment";
        DocPrint: Codeunit "Document-Print";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Sales Order]
        // [SCENARIO 278831] "Print to attachment" for sales order makes new "Document Attachment" record with Pro Forma Invoice report
        Initialize();

        // [GIVEN] Sales order
        LibrarySales.CreateSalesOrder(SalesHeader);

        // [WHEN] "Print to attachment" function is called with "Pro Forma Invoice" strmenu choice
        LibraryVariableStorage.Enqueue("Sales Order Print Option"::"Pro Forma Invoice");
        SalesHeader.SetRecFilter();
        DocPrint.PrintSalesOrderToDocumentAttachment(SalesHeader, DocPrint.GetSalesOrderPrintToAttachmentOption((SalesHeader)));

        // [THEN] New document attachment created with "Document Flow Sales" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type"::Order.AsInteger());
        DocumentAttachment.TestField("Document Flow Sales", true);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Standard Sales - Pro Forma Inv", SalesHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesOrderMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPrintToAttachmentWorkOrder()
    var
        SalesHeader: Record "Sales Header";
        DocumentAttachment: Record "Document Attachment";
        DocPrint: Codeunit "Document-Print";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Sales Order]
        // [SCENARIO 278831] "Print to attachment" for sales order makes new "Document Attachment" record with Work Order report
        Initialize();

        // [GIVEN] Sales order
        LibrarySales.CreateSalesOrder(SalesHeader);

        // [WHEN] "Print to attachment" function is called with "Work Order" strmenu choice
        LibraryVariableStorage.Enqueue("Sales Order Print Option"::"Work Order");
        SalesHeader.SetRecFilter();
        DocPrint.PrintSalesOrderToDocumentAttachment(SalesHeader, DocPrint.GetSalesOrderPrintToAttachmentOption((SalesHeader)));

        // [THEN] New document attachment created with "Document Flow Sales" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type"::Order.AsInteger());
        DocumentAttachment.TestField("Document Flow Sales", true);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Work Order", SalesHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesOrderMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePrintToAttachmentDraftInvoice()
    var
        SalesHeader: Record "Sales Header";
        DocumentAttachment: Record "Document Attachment";
        DocPrint: Codeunit "Document-Print";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Sales Invoice]
        // [SCENARIO 278831] "Print to attachment" for sales invoice makes new "Document Attachment" record with Drart Invoice report
        Initialize();

        // [GIVEN] Sales invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [WHEN] "Print to attachment" function is called with "Standard Sales - Draft Invoice" strmenu choice
        LibraryVariableStorage.Enqueue(1);
        SalesHeader.SetRecFilter();
        DocPrint.PrintSalesInvoiceToDocumentAttachment(SalesHeader, DocPrint.GetSalesInvoicePrintToAttachmentOption(SalesHeader));

        // [THEN] New document attachment created with "Document Flow Sales" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type"::Invoice.AsInteger());
        DocumentAttachment.TestField("Document Flow Sales", true);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Standard Sales - Draft Invoice", SalesHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesOrderMenuHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePrintToAttachmentProFormaInvoice()
    var
        SalesHeader: Record "Sales Header";
        DocumentAttachment: Record "Document Attachment";
        DocPrint: Codeunit "Document-Print";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Sales Invoice]
        // [SCENARIO 278831] "Print to attachment" for sales invoice makes new "Document Attachment" record with "Standard Sales - Pro Forma Inv" report
        Initialize();

        // [GIVEN] Sales invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [WHEN] "Print to attachment" function is called with "Standard Sales - Pro Forma Inv" strmenu choice
        LibraryVariableStorage.Enqueue(2);
        SalesHeader.SetRecFilter();
        DocPrint.PrintSalesInvoiceToDocumentAttachment(SalesHeader, DocPrint.GetSalesInvoicePrintToAttachmentOption(SalesHeader));

        // [THEN] New document attachment created with "Document Flow Sales" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type"::Invoice.AsInteger());
        DocumentAttachment.TestField("Document Flow Sales", true);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Standard Sales - Pro Forma Inv", SalesHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicePrintToAttachment()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentAttachment: Record "Document Attachment";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Posted Sales Invoice]
        // [SCENARIO 278831] "Print to attachment" action on posted sales invoice page makes new "Document Attachment" record 
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Document No." = "1001" opened in the Posted Sales Invoice Card page
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesInvoiceHeader.get(
            LibrarySales.PostSalesDocument(SalesHeader, true, true));
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.Filter.SetFilter("No.", SalesInvoiceHeader."No.");
        // [WHEN] "Print to attachment" function is called
        PostedSalesInvoice.AttachAsPDF.Invoke();

        // [THEN] New document attachment created with "Document Flow Sales" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Invoice Header", SalesInvoiceHeader."No.", 0);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Standard Sales - Invoice", SalesInvoiceHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesInvoiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoicePrintToAttachment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentAttachment: Record "Document Attachment";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Posted Purchase Invoice]
        // [SCENARIO 278831] "Print to attachment" action on posted Purchase invoice page makes new "Document Attachment" record 
        Initialize();

        // [GIVEN] Posted Purchase Invoice with "Document No." = "1001" opened in the Posted Purchase Invoice Card page
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchInvHeader.get(
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.Filter.SetFilter("No.", PurchInvHeader."No.");
        // [WHEN] "Print to attachment" function is called
        PostedPurchaseInvoice.AttachAsPDF.Invoke();

        // [THEN] New document attachment created with "Document Flow Purchase" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Purch. Inv. Header", PurchInvHeader."No.", 0);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Purchase - Invoice", PurchInvHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchInvHeader);
    end;

    [Test]
    [HandlerFunctions('PrintedToAttachmentNotificationHandler')]
    [Scope('OnPrem')]
    procedure TryAttachToPFDProcessingOnlyReport()
    var
        SalesHeader: Record "Sales Header";
        DocPrint: Codeunit "Document-Print";
    begin
        // [FEATURE] [UI] [Print to Attachment] 
        // [SCENARIO 278831] When report selections have single "Processed Only" report "Attach to PDF" action shows notification "There are no reports which could be saved to PDF"
        Initialize();

        // [GIVEN] Report selections have single "Processing Only" report for sales invoices
        SetupReportSelection(ReportSelectionUsage::"S.Order", Report::"Sales Processing Only");
        // [GIVEN] Sales order 
        LibrarySales.CreateSalesOrder(SalesHeader);
        // [WHEN] "Print to attachment" function is called
        SalesHeader.SetRecFilter();
        DocPrint.PrintSalesHeaderToDocumentAttachment(SalesHeader);

        // [THEN] Notification "There are no reports which could be saved to PDF"
        Assert.AreEqual(NoSaveToPDFReportTxt, LibraryVariableStorage.DequeueText(), 'Unexpected notification.');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('PrintedToAttachmentNotificationHandler')]
    [Scope('OnPrem')]
    procedure AttachToPFDVendorReportSelection()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentAttachment: Record "Document Attachment";
    begin
        // [FEATURE] [Print to Attachment] [Posted Purchase Invoice]
        // [SCENARIO 350302] "Attach to PDF" action uses vendor's document layout
        Initialize();

        // [GIVEN] Posted Purchase Invoice with "Document No." = "1001" for vendor "VEND"
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchInvHeader.Get(
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [GIVEN] Set purchase invoice document layout for vendor "VEND" to report 324
        CreateCustomReportSelection(Database::Vendor, PurchInvHeader."Buy-from Vendor No.", "Report Selection Usage"::"P.Invoice", Report::"Purchase Invoice Nos.");

        // [WHEN] "Print to attachment" function is called
        PurchInvHeader.SetRecFilter();
        PurchInvHeader.PrintToDocumentAttachment(PurchInvHeader);

        // [THEN] Attachment file name starts from 324
        FindDocumentAttachment(DocumentAttachment, Database::"Purch. Inv. Header", PurchInvHeader."No.", 0);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Purchase Invoice Nos.", PurchInvHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchInvHeader);
    end;

    [Test]
    procedure PostedSalesCrMemoPrintToAttachment()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentAttachment: Record "Document Attachment";
        PostedSalesCrMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Posted Sales Credit Memo]
        // [SCENARIO 396624] "Print to attachment" action on posted Sales Credit Memo page makes new "Document Attachment" record 
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with "Document No." = "1001" opened in the Posted Sales Credit Memo Card page
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        SalesCrMemoHeader.Get(
            LibrarySales.PostSalesDocument(SalesHeader, false, true));
        PostedSalesCrMemo.OpenEdit();
        PostedSalesCrMemo.Filter.SetFilter("No.", SalesCrMemoHeader."No.");

        // [WHEN] "Print to attachment" function is called
        PostedSalesCrMemo.AttachAsPDF.Invoke();

        // [THEN] New document attachment created with "Document Flow Sales" = yes, File Name = "1307 Sales Credit Memo 1001".
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", 0);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Standard Sales - Credit Memo", SalesCrMemoHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesCrMemoHeader);
    end;

    [Test]
    procedure PostedPurchaseCrMemoPrintToAttachment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        DocumentAttachment: Record "Document Attachment";
        ReportSelections: Record "Report Selections";
        PostedPurchaseCrMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Posted Purchase Credit Memo]
        // [SCENARIO 396624] "Print to attachment" action on posted Purchase Credit Memo page makes new "Document Attachment" record 
        Initialize();

        // [GIVEN] Report 407 "Purchase - Credit Memo" is set as default report for printing Purchase Credit Memo.
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"P.Cr.Memo", Report::"Purchase - Credit Memo");

        // [GIVEN] Posted Purchase Credit Memo with "Document No." = "1001" opened in the Posted Purchase Credit Memo Card page
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        PurchCrMemoHeader.Get(
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
        PostedPurchaseCrMemo.OpenEdit();
        PostedPurchaseCrMemo.Filter.SetFilter("No.", PurchCrMemoHeader."No.");

        // [WHEN] "Print to attachment" function is called
        PostedPurchaseCrMemo.AttachAsPDF.Invoke();

        // [THEN] New document attachment created with "Document Flow Purchase" = yes, File Name = "407 Purchase Credit Memo 1001".
        FindDocumentAttachment(DocumentAttachment, Database::"Purch. Cr. Memo Hdr.", PurchCrMemoHeader."No.", 0);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Purchase - Credit Memo", PurchCrMemoHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchCrMemoHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerDeleteYesDefaultYes')]
    [Scope('OnPrem')]
    procedure SalesDocCustomerChangeDeleteAttachments()
    var
        SalesHeader: Record "Sales Header";
        RecRef: RecordRef;
        SalesDocumentType: Enum "Sales Document Type";
    begin
        // [SCENARIO 395462] Changing customer on a sales document with attachments produces a confirm. Choosing YES deletes attachments.
        Initialize();

        // [GIVEN] A sales order exists with a customer no
        LibrarySales.CreateSalesHeader(SalesHeader, SalesDocumentType::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] A document was attached to the sales order
        RecRef.GetTable(SalesHeader);
        CreateDocAttach(RecRef, 'attachment.jpeg', false, false);

        // [WHEN] Validate a new Customer in "Sell-to Customer No.", YES is chosen in delete attachments confirm
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());

        // [THEN] Attachment is deleted
        AssertNoAttachmentsExist(Database::"Sales Header", SalesHeader."No.", Enum::"Attachment Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerDeleteNoDefaultYes')]
    [Scope('OnPrem')]
    procedure SalesDocCustomerChangeDeleteAttachmentsNO()
    var
        SalesHeader: Record "Sales Header";
        RecRef: RecordRef;
        SalesDocumentType: Enum "Sales Document Type";
    begin
        // [SCENARIO 395462] Changing customer on a sales document with attachments produces a confirm. Choosing NO saves attachments.
        Initialize();

        // [GIVEN] A sales order exists with a customer no
        LibrarySales.CreateSalesHeader(SalesHeader, SalesDocumentType::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] A document was attached to the sales order
        RecRef.GetTable(SalesHeader);
        CreateDocAttach(RecRef, 'attachment.jpeg', false, false);

        // [WHEN] Validate a new Customer in "Sell-to Customer No.", NO is chosen in delete attachments confirm
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());

        // [THEN] Attachment still exists for the document
        CheckDocAttachments(Database::"Sales Header", 1, SalesHeader."No.", 1, 'attachment');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerDeleteYesDefaultYes')]
    [Scope('OnPrem')]
    procedure PurchaseDocVendorChangeDeleteAttachments()
    var
        PurchaseHeader: Record "Purchase Header";
        RecRef: RecordRef;
    begin
        // [SCENARIO 395462] Changing vendor on a purchase document with attachments produces a confirm. Choosing YES deletes attachments.
        Initialize();

        // [GIVEN] A purchase order exists with a vendor no
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // [GIVEN] A document was attached to the purchase order
        RecRef.GetTable(PurchaseHeader);
        CreateDocAttach(RecRef, 'attachment.jpeg', false, false);

        // [WHEN] Validate a new Vendor in "Buy-from Vendor No.", YES is chosen in delete attachments confirm
        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());

        // [THEN] Attachment is deleted
        AssertNoAttachmentsExist(Database::"Purchase Header", PurchaseHeader."No.", Enum::"Attachment Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerDeleteNoDefaultYes')]
    [Scope('OnPrem')]
    procedure PurchaseDocVendorChangeDeleteAttachmentsNO()
    var
        PurchaseHeader: Record "Purchase Header";
        RecRef: RecordRef;
    begin
        // [SCENARIO 395462] Changing vendor on a purchase document with attachments produces a confirm. Choosing NO saves attachments.
        Initialize();

        // [GIVEN] A purchase order exists with a vendor no
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // [GIVEN] A document was attached to the purchase order
        RecRef.GetTable(PurchaseHeader);
        CreateDocAttach(RecRef, 'attachment.jpeg', false, false);

        // [WHEN] Validate a new Vendor in "Buy-from Vendor No.", NO is chosen in delete attachments confirm
        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());

        // [THEN] Attachment still exists for the document
        CheckDocAttachments(Database::"Purchase Header", 1, PurchaseHeader."No.", 1, 'attachment');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceListAttachmentFactbox()
    var
        SalesHeader: Record "Sales Header";
        DocumentAttachment: Record "Document Attachment";
        SalesInvoiceList: TestPage "Sales Invoice List";
        SalesHeaders: array[2] of Code[20];
        i: Integer;
        j: Integer;
    begin
        // [SCENARIO 430965] Number of attached documents correctly shown on the sales invoice list page
        Initialize();

        // [GIVEN] Sales invoice "SI1" with one attachment
        // [GIVEN] Sales invoice "SI2" with two attachments
        for i := 1 to 2 do begin
            LibrarySales.CreateSalesInvoice(SalesHeader);
            SalesHeaders[i] := SalesHeader."No.";
            for j := 1 to i do
                MockDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type", Format(j), 'txt');
        end;

        // [WHEN] Open sales invoice list page
        SalesInvoiceList.OpenView();

        // [THEN] "SI1" has one attachment in factbox
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesHeaders[1]);
        SalesInvoiceList.Filter.SetFilter("No.", SalesHeader."No.");
        SalesInvoiceList.AttachedDocuments.Documents.AssertEquals(1);
        // [THEN] "SI2" has two attachments in factbox
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesHeaders[2]);
        SalesInvoiceList.Filter.SetFilter("No.", SalesHeader."No.");
        SalesInvoiceList.AttachedDocuments.Documents.AssertEquals(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoListAttachmentFactbox()
    var
        SalesHeader: Record "Sales Header";
        DocumentAttachment: Record "Document Attachment";
        SalesCreditMemos: TestPage "Sales Credit Memos";
        SalesHeaders: array[2] of Code[20];
        i: Integer;
        j: Integer;
    begin
        // [SCENARIO 430965] Number of attached documents correctly shown on the sales credit memo list page
        Initialize();

        // [GIVEN] Sales credit memo "SCM1" with one attachment
        // [GIVEN] Sales credit memo "SCM2" with two attachments
        for i := 1 to 2 do begin
            LibrarySales.CreateSalesCreditMemo(SalesHeader);
            SalesHeaders[i] := SalesHeader."No.";
            for j := 1 to i do
                MockDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type", Format(j), 'txt');
        end;

        // [WHEN] Open sales credit memo list page
        SalesCreditMemos.OpenView();

        // [THEN] "SCM1" has one attachment in factbox
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesHeaders[1]);
        SalesCreditMemos.Filter.SetFilter("No.", SalesHeader."No.");
        SalesCreditMemos.AttachedDocuments.Documents.AssertEquals(1);
        // [THEN] "SCM2" has two attachments in factbox
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesHeaders[2]);
        SalesCreditMemos.Filter.SetFilter("No.", SalesHeader."No.");
        SalesCreditMemos.AttachedDocuments.Documents.AssertEquals(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceListAttachmentFactbox()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentAttachment: Record "Document Attachment";
        PurchaseInvoices: TestPage "Purchase Invoices";
        PurchaseHeaders: array[2] of Code[20];
        i: Integer;
        j: Integer;
    begin
        // [SCENARIO 430965] Number of attached documents correctly shown on the purchase invoice list page
        Initialize();

        // [GIVEN] Purchase invoice "PI1" with one attachment
        // [GIVEN] Purchase invoice "PI2" with two attachments
        for i := 1 to 2 do begin
            LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
            PurchaseHeaders[i] := PurchaseHeader."No.";
            for j := 1 to i do
                MockDocumentAttachment(DocumentAttachment, Database::"Purchase Header", PurchaseHeader."No.", PurchaseHeader."Document Type", Format(j), 'txt');
        end;

        // [WHEN] Open purchase invoice list page
        PurchaseInvoices.OpenView();

        // [THEN] "PI1" has one attachment in factbox
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, PurchaseHeaders[1]);
        PurchaseInvoices.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoices.AttachedDocuments.Documents.AssertEquals(1);
        // [THEN] "PI2" has two attachments in factbox
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, PurchaseHeaders[2]);
        PurchaseInvoices.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoices.AttachedDocuments.Documents.AssertEquals(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoListAttachmentFactbox()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentAttachment: Record "Document Attachment";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
        PurchaseHeaders: array[2] of Code[20];
        i: Integer;
        j: Integer;
    begin
        // [SCENARIO 430965] Number of attached documents correctly shown on the purchase credit memo list page
        Initialize();

        // [GIVEN] Purchase credit memo "PCM1" with one attachment
        // [GIVEN] Purchase credit memo "PCM2" with two attachments
        for i := 1 to 2 do begin
            LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
            PurchaseHeaders[i] := PurchaseHeader."No.";
            for j := 1 to i do
                MockDocumentAttachment(DocumentAttachment, Database::"Purchase Header", PurchaseHeader."No.", PurchaseHeader."Document Type", Format(j), 'txt');
        end;

        // [WHEN] Open purchase credit memo list page
        PurchaseCreditMemos.OpenView();

        // [THEN] "PCM1" has one attachment in factbox
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeaders[1]);
        PurchaseCreditMemos.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseCreditMemos.AttachedDocuments.Documents.AssertEquals(1);
        // [THEN] "PCM2" has two attachments in factbox
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeaders[2]);
        PurchaseCreditMemos.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseCreditMemos.AttachedDocuments.Documents.AssertEquals(2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('QuoteToOrderConfirmHandler')]
    procedure EnsureAttachedDateEqualWhenQuoteConvertedToOrder()
    var
        Customer: Record Customer;
        SalesHeaderQuote: Record "Sales Header";
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
        SalesQuotes: TestPage "Sales Quotes";
        SalesQuoteAttachedDate: DateTime;
        SalesHeaderQuoteNo: Code[20];
    begin
        // [SCENARIO 449418] Time stamp change of attachments when converting a sales quote into a sales order
        Initialize();

        // [GIVEN] Create customer, sales quote
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeaderQuote, Customer."No.");
        SalesHeaderQuoteNo := SalesHeaderQuote."No.";

        // [GIVEN] Attached documents for the quote
        RecRef.GetTable(SalesHeaderQuote);
        CreateDocumentAttachment(DocumentAttachment, RecRef, 'foo.jpeg');

        // [GIVEN] The sales quotes list is open- navigate to the created quote 
        SalesQuotes.OpenView();
        while SalesQuotes."No.".Value() <> SalesHeaderQuote."No." do
            if not SalesQuotes.Next() then
                break;

        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Sales Header");
        DocumentAttachment.SetRange("Document Type", SalesHeaderQuote."Document Type"::Quote);
        DocumentAttachment.SetRange("No.", SalesHeaderQuoteNo);
        if DocumentAttachment.FindFirst() then
            SalesQuoteAttachedDate := DocumentAttachment."Attached Date";

        // [WHEN] Quote is converted to order
        SalesQuotes.MakeOrder.Invoke();

        // [THEN] Verify Time stamp change of attachments are equal
        CheckDocAttachmentAttachedDate(SalesHeaderQuoteNo, SalesQuoteAttachedDate);
    end;

    [Test]
    procedure ImportGetAttachmentAsTempBlob()
    var
        DocumentAttachment: Record "Document Attachment";
        ImageBlob: Codeunit "Temp Blob";
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
    begin
        // [GIVEN] image is created
        CreateImage(ImageBlob);

        //[WHEN] image is imported into the table
        DocumentAttachment.Init();
        DocumentAttachment.ImportFromStream(ImageBlob.CreateInStream(), FileName);

        // [THEN] check if it is imported correctly
        Assert.IsTrue(DocumentAttachment."Document Reference ID".HasValue(), 'The ImportFromStream procedure has failed');

        // [THEN] check if attachment is get
        DocumentAttachment.GetAsTempBlob(TempBlob);
        Assert.IsTrue(TempBlob.HasValue(), 'The GetAsTempBlob procedure has failed');
    end;

    [Test]
    procedure Export()
    var
        DocumentAttachment: Record "Document Attachment";
        ImageBlob: Codeunit "Temp Blob";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        FileName: Text;
    begin
        // [GIVEN] image is created
        CreateImage(ImageBlob);

        // [GIVEN] image is imported as attachment
        DocumentAttachment.Init();
        DocumentAttachment.ImportFromStream(ImageBlob.CreateInStream(), FileName);

        //[WHEN] image is exported
        OutStr := TempBlob.CreateOutStream();
        DocumentAttachment.ExportToStream(OutStr);

        // [THEN] check if the blob where it was exported is filled
        Assert.IsTrue(TempBlob.HasValue(), 'The Export procedure has failed.');
    end;

    [Test]
    procedure GetContentType()
    var
        DocumentAttachment: Record "Document Attachment";
        ImageBlob: Codeunit "Temp Blob";
        ImageFormatLbl: Label 'image/png';
        FileName: Text;
    begin
        // [GIVEN] image is created
        CreateImage(ImageBlob);

        // [WHEN] image is imported as attachment
        DocumentAttachment.Init();
        DocumentAttachment.ImportFromStream(ImageBlob.CreateInStream(), FileName);

        // [THEN] check if it has the correct attachment
        Assert.IsTrue(DocumentAttachment.GetContentType() = ImageFormatLbl, 'Procedure GetContentType failed.');
    end;

    #region [Service Management]
    [Test]
    [HandlerFunctions('ListServiceItemFlow')]
    procedure DocAttachServiceItem()
    var
        ServiceItem: Record "Service Item";
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RecordRef: RecordRef;
    begin
        // [SCENARIO 332151] "Document Flow Service" is visible and editable for attachments of Service Item.
        Initialize();

        // [GIVEN] An Service Item Recordis created
        ServiceItem.Init();
        ServiceItem."No." := 'SRVITEM1';
        ServiceItem.Insert();

        // [WHEN] The DocumentAttachmentDetails window opens
        RecordRef.GetTable(ServiceItem);
        DocumentAttachmentDetails.OpenForRecRef(RecordRef);
        DocumentAttachmentDetails.RunModal();

        // [THEN] "Document Flow Service" is visible and editable
        // Handled by ListServiceItemFlow

        ServiceItem.Delete(true);
    end;

    [Test]
    procedure EnsureAttachmentsAreRetainedWhenServiceItemIsRenamed()
    var
        ServiceItem: Record "Service Item";
        DocumentAttachment: Record "Document Attachment";
        RecordRef: RecordRef;
    begin
        // [SCENARIO 332151] Test to ensure that attachments for a Service Item are kept after change in [No.] which is a primary key.
        Initialize();

        // [GIVEN] A Service Item record is created
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Add attachments to the Service Item
        RecordRef.GetTable(ServiceItem);
        CreateDocAttachService(RecordRef, 'ServiceItem1.jpeg', true);
        CreateDocAttachService(RecordRef, 'ServiceItem2.jpeg', false);

        // [WHEN] No. is changed
        ServiceItem.Rename('T');

        // [THEN] No errors. Verfiy document attachments are retained with all the properties
        DocumentAttachment.Init();
        DocumentAttachment.SetRange("Table ID", RecordRef.Number());
        DocumentAttachment.SetRange("No.", ServiceItem."No.");
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');
        DocumentAttachment.FindFirst();
        Assert.AreEqual(DocumentAttachment."File Name", 'ServiceItem1', 'First file name not equal to saved attachment.');
        Assert.IsTrue(DocumentAttachment."Document Flow Service", 'Flow sales value not equal for first attachment.');
        DocumentAttachment.FindLast();
        Assert.AreEqual(DocumentAttachment."File Name", 'ServiceItem2', 'Second file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Service", 'Flow sales value not equal for second attachment.');
    end;

    [Test]
    procedure DocAttachFlowFromItemToServiceItem()
    var
        Item: array[2] of Record Item;
        ServiceItem: Record "Service Item";
        DocumentAttachment: Record "Document Attachment";
        RecordRef: RecordRef;
    begin
        // [SCENARIO 332151] Item attachments with "Document Flow Service" are copied to Service Item attachments and refreshed on Item change.
        Initialize();

        // [GIVEN] An Item[1] with 4 attacments, 2 marked with "Document Flow Service"
        LibraryInventory.CreateItem(Item[1]);
        RecordRef.GetTable(Item[1]);
        CreateDocAttachService(RecordRef, 'Item1_1.jpeg', false);
        CreateDocAttachService(RecordRef, 'Item1_2.jpeg', true);
        CreateDocAttachService(RecordRef, 'Item1_3.jpeg', true);
        CreateDocAttachService(RecordRef, 'Item1_4.jpeg', false);

        // [GIVEN] An Item[2] with 5 attacments, 3 marked with "Document Flow Service"
        LibraryInventory.CreateItem(Item[2]);
        RecordRef.GetTable(Item[2]);
        CreateDocAttachService(RecordRef, 'Item2_1.jpeg', false);
        CreateDocAttachService(RecordRef, 'Item2_2.jpeg', true);
        CreateDocAttachService(RecordRef, 'Item2_3.jpeg', true);
        CreateDocAttachService(RecordRef, 'Item2_4.jpeg', false);
        CreateDocAttachService(RecordRef, 'Item2_5.jpeg', true);

        // [WHEN] A Service Item is created with the Item[1]
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate("Item No.", Item[1]."No.");
        ServiceItem.Modify(true);

        // [THEN] The Service Item has 2 attachments, all marked with "Document Flow Service"
        DocumentAttachment.SetRange("Table ID", Database::"Service Item");
        DocumentAttachment.SetRange("No.", ServiceItem."No.");
        Assert.RecordCount(DocumentAttachment, 2);
        DocumentAttachment.FindFirst();
        DocumentAttachment.TestField("Document Flow Service", true);
        DocumentAttachment.TestField("File Name", 'Item1_2');
        DocumentAttachment.Next();
        DocumentAttachment.TestField("Document Flow Service", true);
        DocumentAttachment.TestField("File Name", 'Item1_3');

        // [WHEN] The Item[1] is changed to Item[2]
        ServiceItem.Validate("Item No.", Item[2]."No.");
        ServiceItem.Modify(true);

        // [THEN] The Service Item has 3 attachments, all marked with "Document Flow Service"
        DocumentAttachment.SetRange("Table ID", Database::"Service Item");
        DocumentAttachment.SetRange("No.", ServiceItem."No.");
        Assert.RecordCount(DocumentAttachment, 3);
        DocumentAttachment.FindFirst();
        DocumentAttachment.TestField("Document Flow Service", true);
        DocumentAttachment.TestField("File Name", 'Item2_2');
        DocumentAttachment.Next();
        DocumentAttachment.TestField("Document Flow Service", true);
        DocumentAttachment.TestField("File Name", 'Item2_3');
        DocumentAttachment.Next();
        DocumentAttachment.TestField("Document Flow Service", true);
        DocumentAttachment.TestField("File Name", 'Item2_5');
    end;

    [Test]
    [HandlerFunctions('ListServiceFlow')]
    procedure DocAttachServiceLine()
    var
        ServiceLine: Record "Service Line";
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RecordRef: RecordRef;
    begin
        // [SCENARIO 332151] "Document Flow Service" is visible and editable for attachments of Service Line.
        Initialize();

        // [GIVEN] A Service Line record is created
        ServiceLine.Init();
        ServiceLine."Document No." := 'SRVLINE1';
        ServiceLine."Line No." := 10000;
        ServiceLine.Insert();

        // [WHEN] The DocumentAttachmentDetails window opens
        RecordRef.GetTable(ServiceLine);
        DocumentAttachmentDetails.OpenForRecRef(RecordRef);
        DocumentAttachmentDetails.RunModal();

        // [THEN] "Document Flow Service" is visible and editable
        // Handled by ListServiceFlow

        ServiceLine.Delete();
    end;

    [Test]
    [HandlerFunctions('ListServiceFlow')]
    procedure DocAttachServiceContractLine()
    var
        ServiceContractLine: Record "Service Contract Line";
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RecordRef: RecordRef;
    begin
        // [SCENARIO 332151] "Document Flow Service" is visible and editable for attachments of Service Contract Line.
        Initialize();

        // [GIVEN] A Service Contract Line record is created
        ServiceContractLine.Init();
        ServiceContractLine."Contract No." := 'SRVLINE1';
        ServiceContractLine."Line No." := 10000;
        ServiceContractLine.Insert();

        // [WHEN] The DocumentAttachmentDetails window opens
        RecordRef.GetTable(ServiceContractLine);
        DocumentAttachmentDetails.OpenForRecRef(RecordRef);
        DocumentAttachmentDetails.RunModal();

        // [THEN] "Document Flow Service" is visible and editable
        // Handled by ListServiceFlow

        ServiceContractLine.Delete();
    end;

    [Test]
    [HandlerFunctions('PrintedToAttachmentNotificationHandler')]
    procedure ServiceQuotePrintToAttachment_AndMakeOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DocumentAttachment: Record "Document Attachment";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        RecordRef: RecordRef;
        ServiceQuoteAttachedDateTime: DateTime;
        ServiceQuote: TestPage "Service Quote";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Service Quote]
        // [SCENARIO 332151] "Print to attachment" action in Service Quote page makes new "Document Attachment" record.
        // [SCENARIO 332151] Transfer Service Quote attachments to Service Order on "Make Order" action.
        Initialize();

        // [GIVEN] Service quote with "Document No." = "1001" opened in the Service Quote page
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, ServiceHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());
        ServiceQuote.OpenEdit();
        ServiceQuote.Filter.SetFilter("No.", ServiceHeader."No.");
        // [WHEN] "Print to attachment" function is called
        ServiceQuote.AttachAsPDF.Invoke();

        // [THEN] New document attachment created with "Document Flow Service"
        FindDocumentAttachment(DocumentAttachment, Database::"Service Header", ServiceHeader."No.", ServiceHeader."Document Type".AsInteger());
        DocumentAttachment.TestField("Document Flow Service", true);
        Assert.IsSubstring(DocumentAttachment."File Name", ServiceHeader."No.");

        // [THEN] Notification "Document has been printed to attachments." displayed
        Assert.AreEqual(PrintedToAttachmentTxt, LibraryVariableStorage.DequeueText(), 'Unexpected notification.');

        LibraryNotificationMgt.RecallNotificationsForRecord(ServiceHeader);

        // [GIVEN] Attached date time of the Service Quote
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Service Header");
        DocumentAttachment.SetRange("Document Type", ServiceHeader."Document Type"::Quote);
        DocumentAttachment.SetRange("No.", ServiceHeader."No.");
        if DocumentAttachment.FindFirst() then
            ServiceQuoteAttachedDateTime := DocumentAttachment."Attached Date";

        // [GIVEN] Add 2nd attachment to Service Quote
        RecordRef.GetTable(ServiceHeader);
        CreateDocAttachService(RecordRef, '2ndAttachment.jpeg', false);

        // [GIVEN] Put "Item" on Inventory
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.FindFirst();
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, '', ItemJournalLine."Entry Type"::"Positive Adjmt.", ServiceLine."No.", 10);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalLine."Journal Batch Name");

        // [WHEN] "Make Order" action is executed
        LibraryService.CreateOrderFromQuote(ServiceHeader);

        // [THEN] Service Quote attachments copied to Service Order attachments
#pragma warning disable AA0210
        ServiceHeader.SetRange("Quote No.", ServiceHeader."No.");
#pragma warning restore AA0210
        ServiceHeader.FindFirst();

        // [THEN] 2 attachments exist for the Service Order
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Service Header");
        DocumentAttachment.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        DocumentAttachment.SetRange("No.", ServiceHeader."No.");
        Assert.RecordCount(DocumentAttachment, 2);

        // [THEN] Verify Time stamp change of attachments are equal
        DocumentAttachment.FindFirst();
        Assert.AreEqual(ServiceQuoteAttachedDateTime, DocumentAttachment."Attached Date", AttachedDateInvalidErr);
    end;

    [Test]
    [HandlerFunctions('PrintedToAttachmentNotificationHandler')]
    procedure ServiceOrderPrintToAttachment()
    var
        ServiceHeader: Record "Service Header";
        DocumentAttachment: Record "Document Attachment";
        ServiceOrder: TestPage "Service Order";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Service Order]
        // [SCENARIO 332151] "Print to attachment" action in Service Order page makes new "Document Attachment" record.
        Initialize();

        // [GIVEN] Service quote with "Document No." = "1001" opened in the Service Order page
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        RecallNotifications := true;
        ServiceOrder.OpenEdit();
        ServiceOrder.Filter.SetFilter("No.", ServiceHeader."No.");
        RecallNotifications := false;
        // [WHEN] "Print to attachment" function is called
        ServiceOrder.AttachAsPDF.Invoke();

        // [THEN] New document attachment created with "Document Flow Service"
        FindDocumentAttachment(DocumentAttachment, Database::"Service Header", ServiceHeader."No.", ServiceHeader."Document Type".AsInteger());
        DocumentAttachment.TestField("Document Flow Service", true);
        Assert.IsSubstring(DocumentAttachment."File Name", ServiceHeader."No.");

        // [THEN] Notification "Document has been printed to attachments." displayed
        Assert.AreEqual(PrintedToAttachmentTxt, LibraryVariableStorage.DequeueText(), 'Unexpected notification.');

        LibraryNotificationMgt.RecallNotificationsForRecord(ServiceHeader);
    end;

    [Test]
    [HandlerFunctions('PrintedToAttachmentNotificationHandler,DocumentAttachmentDetailsMPH')]
    procedure TestDocAttachServiceOrder_ToPostedServiceInvoice_PrintToAttachment_ShowPostedDocAttach()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemForServiceItem: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DocumentAttachment: Record "Document Attachment";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RecordRef: RecordRef;
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        // [SCENARIO 332151] Ensure that document attachments from the Customer/Item/Service Item flow to the Service Order.
        // [SCENARIO 332151] Ensure that document attachments from the Service Order flow to Posted Service Invoice.
        // [SCENARIO 332151] Document attachment can be added in Posted Service Invoice.
        // [SCENARIO 332151] "Print to attachment" action in Posted Service Invoice page makes new "Document Attachment" record.
        // [SCENARIO 332151] Action "Show Posted Document Attachment" on the page Customer Ledger Entries opens Attached Document page for Posted Service Invoice.
        Initialize();

        // [GIVEN] A Customer with 2 attachments, 1 marked to flow
        LibrarySales.CreateCustomer(Customer);
        RecordRef.GetTable(Customer);
        CreateDocAttachService(RecordRef, 'Cust1.jpeg', true);
        CreateDocAttachService(RecordRef, 'Cust2.jpeg', false);

        // [GIVEN] Item with 2 attacments, 1 marked to flow
        LibraryInventory.CreateItem(Item);
        RecordRef.GetTable(Item);
        CreateDocAttachService(RecordRef, 'Item1.jpeg', true);
        CreateDocAttachService(RecordRef, 'Item2.jpeg', false);

        // [GIVEN] Service Item with 2 attacments, 1 marked to flow
        LibraryInventory.CreateItem(ItemForServiceItem);
        RecordRef.GetTable(ItemForServiceItem);
        CreateDocAttachService(RecordRef, 'ServiceItem1.jpeg', true);
        CreateDocAttachService(RecordRef, 'ServiceItem2.jpeg', false);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        ServiceItem.Validate("Item No.", ItemForServiceItem."No.");
        ServiceItem.Modify(true);

        // [WHEN] Service order is created
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(5, 10));
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Unit Price", LibraryRandom.RandIntInRange(3, 5));
        ServiceLine.Modify(true);

        // [THEN] Ensure that document attachments from the Customer/Item/Service Item flow to the Service Order. Service order header has 1 attachment
        CheckDocAttachments(Database::"Service Header", 1, ServiceHeader."No.", ServiceHeader."Document Type".AsInteger(), 'Cust1');

        // [THEN] Ensure that document attachments from the Customer/Item/Service Item flow to the Service Order. Service order line has 2 attachments
        CheckDocAttachments(Database::"Service Line", 2, ServiceLine."Document No.", ServiceLine."Document Type".AsInteger(), 'Item1');

        // [WHEN] Post Service Invoice from Service Order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Ensure that document attachments from the Service Order flow to Posted Service Invoice. Posted service invoice header has 1 attachment
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        CheckDocAttachmentsForPostedDocsCount(Database::"Service Invoice Header", 1, ServiceInvoiceHeader."No.");

        // [THEN] Ensure that document attachments from the Service Order flow to Posted Service Invoice. Posted service invoice line has 2 attachments
        CheckDocAttachmentsForPostedDocsCount(Database::"Service Invoice Line", 2, ServiceInvoiceHeader."No.");

        // [WHEN] Add attachment to posted service invoice with file name "FILE"
        DocumentAttachment."Table ID" := Database::"Service Invoice Header";
        DocumentAttachment."No." := ServiceInvoiceHeader."No.";
        DocumentAttachment."File Name" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(DocumentAttachment."File Name"));
        DocumentAttachment.Insert();

        // [THEN] Document attachment can be added in Posted Service Invoice. Posted service invoice header now has 2 attachments
        CheckDocAttachmentsForPostedDocsCount(Database::"Service Invoice Header", 2, ServiceInvoiceHeader."No.");

        // [WHEN] "Print to attachment" function is called
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.Filter.SetFilter("No.", ServiceInvoiceHeader."No.");
        PostedServiceInvoice.AttachAsPDF.Invoke();

        // [THEN] "Print to attachment" action in Service Contract page makes new "Document Attachment" record. Posted service invoice header now has 3 attachments
        CheckDocAttachmentsForPostedDocsCount(Database::"Service Invoice Header", 3, ServiceInvoiceHeader."No.");

        // [THEN] New document attachment created
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Service Invoice Header");
        DocumentAttachment.SetRange("No.", ServiceInvoiceHeader."No.");
        DocumentAttachment.FindLast();
        Assert.IsSubstring(DocumentAttachment."File Name", ServiceInvoiceHeader."No.");

        // [THEN] Notification "Document has been printed to attachments." displayed
        Assert.AreEqual(PrintedToAttachmentTxt, LibraryVariableStorage.DequeueText(), 'Unexpected notification.');

        LibraryNotificationMgt.RecallNotificationsForRecord(ServiceInvoiceHeader);
        PostedServiceInvoice.Close();

        // [WHEN] Open Customer Ledger Entries page with posted service invoice entry
        FindCustLedgEntry(CustLedgerEntry, ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Customer No.");
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.Filter.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));

        // [THEN] Action "Show Posted Document Attachment" on the page Customer Ledger Entries opens Attached Document page for Posted Service Invoice. Action "Show Posted Document Attachment" is enabled
        Assert.IsTrue(CustomerLedgerEntries.ShowDocumentAttachment.Enabled(), 'Action must be enabled');

        // [WHEN] Action "Show Posted Document Attachment" is being choosen
        CustomerLedgerEntries.ShowDocumentAttachment.Invoke();

        // [THEN] Page Document Attachment Details opened with the first attachment
        DocumentAttachment.FindFirst();
        Assert.AreEqual(DocumentAttachment."File Name", LibraryVariableStorage.DequeueText(), 'Invalid file name');
    end;

    [Test]
    [HandlerFunctions('PrintedToAttachmentNotificationHandler,DocumentAttachmentDetailsMPH')]
    procedure TestDocAttachServiceCreditMemo_ToPostedServiceCreditMemo_PrintToAttachment_ShowPostedDocAttach()
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        DocumentAttachment: Record "Document Attachment";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RecordRef: RecordRef;
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
    begin
        // [SCENARIO 332151] Ensure that document attachments from the Customer/Item/Service Item flow to the Service Credit Memo.
        // [SCENARIO 332151] Ensure that document attachments from the Service Credit Memo flow to Posted Service Credit Memo.
        // [SCENARIO 332151] Document attachment can be added in Posted Service Credit Memo.
        // [SCENARIO 332151] "Print to attachment" action in Posted Service Credit Memo page makes new "Document Attachment" record.
        // [SCENARIO 332151] Action "Show Posted Document Attachment" on the page Customer Ledger Entries opens Attached Document page for Posted Service Credit Memo.
        Initialize();

        // [GIVEN] A Customer with 2 attachments, 1 marked to flow
        LibrarySales.CreateCustomer(Customer);
        RecordRef.GetTable(Customer);
        CreateDocAttachService(RecordRef, 'Cust1.jpeg', true);
        CreateDocAttachService(RecordRef, 'Cust2.jpeg', false);

        // [GIVEN] Item with 2 attacments, 2 marked to flow
        LibraryInventory.CreateItem(Item);
        RecordRef.GetTable(Item);
        CreateDocAttachService(RecordRef, 'Item1.jpeg', true);
        CreateDocAttachService(RecordRef, 'Item2.jpeg', true);

        // [WHEN] Service credit memo is created
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(5, 10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandIntInRange(3, 5));
        ServiceLine.Modify(true);

        // [THEN] Ensure that document attachments from the Customer/Item/Service Item flow to the Service Credit Memo. Service credit memo header has 1 attachment
        CheckDocAttachments(Database::"Service Header", 1, ServiceHeader."No.", ServiceHeader."Document Type".AsInteger(), 'Cust1');

        // [THEN] Ensure that document attachments from the Customer/Item/Service Item flow to the Service Credit Memo. Service credit memo line has 2 attachments
        CheckDocAttachments(Database::"Service Line", 2, ServiceLine."Document No.", ServiceLine."Document Type".AsInteger(), 'Item1');

        // [WHEN] Post Service Credit Memo from Service Credit Memo
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // [THEN] Ensure that document attachments from the Service Credit Memo flow to Posted Service Credit Memo. Posted service credit memo header has 1 attachment
        ServiceCrMemoHeader.SetRange("Customer No.", ServiceHeader."Customer No.");
        ServiceCrMemoHeader.FindLast();
        CheckDocAttachmentsForPostedDocsCount(Database::"Service Cr.Memo Header", 1, ServiceCrMemoHeader."No.");

        // [THEN] Ensure that document attachments from the Service Service Credit flow to Posted Service Credit Memo. Posted service credit memo line has 2 attachments
        CheckDocAttachmentsForPostedDocsCount(Database::"Service Cr.Memo Line", 2, ServiceCrMemoHeader."No.");

        // [WHEN] Add attachment to posted service credit memo with file name "FILE"
        DocumentAttachment."Table ID" := Database::"Service Cr.Memo Header";
        DocumentAttachment."No." := ServiceCrMemoHeader."No.";
        DocumentAttachment."File Name" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(DocumentAttachment."File Name"));
        DocumentAttachment.Insert();

        // [THEN] Document attachment can be added in Posted Service Credit Memo. Posted service credit memo header now has 2 attachments
        CheckDocAttachmentsForPostedDocsCount(Database::"Service Cr.Memo Header", 2, ServiceCrMemoHeader."No.");

        // [WHEN] "Print to attachment" function is called
        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.Filter.SetFilter("No.", ServiceCrMemoHeader."No.");
        PostedServiceCreditMemo.AttachAsPDF.Invoke();

        // [THEN] "Print to attachment" action in Service Contract page makes new "Document Attachment" record. Posted service credit memo header now has 3 attachments
        CheckDocAttachmentsForPostedDocsCount(Database::"Service Cr.Memo Header", 3, ServiceCrMemoHeader."No.");

        // [THEN] New document attachment created
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Service Cr.Memo Header");
        DocumentAttachment.SetRange("No.", ServiceCrMemoHeader."No.");
        DocumentAttachment.FindLast();
        Assert.IsSubstring(DocumentAttachment."File Name", ServiceCrMemoHeader."No.");

        // [THEN] Notification "Document has been printed to attachments." displayed
        Assert.AreEqual(PrintedToAttachmentTxt, LibraryVariableStorage.DequeueText(), 'Unexpected notification.');

        LibraryNotificationMgt.RecallNotificationsForRecord(ServiceCrMemoHeader);
        PostedServiceCreditMemo.Close();

        // [WHEN] Open Customer Ledger Entries page with posted service credit memo entry
        FindCustLedgEntry(CustLedgerEntry, ServiceCrMemoHeader."No.", ServiceCrMemoHeader."Customer No.");
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.Filter.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));

        // [THEN] Action "Show Posted Document Attachment" on the page Customer Ledger Entries opens Attached Document page for Posted Service Credit Memo. Action "Show Posted Document Attachment" is enabled
        Assert.IsTrue(CustomerLedgerEntries.ShowDocumentAttachment.Enabled(), 'Action must be enabled');

        // [WHEN] Action "Show Posted Document Attachment" is being choosen
        CustomerLedgerEntries.ShowDocumentAttachment.Invoke();

        // [THEN] Page Document Attachment Details opened with the first attachment
        DocumentAttachment.FindFirst();
        Assert.AreEqual(DocumentAttachment."File Name", LibraryVariableStorage.DequeueText(), 'Invalid file name');
    end;

    [Test]
    [HandlerFunctions('GetServiceShipmentLinesPageHandler')]
    procedure EnsureDocAttachFlowFromServiceOrderToServiceInvoice()
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceHeaderOrder: Record "Service Header";
        ServiceLineOrder: Record "Service Line";
        RecordRef: RecordRef;
        ServiceInvoicePage: TestPage "Service Invoice";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 332151] Ensuring attached docs on Posted Service Shipment/Service Order flow to Service Invoice when using 'Get Shipment Lines'.
        Initialize();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);
        RecordRef.GetTable(Customer);

        // [GIVEN] Create Service Order with Item line
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeaderOrder, ServiceHeaderOrder."Document Type"::Order, Customer."No.");
        ServiceLineOrder.SetRange("Document Type", ServiceHeaderOrder."Document Type");
        ServiceLineOrder.SetRange("Document No.", ServiceHeaderOrder."No.");
        ServiceLineOrder.FindFirst();

        // [GIVEN] Attach document to Service Order header
        Clear(RecordRef);
        RecordRef.GetTable(ServiceHeaderOrder);
        CreateDocAttach(RecordRef, 'ServiceOrder.jpeg', false, false);

        // [GIVEN] Attach document to 1st Service Order line 
        Clear(RecordRef);
        RecordRef.GetTable(ServiceLineOrder);
        CreateDocAttach(RecordRef, 'ServiceLine.jpeg', false, false);

        // [GIVEN] Post Service Shipment from Service Order
        LibraryService.PostServiceOrder(ServiceHeaderOrder, true, false, false);

        // [GIVEN] Create Service Invoice
        ServiceInvoicePage.OpenNew();
        ServiceInvoicePage."Customer No.".SetValue(Customer."No.");
        Evaluate(InvoiceNo, ServiceInvoicePage."No.".Value);

        // [WHEN] Use 'Get Shipment Lines' to insert lines
        ServiceInvoicePage.ServLines.GetShipmentLines.Invoke(); // opens modal page "Get Shipment Lines", and handler clicks OK

        // [WHEN] Repeat use 'Get Shipment Lines' to check it will run multiple times - inserts new line with attachment
        ServiceInvoicePage.ServLines.GetShipmentLines.Invoke(); // opens modal page "Get Shipment Lines", and handler clicks OK

        // [THEN] Assert attached documents are flown to Service Invoice (one attachment)
        CheckDocAttachments(Database::"Service Header", 1, InvoiceNo, ServiceHeaderOrder."Document Type"::Invoice.AsInteger(), 'ServiceOrder');

        // [THEN] Assert Service Invoice lines have two document attachments (one per each line inserted from Service Order)
        CheckDocAttachments(Database::"Service Line", 2, InvoiceNo, ServiceHeaderOrder."Document Type"::Invoice.AsInteger(), 'ServiceLine');
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler,PrintedToAttachmentNotificationHandler')]
    procedure ServiceContractQuotePrintToAttachment_AndMakeContract()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        DocumentAttachment: Record "Document Attachment";
        SignServContractDoc: Codeunit SignServContractDoc;
        RecordRef: RecordRef;
        ServiceContractQuoteAttachedDateTime: DateTime;
        ServiceContractQuote: TestPage "Service Contract Quote";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Service Contract Quote]
        // [SCENARIO 332151] "Print to attachment" action in Service Contract Quote page makes new "Document Attachment" record.
        // [SCENARIO 332151] Transfer Service Contract Quote attachments to Service Contract on "Make Contract" action.
        Initialize();

        // [GIVEN] Service contract quote opened in the Service Contract Quote page
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Cost", 1000 * LibraryRandom.RandDec(10, 2));  // Use Random because value is not important.
        ServiceContractLine.Validate("Line Value", 10000000 * LibraryRandom.RandDec(10, 2));  // Use Random because value is not important.
        ServiceContractLine.Validate("Service Period", ServiceContractHeader."Service Period");
        ServiceContractLine.Modify(true);

        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Modify(true);

        ServiceContractQuote.OpenEdit();
        ServiceContractQuote.Filter.SetFilter("Contract No.", ServiceContractHeader."Contract No.");
        // [WHEN] "Print to attachment" function is called
        ServiceContractQuote.AttachAsPDF.Invoke();

        // [THEN] New document attachment created with "Document Flow Service"
        FindDocumentAttachment(DocumentAttachment, Database::"Service Contract Header", ServiceContractHeader."Contract No.", DocumentAttachment."Document Type"::"Service Contract Quote".AsInteger());
        DocumentAttachment.TestField("Document Flow Service", true);
        Assert.IsSubstring(DocumentAttachment."File Name", ServiceContractHeader."Contract No.");

        // [THEN] Notification "Document has been printed to attachments." displayed
        Assert.AreEqual(PrintedToAttachmentTxt, LibraryVariableStorage.DequeueText(), 'Unexpected notification.');

        LibraryNotificationMgt.RecallNotificationsForRecord(ServiceContractHeader);

        // [GIVEN] Attached date time of the Service Contract Quote
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Service Contract Header");
        DocumentAttachment.SetRange("No.", ServiceContractHeader."Contract No.");
        if DocumentAttachment.FindFirst() then
            ServiceContractQuoteAttachedDateTime := DocumentAttachment."Attached Date";

        // [GIVEN] Add 2nd attachment to Service Contract Quote
        RecordRef.GetTable(ServiceContractHeader);
        CreateDocAttachService(RecordRef, '2ndAttachment.jpeg', false);

        // [WHEN] "Make Contract" action is executed
        SignServContractDoc.SetHideDialog(true);
        SignServContractDoc.SignContractQuote(ServiceContractHeader);

        // [THEN] Service Contract Quote attachments copied to Service Contract attachments
        ServiceContractHeader.SetRange("Customer No.", ServiceContractHeader."Customer No.");
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Contract);
        ServiceContractHeader.FindFirst();

        // [THEN] 2 attachments exist for the Service Contract
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Service Contract Header");
        DocumentAttachment.SetRange("No.", ServiceContractHeader."Contract No.");
        Assert.RecordCount(DocumentAttachment, 2);

        // [THEN] Verify Time stamp change of attachments are equal
        DocumentAttachment.FindFirst();
        Assert.AreEqual(ServiceContractQuoteAttachedDateTime, DocumentAttachment."Attached Date", AttachedDateInvalidErr);
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler,PrintedToAttachmentNotificationHandler')]
    procedure ServiceContractPrintToAttachment()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        DocumentAttachment: Record "Document Attachment";
        ServiceContract: TestPage "Service Contract";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Service Contract]
        // [SCENARIO 332151] "Print to attachment" action in Service Contract page makes new "Document Attachment" record.
        Initialize();

        // [GIVEN] Service contract opened in the Service Contract page
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContract.OpenEdit();
        ServiceContract.Filter.SetFilter("Contract No.", ServiceContractHeader."Contract No.");
        // [WHEN] "Print to attachment" function is called
        ServiceContract.AttachAsPDF.Invoke();

        // [THEN] New document attachment created with "Document Flow Service"
        FindDocumentAttachment(DocumentAttachment, Database::"Service Contract Header", ServiceContractHeader."Contract No.", DocumentAttachment."Document Type"::"Service Contract".AsInteger());
        DocumentAttachment.TestField("Document Flow Service", true);
        Assert.IsSubstring(DocumentAttachment."File Name", ServiceContractHeader."Contract No.");

        // [THEN] Notification "Document has been printed to attachments." displayed
        Assert.AreEqual(PrintedToAttachmentTxt, LibraryVariableStorage.DequeueText(), 'Unexpected notification.');

        LibraryNotificationMgt.RecallNotificationsForRecord(ServiceContractHeader);
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure TestDocAttachServiceContract()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemForServiceItem: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        DocumentAttachment: Record "Document Attachment";
        RecordRef: RecordRef;
    begin
        // [SCENARIO 332151] Ensure that document attachments from the Customer/Item/Service Item flow to the Service Contract.
        Initialize();

        // [GIVEN] A Customer with 2 attachments, 1 marked to flow
        LibrarySales.CreateCustomer(Customer);
        RecordRef.GetTable(Customer);
        CreateDocAttachService(RecordRef, 'Cust1.jpeg', true);
        CreateDocAttachService(RecordRef, 'Cust2.jpeg', false);

        // [GIVEN] Item with 2 attacments, 1 marked to flow
        LibraryInventory.CreateItem(Item);
        RecordRef.GetTable(Item);
        CreateDocAttachService(RecordRef, 'Item1.jpeg', true);
        CreateDocAttachService(RecordRef, 'Item2.jpeg', false);

        // [GIVEN] Service Item with 2 attacments, 1 marked to flow
        LibraryInventory.CreateItem(ItemForServiceItem);
        RecordRef.GetTable(ItemForServiceItem);
        CreateDocAttachService(RecordRef, 'ServiceItem1.jpeg', true);
        CreateDocAttachService(RecordRef, 'ServiceItem2.jpeg', false);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        ServiceItem.Validate("Item No.", ItemForServiceItem."No.");
        ServiceItem.Modify(true);

        // [WHEN] Service Contract is created
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        // 1st line with Service Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        // 2nd line with Item
        ServiceContractLine.Init();
        ServiceContractLine.Validate("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.Validate("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.Validate("Line No.", 20000);
        ServiceContractLine.Validate("Customer No.", ServiceContractHeader."Customer No.");
        ServiceContractLine.Validate("Item No.", Item."No.");
        ServiceContractLine.Insert(true);

        // [THEN] Ensure that document attachments from the Customer/Item/Service Item flow to the Service Order. Service contract header has 1 attachment
        CheckDocAttachments(Database::"Service Contract Header", 1, ServiceContractHeader."Contract No.", DocumentAttachment."Document Type"::"Service Contract".AsInteger(), 'Cust1');

        // [THEN] Ensure that document attachments from the Customer/Item/Service Item flow to the Service Order. Service contract lines have 2 attachments
        CheckDocAttachments(Database::"Service Contract Line", 2, ServiceContractLine."Contract No.", DocumentAttachment."Document Type"::"Service Contract".AsInteger(), 'ServiceItem1');
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure TestDocAttachServiceContract_Copy()
    var
        Customer: Record Customer;
        ItemForServiceItem: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeaderFrom: Record "Service Contract Header";
        ServiceContractLineFrom: Record "Service Contract Line";
        ServiceContractHeaderTo: Record "Service Contract Header";
        ServiceContractLineTo: Record "Service Contract Line";
        DocumentAttachment: Record "Document Attachment";
        CopyServiceContractMgt: Codeunit "Copy Service Contract Mgt.";
        RecordRef: RecordRef;
    begin
        // [SCENARIO 332151] Transfer document attachments from Service Contract lines when copying Service Contract.
        Initialize();

        // [GIVEN] A Customer with 2 attachments, 1 marked to flow
        LibrarySales.CreateCustomer(Customer);
        RecordRef.GetTable(Customer);
        CreateDocAttachService(RecordRef, 'Cust1.jpeg', true);
        CreateDocAttachService(RecordRef, 'Cust2.jpeg', false);

        // [GIVEN] Service Item with 2 attacments, 1 marked to flow
        LibraryInventory.CreateItem(ItemForServiceItem);
        RecordRef.GetTable(ItemForServiceItem);
        CreateDocAttachService(RecordRef, 'ServiceItem1.jpeg', true);
        CreateDocAttachService(RecordRef, 'ServiceItem2.jpeg', false);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        ServiceItem.Validate("Item No.", ItemForServiceItem."No.");
        ServiceItem.Modify(true);

        // [GIVEN] Service Contract is created
        LibraryService.CreateServiceContractHeader(ServiceContractHeaderFrom, ServiceContractHeaderFrom."Contract Type"::Contract, Customer."No.");
        LibraryService.CreateServiceContractLine(ServiceContractLineFrom, ServiceContractHeaderFrom, ServiceItem."No.");
        ServiceContractLineFrom.Validate("Line Cost", 1000 * LibraryRandom.RandDec(10, 2));  // Use Random because value is not important.
        ServiceContractLineFrom.Validate("Line Value", 10000000 * LibraryRandom.RandDec(10, 2));  // Use Random because value is not important.
        ServiceContractLineFrom.Validate("Service Period", ServiceContractHeaderFrom."Service Period");
        ServiceContractLineFrom.Modify(true);

        ServiceContractHeaderFrom.CalcFields("Calcd. Annual Amount");
        ServiceContractHeaderFrom.Validate("Annual Amount", ServiceContractHeaderFrom."Calcd. Annual Amount");
        ServiceContractHeaderFrom.Validate("Starting Date", WorkDate());
        ServiceContractHeaderFrom.Validate("Price Update Period", ServiceContractHeaderFrom."Service Period");
        ServiceContractHeaderFrom.Modify(true);

        // [WHEN] Add attachment to Service Contract header
        RecordRef.GetTable(ServiceContractHeaderFrom);
        CreateDocAttachService(RecordRef, 'ServiceContractHeader.jpeg', false);

        // [WHEN] Add attachment to Service Contract line
        RecordRef.GetTable(ServiceContractLineFrom);
        CreateDocAttachService(RecordRef, 'ServiceContractLine.jpeg', false);

        // [THEN] Service contract header has 2 attachments
        CheckDocAttachments(Database::"Service Contract Header", 2, ServiceContractHeaderFrom."Contract No.", DocumentAttachment."Document Type"::"Service Contract".AsInteger(), 'Cust1');

        // [THEN] Service contract line has 2 attachments
        CheckDocAttachments(Database::"Service Contract Line", 2, ServiceContractLineFrom."Contract No.", DocumentAttachment."Document Type"::"Service Contract".AsInteger(), 'ServiceItem1');

        // [GIVEN] Create Service Contract to copy to and execute "Copy Document" action
        LibraryService.CreateServiceContractHeader(ServiceContractHeaderTo, ServiceContractHeaderTo."Contract Type"::Contract, ServiceContractHeaderFrom."Customer No.");
        ServiceContractHeaderTo.CalcFields("Calcd. Annual Amount");
        ServiceContractHeaderTo.Validate("Annual Amount", ServiceContractHeaderTo."Calcd. Annual Amount");
        ServiceContractHeaderTo.Validate("Starting Date", WorkDate());
        ServiceContractHeaderTo.Validate("Price Update Period", ServiceContractHeaderTo."Service Period");
        ServiceContractHeaderTo.Modify(true);

        // [WHEN] Copy Service Contract lines
        CopyServiceContractMgt.CopyServiceContractLines(
            ServiceContractHeaderTo, ServiceContractHeaderFrom."Contract Type",
            ServiceContractHeaderFrom."Contract No.", ServiceContractLineTo);

        // [THEN] Check that Service Contract Line fields are same after Copy Document.
        ServiceContractLineTo.TestField("Service Item No.", ServiceContractLineFrom."Service Item No.");
        ServiceContractLineTo.TestField("Line Value", ServiceContractLineFrom."Line Value");
        ServiceContractLineTo.TestField("New Line", true);

        // [THEN] Service contract header has 1 attachment (from Customer)
        CheckDocAttachments(Database::"Service Contract Header", 1, ServiceContractHeaderTo."Contract No.", DocumentAttachment."Document Type"::"Service Contract".AsInteger(), 'Cust1');

        // [THEN] Service contract line has 2 attachments (copied from source Service Contract line)
        CheckDocAttachments(Database::"Service Contract Line", 2, ServiceContractLineTo."Contract No.", DocumentAttachment."Document Type"::"Service Contract".AsInteger(), 'ServiceItem1');
    end;
    #endregion [Service Management]

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Document Attachment Tests");

        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        // Setup demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.SetupReportSelections();
        LibraryService.SetupServiceMgtNoSeries();
        AtLeastOneServiceContractTemplateMustExist();
        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(Database::"Service Mgt. Setup");
    end;

    local procedure CreateTempBLOBWithText(var TempBlob: Codeunit "Temp Blob"; Content: Text)
    var
        BigStr: BigText;
        OStream: OutStream;
    begin
        Clear(BigStr);
        Clear(TempBlob);
        BigStr.AddText(Content);
        TempBlob.CreateOutStream(OStream);
        BigStr.Write(OStream);
    end;

    local procedure CreateTempBLOBWithImageOfType(var TempBlob: Codeunit "Temp Blob"; ImageType: Text)
    var
        ImageFormat: DotNet ImageFormat;
        Bitmap: DotNet Bitmap;
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        Bitmap := Bitmap.Bitmap(1, 1);
        case ImageType of
            'png':
                Bitmap.Save(InStr, ImageFormat.Png);
            'jpeg':
                Bitmap.Save(InStr, ImageFormat.Jpeg);
            else
                Bitmap.Save(InStr, ImageFormat.Bmp);
        end;
        Bitmap.Dispose();
    end;

    local procedure CreateCustomReportSelection(SourceType: Integer; SourceNo: Code[20]; ReportUsage: Enum "Report Selection Usage"; ReportID: Integer)
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        CustomReportSelection."Source Type" := SourceType;
        CustomReportSelection."Source No." := SourceNo;
        CustomReportSelection.Usage := ReportUsage;
        CustomReportSelection."Report ID" := ReportID;
        CustomReportSelection.Insert();
    end;

    [Scope('OnPrem')]
    procedure CheckDocAttachments(TableId: Integer; RecCount: Integer; RecNo: Code[20]; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; FileName: Text[250])
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", TableId);
        DocumentAttachment.SetRange("No.", RecNo);
        DocumentAttachment.SetRange("Document Type", DocType);
        Assert.AreEqual(RecCount, DocumentAttachment.Count(), 'Unexpected document count.');
        Assert.IsTrue(DocumentAttachment.FindFirst(), 'Expected record missing');
        Assert.AreEqual(FileName, DocumentAttachment."File Name", 'Unexpected file attached.');
    end;

    [Scope('OnPrem')]
    procedure CheckDocAttachmentsForPostedDocs(TableId: Integer; RecCount: Integer; RecNo: Code[20]; FileName: Text[250])
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", TableId);
        DocumentAttachment.SetRange("No.", RecNo);
        Assert.AreEqual(RecCount, DocumentAttachment.Count(), 'Unexpected document count.');
        Assert.IsTrue(DocumentAttachment.FindFirst(), 'Expected record missing');
        Assert.AreEqual(FileName, DocumentAttachment."File Name", 'Unexpected file attached.');
    end;

    procedure CheckDocAttachmentsForPostedDocsCount(TableId: Integer; RecCount: Integer; RecNo: Code[20])
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", TableId);
        DocumentAttachment.SetRange("No.", RecNo);
        Assert.AreEqual(RecCount, DocumentAttachment.Count(), 'Unexpected document count.');
    end;

    local procedure AssertNoAttachmentsExist(TableId: Integer; RecNo: Code[20]; DocumentType: Enum "Attachment Document Type")
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Table ID", TableId);
        DocumentAttachment.SetRange("No.", RecNo);
        DocumentAttachment.SetRange("Document Type", DocumentType);
        Assert.RecordIsEmpty(DocumentAttachment);
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Customer: Record Customer; Item: Record Item; DocType: Enum "Sales Document Type")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    local procedure CreatePurchDoc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Vendor: Record Vendor; Item: Record Item; DocType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
    end;

    [Scope('OnPrem')]
    procedure CreateDocAttach(RecRef: RecordRef; FileName: Text[250]; FlowPurch: Boolean; FlowSales: Boolean)
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
    begin
        Clear(DocumentAttachment);
        CreateTempBLOBWithImageOfType(TempBlob, 'jpeg');
        DocumentAttachment.Init();
        DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);
        DocumentAttachment."Document Flow Purchase" := FlowPurch;
        DocumentAttachment."Document Flow Sales" := FlowSales;
        DocumentAttachment.Modify();
    end;

    local procedure CreateDocAttachService(RecRef: RecordRef; FileName: Text[250]; FlowService: Boolean)
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
    begin
        Clear(DocumentAttachment);
        CreateTempBLOBWithImageOfType(TempBlob, 'jpeg');
        DocumentAttachment.Init();
        DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);
        DocumentAttachment."Document Flow Service" := FlowService;
        DocumentAttachment.Modify();
    end;

    local procedure CopyGLAccountToNewNo(OldGLAccountNo: Code[20]; NewGLAccountNo: Code[20]; var GLAccount: Record "G/L Account")
    var
        OldGLAccount: Record "G/L Account";
    begin
        // Duplicate GL account but with specified No. (faster than rename)
        OldGLAccount.Get(OldGLAccountNo);
        GLAccount := OldGLAccount;
        GLAccount."No." := NewGLAccountNo;
        GLAccount.Insert(true);
    end;

    local procedure CreatePostSalesInvoice(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        CreateSalesLine(SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostSalesCrMemo(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        CreateSalesLine(SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceHeaderDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        DocumentAttachment."Table ID" := DATABASE::"Sales Invoice Header";
        DocumentAttachment."No." := SalesInvoiceHeader."No.";
        DocumentAttachment."File Name" :=
          CopyStr(Format(CreateGuid()), 1, MaxStrLen(DocumentAttachment."File Name"));
        DocumentAttachment.Insert();
    end;

    local procedure CreatePostPurchaseInvoice(VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        CreatePurchaseLine(PurchaseHeader);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePostPurchaseCrMemo(VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        CreatePurchaseLine(PurchaseHeader);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceHeaderDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        DocumentAttachment."Table ID" := DATABASE::"Purch. Inv. Header";
        DocumentAttachment."No." := PurchInvHeader."No.";
        DocumentAttachment."File Name" :=
          CopyStr(Format(CreateGuid()), 1, MaxStrLen(DocumentAttachment."File Name"));
        DocumentAttachment.Insert();
    end;

    local procedure FindCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; CustomerNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure FindVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20]; CustomerNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Vendor No.", CustomerNo);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure FindDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; TableId: Integer; DocumentNo: Code[20]; DocumentType: Option)
    begin
        DocumentAttachment.SetRange("Table ID", TableId);
        DocumentAttachment.SetRange("No.", DocumentNo);
        DocumentAttachment.SetRange("Document Type", DocumentType);
        DocumentAttachment.FindFirst();
    end;

    local procedure GetReportCaption(ReportID: Integer): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Report, ReportID) then
            exit(AllObjWithCaption."Object Caption");
    end;

    local procedure GetExpectedAttachmentFileName(ReportId: Integer; DocumentNo: Code[20]): Text
    begin
        exit(StrSubstNo('%1 %2 %3', ReportId, GetReportCaption(ReportId), DocumentNo));
    end;

    local procedure MockDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; TableId: Integer; DocumentNo: Code[20]; DocumentType: Enum "Attachment Document Type"; FileName: Text; FileExtension: Text)
    begin
        Clear(DocumentAttachment);
        DocumentAttachment."Table ID" := TableId;
        DocumentAttachment."No." := DocumentNo;
        DocumentAttachment."Document Type" := DocumentType;
        DocumentAttachment."File Name" := CopyStr(FileName, 1, MaxStrLen(DocumentAttachment."File Name"));
        DocumentAttachment."File Extension" := CopyStr(FileExtension, 1, MaxStrLen(DocumentAttachment."File Extension"));
        DocumentAttachment.Insert();
    end;

    local procedure CheckDocAttachmentAttachedDate(SalesQuoteNo: Code[20]; SalesQuoteAttachedDate: DateTime)
    var
        SalesHaderOrder: Record "Sales Header";
        DocumentAttachment: Record "Document Attachment";
    begin
        SalesHaderOrder.Reset();
        SalesHaderOrder.SetRange("Document Type", SalesHaderOrder."Document Type"::Order);
#pragma warning disable AA0210
        SalesHaderOrder.SetRange("Quote No.", SalesQuoteNo);
#pragma warning restore AA0210
        SalesHaderOrder.FindFirst();

        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Sales Header");
        DocumentAttachment.SetRange("Document Type", SalesHaderOrder."Document Type"::Order);
        DocumentAttachment.SetRange("No.", SalesHaderOrder."No.");
        if DocumentAttachment.FindFirst() then;

        Assert.AreEqual(SalesQuoteAttachedDate, DocumentAttachment."Attached Date", AttachedDateInvalidErr);
    end;

    procedure SetupReportSelection(ReportUsage: Enum "Report Selection Usage"; ReportId: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportUsage);
        ReportSelections.DeleteAll();
        ReportSelections.Init();
        ReportSelections.Usage := ReportUsage;
        ReportSelections.Sequence := '1';
        ReportSelections."Report ID" := ReportId;
        ReportSelections.Insert(true);
    end;

    local procedure CreateImage(var ImageBlob: Codeunit "Temp Blob")
    var
        Base64Convert: Codeunit "Base64 Convert";
        ImageAsBase64Txt: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;
        OutStream: OutStream;
    begin
        ImageBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(ImageAsBase64Txt, OutStream);
    end;

    local procedure AtLeastOneServiceContractTemplateMustExist()
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        if not ServiceContractTemplate.IsEmpty() then
            exit;

        ServiceContractTemplate.Init();
        ServiceContractTemplate.Insert(true);
    end;

    [ModalPageHandler]
    procedure RelatedAttachmentsHandler(var RelatedAttachmentsPage: TestPage "Email Related Attachments")
    begin
        RelatedAttachmentsPage.First();
        Assert.AreEqual('foo.jpeg', RelatedAttachmentsPage.FileName.Value(), 'Wrong attachment');
        Assert.IsFalse(RelatedAttachmentsPage.Next(), 'Unexpected related attachment, only one is expected');
        RelatedAttachmentsPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ListSalesFlow(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Sales".Visible(), 'Expected field not visible');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Sales".Editable(), 'Field should be disabled');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Purchase".Visible(), 'Unexpected field visible');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Service".Visible(), 'Unexpected field visible');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ListItemFlow(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Sales".Visible(), 'Expected field not visible');
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Sales".Editable(), 'Expected field not editable');
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Purchase".Visible(), 'Expected field not visible');
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Purchase".Editable(), 'Expected field not editable');
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Service".Visible(), 'Expected field not visible');
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Service".Editable(), 'Expected field not editable');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ListPurchFlow(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Sales".Visible(), 'Unexpected field visible');
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Purchase".Visible(), 'Expected field not visible');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Purchase".Editable(), 'Expected field should be disabled.');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Service".Visible(), 'Unexpected field visible');
    end;

    [ModalPageHandler]
    procedure ListServiceItemFlow(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Sales".Visible(), 'Expected field visible');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Purchase".Visible(), 'Expected field visible');
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Service".Visible(), 'Expected field not visible');
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Service".Editable(), 'Expected field not editable');
    end;

    [ModalPageHandler]
    procedure ListServiceFlow(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Service".Visible(), 'Expected field not visible');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Service".Editable(), 'Field should be disabled');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Sales".Visible(), 'Unexpected field visible');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Purchase".Visible(), 'Unexpected field visible');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ListResourceFlow(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Sales".Visible(), 'Unexpected field visible');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Purchase".Visible(), 'Unexpected field visible');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Service".Visible(), 'Unexpected field visible');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DocumentAttachmentDetailsMPH(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        LibraryVariableStorage.Enqueue(Format(DocumentAttachmentDetails.Name));
        DocumentAttachmentDetails.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntryCheckShowDocAttachMPH(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        LibraryVariableStorage.Enqueue(ApplyCustomerEntries.ShowDocumentAttachment.Enabled());
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntryChooseShowDocAttachMPH(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.ShowDocumentAttachment.Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AppliedCustomerEntriesCheckShowDocAttachPH(var AppliedCustomerEntries: TestPage "Applied Customer Entries")
    begin
        LibraryVariableStorage.Enqueue(AppliedCustomerEntries.ShowDocumentAttachment.Enabled());
        AppliedCustomerEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AppliedCustomerEntriesChooseShowDocAttachPH(var AppliedCustomerEntries: TestPage "Applied Customer Entries")
    begin
        AppliedCustomerEntries.ShowDocumentAttachment.Invoke();
        AppliedCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntryCheckShowDocAttachMPH(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        LibraryVariableStorage.Enqueue(ApplyVendorEntries.ShowDocumentAttachment.Enabled());
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntryChooseShowDocAttachMPH(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ShowDocumentAttachment.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure GetServiceShipmentLinesPageHandler(var GetServiceShipmentLines: TestPage "Get Service Shipment Lines")
    begin
        GetServiceShipmentLines.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AppliedVendorEntriesCheckShowDocAttachPH(var AppliedVendorEntries: TestPage "Applied Vendor Entries")
    begin
        LibraryVariableStorage.Enqueue(AppliedVendorEntries.ShowDocumentAttachment.Enabled());
        AppliedVendorEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AppliedVendorEntriesChooseShowDocAttachPH(var AppliedVendorEntries: TestPage "Applied Vendor Entries")
    begin
        AppliedVendorEntries.ShowDocumentAttachment.Invoke();
        AppliedVendorEntries.OK().Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure PrintedToAttachmentNotificationHandler(var Notification: Notification): Boolean
    begin
        if RecallNotifications then begin
            Notification.Recall();
            exit(true);
        end;
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CloseEmailEditorHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SalesOrderMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerDeleteYesDefaultYes(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, DeleteAttachmentsConfirmQst) > 0 then
            Reply := true
        else
            Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerDeleteNoDefaultYes(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, DeleteAttachmentsConfirmQst) > 0 then
            Reply := false
        else
            Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure QuoteToOrderConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        case true of
            StrPos(Question, ConfirmConvertToOrderQst) > 0:
                begin
                    Reply := true;
                    exit;
                end;
            StrPos(Question, ConfirmOpeningNewOrderAfterQuoteToOrderQst) > 0:
                begin
                    Reply := false;
                    exit;
                end;
        end;
        Assert.Fail('Wrong question: ' + Question);
    end;

    [ConfirmHandler]
    procedure ServiceConfirmHandler(ConfirmMessage: Text[1024]; var Result: Boolean)
    begin
        Result := false; // Do not use Template
    end;
}

