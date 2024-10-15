codeunit 142096 "Export Electr. Accounting Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Export Electr. Accounting]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        FileManagement: Codeunit "File Management";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        ExportAccounts: Codeunit "Export Accounts";
        ValueMistmatchErr: Label 'XML node attribute %1 values does not match';
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVerifyXMLSchema: Codeunit "Library - Verify XML Schema";
        ExportFileName: Text;
        Month: Integer;
        Year: Integer;
        CurrentWorkDate: Date;
        Initialized: Boolean;
        RequestType: Option AF,FC,DE,CO;
        XSDSchemaFile_ChartOfAccount: Text;
        XSDSchemaFile_Balance: Text;
        XSDSchemaFile_Transactions: Text;
        XSDSchemaFile_AuxAccount: Text;
        XSDSchemaFile_CatalogosParaEsqContE: Text;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateAccountListXSDSchema()
    begin
        // [FEATURE] [Export Electr. Accounting - Chart Of Accounts]
        // [SCENARIO 251784] Verify Export Electr. Accounting against XSD schema in case of "Export Type" = "Chart Of Accounts"
        Initialize();

        ExportAccounts.ExportChartOfAccounts(Year, Month);

        VerifyXMLAgainstXSDSchema(ExportFileName, XSDSchemaFile_ChartOfAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateAccountListXML()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Export Electr. Accounting - Chart Of Accounts]
        // [SCENARIO 251784] Export Electr. Accounting in case of "Export Type" = "Chart Of Accounts"
        Initialize();

        CreateGLAccount(GLAccount);

        ExportAccounts.ExportChartOfAccounts(Year, Month);

        InitializeXMLHelper('http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/CatalogoCuentas');

        VerifyXMLHeader('Catalogo', Month);
        VerifyAccountExistsInXML(GLAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBalanceSheetXSDSchema()
    begin
        // [FEATURE] [Export Electr. Accounting - Trial Balance]
        // [SCENARIO 251784] Verify Export Electr. Accounting against XSD schema in case of "Export Type" = "Trial Balance", "Closing Balance Sheet" = FALSE
        Initialize();

        ExportAccounts.ExportBalanceSheet(Date2DMY(WorkDate(), 3), Month, 1, Today, false);

        VerifyXMLAgainstXSDSchema(ExportFileName, XSDSchemaFile_Balance);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBalanceSheetXSDSchema_ClosingBalance()
    begin
        // [FEATURE] [Export Electr. Accounting - Trial Balance]
        // [SCENARIO 251784] Verify Export Electr. Accounting against XSD schema in case of "Export Type" = "Trial Balance", "Closing Balance Sheet" = TRUE
        Initialize();

        ExportAccounts.ExportBalanceSheet(Date2DMY(WorkDate(), 3), Month, 1, Today, true);

        VerifyXMLAgainstXSDSchema(ExportFileName, XSDSchemaFile_Balance);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBalanceSheetXML()
    var
        GLEntry: Record "G/L Entry";
        BankAccountType: Option Customer,Vendor,Company;
    begin
        // [FEATURE] [Export Electr. Accounting - Trial Balance]
        // [SCENARIO 251784] Export Electr. Accounting in case of "Export Type" = "Trial Balance", "Closing Balance Sheet" = FALSE
        Initialize();

        CreateGLEntry(GLEntry, BankAccountType::Customer);

        ExportAccounts.ExportBalanceSheet(Year, Month, 1, Today, false);

        InitializeXMLHelper('http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/BalanzaComprobacion');

        VerifyXMLHeader('Balanza', Month);
        VerifyAccountBalanceSheetInXML(GLEntry."G/L Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBalanceSheetXML_ClosingBalance()
    var
        GLEntry: Record "G/L Entry";
        BankAccountType: Option Customer,Vendor,Company;
    begin
        // [FEATURE] [Export Electr. Accounting - Trial Balance]
        // [SCENARIO 251784] Export Electr. Accounting in case of "Export Type" = "Trial Balance", "Closing Balance Sheet" = TRUE
        Initialize();

        CreateGLEntry(GLEntry, BankAccountType::Customer);

        ExportAccounts.ExportBalanceSheet(Year, Month, 1, Today, true);

        InitializeXMLHelper('http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/BalanzaComprobacion');

        VerifyXMLHeader('Balanza', 13);
        VerifyAccountBalanceSheetInXML(GLEntry."G/L Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTransactionsXSDSchema_TypeAF()
    begin
        // [FEATURE] [Export Electr. Accounting - Transactions]
        // [SCENARIO 251784] Verify Export Electr. Accounting against XSD schema in case of "Export Type" = "Transactions", "Request Type" = "AF", "Order Number" = "ABC6912345/12"
        Initialize();

        CreateTestData;

        ExportAccounts.ExportTransactions(Year, Month, RequestType::AF, GetOrderNumber, '');

        VerifyXMLAgainstXSDSchema(ExportFileName, XSDSchemaFile_Transactions);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTransactionsXSDSchema_TypeDE()
    begin
        // [FEATURE] [Export Electr. Accounting - Transactions]
        // [SCENARIO 251784] Verify Export Electr. Accounting against XSD schema in case of "Export Type" = "Transactions", "Request Type" = "DE", "Process Number" = "AB012345678901"
        Initialize();

        CreateTestData;

        ExportAccounts.ExportTransactions(Year, Month, RequestType::DE, '', GetProcessNumber);

        VerifyXMLAgainstXSDSchema(ExportFileName, XSDSchemaFile_Transactions);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTransactionsXML()
    var
        GLEntry: Record "G/L Entry";
        BankAccountType: Option Customer,Vendor,Company;
    begin
        // [FEATURE] [Export Electr. Accounting - Transactions]
        // [SCENARIO 251784] Export Electr. Accounting in case of "Export Type" = "Transactions", "Request Type" = "AF", "Order Number" = "ABC6912345/12"
        Initialize();

        // Mock of G/L Entry transaction
        CreateGLEntry(GLEntry, BankAccountType::Customer);

        // with AF
        ExportAccounts.ExportTransactions(Year, Month, RequestType::AF, GetOrderNumber, '');

        InitializeXMLHelper('http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/PolizasPeriodo');

        // Verify Header
        VerifyXMLHeader('Polizas', Month);
        VerifyTipoSolicitudAndNumOrden('Polizas', 'AF', GetOrderNumber);

        // Verify Content
        VerifyJournalTransactionsInXML(GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTransactionsXMLNationalEInvoice()
    var
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        BankAccountType: Option Customer,Vendor,Company;
    begin
        // [FEATURE] [Export Electr. Accounting - Transactions]
        // [SCENARIO 251784] Export Electr. Accounting in case of "Export Type" = "Transactions", national E-invoice
        Initialize();

        // Mock of National Sales E-Invoice
        CreateGLEntry(GLEntry, BankAccountType::Customer);
        CreateCustLedgEntry(CustLedgerEntry, GLEntry, true);
        CreatePostedSalesEInvoice(SalesInvoiceHeader, CustLedgerEntry);

        // with AF
        ExportAccounts.ExportTransactions(Year, Month, RequestType::AF, GetOrderNumber, '');

        // Verify Content
        InitializeXMLHelper('http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/PolizasPeriodo');
        VerifyNationalEInvoiceNodeInXML(GLEntry, CustLedgerEntry, '//Poliza[@NumUnIdenPol="%1"]/Transaccion[@NumCta="%2"]/CompNal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTransactionsXMLNationalReceipt()
    var
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccountType: Option Customer,Vendor,Company;
    begin
        // [FEATURE] [Export Electr. Accounting - Transactions]
        // [SCENARIO 251784] Export Electr. Accounting in case of "Export Type" = "Transactions", national receipt
        Initialize();

        // Mock of National Vendor G/L Entry
        CreateGLEntry(GLEntry, BankAccountType::Customer);
        CreateCustLedgEntry(CustLedgerEntry, GLEntry, true);

        ExportAccounts.ExportTransactions(Year, Month, RequestType::AF, GetOrderNumber, '');

        // Verify Content
        InitializeXMLHelper('http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/PolizasPeriodo');
        VerifyNationalReceiptNodeInXML(GLEntry, CustLedgerEntry, '//Poliza[@NumUnIdenPol="%1"]/Transaccion[@NumCta="%2"]/CompNalOtr');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTransactionsXMLInternationalReceipt()
    var
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccountType: Option Customer,Vendor,Company;
    begin
        // [FEATURE] [Export Electr. Accounting - Transactions]
        // [SCENARIO 251784] Export Electr. Accounting in case of "Export Type" = "Transactions", international receipt
        Initialize();

        // Mock of International Bank Transfer
        CreateGLEntry(GLEntry, BankAccountType::Vendor);
        CreateCustLedgEntry(CustLedgerEntry, GLEntry, false);

        ExportAccounts.ExportTransactions(Year, Month, RequestType::AF, GetOrderNumber, '');

        // Verify Content
        InitializeXMLHelper('http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/PolizasPeriodo');
        VerifyInternationalReceiptNodeInXML(GLEntry, CustLedgerEntry, '//Poliza[@NumUnIdenPol="%1"]/Transaccion[@NumCta="%2"]/CompExt');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTransactionsXMLBankTransferVendor()
    var
        GLEntry: Record "G/L Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccountType: Option Customer,Vendor,Company;
    begin
        // [FEATURE] [Export Electr. Accounting - Transactions]
        // [SCENARIO 251784] Export Electr. Accounting in case of "Export Type" = "Transactions", bank transfer vanedor
        Initialize();

        // Mock of International Bank Transfer
        CreateGLEntry(GLEntry, BankAccountType::Vendor);
        CreateBankAccountLedgerEntry(BankAccountLedgerEntry, GLEntry);
        CreateVendLedgEntry(VendorLedgerEntry, GLEntry, true);

        ExportAccounts.ExportTransactions(Year, Month, RequestType::AF, GetOrderNumber, '');

        // Verify Content
        InitializeXMLHelper('http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/PolizasPeriodo');
        VerifyBankTransferVendorNodeInXML(GLEntry, BankAccountLedgerEntry, VendorLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTransactionsXMLBankTransferInternal()
    var
        GLEntry: Record "G/L Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccountType: Option Customer,Vendor,Company;
    begin
        // [FEATURE] [Export Electr. Accounting - Transactions]
        // [SCENARIO 251784] Export Electr. Accounting in case of "Export Type" = "Transactions", bank transfer internal
        Initialize();

        // Mock of International Bank Transfer
        CreateGLEntry(GLEntry, BankAccountType::Company);
        CreateBankAccountLedgerEntry(BankAccountLedgerEntry, GLEntry);

        ExportAccounts.ExportTransactions(Year, Month, RequestType::AF, GetOrderNumber, '');

        // Verify Content
        InitializeXMLHelper('http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/PolizasPeriodo');
        VerifyBankTransferInternalNodeInXML(GLEntry, BankAccountLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTransactionsXMLCheckPayment()
    var
        GLEntry: Record "G/L Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccountType: Option Customer,Vendor,Company;
    begin
        // [FEATURE] [Export Electr. Accounting - Transactions]
        // [SCENARIO 251784] Export Electr. Accounting in case of "Export Type" = "Transactions", check payment
        Initialize();

        // Mock of Check Payment
        CreateGLEntry(GLEntry, BankAccountType::Vendor);
        CreateBankAccountLedgerEntry(BankAccountLedgerEntry, GLEntry);
        CreateVendLedgEntry(VendorLedgerEntry, GLEntry, true);
        CreateCheckLedgerEntry(CheckLedgerEntry, BankAccountLedgerEntry, VendorLedgerEntry."Vendor No.");

        ExportAccounts.ExportTransactions(Year, Month, RequestType::AF, GetOrderNumber, '');

        // Verify Content
        InitializeXMLHelper('http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/PolizasPeriodo');
        VerifyCheckPaymentNodeInXML(GLEntry, CheckLedgerEntry, VendorLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTransactionsXMLCashPayment()
    var
        GLEntry: Record "G/L Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccountType: Option Customer,Vendor,Company;
    begin
        // [FEATURE] [Export Electr. Accounting - Transactions]
        // [SCENARIO 251784] Export Electr. Accounting in case of "Export Type" = "Transactions", cash payment
        Initialize();

        // Mock of International Cash Payment
        CreateGLEntry(GLEntry, BankAccountType::Vendor);
        CreateVendLedgEntry(VendorLedgerEntry, GLEntry, false);

        ExportAccounts.ExportTransactions(Year, Month, RequestType::AF, GetOrderNumber, '');

        // Verify Content
        InitializeXMLHelper('http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/PolizasPeriodo');
        VerifyCashPaymentNodeInXML(GLEntry, VendorLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateAuxiliaryAccountXSDSchema_TypeFC()
    begin
        // [FEATURE] [Export Electr. Accounting - Auxiliary Accounts]
        // [SCENARIO 251784] Verify Export Electr. Accounting against XSD schema in case of "Export Type" = "Auxiliary Accounts", "Request Type" = "FC", "Order Number" = "ABC6912345/12"
        Initialize();

        ExportAccounts.ExportAuxiliaryAccounts(Date2DMY(WorkDate(), 3), Month, RequestType::FC, GetOrderNumber, '');

        VerifyXMLAgainstXSDSchema(ExportFileName, XSDSchemaFile_AuxAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateAuxiliaryAccountXSDSchema_TypeDE()
    begin
        // [FEATURE] [Export Electr. Accounting - Auxiliary Accounts]
        // [SCENARIO 251784] Verify Export Electr. Accounting against XSD schema in case of "Export Type" = "Auxiliary Accounts", "Request Type" = "DE", "Process Number" = "AB012345678901"
        Initialize();

        ExportAccounts.ExportAuxiliaryAccounts(Date2DMY(WorkDate(), 3), Month, RequestType::DE, '', GetProcessNumber);

        VerifyXMLAgainstXSDSchema(ExportFileName, XSDSchemaFile_AuxAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateAuxiliaryAccountSheetXML_TypeFC()
    var
        GLEntry: Record "G/L Entry";
        BankAccountType: Option Customer,Vendor,Company;
    begin
        // [FEATURE] [Export Electr. Accounting - Auxiliary Accounts]
        // [SCENARIO 452794] Export Electr. Accounting in case of "Export Type" = "Auxiliary Accounts", "Request Type" = "FC", "Order Number" = "ABC6912345/12"
        Initialize();

        CreateGLEntry(GLEntry, BankAccountType::Customer);

        ExportAccounts.ExportAuxiliaryAccounts(Year, Month, RequestType::FC, GetOrderNumber, '');

        InitializeXMLHelper('http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/AuxiliarCtas');

        VerifyXMLHeader('AuxiliarCtas', Month);
        VerifyTipoSolicitudAndNumOrden('AuxiliarCtas', 'FC', GetOrderNumber);
        VerifyAuxiliaryAccountInXML(GLEntry."G/L Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateAuxiliaryAccountSheetXML_TypeDE()
    var
        GLEntry: Record "G/L Entry";
        BankAccountType: Option Customer,Vendor,Company;
    begin
        // [FEATURE] [Export Electr. Accounting - Auxiliary Accounts]
        // [SCENARIO 452794] Export Electr. Accounting in case of "Export Type" = "Auxiliary Accounts", "Request Type" = "DE", "Process Number" = "AB012345678901"
        Initialize();

        CreateGLEntry(GLEntry, BankAccountType::Customer);

        ExportAccounts.ExportAuxiliaryAccounts(Year, Month, RequestType::DE, '', GetProcessNumber);

        InitializeXMLHelper('http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/AuxiliarCtas');

        VerifyXMLHeader('AuxiliarCtas', Month);
        VerifyTipoSolicitudAndNumTramite('AuxiliarCtas', 'DE', GetProcessNumber);
        VerifyAuxiliaryAccountInXML(GLEntry."G/L Account No.");
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Export Electr. Accounting Test");

        if FILE.Exists(ExportFileName) then
            FILE.Erase(ExportFileName);

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Export Electr. Accounting Test");

        SetupCompanyInfo;

        CurrentWorkDate := CalcDate('<1Y>', WorkDate());
        Year := Date2DMY(CurrentWorkDate, 3);
        Month := Date2DMY(CurrentWorkDate, 2);

        ExportFileName := GetFileName;
        ExportAccounts.InitializeRequest(ExportFileName);

        FixChartOfAccounts;
        ExportXSDShemas;

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Export Electr. Accounting Test");
    end;

    local procedure InitializeXMLHelper(NameSpace: Text)
    begin
        LibraryXPathXMLReader.Initialize(ExportFileName, NameSpace);
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(true);
    end;

    local procedure VerifyXMLHeader(RootNodeName: Text; ExpectedMonth: Integer)
    var
        CompanyInformation: Record "Company Information";
        ElementName: Text;
    begin
        CompanyInformation.Get();

        ElementName := '/' + RootNodeName;

        LibraryXPathXMLReader.VerifyAttributeValue(ElementName, 'Version', '1.3');
        LibraryXPathXMLReader.VerifyAttributeValue(ElementName, 'RFC', CompanyInformation."RFC Number");
        LibraryXPathXMLReader.VerifyAttributeValue(ElementName, 'Mes', FormatMonth(ExpectedMonth));
        LibraryXPathXMLReader.VerifyAttributeValue(ElementName, 'Anio', Format(Year));
    end;

    local procedure VerifyAccountExistsInXML(GLAccount: Record "G/L Account")
    var
        Node: DotNet XmlNode;
    begin
        FindNodeByAttributeInXML(Node, 'Catalogo', 'Ctas', 'NumCta', GLAccount."No.");

        Assert.AreEqual(GLAccount.Name, Node.Attributes.GetNamedItem('Desc').Value, StrSubstNo(ValueMistmatchErr, ''));
        Assert.AreEqual('100', Node.Attributes.GetNamedItem('CodAgrup').Value, StrSubstNo(ValueMistmatchErr, ''));         // TODO: Hardcoded for now
        Assert.AreEqual(Format(GLAccount.Indentation + 1), Node.Attributes.GetNamedItem('Nivel').Value, StrSubstNo(ValueMistmatchErr, ''));
        case GLAccount."Debit/Credit" of
            GLAccount."Debit/Credit"::Debit:
                Assert.AreEqual('D', Node.Attributes.GetNamedItem('Natur').Value, StrSubstNo(ValueMistmatchErr, ''));
            GLAccount."Debit/Credit"::Credit:
                Assert.AreEqual('A', Node.Attributes.GetNamedItem('Natur').Value, StrSubstNo(ValueMistmatchErr, ''));
        end;
    end;

    local procedure VerifyAccountBalanceSheetInXML(GLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        Node: DotNet XmlNode;
    begin
        GLAccount.Get(GLAccountNo);
        FindNodeByAttributeInXML(Node, 'Balanza', 'Ctas', 'NumCta', GLAccount."No.");

        GLAccount.CalcFields("Debit Amount", "Credit Amount");

        // Assumption: Saldo start = 0
        Assert.AreEqual(
          FormatDecimal(GLAccount."Debit Amount"), Node.Attributes.GetNamedItem('Debe').Value, StrSubstNo(ValueMistmatchErr, 'Debe'));
        Assert.AreEqual(
          FormatDecimal(GLAccount."Credit Amount"), Node.Attributes.GetNamedItem('Haber').Value, StrSubstNo(ValueMistmatchErr, 'Haber'));
        Assert.AreEqual(FormatDecimal(0), Node.Attributes.GetNamedItem('SaldoIni').Value, StrSubstNo(ValueMistmatchErr, 'SaldoIni'));
        Assert.AreEqual(
          FormatDecimal(GLAccount."Debit Amount" + GLAccount."Credit Amount"), Node.Attributes.GetNamedItem('SaldoFin').Value,
          StrSubstNo(ValueMistmatchErr, 'SaldoFin'));
    end;

    local procedure VerifyAuxiliaryAccountInXML(GLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        Node: DotNet XmlNode;
    begin
        GLAccount.Get(GLAccountNo);
        FindNodeByAttributeInXML(Node, 'AuxiliarCtas', 'Cuenta', 'NumCta', GLAccount."No.");
        FindNodeByAttributeInXML(Node, 'AuxiliarCtas', 'Cuenta', 'DesCta', GLAccount.Name);

        GLAccount.CalcFields("Debit Amount", "Credit Amount");

        // Assumption: Saldo start = 0
        Assert.AreEqual(FormatDecimal(0), Node.Attributes.GetNamedItem('SaldoIni').Value, StrSubstNo(ValueMistmatchErr, 'SaldoIni'));
        Assert.AreEqual(
          FormatDecimal(GLAccount."Debit Amount" + GLAccount."Credit Amount"), Node.Attributes.GetNamedItem('SaldoFin').Value,
          StrSubstNo(ValueMistmatchErr, 'SaldoFin'));

        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.FindFirst();
        FindNodeByAttributeInXML(Node, 'Cuenta', 'DetalleAux', 'NumUnIdenPol', Format(GLEntry."Transaction No."));
        Assert.AreEqual(
          FormatDecimal(GLEntry."Credit Amount"), Node.Attributes.GetNamedItem('Haber').Value, StrSubstNo(ValueMistmatchErr, 'Haber'));
        Assert.AreEqual(
          FormatDecimal(GLEntry."Debit Amount"), Node.Attributes.GetNamedItem('Debe').Value, StrSubstNo(ValueMistmatchErr, 'Debe'));
        Assert.AreEqual(GLEntry.Description, Node.Attributes.GetNamedItem('Concepto').Value, StrSubstNo(ValueMistmatchErr, 'Concepto'));
        Assert.AreEqual(
          Format(GLEntry."Posting Date", 0, 9), Node.Attributes.GetNamedItem('Fecha').Value, StrSubstNo(ValueMistmatchErr, 'Fecha'));
    end;

    local procedure VerifyJournalTransactionsInXML(GLEntry: Record "G/L Entry")
    var
        PolizaNode: DotNet XmlNode;
        TransactionNode: DotNet XmlNode;
    begin
        FindNodeByAttributeInXML(PolizaNode, 'Polizas', 'Poliza', 'NumUnIdenPol', Format(GLEntry."Transaction No."));

        Assert.AreEqual(
          Format(GLEntry."Posting Date", 0, 9), PolizaNode.Attributes.GetNamedItem('Fecha').Value, StrSubstNo(ValueMistmatchErr, 'Fecha'));
        Assert.AreEqual(
          GLEntry."Source Code", PolizaNode.Attributes.GetNamedItem('Concepto').Value, StrSubstNo(ValueMistmatchErr, 'Concepto'));

        FindNodeByAttributeInXML(
          TransactionNode, 'Poliza[@NumUnIdenPol="' + Format(GLEntry."Transaction No.") + '"]', 'Transaccion', 'NumCta',
          Format(GLEntry."G/L Account No."));
        VerifyTransaccionNodeInXML(TransactionNode, GLEntry);
    end;

    local procedure VerifyTransaccionNodeInXML(Node: DotNet XmlNode; GLEntry: Record "G/L Entry")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccount: Record "G/L Account";
    begin
        GeneralLedgerSetup.Get();

        Assert.AreEqual(
          Format(GLEntry.Description), Node.Attributes.GetNamedItem('Concepto').Value, StrSubstNo(ValueMistmatchErr, 'Concepto'));
        Assert.AreEqual(
          FormatDecimal(GLEntry."Debit Amount"), Node.Attributes.GetNamedItem('Debe').Value, StrSubstNo(ValueMistmatchErr, 'Debe'));
        Assert.AreEqual(
          FormatDecimal(GLEntry."Credit Amount"), Node.Attributes.GetNamedItem('Haber').Value, StrSubstNo(ValueMistmatchErr, 'Haber'));
        GLAccount.Get(GLEntry."G/L Account No.");
        Assert.AreEqual(
          GLAccount.Name, Node.Attributes.GetNamedItem('DesCta').Value, StrSubstNo(ValueMistmatchErr, 'DesCta'));
    end;

    local procedure VerifyNationalEInvoiceNodeInXML(GLEntry: Record "G/L Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; XPath: Text)
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Node: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(
          StrSubstNo(
            XPath, Format(GLEntry."Transaction No."),
            Format(GLEntry."G/L Account No.")), Node);

        CustLedgerEntry.CalcFields(Amount);
        Customer.Get(CustLedgerEntry."Customer No.");
        SalesInvoiceHeader.Get(CustLedgerEntry."Document No.");

        Assert.AreEqual(
          SalesInvoiceHeader."Fiscal Invoice Number PAC", Node.Attributes.GetNamedItem('UUID_CFDI').Value,
          StrSubstNo(ValueMistmatchErr, 'UUID_CFDI'));
        Assert.AreEqual(
          FormatDecimal(CustLedgerEntry.Amount), Node.Attributes.GetNamedItem('MontoTotal').Value,
          StrSubstNo(ValueMistmatchErr, 'MontoTotal'));
        Assert.AreEqual(Customer."RFC No.", Node.Attributes.GetNamedItem('RFC').Value, StrSubstNo(ValueMistmatchErr, 'RFC'));
    end;

    local procedure VerifyNationalReceiptNodeInXML(GLEntry: Record "G/L Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; XPath: Text)
    var
        Customer: Record Customer;
        Node: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(
          StrSubstNo(
            XPath, Format(GLEntry."Transaction No."),
            Format(GLEntry."G/L Account No.")), Node);

        CustLedgerEntry.CalcFields(Amount);
        Customer.Get(CustLedgerEntry."Customer No.");

        Assert.AreEqual(
          CustLedgerEntry."Document No.", Node.Attributes.GetNamedItem('CFD_CBB_NumFol').Value,
          StrSubstNo(ValueMistmatchErr, 'CFD_CBB_NumFol'));
        Assert.AreEqual(
          FormatDecimal(CustLedgerEntry.Amount), Node.Attributes.GetNamedItem('MontoTotal').Value,
          StrSubstNo(ValueMistmatchErr, 'MontoTotal'));
        Assert.AreEqual(Customer."RFC No.", Node.Attributes.GetNamedItem('RFC').Value, StrSubstNo(ValueMistmatchErr, 'RFC'));
    end;

    local procedure VerifyInternationalReceiptNodeInXML(GLEntry: Record "G/L Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; XPath: Text)
    var
        Customer: Record Customer;
        Node: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(
          StrSubstNo(
            XPath, Format(GLEntry."Transaction No."),
            Format(GLEntry."G/L Account No.")), Node);

        CustLedgerEntry.CalcFields(Amount);
        Customer.Get(CustLedgerEntry."Customer No.");

        Assert.AreEqual(
          CustLedgerEntry."Document No.", Node.Attributes.GetNamedItem('NumFactExt').Value, StrSubstNo(ValueMistmatchErr, 'NumFactExt'));
        Assert.AreEqual(
          FormatDecimal(CustLedgerEntry.Amount), Node.Attributes.GetNamedItem('MontoTotal').Value,
          StrSubstNo(ValueMistmatchErr, 'MontoTotal'));
        Assert.AreEqual(
          Customer."VAT Registration No.", Node.Attributes.GetNamedItem('TaxID').Value, StrSubstNo(ValueMistmatchErr, 'TaxID'));
    end;

    local procedure VerifyBankTransferVendorNodeInXML(GLEntry: Record "G/L Entry"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        Node: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(
          StrSubstNo(
            '//Poliza[@NumUnIdenPol="%1"]/Transaccion[@NumCta="%2"]/Transferencia', Format(GLEntry."Transaction No."),
            Format(GLEntry."G/L Account No.")), Node);

        Vendor.Get(VendorLedgerEntry."Vendor No.");
        BankAccount.Get(BankAccountLedgerEntry."Bank Account No.");
        VendorBankAccount.Get(Vendor."No.", VendorLedgerEntry."Recipient Bank Account");

        Assert.AreEqual(
          BankAccount."Bank Account No.", Node.Attributes.GetNamedItem('CtaOri').Value, StrSubstNo(ValueMistmatchErr, 'CtaOri'));
        Assert.AreEqual(
          BankAccount."Bank Code", Node.Attributes.GetNamedItem('BancoOriNal').Value, StrSubstNo(ValueMistmatchErr, 'BancoOriNal'));
        Assert.AreEqual(BankAccount.Name, Node.Attributes.GetNamedItem('BancoOriExt').Value, StrSubstNo(ValueMistmatchErr, 'BancoOriExt'));
        Assert.AreEqual(
          VendorBankAccount."Bank Account No.", Node.Attributes.GetNamedItem('CtaDest').Value, StrSubstNo(ValueMistmatchErr, 'CtaDest'));
        Assert.AreEqual(
          VendorBankAccount."Bank Code", Node.Attributes.GetNamedItem('BancoDestNal').Value, StrSubstNo(ValueMistmatchErr, 'BancoDestNal'));
        Assert.AreEqual(
          VendorBankAccount.Name, Node.Attributes.GetNamedItem('BancoDestExt').Value, StrSubstNo(ValueMistmatchErr, 'BancoDestExt'));
        Assert.AreEqual(
          Format(BankAccountLedgerEntry."Posting Date", 0, 9), Node.Attributes.GetNamedItem('Fecha').Value,
          StrSubstNo(ValueMistmatchErr, 'Fecha'));
        Assert.AreEqual(Vendor.Name, Node.Attributes.GetNamedItem('Benef').Value, StrSubstNo(ValueMistmatchErr, 'Benef'));
        Assert.AreEqual(
          FormatDecimal(BankAccountLedgerEntry."Credit Amount"), Node.Attributes.GetNamedItem('Monto').Value,
          StrSubstNo(ValueMistmatchErr, 'Monto'));
        Assert.AreEqual(Vendor."RFC No.", Node.Attributes.GetNamedItem('RFC').Value, StrSubstNo(ValueMistmatchErr, 'RFC'));
    end;

    local procedure VerifyBankTransferInternalNodeInXML(GLEntry: Record "G/L Entry"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    var
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
        RecipientBankAccount: Record "Bank Account";
        Node: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(
          StrSubstNo(
            '//Poliza[@NumUnIdenPol="%1"]/Transaccion[@NumCta="%2"]/Transferencia', Format(GLEntry."Transaction No."),
            Format(GLEntry."G/L Account No.")), Node);

        BankAccount.Get(BankAccountLedgerEntry."Bank Account No.");
        RecipientBankAccount.Get(GLEntry."Bal. Account No.");
        CompanyInformation.Get();

        Assert.AreEqual(
          BankAccount."Bank Account No.", Node.Attributes.GetNamedItem('CtaOri').Value, StrSubstNo(ValueMistmatchErr, 'CtaOri'));
        Assert.AreEqual(
          BankAccount."Bank Code", Node.Attributes.GetNamedItem('BancoOriNal').Value, StrSubstNo(ValueMistmatchErr, 'BancoOriNal'));
        Assert.AreEqual(BankAccount.Name, Node.Attributes.GetNamedItem('BancoOriExt').Value, StrSubstNo(ValueMistmatchErr, 'BancoOriExt'));
        Assert.AreEqual(
          RecipientBankAccount."Bank Account No.", Node.Attributes.GetNamedItem('CtaDest').Value, StrSubstNo(ValueMistmatchErr, 'CtaDest'));
        Assert.AreEqual(
          RecipientBankAccount."Bank Code", Node.Attributes.GetNamedItem('BancoDestNal').Value, StrSubstNo(ValueMistmatchErr, 'BancoDestNal'));
        Assert.AreEqual(
          RecipientBankAccount.Name, Node.Attributes.GetNamedItem('BancoDestExt').Value, StrSubstNo(ValueMistmatchErr, 'BancoDestExt'));
        Assert.AreEqual(
          Format(BankAccountLedgerEntry."Posting Date", 0, 9), Node.Attributes.GetNamedItem('Fecha').Value,
          StrSubstNo(ValueMistmatchErr, 'Fecha'));
        Assert.AreEqual(CompanyInformation.Name, Node.Attributes.GetNamedItem('Benef').Value, StrSubstNo(ValueMistmatchErr, 'Benef'));
        Assert.AreEqual(
          FormatDecimal(BankAccountLedgerEntry."Credit Amount"), Node.Attributes.GetNamedItem('Monto').Value,
          StrSubstNo(ValueMistmatchErr, 'Monto'));
        Assert.AreEqual(CompanyInformation."RFC Number", Node.Attributes.GetNamedItem('RFC').Value, StrSubstNo(ValueMistmatchErr, 'RFC'));
    end;

    local procedure VerifyCheckPaymentNodeInXML(GLEntry: Record "G/L Entry"; CheckLedgerEntry: Record "Check Ledger Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        Node: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(
          StrSubstNo(
            '//Poliza[@NumUnIdenPol="%1"]/Transaccion[@NumCta="%2"]/Cheque', Format(GLEntry."Transaction No."),
            Format(GLEntry."G/L Account No.")), Node);

        Vendor.Get(VendorLedgerEntry."Vendor No.");
        BankAccount.Get(CheckLedgerEntry."Bank Account No.");

        Assert.AreEqual(CheckLedgerEntry."Check No.", Node.Attributes.GetNamedItem('Num').Value, StrSubstNo(ValueMistmatchErr, 'Num'));
        Assert.AreEqual(
          BankAccount."Bank Code", Node.Attributes.GetNamedItem('BanEmisNal').Value, StrSubstNo(ValueMistmatchErr, 'BanEmisNal'));
        Assert.AreEqual(BankAccount.Name, Node.Attributes.GetNamedItem('BanEmisExt').Value, StrSubstNo(ValueMistmatchErr, 'BanEmisExt'));
        Assert.AreEqual(
          BankAccount."Bank Account No.", Node.Attributes.GetNamedItem('CtaOri').Value, StrSubstNo(ValueMistmatchErr, 'CtaOri'));
        Assert.AreEqual(
          Format(CheckLedgerEntry."Check Date", 0, 9), Node.Attributes.GetNamedItem('Fecha').Value, StrSubstNo(ValueMistmatchErr, 'Fecha'));
        Assert.AreEqual(Vendor.Name, Node.Attributes.GetNamedItem('Benef').Value, StrSubstNo(ValueMistmatchErr, 'Benef'));

        Assert.AreEqual(
          FormatDecimal(CheckLedgerEntry.Amount), Node.Attributes.GetNamedItem('Monto').Value, StrSubstNo(ValueMistmatchErr, 'Monto'));
        Assert.AreEqual(Vendor."RFC No.", Node.Attributes.GetNamedItem('RFC').Value, StrSubstNo(ValueMistmatchErr, 'RFC'));
    end;

    local procedure VerifyCashPaymentNodeInXML(GLEntry: Record "G/L Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        Node: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(
          StrSubstNo(
            '//Poliza[@NumUnIdenPol="%1"]/Transaccion[@NumCta="%2"]/OtrMetodoPago', Format(GLEntry."Transaction No."),
            Format(GLEntry."G/L Account No.")), Node);

        VendorLedgerEntry.CalcFields(Amount);
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        PaymentMethod.Get(VendorLedgerEntry."Payment Method Code");

        Assert.AreEqual(
          PaymentMethod."SAT Payment Method Code", Node.Attributes.GetNamedItem('MetPagoPol').Value,
          StrSubstNo(ValueMistmatchErr, 'MetPagoPol'));
        Assert.AreEqual(
          Format(VendorLedgerEntry."Posting Date", 0, 9), Node.Attributes.GetNamedItem('Fecha').Value, StrSubstNo(ValueMistmatchErr, 'Fecha'));
        Assert.AreEqual(Vendor.Name, Node.Attributes.GetNamedItem('Benef').Value, StrSubstNo(ValueMistmatchErr, 'Benef'));
        Assert.AreEqual(
          FormatDecimal(VendorLedgerEntry.Amount), Node.Attributes.GetNamedItem('Monto').Value, StrSubstNo(ValueMistmatchErr, 'Monto'));
        Assert.AreEqual(Vendor."RFC No.", Node.Attributes.GetNamedItem('RFC').Value, StrSubstNo(ValueMistmatchErr, 'RFC'));
    end;

    local procedure VerifyXMLAgainstXSDSchema(XMLFileName: Text; XSDFileName: Text)
    var
        Message: Text;
    begin
        LibraryVerifyXMLSchema.SetAdditionalSchemaPath(XSDSchemaFile_CatalogosParaEsqContE);
        Assert.IsTrue(LibraryVerifyXMLSchema.VerifyXMLAgainstSchema(XMLFileName, XSDFileName, Message), Message);
    end;

    local procedure VerifyTipoSolicitudAndNumOrden(NodeName: Text; TipoSolicitud: Text; NumOrden: Text)
    begin
        LibraryXPathXMLReader.VerifyAttributeValue('/' + NodeName, 'TipoSolicitud', TipoSolicitud);
        LibraryXPathXMLReader.VerifyAttributeValue('/' + NodeName, 'NumOrden', NumOrden);
    end;

    local procedure VerifyTipoSolicitudAndNumTramite(NodeName: Text; TipoSolicitud: Text; NumTramite: Text)
    begin
        LibraryXPathXMLReader.VerifyAttributeValue('/' + NodeName, 'TipoSolicitud', TipoSolicitud);
        LibraryXPathXMLReader.VerifyAttributeValue('/' + NodeName, 'NumTramite', NumTramite);
    end;

    local procedure CreateTestData()
    var
        GLEntry: Record "G/L Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
        InvoiceCustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        BankAccountType: Option Customer,Vendor,Company;
    begin
        // Mock of National Vendor Payment
        CreateGLEntry(GLEntry, BankAccountType::Vendor);
        CreateBankAccountLedgerEntry(BankAccountLedgerEntry, GLEntry);
        CreateVendLedgEntry(VendorLedgerEntry, GLEntry, true);
        CreateCheckLedgerEntry(CheckLedgerEntry, BankAccountLedgerEntry, VendorLedgerEntry."Vendor No.");

        // Mock of National Sales Invoice
        CreateGLEntry(GLEntry, BankAccountType::Customer);
        CreateCustLedgEntry(InvoiceCustLedgerEntry, GLEntry, true);
        CreatePostedSalesEInvoice(SalesInvoiceHeader, InvoiceCustLedgerEntry);

        // Mock of International Bank Transfer
        CreateGLEntry(GLEntry, BankAccountType::Vendor);
        CreateBankAccountLedgerEntry(BankAccountLedgerEntry, GLEntry);
        CreateVendLedgEntry(VendorLedgerEntry, GLEntry, false);

        // Mock of International Cash Payment
        CreateGLEntry(GLEntry, BankAccountType::Vendor);
        CreateVendLedgEntry(VendorLedgerEntry, GLEntry, false);
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry"; BankAccountType: Option Customer,Vendor,Company)
    var
        GLEntryLast: Record "G/L Entry";
        GLAccount: Record "G/L Account";
        SourceCodeSetup: Record "Source Code Setup";
        RecipientBankAccount: Record "Bank Account";
    begin
        CreateGLAccount(GLAccount);
        GLEntryLast.FindLast();
        SourceCodeSetup.Get();

        with GLEntry do begin
            Init();
            "Entry No." := GLEntryLast."Entry No." + 1;
            "Transaction No." := GLEntryLast."Transaction No." + 1;
            "Document No." := Format(LibraryRandom.RandInt(10000));
            "Posting Date" := CurrentWorkDate;
            Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Description)), 1, MaxStrLen(Description));

            "G/L Account No." := GLAccount."No.";

            case BankAccountType of
                BankAccountType::Customer:
                    begin
                        "Source Code" := SourceCodeSetup.Sales;
                        "Debit Amount" := LibraryRandom.RandDec(1000, 2);
                        Amount := "Debit Amount";
                        "Bal. Account Type" := "Bal. Account Type"::Customer;
                    end;
                BankAccountType::Vendor:
                    begin
                        "Source Code" := SourceCodeSetup.Purchases;
                        "Credit Amount" := LibraryRandom.RandDec(1000, 2);
                        Amount := -"Credit Amount";
                        "Bal. Account Type" := "Bal. Account Type"::Vendor;
                        "Document Type" := "Document Type"::Payment;
                    end;
                BankAccountType::Company:
                    begin
                        "Source Code" := SourceCodeSetup."General Journal";
                        "Credit Amount" := LibraryRandom.RandDec(1000, 2);
                        Amount := -"Credit Amount";
                        "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
                        CreateBankAccount(RecipientBankAccount, "G/L Account No.");
                        "Bal. Account No." := RecipientBankAccount."No.";
                    end;
            end;
            Insert();
        end;
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        with GLAccount do begin
            "Account Type" := "Account Type"::Posting;
            "Debit/Credit" := LibraryRandom.RandIntInRange(1, 2);
            "SAT Account Code" := '100';
            Modify();
        end;
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account"; GLBankAccountNo: Code[20])
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccountPostingGroup(BankAccountPostingGroup);

        BankAccountPostingGroup.Init();
        BankAccountPostingGroup.Code :=
          LibraryUtility.GenerateRandomCode(BankAccountPostingGroup.FieldNo(Code), DATABASE::"Bank Account Posting Group");
        BankAccountPostingGroup."G/L Account No." := GLBankAccountNo;
        BankAccountPostingGroup.Insert(true);

        BankAccount."Bank Acc. Posting Group" := BankAccountPostingGroup.Code;
        BankAccount."Bank Code" := '006';
        BankAccount."Bank Account No." := LibraryUtility.GenerateGUID();
        BankAccount.Modify();
    end;

    local procedure CreateCheckLedgerEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; VendorNo: Code[20])
    begin
        with CheckLedgerEntry do begin
            Init();
            "Bank Account No." := BankAccountLedgerEntry."Bank Account No.";
            "Entry No." := BankAccountLedgerEntry."Entry No.";
            "Bank Account Ledger Entry No." := BankAccountLedgerEntry."Entry No.";
            "Check No." := LibraryUtility.GenerateRandomCode(FieldNo("Check No."), DATABASE::"Check Ledger Entry");
            "Check Date" := CurrentWorkDate;
            Amount := BankAccountLedgerEntry."Credit Amount";
            "Bal. Account Type" := "Bal. Account Type"::Vendor;
            "Bal. Account No." := VendorNo;
            Insert();
        end;
    end;

    local procedure CreateBankAccountLedgerEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; GLEntry: Record "G/L Entry")
    var
        BankAccount: Record "Bank Account";
    begin
        CreateBankAccount(BankAccount, GLEntry."G/L Account No.");

        with BankAccountLedgerEntry do begin
            Init();
            "Entry No." := GLEntry."Entry No.";
            "Transaction No." := GLEntry."Transaction No.";
            "Posting Date" := CurrentWorkDate;
            "Bank Acc. Posting Group" := BankAccount."Bank Acc. Posting Group";
            "Bal. Account Type" := GLEntry."Bal. Account Type";
            "Bal. Account No." := GLEntry."Bal. Account No.";
            "Bank Account No." := BankAccount."No.";
            "Document Date" := CurrentWorkDate;
            "Credit Amount" := -GLEntry.Amount;
            Insert();
        end;
    end;

    local procedure CreateVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GLEntry: Record "G/L Entry"; IsNational: Boolean)
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        CreateVendorWithBankAccount(Vendor, VendorBankAccount, GLEntry."G/L Account No.", IsNational);

        with VendorLedgerEntry do begin
            FindLast();
            CreateDetailedVendorLedgerEntry("Entry No." + 1);
            Init();
            "Entry No." += 1;
            "Vendor No." := Vendor."No.";
            "Posting Date" := CurrentWorkDate;
            "Vendor Posting Group" := Vendor."Vendor Posting Group";
            "Recipient Bank Account" := VendorBankAccount.Code;
            "Document No." := Format(LibraryRandom.RandInt(10000));
            "Transaction No." := GLEntry."Transaction No.";
            "Payment Method Code" := CreatePaymentMethod;
            Insert();
        end;
    end;

    local procedure CreateCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; GLEntry: Record "G/L Entry"; IsNational: Boolean)
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CreateCustomerWithBankAccount(Customer, GLEntry."G/L Account No.", CustomerBankAccount, IsNational);

        with CustLedgerEntry do begin
            FindLast();
            CreateDetailedCustLedgerEntry("Entry No." + 1);
            Init();
            "Entry No." += 1;
            "Customer No." := Customer."No.";
            "Posting Date" := CurrentWorkDate;
            "Customer Posting Group" := Customer."Customer Posting Group";
            "Recipient Bank Account" := CustomerBankAccount.Code;
            "Document No." := Format(LibraryRandom.RandInt(10000));
            "Transaction No." := GLEntry."Transaction No.";
            Insert();
        end;
    end;

    local procedure CreateDetailedCustLedgerEntry(CustLedgerEntryNo: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        with DetailedCustLedgEntry do begin
            FindLast();
            Init();
            "Entry No." += 1;
            "Cust. Ledger Entry No." := CustLedgerEntryNo;
            "Entry Type" := "Entry Type"::"Initial Entry";
            "Posting Date" := CurrentWorkDate;
            Amount := LibraryRandom.RandDec(1000, 2);
            "Ledger Entry Amount" := true;
            Insert();
        end;
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        with DetailedVendorLedgEntry do begin
            FindLast();
            Init();
            "Entry No." += 1;
            "Vendor Ledger Entry No." := VendorLedgerEntryNo;
            "Entry Type" := "Entry Type"::"Initial Entry";
            "Posting Date" := CurrentWorkDate;
            Amount := LibraryRandom.RandDec(1000, 2);
            "Ledger Entry Amount" := true;
            Insert();
        end;
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account"; PayablesAccount: Code[20]; IsNational: Boolean)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LibraryPurchase.CreateVendorWithVATRegNo(Vendor);

        VendorPostingGroup.Init();
        VendorPostingGroup.Code :=
          LibraryUtility.GenerateRandomCode(VendorPostingGroup.FieldNo(Code), DATABASE::"Vendor Posting Group");
        VendorPostingGroup."Payables Account" := PayablesAccount;
        VendorPostingGroup.Insert(true);

        Vendor."Vendor Posting Group" := VendorPostingGroup.Code;
        Vendor."RFC No." := 'VED920404DA3';
        if IsNational then
            Vendor."Country/Region Code" := '';
        Vendor.Modify();

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");

        VendorBankAccount."Bank Code" := '009';
        VendorBankAccount."Bank Account No." := LibraryUtility.GenerateGUID();
        VendorBankAccount.Name :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(VendorBankAccount.Name)), 1, MaxStrLen(VendorBankAccount.Name));

        VendorBankAccount.Modify();
    end;

    local procedure CreateCustomerWithBankAccount(var Customer: Record Customer; ReceivablesAccount: Code[20]; var CustomerBankAccount: Record "Customer Bank Account"; IsNational: Boolean)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibrarySales.CreateCustomerWithVATRegNo(Customer);

        CustomerPostingGroup.Init();
        CustomerPostingGroup.Code :=
          LibraryUtility.GenerateRandomCode(CustomerPostingGroup.FieldNo(Code), DATABASE::"Customer Posting Group");
        CustomerPostingGroup."Receivables Account" := ReceivablesAccount;
        CustomerPostingGroup.Insert(true);

        Customer."Customer Posting Group" := CustomerPostingGroup.Code;
        Customer."RFC No." := 'CUS920404DA3';
        if IsNational then
            Customer."Country/Region Code" := '';
        Customer.Modify();

        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");

        CustomerBankAccount."Bank Code" := '012';
        CustomerBankAccount."Bank Account No." := LibraryUtility.GenerateGUID();
        CustomerBankAccount.Modify();
    end;

    local procedure CreatePaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod."SAT Payment Method Code" := '03';
        PaymentMethod.Modify();
        exit(PaymentMethod.Code);
    end;

    local procedure CreatePostedSalesEInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        with SalesInvoiceHeader do begin
            Init();
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Sales Invoice Header");
            "Fiscal Invoice Number PAC" := DelChr(Format(CreateGuid()), '=', '{}');
            Insert();
        end;

        SourceCodeSetup.Get();
        with CustLedgerEntry do begin
            "Document Type" := "Document Type"::Invoice;
            "Document No." := SalesInvoiceHeader."No.";
            "Source Code" := SourceCodeSetup.Sales;
            Modify();
        end
    end;

    local procedure FixChartOfAccounts()
    var
        GLAccount: Record "G/L Account";
    begin
        with GLAccount do begin
            if FindSet() then
                repeat
                    CalcFields("Debit Amount", "Credit Amount");
                    if "Debit/Credit" = "Debit/Credit"::Both then begin
                        if "Debit Amount" <> 0 then
                            "Debit/Credit" := "Debit/Credit"::Debit
                        else
                            "Debit/Credit" := "Debit/Credit"::Credit
                    end;

                    "SAT Account Code" := '100';
                    Modify();
                until Next = 0;
        end;
    end;

    local procedure SetupCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
    begin
        with CompanyInformation do begin
            Get();
            "RFC Number" := 'SWC920404DA3';  // Set number, otherwise will run into all kind of errors
            Modify(true);
        end;
    end;

    local procedure FindNodeByAttributeInXML(var Node: DotNet XmlNode; ParentNodeName: Text; NodeName: Text; AttributeName: Text; AttributeValue: Text)
    begin
        LibraryXPathXMLReader.GetNodeByXPath(
          '//' + ParentNodeName + '/' + NodeName + '[@' + AttributeName + '="' + AttributeValue + '"]', Node);
    end;

    local procedure FormatDecimal(Amount: Decimal): Text
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,9>'));
    end;

    local procedure FormatMonth(Month: Integer): Text
    begin
        if Month in [1 .. 9] then
            exit('0' + Format(Month));
        exit(Format(Month));
    end;

    local procedure GetFileName(): Text
    begin
        exit(FileManagement.ServerTempFileName('XML'));
    end;

    local procedure GetOrderNumber(): Text[13]
    begin
        exit('ABC6912345/12');
    end;

    local procedure GetProcessNumber(): Text[14]
    begin
        exit('AB012345678901');
    end;

    local procedure ExportXSDShemas()
    begin
        XSDSchemaFile_CatalogosParaEsqContE :=
          LibraryUtility.GetInetRoot + '..\' + '\GDL\NA\App\Test\XMLSchemas\CatalogosParaEsqContE.xsd';
        XSDSchemaFile_ChartOfAccount := LibraryUtility.GetInetRoot + '..\' + '\GDL\NA\App\Test\XMLSchemas\CatalogoCuentas_1_3.xsd';
        XSDSchemaFile_Balance := LibraryUtility.GetInetRoot + '..\' + '\GDL\NA\App\Test\XMLSchemas\BalanzaComprobacion_1_3.xsd';
        XSDSchemaFile_Transactions := LibraryUtility.GetInetRoot + '..\' + '\GDL\NA\App\Test\XMLSchemas\PolizasPeriodo_1_3.xsd';
        XSDSchemaFile_AuxAccount := LibraryUtility.GetInetRoot + '..\' + '\GDL\NA\App\Test\XMLSchemas\AuxiliarCtas_1_3.xsd';
    end;
}

