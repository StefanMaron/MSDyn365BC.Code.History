codeunit 147528 "SII Corrective Documents"
{
    // // [FEATURE] [SII]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        SIIXMLCreator: Codeunit "SII XML Creator";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySII: Codeunit "Library - SII";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        XPathPurchFacturaRecibidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/';
        XPathPurchBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/sii:DesgloseFactura/sii:DesgloseIVA/sii:DetalleIVA/';
        XPathSalesBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseFactura/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/';
        XPathSalesFacturaExpedidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/';
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        CorrectedInvoiceNoMustHaveValueErr: Label 'Corrected Invoice No. must have a value in Sales Header';

    [Test]
    [Scope('OnPrem')]
    procedure NegativeF1SalesInvoiceHaveNegativeAmountsAndDoesNotHaveCreditMemoXMLNodes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 231007] Negative Sales Invoice with type "F1 Invoice" have negative amounts and does not have XML nodes of Credit Memo in SII File

        Initialize();

        // [GIVEN] Sales Credit Memo with "Cr. Memo Type" = "F1 Invoice" (negative invoice)
        PostSalesCrMemoWithFType(CustLedgerEntry, SalesLine, SalesHeader."Cr. Memo Type"::"F1 Invoice");

        // [WHEN] Generatel XML for Posted Sales Credit Memo
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] No elements of Credit Memo in exported SII file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:TipoRectificativa');
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:ImporteTotal');

        // [THEN] TipoFactura is "F1" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'F1');

        // [THEN] BaseImponible and CuotaRepercutida have negative values in exported SII file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-SalesLine.Amount));
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, 'sii:CuotaRepercutida',
          SIIXMLCreator.FormatNumber(-(SalesLine."Amount Including VAT" - SalesLine.Amount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeF1PurchInvoiceHaveNegativeAmountsAndDoesNotHaveCreditMemoXMLNodes()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 231007] Negative Purchase Invoice with type "F1 Invoice" have negative amounts and does not have XML nodes of Credit Memo in SII File

        Initialize();

        // [GIVEN] Purchase Credit Memo with "Cr. Memo Type" = "F1 Invoice" (negative invoice)
        PostPurchCrMemoWithFType(VendorLedgerEntry, PurchaseLine, PurchaseHeader."Cr. Memo Type"::"F1 Invoice");

        // [WHEN] Generatel XML for Posted Purchase Credit Memo
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] No elements of Credit Memo in exported SII file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:TipoRectificativa');
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:ImporteTotal');

        // [THEN] TipoFactura is "F1" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'F1');

        // [THEN] BaseImponible and CuotaRepercutida have negative values in exported SII file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-PurchaseLine.Amount));
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, 'sii:CuotaSoportada',
          SIIXMLCreator.FormatNumber(-(PurchaseLine."Amount Including VAT" - PurchaseLine.Amount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeF1ServiceInvoiceHaveNegativeAmountsAndDoesNotHaveCreditMemoXMLNodes()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 231007] Negative Service Invoice with type "F1 Invoice" have negative amounts and does not have XML nodes of Credit Memo in SII File

        Initialize();

        // [GIVEN] Service Credit Memo with "Cr. Memo Type" = "F1 Invoice" (negative invoice)
        PostServiceCrMemoWithFType(CustLedgerEntry, ServiceLine, ServiceHeader."Cr. Memo Type"::"F1 Invoice");

        // [WHEN] Generatel XML for Posted Service Credit Memo
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] No elements of Credit Memo in exported SII file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:TipoRectificativa');
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:ImporteTotal');

        // [THEN] TipoFactura is "F1" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'F1');

        // [THEN] BaseImponible and CuotaRepercutida have negative values in exported SII file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-ServiceLine.Amount));
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, 'sii:CuotaRepercutida',
          SIIXMLCreator.FormatNumber(-(ServiceLine."Amount Including VAT" - ServiceLine.Amount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeF2SalesInvoiceHaveNegativeAmountsAndDoesNotHaveCreditMemoXMLNodes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 231007] Negative Sales Invoice with type "F2 Simplified Invoice" have negative amounts and does not have XML nodes of Credit Memo in SII File

        Initialize();

        // [GIVEN] Sales Credit Memo with "Cr. Memo Type" = "F2 Simplified Invoice" (negative invoice)
        PostSalesCrMemoWithFType(CustLedgerEntry, SalesLine, SalesHeader."Cr. Memo Type"::"F2 Simplified Invoice");

        // [WHEN] Generatel XML for Posted Sales Credit Memo
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] No elements of Credit Memo in exported SII file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:TipoRectificativa');

        // [THEN] ImporteTotal exists in exported SII file since "Cr. Memo Type" = "F2 Simplified Invoice"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:ImporteTotal');

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'F2');

        // [THEN] BaseImponible and CuotaRepercutida have negative values in exported SII file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-SalesLine.Amount));
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, 'sii:CuotaRepercutida',
          SIIXMLCreator.FormatNumber(-(SalesLine."Amount Including VAT" - SalesLine.Amount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeF2PurchInvoiceHaveNegativeAmountsAndDoesNotHaveCreditMemoXMLNodes()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 231007] Negative Purchase Invoice with type "F2 Simplified Invoice" have negative amounts and does not have XML nodes of Credit Memo in SII File

        Initialize();

        // [GIVEN] Purchase Credit Memo with "Cr. Memo Type" = "F2 Simplified Invoice" (negative invoice)
        PostPurchCrMemoWithFType(VendorLedgerEntry, PurchaseLine, PurchaseHeader."Cr. Memo Type"::"F2 Simplified Invoice");

        // [WHEN] Generatel XML for Posted Purchase Credit Memo
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] No elements of Credit Memo in exported SII file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:TipoRectificativa');

        // [THEN] ImporteTotal exists in exported SII file since "Cr. Memo Type" = "F2 Simplified Invoice"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:ImporteTotal');

        // [THEN] TipoFactura is "F1" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'F2');

        // [THEN] BaseImponible and CuotaRepercutida have negative values in exported SII file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-PurchaseLine.Amount));
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, 'sii:CuotaSoportada',
          SIIXMLCreator.FormatNumber(-(PurchaseLine."Amount Including VAT" - PurchaseLine.Amount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeF2ServiceInvoiceHaveNegativeAmountsAndDoesNotHaveCreditMemoXMLNodes()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 231007] Negative Service Invoice with type "F2 Simplified Invoice" have negative amounts and does not have XML nodes of Credit Memo in SII File

        Initialize();

        // [GIVEN] Service Credit Memo with "Cr. Memo Type" = "F2 Simplified Invoice" (negative invoice)
        PostServiceCrMemoWithFType(CustLedgerEntry, ServiceLine, ServiceHeader."Cr. Memo Type"::"F2 Simplified Invoice");

        // [WHEN] Generatel XML for Posted Service Credit Memo
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] No elements of Credit Memo in exported SII file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:TipoRectificativa');

        // [THEN] ImporteTotal exists in exported SII file since "Cr. Memo Type" = "F2 Simplified Invoice"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:ImporteTotal');

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'F2');

        // [THEN] BaseImponible and CuotaRepercutida have negative values in exported SII file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-ServiceLine.Amount));
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, 'sii:CuotaRepercutida',
          SIIXMLCreator.FormatNumber(-(ServiceLine."Amount Including VAT" - ServiceLine.Amount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CuotaDeducibleDeductNegativeLineForPurchInvoice()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        TotalVATAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 251317] CuotaDeducible node has value deducting negative line in Purchase Invoice

        Initialize();

        // [GIVEN] Posted Purchase Invoice with two lines. First line has "VAT Amount" = 100, second line is negative and has "VAT Amount" = -40
        PostPurchInvWithMultipleLinesOneNegative(TotalVATAmount, VendorLedgerEntry);

        // [WHEN] Generatel XML for Posted Purchase Invoice
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] Cuota Deducible has value 60 in XML file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(TotalVATAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectiveSalesInvoiceWithR1Type()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 383654] Stan can send sales invoice with "Invoice Type" = "R1" to the SII in order to reflect the corrective invoice

        Initialize();

        // [GIVEN] "Include Importe Total" is enabled in the SII Setup
        SetIncludeImporteTotalInSIISetup();

        // [GIVEN] Sales invoice with "Invoice Type" = "R1"
        PostSalesInvoiceWithRType(CustLedgerEntry, SalesLine, SalesHeader."Invoice Type"::"R1 Corrected Invoice");

        // [WHEN] Generatel XML for posted document
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] TipoFactura is "R1" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'R1');

        // [THEN] TipoFactura is "R1" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoRectificativa', 'S');

        // [THEN] ImporteTotal is positive in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(-SalesLine."Amount Including VAT"));

        // [THEN] BaseRectificada is "0" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ImporteRectificacion/sii:BaseRectificada', SIIXMLCreator.FormatNumber(0));

        // [THEN] CuotaRectificada is "0" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ImporteRectificacion/sii:CuotaRectificada', SIIXMLCreator.FormatNumber(0));

        // [THEN] BaseImponible and CuotaRepercutida have positive values in exported SII file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(SalesLine.Amount));
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, 'sii:CuotaRepercutida',
          SIIXMLCreator.FormatNumber((SalesLine."Amount Including VAT" - SalesLine.Amount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectivePurchInvoiceWithR1Type()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 383654] Stan can send purchase invoice with "Invoice Type" = "R1" to the SII in order to reflect the corrective invoice

        Initialize();

        // [GIVEN] "Include Importe Total" is enabled in the SII Setup
        SetIncludeImporteTotalInSIISetup();

        // [GIVEN] Purchase invoice with "Invoice Type" = "R1"
        PostPurchInvWithRType(VendorLedgerEntry, PurchaseLine, PurchaseHeader."Invoice Type"::"R1 Corrected Invoice");

        // [WHEN] Generatel XML for posted document
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] TipoFactura is "R1" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'R1');

        // [THEN] TipoFactura is "R1" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoRectificativa', 'S');

        // [THEN] ImporteTotal is positive in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(PurchaseLine."Amount Including VAT"));

        // [THEN] BaseRectificada is "0" in exported SII File`
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ImporteRectificacion/sii:BaseRectificada', SIIXMLCreator.FormatNumber(0));

        // [THEN] CuotaRectificada is "0" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ImporteRectificacion/sii:CuotaRectificada', SIIXMLCreator.FormatNumber(0));

        // [THEN] BaseImponible and CuotaRepercutida have positive values in exported SII file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(PurchaseLine.Amount));
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, 'sii:CuotaSoportada',
          SIIXMLCreator.FormatNumber((PurchaseLine."Amount Including VAT" - PurchaseLine.Amount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToPostRemovalSalesCreditMemoWithCorrectedInvoiceNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 454286] Stan cannot post the removal sales credit memo with blank "Corrected Invoice No."

        Initialize();
        // [GIVEN] Sales credit memo with "Correction Type" = Removal and "Corrected Invoice No." = blank
        CreateSalesDoc(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", "SII Sales Credit Memo Type"::"R1 Corrected Invoice",
          "SII Purch. Invoice Type"::"F1 Invoice", SalesHeader."Correction Type"::Removal);
        SalesHeader."Corrected Invoice No." := '';
        SalesHeader.Modify();

        // [WHEN] Post sales credit memo
        asserterror CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);
        // [THEN] A "Corrected Invoice No. must have a value in Sales Header" error message is thrown
        Assert.ExpectedError(CorrectedInvoiceNoMustHaveValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToPostReplacementSalesCreditMemoWithCorrectedInvoiceNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 454286] Stan cannot post the replacement sales credit memo with blank "Corrected Invoice No."

        Initialize();
        // [GIVEN] Sales credit memo with "Correction Type" = Removal and "Corrected Invoice No." = blank
        CreateSalesDoc(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", "SII Sales Credit Memo Type"::"R1 Corrected Invoice",
          "SII Purch. Invoice Type"::"F1 Invoice", SalesHeader."Correction Type"::Replacement);
        SalesHeader."Corrected Invoice No." := '';
        SalesHeader.Modify();

        // [WHEN] Post sales credit memo
        asserterror CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);
        // [THEN] A "Corrected Invoice No. must have a value in Sales Header" error message is thrown
        Assert.ExpectedError(CorrectedInvoiceNoMustHaveValueErr);
    end;

    local procedure Initialize()
    begin
        Clear(SIIXMLCreator);
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();
        LibrarySetupStorage.Save(DATABASE::"SII Setup");

        IsInitialized := true;
    end;

    local procedure PostSalesInvoiceWithRType(var CustLedgerEntry: Record "Cust. Ledger Entry"; var SalesLine: Record "Sales Line"; RType: Enum "SII Sales Invoice Type")
    begin
        PostSalesDoc(CustLedgerEntry, SalesLine, "Sales Document Type"::Invoice, "SII Sales Credit Memo Type"::"R1 Corrected Invoice", RType);
    end;

    local procedure PostSalesCrMemoWithFType(var CustLedgerEntry: Record "Cust. Ledger Entry"; var SalesLine: Record "Sales Line"; FType: Enum "SII Sales Credit Memo Type")
    begin
        PostSalesDoc(CustLedgerEntry, SalesLine, "Sales Document Type"::"Credit Memo", FType, "SII Sales Invoice Type"::"F1 Invoice");
    end;

    local procedure PostSalesDoc(var CustLedgerEntry: Record "Cust. Ledger Entry"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; FType: Enum "SII Sales Credit Memo Type"; RType: Enum "SII Sales Invoice Type")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Invoice Type", RType);
        SalesHeader.Validate("Cr. Memo Type", FType);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchInvWithRType(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PurchaseLine: Record "Purchase Line"; RType: Enum "SII Purch. Invoice Type")
    begin
        PostPurchDoc(VendorLedgerEntry, PurchaseLine, "Purchase Document Type"::Invoice, "SII Purch. Credit Memo Type"::"R1 Corrected Invoice", RType);
    end;

    local procedure PostPurchCrMemoWithFType(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PurchaseLine: Record "Purchase Line"; FType: Enum "SII Purch. Credit Memo Type")
    begin
        PostPurchDoc(VendorLedgerEntry, PurchaseLine, "Purchase Document Type"::"Credit Memo", FType, "SII Purch. Invoice Type"::"F1 Invoice");
    end;

    local procedure PostPurchDoc(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PurchaseLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; FType: Enum "SII Purch. Credit Memo Type"; RType: Enum "SII Purch. Invoice Type")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Invoice Type", RType);
        PurchaseHeader.Validate("Cr. Memo Type", FType);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, DocType,
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostPurchInvWithMultipleLinesOneNegative(var TotalVATAmount: Decimal; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        LibrarySII.UpdateDirectUnitCostPurchaseLine(PurchaseLine, LibraryRandom.RandDec(100, 2));
        TotalVATAmount += PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), -1);
        LibrarySII.UpdateDirectUnitCostPurchaseLine(PurchaseLine, -LibraryRandom.RandDec(100, 2));
        TotalVATAmount += PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice,
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostServiceCrMemoWithFType(var CustLedgerEntry: Record "Cust. Ledger Entry"; var ServiceLine: Record "Service Line"; FType: Enum "SII Sales Credit Memo Type")
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibrarySII.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo(), '');
        ServiceHeader.Validate("Cr. Memo Type", FType);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item,
          LibrarySII.CreateItemWithSpecificVATSetup(ServiceHeader."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25)),
          LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry, ServiceHeader."No.");
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; FType: Enum "SII Sales Credit Memo Type"; RType: Enum "SII Purch. Invoice Type"; CorrectionType: Option)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Invoice Type", RType);
        SalesHeader.Validate("Cr. Memo Type", FType);
        SalesHeader.Validate("Correction Type", CorrectionType);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure SetIncludeImporteTotalInSIISetup()
    var
        SIISetup: Record "SII Setup";
    begin
        SIISetup.Get();
        SIISetup.Validate("Include ImporteTotal", true);
        SIISetup.Modify(true);
    end;
}

