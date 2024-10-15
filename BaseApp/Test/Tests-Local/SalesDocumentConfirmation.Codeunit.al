codeunit 144045 "Sales Document Confirmation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Customer: Record Customer;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        TestPaymentTxt: Label 'Test Payment';
        TestShipmentTxt: Label 'Test Shipment';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('OrderReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyOrderConfirmationReportTest()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize;

        // Create Sales Order
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        Commit();

        SalesHeader.SetRange("No.", SalesHeader."No.");
        REPORT.Run(REPORT::"Order Confirmation", true, false, SalesHeader);

        // Verify Footer in Report Order Confirmation
        VerifyReportData(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('QuoteReportRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyQuoteConfirmationReportTest()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize;

        // Create Sales Quote
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        Commit();

        SalesHeader.SetRange("No.", SalesHeader."No.");
        REPORT.Run(REPORT::"Sales - Quote", true, false, SalesHeader);

        // Verify Footer in Report Order Confirmation
        VerifyReportData(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ReturnOrderReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyReturnOrderConfirmationReportTest()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize;

        // Create Return Order
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", Customer."No.");
        Commit();

        SalesHeader.SetRange("No.", SalesHeader."No.");
        REPORT.Run(REPORT::"Return Order Confirmation", true, false, SalesHeader);

        // Verify Footer in Report Order Confirmation
        VerifyReportData(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('BlanketOrderReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyBlanketOrderConfirmationReportTest()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize;

        // Create Return Order
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Blanket Order", Customer."No.");
        Commit();

        SalesHeader.SetRange("No.", SalesHeader."No.");
        REPORT.Run(REPORT::"Blanket Sales Order", true, false, SalesHeader);

        // Verify Footer in Report Order Confirmation
        VerifyReportData(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('InvoiceReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostAndVerifyInvoiceConfirmationReportTest()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // Setup
        Initialize;

        // Create and Post Sales Invoice
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);
        Commit();

        SalesInvoiceHeader.SetRange("No.", DocumentNo);
        REPORT.Run(REPORT::"Sales - Invoice", true, false, SalesInvoiceHeader);

        // Verify Footer in Report Order Confirmation
        VerifyReportData(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('CreditMemoReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostAndVerifyCreditMemoConfirmationReportTest()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentNo: Code[20];
    begin
        // Setup
        Initialize;

        // Create and Post Sales Credit Memo
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);
        Commit();

        SalesCrMemoHeader.SetRange("No.", DocumentNo);
        REPORT.Run(REPORT::"Sales - Credit Memo", true, false, SalesCrMemoHeader);

        // Verify Footer in Report Order Confirmation
        VerifyReportData(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ShipmentReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostAndVerifyShipmentConfirmationReportTest()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // Setup
        Initialize;

        // Create and Post Sales Credit Memo
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Commit();

        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        REPORT.Run(REPORT::"Sales - Shipment", true, false, SalesShipmentHeader);

        // Verify Footer in Report Order Confirmation
        VerifyReportData(SalesHeader);
    end;

    local procedure Initialize()
    var
        PaymentTermsCode: Code[10];
        ShipmentMethodCode: Code[10];
    begin
        if not IsInitialized then begin
            IsInitialized := true;

            PaymentTermsCode := CreatePaymentTermCode;
            ShipmentMethodCode := CreateShipmentMethodCode;

            // Add Payment Term Translation
            CreatePaymentTermTranslation(PaymentTermsCode);

            // Add Shipment Term Translation
            CreateShipmentMethodTranslation(ShipmentMethodCode);

            LibraryERMCountryData.CreateGeneralPostingSetupData;
            LibraryERMCountryData.UpdateGeneralPostingSetup;

            // Create Customer
            CreateCustomer(PaymentTermsCode, ShipmentMethodCode);
        end;
    end;

    local procedure CreateShipmentMethodCode(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.Init();
        ShipmentMethod.Code := LibraryUtility.GenerateRandomCode(ShipmentMethod.FieldNo(Code), DATABASE::"Shipment Method");
        ShipmentMethod.Description := 'Test Shipment Method';
        ShipmentMethod.Insert();
        exit(ShipmentMethod.Code);
    end;

    local procedure CreatePaymentTermCode(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        exit(PaymentTerms.Code);
    end;

    [Normal]
    local procedure CreateCustomer(PaymentTerms: Code[10]; ShipmentMethod: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms);
        Customer.Validate("Shipment Method Code", ShipmentMethod);
        Customer.Modify();
    end;

    local procedure CreatePaymentTermTranslation(PaymentTerm: Code[10])
    var
        PaymentTermTranslation: Record "Payment Term Translation";
    begin
        PaymentTermTranslation.Init();
        PaymentTermTranslation.Validate("Payment Term", PaymentTerm);
        PaymentTermTranslation.Validate(Description, TestPaymentTxt);
        PaymentTermTranslation.Insert();
    end;

    local procedure CreateShipmentMethodTranslation(ShipmentMethod: Code[10])
    var
        ShipmentMethodTranslation: Record "Shipment Method Translation";
    begin
        ShipmentMethodTranslation.Init();
        ShipmentMethodTranslation.Validate("Shipment Method", ShipmentMethod);
        ShipmentMethodTranslation.Validate(Description, TestShipmentTxt);
        ShipmentMethodTranslation.Insert();
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Option; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OrderReportRequestPageHandler(var OrderConfirmation: TestRequestPage "Order Confirmation")
    begin
        OrderConfirmation.NoOfCopies.SetValue(0);
        OrderConfirmation.ShowInternalInfo.SetValue(false);
        OrderConfirmation.ArchiveDocument.SetValue(false);
        OrderConfirmation.LogInteraction.SetValue(true);
        OrderConfirmation.ShowAssemblyComponents.SetValue(false);

        OrderConfirmation.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure QuoteReportRequestPageHandler(var SalesQuote: TestRequestPage "Sales - Quote")
    begin
        SalesQuote.NoOfCopies.SetValue(0);
        SalesQuote.ShowInternalInfo.SetValue(false);
        SalesQuote.ArchiveDocument.SetValue(false);
        SalesQuote.LogInteraction.SetValue(true);

        SalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReturnOrderReportRequestPageHandler(var ReturnOrderConfirmation: TestRequestPage "Return Order Confirmation")
    begin
        ReturnOrderConfirmation.NoOfCopies.SetValue(0);
        ReturnOrderConfirmation.ShowInternalInfo.SetValue(false);
        ReturnOrderConfirmation.LogInteraction.SetValue(true);

        ReturnOrderConfirmation.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BlanketOrderReportRequestPageHandler(var BlanketSalesOrder: TestRequestPage "Blanket Sales Order")
    begin
        BlanketSalesOrder.NoOfCopies.SetValue(0);
        BlanketSalesOrder.ShowInternalInfo.SetValue(false);
        BlanketSalesOrder.ArchiveDocument.SetValue(false);
        BlanketSalesOrder.LogInteraction.SetValue(true);

        BlanketSalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvoiceReportRequestPageHandler(var SalesInvoice: TestRequestPage "Sales - Invoice")
    begin
        SalesInvoice.NoOfCopies.SetValue(0);
        SalesInvoice.ShowInternalInfo.SetValue(false);
        SalesInvoice.LogInteraction.SetValue(true);
        SalesInvoice.DisplayAsmInformation.SetValue(false);

        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreditMemoReportRequestPageHandler(var SalesCreditMemo: TestRequestPage "Sales - Credit Memo")
    begin
        SalesCreditMemo.NoOfCopies.SetValue(0);
        SalesCreditMemo.ShowInternalInfo.SetValue(false);
        SalesCreditMemo.LogInteraction.SetValue(true);

        SalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ShipmentReportRequestPageHandler(var SalesShipment: TestRequestPage "Sales - Shipment")
    begin
        SalesShipment.NoOfCopies.SetValue(0);
        SalesShipment.ShowInternalInfo.SetValue(false);
        SalesShipment.LogInteraction.SetValue(true);
        SalesShipment."Show Correction Lines".SetValue(false);
        SalesShipment.ShowLotSN.SetValue(false);

        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure VerifyReportData(SalesHeader: Record "Sales Header")
    begin
        // Verify the XML
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.GetNextRow;

        LibraryReportDataset.AssertCurrentRowValueEquals('FooterTxt1', Format(TestPaymentTxt));

        // Return Order and Credit Memo do not have Shipment Footer
        if (SalesHeader."Document Type" <> SalesHeader."Document Type"::"Return Order") and
           (SalesHeader."Document Type" <> SalesHeader."Document Type"::"Credit Memo")
        then
            LibraryReportDataset.AssertCurrentRowValueEquals('FooterTxt2', Format(TestShipmentTxt));
    end;
}

