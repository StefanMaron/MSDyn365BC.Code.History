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
        NoContentErr: Label 'The selected file has no content. Please choose another file.';
        DuplicateErr: Label 'This file is already attached to the document. Please choose another file.';
        PrintedToAttachmentTxt: Label 'The document has been printed to attachments.';
        NoSaveToPDFReportTxt: Label 'There are no reports which could be saved to PDF for this document.';
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
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
        ReportSelectionUsage: Enum "Report Selection Usage";
        isInitialized: Boolean;

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
        Initialize;
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
        Initialize;
        DocumentAttachment.Init();

        RecRef.GetTable(Customer);

        CreateTempBLOBWithImageOfType(TempBlob, 'jpeg');
        DocumentAttachment.SaveAttachment(RecRef, 'image.jpeg', TempBlob);

        // Verify FileType is set to image
        Assert.AreEqual('Image', Format(DocumentAttachment."File Type"::Image), 'File type is not equal to image.');

        // Verify user security id
        Assert.AreEqual(UserSecurityId, DocumentAttachment."Attached By", 'AttachedBy is not eqal to USERSECURITYID');

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
        Assert.IsFalse(DocumentAttachment."Document Flow Sales", 'Document flow is true.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureDuplicateFileWithSameNameAndExtIsNotSaved()
    var
        Customer: Record Customer;
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Ensure duplicate file name with same extension is not saved. For example saving 'test.jpeg' twice is NOT allowed.

        // [GIVEN] Two Image files
        // [WHEN] Save attachment function is called twice
        // [THEN] Duplicate file error is shown.
        // Initialize
        Initialize;
        DocumentAttachment.Init();
        CreateTempBLOBWithImageOfType(TempBlob, 'jpeg');

        RecRef.GetTable(Customer);

        // Save first time
        DocumentAttachment.SaveAttachment(RecRef, 'test.jpeg', TempBlob);

        // Save second time
        asserterror DocumentAttachment.SaveAttachment(RecRef, 'test.jpeg', TempBlob);
        Assert.ExpectedError(DuplicateErr);
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
        Initialize;
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
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Ensure attached documents for a vendor can be deleted.
        // [GIVEN] Two attached documents for a vendor
        // [WHEN] DeleteDocAttachments is called on COD1173
        // [THEN] All the attached documents are deleted for vendor.
        // Initialize
        Initialize;
        localVendor.Init();
        localVendor."No." := '22';
        localVendor.Insert();

        DocumentAttachment.Init();

        RecRef.GetTable(localVendor);

        CreateTempBLOBWithImageOfType(TempBlob, 'jpeg');

        // Save first file (test.jpeg)
        DocumentAttachment.SaveAttachment(RecRef, 'foo.jpeg', TempBlob);
        Clear(DocumentAttachment);

        // Create and save a png file (test.png)
        DocumentAttachment.Init();
        CreateTempBLOBWithImageOfType(TempBlob, 'jpeg');
        DocumentAttachment.SaveAttachment(RecRef, 'bar.jpeg', TempBlob);
        Clear(DocumentAttachment);

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
        Initialize;
        LibraryResource.CreateResourceNew(Resource);
        RecRef.GetTable(Resource);

        // [WHEN] The DocumentAttachmentDetails window opens.
        // [THEN] 0 flow fields are visible.
        DocumentAttachmentDetails.OpenForRecRef(RecRef);
        DocumentAttachmentDetails.RunModal;
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
        Initialize;
        LocalItem.Init();
        LocalItem."No." := '2';
        LocalItem.Insert();

        RecRef.GetTable(LocalItem);

        // [WHEN] The DocumentAttachmentDetails window opens.
        // [THEN] 2 flow fields are visible and editable.
        DocumentAttachmentDetails.OpenForRecRef(RecRef);
        DocumentAttachmentDetails.RunModal;

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
        Initialize;
        LocalSalesLine.Init();
        LocalSalesLine."Document No." := '2';
        LocalSalesLine."Line No." := 1000;
        LocalSalesLine.Insert();

        RecRef.GetTable(LocalSalesLine);

        // [WHEN] The DocumentAttachmentDetails window opens.
        // [THEN] the sales doc flow fields is visible and editable.

        DocumentAttachmentDetails.OpenForRecRef(RecRef);
        DocumentAttachmentDetails.RunModal;

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
        Initialize;
        LocalPurchaseLine.Init();
        LocalPurchaseLine."No." := '2';
        LocalPurchaseLine."Line No." := 1000;
        LocalPurchaseLine.Insert();

        RecRef.GetTable(LocalPurchaseLine);

        // [WHEN] The DocumentAttachmentDetails window opens.
        // [THEN] the purch doc flow fields is visible and editable.
        DocumentAttachmentDetails.OpenForRecRef(RecRef);
        DocumentAttachmentDetails.RunModal;

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
        Initialize;

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
        CheckDocAttachments(DATABASE::"Sales Header", 1, SalesHeader."No.", SalesHeader."Document Type", 'cust1');

        // [THEN] the sales line has one attachment.
        CheckDocAttachments(DATABASE::"Sales Line", 1, SalesLine."Document No.", SalesLine."Document Type", 'item1');
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
        Initialize;

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

        CheckDocAttachments(DATABASE::"Purchase Header", 1, PurchaseHeader."No.", PurchaseHeader."Document Type", 'vend1');

        // [THEN] the sales line has one attachment.

        CheckDocAttachments(DATABASE::"Purchase Line", 1, PurchaseLine."Document No.", PurchaseLine."Document Type", 'item1');
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
        Initialize;
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
        Assert.IsTrue(SalesHeaderQuote.FindFirst, 'Sales order was created from quote.');
        Assert.AreEqual(SalesHeaderQuote."Document Type"::Order, SalesHeaderQuote."Document Type",
          'Sales quote is not converted to sales order');
        Assert.AreEqual(QuoteNo, SalesHeaderQuote."Quote No.", 'Sales order does not have expected quote number.');

        OrderNo := SalesHeaderQuote."No.";

        // [THEN] Assert docs are flown to sales order
        CheckDocAttachments(DATABASE::"Sales Header", 1, OrderNo, SalesHeaderQuote."Document Type"::Order, 'salesquote');

        // [THEN] the sales line has one attachment for sales order
        CheckDocAttachments(DATABASE::"Sales Line", 1, OrderNo, SalesHeaderQuote."Document Type"::Order, 'salesline');
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
        Initialize;
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
        Assert.IsTrue(SalesHeader.FindFirst, 'Sales Invoice was not created from Sales Quote.');
        Assert.AreEqual(SalesHeader."Document Type"::Invoice, SalesHeader."Document Type",
          'Sales quote is not converted to sales invoice');
        Assert.AreEqual(QuoteNo, SalesHeader."Quote No.", 'Sales Invoice does not have expected Sales Quote number.');

        InvoiceNo := SalesHeader."No.";

        // [THEN] Assert docs are flown to Sales Invoice
        CheckDocAttachments(DATABASE::"Sales Header", 1, InvoiceNo, SalesHeader."Document Type"::Invoice, 'salesquote');

        // [THEN] the sales line should have one document attachment for sales invoice
        CheckDocAttachments(DATABASE::"Sales Line", 1, InvoiceNo, SalesHeader."Document Type"::Invoice, 'salesline');
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
        Initialize;
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
        Assert.IsTrue(PurchaseHeader.FindFirst, 'Purch order was not created from quote.');
        Assert.AreEqual(PurchaseHeader."Document Type"::Order, PurchaseHeader."Document Type",
          'Purch quote is not converted to purch order');
        Assert.AreEqual(QuoteNo, PurchaseHeader."Quote No.", 'Purch order does not have expected quote number.');

        OrderNo := PurchaseHeader."No.";

        // [THEN] Assert docs are flown to purch order
        CheckDocAttachments(DATABASE::"Purchase Header", 1, OrderNo, PurchaseHeader."Document Type"::Order, 'purchquote');

        // [THEN] the sales line has one attachment for purch order
        CheckDocAttachments(DATABASE::"Purchase Line", 1, OrderNo, PurchaseHeader."Document Type"::Order, 'purchline');
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
        Initialize;

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
        PurchaseHeader.FindFirst;

        OrderNo := PurchaseHeader."No.";

        // [THEN] Assert docs are flown to purch order
        CheckDocAttachments(DATABASE::"Purchase Header", 1, OrderNo, PurchaseHeader."Document Type"::Order, 'purchblanket');

        // [THEN] the purch line has one attachment for purch order
        CheckDocAttachments(DATABASE::"Purchase Line", 1, OrderNo, PurchaseHeader."Document Type"::Order, 'purchblanketline');
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
        Initialize;

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
        Assert.IsTrue(PurchaseHeader.FindFirst, 'Purch invoice was not created with the expected vendor No.');
        Assert.AreEqual(PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Document Type",
          'Unexpected Document Type for Purchase Header');

        // Assert purchase line is created with the expected Purchase header Document No. and Item No.
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.IsTrue(PurchaseLine.FindFirst, 'Purchase line not created for Purchase header');
        Assert.AreEqual(PurchaseLine."Document Type"::Invoice, PurchaseLine."Document Type", 'Unexpected Document Type for Purchase Line');
        Assert.AreEqual(Item."No.", PurchaseLine."No.", 'Unexpected Item No. in Purchase Line');

        // [THEN] Assert docs are flown to purch invoice at the header level
        CheckDocAttachments(
          DATABASE::"Purchase Header", 1, PurchaseHeader."No.", PurchaseHeader."Document Type"::Invoice, 'vendortopurchinvoiceheader');

        // [THEN] Assert docs are flown to purch invoice at the item line level
        CheckDocAttachments(
          DATABASE::"Purchase Line", 1, PurchaseLine."Document No.", PurchaseHeader."Document Type"::Invoice, 'itemtopurchinvoiceline');
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
        Initialize;

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(CreatePostSalesInvoice(LibrarySales.CreateCustomerNo));

        // [GIVEN] Add attachment to Sales invoice
        CreateSalesInvoiceHeaderDocumentAttachment(DocumentAttachment, SalesInvoiceHeader);

        // [WHEN] Customer Ledger Entries page is being opened for posted sales invoice
        FindCustLedgEntry(CustLedgerEntry, SalesInvoiceHeader."No.", SalesInvoiceHeader."Sell-to Customer No.");
        CustomerLedgerEntries.OpenView;
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));

        // [THEN] Action "Show Posted Document Attachment" is enabled
        Assert.IsTrue(
          CustomerLedgerEntries.ShowDocumentAttachment.Enabled,
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
        Initialize;

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(CreatePostSalesInvoice(LibrarySales.CreateCustomerNo));

        // [GIVEN] Add attachment to sales invoice with file name "FILE"
        CreateSalesInvoiceHeaderDocumentAttachment(DocumentAttachment, SalesInvoiceHeader);

        // [GIVEN] Open Customer Ledger Entries page with posted sales invoice entry
        FindCustLedgEntry(CustLedgerEntry, SalesInvoiceHeader."No.", SalesInvoiceHeader."Sell-to Customer No.");
        CustomerLedgerEntries.OpenView;
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));

        // [WHEN] Action "Show Posted Document Attachment" is being choosen
        CustomerLedgerEntries.ShowDocumentAttachment.Invoke;

        // [THEN] Page Document Attachment Details opened with file name = "FILE"
        Assert.AreEqual(
          DocumentAttachment."File Name",
          LibraryVariableStorage.DequeueText,
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
        Initialize;

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(CreatePostSalesInvoice(LibrarySales.CreateCustomerNo));

        // [GIVEN] Add attachment to sales invoice
        CreateSalesInvoiceHeaderDocumentAttachment(DocumentAttachment, SalesInvoiceHeader);

        // [GIVEN] Posted Sales Cr. Memo
        SalesCrMemoHeader.Get(CreatePostSalesCrMemo(SalesInvoiceHeader."Sell-to Customer No."));

        // [GIVEN] Open Customer Ledger Entries page for posted credit memo
        FindCustLedgEntry(CustLedgerEntry, SalesCrMemoHeader."No.", SalesInvoiceHeader."Sell-to Customer No.");
        CustomerLedgerEntries.OpenView;
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));

        // [WHEN] Choose Apply Entries
        CustomerLedgerEntries."Apply Entries".Invoke;

        // [THEN] Action "Show Posted Document Attachment" for sales invoice is enabled
        Assert.IsTrue(
          LibraryVariableStorage.DequeueBoolean,
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
        Initialize;

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(CreatePostSalesInvoice(LibrarySales.CreateCustomerNo));

        // [GIVEN] Add attachment to sales invoice with file name "FILE"
        CreateSalesInvoiceHeaderDocumentAttachment(DocumentAttachment, SalesInvoiceHeader);

        // [GIVEN] Posted Sales Cr. Memo
        SalesCrMemoHeader.Get(CreatePostSalesCrMemo(SalesInvoiceHeader."Sell-to Customer No."));

        // [GIVEN] Open Customer Ledger Entries page for posted credit memo
        FindCustLedgEntry(CustLedgerEntry, SalesInvoiceHeader."No.", SalesInvoiceHeader."Sell-to Customer No.");
        CustomerLedgerEntries.OpenView;
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));

        // [GIVEN] Choose Apply Entries
        CustomerLedgerEntries."Apply Entries".Invoke;

        // [WHEN] Action "Show Posted Document Attachment" is being choosen
        CustomerLedgerEntries.ShowDocumentAttachment.Invoke;

        // [THEN] Page Document Attachment Details opened with file name = "FILE"
        Assert.AreEqual(
          DocumentAttachment."File Name",
          LibraryVariableStorage.DequeueText,
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
        Initialize;

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(CreatePostSalesInvoice(LibrarySales.CreateCustomerNo));

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
        CustomerLedgerEntries.OpenView;
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));

        // [WHEN] Open applied entries page
        CustomerLedgerEntries.AppliedEntries.Invoke;

        // [THEN] Action "Show Posted Document Attachment" for sales invoice is enabled
        Assert.IsTrue(
          LibraryVariableStorage.DequeueBoolean,
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
        Initialize;

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(CreatePostSalesInvoice(LibrarySales.CreateCustomerNo));

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
        CustomerLedgerEntries.OpenView;
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));

        // [WHEN] Open applied entries page and action "Show Posted Document Attachment" is being choosen
        CustomerLedgerEntries.AppliedEntries.Invoke;

        // [THEN] Page Document Attachment Details opened with file name = "FILE"
        Assert.AreEqual(
          DocumentAttachment."File Name",
          LibraryVariableStorage.DequeueText,
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
        Initialize;

        // [GIVEN] Posted Purchase Invoice
        PurchInvHeader.Get(CreatePostPurchaseInvoice(LibraryPurchase.CreateVendorNo));

        // [GIVEN] Add attachment to purchase invoice
        CreatePurchaseInvoiceHeaderDocumentAttachment(DocumentAttachment, PurchInvHeader);

        // [WHEN] Vendor Ledger Entries page is being opened for posted purchase invoice
        FindVendLedgEntry(VendorLedgerEntry, PurchInvHeader."No.", PurchInvHeader."Buy-from Vendor No.");
        VendorLedgerEntries.OpenView;
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(VendorLedgerEntry."Entry No."));

        // [THEN] Action "Show Posted Document Attachment" is enabled
        Assert.IsTrue(
          VendorLedgerEntries.ShowDocumentAttachment.Enabled,
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
        Initialize;

        // [GIVEN] Posted Purchase Invoice
        PurchInvHeader.Get(CreatePostPurchaseInvoice(LibraryPurchase.CreateVendorNo));

        // [GIVEN] Add attachment to purchase invoice
        CreatePurchaseInvoiceHeaderDocumentAttachment(DocumentAttachment, PurchInvHeader);

        // [WHEN] Vendor Ledger Entries page is being opened for posted purchase invoice
        FindVendLedgEntry(VendorLedgerEntry, PurchInvHeader."No.", PurchInvHeader."Buy-from Vendor No.");
        VendorLedgerEntries.OpenView;
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(VendorLedgerEntry."Entry No."));

        // [WHEN] Action "Show Posted Document Attachment" is being choosen
        VendorLedgerEntries.ShowDocumentAttachment.Invoke;

        // [THEN] Page Document Attachment Details opened with file name = "FILE"
        Assert.AreEqual(
          DocumentAttachment."File Name",
          LibraryVariableStorage.DequeueText,
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
        Initialize;

        // [GIVEN] Posted Purchase Invoice
        PurchInvHeader.Get(CreatePostPurchaseInvoice(LibraryPurchase.CreateVendorNo));

        // [GIVEN] Add attachment to purchase invoice
        CreatePurchaseInvoiceHeaderDocumentAttachment(DocumentAttachment, PurchInvHeader);

        // [GIVEN] Posted Purchase Cr. Memo
        PurchCrMemoHdr.Get(CreatePostPurchaseCrMemo(PurchInvHeader."Buy-from Vendor No."));

        // [GIVEN] Open Vendor Ledger Entries page for posted credit memo
        FindVendLedgEntry(VendorLedgerEntry, PurchCrMemoHdr."No.", PurchInvHeader."Buy-from Vendor No.");
        VendorLedgerEntries.OpenView;
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(VendorLedgerEntry."Entry No."));

        // [WHEN] Choose Apply Entries
        VendorLedgerEntries.ActionApplyEntries.Invoke;

        // [THEN] Action "Show Posted Document Attachment" for purchase invoice is enabled
        Assert.IsTrue(
          LibraryVariableStorage.DequeueBoolean,
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
        Initialize;

        // [GIVEN] Posted Purchase Invoice
        PurchInvHeader.Get(CreatePostPurchaseInvoice(LibraryPurchase.CreateVendorNo));

        // [GIVEN] Add attachment to purchase invoice
        CreatePurchaseInvoiceHeaderDocumentAttachment(DocumentAttachment, PurchInvHeader);

        // [GIVEN] Posted Purchase Cr. Memo
        PurchCrMemoHdr.Get(CreatePostPurchaseCrMemo(PurchInvHeader."Buy-from Vendor No."));

        // [GIVEN] Open Vendor Ledger Entries page for posted credit memo
        FindVendLedgEntry(VendorLedgerEntry, PurchCrMemoHdr."No.", PurchInvHeader."Buy-from Vendor No.");
        VendorLedgerEntries.OpenView;
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(VendorLedgerEntry."Entry No."));

        // [WHEN] Choose Apply Entries
        VendorLedgerEntries.ActionApplyEntries.Invoke;

        // [WHEN] Action "Show Posted Document Attachment" is being choosen
        VendorLedgerEntries.ShowDocumentAttachment.Invoke;

        // [THEN] Page Document Attachment Details opened with file name = "FILE"
        Assert.AreEqual(
          DocumentAttachment."File Name",
          LibraryVariableStorage.DequeueText,
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
        Initialize;

        // [GIVEN] Posted Purchase Invoice
        PurchInvHeader.Get(CreatePostPurchaseInvoice(LibraryPurchase.CreateVendorNo));

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
        VendorLedgerEntries.OpenView;
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(VendorLedgerEntry."Entry No."));

        // [WHEN] Open applied entries page
        VendorLedgerEntries.AppliedEntries.Invoke;

        // [THEN] Action "Show Posted Document Attachment" for purchase invoice is enabled
        Assert.IsTrue(
          LibraryVariableStorage.DequeueBoolean,
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
        Initialize;

        // [GIVEN] Posted Purchase Invoice
        PurchInvHeader.Get(CreatePostPurchaseInvoice(LibraryPurchase.CreateVendorNo));

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
        VendorLedgerEntries.OpenView;
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(VendorLedgerEntry."Entry No."));

        // [WHEN] Open applied entries page and action "Show Posted Document Attachment" is being choosen
        VendorLedgerEntries.AppliedEntries.Invoke;

        // [THEN] Page Document Attachment Details opened with file name = "FILE"
        Assert.AreEqual(
          DocumentAttachment."File Name",
          LibraryVariableStorage.DequeueText,
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
        Initialize;
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Customer with an attachment
        RecRef.GetTable(Customer);
        CreateDocAttach(RecRef, 'cust1.jpeg', false, true);
        CreateDocAttach(RecRef, 'cust2.jpeg', false, false);

        // [WHEN] No. is changed
        Customer.Rename('T');

        // [THEN] No errors. Verfiy document attachments are retained with all the properties
        DocumentAttachment.Init();
        DocumentAttachment.SetRange("Table ID", RecRef.Number);
        DocumentAttachment.SetRange("No.", 'T');
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');
        DocumentAttachment.FindFirst;
        Assert.AreEqual(DocumentAttachment."File Name", 'cust1', 'First file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for first attachment.');
        Assert.IsTrue(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for first attachment.');
        DocumentAttachment.FindLast;
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
        Initialize;
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Vendor with an attachment
        RecRef.GetTable(Vendor);
        CreateDocAttach(RecRef, 'ven1.jpeg', false, true);
        CreateDocAttach(RecRef, 'ven2.jpeg', false, false);

        // [WHEN] No. is changed
        Vendor.Rename('T');

        // [THEN] No errors. Verfiy document attachments are retained with all the properties
        DocumentAttachment.Init();
        DocumentAttachment.SetRange("Table ID", RecRef.Number);
        DocumentAttachment.SetRange("No.", 'T');
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');
        DocumentAttachment.FindFirst;
        Assert.AreEqual(DocumentAttachment."File Name", 'ven1', 'First file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for first attachment.');
        Assert.IsTrue(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for first attachment.');
        DocumentAttachment.FindLast;
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
        Initialize;
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Item with an attachment
        RecRef.GetTable(Item);
        CreateDocAttach(RecRef, 'item1.jpeg', false, true);
        CreateDocAttach(RecRef, 'item2.jpeg', false, false);

        // [WHEN] No. is changed
        Item.Rename('T');

        // [THEN] No errors. Verfiy document attachments are retained with all the properties
        DocumentAttachment.Init();
        DocumentAttachment.SetRange("Table ID", RecRef.Number);
        DocumentAttachment.SetRange("No.", 'T');
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');
        DocumentAttachment.FindFirst;
        Assert.AreEqual(DocumentAttachment."File Name", 'item1', 'First file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for first attachment.');
        Assert.IsTrue(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for first attachment.');
        DocumentAttachment.FindLast;
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
        Initialize;
        LibraryHumanResource.CreateEmployee(Employee);

        // [GIVEN] Employee with an attachment
        RecRef.GetTable(Employee);
        CreateDocAttach(RecRef, 'emp1.jpeg', false, true);
        CreateDocAttach(RecRef, 'emp2.jpeg', false, false);

        // [WHEN] No. is changed
        Employee.Rename('T');

        // [THEN] No errors. Verfiy document attachments are retained with all the properties
        DocumentAttachment.Init();
        DocumentAttachment.SetRange("Table ID", RecRef.Number);
        DocumentAttachment.SetRange("No.", 'T');
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');
        DocumentAttachment.FindFirst;
        Assert.AreEqual(DocumentAttachment."File Name", 'emp1', 'First file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for first attachment.');
        Assert.IsTrue(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for first attachment.');
        DocumentAttachment.FindLast;
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
        Initialize;
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);

        // [GIVEN] Fixed Asset with an attachment
        RecRef.GetTable(FixedAsset);
        CreateDocAttach(RecRef, 'fa1.jpeg', false, true);
        CreateDocAttach(RecRef, 'fa2.jpeg', false, false);

        // [WHEN] No. is changed
        FixedAsset.Rename('T');

        // [THEN] No errors. Verfiy document attachments are retained with all the properties
        DocumentAttachment.Init();
        DocumentAttachment.SetRange("Table ID", RecRef.Number);
        DocumentAttachment.SetRange("No.", 'T');
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');
        DocumentAttachment.FindFirst;
        Assert.AreEqual(DocumentAttachment."File Name", 'fa1', 'First file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for first attachment.');
        Assert.IsTrue(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for first attachment.');
        DocumentAttachment.FindLast;
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
        Initialize;
        LibraryResource.CreateResourceNew(Resource);

        // [GIVEN] Resource with an attachment
        RecRef.GetTable(Resource);
        CreateDocAttach(RecRef, 're1.jpeg', false, true);
        CreateDocAttach(RecRef, 're2.jpeg', false, false);

        // [WHEN] No. is changed
        Resource.Rename('T');

        // [THEN] No errors. Verfiy document attachments are retained with all the properties
        DocumentAttachment.Init();
        DocumentAttachment.SetRange("Table ID", RecRef.Number);
        DocumentAttachment.SetRange("No.", 'T');
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');
        DocumentAttachment.FindFirst;
        Assert.AreEqual(DocumentAttachment."File Name", 're1', 'First file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for first attachment.');
        Assert.IsTrue(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for first attachment.');
        DocumentAttachment.FindLast;
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
        Initialize;
        LibraryJob.CreateJob(Job);

        // [GIVEN] Job with an attachment
        RecRef.GetTable(Job);
        CreateDocAttach(RecRef, 'job1.jpeg', false, true);
        CreateDocAttach(RecRef, 'job2.jpeg', false, false);

        // [WHEN] No. is changed
        Job.Rename('T');

        // [THEN] No errors. Verfiy document attachments are retained with all the properties
        DocumentAttachment.Init();
        DocumentAttachment.SetRange("Table ID", RecRef.Number);
        DocumentAttachment.SetRange("No.", 'T');
        Assert.AreEqual(2, DocumentAttachment.Count, 'Two attachments were expected for this record.');
        DocumentAttachment.FindFirst;
        Assert.AreEqual(DocumentAttachment."File Name", 'job1', 'First file name not equal to saved attachment.');
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Flow purchase value not equal for first attachment.');
        Assert.IsTrue(DocumentAttachment."Document Flow Sales", 'Flow sales value not equal for first attachment.');
        DocumentAttachment.FindLast;
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
        Initialize;

        // [GIVEN] Sales quote with "Document No." = "1001" opened in the Sales Quote Card page
        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader, LibrarySales.CreateCustomerNo());
        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", SalesHeader."No.");
        // [WHEN] "Print to attachment" function is called
        SalesQuote.AttachAsPDF.Invoke();

        // [THEN] New document attachment created with "Document Flow Sales" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type");
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
        Initialize;

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
        Initialize;

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
        Initialize;

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
        Initialize;

        // [GIVEN] Purchase quote with "Document No." = "1001" opened in the Purchase Quote Card page
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);
        PurchaseQuote.OpenEdit();
        PurchaseQuote.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [WHEN] "Print to attachment" function is called
        PurchaseQuote.AttachAsPDF.Invoke();

        // [THEN] New document attachment created with "Document Flow Purchase" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Purchase Header", PurchaseHeader."No.", PurchaseHeader."Document Type");
        DocumentAttachment.TestField("Document Flow Purchase", true);

        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteForVendorPrintToAttachment()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentAttachment: Record "Document Attachment";
        ReportSelectionUsage: Enum "Report Selection Usage";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI] [Print to Attachment] [Purchase Quote]
        // [SCENARIO 278831] "Print to attachment" action on purchase quote page makes an attachment of report which is set up for particular vendor
        Initialize;

        // [GIVEN] Purchase quote for vendor "V" with "Document No." = "1001" opened in the Purchase Quote Card page
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);
        PurchaseQuote.OpenEdit();
        PurchaseQuote.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [GIVEN] Vendor "V" have a report selection setup to print qoute with report 204
        CreateCustomReportSelection(Database::Vendor, PurchaseHeader."Pay-to Vendor No.", ReportSelectionUsage::"P.Quote", Report::"Purchase - Quote");
        // [WHEN] "Print to attachment" function is called
        PurchaseQuote.AttachAsPDF.Invoke();

        // [THEN] New document attachment created with "File Name" = "204 Purchase Quote 1001"
        FindDocumentAttachment(DocumentAttachment, Database::"Purchase Header", PurchaseHeader."No.", PurchaseHeader."Document Type");
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
        Initialize;

        // [GIVEN] Sales order
        LibrarySales.CreateSalesOrder(SalesHeader);

        // [WHEN] "Print to attachment" function is called with "Order Confirmation" strmenu choice
        LibraryVariableStorage.Enqueue("Sales Order Print Option"::"Order Confirmation");
        SalesHeader.SetRecFilter();
        DocPrint.PrintSalesOrderToDocumentAttachment(SalesHeader, DocPrint.GetSalesOrderPrintToAttachmentOption((SalesHeader)));

        // [THEN] New document attachment created with "Document Flow Sales" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type"::Order);
        DocumentAttachment.TestField("Document Flow Sales", true);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Standard Sales - Order Conf.", SalesHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
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
        Initialize;

        // [GIVEN] Sales order
        LibrarySales.CreateSalesOrder(SalesHeader);

        // [WHEN] "Print to attachment" function is called with "Pick Instruction" strmenu choice
        LibraryVariableStorage.Enqueue("Sales Order Print Option"::"Pick Instruction");
        SalesHeader.SetRecFilter();
        DocPrint.PrintSalesOrderToDocumentAttachment(SalesHeader, DocPrint.GetSalesOrderPrintToAttachmentOption((SalesHeader)));

        // [THEN] New document attachment created with "Document Flow Sales" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type"::Order);
        DocumentAttachment.TestField("Document Flow Sales", true);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Pick Instruction", SalesHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
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
        Initialize;

        // [GIVEN] Sales order
        LibrarySales.CreateSalesOrder(SalesHeader);

        // [WHEN] "Print to attachment" function is called with "Pro Forma Invoice" strmenu choice
        LibraryVariableStorage.Enqueue("Sales Order Print Option"::"Pro Forma Invoice");
        SalesHeader.SetRecFilter();
        DocPrint.PrintSalesOrderToDocumentAttachment(SalesHeader, DocPrint.GetSalesOrderPrintToAttachmentOption((SalesHeader)));

        // [THEN] New document attachment created with "Document Flow Sales" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type"::Order);
        DocumentAttachment.TestField("Document Flow Sales", true);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Standard Sales - Pro Forma Inv", SalesHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
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
        Initialize;

        // [GIVEN] Sales order
        LibrarySales.CreateSalesOrder(SalesHeader);

        // [WHEN] "Print to attachment" function is called with "Work Order" strmenu choice
        LibraryVariableStorage.Enqueue("Sales Order Print Option"::"Work Order");
        SalesHeader.SetRecFilter();
        DocPrint.PrintSalesOrderToDocumentAttachment(SalesHeader, DocPrint.GetSalesOrderPrintToAttachmentOption((SalesHeader)));

        // [THEN] New document attachment created with "Document Flow Sales" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type"::Order);
        DocumentAttachment.TestField("Document Flow Sales", true);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Work Order", SalesHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
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
        Initialize;

        // [GIVEN] Sales invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [WHEN] "Print to attachment" function is called with "Standard Sales - Draft Invoice" strmenu choice
        LibraryVariableStorage.Enqueue(1);
        SalesHeader.SetRecFilter();
        DocPrint.PrintSalesInvoiceToDocumentAttachment(SalesHeader, DocPrint.GetSalesInvoicePrintToAttachmentOption(SalesHeader));

        // [THEN] New document attachment created with "Document Flow Sales" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type"::Invoice);
        DocumentAttachment.TestField("Document Flow Sales", true);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Standard Sales - Draft Invoice", SalesHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
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
        Initialize;

        // [GIVEN] Sales invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [WHEN] "Print to attachment" function is called with "Standard Sales - Pro Forma Inv" strmenu choice
        LibraryVariableStorage.Enqueue(2);
        SalesHeader.SetRecFilter();
        DocPrint.PrintSalesInvoiceToDocumentAttachment(SalesHeader, DocPrint.GetSalesInvoicePrintToAttachmentOption(SalesHeader));

        // [THEN] New document attachment created with "Document Flow Sales" = yes
        FindDocumentAttachment(DocumentAttachment, Database::"Sales Header", SalesHeader."No.", SalesHeader."Document Type"::Invoice);
        DocumentAttachment.TestField("Document Flow Sales", true);
        DocumentAttachment.TestField("File Name", GetExpectedAttachmentFileName(Report::"Standard Sales - Pro Forma Inv", SalesHeader."No."));

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
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
        Initialize;

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
        Initialize;

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
        Initialize;

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

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore;
        if isInitialized then
            exit;

        // Setup demonstration data.
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdateSalesReceivablesSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.SetupReportSelections();
        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
    end;

    local procedure CreateTempBLOBWithText(var TempBlob: Codeunit "Temp Blob"; Content: Text)
    var
        OStream: OutStream;
        BigStr: BigText;
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
        Bitmap.Dispose;
    end;

    local procedure CreateCustomReportSelection(SourceType: Integer; SourceNo: Code[20]; ReportUsage: Integer; ReportID: Integer)
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        with CustomReportSelection do begin
            "Source Type" := SourceType;
            "Source No." := SourceNo;
            Usage := ReportUsage;
            "Report ID" := ReportID;
            Insert();
        end;

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
        Assert.AreEqual(RecCount, DocumentAttachment.Count, 'Unexpected document count.');
        Assert.IsTrue(DocumentAttachment.FindFirst, 'Expected record missing');
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
        Assert.AreEqual(RecCount, DocumentAttachment.Count, 'Unexpected document count.');
        Assert.IsTrue(DocumentAttachment.FindFirst, 'Expected record missing');
        Assert.AreEqual(FileName, DocumentAttachment."File Name", 'Unexpected file attached.');
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Customer: Record Customer; Item: Record Item; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    local procedure CreatePurchDoc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Vendor: Record Vendor; Item: Record Item; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order")
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
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 1);
        SalesLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceHeaderDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        DocumentAttachment."Table ID" := DATABASE::"Sales Invoice Header";
        DocumentAttachment."No." := SalesInvoiceHeader."No.";
        DocumentAttachment."File Name" :=
          CopyStr(Format(CreateGuid), 1, MaxStrLen(DocumentAttachment."File Name"));
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
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, 1);
        PurchaseLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceHeaderDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        DocumentAttachment."Table ID" := DATABASE::"Purch. Inv. Header";
        DocumentAttachment."No." := PurchInvHeader."No.";
        DocumentAttachment."File Name" :=
          CopyStr(Format(CreateGuid), 1, MaxStrLen(DocumentAttachment."File Name"));
        DocumentAttachment.Insert();
    end;

    local procedure FindCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; CustomerNo: Code[20])
    begin
        with CustLedgerEntry do begin
            SetRange("Document No.", DocumentNo);
            SetRange("Customer No.", CustomerNo);
            FindFirst;
        end;
    end;

    local procedure FindVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20]; CustomerNo: Code[20])
    begin
        with VendorLedgerEntry do begin
            SetRange("Document No.", DocumentNo);
            SetRange("Vendor No.", CustomerNo);
            FindFirst;
        end;
    end;

    local procedure FindDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; TableId: Integer; DocumentNo: Code[20]; DocumentType: Option)
    begin
        with DocumentAttachment do begin
            SetRange("Table ID", TableId);
            SetRange("No.", DocumentNo);
            SetRange("Document Type", DocumentType);
            FindFirst;
        end;
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

    local procedure MockDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; TableId: Integer; DocumentNo: Code[20]; DocumentType: Option; FileName: Text; FileExtension: Text)
    begin
        Clear(DocumentAttachment);
        with DocumentAttachment do begin
            "Table ID" := TableId;
            "No." := DocumentNo;
            "Document Type" := DocumentType;
            "File Name" := CopyStr(FileName, 1, MaxStrLen("File Name"));
            "File Extension" := CopyStr(FileExtension, 1, MaxStrLen("File Extension"));
            Insert();
        end;
    end;

    procedure SetupReportSelection(ReportUsage: Option; ReportId: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportUsage);
        ReportSelections.DeleteAll;
        ReportSelections.Init();
        ReportSelections.Usage := ReportUsage;
        ReportSelections.Sequence := '1';
        ReportSelections."Report ID" := ReportId;
        ReportSelections.Insert(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ListSalesFlow(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Sales".Visible, 'Expected field not visible');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Sales".Editable, 'Field should be disabled');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Purchase".Visible, 'Unexpected field visible');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ListItemFlow(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Sales".Visible, 'Expected field not visible');
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Sales".Editable, 'Expected field not editable');
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Purchase".Visible, 'Expected field not visible');
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Purchase".Editable, 'Expected field not editable');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ListPurchFlow(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Sales".Visible, 'Unexpected field visible');
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Purchase".Visible, 'Expected field not visible');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Purchase".Editable, 'Expected field should be disabled.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ListResourceFlow(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Sales".Visible, 'Unexpected field visible');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Purchase".Visible, 'Unexpected field visible');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DocumentAttachmentDetailsMPH(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        LibraryVariableStorage.Enqueue(Format(DocumentAttachmentDetails.Name));
        DocumentAttachmentDetails.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntryCheckShowDocAttachMPH(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        LibraryVariableStorage.Enqueue(ApplyCustomerEntries.ShowDocumentAttachment.Enabled);
        ApplyCustomerEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntryChooseShowDocAttachMPH(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.ShowDocumentAttachment.Invoke;
        ApplyCustomerEntries.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AppliedCustomerEntriesCheckShowDocAttachPH(var AppliedCustomerEntries: TestPage "Applied Customer Entries")
    begin
        LibraryVariableStorage.Enqueue(AppliedCustomerEntries.ShowDocumentAttachment.Enabled);
        AppliedCustomerEntries.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AppliedCustomerEntriesChooseShowDocAttachPH(var AppliedCustomerEntries: TestPage "Applied Customer Entries")
    begin
        AppliedCustomerEntries.ShowDocumentAttachment.Invoke;
        AppliedCustomerEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntryCheckShowDocAttachMPH(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        LibraryVariableStorage.Enqueue(ApplyVendorEntries.ShowDocumentAttachment.Enabled);
        ApplyVendorEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntryChooseShowDocAttachMPH(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ShowDocumentAttachment.Invoke;
        ApplyVendorEntries.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AppliedVendorEntriesCheckShowDocAttachPH(var AppliedVendorEntries: TestPage "Applied Vendor Entries")
    begin
        LibraryVariableStorage.Enqueue(AppliedVendorEntries.ShowDocumentAttachment.Enabled);
        AppliedVendorEntries.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AppliedVendorEntriesChooseShowDocAttachPH(var AppliedVendorEntries: TestPage "Applied Vendor Entries")
    begin
        AppliedVendorEntries.ShowDocumentAttachment.Invoke;
        AppliedVendorEntries.OK.Invoke;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure PrintedToAttachmentNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SalesOrderMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;
}

