codeunit 144221 "PEPPOL Pmt. Discount BE"
{
    // // [FEATURE] [PEPPOL] [BIS Billing] [Payment Discount]
    // ----------------------------------------------------------------------------------
    // Test Function Name                                                          TFS ID
    // ----------------------------------------------------------------------------------
    // PaymentDiscountNotDeductedFromTaxAmountsForBESalesInvoice                    644611

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentDiscountNotDeductedFromTaxAmountsForBESalesInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerNo: Code[20];
        PaymentTermsCode: Code[10];
        XMLFilePath: Text;
    begin
        // [SCENARIO 644611] For the Belgian PEPPOL format the taxable amount is calculated on the full amount,
        // i.e. the payment discount is NOT deducted from the VAT-taxable base, so the XML matches the invoice printout.
        Initialize();

        // [GIVEN] Payment Terms with a 3% payment discount
        PaymentTermsCode := CreatePaymentTermsWithDiscount(3);
        // [GIVEN] A customer that uses those payment terms
        CustomerNo := CreateCustomerWithAddressAndGLN();
        // [GIVEN] A posted sales invoice for 1 x 111.20 EUR with 21% VAT and the 3% payment discount terms
        PostSalesInvoiceWithPmtDiscount(SalesInvoiceHeader, CustomerNo, PaymentTermsCode, 111.2, 21);

        // [WHEN] The posted invoice is exported to PEPPOL BIS 3.0 using the Belgian sales format
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());
        LibraryXMLRead.Initialize(XMLFilePath);

        // [THEN] The taxable/monetary totals are calculated on the full amount (111.20 / 134.55),
        // and NOT reduced by the payment discount (which would give 107.86 / 131.21 and fail BR-S-08).
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:LegalMonetaryTotal', 'cbc:LineExtensionAmount', 111.2);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:LegalMonetaryTotal', 'cbc:TaxExclusiveAmount', 111.2);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:LegalMonetaryTotal', 'cbc:TaxInclusiveAmount', 134.55);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:LegalMonetaryTotal', 'cbc:PayableAmount', 134.55);
        // [THEN] The tax subtotal taxable amount equals the full amount and no payment-discount allowance is emitted
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxSubtotal', 'cbc:TaxableAmount', 111.2);
        LibraryXMLRead.VerifyNodeAbsence('cac:AllowanceCharge');
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
    begin
        LibrarySetupStorage.Restore();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"PEPPOL Pmt. Discount BE");

        if IsInitialized then begin
            EnableAdjustForPaymentDiscount();
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

        EnableAdjustForPaymentDiscount();

        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"PEPPOL Pmt. Discount BE");
    end;

    local procedure EnableAdjustForPaymentDiscount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Adjust for Payment Disc." := true;
        GeneralLedgerSetup.Modify();
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
        VATPostingSetup."Adjust for Payment Discount" := true;
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
