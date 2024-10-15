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
        XPathPurchBaseDetalleIVATok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/sii:DesgloseFactura/sii:DesgloseIVA/sii:DetalleIVA/';

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

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithBaseImponibleACosteNode()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 330227] Sales invoice with "Sales Special Scheme Code" has BaseImponibleACost XML node with the total VAT Base value

        Initialize;

        // [GIVEN] Sales invoice with total VAT Base equals 100 and "Special Scheme Code" equals "06 Groups of Entities"
        PostSalesDocWithSpecialSchemeCode(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0, SalesHeader."Special Scheme Code"::"06 Groups of Entities");

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "BaseImponibleACoste" with value 100
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:BaseImponibleACoste',
          SIIXMLCreator.FormatNumber(
            -GetTotalVATBase(VATEntry.Type::Sale, CustLedgerEntry."Document Type",
              CustLedgerEntry."Document No.", CustLedgerEntry."Posting Date")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithBaseImponibleACosteNode()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 330227] Sales credit memo with "Sales Special Scheme Code" has BaseImponibleACost XML node with the total VAT Base value

        Initialize;

        // [GIVEN] Sales credit memo with total VAT Base equals 100 and "Special Scheme Code" equals "06 Groups of Entities"
        PostSalesDocWithSpecialSchemeCode(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", 0, SalesHeader."Special Scheme Code"::"06 Groups of Entities");

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "BaseImponibleACoste" with value 100
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:BaseImponibleACoste',
          SIIXMLCreator.FormatNumber(
            -GetTotalVATBase(VATEntry.Type::Sale, CustLedgerEntry."Document Type",
              CustLedgerEntry."Document No.", CustLedgerEntry."Posting Date")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReplacementCrMemoWithBaseImponibleACosteNode()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 330227] Sales replacement credit memo with "Sales Special Scheme Code" has BaseImponibleACost XML node with the total VAT Base value

        Initialize;

        // [GIVEN] Sales replacement credit memo with total VAT Base equals 100 and "Special Scheme Code" equals "06 Groups of Entities"
        PostSalesDocWithSpecialSchemeCode(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo",
          SalesHeader."Correction Type"::Replacement, SalesHeader."Special Scheme Code"::"06 Groups of Entities");

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "BaseImponibleACoste" with value 100
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:BaseImponibleACoste',
          SIIXMLCreator.FormatNumber(
            -GetTotalVATBase(VATEntry.Type::Sale, CustLedgerEntry."Document Type",
              CustLedgerEntry."Document No.", CustLedgerEntry."Posting Date")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithBaseImponibleACosteNode()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 330227] Purchase invoice with "Sales Special Scheme Code" has BaseImponibleACost XML node with the total VAT Base value

        Initialize;

        // [GIVEN] Purchase invoice with total VAT Base equals 100 and "Special Scheme Code" equals "06 Groups of Entities"
        PostPurchDocWithSpecialSchemeCode(
          VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0, PurchaseHeader."Special Scheme Code"::"06 Groups of Entities");

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "BaseImponibleACoste" with value 100
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:BaseImponibleACoste',
          SIIXMLCreator.FormatNumber(
            GetTotalVATBase(VATEntry.Type::Purchase, VendorLedgerEntry."Document Type",
              VendorLedgerEntry."Document No.", VendorLedgerEntry."Posting Date")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithBaseImponibleACosteNode()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 330227] Purchase credit memo with "Sales Special Scheme Code" has BaseImponibleACost XML node with the total VAT Base value

        Initialize;

        // [GIVEN] Purchase credit memo with total VAT Base equals 100 and "Special Scheme Code" equals "06 Groups of Entities"
        PostPurchDocWithSpecialSchemeCode(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo",
          0, PurchaseHeader."Special Scheme Code"::"06 Groups of Entities");

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "BaseImponibleACoste" with value 100
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:BaseImponibleACoste',
          SIIXMLCreator.FormatNumber(
            GetTotalVATBase(VATEntry.Type::Purchase, VendorLedgerEntry."Document Type",
              VendorLedgerEntry."Document No.", VendorLedgerEntry."Posting Date")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReplacementCrMemoWithBaseImponibleACosteNode()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 330227] Purchase replacement credit memo with "Sales Special Scheme Code" has BaseImponibleACost XML node with the total VAT Base value

        Initialize;

        // [GIVEN] Purchase replacement credit memo with total VAT Base equals 100 and "Special Scheme Code" equals "06 Groups of Entities"
        PostPurchDocWithSpecialSchemeCode(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Replacement,
          PurchaseHeader."Special Scheme Code"::"06 Groups of Entities");

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "BaseImponibleACoste" with value 100
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:BaseImponibleACoste',
          SIIXMLCreator.FormatNumber(
            GetTotalVATBase(VATEntry.Type::Purchase, VendorLedgerEntry."Document Type",
              VendorLedgerEntry."Document No.", VendorLedgerEntry."Posting Date")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithBaseImponibleACosteNodeDoesNotConsiderZeroVATEntries()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 332475] Sales invoice with "Sales Special Scheme Code" and zero "VAT %" has BaseImponibleACost XML node with the zero value

        Initialize;

        // [GIVEN] Sales invoice with total VAT Base equals 100 and "VAT %" = 0
        PostSalesDocWithZeroVATPercent(CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "BaseImponibleACoste" with value 0
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponibleACoste', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithBaseImponibleACosteNodeDoesNotConsiderZeroVATEntries()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 332475] Sales credit memo with "Sales Special Scheme Code" and zero "VAT %" has BaseImponibleACost XML node with the zero value

        Initialize;

        // [GIVEN] Sales credit memo with total VAT Base equals 100 and "VAT %" = 0
        PostSalesDocWithZeroVATPercent(CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "BaseImponibleACoste" with value 0
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponibleACoste', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReplacementCrMemoWithBaseImponibleACosteNodeDoesNotConsiderZeroVATEntries()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 332475] Sales replacement credit memo with "Sales Special Scheme Code" and zero "VAT %" has BaseImponibleACost XML node with the zero value

        Initialize;

        // [GIVEN] Sales replacement credit memo with total VAT Base equals 100 and "VAT %" = 0
        PostSalesDocWithZeroVATPercent(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "BaseImponibleACoste" with value 0
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponibleACoste', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithBaseImponibleACosteNodeDoesNotConsiderZeroVATEntries()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 332475] Purchase invoice with "Purchase Special Scheme Code" and zero "VAT %" has BaseImponibleACost XML node with the zero value

        Initialize;

        // [GIVEN] Purchase invoice with total VAT Base equals 100 and "VAT %" = 0
        PostPurchaseDocWithZeroVATPercent(VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "BaseImponibleACoste" with value 0
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponibleACoste', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithBaseImponibleACosteNodeDoesNotConsiderZeroVATEntries()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 332475] Purchase credit memo with "Purchase Special Scheme Code" and zero "VAT %" has BaseImponibleACost XML node with the zero value

        Initialize;

        // [GIVEN] Purchase credit memo with total VAT Base equals 100 and "VAT %" = 0
        PostPurchaseDocWithZeroVATPercent(VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "BaseImponibleACoste" with value 0
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponibleACoste', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReplacementCrMemoWithBaseImponibleACosteNodeDoesNotConsiderZeroVATEntries()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 332475] Purchase replacement credit memo with "Purchase Special Scheme Code" and zero "VAT %" has BaseImponibleACost XML node with the zero value

        Initialize;

        // [GIVEN] Purchase replacement credit memo with total VAT Base equals 100 and "VAT %" = 0
        PostPurchaseDocWithZeroVATPercent(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "BaseImponibleACoste" with value 0
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponibleACoste', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithSpecialSchemeCode02()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 355791] An xml file of purchase invoice with the special scheme code "02" contains nodes PorcentCompensacionREAGYP and ImporteCompensacionREAGYP

        Initialize();

        // [GIVEN] Purchase invoice with "Special Scheme Code" = "02", "VAT %" = 21 and total VAT amount = 210
        PostPurchDocWithSpecialSchemeCode(
          VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0,
          PurchaseHeader."Special Scheme Code"::"02 Special System Activities");

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "PorcentCompensacionREAGYP" with value "21"
        FindVATEntryFromVendLedgEntry(VATEntry, VendorLedgerEntry);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseDetalleIVATok, 'sii:PorcentCompensacionREAGYP', SIIXMLCreator.FormatNumber(VATEntry."VAT %"));

        // [THEN] XML file has node "ImporteCompensacionREAGYP" with value "210"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseDetalleIVATok, 'sii:ImporteCompensacionREAGYP', SIIXMLCreator.FormatNumber(VATEntry.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithSpecialSchemeCode02()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 355791] An xml file of purchase credit memo with the special scheme code "02" contains nodes PorcentCompensacionREAGYP and ImporteCompensacionREAGYP

        Initialize();

        // [GIVEN] Purchase credit memo with "Special Scheme Code" = "02", "VAT %" = 21 and total VAT amount = 210
        PostPurchDocWithSpecialSchemeCode(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", 0,
          PurchaseHeader."Special Scheme Code"::"02 Special System Activities");

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "PorcentCompensacionREAGYP" with value "21"
        FindVATEntryFromVendLedgEntry(VATEntry, VendorLedgerEntry);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseDetalleIVATok, 'sii:PorcentCompensacionREAGYP', SIIXMLCreator.FormatNumber(VATEntry."VAT %"));

        // [THEN] XML file has node "ImporteCompensacionREAGYP" with value "210"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseDetalleIVATok, 'sii:ImporteCompensacionREAGYP', SIIXMLCreator.FormatNumber(VATEntry.Amount));
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
        CreateSalesDocWithSpecialSchemeCode(SalesHeader, DocType, CorrType, SpecialSchemeCode);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
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

    local procedure PostSalesDocWithSpecialSchemeCode(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Option; CorrType: Option; SpecialSchemeCode: Option)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocWithSpecialSchemeCode(SalesHeader, DocType, CorrType, SpecialSchemeCode);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesDocWithSpecialSchemeCode(var SalesHeader: Record "Sales Header"; DocType: Option; CorrType: Option; SpecialSchemeCode: Option)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo);
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Validate("Special Scheme Code", SpecialSchemeCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure PostSalesDocWithZeroVATPercent(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Option; CorrType: Option)
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo);
        SalesHeader.Validate("Special Scheme Code", SalesHeader."Special Scheme Code"::"06 Groups of Entities");
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Modify(true);
        VATBusinessPostingGroup.Get(SalesHeader."VAT Bus. Posting Group");
        LibrarySII.CreateVATPostingSetup(
          VATPostingSetup, VATProductPostingGroup, VATBusinessPostingGroup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0, false); // zero VAT %
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, LibraryRandom.RandInt(100));
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchaseDocWithZeroVATPercent(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Option; CorrType: Option)
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, LibraryPurchase.CreateVendorNo);
        PurchaseHeader.Validate("Special Scheme Code", PurchaseHeader."Special Scheme Code"::"06 Groups of Entities");
        PurchaseHeader.Validate("Correction Type", CorrType);
        PurchaseHeader.Modify(true);
        VATBusinessPostingGroup.Get(PurchaseHeader."VAT Bus. Posting Group");
        LibrarySII.CreateVATPostingSetup(
          VATPostingSetup, VATProductPostingGroup, VATBusinessPostingGroup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0, false); // zero VAT %
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocType, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure GetTotalVATBase(Type: Option; DocType: Option; DocNo: Code[20]; PostingDate: Date): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange(Type, Type);
        VATEntry.SetRange("Document Type", DocType);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange("Posting Date", PostingDate);
        VATEntry.CalcSums(Base);
        exit(VATEntry.Base);
    end;

    local procedure FindVATEntryFromVendLedgEntry(var VATEntry: Record "VAT Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VATEntry.SetRange("Document Type", VendorLedgerEntry."Document Type");
        VATEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
        VATEntry.SetRange("Posting Date", VendorLedgerEntry."Posting Date");
        VATEntry.FindFirst();
    end;
}

