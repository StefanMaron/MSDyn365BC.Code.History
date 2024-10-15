codeunit 147555 "SII Unrealized VAT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SII] [Unrealized VAT]
    end;

    var
        Library340347Declaration: Codeunit "Library - 340 347 Declaration";
        LibrarySII: Codeunit "Library - SII";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        XPathPurchBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/sii:DesgloseFactura/sii:DesgloseIVA/sii:DetalleIVA/';
        IsInitialized: Boolean;
        XPathSalesBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseFactura/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/';

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithSingleGLAccLine()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 263648] Purchase invoice with G/L Account has one details line in XML file

        Initialize;

        // [GIVEN] Posted purchase invoice with Unrealized VAT Setup and single line with G/L Account with amount = 100
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, true, true);
        PostPurchInvWithVATPostingSetupAndGLAcc(VendorLedgerEntry, PurchaseLine, VATPostingSetup);

        // [WHEN] Export posted purchase invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] BaseImponible node exports with amount = 100
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(PurchaseLine.Amount));

        // [THEN] Only one BaseImponible node exports
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);

        // Tear down
        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithSingleGLAccLine()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 263648] Sales invoice with G/L Account has one details line in XML file

        Initialize;

        // [GIVEN] Posted sales invoice with Unrealized VAT Setup and single line with G/L Account with amount = 100
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, true, true);
        PostSalesInvWithVATPostingSetupAndGLAcc(CustLedgerEntry, SalesLine, VATPostingSetup);

        // [WHEN] Export posted sales invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] BaseImponible node exports with amount = 100
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(SalesLine.Amount));

        // [THEN] Only one BaseImponible node exports
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);

        // Tear down
        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue;
        IsInitialized := true;
    end;

    local procedure PostPurchInvWithVATPostingSetupAndGLAcc(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        Library340347Declaration.CreateVendor(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          SetVATProdPostGroupForGLAcc(LibraryERM.CreateGLAccountWithPurchSetup, VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostSalesInvWithVATPostingSetupAndGLAcc(var CustLedgerEntry: Record "Cust. Ledger Entry"; var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          SetVATProdPostGroupForGLAcc(LibraryERM.CreateGLAccountWithSalesSetup, VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure SetVATProdPostGroupForGLAcc(GLAccNo: Code[20]; VATProdPostGroupCode: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccNo);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostGroupCode);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;
}

