codeunit 144054 "BE - Export PEPPOL 2.1"
{
    // // [FEATURE] [Export] [PEPPOL 2.1]
    // 
    // <Invoice
    //   xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    //   xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
    //   xmlns:ccts="urn:un:unece:uncefact:documentation:2"
    //   xmlns:qdt="urn:oasis:names:specification:ubl:schema:xsd:QualifiedDatatypes-2"
    //   xmlns:udt="urn:un:unece:uncefact:data:specification:UnqualifiedDataTypesSchemaModule:2"
    //   xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2">

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryBEHelper: Codeunit "Library - BE Helper";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceWithVATLoweredBase()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Sales] [Payment Discount]
        // [SCENARIO 231643] Export posted sales invoice in PEPPOL 2.1 format ignores VAT Base (lowered)
        Initialize;

        // [GIVEN] Payment terms "PT" with "Discount %" = 2%
        // [GIVEN] General Ledger Setup with "VAT Tolerance %" = 3% (greater than payment terms discount)
        // [GIVEN] Customer "C" with "Payment Terms Code" = "PT"
        UpdateCompanyInformation;
        CreatePEPPOLCustomer(Customer);

        // [GIVEN] Posted sales invoice "I" for customer "C" with amount = 1000 and "VAT %" = 10%
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.", '', LibraryRandom.RandDecInRange(10, 20, 2), '', 0D);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
        SalesInvoiceHeader.Get(DocumentNo);

        // [WHEN] Export "I" in PEPPOL 2.1 format
        FileName := PEPPOLXMLExport(SalesInvoiceHeader, 'PEPPOL 2.1');

        // [THEN] Posted Sales Invoice has "Payment Discount" = 1000 * 2% = 20 and "VAT Base (Lowered)" = 1000 - 20 = 980
        // [THEN] Reported "Tax Amount" = 1000 * 10% = 100 (ingores payment discount)
        // [THEN] Reported "Amount including VAT" = 1000 + 100 = 1100 (ingores payment discount)
        VerifyAmountsInXml(SalesLine, FileName);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"BE - Export PEPPOL 2.1");
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"BE - Export PEPPOL 2.1");

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"BE - Export PEPPOL 2.1");
    end;

    local procedure InitializeLibraryXPathXMLReader(FileName: Text)
    begin
        Clear(LibraryXPathXMLReader);
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        LibraryXPathXMLReader.AddAdditionalNamespace('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
    end;

    local procedure CreatePEPPOLCustomer(var Customer: Record Customer)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        UpdateVATToleranceOnGLSetup(PaymentTerms."Discount %" + 1);

        LibrarySales.CreateCustomerWithAddress(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);

        Customer."VAT Registration No." := LibraryBEHelper.CreateVatRegNo('BE');
        Customer."Enterprise No." := LibraryUtility.GenerateGUID;

        Customer.Modify(true);
    end;

    local procedure GetFomattedAmount(AmountToFormat: Decimal): Text
    begin
        exit(Format(AmountToFormat, 0, 9));
    end;

    local procedure PEPPOLXMLExport(SalesInvoiceHeader: Record "Sales Invoice Header"; FormatCode: Code[20]): Text
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        SalesInvoiceHeader.SetRecFilter;
        ElectronicDocumentFormat.SendElectronically(ServerFileName, ClientFileName, SalesInvoiceHeader, FormatCode);
        exit(ServerFileName);
    end;

    local procedure UpdateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        with CompanyInformation do begin
            Get;
            Validate("SWIFT Code", Format(LibraryRandom.RandIntInRange(1000000, 9999999)));
            Modify(true);
        end;
    end;

    local procedure UpdateVATToleranceOnGLSetup(NewVATTolerancePercent: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup.Validate("VAT Tolerance %", NewVATTolerancePercent);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyAmountsInXml(SalesLine: Record "Sales Line"; FileName: Text)
    var
        LineAmount: Decimal;
        VATAmount: Decimal;
    begin
        LineAmount := SalesLine."Line Amount";
        VATAmount := Round(SalesLine."Line Amount" * SalesLine."VAT %" / 100);

        InitializeLibraryXPathXMLReader(FileName);

        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:TaxTotal/cbc:TaxAmount', GetFomattedAmount(VATAmount));
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount', GetFomattedAmount(VATAmount));
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount', GetFomattedAmount(LineAmount));
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:LegalMonetaryTotal/cbc:LineExtensionAmount', GetFomattedAmount(LineAmount));
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount', GetFomattedAmount(LineAmount));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '//cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount', GetFomattedAmount(LineAmount + VATAmount));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '//cac:LegalMonetaryTotal/cbc:PayableAmount', GetFomattedAmount(LineAmount + VATAmount));
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:InvoiceLine/cac:TaxTotal/cbc:TaxAmount', GetFomattedAmount(VATAmount));
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:InvoiceLine/cbc:LineExtensionAmount', GetFomattedAmount(LineAmount));
    end;
}

