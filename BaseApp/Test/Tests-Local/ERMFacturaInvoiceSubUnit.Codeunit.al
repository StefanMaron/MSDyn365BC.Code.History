codeunit 144513 "ERM FacturaInvoiceSubUnit"
{
    // // [FEATURE] [Factura-Invoice] [Proforma-Invoice] [Report]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryVATLedger: Codeunit "Library - VAT Ledger";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRUReports: Codeunit "Library RU Reports";
        Assert: Codeunit Assert;
        SalesDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
        IsInitialized: Boolean;
        SalesVATLedgerKPPErr: Label 'Sales VAT Ledger Line incorrect Reg. Reason Code';

    [Test]
    [Scope('OnPrem')]
    procedure UnpostedSalesFactura()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO] Export REP 12411 "Order Factura-Invoice (A)" for open sales invoice

        // [GIVEN] Company address with "Post Code" = "A", County = "B", City = "C", "Address" = "D", "Address 2" = "E"
        // [GIVEN] Sales invoice for customer with "Post Code" = "F", County = "G", City = "H", "Address" = "I", "Address 2" = "J"
        CreateCustomerAndInvoice(SalesHeader, Customer, ShipToAddress);

        // [WHEN] Print REP 12411 "Order Factura-Invoice (A)"
        FacturaInvoiceExcelExport(SalesHeader, false);

        // [THEN] Exported factura field "2a" (seller address) = "A, B, C, D, E"
        // [THEN] Exported factura field "6a" (buyer address) = "F, G, H, I, J"
        VerifyFacturaReportHeader(Customer."No.");
        VerifyAddressKPPCode(Customer, ShipToAddress, ShipToAddress."KPP Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesFactura()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // [SCENARIO] Export REP 12418 "Posted Factura-Invoice (A)" for posted sales invoice
        CreateCustomerAndInvoice(SalesHeader, Customer, ShipToAddress);

        // [GIVEN] Company address with "Post Code" = "A", County = "B", City = "C", "Address" = "D", "Address 2" = "E"
        // [GIVEN] Posted sales invoice for customer with "Post Code" = "F", County = "G", City = "H", "Address" = "I", "Address 2" = "J"
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Print REP 12418 "Posted Factura-Invoice (A)"
        PostedFacturaInvoiceExcelExport(DocumentNo);
        VerifyAddressKPPCode(Customer, ShipToAddress, ShipToAddress."KPP Code");

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), Customer."No.");

        // [THEN] Exported factura field "2a" (seller address) = "A, B, C, D, E"
        // [THEN] Exported factura field "6a" (buyer address) = "F, G, H, I, J"
        VerifyFacturaReportHeader(Customer."No.");
        VerifyVATLedgerKPPCode(VATLedgerCode, ShipToAddress."KPP Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualKPPCode()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        KPPCode: Code[10];
    begin
        // Manually filled KPP Code
        CreateCustomerAndInvoice(SalesHeader, Customer, ShipToAddress);
        KPPCode :=
          LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("KPP Code"), DATABASE::"Sales Header");
        SetManualKPPCode(SalesHeader, KPPCode);

        FacturaInvoiceExcelExport(SalesHeader, false);
        VerifyAddressKPPCode(Customer, ShipToAddress, KPPCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocKPPCode()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // Copy Document KPP Code check
        CreateCustomerAndInvoice(SalesHeader, Customer, ShipToAddress);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", DocumentNo, true, false);
        FindSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.");
        UpdateSalesHeaderAddSheet(SalesHeader, CalcDate('<1D>', WorkDate()), WorkDate(), true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        FacturaInvoiceExcelExport(SalesHeader, false);
        FindSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), Customer."No.");
        LibrarySales.CreateSalesVATLedgerAddSheet(VATLedgerCode);
        VerifyVATLedgerKPPCode(VATLedgerCode, ShipToAddress."KPP Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketOrderKPPCode()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Create Sales Order from Blanket Order. Verify KPP Code.
        VerifyKPPCodeBlanketQuoteOrder(SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteKPPCode()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Create Sales Order from Sales Quote. Verify KPP Code.
        VerifyKPPCodeBlanketQuoteOrder(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceProformaBankPaymentDetails()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [GIVEN] Unposted Sales Invoice
        CreateCustomerAndInvoice(SalesHeader, Customer, ShipToAddress);

        // [WHEN] Print REP12409 "Order Proforma-Invoice (A)"
        FacturaInvoiceExcelExport(SalesHeader, true);

        // [THEN] Exported Proforma has correct Company Bank Payment details
        VerifyProformaBankPaymentSection;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        Clear(LibraryReportValidation);

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        UpdateStockOutWarning;
        UpdateCompanyInformation;
        IsInitialized := true;
    end;

    local procedure CreateCustomerWithSubUnit(var Customer: Record Customer; var ShipToAddress1: Record "Ship-to Address")
    begin
        LibrarySales.CreateCustomer(Customer);
        with Customer do begin
            Address := LibraryUtility.GenerateGUID();
            "Address 2" := LibraryUtility.GenerateGUID();
            "KPP Code" := GenerateKPPCode;
            County := LibraryUtility.GenerateGUID();
            Modify(true);
            AddShipToAddress("No.", ShipToAddress1);
        end;
    end;

    local procedure GenerateKPPCode(): Code[10]
    var
        Customer: Record Customer;
    begin
        exit(
          LibraryUtility.GenerateRandomCode(Customer.FieldNo("KPP Code"), DATABASE::Customer));
    end;

    local procedure AddShipToAddress(CustomerNo: Code[20]; var ShipToAddress: Record "Ship-to Address")
    begin
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        ShipToAddress.Address := LibraryUtility.GenerateGUID();
        ShipToAddress."Address 2" := LibraryUtility.GenerateGUID();
        ShipToAddress.County := LibraryUtility.GenerateGUID();
        ShipToAddress."KPP Code" := GenerateKPPCode;
        ShipToAddress.Modify(true);
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CustomerNo: Code[20]; ShipToCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemNoWithTariff, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(5));
        SalesLine.Modify(true);
        SalesHeader.Validate("Ship-to Code", ShipToCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate(Name, LibraryUtility.GenerateGUID());
        CountryRegion.Validate("Local Country/Region Code", CountryRegion.Code);
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateItemNoWithTariff(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        with Item do begin
            Validate(Description, CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Description), 0), 1, MaxStrLen(Description)));
            Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
            Validate("Tariff No.", CreateTariffNo);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateTariffNo(): Code[20]
    var
        TariffNumber: Record "Tariff Number";
    begin
        with TariffNumber do begin
            Init();
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Tariff Number");
            Description := LibraryUtility.GenerateGUID();
            Insert();
            exit("No.");
        end;
    end;

    local procedure FacturaInvoiceExcelExport(SalesHeader: Record "Sales Header"; IsProforma: Boolean) FileName: Text
    var
        OrderFacturaInvoice: Report "Order Factura-Invoice (A)";
    begin
        LibraryReportValidation.SetFileName(SalesHeader."No.");
        FileName := LibraryReportValidation.GetFileName;
        Commit();
        SalesHeader.SetRange("No.", SalesHeader."No.");
        OrderFacturaInvoice.SetTableView(SalesHeader);
        OrderFacturaInvoice.InitializeRequest(1, 1, false, false, IsProforma);
        OrderFacturaInvoice.SetFileNameSilent(FileName);
        OrderFacturaInvoice.UseRequestPage(false);
        OrderFacturaInvoice.Run();
    end;

    local procedure PostedFacturaInvoiceExcelExport(DocumentNo: Code[20]) FileName: Text
    var
        SalesInvHeader: Record "Sales Invoice Header";
        PostedFacturaInvoice: Report "Posted Factura-Invoice (A)";
    begin
        LibraryReportValidation.SetFileName(DocumentNo);
        FileName := LibraryReportValidation.GetFileName;
        Commit();
        SalesInvHeader.SetRange("No.", DocumentNo);
        PostedFacturaInvoice.SetTableView(SalesInvHeader);
        PostedFacturaInvoice.SetFileNameSilent(FileName);
        PostedFacturaInvoice.UseRequestPage(false);
        PostedFacturaInvoice.Run();
    end;

    local procedure CreateCustomerAndInvoice(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var ShipToAddress: Record "Ship-to Address")
    begin
        Initialize();
        CreateCustomerWithSubUnit(Customer, ShipToAddress);
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", ShipToAddress.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure SetManualKPPCode(var SalesHeader: Record "Sales Header"; KPPCode: Code[10])
    begin
        SalesHeader."KPP Code" := KPPCode;
        SalesHeader.Modify();
    end;

    local procedure FindSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("No.", DocumentNo);
        SalesHeader.FindFirst();
    end;

    local procedure UpdateStockOutWarning()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        with SalesReceivablesSetup do begin
            Get();
            "Stockout Warning" := false;
            Modify(true);
        end;
    end;

    local procedure UpdateSalesHeaderAddSheet(var SalesHeader: Record "Sales Header"; PostingDate: Date; CorrectedDocDate: Date; AddVATLedger: Boolean)
    begin
        SalesHeader."Posting Date" := PostingDate;
        SalesHeader."Additional VAT Ledger Sheet" := AddVATLedger;
        SalesHeader."Corrected Document Date" := CorrectedDocDate;
        SalesHeader.Modify(true);
    end;

    local procedure UpdateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        with CompanyInformation do begin
            Get();
            "Bank Name" := LibraryUtility.GenerateGUID();
            "Bank City" := LibraryUtility.GenerateGUID();
            "VAT Registration No." := LibraryUtility.GenerateGUID();
            "KPP Code" := LibraryUtility.GenerateGUID();
            "Full Name" := LibraryUtility.GenerateGUID();
            "Bank Branch No." := LibraryUtility.GenerateGUID();
            "Bank BIC" := LibraryUtility.GenerateGUID();
            "Bank Corresp. Account No." := LibraryUtility.GenerateGUID();
            "Bank Account No." := LibraryUtility.GenerateGUID();
            "Country/Region Code" := LibraryVATLedger.MockCountryEAEU;
            Modify();
        end;
        LibraryRUReports.UpdateCompanyAddress;
    end;

    local procedure FormatAmount(DecimalValue: Decimal): Text
    begin
        exit(Format(DecimalValue, 0, '<Sign><Integer Thousand><Decimal,3><Filler Character,0>'));
    end;

    local procedure VerifyAddressKPPCode(Customer: Record Customer; ShipToAddress: Record "Ship-to Address"; ShipToKPPCode: Code[10])
    var
        LocalReportMgt: Codeunit "Local Report Management";
        FileName: Text;
    begin
        FileName := LibraryReportValidation.GetFileName;
        with ShipToAddress do
            LibraryRUReports.VerifyFactura_ConsigneeAndAddress(
              FileName,
              LocalReportMgt.GetShipToAddrName(Customer."No.", Code, Name, "Name 2") + '  ' +
              LocalReportMgt.GetFullAddr("Post Code", City, Address, "Address 2", '', County));
        LibraryRUReports.VerifyFactura_BuyerINN(FileName, Customer."VAT Registration No." + ' / ' + ShipToKPPCode);
    end;

    local procedure VerifyVATLedgerKPPCode(VATLedgerCode: Code[20]; KPPCode: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        with VATLedgerLine do begin
            SetRange(Code, VATLedgerCode);
            FindSet();
            repeat
                Assert.AreEqual(KPPCode, "Reg. Reason Code", SalesVATLedgerKPPErr);
            until Next = 0;
        end;
    end;

    local procedure VerifyKPPCodeBlanketQuoteOrder(DocType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        ERMVATTool: Codeunit "ERM VAT Tool - Helper";
    begin
        Initialize();
        CreateCustomerWithSubUnit(Customer, ShipToAddress);
        CreateSalesDoc(SalesHeader, DocType, Customer."No.", ShipToAddress.Code);
        ERMVATTool.MakeOrderSales(SalesHeader, SalesOrderHeader);

        Assert.AreEqual(ShipToAddress."KPP Code", SalesOrderHeader."KPP Code", SalesVATLedgerKPPErr);
    end;

    local procedure VerifyProformaBankPaymentSection()
    var
        CompanyInformation: Record "Company Information";
        LocalReportManagement: Codeunit "Local Report Management";
    begin
        with CompanyInformation do begin
            Get();
            LibraryReportValidation.VerifyCellValueByRef('Y', 30, 1, "Bank Name"); // BankName
            LibraryReportValidation.VerifyCellValueByRef('Y', 31, 1, "Bank City"); // BankCity
            LibraryReportValidation.VerifyCellValueByRef('AE', 32, 1, "VAT Registration No."); // ComapnyINN
            LibraryReportValidation.VerifyCellValueByRef('BH', 32, 1, "KPP Code"); // ComapnyKPP
            LibraryReportValidation.VerifyCellValueByRef('Y', 33, 1, LocalReportManagement.GetCompanyName()); // ComapnyName
            LibraryReportValidation.VerifyCellValueByRef('Y', 34, 1, "Bank Branch No."); // BankBranchNo
            LibraryReportValidation.VerifyCellValueByRef('CR', 30, 1, "Bank BIC"); // BankBIC
            LibraryReportValidation.VerifyCellValueByRef('CR', 31, 1, "Bank Corresp. Account No."); // BankCorespAccNo
            LibraryReportValidation.VerifyCellValueByRef('CR', 33, 1, "Bank Account No."); // BankAccountNo
        end;
    end;

    local procedure VerifySalesLineColumns(LineNo: Integer; ItemNo: Code[20]; Qty: Text; UnitPrice: Text; Amount: Text; VATPct: Text; VATAmt: Text; AmtInclVAT: Text; CountryCode: Code[10]; CDNo: Code[30])
    var
        Item: Record Item;
        Offset: Integer;
        FileName: Text;
    begin
        Offset := LineNo - 22;
        Item.Get(ItemNo);
        FileName := LibraryReportValidation.GetFileName;
        LibraryRUReports.VerifyFactura_LineNo(FileName, '1', 0);
        LibraryRUReports.VerifyFactura_ItemNo(FileName, Item.Description, 0);
        LibraryRUReports.VerifyFactura_TariffNo(FileName, Item."Tariff No.", 0);
        LibraryRUReports.VerifyFactura_Qty(FileName, Qty, Offset);
        LibraryRUReports.VerifyFactura_Price(FileName, UnitPrice, Offset);
        LibraryRUReports.VerifyFactura_Amount(FileName, Amount, Offset);
        LibraryRUReports.VerifyFactura_VATPct(FileName, VATPct, Offset);
        LibraryRUReports.VerifyFactura_VATAmount(FileName, VATAmt, Offset);
        LibraryRUReports.VerifyFactura_AmountInclVAT(FileName, AmtInclVAT, Offset);
        LibraryRUReports.VerifyFactura_CountryCode(FileName, CountryCode, Offset);
        LibraryRUReports.VerifyFactura_GTD(FileName, CDNo, Offset);
    end;

    local procedure VerifyFacturaReportHeader(CustomerNo: Code[20])
    var
        CompanyInformation: Record "Company Information";
        LocalReportMgt: Codeunit "Local Report Management";
        FileName: Text;
    begin
        FileName := LibraryReportValidation.GetFileName;
        LibraryRUReports.VerifyFactura_SellerName(FileName, LocalReportMgt.GetCompanyName());
        LibraryRUReports.VerifyFactura_SellerAddress(FileName, LocalReportMgt.GetLegalAddress);
        CompanyInformation.Get();
        LibraryRUReports.VerifyFactura_SellerINN(
          FileName, CompanyInformation."VAT Registration No." + ' / ' + CompanyInformation."KPP Code");
        LibraryRUReports.VerifyFactura_BuyerName(FileName, LocalReportMgt.GetCustName(CustomerNo));
        LibraryRUReports.VerifyFactura_BuyerAddress(FileName, LibraryRUReports.GetCustomerFullAddress(CustomerNo));
    end;
}

