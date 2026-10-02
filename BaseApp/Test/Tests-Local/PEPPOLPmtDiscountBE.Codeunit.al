codeunit 144221 "PEPPOL Pmt. Discount BE"
{
    // // [FEATURE] [PEPPOL] [BIS Billing] [Payment Discount]
    // ----------------------------------------------------------------------------------
    // Test Function Name                                                          TFS ID
    // ----------------------------------------------------------------------------------
    // BESalesInvoiceEscompteCompensation                                          643204

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        InvoiceNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2', Locked = true;
        EscompteExemptionReasonTxt: Label 'Conditional early-payment discount, not part of the taxable amount';

    [Test]
    [Scope('OnPrem')]
    procedure BESalesInvoiceEscompteCompensation()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerNo: Code[20];
        PaymentTermsCode: Code[10];
        XMLFilePath: Text;
    begin
        // [SCENARIO 643204] The Belgian escompte keeps VAT on the discounted base, but the conditional payment discount must not reduce the amount payable.
        Initialize();

        // [GIVEN] Payment Terms with a 3% payment discount
        PaymentTermsCode := CreatePaymentTermsWithDiscount(3);
        // [GIVEN] A customer that uses those payment terms
        CustomerNo := CreateCustomerWithAddressAndGLN();
        // [GIVEN] A posted sales invoice for 1 x 111.20 with 21% VAT and the 3% payment discount terms; the escompte
        // is active so VAT is charged on the discounted base 107.86 (VAT 22.65, total 133.85).
        PostSalesInvoiceWithPmtDiscount(SalesInvoiceHeader, CustomerNo, PaymentTermsCode, 111.2, 21);

        // [WHEN] The posted invoice is exported to PEPPOL BIS 3.0 using the Belgian sales format
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());
        InitXPathXMLReaderForInvoice(XMLFilePath);

        // [THEN] Two VAT breakdowns: Standard 107.86 / 22.65 and the compensating Exempt 3.34 / 0.00 (with a reason)
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//cac:TaxTotal/cac:TaxSubtotal', 2);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:TaxTotal/cbc:TaxAmount', '22.65');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:TaxSubtotal[cac:TaxCategory/cbc:ID=''S'']/cbc:TaxableAmount', '107.86');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:TaxSubtotal[cac:TaxCategory/cbc:ID=''S'']/cbc:TaxAmount', '22.65');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:TaxSubtotal[cac:TaxCategory/cbc:ID=''E'']/cbc:TaxableAmount', '3.34');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:TaxSubtotal[cac:TaxCategory/cbc:ID=''E'']/cbc:TaxAmount', '0.00');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:TaxSubtotal[cac:TaxCategory/cbc:ID=''E'']/cac:TaxCategory/cbc:TaxExemptionReason', EscompteExemptionReasonTxt);

        // [THEN] Two document-level AllowanceCharges: the Standard payment-discount allowance and the Exempt compensating charge
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//cac:AllowanceCharge', 2);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:AllowanceCharge[cbc:ChargeIndicator=''false'']/cbc:Amount', '3.34');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:AllowanceCharge[cbc:ChargeIndicator=''true'']/cbc:Amount', '3.34');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:AllowanceCharge[cbc:ChargeIndicator=''true'']/cac:TaxCategory/cbc:ID', 'E');
        // [THEN] The compensating charge carries only a text reason - no (empty) reason code element is emitted
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//cac:AllowanceCharge[cbc:ChargeIndicator=''true'']/cbc:AllowanceChargeReasonCode', 0);

        // [THEN] The amount payable stays whole: LineExtension/TaxExclusive 111.20, Allowance & Charge 3.34, total 133.85
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:LegalMonetaryTotal/cbc:LineExtensionAmount', '111.2');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount', '111.2');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount', '3.34');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:LegalMonetaryTotal/cbc:ChargeTotalAmount', '3.34');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount', '133.85');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:LegalMonetaryTotal/cbc:PayableAmount', '133.85');
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
    begin
        LibrarySetupStorage.Restore();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"PEPPOL Pmt. Discount BE");

        if IsInitialized then begin
            EnableBEPaymentDiscountVAT();
            exit;
        end;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"PEPPOL Pmt. Discount BE");

        CompanyInformation.Get();
        CompanyInformation.Validate(IBAN, 'GB29NWBK60161331926819');
        CompanyInformation.Validate("SWIFT Code", 'MIDLGB22Z0K');
        CompanyInformation.Validate("Bank Branch No.", '1234');
        if CompanyInformation."VAT Registration No." = '' then
            CompanyInformation."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code");
        CompanyInformation.Validate(GLN, '1234567891231');
        CompanyInformation.Validate("Use GLN in Electronic Document", true);
        CompanyInformation.Modify(true);

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateLocalData();

        EnableBEPaymentDiscountVAT();

        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"PEPPOL Pmt. Discount BE");
    end;

    local procedure EnableBEPaymentDiscountVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Belgian escompte: VAT is charged on the discounted base.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Adjust for Payment Disc.", false);
        GeneralLedgerSetup.Validate("Pmt. Disc. Excl. VAT", true);
        GeneralLedgerSetup.Validate("VAT Tolerance %", 3);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure InitXPathXMLReaderForInvoice(XMLFilePath: Text)
    begin
        LibraryXPathXMLReader.Initialize(XMLFilePath, InvoiceNamespaceTxt);
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        LibraryXPathXMLReader.AddAdditionalNamespace('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
    end;

    local procedure CreatePaymentTermsWithDiscount(DiscountPct: Decimal): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Discount Date Calculation", '<8D>');
        PaymentTerms.Validate("Discount Date Calculation", PaymentTerms."Discount Date Calculation");
        PaymentTerms.Validate("Discount %", DiscountPct);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateCustomerWithAddressAndGLN(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomerWithAddress(Customer);
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(Customer."Country/Region Code");
        Customer.Validate(GLN, '1234567891231');
        Customer."Use GLN in Electronic Document" := true;
        Customer.Modify();
        exit(Customer."No.");
    end;

    local procedure PostSalesInvoiceWithPmtDiscount(var SalesInvoiceHeader: Record "Sales Invoice Header"; CustomerNo: Code[20]; PaymentTermsCode: Code[10]; UnitPrice: Decimal; VATPct: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        SalesHeader.Validate("Your Reference", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("VAT Prod. Posting Group", CreateVATPostingSetupWithPmtDiscount(SalesHeader."VAT Bus. Posting Group", VATPct));
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();
    end;

    local procedure CreateVATPostingSetupWithPmtDiscount(VATBusPostingGroup: Code[20]; VATPct: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup."VAT Identifier" := LibraryUtility.GenerateGUID();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Validate("Tax Category", 'S');
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
        exit(VATProductPostingGroup.Code);
    end;

    local procedure CreateBISElectronicDocumentFormatSalesInvoice(): Code[20]
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        ElectronicDocumentFormat.Init();
        ElectronicDocumentFormat.Code := LibraryUtility.GenerateGUID();
        ElectronicDocumentFormat.Usage := ElectronicDocumentFormat.Usage::"Sales Invoice";
        ElectronicDocumentFormat."Codeunit ID" := Codeunit::"Exp. Sales Inv. PEPPOL BIS3.0";
        if ElectronicDocumentFormat.Insert() then;
        exit(ElectronicDocumentFormat.Code);
    end;

    local procedure PEPPOLXMLExport(DocumentVariant: Variant; FormatCode: Code[20]): Text
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFileName, DocumentVariant, FormatCode);
        ServerFileName := CopyStr(FileManagement.ServerTempFileName('xml'), 1, 250);
        FileManagement.BLOBExportToServerFile(TempBlob, ServerFileName);
        exit(ServerFileName);
    end;
}
