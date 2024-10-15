codeunit 147559 "SII Complex Rules"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SII]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        IsInitialized: Boolean;
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        XPathSalesBaseDetalleIVATok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseFactura/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroTipoImpositivoWhenExportSalesInvoiceWithZeroBaseAndSpecialSchemeCode03()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 316808] XML has value "0" in node "TipoImpositivo" when post Sales Invoice with zero VAT Base and "Special Scheme Code" = "03"

        Initialize;

        // [GIVEN] Posted Sales Invoice with two lines - one positive, one negative, both with same line amount so that VAT Base is zero.
        // [GIVEN] "Special Scheme Code" = "03"
        PostSalesDocWithZeroBaseAndSpecialSchemeCode(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0, SalesHeader."Special Scheme Code"::"03 Special System");

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "TipoImpositivo" = "0"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesBaseDetalleIVATok, 'sii:TipoImpositivo', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroTipoImpositivoWhenExportSalesCrMemoWithZeroBaseAndSpecialSchemeCode03()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] ]Sales] [Credit Memo]
        // [SCENARIO 316808] XML has value "0" in node "TipoImpositivo" when post Sales Credit Memo with zero VAT Base and "Special Scheme Code" = "03"

        Initialize;

        // [GIVEN] Posted Sales Credit Memo with two lines - one positive, one negative, both with same line amount so that VAT Base is zero.
        // [GIVEN] "Special Scheme Code" = "03"
        PostSalesDocWithZeroBaseAndSpecialSchemeCode(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", 0, SalesHeader."Special Scheme Code"::"03 Special System");

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "TipoImpositivo" = "0"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesBaseDetalleIVATok, 'sii:TipoImpositivo', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroTipoImpositivoWhenExportReplacementSalesCrMemoWithZeroBaseAndSpecialSchemeCode03()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 316808] XML has value "0" in node "TipoImpositivo" when post Replacement Sales Credit Memo with zero VAT Base and "Special Scheme Code" = "03"

        Initialize;

        // [GIVEN] Posted Replacement Sales Credit Memo with two lines - one positive, one negative, both with same line amount so that VAT Base is zero.
        // [GIVEN] "Special Scheme Code" = "03"
        PostSalesDocWithZeroBaseAndSpecialSchemeCode(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement,
          SalesHeader."Special Scheme Code"::"03 Special System");

        // [WHEN] Create xml for Posted Replacement Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "TipoImpositivo" = "0"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesBaseDetalleIVATok, 'sii:TipoImpositivo', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroTipoImpositivoWhenExportSalesInvoiceWithZeroBaseAndSpecialSchemeCode05()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 316808] XML has value "0" in node "TipoImpositivo" when post Sales Invoice with zero VAT Base and "Special Scheme Code" = "05"

        Initialize;

        // [GIVEN] Posted Sales Invoice with two lines - one positive, one negative, both with same line amount so that VAT Base is zero.
        // [GIVEN] "Special Scheme Code" = "05"
        PostSalesDocWithZeroBaseAndSpecialSchemeCode(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0, SalesHeader."Special Scheme Code"::"05 Travel Agencies");

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "TipoImpositivo" = "0"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesBaseDetalleIVATok, 'sii:TipoImpositivo', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroTipoImpositivoWhenExportSalesCrMemoWithZeroBaseAndSpecialSchemeCode05()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 316808] XML has value "0" in node "TipoImpositivo" when post Sales Credit Memo with zero VAT Base and "Special Scheme Code" = "05"

        Initialize;

        // [GIVEN] Posted Sales Credit Memo with two lines - one positive, one negative, both with same line amount so that VAT Base is zero.
        // [GIVEN] "Special Scheme Code" = "05"
        PostSalesDocWithZeroBaseAndSpecialSchemeCode(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", 0, SalesHeader."Special Scheme Code"::"05 Travel Agencies");

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "TipoImpositivo" = "0"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesBaseDetalleIVATok, 'sii:TipoImpositivo', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroTipoImpositivoWhenExportReplacementSalesCrMemoWithZeroBaseAndSpecialSchemeCode05()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 316808] XML has value "0" in node "TipoImpositivo" when post Replacement Sales Credit Memo with zero VAT Base and "Special Scheme Code" = "05"

        Initialize;

        // [GIVEN] Posted Replacement Sales Credit Memo with two lines - one positive, one negative, both with same line amount so that VAT Base is zero.
        // [GIVEN] "Special Scheme Code" = "05"
        PostSalesDocWithZeroBaseAndSpecialSchemeCode(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement,
          SalesHeader."Special Scheme Code"::"05 Travel Agencies");

        // [WHEN] Create xml for Posted Replacement Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "TipoImpositivo" = "0"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesBaseDetalleIVATok, 'sii:TipoImpositivo', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroTipoImpositivoWhenExportSalesInvoiceWithZeroBaseAndSpecialSchemeCode09()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 316808] XML has value "0" in node "TipoImpositivo" when post Sales Invoice with zero VAT Base and "Special Scheme Code" = "09"

        Initialize;

        // [GIVEN] Posted Sales Invoice with two lines - one positive, one negative, both with same line amount so that VAT Base is zero.
        // [GIVEN] "Special Scheme Code" = "09"
        PostSalesDocWithZeroBaseAndSpecialSchemeCode(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0, SalesHeader."Special Scheme Code"::"09 Travel Agency Services");

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "TipoImpositivo" = "0"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesBaseDetalleIVATok, 'sii:TipoImpositivo', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroTipoImpositivoWhenExportSalesCrMemoWithZeroBaseAndSpecialSchemeCode09()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 316808] XML has value "0" in node "TipoImpositivo" when post Sales Credit Memo with zero VAT Base and "Special Scheme Code" = "09"

        Initialize;

        // [GIVEN] Posted Sales Credit Memo with two lines - one positive, one negative, both with same line amount so that VAT Base is zero.
        // [GIVEN] "Special Scheme Code" = "09"
        PostSalesDocWithZeroBaseAndSpecialSchemeCode(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", 0, SalesHeader."Special Scheme Code"::"09 Travel Agency Services");

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "TipoImpositivo" = "0"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesBaseDetalleIVATok, 'sii:TipoImpositivo', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroTipoImpositivoWhenExportReplacementSalesCrMemoWithZeroBaseAndSpecialSchemeCode09()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 316808] XML has value "0" in node "TipoImpositivo" when post Replacement Sales Credit Memo with zero VAT Base and "Special Scheme Code" = "09"

        Initialize;

        // [GIVEN] Posted Replacement Sales Credit Memo with two lines - one positive, one negative, both with same line amount so that VAT Base is zero.
        // [GIVEN] "Special Scheme Code" = "09"
        PostSalesDocWithZeroBaseAndSpecialSchemeCode(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement,
          SalesHeader."Special Scheme Code"::"09 Travel Agency Services");

        // [WHEN] Create xml for Posted Replacement Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "TipoImpositivo" = "0"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesBaseDetalleIVATok, 'sii:TipoImpositivo', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroCuotaDeducibleWhenExportPurchInvWithSpecialSchemeCode13()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 316808] XML has value "0" in node "CuotaDeducible" when post Purchase Invoice with "Special Scheme Code" = "13"

        Initialize;

        // [GIVEN] Post Purchase Invoice with "Special Scheme Code" = "13"
        PostPurchDocWithSpecialSchemeCode(
          VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0, PurchaseHeader."Special Scheme Code"::"13 Import (Without DUA)");

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "CuotaDeducible" = "0"
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroCuotaDeducibleWhenExportPurchCrMemoWithSpecialSchemeCode13()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 316808] XML has value "0" in node "CuotaDeducible" when post Purchase Credit Memo with "Special Scheme Code" = "13"

        Initialize;

        // [GIVEN] Post Purchase Credit Memo with "Special Scheme Code" = "13"
        PostPurchDocWithSpecialSchemeCode(
          VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0, PurchaseHeader."Special Scheme Code"::"13 Import (Without DUA)");

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "CuotaDeducible" = "0"
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroCuotaDeducibleWhenExportReplacementPurchCrMemoWithSpecialSchemeCode13()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 316808] XML has value "0" in node "CuotaDeducible" when post ReplacementPurchase Credit Memo with "Special Scheme Code" = "13"

        Initialize;

        // [GIVEN] Post Replacement Purchase Credit Memo with "Special Scheme Code" = "13"
        PostPurchDocWithSpecialSchemeCode(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Replacement,
          PurchaseHeader."Special Scheme Code"::"13 Import (Without DUA)");

        // [WHEN] Create xml for Posted Replacement Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "CuotaDeducible" = "0"
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(0));
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue;
        IsInitialized := true;
    end;

    local procedure PostSalesDocWithZeroBaseAndSpecialSchemeCode(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Option; CorrType: Option; SpecialSchemeCode: Option)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NegativeSalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo);
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Validate("Special Scheme Code", SpecialSchemeCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.CreateSalesLine(
          NegativeSalesLine, SalesHeader, SalesLine.Type::"G/L Account", SalesLine."No.", -SalesLine.Quantity);
        NegativeSalesLine.Validate("Unit Price", SalesLine."Unit Price");
        NegativeSalesLine.Modify(true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchDocWithSpecialSchemeCode(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Option; CorrType: Option; SpecialSchemeCode: Option)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, LibraryPurchase.CreateVendorNo);
        PurchaseHeader.Validate("Correction Type", CorrType);
        PurchaseHeader.Validate("Special Scheme Code", SpecialSchemeCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocType, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;
}

