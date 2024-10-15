#if not CLEAN22
codeunit 144052 "Test Intrastat Export"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteState = Pending;
#pragma warning disable AS0072    
    ObsoleteTag = '22.0';
#pragma warning restore AS0072    
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    trigger OnRun()
    begin
        // [FEATURE] [Intrastat]
    end;

    var
        Assert: Codeunit Assert;
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        ReqFieldValMissingErr: Label 'It cannot be zero or empty';
        BatchReExpErr: Label 'Current value is ''Yes''';
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        JnlLineType: Option Receipt,Shipment;
        KBONumberTxt: Label '0437910359';
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateXMLReceipt()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Receipt]
        // [SCENARIO 120548] Exported Intrastat Journal file values equal to Intrastat Journal Line values
        Initialize();

        // [GIVEN] Simplified Intrastat Declaration = true
        UpdateSimplifiedIntrastatDeclOnGLSetup(true);

        // [GIVEN] Intrastat Journal Line of receipt
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch, JnlLineType::Receipt);

        // [WHEN] Intrastat exported to file
        CreateFile(IntrastatJnlBatch, IntrastatJnlLine, KBONumberTxt, false, false);

        // [THEN] Report name created for simplified receipts 'EX19S'
        LibraryXPathXMLReader.VerifyAttributeValue('//Report', 'code', 'EX19S');
        LibraryXPathXMLReader.VerifyAttributeValue('//Data', 'form', 'EXF19S');

        // [THEN] Common fields in XML file are equal to values in Intrastat Journal LIne
        VerifyXMLIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Statistics Period", '19');

        // [THEN] 'EXCNTORI' and 'PARTNERID' not exported
        LibraryXPathXMLReader.VerifyNodeAbsence('//Dim[@prop=''EXCNTORI'']');
        LibraryXPathXMLReader.VerifyNodeAbsence('//Dim[@prop=''PARTNERID'']');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateXMLReceiptCounterparty()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Receipt]
        // [SCENARIO 268704] Exported Intrastat Journal of receipt with counterparty
        Initialize();

        // [GIVEN] Simplified Intrastat Declaration = true
        UpdateSimplifiedIntrastatDeclOnGLSetup(true);

        // [GIVEN] Intrastat Journal Line
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch, JnlLineType::Receipt);

        // [WHEN] Intrastat exported to file with counterparty
        CreateFile(IntrastatJnlBatch, IntrastatJnlLine, KBONumberTxt, false, true);

        // [THEN] Report name created for simplified receipts 'EX19S'
        LibraryXPathXMLReader.VerifyAttributeValue('//Report', 'code', 'EX19S');
        LibraryXPathXMLReader.VerifyAttributeValue('//Data', 'form', 'EXF19S');

        // [THEN] Common fields in XML file are equal to values in Intrastat Journal LIne
        VerifyXMLIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Statistics Period", '19');

        // [THEN] 'EXCNTORI' and 'PARTNERID' not exported
        LibraryXPathXMLReader.VerifyNodeAbsence('//Dim[@prop=''EXCNTORI'']');
        LibraryXPathXMLReader.VerifyNodeAbsence('//Dim[@prop=''PARTNERID'']');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateXMLReceiptExtended()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Receipt]
        // [SCENARIO 268704] Exported Intrastat Journal of receipt for extended declaration
        Initialize();

        // [GIVEN] Simplified Intrastat Declaration = false
        UpdateSimplifiedIntrastatDeclOnGLSetup(false);

        // [GIVEN] Intrastat Journal Line
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch, JnlLineType::Receipt);

        // [WHEN] Intrastat exported to file
        CreateFile(IntrastatJnlBatch, IntrastatJnlLine, KBONumberTxt, false, false);

        // [THEN] Report name created for extended receipts 'EX19E'
        LibraryXPathXMLReader.VerifyAttributeValue('//Report', 'code', 'EX19E');
        LibraryXPathXMLReader.VerifyAttributeValue('//Data', 'form', 'EXF19E');

        // [THEN] Common fields in XML file are equal to values in Intrastat Journal LIne
        VerifyXMLIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Statistics Period", '19');

        // [THEN] 'EXCNTORI' and 'PARTNERID' not exported
        LibraryXPathXMLReader.VerifyNodeAbsence('//Dim[@prop=''EXCNTORI'']');
        LibraryXPathXMLReader.VerifyNodeAbsence('//Dim[@prop=''PARTNERID'']');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateXMLReceiptExtendedCounterparty()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Receipt]
        // [SCENARIO 268704] Exported Intrastat Journal of receipt for extended declaration with counterparty
        Initialize();

        // [GIVEN] Simplified Intrastat Declaration = false
        UpdateSimplifiedIntrastatDeclOnGLSetup(false);

        // [GIVEN] Intrastat Journal Line
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch, JnlLineType::Receipt);

        // [WHEN] Intrastat exported to file with counterparty
        CreateFile(IntrastatJnlBatch, IntrastatJnlLine, KBONumberTxt, false, true);

        // [THEN] Report name created for extended receipts 'EX19E'
        LibraryXPathXMLReader.VerifyAttributeValue('//Report', 'code', 'EX19E');
        LibraryXPathXMLReader.VerifyAttributeValue('//Data', 'form', 'EXF19E');

        // [THEN] Common fields in XML file are equal to values in Intrastat Journal LIne
        VerifyXMLIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Statistics Period", '19');

        // [THEN] 'EXCNTORI' and 'PARTNERID' not exported
        LibraryXPathXMLReader.VerifyNodeAbsence('//Dim[@prop=''EXCNTORI'']');
        LibraryXPathXMLReader.VerifyNodeAbsence('//Dim[@prop=''PARTNERID'']');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateXMLShipment()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Shipment]
        // [SCENARIO 268704] Export Intrastat Journal of shipments
        Initialize();

        // [GIVEN] Simplified Intrastat Declaration = true
        UpdateSimplifiedIntrastatDeclOnGLSetup(true);

        // [GIVEN] Intrastat Journal Line
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch, JnlLineType::Shipment);

        // [WHEN] Intrastat exported to file
        CreateFile(IntrastatJnlBatch, IntrastatJnlLine, KBONumberTxt, false, false);

        // [THEN] Report name created for simplified shipments 'EX29S'
        LibraryXPathXMLReader.VerifyAttributeValue('//Report', 'code', 'EX29S');
        LibraryXPathXMLReader.VerifyAttributeValue('//Data', 'form', 'EXF29S');

        // [THEN] Common fields in XML file are equal to values in Intrastat Journal LIne
        VerifyXMLIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Statistics Period", '29');

        // [THEN] 'EXCNTORI' and 'PARTNERID' not exported
        LibraryXPathXMLReader.VerifyNodeAbsence('//Dim[@prop=''EXCNTORI'']');
        LibraryXPathXMLReader.VerifyNodeAbsence('//Dim[@prop=''PARTNERID'']');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateXMLShipmentCounterparty()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Shipment]
        // [SCENARIO 268704] Export Intrastat Journal of shipments with Counterparty info
        Initialize();

        // [GIVEN] Simplified Intrastat Declaration = true
        UpdateSimplifiedIntrastatDeclOnGLSetup(true);

        // [GIVEN] Intrastat Journal Line
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch, JnlLineType::Shipment);

        // [WHEN] Intrastat exported to file with counterparty
        CreateFile(IntrastatJnlBatch, IntrastatJnlLine, KBONumberTxt, false, true);

        // [THEN] Report name created for simplified shipments with counterparty info 'INTRASTAT_X_S'
        LibraryXPathXMLReader.VerifyAttributeValue('//Report', 'code', 'INTRASTAT_X_S');
        LibraryXPathXMLReader.VerifyAttributeValue('//Data', 'form', 'INTRASTAT_X_SF');

        // [THEN] Common fields in XML file are equal to values in Intrastat Journal LIne
        VerifyXMLIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Statistics Period", '29');

        // [THEN] 'EXCNTORI' and 'PARTNERID' exported with value from Intrastat Journal
        LibraryXPathXMLReader.VerifyNodeValue('//Dim[@prop=''EXCNTORI'']', IntrastatJnlLine."Country/Region of Origin Code");
        LibraryXPathXMLReader.VerifyNodeValue('//Dim[@prop=''PARTNERID'']', IntrastatJnlLine."Partner VAT ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateXMLShipmentExtended()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Shipment]
        // [SCENARIO 268704] Export Intrastat Journal of shipments for extended declaration
        Initialize();

        // [GIVEN] Simplified Intrastat Declaration = false
        UpdateSimplifiedIntrastatDeclOnGLSetup(false);

        // [GIVEN] Intrastat Journal Line
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch, JnlLineType::Shipment);

        // [WHEN] Intrastat exported to file
        CreateFile(IntrastatJnlBatch, IntrastatJnlLine, KBONumberTxt, false, false);

        // [THEN] Report name created for extended shipments 'EX29E'
        LibraryXPathXMLReader.VerifyAttributeValue('//Report', 'code', 'EX29E');
        LibraryXPathXMLReader.VerifyAttributeValue('//Data', 'form', 'EXF29E');

        // [THEN] Common fields in XML file are equal to values in Intrastat Journal LIne
        VerifyXMLIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Statistics Period", '29');

        // [THEN] 'EXCNTORI' and 'PARTNERID' not exported
        LibraryXPathXMLReader.VerifyNodeAbsence('//Dim[@prop=''EXCNTORI'']');
        LibraryXPathXMLReader.VerifyNodeAbsence('//Dim[@prop=''PARTNERID'']');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateXMLShipmentExtendedCounterparty()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Shipment]
        // [SCENARIO 268704] Export Intrastat Journal of shipments for extended declaration with Counterparty info
        Initialize();

        // [GIVEN] Simplified Intrastat Declaration = false
        UpdateSimplifiedIntrastatDeclOnGLSetup(false);

        // [GIVEN] Intrastat Journal Line
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch, JnlLineType::Shipment);

        // [WHEN] Intrastat exported to file with counterparty
        CreateFile(IntrastatJnlBatch, IntrastatJnlLine, KBONumberTxt, false, true);

        // [THEN] Report name created for extended shipments with counterparty info 'INTRASTAT_X_E'
        LibraryXPathXMLReader.VerifyAttributeValue('//Report', 'code', 'INTRASTAT_X_E');
        LibraryXPathXMLReader.VerifyAttributeValue('//Data', 'form', 'INTRASTAT_X_EF');

        // [THEN] Common fields in XML file are equal to values in Intrastat Journal LIne
        VerifyXMLIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Statistics Period", '29');

        // [THEN] 'EXCNTORI' and 'PARTNERID' exported with value from Intrastat Journal
        LibraryXPathXMLReader.VerifyNodeValue('//Dim[@prop=''EXCNTORI'']', IntrastatJnlLine."Country/Region of Origin Code");
        LibraryXPathXMLReader.VerifyNodeValue('//Dim[@prop=''PARTNERID'']', IntrastatJnlLine."Partner VAT ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateXSD()
    begin
        // This test can only be run locally due to its dependency to www.onegate.eu
        /*
        CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateIntrastatJnlBatch(IntrastatJnlBatch,IntrastatJnlTemplate);
        CreateIntrastatJnlLine(IntrastatJnlLine,IntrastatJnlBatch,JnlLineType::Receipt);
        
        KBONumber := '0437910359';
        NihilDeclaration := FALSE;
        
        CreateFile(FileName,IntrastatJnlBatch,IntrastatJnlLine,KBONumber,NihilDeclaration);
        
        VerifyXMLAgainstXSDSchema(
          FileName,'http://www.onegate.eu/2010-01-01',
          'http://www.nbb.be/doc/DQ/f_pdf_ex/declarationReport%20-%20Domain%20SXX.XSD');
        */

    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreventReexport()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [SCENARIO 120548] Reexport file is not possible for Intrastat Journal

        // [GIVEN] Intrastat Journal Line
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch, JnlLineType::Receipt);

        // [GIVEN] Intrastat Journal exported
        CreateFile(IntrastatJnlBatch, IntrastatJnlLine, KBONumberTxt, false, false);

        // [WHEN] Intrastat Journal exported one more time
        asserterror CreateFile(IntrastatJnlBatch, IntrastatJnlLine, KBONumberTxt, false, false);

        // [THEN] Error message appears stating "System 19 reported" should not be TRUE
        Assert.ExpectedError(BatchReExpErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportWithEmptyIntrastatCode()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        CountryRegion: Record "Country/Region";
    begin
        // [SCENARIO 371608] Export Intrastat with Country/Region that has empty Intrastat Code

        // [GIVEN] Intrastat Journal Line with Country/Region that has empty "Intrastat Code"
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch, JnlLineType::Receipt);
        CountryRegion.Get(IntrastatJnlLine."Country/Region Code");
        CountryRegion.Validate("Intrastat Code", '');
        CountryRegion.Modify(true);

        // [WHEN] Intrastat exported to file
        asserterror CreateFile(IntrastatJnlBatch, IntrastatJnlLine, '', false, false);

        // [THEN] Error message appears
        Assert.ExpectedError(ReqFieldValMissingErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetPartnerIDFromEnterpriseNoOfSalesInvoice()
    var
        BillToCustomer: Record Customer;
        SellToCustomer: Record Customer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 268704] Partner VAT ID is taken as Enterprise No from Bill-to Customer No. of Sales Invoice
        Initialize();

        // [GIVEN] Shipment on Sales Invoice = false
        UpdateShipmentOnInvoiceSalesSetup(false);

        // [GIVEN] Bill-to Customer with Enterprise No. = '123456'
        BillToCustomer.Get(CreateEUCustomerWithVATRegNo());
        SellToCustomer.Get(CreateEUCustomerWithVATRegNo());
        ResetCustomerVATRegNo(SellToCustomer);
        CreatePostSalesInvoice(ItemLedgerEntry, SellToCustomer."No.", BillToCustomer."No.", CreateItemWithTariffNo());

        // [WHEN] Intrastat Journal Line is created
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        RunGetItemEntries(ItemLedgerEntry, IntrastatJnlBatch);

        // [THEN] Partner VAT ID  = '123456' in Intrastat Journal Line
        SalesInvoiceHeader.Get(ItemLedgerEntry."Document No.");
        SalesInvoiceHeader.TestField("Enterprise No.", BillToCustomer."Enterprise No.");
        VerifyPartnerID(IntrastatJnlBatch, SellToCustomer."Enterprise No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetPartnerIDFromEnterpriseNoOfSalesShipment()
    var
        BillToCustomer: Record Customer;
        SellToCustomer: Record Customer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 268704] Partner VAT ID is taken as Enterprise No from Bill-to Customer No. of Sales Shipment
        Initialize();

        // [GIVEN] Shipment on Sales Invoice = true
        UpdateShipmentOnInvoiceSalesSetup(true);

        // [GIVEN] Bill-to Customer with Enterprise No. = '123456'
        BillToCustomer.Get(CreateEUCustomerWithVATRegNo());
        SellToCustomer.Get(CreateEUCustomerWithVATRegNo());
        ResetCustomerVATRegNo(SellToCustomer);
        CreatePostSalesInvoice(ItemLedgerEntry, SellToCustomer."No.", BillToCustomer."No.", CreateItemWithTariffNo());

        // [WHEN] Intrastat Journal Line is created
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        RunGetItemEntries(ItemLedgerEntry, IntrastatJnlBatch);

        // [THEN] Partner VAT ID  = '123456' in Intrastat Journal Line
        SalesShipmentHeader.Get(ItemLedgerEntry."Document No.");
        SalesShipmentHeader.TestField("Enterprise No.", BillToCustomer."Enterprise No.");
        VerifyPartnerID(IntrastatJnlBatch, SellToCustomer."Enterprise No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetPartnerIDFromVATRegNoOfSalesInvoice()
    var
        BillToCustomer: Record Customer;
        SellToCustomer: Record Customer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 268704] Partner VAT ID is taken as VAT Registration No from Bill-to Customer No. of Sales Invoice
        Initialize();

        // [GIVEN] Shipment on Sales Invoice = false
        UpdateShipmentOnInvoiceSalesSetup(false);

        // [GIVEN] Bill-to Customer with Enterprise No. = '123456' and VAT Registration No = 'AT0123456'
        BillToCustomer.Get(CreateEUCustomerWithVATRegNo());
        SellToCustomer.Get(CreateEUCustomerWithVATRegNo());
        CreatePostSalesInvoice(ItemLedgerEntry, SellToCustomer."No.", BillToCustomer."No.", CreateItemWithTariffNo());

        // [WHEN] Intrastat Journal Line is created
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        RunGetItemEntries(ItemLedgerEntry, IntrastatJnlBatch);

        // [THEN] Partner VAT ID  = 'AT0123456' in Intrastat Journal Line
        SalesInvoiceHeader.Get(ItemLedgerEntry."Document No.");
        SalesInvoiceHeader.TestField("VAT Registration No.", BillToCustomer."VAT Registration No.");
        VerifyPartnerID(IntrastatJnlBatch, SellToCustomer."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetPartnerIDFromVATRegNoOfSalesShipment()
    var
        BillToCustomer: Record Customer;
        SellToCustomer: Record Customer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 268704] Partner VAT ID is taken as VAT Registration No from Bill-to Customer No. of Sales Shipment
        Initialize();

        // [GIVEN] Shipment on Sales Invoice = true
        UpdateShipmentOnInvoiceSalesSetup(true);

        // [GIVEN] Bill-to Customer with Enterprise No. = '123456' and VAT Registration No = 'AT0123456'
        BillToCustomer.Get(CreateEUCustomerWithVATRegNo());
        SellToCustomer.Get(CreateEUCustomerWithVATRegNo());
        CreatePostSalesInvoice(ItemLedgerEntry, SellToCustomer."No.", BillToCustomer."No.", CreateItemWithTariffNo());

        // [WHEN] Intrastat Journal Line is created
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        RunGetItemEntries(ItemLedgerEntry, IntrastatJnlBatch);

        // [THEN] Partner VAT ID  = 'AT0123456' in Intrastat Journal Line
        SalesShipmentHeader.Get(ItemLedgerEntry."Document No.");
        SalesShipmentHeader.TestField("VAT Registration No.", BillToCustomer."VAT Registration No.");
        VerifyPartnerID(IntrastatJnlBatch, SellToCustomer."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetPartnerIDNonEUCustomer()
    var
        Customer: Record Customer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 268704] Partner VAT ID returns default value for non EU customer
        Initialize();

        // [GIVEN] Shipment on Sales Invoice = false
        UpdateShipmentOnInvoiceSalesSetup(false);

        // [GIVEN] Non EU Bill-to Customer with VAT Registration No. = 'CN000123'
        Customer.Get(CreateCustomerWithVATRegNo());
        CreatePostSalesInvoice(ItemLedgerEntry, CreateCustomerWithVATRegNo(), Customer."No.", CreateItemWithTariffNo());

        // [WHEN] Intrastat Journal Line is created
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        RunGetItemEntries(ItemLedgerEntry, IntrastatJnlBatch);

        // [THEN] Partner VAT ID  = 'QV999999999999' in Intrastat Journal Line
        VerifyPartnerID(IntrastatJnlBatch, GetDefaultPartnerID());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetPartnerIDFromEnterpriseNoOfPurchaseCrMemo()
    var
        Vendor: Record Vendor;
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [Purchase] [Return Shipment]
        // [SCENARIO 268704] Partner VAT ID is taken as Enterprise No from Pay-to Vendor No. of Purchase Credit Memo
        Initialize();

        // [GIVEN] Return Shipment on Credit Memo = false
        UpdateRetShpmtOnCrMemoPurchSetup(false);

        // [GIVEN] Pay-to Vendor with Enterprise No. = '123456'
        Vendor.Get(CreateEUVendorWithVATRegNo());
        ResetVendorVATRegNo(Vendor);
        CreatePostPurchCrMemo(ItemLedgerEntry, CreateEUVendorWithVATRegNo(), Vendor."No.");

        // [WHEN] Intrastat Journal Line is created
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        RunGetItemEntries(ItemLedgerEntry, IntrastatJnlBatch);

        // [THEN] Partner VAT ID  = '123456' in Intrastat Journal Line
        PurchCrMemoHdr.Get(ItemLedgerEntry."Document No.");
        VerifyPartnerID(IntrastatJnlBatch, Vendor."Enterprise No.");
        VerifyPartnerID(IntrastatJnlBatch, PurchCrMemoHdr."Enterprise No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetPartnerIDFromEnterpriseNoOfPurchaseReturnOrder()
    var
        Vendor: Record Vendor;
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        // [FEATURE] [Purchase] [Return Shipment]
        // [SCENARIO 268704] Partner VAT ID is taken as Enterprise No from Pay-to Vendor No. of Purchase Return Order
        Initialize();

        // [GIVEN] Return Shipment on Credit Memo = true
        UpdateRetShpmtOnCrMemoPurchSetup(true);

        // [GIVEN] Pay-to Vendor with Enterprise No. = '123456'
        Vendor.Get(CreateEUVendorWithVATRegNo());
        ResetVendorVATRegNo(Vendor);
        CreatePostPurchCrMemo(ItemLedgerEntry, CreateEUVendorWithVATRegNo(), Vendor."No.");

        // [WHEN] Intrastat Journal Line is created
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        RunGetItemEntries(ItemLedgerEntry, IntrastatJnlBatch);

        // [THEN] Partner VAT ID  = '123456' in Intrastat Journal Line
        ReturnShipmentHeader.Get(ItemLedgerEntry."Document No.");
        VerifyPartnerID(IntrastatJnlBatch, Vendor."Enterprise No.");
        VerifyPartnerID(IntrastatJnlBatch, ReturnShipmentHeader."Enterprise No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetPartnerIDFromVATRegNoOfPurchaseCrMemo()
    var
        Vendor: Record Vendor;
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [Purchase] [Return Shipment]
        // [SCENARIO 268704] Partner VAT ID is taken as VAT Registration No from Pay-to Vendor No. of Purchase Credit Memo
        Initialize();

        // [GIVEN] Return Shipment on Credit Memo = false
        UpdateRetShpmtOnCrMemoPurchSetup(false);

        // [GIVEN] Pay-to Vendor with Enterprise No. = '123456' and VAT Registration No = 'AT0123456'
        Vendor.Get(CreateEUVendorWithVATRegNo());
        CreatePostPurchCrMemo(ItemLedgerEntry, CreateEUVendorWithVATRegNo(), Vendor."No.");

        // [WHEN] Intrastat Journal Line is created
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        RunGetItemEntries(ItemLedgerEntry, IntrastatJnlBatch);

        // [THEN] Partner VAT ID  = 'AT0123456' in Intrastat Journal Line
        PurchCrMemoHdr.Get(ItemLedgerEntry."Document No.");
        VerifyPartnerID(IntrastatJnlBatch, Vendor."VAT Registration No.");
        VerifyPartnerID(IntrastatJnlBatch, PurchCrMemoHdr."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetPartnerIDFromVATRegNoOfPurchaseReturnOrder()
    var
        Vendor: Record Vendor;
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        // [FEATURE] [Purchase] [Return Shipment]
        // [SCENARIO 268704] Partner VAT ID is taken as VAT Registration No from Pay-to Vendor No. of Purchase Return Order
        Initialize();

        // [GIVEN] Return Shipment on Credit Memo = true
        UpdateRetShpmtOnCrMemoPurchSetup(true);

        // [GIVEN] Pay-to Vendor with Enterprise No. = '123456' and VAT Registration No = 'AT0123456'
        Vendor.Get(CreateEUVendorWithVATRegNo());
        CreatePostPurchCrMemo(ItemLedgerEntry, CreateEUVendorWithVATRegNo(), Vendor."No.");

        // [WHEN] Intrastat Journal Line is created
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        RunGetItemEntries(ItemLedgerEntry, IntrastatJnlBatch);

        // [THEN] Partner VAT ID  = 'AT0123456' in Intrastat Journal Line
        ReturnShipmentHeader.Get(ItemLedgerEntry."Document No.");
        VerifyPartnerID(IntrastatJnlBatch, Vendor."VAT Registration No.");
        VerifyPartnerID(IntrastatJnlBatch, ReturnShipmentHeader."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetPartnerIDNonEUVendor()
    var
        Vendor: Record Vendor;
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // [FEATURE] [Purchase] [Return Shipment]
        // [SCENARIO 268704] Partner VAT ID returns default value for non EU vendor
        Initialize();

        // [GIVEN] Return Shipment on Credit Memo = false
        UpdateRetShpmtOnCrMemoPurchSetup(false);

        // [GIVEN] Non EU Pay-to Vendor with VAT Registration No. = 'CN000123'
        Vendor.Get(CreateVendorWithVATRegNo());
        CreatePostPurchCrMemo(ItemLedgerEntry, CreateVendorWithVATRegNo(), Vendor."No.");

        // [WHEN] Intrastat Journal Line is created
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        RunGetItemEntries(ItemLedgerEntry, IntrastatJnlBatch);

        // [THEN] Partner VAT ID  = 'QV999999999999' in Intrastat Journal Line
        VerifyPartnerID(IntrastatJnlBatch, GetDefaultPartnerID());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExportXMLWithSameTariffCountryPartner()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        BillToCustNo: Code[20];
        IntrastatTransType: Code[10];
        IntrastatArea: Code[10];
        TotalWeight1: Decimal;
        NoOfUnits1: Decimal;
        TotalWeight2: Decimal;
        NoOfUnits2: Decimal;
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 268704] Export XML with same Tariff No. and Country of Origin and Partner VAT ID combination
        Initialize();

        // [GIVEN] Shipment on Sales Invoice = false
        UpdateShipmentOnInvoiceSalesSetup(false);

        // [GIVEN] Two sales invoices with the same Item for Bill-to Customer with VAT Registration No = 'AT0123456', Country of Origin = 'SE', TariffNo = 'XY12345'
        // [GIVEN] First invoice with Total Weight = 5.15, No Of Supplementary Units = 2
        // [GIVEN] Second invoice with Total Weight = 6.10, No Of Supplementary Units = 3
        // [GIVEN] Sales invoice with the same Item for Bill-to Customer with VAT Registration No = 'NO987654', Country of Origin = 'SE', TariffNo = 'XY12345'
        // [GIVEN] Sales invoice has Total Weight = 7, No Of Supplementary Units = 4
        Customer1.Get(CreateEUCustomerWithVATRegNo());
        Customer2.Get(CreateEUCustomerWithVATRegNo());
        BillToCustNo := CreateEUCustomerWithVATRegNo(); // have the same Country/Region
        Item.Get(CreateItemWithTariffNo());
        CreatePostSalesInvoice(ItemLedgerEntry, Customer1."No.", BillToCustNo, Item."No.");
        CreatePostSalesInvoice(ItemLedgerEntry, Customer1."No.", BillToCustNo, Item."No.");
        CreatePostSalesInvoice(ItemLedgerEntry, Customer2."No.", BillToCustNo, Item."No.");

        // [GIVEN] Intrastat Journal Lines created
        ItemLedgerEntry.SetRange("Source Type");
        ItemLedgerEntry.SetRange("Source No.");
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        RunGetItemEntries(ItemLedgerEntry, IntrastatJnlBatch);
        IntrastatTransType :=
          LibraryUtility.GenerateRandomCode(IntrastatJnlLine.FieldNo("Transaction Type"), DATABASE::"Intrastat Jnl. Line");
        IntrastatArea := LibraryUtility.GenerateRandomCode(IntrastatJnlLine.FieldNo(Area), DATABASE::"Intrastat Jnl. Line");
        UpdateIntrastatJnlLines(TotalWeight1, NoOfUnits1, Item."No.", Customer1."VAT Registration No.", IntrastatTransType, IntrastatArea);
        UpdateIntrastatJnlLines(TotalWeight2, NoOfUnits2, Item."No.", Customer2."VAT Registration No.", IntrastatTransType, IntrastatArea);

        // [WHEN] Export Intrastat file
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.FindFirst();
        CreateFile(IntrastatJnlBatch, IntrastatJnlLine, KBONumberTxt, false, true);

        // [THEN] 1st <Item> section: 'EXTGO' = '12345', 'EXCNTORI' = 'SE', 'PARTNERID' = 'AT0123456'
        // [THEN] Total Weight 'EXWEIGHT' = 11 (5.15 + 6.10 rounded to integer), No Of Supplementary Units 'EXUNITS' = 5 (2 + 3)
        // [THEN] 2nd <Item> section: 'EXTGO' = '12345', 'EXCNTORI' = 'SE', 'PARTNERID' = 'NO987654'
        // [THEN] Total Weight 'EXWEIGHT' = 7 , No Of Supplementary Units 'EXUNITS' = 4
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/DeclarationReport/Report/Data/Item', 2);
        VerifyXMLDataItemValues(Item, Customer1."VAT Registration No.", TotalWeight1, NoOfUnits1, 0);
        VerifyXMLDataItemValues(Item, Customer2."VAT Registration No.", TotalWeight2, NoOfUnits2, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetPartnerIDFromEnterpriseNoOfServiceInvoice()
    var
        Customer: Record Customer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Service] [Shipment]
        // [SCENARIO 299263] Partner VAT ID is taken as Enterprise No from Bill-to Customer No. of Service Invoice
        Initialize();

        // [GIVEN] Shipment on Sales Invoice = false
        UpdateShipmentOnInvoiceSalesSetup(false);

        // [GIVEN] Posted Service Invoice where Bill-to Customer with Enterprise No. = '123456'
        Customer.Get(CreateEUCustomerWithVATRegNo());
        ResetCustomerVATRegNo(Customer);
        CreatePostServiceInvoice(
          ItemLedgerEntry, DocumentNo, CreateEUCustomerWithVATRegNo(), Customer."No.", CreateItemWithTariffNo());

        // [WHEN] Intrastat Journal Line is created
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        RunGetItemEntries(ItemLedgerEntry, IntrastatJnlBatch);

        // [THEN] Partner VAT ID  = '123456' in Intrastat Journal Line
        ServiceInvoiceHeader.Get(DocumentNo);
        ServiceInvoiceHeader.TestField("Enterprise No.", Customer."Enterprise No.");
        VerifyPartnerID(IntrastatJnlBatch, Customer."Enterprise No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetPartnerIDFromEnterpriseNoOfServiceShipment()
    var
        Customer: Record Customer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Service] [Shipment]
        // [SCENARIO 299263] Partner VAT ID is taken as Enterprise No from Bill-to Customer No. of Service Shipment
        Initialize();

        // [GIVEN] Shipment on Sales Invoice = true
        UpdateShipmentOnInvoiceSalesSetup(true);

        // [GIVEN] Posted Service Invoice where Bill-to Customer with Enterprise No. = '123456'
        Customer.Get(CreateEUCustomerWithVATRegNo());
        ResetCustomerVATRegNo(Customer);
        CreatePostServiceInvoice(
          ItemLedgerEntry, DocumentNo, CreateEUCustomerWithVATRegNo(), Customer."No.", CreateItemWithTariffNo());

        // [WHEN] Intrastat Journal Line is created
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        RunGetItemEntries(ItemLedgerEntry, IntrastatJnlBatch);

        // [THEN] Partner VAT ID  = '123456' in Intrastat Journal Line
        ServiceInvoiceHeader.Get(DocumentNo);
        ServiceInvoiceHeader.TestField("Enterprise No.", Customer."Enterprise No.");
        VerifyPartnerID(IntrastatJnlBatch, Customer."Enterprise No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetPartnerIDFromVATRegNoOfServiceInvoice()
    var
        Customer: Record Customer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Service] [Shipment]
        // [SCENARIO 299263] Partner VAT ID is taken as VAT Registration No from Bill-to Customer No. of Service Invoice
        Initialize();

        // [GIVEN] Shipment on Sales Invoice = false
        UpdateShipmentOnInvoiceSalesSetup(false);

        // [GIVEN] Posted Service Invoice where Bill-to Customer with Enterprise No. = '123456' and VAT Registration No = 'AT0123456'
        Customer.Get(CreateEUCustomerWithVATRegNo());
        CreatePostServiceInvoice(
          ItemLedgerEntry, DocumentNo, CreateEUCustomerWithVATRegNo(), Customer."No.", CreateItemWithTariffNo());

        // [WHEN] Intrastat Journal Line is created
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        RunGetItemEntries(ItemLedgerEntry, IntrastatJnlBatch);

        // [THEN] Partner VAT ID  = 'AT0123456' in Intrastat Journal Line
        ServiceInvoiceHeader.Get(DocumentNo);
        ServiceInvoiceHeader.TestField("VAT Registration No.", Customer."VAT Registration No.");
        VerifyPartnerID(IntrastatJnlBatch, Customer."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetPartnerIDFromVATRegNoOfServiceShipment()
    var
        Customer: Record Customer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Service] [Shipment]
        // [SCENARIO 299263] Partner VAT ID is taken as VAT Registration No from Bill-to Customer No. of Service Shipment
        Initialize();

        // [GIVEN] Shipment on Sales Invoice = true
        UpdateShipmentOnInvoiceSalesSetup(true);

        // [GIVEN] Posted Service Invoice where Bill-to Customer with Enterprise No. = '123456' and VAT Registration No = 'AT0123456'
        Customer.Get(CreateEUCustomerWithVATRegNo());
        CreatePostServiceInvoice(
          ItemLedgerEntry, DocumentNo, CreateEUCustomerWithVATRegNo(), Customer."No.", CreateItemWithTariffNo());

        // [WHEN] Intrastat Journal Line is created
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        RunGetItemEntries(ItemLedgerEntry, IntrastatJnlBatch);

        // [THEN] Partner VAT ID  = 'AT0123456' in Intrastat Journal Line
        ServiceInvoiceHeader.Get(DocumentNo);
        ServiceInvoiceHeader.TestField("VAT Registration No.", Customer."VAT Registration No.");
        VerifyPartnerID(IntrastatJnlBatch, Customer."VAT Registration No.");
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");

        isInitialized := true;
    end;

    local procedure CreateCustomerWithVATRegNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CreateCountryRegionWithIntrastatCode());
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(Customer."Country/Region Code"));
        Customer."Enterprise No." := LibraryUtility.GenerateGUID(); // skip format check on validation
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateEUCustomerWithVATRegNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CreateEUCountryRegionWithIntrastatCode());
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(Customer."Country/Region Code"));
        Customer."Enterprise No." := LibraryUtility.GenerateGUID(); // skip format check on validation
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendorWithVATRegNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CreateCountryRegionWithIntrastatCode());
        Vendor.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(Vendor."Country/Region Code"));
        Vendor."Enterprise No." := LibraryUtility.GenerateGUID(); // skip format check on validation
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateEUVendorWithVATRegNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CreateEUCountryRegionWithIntrastatCode());
        Vendor.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(Vendor."Country/Region Code"));
        Vendor."Enterprise No." := LibraryUtility.GenerateGUID(); // skip format check on validation
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCountryRegionWithIntrastatCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        with CountryRegion do begin
            Validate("Intrastat Code", LibraryUtility.GenerateRandomCode(FieldNo("Intrastat Code"), DATABASE::"Intrastat Jnl. Line"));
            Modify(true);
            exit(Code);
        end;
    end;

    local procedure CreateEUCountryRegionWithIntrastatCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        with CountryRegion do begin
            Validate("Intrastat Code", LibraryUtility.GenerateRandomCode(FieldNo("Intrastat Code"), DATABASE::"Intrastat Jnl. Line"));
            Validate("EU Country/Region Code", Code);
            Modify(true);
            exit(Code);
        end;
    end;

    local procedure CreateIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; JnlLineType: Option Receipt,Shipment)
    begin
        with IntrastatJnlLine do begin
            LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
            Date := ConvertPeriodToDate(IntrastatJnlBatch."Statistics Period");

            Type := JnlLineType;
            "Country/Region Code" := CreateCountryRegionWithIntrastatCode();
            "Transaction Type" := LibraryUtility.GenerateRandomCode(FieldNo("Transaction Type"), DATABASE::"Intrastat Jnl. Line");
            Area := LibraryUtility.GenerateRandomCode(FieldNo(Area), DATABASE::"Intrastat Jnl. Line");
            "Tariff No." := CreateTariffNumber();
            "Total Weight" := LibraryRandom.RandInt(1000);
            "No. of Supplementary Units" := LibraryRandom.RandInt(1000);
            "Statistical Value" := LibraryRandom.RandInt(1000);
            "Transport Method" := LibraryUtility.GenerateRandomCode(FieldNo("Transport Method"), DATABASE::"Intrastat Jnl. Line");
            "Transaction Specification" :=
              LibraryUtility.GenerateRandomCode(FieldNo("Transaction Specification"), DATABASE::"Intrastat Jnl. Line");
            "Partner VAT ID" := LibraryUtility.GenerateGUID();
            "Country/Region of Origin Code" := "Country/Region Code";
            Modify(true);
        end;
    end;

    local procedure CreateIntrastatJnlLineForJobEntry(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; CountryRegionCode: Code[10]; JnlLineType: Option Receipt,Shipment; JobEntryNo: Integer)
    begin
        with IntrastatJnlLine do begin
            "Journal Template Name" := IntrastatJnlBatch."Journal Template Name";
            "Journal Batch Name" := IntrastatJnlBatch.Name;
            "Line No." := LibraryUtility.GetNewRecNo(IntrastatJnlLine, FieldNo("Line No."));
            Date := ConvertPeriodToDate(IntrastatJnlBatch."Statistics Period");
            Type := JnlLineType;
            "Country/Region Code" := CountryRegionCode;
            "Source Type" := "Source Type"::"Job Entry";
            "Source Entry No." := JobEntryNo;
            Insert();
        end;
    end;

    local procedure CreateItemWithTariffNo(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithTariffNo(Item, CreateTariffNumber());
        Item.Validate("Country/Region of Origin Code", LibraryERM.CreateCountryRegionWithIntrastatCode());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateFile(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; IntrastatJnlLine: Record "Intrastat Jnl. Line"; KBONumber: Text[30]; NihilDeclaration: Boolean; Counterparty: Boolean)
    var
        IntrastatMakeDiskTaxAuth: Report "Intrastat - Make Disk Tax Auth";
        FileTempBlob: Codeunit "Temp Blob";
        FileOutStream: OutStream;
        Namespace: Text;
    begin
        IntrastatJnlBatch.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlBatch.SetRange(Name, IntrastatJnlBatch.Name);
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlLine."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlLine."Journal Batch Name");
        IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type);

        IntrastatMakeDiskTaxAuth.SetTableView(IntrastatJnlLine);
        IntrastatMakeDiskTaxAuth.SetTableView(IntrastatJnlBatch);

        FileTempBlob.CreateOutStream(FileOutStream);
        IntrastatMakeDiskTaxAuth.InitializeRequest(FileOutStream, KBONumber, NihilDeclaration, Counterparty);
        IntrastatMakeDiskTaxAuth.UseRequestPage(false);
        IntrastatMakeDiskTaxAuth.Run();

        Namespace := 'http://www.onegate.eu/2010-01-01';
        LibraryXPathXMLReader.InitializeWithBlob(FileTempBlob, Namespace);
    end;

    local procedure CreateTariffNumber(): Code[20]
    var
        TariffNumber: Record "Tariff Number";
    begin
        with TariffNumber do begin
            Init();
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Tariff Number");
            Insert(true);
            exit("No.");
        end;
    end;

    local procedure ConvertPeriodToDate(Period: Code[10]): Date
    var
        Month: Integer;
        Year: Integer;
        Century: Integer;
    begin
        Century := Date2DMY(WorkDate(), 3) div 100;
        Evaluate(Year, CopyStr(Period, 1, 2));
        Year := Year + Century * 100;
        Evaluate(Month, CopyStr(Period, 3, 2));
        exit(DMY2Date(1, Month, Year));
    end;

    local procedure CreatePostSalesInvoice(var ItemLedgerEntry: Record "Item Ledger Entry"; ShipToCustomerNo: Code[20]; BillToCustomerNo: Code[20]; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, ShipToCustomerNo);
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomerNo);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ItemLedgerEntry.SetRange("Source Type", ItemLedgerEntry."Source Type"::Customer);
        ItemLedgerEntry.SetRange("Source No.", SalesHeader."Sell-to Customer No.");
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure CreatePostPurchCrMemo(var ItemLedgerEntry: Record "Item Ledger Entry"; BuyFromVendorNo: Code[20]; PayToVendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", BuyFromVendorNo);
        PurchaseHeader.Validate("Pay-to Vendor No.", PayToVendorNo);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithTariffNo(), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ItemLedgerEntry.SetRange("Source Type", ItemLedgerEntry."Source Type"::Vendor);
        ItemLedgerEntry.SetRange("Source No.", PurchaseHeader."Buy-from Vendor No.");
        ItemLedgerEntry.FindFirst();
    end;

    local procedure CreatePostServiceInvoice(var ItemLedgerEntry: Record "Item Ledger Entry"; var DocumentNo: Code[20]; ShipToCustomerNo: Code[20]; BillToCustomerNo: Code[20]; ItemNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ShipToCustomerNo);
        ServiceHeader.Validate("Bill-to Customer No.", BillToCustomerNo);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(10, 20));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        DocumentNo := ServiceHeader."Last Posting No.";

        ItemLedgerEntry.SetRange("Source Type", ItemLedgerEntry."Source Type"::Customer);
        ItemLedgerEntry.SetRange("Source No.", ServiceHeader."Customer No.");
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    [Scope('OnPrem')]
    procedure DeleteServerFile(ServerFileName: Text)
    var
        FileManagement: Codeunit "File Management";
    begin
        FileManagement.DeleteServerFile(ServerFileName);
    end;

    local procedure GetDefaultPartnerID(): Text[50]
    begin
        exit('QV999999999999');
    end;

    local procedure MockJobEntry(CustomerNo: Code[20]): Integer
    var
        Job: Record Job;
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        Job.Init();
        Job."No." := LibraryUtility.GenerateGUID();
        Job."Bill-to Customer No." := CustomerNo;
        Job.Insert();
        JobLedgerEntry.Init();
        JobLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(JobLedgerEntry, JobLedgerEntry.FieldNo("Entry No."));
        JobLedgerEntry."Job No." := Job."No.";
        JobLedgerEntry.Insert();
        exit(JobLedgerEntry."Entry No.");
    end;

    local procedure RunGetItemEntries(var ItemLedgerEntry: Record "Item Ledger Entry"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        GetItemLedgerEntries: Report "Get Item Ledger Entries";
    begin
        IntrastatJnlLine."Journal Template Name" := IntrastatJnlBatch."Journal Template Name";
        IntrastatJnlLine."Journal Batch Name" := IntrastatJnlBatch.Name;
        GetItemLedgerEntries.InitializeRequest(WorkDate(), WorkDate(), 0);
        GetItemLedgerEntries.SetIntrastatJnlLine(IntrastatJnlLine);
        GetItemLedgerEntries.SetTableView(ItemLedgerEntry);
        GetItemLedgerEntries.UseRequestPage(false);
        GetItemLedgerEntries.Run();
    end;

    local procedure ResetCustomerVATRegNo(var Customer: Record Customer)
    begin
        Customer."VAT Registration No." := '';
        Customer.Modify();
    end;

    local procedure ResetVendorVATRegNo(var Vendor: Record Vendor)
    begin
        Vendor."VAT Registration No." := '';
        Vendor.Modify();
    end;

    local procedure UpdateIntrastatJnlLines(var TotalWeight: Decimal; var NoOfUnits: Decimal; ItemNo: Code[20]; PartnerID: Text[50]; IntrastatTransType: Code[10]; IntrastatArea: Code[10])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        with IntrastatJnlLine do begin
            SetRange("Item No.", ItemNo);
            SetRange("Partner VAT ID", PartnerID);
            FindSet();
            repeat
                "Transaction Type" := IntrastatTransType;
                Area := IntrastatArea;
                "Total Weight" := LibraryRandom.RandDecInRange(10, 20, 2);
                "No. of Supplementary Units" := LibraryRandom.RandIntInRange(10, 20);
                Modify();
                TotalWeight += "Total Weight";
                NoOfUnits += "No. of Supplementary Units";
            until Next() = 0;
        end;
    end;

    local procedure UpdateSimplifiedIntrastatDeclOnGLSetup(SimpleIntrastatDecl: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Simplified Intrastat Decl.", SimpleIntrastatDecl);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateShipmentOnInvoiceSalesSetup(ShipmentOnInvoice: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Shipment on Invoice", ShipmentOnInvoice);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateRetShpmtOnCrMemoPurchSetup(RetShpmtOnCrMemo: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Return Shipment on Credit Memo", RetShpmtOnCrMemo);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure VerifyPartnerID(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; PartnerID: Text[50])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.FindFirst();
        IntrastatJnlLine.TestField("Partner VAT ID", PartnerID);
    end;

    local procedure VerifyXMLIntrastatJnlLine(IntrastatJnlLine: Record "Intrastat Jnl. Line"; StatisticsPeriod: Code[10]; SystemType: Text)
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(IntrastatJnlLine."Country/Region Code");
        LibraryXPathXMLReader.VerifyAttributeValue(
          '//Report', 'date', Format(ConvertPeriodToDate(StatisticsPeriod), 0, '<Year4>-<Month,2>'));
        LibraryXPathXMLReader.VerifyNodeValue('//Dim[@prop=''EXTRF'']', SystemType);
        LibraryXPathXMLReader.VerifyNodeValue('//Dim[@prop=''EXCNT'']', CountryRegion."Intrastat Code");
        LibraryXPathXMLReader.VerifyNodeValue('//Dim[@prop=''EXTTA'']', IntrastatJnlLine."Transaction Type");
        LibraryXPathXMLReader.VerifyNodeValue('//Dim[@prop=''EXREG'']', IntrastatJnlLine.Area);
        LibraryXPathXMLReader.VerifyNodeValue(
          '//Dim[@prop=''EXTGO'']', DelChr(IntrastatJnlLine."Tariff No.", '=', DelChr(IntrastatJnlLine."Tariff No.", '=', '0123456789')));
        LibraryXPathXMLReader.VerifyNodeValue('//Dim[@prop=''EXWEIGHT'']', Format(Round(IntrastatJnlLine."Total Weight", 1), 0, 9));
        LibraryXPathXMLReader.VerifyNodeValue(
          '//Dim[@prop=''EXUNITS'']', Format(Round(IntrastatJnlLine."No. of Supplementary Units"), 0, 9));
        LibraryXPathXMLReader.VerifyNodeValue('//Dim[@prop=''EXTXVAL'']', Format(IntrastatJnlLine."Statistical Value"));
    end;

    local procedure VerifyXMLDataItemValues(Item: Record Item; VATRegNo: Text[20]; TotalWeight: Decimal; NoOfUnits: Decimal; Index: Integer)
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          '//Dim[@prop=''EXTGO'']', DelChr(Item."Tariff No.", '=', DelChr(Item."Tariff No.", '=', '0123456789')), Index);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//Dim[@prop=''EXCNTORI'']', Item."Country/Region of Origin Code", Index);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//Dim[@prop=''PARTNERID'']', VATRegNo, Index);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//Dim[@prop=''EXWEIGHT'']', Format(Round(TotalWeight, 1)), Index);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//Dim[@prop=''EXUNITS'']', Format(NoOfUnits), Index);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

#endif