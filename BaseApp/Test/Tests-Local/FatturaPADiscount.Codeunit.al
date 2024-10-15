codeunit 144204 "FatturaPA Discount"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA] [Export]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        IsInitialized: Boolean;
        FatturaPA_ElectronicFormatTxt: Label 'FatturaPA';
        UnexpectedElementValueErr: Label 'Unexpected element value for element %1. Expected element value: %2. Actual element value: %3.', Comment = '%1=XML Element Name;%2=Expected XML Element Value;%3=Actual XML element Value;';

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice] [Invoice Discount]
        // [SCENARIO 298793] Invoice Discount Amount of Sales Invoice exports to multiple nodes in FatturaPA file

        Initialize;

        // [GIVEN] Posted Sales Invoice with Quantity = 5, "Line Amount" = 100, "Invoice Discount Amount" = 20
        CustomerNo := CreateCustomer;
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod, CreatePaymentTerms, CustomerNo, SalesHeader."Document Type"::Invoice);
        UpdateDiscAmountInSalesLine(SalesLine, SalesHeader, 1 / LibraryRandom.RandIntInRange(3, 10), 0);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali has value 20
        // TFS ID: 308856
        // [THEN] Prezzo Totale node has value 100.
        // [THEN] Importo node under DettaglioLinee has value 4 (Invoice Discount Amount / Quantity)
        VerifyInvDiscAmount(ServerFileName, SalesLine.Quantity, SalesLine."Line Amount", SalesLine."Inv. Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Invoice Discount]
        // [SCENARIO 298793] Invoice Discount Amount of Sales Credit Memo exports to multiple nodes in FatturaPA file

        Initialize;

        // [GIVEN] Posted Sales Invoice with Quantity = 5, "Line Amount" = 100, "Invoice Discount Amount" = 20
        CustomerNo := CreateCustomer;
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod, CreatePaymentTerms, CustomerNo, SalesHeader."Document Type"::"Credit Memo");
        UpdateDiscAmountInSalesLine(SalesLine, SalesHeader, 1 / LibraryRandom.RandIntInRange(3, 10), 0);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesCrMemoHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali has value 20
        // TFS ID: 308856
        // [THEN] Prezzo Totale node has value 100.
        // [THEN] Importo node under DettaglioLinee has value 4 (Invoice Discount Amount / Quantity)
        VerifyInvDiscAmount(ServerFileName, SalesLine.Quantity, SalesLine."Line Amount", SalesLine."Inv. Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceWithInvoiceDiscount()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Service] [Invoice] [Invoice Discount]
        // [SCENARIO 298066] Invoice Discount Amount of Service Invoice exports to multiple nodes in FatturaPA file

        Initialize;

        // [GIVEN] Posted Service Invoice with Quantity = 5, "Line Amount" = 100, "Invoice Discount Amount" = 20
        CustomerNo := CreateCustomer;
        CreateServiceDocument(
          ServiceHeader, CustomerNo, ServiceHeader."Document Type"::Invoice);
        UpdateDiscAmountInServiceLine(ServiceLine, ServiceHeader, 1 / LibraryRandom.RandIntInRange(3, 10), 0);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali has value 20
        // TFS ID: 308856
        // [THEN] Prezzo Totale node has value 100.
        // [THEN] Importo node under DettaglioLinee has value 4 (Invoice Discount Amount / Quantity)
        VerifyInvDiscAmount(ServerFileName, ServiceLine.Quantity, ServiceLine."Line Amount", ServiceLine."Inv. Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoInvoiceDiscount()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Service] [Credit Memo] [Invoice Discount]
        // [SCENARIO 298066] Invoice Discount Amount of Service Credit Memo exports to multiple nodes in FatturaPA file

        Initialize;

        // [GIVEN] Posted Service Invoice with Quantity = 5, "Line Amount" = 100, "Invoice Discount Amount" = 20
        CustomerNo := CreateCustomer;
        CreateServiceDocument(
          ServiceHeader, CustomerNo, ServiceHeader."Document Type"::"Credit Memo");
        UpdateDiscAmountInServiceLine(ServiceLine, ServiceHeader, 1 / LibraryRandom.RandIntInRange(3, 10), 0);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceCrMemoHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali has value 20
        // TFS ID: 308856
        // [THEN] Prezzo Totale node has value 100.
        // [THEN] Importo node under DettaglioLinee has value 4 (Invoice Discount Amount / Quantity)
        VerifyInvDiscAmount(ServerFileName, ServiceLine.Quantity, ServiceLine."Line Amount", ServiceLine."Inv. Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceLineDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice] [Line Discount]
        // [SCENARIO 298793] Line Discount Percent of Sales Invoice must be exported to Percentuale node

        Initialize;

        // [GIVEN] Posted Sales Invoice with "Line Discount %" = 5
        CustomerNo := CreateCustomer;
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod, CreatePaymentTerms, CustomerNo, SalesHeader."Document Type"::Invoice);
        UpdateDiscAmountInSalesLine(SalesLine, SalesHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(ServerFileName, SalesLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoLineDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Line Discount]
        // [SCENARIO 298793] Line Discount Percent of Sales Credit Memo must be exported to Percentuale node

        Initialize;

        // [GIVEN] Posted Sales Credit Memo with "Line Discount %" = 5
        CustomerNo := CreateCustomer;
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod, CreatePaymentTerms, CustomerNo, SalesHeader."Document Type"::"Credit Memo");
        UpdateDiscAmountInSalesLine(SalesLine, SalesHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesCrMemoHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(ServerFileName, SalesLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceLineDiscount()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Service] [Invoice] [Line Discount]
        // [SCENARIO 298066] Line Discount Percent of Service Invoice must be exported to Percentuale node

        Initialize;

        // [GIVEN] Posted Service Invoice with "Line Discount %" = 5
        CustomerNo := CreateCustomer;
        CreateServiceDocument(
          ServiceHeader, CustomerNo, ServiceHeader."Document Type"::Invoice);
        UpdateDiscAmountInServiceLine(ServiceLine, ServiceHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(ServerFileName, ServiceLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoLineDiscount()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Service] [Credit Memo] [Line Discount]
        // [SCENARIO 298066] Line Discount Percent of Service Credit Memo must be exported to Percentuale node

        Initialize;

        // [GIVEN] Posted Service Credit Memo with "Line Discount %" = 5
        CustomerNo := CreateCustomer;
        CreateServiceDocument(
          ServiceHeader, CustomerNo, ServiceHeader."Document Type"::"Credit Memo");
        UpdateDiscAmountInServiceLine(ServiceLine, ServiceHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceCrMemoHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(ServerFileName, ServiceLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceBothDiscounts()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice] [Line Discount] [Invoice Discount]
        // [SCENARIO 298793] Line Discount Percent and Invoice Discount Amount of Sales Invoice must be exported to specific nodes of FatturaPA file

        Initialize;

        // [GIVEN] Posted Sales Invoice with "Line Discount %" = 5
        CustomerNo := CreateCustomer;
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod, CreatePaymentTerms, CustomerNo, SalesHeader."Document Type"::Invoice);
        UpdateDiscAmountInSalesLine(SalesLine, SalesHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(ServerFileName, SalesLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoBothDiscounts()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Line Discount] [Invoice Discount]
        // [SCENARIO 298793] Line Discount Percent and Invoice Discount Amount of Sales Credit Memo must be exported to specific nodes of FatturaPA file

        Initialize;

        // [GIVEN] Posted Sales Credit Memo with "Line Discount %" = 5
        CustomerNo := CreateCustomer;
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod, CreatePaymentTerms, CustomerNo, SalesHeader."Document Type"::"Credit Memo");
        UpdateDiscAmountInSalesLine(SalesLine, SalesHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesCrMemoHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(ServerFileName, SalesLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceBothDiscounts()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Service] [Invoice] [Line Discount] [Invoice Discount]
        // [SCENARIO 298066] Line Discount Percent and Invoice Discount Amount of Service Invoice must be exported to specific nodes of FatturaPA file

        Initialize;

        // [GIVEN] Posted Service Invoice with "Line Discount %" = 5
        CustomerNo := CreateCustomer;
        CreateServiceDocument(
          ServiceHeader, CustomerNo, ServiceHeader."Document Type"::Invoice);
        UpdateDiscAmountInServiceLine(ServiceLine, ServiceHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(ServerFileName, ServiceLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoBothDiscounts()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Service] [Credit Memo] [Line Discount] [Invoice Discount]
        // [SCENARIO 298066] Line Discount Percent and Invoice Discount Amount of Service Credit Memo must be exported to specific nodes of FatturaPA file

        Initialize;

        // [GIVEN] Posted Service Credit Memo with "Line Discount %" = 5
        CustomerNo := CreateCustomer;
        CreateServiceDocument(
          ServiceHeader, CustomerNo, ServiceHeader."Document Type"::"Credit Memo");
        UpdateDiscAmountInServiceLine(ServiceLine, ServiceHeader, 0, LibraryRandom.RandIntInRange(3, 10));
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceCrMemoHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Importo node under DatiGenerali does not exist
        // [THEN] Importo node under DettaglioLinee does not exist
        // [THEN] Percentuale node under DettaglioLinee has value 5
        VerifyLineDiscPct(ServerFileName, ServiceLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineNodesExistsWithHundredPctDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Line Discount]
        // [SCENARIO 300725] FatturaPA file has line XML nodes if Line Amount is zero because of hundred percent line discount

        Initialize;

        // [GIVEN] Posted sales invoice with "Line Amount" = 0 and "Line Discount %" = 100
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod, CreatePaymentTerms, CreateCustomer, SalesHeader."Document Type"::Invoice);
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Line Discount %", 100);
        SalesLine.Modify(true);
        SalesInvoiceHeader.SetRange("No.", LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Line node PrezzoTotale exists and the value is zero
        VerifyLineAmount(ServerFileName, 0);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;

        LibraryITLocalization.SetupFatturaPA;
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        IsInitialized := true;
    end;

    local procedure DeleteServerFile(ServerFileName: Text)
    var
        FileManagement: Codeunit "File Management";
    begin
        FileManagement.DeleteServerFile(ServerFileName);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]; DocumentType: Option)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, DocumentType, CustomerNo, '', LibraryRandom.RandIntInRange(5, 10), '', 0D);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; DocumentType: Option)
    var
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
    begin
        CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem, '');
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        exit(
          LibraryITLocalization.CreateFatturaCustomerNo(
            CopyStr(LibraryUtility.GenerateRandomCode(Customer.FieldNo("PA Code"), DATABASE::Customer), 1, 6)));
    end;

    local procedure CreatePaymentMethod(): Code[10]
    begin
        exit(LibraryITLocalization.CreateFatturaPaymentMethodCode);
    end;

    local procedure CreatePaymentTerms(): Code[10]
    begin
        exit(LibraryITLocalization.CreateFatturaPaymentTermsCode);
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocType: Option; CustomerNo: Code[20])
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocType, CustomerNo);
        ServiceHeader.Validate("Order Date", WorkDate);
        ServiceHeader.Validate("Payment Method Code", CreatePaymentMethod);
        ServiceHeader.Validate("Payment Terms Code", CreatePaymentTerms);
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceLineWithItem(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItem: Record "Service Item"; ItemNo: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure FormatAmount(Amount: Decimal): Text[250]
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,9>'))
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst;
    end;

    local procedure UpdateDiscAmountInSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; InvDiscFactor: Decimal; LineDiscPct: Decimal)
    begin
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Line Discount %", LineDiscPct);
        SalesLine.Validate("Inv. Discount Amount", SalesLine.Amount * InvDiscFactor);
        SalesLine.Modify(true);
    end;

    local procedure UpdateDiscAmountInServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; InvDiscFactor: Decimal; LineDiscPct: Decimal)
    begin
        FindServiceLine(ServiceLine, ServiceHeader);
        ServiceLine.Validate("Line Discount %", LineDiscPct);
        ServiceLine.Validate("Inv. Discount Amount", ServiceLine.Amount * InvDiscFactor);
        ServiceLine.Modify(true);
    end;

    local procedure VerifyInvDiscAmount(ServerFileName: Text[250]; Quantity: Decimal; LineAmount: Decimal; InvDiscAmount: Decimal)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento/ScontoMaggiorazione/Importo',
          FormatAmount(InvDiscAmount));
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/PrezzoTotale',
          FormatAmount(LineAmount));
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/ScontoMaggiorazione/Importo',
          FormatAmount(Round(InvDiscAmount / Quantity)));

        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyLineAmount(ServerFileName: Text[250]; LineAmount: Decimal)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/PrezzoTotale',
          FormatAmount(LineAmount));
        DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyLineDiscPct(ServerFileName: Text[250]; LineDiscPct: Decimal)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        AssertElementDoesNotExist(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento/ScontoMaggiorazione/Importo');
        AssertElementDoesNotExist(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/ScontoMaggiorazione/Importo');
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/ScontoMaggiorazione/Percentuale',
          FormatAmount(LineDiscPct));

        DeleteServerFile(ServerFileName);
    end;

    local procedure AssertCurrentElementValue(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text; ExpectedValue: Text)
    begin
        TempXMLBuffer.Reset;
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, XPath);
        Assert.AreEqual(ExpectedValue, TempXMLBuffer.Value,
          StrSubstNo(UnexpectedElementValueErr, TempXMLBuffer.GetElementName, ExpectedValue, TempXMLBuffer.Value));
    end;

    local procedure AssertElementDoesNotExist(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text)
    begin
        TempXMLBuffer.Reset;
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, XPath);
        Assert.RecordCount(TempXMLBuffer, 0);
    end;
}

