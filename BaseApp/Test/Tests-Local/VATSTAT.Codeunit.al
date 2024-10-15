codeunit 144001 VATSTAT
{
    // // [FEATURE] [VAT Statement]

    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        FileMgt: Codeunit "File Management";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        FdfFileHelper: Codeunit FDFFileHelper;
        IncludeVATEntries: Option Open,Closed,"Open and Closed";
        PeriodSelection: Option "Before and Within Period","Within Period";
        ReportingType: Option Quarter,Month,"Defined period";
        DefaultFdfTxt: Label 'Default.fdf';
        DefaultXmlTxt: Label 'Default.xml';
        arguments: Option ,Zahl101,Zahl102,Zahl103,Zahl104,Zahl105,Zahl106,Zahl107,Zahl108,Zahl109,Zahl110,Zahl111,Zahl112,Zahl113,Zahl115a,Zahl116a,Zahl117a,Zahl118a,Zahl119a,Zahl120a,Zahl123,Zahl124,Zahl125,Zahl125b,Zahl125a,Zahl126,Zahl127,Zahl128a,Zahl129a,Zahl130a,Zahl131,Zahl132,Zahl133,Zahl134,Zahl134a,Zahl135,Zahl136,Zahl136a,Zahl137a,Zahl137,Zahl138,Zahl139,DD140,Zahl140,DD141,Zahl141,DD143_27,Zahl143_27,DD143_28,Zahl143_28,DD143,Zahl143,Checkbox100X,Checkbox100Xx;
        PdfFileName: Text[260];
        FdfFileName: Text[260];
        XmlFileName: Text[260];
        IsInitialized: Boolean;
        AdjustDatesMsg: Label 'Would you like to set the Starting and Ending Date according to the selected Reporting Type?';
        StringContainsErr: Label 'The specified substring=''%2'' did not occur within this string=''%1''.';
        NumberOffFdfHeaderAndFooterLinesTok: Label '15';
        DefinedHeaderAndFooterLines: Integer;
        TestClassWorkdate: Date;
        MissingFDFTagErr: Label 'Assert.IsTrue failed. The key="%1" could not be found';
        MissingXMLElementErr: Label 'Assert.AreNotEqual failed. Expected any value except:<0> (Integer). Actual:<0> (Integer)';

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure FDFFileInsteadOfPrintOut()
    var
        VATStatementAT: Report "VAT Statement AT";
    begin
        // Purpose of the test is to validate that a FDF file is generated.
        // Setup.
        Initialize;
        EnqueRequestPageFields(WorkDate, 0D, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::Month, false, false, false, false, 0);

        // Exercise: Run the VAT Statement AT report.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify that the Fdf file is generated
        Assert.IsTrue(Exists(FdfFileName), StrSubstNo('File %1 must be generated', FdfFileName));
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATConfirmHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure XMLFileInsteadOfPrintOut()
    var
        VATStatementAT: Report "VAT Statement AT";
    begin
        // Purpose of the test is to validate that a FDF file is generated.
        // Setup.
        Initialize;
        EnqueRequestPageFields(0D, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::Quarter, false, false, false, false, 0);

        // Exercise: Run the VAT Statement AT report.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify that the Xml file are generated
        Assert.IsTrue(Exists(XmlFileName), StrSubstNo('File %1 must be generated', XmlFileName));
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure NationalSalesInvoiceInFDFFile()
    var
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // Enter a domestic sales invoice and verify that the data in the generated FDF file.
        Initialize;
        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a domestic sales invoice.
        DocNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, 'DOMESTIC');

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Sale);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl101, VATEntry.Base + VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl115a, VATEntry.Base);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 2);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', -(VATEntry.Base + VATEntry.Amount));
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/VERSTEUERT/KZ022', -VATEntry.Base);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 2);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure EUSalesInvoiceInFDFFile()
    var
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // Enter an eu sales invoice and verify that the data in the generated FDF file.
        Initialize;
        SetupVatStatementLine('1000', 'EULIEF', true);
        SetupVatStatementLine('1017', 'EULIEF', true);
        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create an eu sales invoice.
        DocNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, 'EU');

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Sale);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl101, VATEntry.Base + VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl108, VATEntry.Base);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 2);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', -(VATEntry.Base + VATEntry.Amount));
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/STEUERFREI/KZ017', -VATEntry.Base);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 2);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ForeignSalesInvoiceInFDFFile()
    var
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // Enter a foreign sales invoice and verify that the data in the generated FDF file.
        Initialize;
        SetupVatStatementLine('1011', 'BU0', true);
        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a foreign sales invoice.
        DocNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, 'EXPORT');

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Sale);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl101, VATEntry.Base + VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl105, VATEntry.Base);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 2);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', -(VATEntry.Base + VATEntry.Amount));
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/STEUERFREI/KZ011', -VATEntry.Base);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 2);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure NationalPurchaseInvoiceInFDFFile()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // Enter a domestic purchase invoice and verify that the data in the generated FDF file.
        Initialize;
        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a domestic purchase invoice.
        DocNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, 'DOMESTIC');

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl133, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 1);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ060', VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 2);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure EUPurchaseInvoiceInFDFFile()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // Enter an eu purchase invoice and verify that the data in the generated FDF file.
        Initialize;
        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create an eu purchase invoice.
        DocNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, 'EU');

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl126, VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl128a, VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl135, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 3);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'INNERGEMEINSCHAFTLICHE_ERWERBE/KZ070', VATEntry.Base);
        VerifyXMLLine(LibraryXPathXMLReader, 'INNERGEMEINSCHAFTLICHE_ERWERBE/VERSTEUERT_IGE/KZ072', VATEntry.Base);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ065', VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 4);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ForeignPurchaseInvoiceInFDFFile()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
    begin
        // Enter a foreign purchase invoice and verify that the data in the generated FDF file.
        Initialize;
        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a foreign purchase invoice.
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, 'EXPORT');

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify various Amounts in the VAT Statement report.
        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 1);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure NationalSalesCreditMemoInFile()
    var
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // Enter a domestic sales invoice and verify that the data in the generated FDF file.
        Initialize;
        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a domestic sales invoice.
        DocNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", 'DOMESTIC');

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Sale);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl110, VATEntry.Amount);
        VerifyFDFLineMinus(FdfFileHelper, arguments::DD143);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl143, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 3);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/STEUERFREI/KZ019', VATEntry.Amount);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ090', -VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 3);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure NationalSalesCreditMemo1067InFile()
    var
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 379404] VAT Statement Line '1067' is exported in case of Sales Credit Memo
        Initialize;

        // [GIVEN] Setup VAT Statement Line '1067' with 'Row Totaling' = 'UST20' (Sale Domestic VAT20)
        SetupVatStatementLine('1067', 'UST20', true);
        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // [GIVEN] Posted domestic Sales Credit Memo (VAT Amount = 100)
        DocNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", 'DOMESTIC');
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Sale);

        // [WHEN] Export VAT Statement
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // [THEN] '1067' is exported:
        // [THEN] FDF file 'DD141' = '-'
        // [THEN] FDF file 'Zahl141' = '100'
        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineMinus(FdfFileHelper, arguments::DD141);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl141, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 5);

        // [THEN] XML file 'KZ067' = '-100'
        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ067', -VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 4);

        // Tear Down
        SetupVatStatementLine('1067', '', false);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure EUPurchaseCreditMemo1067InFile()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
        PurchInvoiceVATEntryAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 382292] VAT Statement Line '1067' is exported in case of Purchase Credit Memo
        Initialize;

        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // [GIVEN] Posted EU Purchase Invoice (VAT Amount = 100)
        DocNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, 'EU');
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Purchase);
        PurchInvoiceVATEntryAmount := VATEntry.Amount;

        // [GIVEN] Posted EU Purchase Credit Memo (VAT Amount = -300)
        DocNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", 'EU');
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Purchase);

        // [WHEN] Export VAT Statement
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // [THEN] '1067' is exported:
        // [THEN] FDF file 'Zahl141' = '-200'
        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl141, PurchInvoiceVATEntryAmount + VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 3);

        // [THEN] XML file 'KZ067' = '200'
        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ067', -(PurchInvoiceVATEntryAmount + VATEntry.Amount));

        // [THEN] XML file 'KZ090' = '-200'
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ090', PurchInvoiceVATEntryAmount + VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 3);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure EUSalesCreditMemoInFile()
    var
        SalesHeader: Record "Sales Header";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
    begin
        // Enter an eu sales invoice and verify that the data in the generated FDF file.
        Initialize;
        SetupVatStatementLine('1000', 'EULIEF', true);
        SetupVatStatementLine('1017', 'EULIEF', true);
        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create an eu sales invoice.
        CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", 'EU');

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify various Amounts in the VAT Statement report.
        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 1);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ForeignSalesCreditMemoInFile()
    var
        SalesHeader: Record "Sales Header";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
    begin
        // [FEATURE] [Sales]
        // Enter a foreign sales invoice and verify that the data in the generated FDF file
        Initialize;

        // [GIVEN] Setup VAT Statement Line '1011' with 'Row Totaling' = 'BU0' (Sale Export VAT10)
        SetupVatStatementLine('1011', 'BU0', true);
        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // [GIVEN] Foreign sales invoice
        CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", 'EXPORT');

        // [WHEN] Export VAT Statement
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // [THEN] There is one KZ line
        // [THEN] '1090' is exported with amount -1000
        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 1);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ConstructionPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        Item: Record Item;
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATTotalRowNo: Code[10];
        DocNo: Code[20];
        VATBusPostingGroupCode: Code[20];
        VATProPostingGroupCode: Code[20];
    begin
        // Enter a foreign purchase invoice and verify that the data in the generated FDF file.
        Initialize;

        CreateVATPostingGroup(VATBusPostingGroupCode, VATProPostingGroupCode);

        VATTotalRowNo := LibraryUtility.GenerateRandomCode(VATStatementLine.FieldNo("Row No."), DATABASE::"VAT Statement Line");
        CreateVATEntTotVATStmtLine(VATTotalRowNo, VATBusPostingGroupCode, VATProPostingGroupCode);
        CreateRowTotVATStmtLine('1048', VATTotalRowNo);
        CreateRowTotVATStmtLine('1082', VATTotalRowNo);

        CreateItem(Item, VATProPostingGroupCode);

        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a foreign purchase invoice.
        DocNo := CreateAndPostPurchaseDocumentOnItem(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VATBusPostingGroupCode, Item);

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl125, VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl136a, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 2);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/VERSTEUERT/KZ048', VATEntry.Amount);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ082', VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 3);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ConstructionPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        Item: Record Item;
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATTotalRowNo: Code[10];
        DocNo: Code[20];
        VATBusPostingGroupCode: Code[20];
        VATProPostingGroupCode: Code[20];
    begin
        // Enter a foreign purchase invoice and verify that the data in the generated FDF file.
        Initialize;

        CreateVATPostingGroup(VATBusPostingGroupCode, VATProPostingGroupCode);

        VATTotalRowNo := LibraryUtility.GenerateRandomCode(VATStatementLine.FieldNo("Row No."), DATABASE::"VAT Statement Line");
        CreateVATEntTotVATStmtLine(VATTotalRowNo, VATBusPostingGroupCode, VATProPostingGroupCode);
        CreateRowTotVATStmtLine('1048', VATTotalRowNo);
        CreateRowTotVATStmtLine('1082', VATTotalRowNo);

        CreateItem(Item, VATProPostingGroupCode);

        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a foreign purchase invoice.
        DocNo := CreateAndPostPurchaseDocumentOnItem(
            PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VATBusPostingGroupCode, Item);

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl141, VATEntry.Amount);
        VerifyFDFLineMinus(FdfFileHelper, arguments::DD143);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl143, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 3);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ067', -VATEntry.Amount);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ090', VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 3);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ConstructionReverseChargePurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        Item: Record Item;
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATTotalRowNo: Code[10];
        DocNo: Code[20];
        VATBusPostingGroupCode: Code[20];
        VATProPostingGroupCode: Code[20];
    begin
        // Enter a foreign purchase invoice and verify that the data in the generated FDF file.
        Initialize;

        CreateVATPostingGroup(VATBusPostingGroupCode, VATProPostingGroupCode);

        VATTotalRowNo := LibraryUtility.GenerateRandomCode(VATStatementLine.FieldNo("Row No."), DATABASE::"VAT Statement Line");
        CreateVATEntTotVATStmtLine(VATTotalRowNo, VATBusPostingGroupCode, VATProPostingGroupCode);
        CreateRowTotVATStmtLine('1057', VATTotalRowNo);
        CreateRowTotVATStmtLine('1066', VATTotalRowNo);

        CreateItem(Item, VATProPostingGroupCode);

        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a foreign purchase invoice.
        DocNo := CreateAndPostPurchaseDocumentOnItem(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VATBusPostingGroupCode, Item);

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl124, VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl136, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 2);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/VERSTEUERT/KZ057', VATEntry.Amount);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ066', VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 3);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ConstructionReverseChargeCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        Item: Record Item;
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATTotalRowNo: Code[10];
        DocNo: Code[20];
        VATBusPostingGroupCode: Code[20];
        VATProPostingGroupCode: Code[20];
    begin
        // Enter a foreign purchase invoice and verify that the data in the generated FDF file.
        Initialize;

        CreateVATPostingGroup(VATBusPostingGroupCode, VATProPostingGroupCode);

        VATTotalRowNo := LibraryUtility.GenerateRandomCode(VATStatementLine.FieldNo("Row No."), DATABASE::"VAT Statement Line");
        CreateVATEntTotVATStmtLine(VATTotalRowNo, VATBusPostingGroupCode, VATProPostingGroupCode);
        CreateRowTotVATStmtLine('1057', VATTotalRowNo);
        CreateRowTotVATStmtLine('1066', VATTotalRowNo);

        CreateItem(Item, VATProPostingGroupCode);

        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a foreign purchase invoice.
        DocNo := CreateAndPostPurchaseDocumentOnItem(
            PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VATBusPostingGroupCode, Item);

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl141, VATEntry.Amount);
        VerifyFDFLineMinus(FdfFileHelper, arguments::DD143);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl143, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 3);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ067', -VATEntry.Amount);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ090', VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 3);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ReportOtionSurplusAndMail()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // Enter an eu purchase invoice and verify that the data in the generated FDF file.
        Initialize;
        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, true, true, 0);

        // Create an eu purchase invoice.
        DocNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, 'EU');

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl126, VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl128a, VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl135, VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Checkbox100X, 1);
        VerifyFDFLineValue(FdfFileHelper, arguments::Checkbox100Xx, 1);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 5);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'INNERGEMEINSCHAFTLICHE_ERWERBE/KZ070', VATEntry.Base);
        VerifyXMLLine(LibraryXPathXMLReader, 'INNERGEMEINSCHAFTLICHE_ERWERBE/VERSTEUERT_IGE/KZ072', VATEntry.Base);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ065', VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 4);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/ERKLAERUNGS_UEBERMITTLUNG/ERKLAERUNG/VORSTEUER/ARE', 'J');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/ERKLAERUNGS_UEBERMITTLUNG/ERKLAERUNG/VORSTEUER/REPO', 'J');
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure NewReportIDs27And28()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry1: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
        Item1: Record Item;
        Item2: Record Item;
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo1: Code[20];
        DocNo2: Code[20];
        VATBusPostingGroupCode: Code[20];
        VATProPostingGroupCode: Code[20];
    begin
        // Enter a foreign purchase invoice and verify that the data is NOT in the generated FDF file (field 27 and 28 have been removed in 2014).
        Initialize;

        // Setup: Item1
        CreateVATPostingGroup(VATBusPostingGroupCode, VATProPostingGroupCode);

        CreateVATEntTotVATStmtLine('1027', VATBusPostingGroupCode, VATProPostingGroupCode);

        CreateItem(Item1, VATProPostingGroupCode);

        // Setup: Item2
        CreateVATPostingGroup(VATBusPostingGroupCode, VATProPostingGroupCode);

        CreateVATEntTotVATStmtLine('1028', VATBusPostingGroupCode, VATProPostingGroupCode);

        CreateItem(Item2, VATProPostingGroupCode);

        // Create a foreign purchase invoice.
        DocNo1 :=
          CreateAndPostPurchaseDocumentOnItem(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VATBusPostingGroupCode, Item1);
        DocNo2 :=
          CreateAndPostPurchaseDocumentOnItem(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VATBusPostingGroupCode, Item2);

        // Exercise.
        EnqueRequestPageFields(WorkDate, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry1, DocNo1, VATEntry1."Document Type"::Invoice, VATEntry1.Type::Purchase);
        GetVATEntry(VATEntry2, DocNo2, VATEntry2."Document Type"::Invoice, VATEntry2.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        // These fields are missing
        asserterror VerifyFDFLineValue(FdfFileHelper, arguments::Zahl141, VATEntry1.Amount + VATEntry2.Amount);
        Assert.ExpectedError(StrSubstNo(MissingFDFTagErr, Format(arguments::Zahl141)));
        asserterror VerifyFDFLineValue(FdfFileHelper, arguments::Zahl143_27, VATEntry1.Amount);
        Assert.ExpectedError(StrSubstNo(MissingFDFTagErr, Format(arguments::Zahl143_27)));
        asserterror VerifyFDFLineValue(FdfFileHelper, arguments::Zahl143_28, VATEntry2.Amount);
        Assert.ExpectedError(StrSubstNo(MissingFDFTagErr, Format(arguments::Zahl143_28)));
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        // These fields are missing
        asserterror VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ067', VATEntry1.Amount + VATEntry2.Amount);
        Assert.ExpectedError(MissingXMLElementErr);
        asserterror VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ027', VATEntry1.Amount);
        Assert.ExpectedError(MissingXMLElementErr);
        asserterror VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ028', VATEntry2.Amount);
        Assert.ExpectedError(MissingXMLElementErr);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 1);
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateRequestPageHandler,UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure TestUpdateVATStatementTemplate()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementLine: Record "VAT Statement Line";
        StatementTemplateName: Code[10];
    begin
        Initialize;

        // Setup: Clear all date to be created by update
        StatementTemplateName := 'UVA-2016';
        VATStatementLine.SetRange("Statement Template Name", StatementTemplateName);
        VATStatementLine.DeleteAll;
        VATStatementTemplate.SetRange(Name, StatementTemplateName);
        VATStatementTemplate.DeleteAll;
        VATStatementName.SetRange("Statement Template Name", StatementTemplateName);
        VATStatementName.DeleteAll;

        Commit;

        // Execute: Run the report
        REPORT.Run(REPORT::"Update VAT Statement Template");

        // Validate: Statement Lines should hold data
        VATStatementLine.SetRange("Statement Template Name", StatementTemplateName);
        Assert.IsFalse(VATStatementLine.IsEmpty, 'VAT Statment Lines should hold the updateded values');
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateRequestPageHandler,UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure TestUpdateVATStatementTemplateWithData()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATLineCount: Integer;
    begin
        Initialize;

        // Setup: Clear all date to be created by update
        REPORT.Run(REPORT::"Update VAT Statement Template");

        VATStatementLine.SetRange("Statement Template Name", 'UVA-2016');
        VATLineCount := VATStatementLine.Count;

        VATStatementLine.SetFilter("Row Totaling", '<>''''');
        VATStatementLine.DeleteAll;
        VATStatementLine.SetRange("Row Totaling");
        Assert.IsTrue(VATLineCount > VATStatementLine.Count, 'Verify that we did delete something');

        Commit;

        // Execute: Run the report
        REPORT.Run(REPORT::"Update VAT Statement Template");

        // Validate: Statement Lines should hold data
        Assert.AreEqual(VATLineCount, VATStatementLine.Count, 'VAT Statment Lines should be recreated');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure UpdateVATStmtTemplateRequestPageHandler(var UpdateVATStatementTemplate: TestRequestPage "Update VAT Statement Template")
    begin
        UpdateVATStatementTemplate.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UpdateVATStmtTemplateConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATConfirmHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure TestCompanyInfoInVATStatement()
    var
        CompanyInformation: Record "Company Information";
        VATStatementAT: Report "VAT Statement AT";
    begin
        // Purpose of the test is to validate that a FDF file is generated.
        // Setup.
        Initialize;
        CompanyInformation.Get;
        CompanyInformation."Address 2" := 'Zenter';
        CompanyInformation."House Number" := '20House';
        CompanyInformation."Floor Number" := '07Floor';
        CompanyInformation."Room Number" := '86Raum';
        CompanyInformation.Modify;
        Commit;
        EnqueRequestPageFields(0D, WorkDate, IncludeVATEntries::"Open and Closed", PeriodSelection::"Within Period",
          ReportingType::Quarter, false, false, false, false, 0);

        // Exercise: Run the VAT Statement AT report.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal;

        // Verify that the Xml file are generated
        Assert.IsTrue(Exists(XmlFileName), StrSubstNo('File %1 must be generated', XmlFileName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRelocationOfLocalVATReports()
    var
        DACHReportSelections: Record "DACH Report Selections";
    begin
        DACHReportSelections.Get(DACHReportSelections.Usage::"VAT Statement", 1);
        Assert.AreEqual(11110, DACHReportSelections."Report ID", 'Report 11110 was expected');
        DACHReportSelections.Get(DACHReportSelections.Usage::"Sales VAT Acc. Proof", 1);
        Assert.AreEqual(11, DACHReportSelections."Report ID", 'Report 11 was expected');
        DACHReportSelections.Get(DACHReportSelections.Usage::"VAT Statement Schedule", 1);
        Assert.AreEqual(11010, DACHReportSelections."Report ID", 'Report 11010 was expected');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        PdfFile: File;
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::VATSTAT);
        LibraryVariableStorage.Clear;

        if TestClassWorkdate <> 0D then begin
            TestClassWorkdate := CalcDate('<+1D>', TestClassWorkdate);
            WorkDate := TestClassWorkdate;
        end;

        if Exists(FdfFileName) and not Erase(FdfFileName) then
            Assert.IsFalse(Exists(XmlFileName), StrSubstNo('File %1 must be removed', FdfFileName));

        if Exists(XmlFileName) and not Erase(XmlFileName) then
            Assert.IsFalse(Exists(XmlFileName), StrSubstNo('File %1 must be removed', XmlFileName));

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::VATSTAT);

        PdfFileName := CopyStr(FileMgt.ServerTempFileName('pdf'), 1, 260);
        PdfFile.Create(PdfFileName);
        PdfFile.Write(PdfFileName);
        PdfFile.Close;

        FdfFileName := CopyStr(FileMgt.GetDirectoryName(PdfFileName) + '\' + DefaultFdfTxt, 1, 260);
        XmlFileName := CopyStr(FileMgt.GetDirectoryName(PdfFileName) + '\' + DefaultXmlTxt, 1, 260);

        if Exists(FdfFileName) then
            Erase(FdfFileName);

        if Exists(XmlFileName) then
            Erase(XmlFileName);

        TestClassWorkdate := CalcDate('<-1Y>', Today);
        WorkDate := TestClassWorkdate;

        LibraryERMCountryData.UpdateGeneralPostingSetup;
        Commit;

        Evaluate(DefinedHeaderAndFooterLines, NumberOffFdfHeaderAndFooterLinesTok);

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::VATSTAT);
    end;

    local procedure SetupVatStatementLine(RowNo: Code[10]; RowTotalingFilter: Text; Add: Boolean)
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        with VATStatementLine do begin
            SetFilter("Statement Template Name", 'UVA-2016');
            SetFilter("Row No.", RowNo);
            FindFirst;
            if not StringContains("Row Totaling", RowTotalingFilter) then begin
                if Add then begin
                    if "Row Totaling" <> '' then
                        RowTotalingFilter := '|' + RowTotalingFilter;
                    "Row Totaling" := CopyStr("Row Totaling" + RowTotalingFilter, 1, MaxStrLen("Row Totaling"));
                end else
                    "Row Totaling" := CopyStr(RowTotalingFilter, 1, MaxStrLen("Row Totaling"));
                Modify;
            end;
        end;
    end;

    [Normal]
    local procedure EnqueRequestPageFields(StartingDate: Date; EndingDate: Date; IncludeVATEntries: Option; PeriodSelection: Option; ReportingType: Option; CheckPositions: Boolean; RoundToWholeNumbers: Boolean; SurplusUsedToPayDues: Boolean; AdditionalInvoicesSentViaMail: Boolean; NumberPar6Abs1: Integer)
    begin
        LibraryVariableStorage.Enqueue(ReportingType);
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(IncludeVATEntries);
        LibraryVariableStorage.Enqueue(PeriodSelection);
        LibraryVariableStorage.Enqueue(CheckPositions);
        LibraryVariableStorage.Enqueue(RoundToWholeNumbers);
        LibraryVariableStorage.Enqueue(SurplusUsedToPayDues);
        LibraryVariableStorage.Enqueue(AdditionalInvoicesSentViaMail);
        LibraryVariableStorage.Enqueue(NumberPar6Abs1);
    end;

    local procedure CreateAndPostSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Option; BusPostingGroup: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Find an Item and Create Sales Order with Random Quantity
        LibrarySales.FindItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(BusPostingGroup));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; BusPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        // Find an Item and Create Purchase Order with Random Quantity
        // Returns the number of the purchase document
        LibrarySales.FindItem(Item);
        exit(CreateAndPostPurchaseDocumentOnItem(PurchaseHeader, DocumentType, BusPostingGroup, Item));
    end;

    local procedure CreateAndPostPurchaseDocumentOnItem(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; BusPostingGroup: Code[20]; Item: Record Item): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Order with Random Quantity
        // Returns the number of the purchase document
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(BusPostingGroup));
        PurchaseHeader.Validate(
          "Vendor Cr. Memo No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Cr. Memo No."), DATABASE::"Purchase Header"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateCustomer(BusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        // Create a new Domestic Customer.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", BusPostingGroup);
        Customer.Validate("VAT Bus. Posting Group", BusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(BusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        // Create a new Domestic Customer.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", BusPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", BusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVATPostingGroup(var VATBusinessPostingGroupCode: Code[20]; var VATProductPostingGroupCode: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VST_GLAccount: Record "G/L Account";
        UST_GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATProductPostingGroupCode := VATProductPostingGroup.Code;
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATBusinessPostingGroupCode := VATBusinessPostingGroup.Code;

        LibraryERM.CreateGLAccount(VST_GLAccount);
        LibraryERM.CreateGLAccount(UST_GLAccount);

        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode, VATProductPostingGroupCode);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("VAT Identifier",
          LibraryUtility.GenerateRandomCode(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(10, 30));
        VATPostingSetup.Validate("Purchase VAT Account", VST_GLAccount."No.");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", UST_GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item; VATProPostingGroupCode: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProPostingGroupCode);
        Item.Modify(true);
    end;

    local procedure StringContains(String: Text; SubString: Text): Boolean
    begin
        exit(StrPos(String, SubString) > 0);
    end;

    local procedure AssertStringContains(String: Text; SubString: Text)
    begin
        if (SubString = '') or (SubString = ' ') then
            exit;
        Assert.IsTrue(StringContains(String, SubString), StrSubstNo(StringContainsErr, String, SubString));
    end;

    local procedure AssertStringContainsDec(String: Text; Amount: Decimal)
    begin
        Assert.AreEqual(String, Format(Abs(Amount), 0, 1), StrSubstNo(StringContainsErr, String, Amount));
    end;

    local procedure VerifyFDFHeader(FDFFileHelper: Codeunit FDFFileHelper)
    var
        CompanyInformation: Record "Company Information";
        actualValue: Text;
    begin
        CompanyInformation.Get;

        actualValue := FDFFileHelper.GetValue('Text01');
        AssertStringContains(actualValue, CompanyInformation."Tax Office Name");
        AssertStringContains(actualValue, CompanyInformation."Tax Office Address");
        AssertStringContains(actualValue, CompanyInformation."Tax Office Post Code");
        AssertStringContains(actualValue, CompanyInformation."Tax Office City");

        actualValue := FDFFileHelper.GetValue('Zahl02_1');
        AssertStringContains(actualValue, CopyStr(CompanyInformation."Registration No.", 1, 3));

        actualValue := FDFFileHelper.GetValue('Zahl02_2');
        AssertStringContains(actualValue, CopyStr(CompanyInformation."Registration No.", 5, 4));

        actualValue := FDFFileHelper.GetValue('Zahl03');
        AssertStringContains(actualValue, CompanyInformation."Tax Office Number");

        actualValue := FDFFileHelper.GetValue('Text03');
        AssertStringContains(actualValue, CompanyInformation.Name);
        AssertStringContains(actualValue, CompanyInformation."Name 2");

        actualValue := FDFFileHelper.GetValue('Text05');
        AssertStringContains(actualValue, CompanyInformation.Address);
        AssertStringContains(actualValue, CompanyInformation."Address 2");

        actualValue := FDFFileHelper.GetValue('Text06');
        AssertStringContains(actualValue, CompanyInformation."House Number");

        actualValue := FDFFileHelper.GetValue('Text07');
        AssertStringContains(actualValue, CompanyInformation."Floor Number");

        actualValue := FDFFileHelper.GetValue('Text07a');
        AssertStringContains(actualValue, CompanyInformation."Room Number");

        actualValue := FDFFileHelper.GetValue('Text07b');
        AssertStringContains(actualValue, CompanyInformation."Country/Region Code");

        actualValue := FDFFileHelper.GetValue('Text07c');
        AssertStringContains(actualValue, CompanyInformation."Phone No.");

        actualValue := FDFFileHelper.GetValue('Text07d');
        AssertStringContains(actualValue, CompanyInformation."Post Code");

        actualValue := FDFFileHelper.GetValue('Text07e');
        AssertStringContains(actualValue, CompanyInformation.City);
    end;

    local procedure VerifyFDFLineValue(FDFFileHelper: Codeunit FDFFileHelper; "key": Option; expectedValue: Decimal)
    var
        actualValue: Text;
    begin
        arguments := key;
        actualValue := FDFFileHelper.GetValue(Format(arguments));
        AssertStringContainsDec(actualValue, expectedValue);
    end;

    local procedure VerifyFDFLineMinus(FDFFileHelper: Codeunit FDFFileHelper; "key": Option)
    var
        actualValue: Text;
    begin
        arguments := key;
        actualValue := FDFFileHelper.GetValue(Format(arguments));
        AssertStringContains(actualValue, '-');
    end;

    local procedure VerifyXMLHeader(LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader")
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/ERKLAERUNGS_UEBERMITTLUNG/INFO_DATEN/ART_IDENTIFIKATIONSBEGRIFF', 'FASTNR');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/ERKLAERUNGS_UEBERMITTLUNG/INFO_DATEN/IDENTIFIKATIONSBEGRIFF', '991234567');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/ERKLAERUNGS_UEBERMITTLUNG/INFO_DATEN/PAKET_NR', '999999999');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/ERKLAERUNGS_UEBERMITTLUNG/INFO_DATEN/ANZAHL_ERKLAERUNGEN', '1');

        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, '@art', 'U30');
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, 'SATZNR', '1');

        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, 'ALLGEMEINE_DATEN/ANBRINGEN', 'U30');
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, 'ALLGEMEINE_DATEN/ZRVON/@type', 'jahrmonat');
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, 'ALLGEMEINE_DATEN/ZRVON', Format(WorkDate, 0, '<Year4>-<Month,2>'));
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, 'ALLGEMEINE_DATEN/ZRBIS/@type', 'jahrmonat');
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, 'ALLGEMEINE_DATEN/ZRBIS', Format(WorkDate, 0, '<Year4>-<Month,2>'));
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, 'ALLGEMEINE_DATEN/FASTNR', '991234567');
    end;

    local procedure VerifyXMLLine(LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader"; Path: Text; Value: Decimal)
    begin
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, Path + '/@type', 'kz');
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, Path, Format(Value, 0, '<sign><integer><decimals,3><comma,.>'));
    end;

    local procedure VerifyXMLValueInErklaerung(LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader"; XPath: Text; ExpectedValue: Text)
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/ERKLAERUNGS_UEBERMITTLUNG/ERKLAERUNG/' + XPath, ExpectedValue);
    end;

    local procedure GetVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20]; DocumentType: Option; Type: Option)
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange(Type, Type);
        VATEntry.FindFirst;
        Assert.AreEqual(1, VATEntry.Count, '');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStmtATRequestPageHandler(var VATStatementAT: TestRequestPage "VAT Statement AT")
    var
        Variables: Variant;
    begin
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.ReportingType.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.StartingDate.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.EndingDate.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.IncludeVATEntries.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.PeriodSelection.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.CheckPositions.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.RoundToWholeNumbers.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.SurplusUsedToPayDues.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.AdditionalInvoicesSentViaMail.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.NumberPar6Abs1.SetValue(Variables);
        VATStatementAT.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure VATStmtATConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if Question = AdjustDatesMsg then
            Reply := true
        else
            Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure VATStmtATMessageHandler(Msg: Text[1024])
    begin
    end;

    local procedure CreateVATEntTotVATStmtLine(RowNo: Code[10]; BusPostingGroup: Code[20]; ProdPostingGroup: Code[20])
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementLine: Record "VAT Statement Line";
        LineNoToCreate: Integer;
    begin
        VATStatementTemplate.FindFirst;

        with VATStatementLine do begin
            SetRange("Statement Template Name", VATStatementTemplate.Name);
            if FindLast then
                LineNoToCreate := "Line No." + 10000
            else
                LineNoToCreate := 1;

            Init;
            Validate("Line No.", LineNoToCreate);
            Validate("Row No.", RowNo);
            Validate(Type, Type::"VAT Entry Totaling");
            Validate("Gen. Posting Type", "Gen. Posting Type"::Purchase);
            Validate("VAT Bus. Posting Group", BusPostingGroup);
            Validate("VAT Prod. Posting Group", ProdPostingGroup);
            Validate("Amount Type", "Amount Type"::Amount);
            Validate(Print, true);
            Insert(true);
        end;
    end;

    local procedure CreateRowTotVATStmtLine(RowNo: Code[10]; RowTotaling: Code[10])
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementLine: Record "VAT Statement Line";
        LineNoToCreate: Integer;
    begin
        VATStatementTemplate.FindFirst;

        with VATStatementLine do begin
            SetRange("Statement Template Name", VATStatementTemplate.Name);
            if FindLast then
                LineNoToCreate := "Line No." + 10000
            else
                LineNoToCreate := 1;

            Init;
            Validate("Line No.", LineNoToCreate);
            Validate("Row No.", RowNo);
            Validate(Type, Type::"Row Totaling");
            Validate("Row Totaling", RowTotaling);
            Validate(Print, true);
            Insert(true);
        end;
    end;
}

