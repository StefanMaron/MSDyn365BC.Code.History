codeunit 147522 "SII Document Processing"
{
    // // [FEATURE] [SII]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        TagMustNotExistErr: Label '%1 must not exist';
        FieldMustNotBeErr: Label '%1 must not be %2', Locked = true;
        SiiRLUrlTok: Label 'https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/ssii/fact/ws/SuministroLR.xsd';
        SiiUrlTok: Label 'https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/ssii/fact/ws/SuministroInformacion.xsd';
        SoapenvUrlTok: Label 'http://schemas.xmlsoap.org/soap/envelope/';
        XPathPrestacionServiciosTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseTipoOperacion/sii:PrestacionServicios';
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        XPathSalesFacturaExpedidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/';
        XPathPurchFacturaRecibidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/';
        MarkAsNotAcceptedErr: Label 'Marked as not accepted';
        MarkAsAcceptedErr: Label 'Marked as accepted';
        CertificateUsedInSIISetupQst: Label 'A certificate is used in the SII Setup. Do you really want to delete the certificate?';
        FieldMustHaveValueInSIISetupErr: Label '%1 must have a value in SII VAT Setup', Comment = '%1 = field caption';

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithTypeF5()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Purchase]
        // [SCENARIO 220620] Cassie can post purchase invoice with "Invoice Type" = "F5 Imports (DUA)" without sending to web service
        // [SCENARIO 233508] Purchase Invoice with "Invoice Type" = "F5 Imports (DUA)" is supported
        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Purchase invoice with "Invoice Type" = "F5 Imports (DUA)"
        CreatePurchInvoiceWithType(PurchaseHeader, PurchaseHeader."Invoice Type"::"F5 Imports (DUA)");

        // [GIVEN] Post invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments;

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::Invoice, DocumentNo, SIIDocUploadState."Document Source"::"Vendor Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceFromJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Journal] [Sales] [Invoice]
        // [SCENARIO] Posting customer's invoice generates SII Doc. Upload State entry when SII Setup is enabled
        // [SCENARIO 375398] SII Version is 1.1bis in SII Doc. Upload State generated from sales invoice

        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Journal line with type "Invoice" for customer
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo, LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Post journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] SII Doc. Upload State in state "Pending" is created
        with SIIDocUploadState do begin
            LibrarySII.FindSIIDocUploadState(
              SIIDocUploadState, "Document Source"::"Customer Ledger", "Document Type"::Invoice, GenJournalLine."Document No.");
            TestField(Status, Status::Pending);
        end;

        // [THEN] Version of SII Doc. Upload State is 1.1bis
        SIIDocUploadState.TestField("Version No.", SIIDocUploadState."Version No."::"2.1");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceFromJournalVersion11()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
        OldWorkDate: Date;
    begin
        // [FEATURE] [Journal] [Sales] [Invoice]
        // [SCENARIO] Posting customer's invoice generates SII Doc. Upload State entry when SII Setup is enabled
        // [SCENARIO 375398] SII Version is 1.1 in SII Doc. Upload State generated from sales invoice when work date is before year 2021

        Initialize();

        // [GIVEN] Work date is 31.12.2020
        OldWorkDate := WorkDate();
        WorkDate := 20201231D;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Journal line with type "Invoice" for customer
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo, LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Post journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] SII Doc. Upload State in state "Pending" is created
        with SIIDocUploadState do begin
            LibrarySII.FindSIIDocUploadState(
              SIIDocUploadState, "Document Source"::"Customer Ledger", "Document Type"::Invoice, GenJournalLine."Document No.");
            TestField(Status, Status::Pending);
        end;

        // [THEN] Version of SII Doc. Upload State is 1.1
        SIIDocUploadState.TestField("Version No.", SIIDocUploadState."Version No."::"1.1");

        // Tear down
        WorkDate := OldWorkDate;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceFromJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Journal] [Purchae] [Invoice]
        // [SCENARIO] Posting vendor's invoice generates SII Doc. Upload State entry when SII Setup is enabled
        // [SCENARIO 375398] SII Version is 1.1bis in SII Doc. Upload State generated from purchase invoice
        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Journal line with type "Invoice" for vendor
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo, -LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Post journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] SII Doc. Upload State in state "Pending" is created
        with SIIDocUploadState do begin
            LibrarySII.FindSIIDocUploadState(
              SIIDocUploadState, "Document Source"::"Vendor Ledger", "Document Type"::Invoice, GenJournalLine."Document No.");
            TestField(Status, Status::Pending);
        end;

        // [THEN] Version of SII Doc. Upload State is 1.1bis
        SIIDocUploadState.TestField("Version No.", SIIDocUploadState."Version No."::"2.1");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoFromJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Journal] [Sales] [Credit Memo]
        // [SCENARIO] Posting customer's credit memo generates SII Doc. Upload State entry when SII Setup is enabled
        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Journal line with type "Credit Memo" for customer
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo, -LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Post journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        with SIIDocUploadState do begin
            LibrarySII.FindSIIDocUploadState(
              SIIDocUploadState, "Document Source"::"Customer Ledger", "Document Type"::"Credit Memo", GenJournalLine."Document No.");
            TestField(Status, Status::Pending);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoFromJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Journal] [Purchase] [Credit Memo]
        // [SCENARIO] Posting vendor's credit memo generates SII Doc. Upload State entry when SII Setup is enabled
        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Journal line with type "Credit Memo" for vendor
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo, LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Post journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        with SIIDocUploadState do begin
            LibrarySII.FindSIIDocUploadState(
              SIIDocUploadState, "Document Source"::"Vendor Ledger", "Document Type"::"Credit Memo", GenJournalLine."Document No.");
            TestField(Status, Status::Pending);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoFromJournalXml()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Journal] [Sales] [Credit Memo]
        // [SCENARIO 221933] Stan can generte SII XML file for Posted Sales Credit Memo created from Journal

        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Posted Credit Memo from Journal
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo, -LibraryRandom.RandIntInRange(100, 200));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");

        // [WHEN] Generated XML file for Posted Credit Memo
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] XML File contains "Document No." and type of correction "I"
        ValidateElementByName(XMLDoc, 'sii:TipoRectificativa', 'I');
        ValidateElementByName(XMLDoc, 'sii:NumSerieFacturaEmisor', CustLedgerEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoFromJournalXml()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Journal] [Purchase] [Credit Memo]
        // [SCENARIO 221933] Stan can generate SII XML file for Posted Purch Credit Memo created from Journal

        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Posted Credit Memo from Journal
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo, LibraryRandom.RandIntInRange(100, 200));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");

        // [WHEN] Generated XML file for Posted Credit Memo
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] XML File contains "Document No." and type of correction "I"
        ValidateElementByName(XMLDoc, 'sii:TipoRectificativa', 'I');
        ValidateElementByName(XMLDoc, 'sii:NumSerieFacturaEmisor', VendorLedgerEntry."External Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyRegularSIIHistoryEntryCreatesWhenPostIntracommunitySalesDoc()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
    begin
        // [FEATURE] [Intracommunity] [UT] [Sales]
        // [SCENARIO] Only SII History with "Upload Type" equals "Intracommunity" creates when create request for document with Intracommunity customer

        Initialize;

        // [GIVEN] Customer Ledger Entry with Intracommunity Customer
        MockCustLedgEntryWithIntracommunityCust(CustLedgerEntry);

        // [WHEN] Create new SII request for Customer Ledger Entry
        SIIDocUploadState.CreateNewRequest(
          CustLedgerEntry."Entry No.", SIIDocUploadState."Document Source"::"Customer Ledger".AsInteger(), CustLedgerEntry."Document Type".AsInteger(),
          CustLedgerEntry."Document No.", CustLedgerEntry."External Document No.", CustLedgerEntry."Posting Date");

        FilterSIIHistory(
          SIIHistory, "SII Doc. Upload State Document Type"::Invoice,
          CustLedgerEntry."Document No.", SIIDocUploadState."Document Source"::"Customer Ledger");

        // [THEN] SII History Entry with type "Regular" is created
        SIIHistory.SetRange("Upload Type", SIIHistory."Upload Type"::Regular);
        Assert.RecordIsNotEmpty(SIIHistory);

        // [THEN] SII History Entry with type "Intracommunity" is not created
        SIIHistory.SetRange("Upload Type", SIIHistory."Upload Type"::Intracommunity);
        Assert.RecordIsEmpty(SIIHistory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyRegularSIIHistoryEntryCreatesWhenPostIntracommunityPurchDoc()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
    begin
        // [FEATURE] [Intracommunity] [UT] [Purchase]
        // [SCENARIO] Only SII History with "Upload Type" equals "Intracommunity" creates when create request for document with Intracommunity vendor

        Initialize;

        // [GIVEN] Vendor Ledger Entry with Intracommunity Vendor
        MockVendLedgEntryWithIntracommunityVend(VendorLedgerEntry);

        // [WHEN] Create new SII request for Vendor Ledger Entry
        SIIDocUploadState.CreateNewRequest(
          VendorLedgerEntry."Entry No.", SIIDocUploadState."Document Source"::"Vendor Ledger".AsInteger(), VendorLedgerEntry."Document Type".AsInteger(),
          VendorLedgerEntry."Document No.", VendorLedgerEntry."External Document No.", VendorLedgerEntry."Posting Date");

        FilterSIIHistory(
          SIIHistory, "SII Doc. Upload State Document Type"::Invoice, VendorLedgerEntry."Document No.",
          SIIDocUploadState."Document Source"::"Vendor Ledger");

        // [THEN] SII History Entry with type "Regular" is created
        SIIHistory.SetRange("Upload Type", SIIHistory."Upload Type"::Regular);
        Assert.RecordIsNotEmpty(SIIHistory);

        // [THEN] SII History Entry with type "Intracommunity" is not created
        SIIHistory.SetRange("Upload Type", SIIHistory."Upload Type"::Intracommunity);
        Assert.RecordIsEmpty(SIIHistory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithTypeF3()
    var
        SalesHeader: Record "Sales Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 220620] It must be possible to post Sales Invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices"
        // [SCENARIO 233508] Sales Invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices" is supported

        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Sales invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices"
        CreateSalesInvoiceWithType(SalesHeader, SalesHeader."Invoice Type"::"F3 Invoice issued to replace simplified invoices");

        // [GIVEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments;

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::Invoice, DocumentNo, SIIDocUploadState."Document Source"::"Customer Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithTypeF4()
    var
        SalesHeader: Record "Sales Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 220620] It must be possible to post Sales Invoice with "Invoice Type" = "F4 Invoice summary entry"
        // [SCENARIO 233508] Sales Invoice with "Invoice Type" = "F4 Invoice summary entry" is supported

        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Sales invoice with "Invoice Type" = "F4 Invoice summary entry"
        CreateSalesInvoiceWithType(SalesHeader, SalesHeader."Invoice Type"::"F4 Invoice summary entry");

        // [GIVEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments;

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::Invoice, DocumentNo, SIIDocUploadState."Document Source"::"Customer Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithTypeF3()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Purchase]
        // [SCENARIO 220620] Cassie can post purchase invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices" without sending to web service
        // [SCENARIO 233508] Purchase Invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices" is supported
        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Purchase invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices"
        CreatePurchInvoiceWithType(PurchaseHeader, PurchaseHeader."Invoice Type"::"F3 Invoice issued to replace simplified invoices");

        // [GIVEN] Post invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments;

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::Invoice, DocumentNo, SIIDocUploadState."Document Source"::"Vendor Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithTypeF4()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Purchase]
        // [SCENARIO 220620] Cassie can post purchase invoice with "Invoice Type" = "F4 Invoice summary entry" without sending to web service
        // [SCENARIO 233508] Purchase Invoice with "Invoice Type" = "F4 Invoice summary entry" is supported
        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Purchase invoice with "Invoice Type" = "F4 Invoice summary entry"
        CreatePurchInvoiceWithType(
          PurchaseHeader, PurchaseHeader."Invoice Type"::"F4 Invoice summary entry");

        // [GIVEN] Post invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments;

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::Invoice, DocumentNo, SIIDocUploadState."Document Source"::"Vendor Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithTypeF6()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Purchase]
        // [SCENARIO 220620] Cassie can post purchase invoice with "Invoice Type" = "F6 Accounting support material" without sending to web service
        // [SCENARIO 233508] Purchase Invoice with "Invoice Type" = "F6 Accounting support material" is supported
        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Purchase invoice with "Invoice Type" = "F6 Accounting support material"
        CreatePurchInvoiceWithType(
          PurchaseHeader, PurchaseHeader."Invoice Type"::"F6 Accounting support material");

        // [GIVEN] Post invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments;

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::Invoice, DocumentNo, SIIDocUploadState."Document Source"::"Vendor Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCrMemoWithTypeR2()
    var
        SalesHeader: Record "Sales Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 220620] It must be possible to post Sales Credit Memo with "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)"
        // [SCENARIO 233508] Sales Credit Memo with "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)" is supported

        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Sales Credit Memo with "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)"
        CreateSalesCrMemoWithType(
          SalesHeader, SalesHeader."Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");

        // [GIVEN] Post Credit Memo
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments;

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::"Credit Memo", DocumentNo, SIIDocUploadState."Document Source"::"Customer Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCrMemoWithTypeR3()
    var
        SalesHeader: Record "Sales Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 220620] It must be possible to post Sales Credit Memo with "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)"
        // [SCENARIO 233508] Sales Credit Memo with "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)" is supported

        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Sales Credit Memo with "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)"
        CreateSalesCrMemoWithType(
          SalesHeader, SalesHeader."Cr. Memo Type"::"R3 Corrected Invoice (Art. 80.4)");

        // [GIVEN] Post Credit Memo
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments;

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::"Credit Memo", DocumentNo, SIIDocUploadState."Document Source"::"Customer Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCrMemoWithTypeR4()
    var
        SalesHeader: Record "Sales Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 220620] It must be possible to post Sales Credit Memo with "Cr. Memo Type" = "R4 Corrected Invoice (Other)"
        // [SCENARIO 233508] Sales Credit Memo with "Cr. Memo Type" = "R4 Corrected Invoice (Other)" is supported

        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Sales Credit Memo with "Cr. Memo Type" = "R4 Corrected Invoice (Other)"
        CreateSalesCrMemoWithType(
          SalesHeader, SalesHeader."Cr. Memo Type"::"R4 Corrected Invoice (Other)");

        // [GIVEN] Post Credit Memo
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments;

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::"Credit Memo", DocumentNo, SIIDocUploadState."Document Source"::"Customer Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCrMemoWithTypeR2()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 220620] Cassie can post purchase Credit Memo with "Invoice Type" = "R2 Corrected Invoice (Art. 80.3)" without sending to web service
        // [SCENARIO 233508] Purchase Credit Memo with "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)" is supported

        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Purchase Credit Memo with "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)"
        CreatePurchCrMemoWithType(PurchaseHeader, PurchaseHeader."Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");

        // [GIVEN] Post Credit Memo
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments;

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::"Credit Memo", DocumentNo, SIIDocUploadState."Document Source"::"Vendor Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCrMemoWithTypeR3()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 220620] Cassie can post purchase Credit Memo with "Invoice Type" = "R3 Corrected Invoice (Art. 80.4)" without sending to web service
        // [SCENARIO 233508] Purchase Credit Memo with "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)" is supported
        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Purchase Credit Memo with "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)"
        CreatePurchCrMemoWithType(PurchaseHeader, PurchaseHeader."Cr. Memo Type"::"R3 Corrected Invoice (Art. 80.4)");

        // [GIVEN] Post Credit Memo
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments;

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::"Credit Memo", DocumentNo, SIIDocUploadState."Document Source"::"Vendor Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCrMemoWithTypeR4()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 220620] Cassie can post purchase Credit Memo with "Invoice Type" = "R4 Corrected Invoice (Other)" without sending to web service
        // [SCENARIO 233508] Purchase Credit Memo with "Cr. Memo Type" = "R4 Corrected Invoice (Other)" is supported

        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Purchase Credit Memo with "Cr. Memo Type" = "R4 Corrected Invoice (Other)"
        CreatePurchCrMemoWithType(PurchaseHeader, PurchaseHeader."Cr. Memo Type"::"R4 Corrected Invoice (Other)");

        // [GIVEN] Post Credit Memo
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments;

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::"Credit Memo", DocumentNo, SIIDocUploadState."Document Source"::"Vendor Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIStatusOfPostedPurchInvoiceoRefersToSIIDocUploadState()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 224053] "SII Status" of Posted Purchase Invoice refers to status of related "SII Doc. Upload State" record

        Initialize;

        PurchInvHeader.Init();
        PurchInvHeader."No." := LibraryUtility.GenerateGUID;
        PurchInvHeader.Insert();

        MockSIIDocUploadStateWithIncorrectStatus(
          SIIDocUploadState."Document Source"::"Vendor Ledger",
          SIIDocUploadState."Document Type"::Invoice, PurchInvHeader."No.");

        PurchInvHeader.CalcFields("SII Status", "Sent to SII");
        PurchInvHeader.TestField("SII Status", PurchInvHeader."SII Status"::Incorrect);

        // TFS ID 351319: A document sent to sii has value "Sent to SII"
        PurchInvHeader.TestField("Sent to SII");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIStatusOfPostedSalesInvoiceRefersToSIIDocUploadState()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 224053] "SII Status" of Posted Sales Invoice refers to status of related "SII Doc. Upload State" record

        Initialize;

        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID;
        SalesInvoiceHeader.Insert();

        MockSIIDocUploadStateWithIncorrectStatus(
          SIIDocUploadState."Document Source"::"Customer Ledger",
          SIIDocUploadState."Document Type"::Invoice, SalesInvoiceHeader."No.");

        SalesInvoiceHeader.CalcFields("SII Status", "Sent to SII");
        SalesInvoiceHeader.TestField("SII Status", SalesInvoiceHeader."SII Status"::Incorrect);

        // TFS ID 351319: A document sent to sii has value "Sent to SII"
        SalesInvoiceHeader.TestField("Sent to SII");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIStatusOfPostedServInvoiceRefersToSIIDocUploadState()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Service] [Invoice] [UT]
        // [SCENARIO 224053] "SII Status" of Posted Service Invoice refers to status of related "SII Doc. Upload State" record

        Initialize;

        ServiceInvoiceHeader.Init();
        ServiceInvoiceHeader."No." := LibraryUtility.GenerateGUID;
        ServiceInvoiceHeader.Insert();

        MockSIIDocUploadStateWithIncorrectStatus(
          SIIDocUploadState."Document Source"::"Customer Ledger",
          SIIDocUploadState."Document Type"::Invoice, ServiceInvoiceHeader."No.");

        ServiceInvoiceHeader.CalcFields("SII Status", "Sent to SII");
        ServiceInvoiceHeader.TestField("SII Status", ServiceInvoiceHeader."SII Status"::Incorrect);

        // TFS ID 351319: A document sent to sii has value "Sent to SII"
        ServiceInvoiceHeader.TestField("Sent to SII");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIStatusOfPostedPurchCreditMemoRefersToSIIDocUploadState()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Purchase] [Credit Memo] [UT]
        // [SCENARIO 224053] "SII Status" of Posted Purchase Credit Memo refers to status of related "SII Doc. Upload State" record

        Initialize;

        PurchCrMemoHdr.Init();
        PurchCrMemoHdr."No." := LibraryUtility.GenerateGUID;
        PurchCrMemoHdr.Insert();

        MockSIIDocUploadStateWithIncorrectStatus(
          SIIDocUploadState."Document Source"::"Vendor Ledger",
          SIIDocUploadState."Document Type"::"Credit Memo", PurchCrMemoHdr."No.");

        PurchCrMemoHdr.CalcFields("SII Status", "Sent to SII");
        PurchCrMemoHdr.TestField("SII Status", PurchCrMemoHdr."SII Status"::Incorrect);

        // TFS ID 351319: A document sent to sii has value "Sent to SII"
        PurchCrMemoHdr.TestField("Sent to SII");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIStatusOfPostedSalesCreditMemoRefersToSIIDocUploadState()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Sales] [Credit Memo] [UT]
        // [SCENARIO 224053] "SII Status" of Posted Sales Credit Memo refers to status of related "SII Doc. Upload State" record

        Initialize;

        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."No." := LibraryUtility.GenerateGUID;
        SalesCrMemoHeader.Insert();

        MockSIIDocUploadStateWithIncorrectStatus(
          SIIDocUploadState."Document Source"::"Customer Ledger",
          SIIDocUploadState."Document Type"::"Credit Memo", SalesCrMemoHeader."No.");

        SalesCrMemoHeader.CalcFields("SII Status", "Sent to SII");
        SalesCrMemoHeader.TestField("SII Status", SalesCrMemoHeader."SII Status"::Incorrect);

        // TFS ID 351319: A document sent to sii has value "Sent to SII"
        SalesCrMemoHeader.TestField("Sent to SII");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIStatusOfPostedServCreditMemoRefersToSIIDocUploadState()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Service] [Credit Memo] [UT]
        // [SCENARIO 224053] "SII Status" of Posted Service Credit Memo refers to status of related "SII Doc. Upload State" record

        Initialize;

        ServiceCrMemoHeader.Init();
        ServiceCrMemoHeader."No." := LibraryUtility.GenerateGUID;
        ServiceCrMemoHeader.Insert();

        MockSIIDocUploadStateWithIncorrectStatus(
          SIIDocUploadState."Document Source"::"Customer Ledger",
          SIIDocUploadState."Document Type"::"Credit Memo", ServiceCrMemoHeader."No.");

        ServiceCrMemoHeader.CalcFields("SII Status", "Sent to SII");
        ServiceCrMemoHeader.TestField("SII Status", ServiceCrMemoHeader."SII Status"::Incorrect);

        // TFS ID 351319: A document sent to sii has value "Sent to SII"
        ServiceCrMemoHeader.TestField("Sent to SII");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLRequestEUServiceReverseChargeVATSalesInvoice()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [EU Service] [Reverse Charge VAT]
        // [SCENARIO 225529] SII XML request does not contain tag 'sii:Entrega' for EU Service intracommunity sales invoice with Reverse Charge VAT
        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] EU Service reverse charge VAT Posting Setup "V"
        // [GIVEN] Intracommunity customer "C"
        CreateReverseChargeVATIntracommunityCustoemerAndGLAccount(Customer, GLAccount, true);

        // [GIVEN] Sales invoice for customer "C" with VAT groups from "V"
        CreateSalesDocumentWithGLAccount(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", GLAccount."No.");

        // [WHEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);

        // [THEN] System generates SII XML request
        SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] XML request does not contain "sii:Entrega" tag
        VerifyTagAbsence(XMLDoc, 'sii:Entrega');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLRequestEUServiceReverseChargeVATCreditMemo()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo] [EU Service] [Reverse Charge VAT]
        // [SCENARIO 225529] SII XML request does not contain tag 'sii:Entrega' for EU Service intracommunity sales invoice with Reverse Charge VAT
        Initialize;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] EU Service reverse charge VAT Posting Setup "V"
        // [GIVEN] Intracommunity customer "C"
        CreateReverseChargeVATIntracommunityCustoemerAndGLAccount(Customer, GLAccount, true);

        // [GIVEN] Sales invoice for customer "C" with VAT groups from "V"
        CreateSalesDocumentWithGLAccount(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.", GLAccount."No.");

        // [WHEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] System generated SII XML request
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", DocumentNo);
        SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] XML request does not contain "sii:Entrega" tag
        VerifyTagAbsence(XMLDoc, 'sii:Entrega');

        // [THEN] XML node by XPath '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseTipoOperacion/sii:PrestacionServicios' generated
        LibraryXPathXMLReader.InitializeWithText(XMLDoc.OuterXml, '');
        SetupXMLNamespaces;
        LibraryXPathXMLReader.VerifyNodeCountByXPath(XPathPrestacionServiciosTok, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NotifyOnSuccessIsDisabledInSIIJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
        SIIJobManagement: Codeunit "SII Job Management";
        JobType: Option HandlePending,HandleCommError,InitialUpload;
    begin
        // [FEATURE] [UT] [Job Queue]
        // [SCENARIO 251642] Job Queue Entry created via SII Job Management codeunit has disabled "Notify on Success"

        Initialize;

        JobQueueEntry.DeleteAll();
        SIIJobManagement.RenewJobQueueEntry(JobType::HandlePending);
        JobQueueEntry.FindFirst;
        JobQueueEntry.TestField("Notify On Success", false);
        JobQueueEntry.TestField("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.TestField("Object ID to Run", CODEUNIT::"SII Job Upload Pending Docs.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIISetupShowAdvancedActions()
    var
        SIIHistory: TestPage "SII History";
        SIISetup: TestPage "SII Setup";
    begin
        // [FEATURE] [Advanced Mark] [UI] [UT]
        // [SCENARIO 253910] There is a checkbox "Show Advanced Actions" on SII Setup page which enables additional actions on SII History page
        LibrarySII.InitSetup(false, false);
        LibrarySII.ShowAdvancedActions(false);

        // There is a "Show Advanced Actions" checkbox on SII Setup page
        SIISetup.OpenEdit;
        Assert.IsTrue(SIISetup."Show Advanced Actions".Visible, '');
        Assert.IsTrue(SIISetup."Show Advanced Actions".Enabled, '');
        SIISetup."Show Advanced Actions".AssertEquals(false);
        SIISetup.Close;

        // SII History advanced actions are hidden in case of SIISetup."Show Advanced Actions" = FALSE
        SIIHistory.OpenEdit;
        Assert.IsFalse(SIIHistory."Mark As Accepted".Visible, '');
        Assert.IsFalse(SIIHistory."Mark As Accepted".Enabled, '');
        SIIHistory.Close;

        // SII History advanced actions are visible but not enabled in case of SIISetup."Enabled" = FALSE, "Show Advanced Actions" = TRUE
        LibrarySII.ShowAdvancedActions(true);
        SIIHistory.OpenEdit;
        Assert.IsTrue(SIIHistory."Mark As Accepted".Visible, '');
        Assert.IsFalse(SIIHistory."Mark As Accepted".Enabled, '');
        SIIHistory.Close;

        // SII History advanced actions are visible and enabled in case of SIISetup."Enabled" = TRUE, "Show Advanced Actions" = TRUE
        LibrarySII.InitSetup(true, false);
        SIIHistory.OpenEdit;
        Assert.IsTrue(SIIHistory."Mark As Accepted".Visible, '');
        Assert.IsTrue(SIIHistory."Mark As Accepted".Enabled, '');
        SIIHistory.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIHistoryMarkAsAccepted_Negative()
    var
        SIIHistory: Record "SII History";
        StatusCollection: array[2] of Option;
        i: Integer;
    begin
        // [FEATURE] [Advanced Mark] [UT]
        // [SCENARIO 253910] There is a fielderror when try "Mark As Accepted" history entry with status "Accepted"\"Accepted With Errors"
        LibrarySII.InitSetup(true, false);
        LibrarySII.ShowAdvancedActions(true);
        Commit();

        StatusCollection[1] := SIIHistory.Status::Accepted;
        StatusCollection[2] := SIIHistory.Status::"Accepted With Errors";

        for i := 1 to ArrayLen(StatusCollection) do begin
            LibrarySII.MockHistoryEntry(SIIHistory, StatusCollection[i]);
            asserterror SIIHistory.MarkAsAccepted;
            Assert.ExpectedErrorCode('TableError');
            Assert.ExpectedError(StrSubstNo(FieldMustNotBeErr, SIIHistory.FieldCaption(Status), SIIHistory.Status));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIHistoryMarkAsNotAccepted_Negative()
    var
        SIIHistory: Record "SII History";
        StatusCollection: array[5] of Option;
        i: Integer;
    begin
        // [FEATURE] [Advanced Mark] [UT]
        // [SCENARIO 253910] There is a fielderror when try "Mark As Not Accepted" history entry with status "Communication Error"\"Failed"\"Incorrect"\"Not Supported"\"Pending"
        LibrarySII.InitSetup(true, false);
        LibrarySII.ShowAdvancedActions(true);
        Commit();

        StatusCollection[1] := SIIHistory.Status::"Communication Error";
        StatusCollection[2] := SIIHistory.Status::Failed;
        StatusCollection[3] := SIIHistory.Status::Incorrect;
        StatusCollection[4] := SIIHistory.Status::"Not Supported";
        StatusCollection[5] := SIIHistory.Status::Pending;

        for i := 1 to ArrayLen(StatusCollection) do begin
            LibrarySII.MockHistoryEntry(SIIHistory, StatusCollection[i]);
            asserterror SIIHistory.MarkAsNotAccepted;
            Assert.ExpectedErrorCode('TableError');
            Assert.ExpectedError(StrSubstNo(FieldMustNotBeErr, SIIHistory.FieldCaption(Status), SIIHistory.Status));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIHistoryMarkAsAccepted()
    var
        SIIHistory: Record "SII History";
    begin
        // [FEATURE] [Advanced Mark]
        // [SCENARIO 253910] "Mark As Accepted" history "Failed" entry
        LibrarySII.InitSetup(true, false);
        LibrarySII.ShowAdvancedActions(true);

        // [GIVEN] History "Failed" entry
        LibrarySII.MockHistoryEntry(SIIHistory, SIIHistory.Status::Failed);

        // [WHEN] Mark As Accepted
        SIIHistory.MarkAsAccepted;

        // [THEN] An existing history entry has status "Accepted With Errors"
        // TFS 292525: SII Entry marked as accepted does not different from accepted by system
        VerifyHistoryAndDocUploadValuesAfterMark(
          SIIHistory."Document State Id", SIIHistory.Status::"Accepted With Errors", MarkAsAcceptedErr,
          SIIHistory."Upload Type"::Regular, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIHistoryMarkAsNotAccepted()
    var
        SIIHistory: Record "SII History";
    begin
        // [FEATURE] [Advanced Mark]
        // [SCENARIO 253910] "Mark As Not Accepted" history "Accepted" entry
        LibrarySII.InitSetup(true, false);
        LibrarySII.ShowAdvancedActions(true);

        // [GIVEN] History "Accepted" entry
        LibrarySII.MockHistoryEntry(SIIHistory, SIIHistory.Status::Accepted);

        // [WHEN] Mark As Not Accepted
        SIIHistory.MarkAsNotAccepted;

        // [THEN] An existing history entry has status "Accepted With Errors"
        // TFS 292525: SII Entry marked as accepted does not different from accepted by system
        VerifyHistoryAndDocUploadValuesAfterMark(
          SIIHistory."Document State Id", SIIHistory.Status::Failed, MarkAsNotAcceptedErr, SIIHistory."Upload Type"::Regular, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTypeAndSpecialSchemeCodeInJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 261095] Stan can specify "Invoice Type" and "Special Scheme" code in General Journal Line for Sales Invoice

        // [GIVEN] Enabled SII Setup
        LibrarySII.InitSetup(true, false);

        // [GIVEN] Posted journal line for Sales Invoice with "Invoice Type" = "F2 Simplified Invoice" and "Sales Special Scheme Code" = "04 Gold")
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo, LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate("Sales Invoice Type", GenJournalLine."Sales Invoice Type"::"F2 Simplified Invoice");
        GenJournalLine.Validate("Sales Special Scheme Code", GenJournalLine."Sales Special Scheme Code"::"04 Gold");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] System generated SII XML request
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'F2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '04');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoTypeAndSpecialSchemeCodeInJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        CustNo: Code[20];
        DocNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 261095] Stan can specify "Invoice Type" and "Special Scheme" code in General Journal Line for Sales Credit Memo
        // [SCENARIO 269110] SII Doc. Upload State has "Corrected Doc. No." and "Corr. Posting Date" of corrected sales 2invoice

        // [GIVEN] Enabled SII Setup
        LibrarySII.InitSetup(true, false);

        // [GIVEN] Posted Sales Invoice "X" and "Posting Date" = "Y"
        CustNo := LibrarySales.CreateCustomerNo;
        PostingDate := LibraryRandom.RandDate(10);
        DocNo := MockSalesInvoiceDocWithEntry(CustNo, PostingDate);

        // [GIVEN] Posted journal line for Replacement Sales Credit Memo with "Invoice Type" = "F2 Simplified Invoice", "Sales Special Scheme Code" = "04 Gold" and "Corrected Invoice No." = "X"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, CustNo, -LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate("Sales Cr. Memo Type", GenJournalLine."Sales Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");
        GenJournalLine.Validate("Sales Special Scheme Code", GenJournalLine."Sales Special Scheme Code"::"04 Gold");
        GenJournalLine.Validate("Correction Type", GenJournalLine."Correction Type"::Replacement);
        GenJournalLine.Validate("Corrected Invoice No.", DocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] System generated SII XML request
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'R2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '04');

        // [THEN] NumSerieFacturaEmisor under node FacturasRectificadas is "X1" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:FacturasRectificadas/sii:IDFacturaRectificada/sii:NumSerieFacturaEmisor', DocNo);

        // [THEN] SII Doc. Upload State for Credit Memo exists with "Corrected Doc. No." = "X" and "Corr. Posting Date" = "Y"
        LibrarySII.FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Customer Ledger", SIIDocUploadState."Document Type"::"Credit Memo",
          CustLedgerEntry."Document No.");
        SIIDocUploadState.TestField("Corrected Doc. No.", DocNo);
        SIIDocUploadState.TestField("Corr. Posting Date", PostingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceTypeAndSpecialSchemeCodeInJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 261095] Stan can specify "Invoice Type" and "Special Scheme" code in General Journal Line for Purchase Invoice

        // [GIVEN] Enabled SII Setup
        LibrarySII.InitSetup(true, false);

        // [GIVEN] Posted journal line for Purchase Invoice with "Invoice Type" = "F2 Simplified Invoice" and "Purch. Special Scheme Code" = "04 Gold")
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo, -LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate("Purch. Invoice Type", GenJournalLine."Purch. Invoice Type"::"F2 Simplified Invoice");
        GenJournalLine.Validate("Purch. Special Scheme Code", GenJournalLine."Purch. Special Scheme Code"::"04 Gold");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] System generated SII XML request
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'F2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '04');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoTypeAndSpecialSchemeCodeInJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        VendNo: Code[20];
        DocNo: Code[20];
        DocDate: Date;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 261095] Stan can specify "Invoice Type" and "Special Scheme" code in General Journal Line for Purchase Credit Memo
        // [SCENARIO 269110] SII Doc. Upload State has "Corrected Doc. No." and "Corr. Posting Date" of corrected purchase invoice

        // [GIVEN] Enabled SII Setup
        LibrarySII.InitSetup(true, false);

        // [GIVEN] Posted Purchase Invoice "X" and "Document Date" = "Y"
        VendNo := LibraryPurchase.CreateVendorNo;
        DocDate := LibraryRandom.RandDate(10);
        DocNo := MockPurchInvoiceDocWithEntry(VendNo, DocDate);

        // [GIVEN] Posted journal line for Purchase Credit Memo with "Invoice Type" = "F2 Simplified Invoice", "Purch. Special Scheme Code" = "04 Gold" and "Corrected Invoice No." = "X"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, VendNo, LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate("Purch. Cr. Memo Type", GenJournalLine."Purch. Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");
        GenJournalLine.Validate("Purch. Special Scheme Code", GenJournalLine."Purch. Special Scheme Code"::"04 Gold");
        GenJournalLine.Validate("Correction Type", GenJournalLine."Correction Type"::Replacement);
        GenJournalLine.Validate("Corrected Invoice No.", DocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] System generated SII XML request
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'R2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '04');

        // [THEN] NumSerieFacturaEmisor under node FacturasRectificadas is "X1" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:FacturasRectificadas/sii:IDFacturaRectificada/sii:NumSerieFacturaEmisor', DocNo);

        // [THEN] SII Doc. Upload State for Credit Memo exists with "Corrected Doc. No." = "X" and "Corr. Posting Date" = "Y"
        LibrarySII.FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Vendor Ledger", SIIDocUploadState."Document Type"::"Credit Memo",
          VendorLedgerEntry."Document No.");
        SIIDocUploadState.TestField("Corrected Doc. No.", DocNo);
        SIIDocUploadState.TestField("Corr. Posting Date", DocDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IDVersionTakesFromSIIDocUploadState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 263060] It is possible to set specific version for IDVersionSii node through function SetSIIVersionNo of codeunit SII XML Creator

        Initialize;

        // [GIVEN] Posted invoice
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo, LibraryRandom.RandIntInRange(100, 200));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");

        // [GIVEN] "Version No." is changed to "1.0" in SII Doc. Upload State related to posted invoice
        SIIXMLCreator.SetSIIVersionNo(SIIDocUploadState."Version No."::"1.0");

        // [WHEN] Generated XML file for Posted invoice
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] XML File contains IDVersionSii with value "1.0"
        ValidateElementByName(XMLDoc, 'sii:IDVersionSii', '1.0');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToProcessDocumentWithoutSchemeReference()
    var
        SIISetup: Record "SII Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 341899] Stan cannot submit the document to SII if the SuministroInformacion Schema or SuministroLR Schema is not specified

        Initialize;

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo, LibraryRandom.RandIntInRange(100, 200));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");

        SIISetup.Get;
        SIISetup."SuministroInformacion Schema" := '';
        SIISetup.Modify;

        asserterror SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(
          StrSubstNo(FieldMustHaveValueInSIISetupErr, SIISetup.FieldCaption("SuministroInformacion Schema")));

        SIISetup."SuministroInformacion Schema" := SIISetup."SuministroLR Schema";
        SIISetup."SuministroLR Schema" := '';
        SIISetup.Modify;

        asserterror SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(
          StrSubstNo(FieldMustHaveValueInSIISetupErr, SIISetup.FieldCaption("SuministroLR Schema")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure NotPossibleToDeleteCertificateUsedInSIISetupIfUserNotConfirm()
    var
        IsolatedCertificate: Record "Isolated Certificate";
        SIISetup: Record "SII Setup";
    begin
        // [SCENARIO 316847] An isolated certificate not removes if it is used in the SII Setup and user cancels the confirmation

        Initialize;

        // [GIVEN] Isolated certificate "A"
        IsolatedCertificate.Init;
        IsolatedCertificate.Insert(true);

        // [GIVEN] SII setup with "Certificate Code" = "A"
        SIISetup.Get;
        SIISetup."Certificate Code" := IsolatedCertificate.Code;
        SIISetup.Modify;
        Commit;

        LibraryVariableStorage.Enqueue(CertificateUsedInSIISetupQst);
        LibraryVariableStorage.Enqueue(false); // say no in confirmation window

        // [WHEN] Delete isolated certificate "A" and cancel confirmation
        asserterror IsolatedCertificate.Delete(true);

        // [THEN] Error thrown with no text
        Assert.ExpectedError('');

        // [THEN] Isolated certificate not removed
        IsolatedCertificate.Find;

        // [THEN] "Certificate Code" still has value "A" in the SII Setup
        SIISetup.Find;
        SIISetup.TestField("Certificate Code", IsolatedCertificate.Code);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CertificateCodeBlanksInSIISetupIfUserConfirmCertificateDeletion()
    var
        IsolatedCertificate: Record "Isolated Certificate";
        SIISetup: Record "SII Setup";
    begin
        // [SCENARIO 316847] An isolated certificate removes if it is used in the SII Setup and user confirms

        Initialize;

        // [GIVEN] Isolated certificate "A"
        IsolatedCertificate.Init;
        IsolatedCertificate.Insert(true);

        // [GIVEN] SII setup with "Certificate Code" = "A"
        SIISetup.Get;
        SIISetup."Certificate Code" := IsolatedCertificate.Code;
        SIISetup.Modify;
        Commit;

        LibraryVariableStorage.Enqueue(CertificateUsedInSIISetupQst);
        LibraryVariableStorage.Enqueue(true); // say yes in confirmation window

        // [WHEN] Delete isolated certificate "A" and confirm this
        IsolatedCertificate.Delete(true);

        // [THEN] Isolated certificate not removed
        Assert.IsFalse(IsolatedCertificate.Find, 'Isolated certificate was not removed');

        // [THEN] "Certificate Code" does not have in the SII Setup
        SIISetup.Find;
        SIISetup.TestField("Certificate Code", '');

        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;

        IsInitialized := true;

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue;
        LibrarySetupStorage.Save(DATABASE::"SII Setup");
    end;

    local procedure CreateSalesInvoiceWithType(var SalesHeader: Record "Sales Header"; SIIDocType: Option)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          '', '', LibraryRandom.RandDecInRange(100, 200, 2), '', WorkDate);
        SalesHeader.Validate("Invoice Type", SIIDocType);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesCrMemoWithType(var SalesHeader: Record "Sales Header"; SIIDocType: Option)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo",
          '', '', LibraryRandom.RandDecInRange(100, 200, 2), '', WorkDate);
        SalesHeader.Validate("Cr. Memo Type", SIIDocType);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesDocumentWithGLAccount(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; GLAccountNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDecInRange(100, 200, 2));

        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchInvoiceWithType(var PurchaseHeader: Record "Purchase Header"; SIIDocType: Option)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          '', '', LibraryRandom.RandDecInRange(100, 200, 2), '', WorkDate);
        PurchaseHeader.Validate("Invoice Type", SIIDocType);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchCrMemoWithType(var PurchaseHeader: Record "Purchase Header"; SIIDocType: Option)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo",
          '', '', LibraryRandom.RandDecInRange(100, 200, 2), '', WorkDate);
        PurchaseHeader.Validate("Cr. Memo Type", SIIDocType);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateIntraCommunityCustomer(var Customer: Record Customer)
    var
        CountryRegion: Record "Country/Region";
    begin
        CreateIntracommunityCountryRegion(CountryRegion);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);
    end;

    local procedure CreateIntraCommunityVendor(var Vendor: Record Vendor)
    var
        CountryRegion: Record "Country/Region";
    begin
        CreateIntracommunityCountryRegion(CountryRegion);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateReverseChargeVATIntracommunityCustoemerAndGLAccount(var Customer: Record Customer; var GLAccount: Record "G/L Account"; EUService: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(5, 10));
        VATPostingSetup.Validate("EU Service", EUService);
        VATPostingSetup.Modify(true);

        CreateIntraCommunityCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure CreateIntracommunityCountryRegion(var CountryRegion: Record "Country/Region")
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("EU Country/Region Code", CountryRegion.Code);
        CountryRegion.Modify(true);
    end;

    local procedure FilterSIIHistory(var SIIHistory: Record "SII History"; DocType: Enum "SII Doc. Upload State Document Type"; DocNo: Code[20]; DocSource: Enum "SII Doc. Upload State Document Source")
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        LibrarySII.FindSIIDocUploadState(SIIDocUploadState, DocSource, DocType, DocNo);
        SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
    end;

    local procedure MockCustLedgEntryWithIntracommunityCust(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        Customer: Record Customer;
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := LibraryUtility.GenerateGUID;
        CustLedgerEntry."Posting Date" := WorkDate;
        CreateIntraCommunityCustomer(Customer);
        CustLedgerEntry."Sell-to Customer No." := Customer."No.";
        CustLedgerEntry."Customer No." := Customer."No.";
        CustLedgerEntry.Insert();
    end;

    local procedure MockVendLedgEntryWithIntracommunityVend(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        Vendor: Record Vendor;
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document No." := LibraryUtility.GenerateGUID;
        VendorLedgerEntry."Posting Date" := WorkDate;
        CreateIntraCommunityVendor(Vendor);
        VendorLedgerEntry."Buy-from Vendor No." := Vendor."No.";
        VendorLedgerEntry."Vendor No." := Vendor."No.";
        VendorLedgerEntry.Insert();
    end;

    local procedure MockSIIDocUploadStateWithIncorrectStatus(DocSource: enum "SII Doc. Upload State Document Source"; DocType: Enum "SII Doc. Upload State Document Type"; DocNo: Code[20])
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        SIIDocUploadState.Init();
        SIIDocUploadState.Id := LibraryUtility.GetNewRecNo(SIIDocUploadState, SIIDocUploadState.FieldNo(Id));
        SIIDocUploadState."Document Source" := DocSource;
        SIIDocUploadState."Document Type" := DocType;
        SIIDocUploadState."Document No." := DocNo;
        SIIDocUploadState.Status := SIIDocUploadState.Status::Incorrect;
        SIIDocUploadState.Insert();
    end;

    local procedure MockSalesInvoiceDocWithEntry(CustNo: Code[20]; PostingDate: Date): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID;
        SalesInvoiceHeader."Bill-to Customer No." := CustNo;
        SalesInvoiceHeader."Posting Date" := PostingDate;
        SalesInvoiceHeader.Insert();
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := SalesInvoiceHeader."No.";
        CustLedgerEntry."Posting Date" := SalesInvoiceHeader."Posting Date";
        CustLedgerEntry.Insert();

        exit(SalesInvoiceHeader."No.");
    end;

    local procedure MockPurchInvoiceDocWithEntry(VendNo: Code[20]; DocDate: Date): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        PurchInvHeader.Init();
        PurchInvHeader."No." := LibraryUtility.GenerateGUID;
        PurchInvHeader."Pay-to Vendor No." := VendNo;
        PurchInvHeader."Document Date" := DocDate;
        PurchInvHeader.Insert();
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document No." := PurchInvHeader."No.";
        VendorLedgerEntry."External Document No." := PurchInvHeader."No.";
        VendorLedgerEntry."Document Date" := PurchInvHeader."Document Date";
        VendorLedgerEntry.Insert();
        exit(PurchInvHeader."No.");
    end;

    local procedure ValidateElementByName(XMLDoc: DotNet XmlDocument; ElementName: Text; ExpectedValue: Text)
    var
        XMLNodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        i: Integer;
        AssertMsg: Text;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName(ElementName);
        for i := 0 to XMLNodeList.Count - 1 do begin
            XMLNode := XMLNodeList.Item(i);
            AssertMsg := StrSubstNo('Value is invalid for element : %1', ElementName);
            Assert.AreEqual(ExpectedValue, Format(XMLNode.InnerText), AssertMsg);
        end;
    end;

    local procedure SetupXMLNamespaces()
    begin
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('soapenv', SoapenvUrlTok);
        LibraryXPathXMLReader.AddAdditionalNamespace('siiRL', SiiRLUrlTok);
        LibraryXPathXMLReader.AddAdditionalNamespace('sii', SiiUrlTok);
    end;

    local procedure VerifySIIHistoryByStateIdIsSupported(var SIIHistory: Record "SII History"; DocType: Enum "SII Doc. Upload State Document Type"; DocNo: Code[20]; DocSource: Enum "SII Doc. Upload State Document Source")
    begin
        FilterSIIHistory(SIIHistory, DocType, DocNo, DocSource);
        SIIHistory.FindFirst;
        Assert.IsFalse(SIIHistory.Status = SIIHistory.Status::"Not Supported", 'Document is not supported');
    end;

    local procedure VerifyTagAbsence(XMLDoc: DotNet XmlDocument; TagName: Text)
    var
        XMLNodeList: DotNet XmlNodeList;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName(TagName);
        Assert.AreEqual(0, XMLNodeList.Count, StrSubstNo(TagMustNotExistErr, TagName));
    end;

    local procedure VerifyHistoryAndDocUploadValuesAfterMark(DocumentStateId: Integer; ExpectedStatus: Option; ExpectedErrorMessage: Text[250]; ExpectedUploadType: Option; ExpectedRetryAccepted: Boolean)
    var
        SIIHistory: Record "SII History";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        with SIIHistory do begin
            SetRange("Document State Id", DocumentStateId);
            Assert.RecordCount(SIIHistory, 1);
            FindLast;
            TestField(Status, ExpectedStatus);
            Assert.ExpectedMessage(ExpectedErrorMessage, "Error Message");
            TestField("Upload Type", ExpectedUploadType);
            TestField("Is Accepted With Errors Retry", false);
            TestField("Retry Accepted", ExpectedRetryAccepted);
        end;

        with SIIDocUploadState do begin
            Get(DocumentStateId);
            TestField(Status, ExpectedStatus);
            TestField("Transaction Type", ExpectedUploadType);
            TestField("Retry Accepted", ExpectedRetryAccepted);
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Question);
        Reply := LibraryVariableStorage.DequeueBoolean;
    end;
}

