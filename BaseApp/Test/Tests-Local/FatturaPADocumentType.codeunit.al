codeunit 144210 "FatturaPA Document Type"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySplitVAT: Codeunit "Library - Split VAT";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        FatturaPA_ElectronicFormatTxt: Label 'FatturaPA';
        UnexpectedElementValueErr: Label 'Unexpected element value for element %1. Expected element value: %2. Actual element value: %3.', Comment = '%1=XML Element Name;%2=Expected XML Element Value;%3=Actual XML element Value;';
        OptionAlreadySpecifiedErr: Label 'Documents of type %1 already have code %2 as default. You can only use one code for each type of document.', Comment = '%1 = field caption;%2 = code value.';

    [Test]
    [Scope('OnPrem')]
    procedure FatturaDocTypeListCreatesOnPageOpening()
    var
        FatturaDocumentType: Record "Fattura Document Type";
        FatturaDocumentTypeList: TestPage "Fattura Document Type List";
    begin
        // [FEATURE] [DEMO] [UI]

        Initialize();
        LibraryLowerPermissions.SetLocal();
        FatturaDocumentTypeList.OpenView();
        Assert.IsFalse(FatturaDocumentType.IsEmpty(), 'Fattura Document Type list is empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleDefaultTypeOfFatturaDocumentType()
    var
        FatturaDocumentType: Record "Fattura Document Type";
        InvoiceFatturaDocumentType: Record "Fattura Document Type";
        CrMemoFatturaDocumentType: Record "Fattura Document Type";
        SelfBillingFatturaDocumentType: Record "Fattura Document Type";
        PrepaymentFatturaDocumentType: Record "Fattura Document Type";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // [FEATURE] [DEMO] [UT]
        // [SCENARIO 352458] A list of the Fattura Document Type codes can have only one default value of Invoice, Credit Memo, Self-Billing and Prepayment

        Initialize;
        FatturaDocHelper.InsertFatturaDocumentTypeList();
        InvoiceFatturaDocumentType.SetRange(Invoice, true);
        Assert.IsTrue(InvoiceFatturaDocumentType.FindFirst(), 'No code for the Invoice');
        CrMemoFatturaDocumentType.SetRange("Credit Memo", true);
        Assert.IsTrue(CrMemoFatturaDocumentType.FindFirst(), 'No code for the Credit Memo');
        SelfBillingFatturaDocumentType.SetRange("Self-Billing", true);
        Assert.IsTrue(SelfBillingFatturaDocumentType.FindFirst(), 'No code for the Self-Billing');
        PrepaymentFatturaDocumentType.SetRange(Prepayment, true);
        Assert.IsTrue(PrepaymentFatturaDocumentType.FindFirst(), 'No code for the Prepayment');
        Commit;

        FilterFatturaDocumentTypeNoDefaultValues(FatturaDocumentType);
        FatturaDocumentType.FindFirst();
        asserterror FatturaDocumentType.Validate(Invoice, true);
        Assert.ExpectedError(
          StrSubstNo(OptionAlreadySpecifiedErr, FatturaDocumentType.FieldCaption(Invoice), InvoiceFatturaDocumentType."No."));
        asserterror FatturaDocumentType.Validate("Credit Memo", true);
        Assert.ExpectedError(
          StrSubstNo(OptionAlreadySpecifiedErr, FatturaDocumentType.FieldCaption("Credit Memo"), CrMemoFatturaDocumentType."No."));
        asserterror FatturaDocumentType.Validate("Self-Billing", true);
        Assert.ExpectedError(
          StrSubstNo(OptionAlreadySpecifiedErr, FatturaDocumentType.FieldCaption("Self-Billing"), SelfBillingFatturaDocumentType."No."));
        asserterror FatturaDocumentType.Validate(Prepayment, true);
        Assert.ExpectedError(
          StrSubstNo(OptionAlreadySpecifiedErr, FatturaDocumentType.FieldCaption(Prepayment), PrepaymentFatturaDocumentType."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SelfBillingTypeIsCustVATRegMatchesCompanyInfInSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 352458] A "Fattura Document Type" is self-billing in the Sales Document if customer has the same VAT Registration No. as Company

        Initialize;
        SalesHeader.Init;
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.TestField("Fattura Document Type", FatturaDocHelper.GetInvoiceCode());

        Customer.Get(LibraryITLocalization.CreateCustomer());
        SetVATRegistrationNoInCompanyInformation(Customer."VAT Registration No.");
        SalesHeader.Validate("Bill-to Customer No.", Customer."No.");
        SalesHeader.TestField("Fattura Document Type", FatturaDocHelper.GetSelfBillingCode());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SelfBillingTypeIsCustVATRegMatchesCompanyInfInServDoc()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // [SCENARIO 352458] A "Fattura Document Type" is self-billing in the Service Document if customer has the same VAT Registration No. as Company

        Initialize;
        ServiceHeader.Init;
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Invoice;
        ServiceHeader.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        ServiceHeader.TestField("Fattura Document Type", FatturaDocHelper.GetInvoiceCode());

        Customer.Get(LibraryITLocalization.CreateCustomer());
        SetVATRegistrationNoInCompanyInformation(Customer."VAT Registration No.");
        ServiceHeader.Validate("Bill-to Customer No.", Customer."No.");
        ServiceHeader.TestField("Fattura Document Type", FatturaDocHelper.GetSelfBillingCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMemoDocTypeInSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 342458] A "Fattura Document Type" is credit memo in the Sales Credit Memo document

        Initialize;
        SalesHeader.Init;
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.TestField("Fattura Document Type", FatturaDocHelper.GetCrMemoCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMemoDocTypeInServDoc()
    var
        ServiceHeader: Record "Service Header";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 342458] A "Fattura Document Type" is credit memo in the Service Credit Memo document

        Initialize;
        ServiceHeader.Init;
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::"Credit Memo";
        ServiceHeader.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        ServiceHeader.TestField("Fattura Document Type", FatturaDocHelper.GetCrMemoCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualDocTypeInSalesDoc()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        FatturaDocType: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Export]
        // [SCENARIO 352458] A FatturaPA xml file has Fattura Document Type code manually entered in the sales document

        Initialize;
        FatturaDocType := GetRandomFatturaDocType();
        DocumentNo := PostSalesInvoice(FatturaDocType);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] TipoDocumento is "TD02" in exported file
        VerifyTipoDocumento(ServerFileName, FatturaDocType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualDocTypeInServDoc()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        FatturaDocType: Code[20];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Export]
        // [SCENARIO 352458] A FatturaPA xml file has Fattura Document Type code manually entered in the service document

        Initialize;
        FatturaDocType := GetRandomFatturaDocType();
        CustomerNo := PostServiceInvoice(FatturaDocType);
        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] TipoDocumento is "TD02" in exported file
        VerifyTipoDocumento(ServerFileName, FatturaDocType);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"FatturaPA Document Type");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"FatturaPA Document Type");
        LibraryITLocalization.SetupFatturaPA();
        LibrarySetupStorage.SaveCompanyInformation();
        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SavePurchasesSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"FatturaPA Document Type");
        IsInitialized := true;
    end;

    local procedure PostSalesInvoice(FatturaDocType: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          LibraryITLocalization.CreateCustomer(), '', 5, '', 0D);
        SalesHeader.Validate("Fattura Document Type", FatturaDocType);
        SalesHeader.Validate("Payment Method Code", LibraryITLocalization.CreateFatturaPaymentMethodCode);
        SalesHeader.Validate("Payment Terms Code", LibraryITLocalization.CreateFatturaPaymentTermsCode);
        SalesHeader.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostServiceInvoice(FatturaDocType: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Invoice, LibraryITLocalization.CreateCustomer());
        ServiceHeader.Validate("Order Date", WorkDate);
        ServiceHeader.Validate("Payment Method Code", LibraryITLocalization.CreateFatturaPaymentMethodCode());
        ServiceHeader.Validate("Payment Terms Code", LibraryITLocalization.CreateFatturaPaymentTermsCode());
        ServiceHeader.Validate("Fattura Document Type", FatturaDocType);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(ServiceHeader."Customer No.");
    end;

    local procedure SetVATRegistrationNoInCompanyInformation(VATRegistrationNo: Code[20])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("VAT Registration No.", VATRegistrationNo);
        CompanyInformation.Modify(true);
    end;

    local procedure GetRandomFatturaDocType(): Code[20]
    var
        FatturaDocumentType: Record "Fattura Document Type";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        FatturaDocHelper.InsertFatturaDocumentTypeList();
        FilterFatturaDocumentTypeNoDefaultValues(FatturaDocumentType);
        FatturaDocumentType.FindSet();
        FatturaDocumentType.Next(LibraryRandom.RandIntInRange(1, 5));
        exit(FatturaDocumentType."No.");
    end;

    local procedure FilterFatturaDocumentTypeNoDefaultValues(var FatturaDocumentType: Record "Fattura Document Type")
    begin
        FatturaDocumentType.SetRange(Invoice, false);
        FatturaDocumentType.SetRange("Credit Memo", false);
        FatturaDocumentType.SetRange("Self-Billing", false);
        FatturaDocumentType.SetRange(Prepayment, false);
    end;

    local procedure VerifyTipoDocumento(ServerFileName: Text[250]; ExpectedElementValue: Text)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        FileManagement: Codeunit "File Management";
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento/TipoDocumento');
        Assert.AreEqual(ExpectedElementValue, TempXMLBuffer.Value,
          StrSubstNo(UnexpectedElementValueErr, TempXMLBuffer.GetElementName, ExpectedElementValue, TempXMLBuffer.Value));
        FileManagement.DeleteServerFile(ServerFileName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

