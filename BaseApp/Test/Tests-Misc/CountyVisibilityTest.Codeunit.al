codeunit 134449 "County Visibility Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Address] [County] [UI]
    end;

    var
        CountryWithCounty: Record "Country/Region";
        CountryWithoutCounty: Record "Country/Region";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        CountyVisibleTxt: Label 'County field %1 should be visible';
        CountyNotVisibleTxt: Label 'County field %1 should not be visible';
        CountyTxt: Label 'County';

    [Test]
    [HandlerFunctions('TemplatePageHandler')]
    [Scope('OnPrem')]
    procedure CustomerCardCountyVisibility()
    var
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        CustomerCard.OpenNew();
        CustomerCard."Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(CustomerCard.County.Visible(), StrSubstNo(CountyNotVisibleTxt, 'County'));
        CustomerCard."Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(CustomerCard.County.Visible(), StrSubstNo(CountyVisibleTxt, 'County'));
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('TemplatePageHandler')]
    [Scope('OnPrem')]
    procedure VendorCardCountyVisibility()
    var
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();

        VendorCard.OpenNew();
        VendorCard."Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(VendorCard.County.Visible(), StrSubstNo(CountyNotVisibleTxt, 'County'));
        VendorCard."Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(VendorCard.County.Visible(), StrSubstNo(CountyVisibleTxt, 'County'));
        VendorCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceCardCountyVisibility()
    var
        ResourceCard: TestPage "Resource Card";
    begin
        Initialize();

        ResourceCard.OpenNew();
        ResourceCard."Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(ResourceCard.County.Visible(), StrSubstNo(CountyNotVisibleTxt, 'County'));
        ResourceCard."Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(ResourceCard.County.Visible(), StrSubstNo(CountyVisibleTxt, 'County'));
        ResourceCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobCardCountyVisibility()
    var
        JobCard: TestPage "Job Card";
    begin
        Initialize();

        JobCard.OpenNew();
        JobCard."Bill-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(JobCard."Bill-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'County'));
        JobCard."Bill-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(JobCard."Bill-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'County'));
        JobCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeCardCountyVisibility()
    var
        EmployeeCard: TestPage "Employee Card";
    begin
        Initialize();

        EmployeeCard.OpenNew();
        EmployeeCard."Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(EmployeeCard.County.Visible(), StrSubstNo(CountyNotVisibleTxt, 'County'));
        EmployeeCard."Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(EmployeeCard.County.Visible(), StrSubstNo(CountyVisibleTxt, 'County'));
        EmployeeCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderCountyVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);

        SalesOrder.OpenNew();
        SalesOrder."Sell-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(SalesOrder."Sell-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Sell-to County'));
        SalesOrder."Sell-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(SalesOrder."Sell-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Sell-to County'));

        SalesOrder.BillToOptions.Value := 'Another Customer';
        SalesOrder."Bill-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(SalesOrder."Bill-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Bill-to County'));
        SalesOrder."Bill-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(SalesOrder."Bill-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Bill-to County'));

        SalesOrder.ShippingOptions.Value := 'Custom Address';
        SalesOrder."Ship-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(SalesOrder."Ship-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Ship-to County'));
        SalesOrder."Ship-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(SalesOrder."Ship-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Ship-to County'));
        SalesOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteCountyVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote, '', '', 1, '', 0D);

        SalesQuote.OpenNew();
        SalesQuote."Sell-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(SalesQuote."Sell-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Sell-to County'));
        SalesQuote."Sell-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(SalesQuote."Sell-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Sell-to County'));

        SalesQuote.BillToOptions.Value := 'Another Customer';
        SalesQuote."Bill-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(SalesQuote."Bill-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Bill-to County'));
        SalesQuote."Bill-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(SalesQuote."Bill-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Bill-to County'));

        SalesQuote.ShippingOptions.Value := 'Custom Address';
        SalesQuote."Ship-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(SalesQuote."Ship-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Ship-to County'));
        SalesQuote."Ship-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(SalesQuote."Ship-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Ship-to County'));
        SalesQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceCountryVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '', '', 1, '', 0D);

        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(SalesInvoice."Sell-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Sell-to County'));
        SalesInvoice."Sell-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(SalesInvoice."Sell-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Sell-to County'));

        SalesInvoice.BillToOptions.Value := 'Another Customer';
        SalesInvoice."Bill-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(SalesInvoice."Bill-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Bill-to County'));
        SalesInvoice."Bill-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(SalesInvoice."Bill-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Bill-to County'));

        SalesInvoice.ShippingOptions.Value := 'Custom Address';
        SalesInvoice."Ship-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(SalesInvoice."Ship-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Ship-to County'));
        SalesInvoice."Ship-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(SalesInvoice."Ship-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Ship-to County'));
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoCountyVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '', '', 1, '', 0D);

        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(SalesCreditMemo."Sell-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Sell-to County'));
        SalesCreditMemo."Sell-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(SalesCreditMemo."Sell-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Sell-to County'));

        SalesCreditMemo."Bill-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(SalesCreditMemo."Bill-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Bill-to County'));
        SalesCreditMemo."Bill-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(SalesCreditMemo."Bill-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Bill-to County'));
        SalesCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderCountyVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '', '', 1, '', 0D);

        SalesReturnOrder.OpenNew();
        SalesReturnOrder."Sell-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(SalesReturnOrder."Sell-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Sell-to County'));
        SalesReturnOrder."Sell-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(SalesReturnOrder."Sell-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Sell-to County'));

        SalesReturnOrder."Bill-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(SalesReturnOrder."Bill-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Bill-to County'));
        SalesReturnOrder."Bill-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(SalesReturnOrder."Bill-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Bill-to County'));

        SalesReturnOrder."Ship-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(SalesReturnOrder."Ship-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Ship-to County'));
        SalesReturnOrder."Ship-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(SalesReturnOrder."Ship-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Ship-to County'));
        SalesReturnOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentSellToCountyNotVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);
        SalesHeader."Sell-to Country/Region Code" := CountryWithoutCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentHeader.FindFirst();

        PostedSalesShipment.OpenView();
        PostedSalesShipment.GotoRecord(SalesShipmentHeader);
        Assert.IsFalse(PostedSalesShipment."Sell-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Sell-to County'));
        PostedSalesShipment.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentBillToCountyNotVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);
        SalesHeader."Bill-to Country/Region Code" := CountryWithoutCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesShipmentHeader.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        SalesShipmentHeader.FindFirst();

        PostedSalesShipment.OpenView();
        PostedSalesShipment.GotoRecord(SalesShipmentHeader);
        Assert.IsFalse(PostedSalesShipment."Bill-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Bill-to County'));
        PostedSalesShipment.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentSellToCountyVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);
        SalesHeader."Sell-to Country/Region Code" := CountryWithCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentHeader.FindFirst();

        PostedSalesShipment.OpenView();
        PostedSalesShipment.GotoRecord(SalesShipmentHeader);
        Assert.IsFalse(PostedSalesShipment."Sell-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Sell-to County'));
        PostedSalesShipment.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentBillToCountyVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);
        SalesHeader."Bill-to Country/Region Code" := CountryWithCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesShipmentHeader.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        SalesShipmentHeader.FindFirst();

        PostedSalesShipment.OpenView();
        PostedSalesShipment.GotoRecord(SalesShipmentHeader);
        Assert.IsFalse(PostedSalesShipment."Bill-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Bill-to County'));
        PostedSalesShipment.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceSellToCountyNotVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);
        SalesHeader."Sell-to Country/Region Code" := CountryWithoutCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst();

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        Assert.IsFalse(PostedSalesInvoice."Sell-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Sell-to County'));
        PostedSalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceBillToCountyNotVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);
        SalesHeader."Bill-to Country/Region Code" := CountryWithoutCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        SalesInvoiceHeader.FindFirst();

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        Assert.IsFalse(PostedSalesInvoice."Bill-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Bill-to County'));
        PostedSalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceSellToCountyVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);
        SalesHeader."Sell-to Country/Region Code" := CountryWithCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst();

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        Assert.IsFalse(PostedSalesInvoice."Sell-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Sell-to County'));
        PostedSalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceBillToCountyVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);
        SalesHeader."Bill-to Country/Region Code" := CountryWithCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        SalesInvoiceHeader.FindFirst();

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        Assert.IsFalse(PostedSalesInvoice."Bill-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Bill-to County'));
        PostedSalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoSellToCountyNotVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '', '', 1, '', 0D);
        SalesHeader."Sell-to Country/Region Code" := CountryWithoutCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.GotoRecord(SalesCrMemoHeader);
        Assert.IsFalse(PostedSalesCreditMemo."Sell-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Sell-to County'));
        PostedSalesCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoBillToCountyNotVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '', '', 1, '', 0D);
        SalesHeader."Bill-to Country/Region Code" := CountryWithoutCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesCrMemoHeader.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        SalesCrMemoHeader.FindFirst();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.GotoRecord(SalesCrMemoHeader);
        Assert.IsFalse(PostedSalesCreditMemo."Bill-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Bill-to County'));
        PostedSalesCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoSellToCountyVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '', '', 1, '', 0D);
        SalesHeader."Sell-to Country/Region Code" := CountryWithCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.GotoRecord(SalesCrMemoHeader);
        Assert.IsFalse(PostedSalesCreditMemo."Sell-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Sell-to County'));
        PostedSalesCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoBillToCountyVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '', '', 1, '', 0D);
        SalesHeader."Bill-to Country/Region Code" := CountryWithCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesCrMemoHeader.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        SalesCrMemoHeader.FindFirst();

        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.GotoRecord(SalesCrMemoHeader);
        Assert.IsFalse(PostedSalesCreditMemo."Bill-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Bill-to County'));
        PostedSalesCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptSellToCountyNotVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReceiptHeader: Record "Return Receipt Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '', '', 1, '', 0D);
        SalesHeader."Sell-to Country/Region Code" := CountryWithoutCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ReturnReceiptHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        ReturnReceiptHeader.FindFirst();

        PostedReturnReceipt.OpenView();
        PostedReturnReceipt.GotoRecord(ReturnReceiptHeader);
        Assert.IsFalse(PostedReturnReceipt."Sell-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Sell-to County'));
        PostedReturnReceipt.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptBillToCountyNotVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReceiptHeader: Record "Return Receipt Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '', '', 1, '', 0D);
        SalesHeader."Bill-to Country/Region Code" := CountryWithoutCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ReturnReceiptHeader.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        ReturnReceiptHeader.FindFirst();

        PostedReturnReceipt.OpenView();
        PostedReturnReceipt.GotoRecord(ReturnReceiptHeader);
        Assert.IsFalse(PostedReturnReceipt."Bill-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Bill-to County'));
        PostedReturnReceipt.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptSellToCountyVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReceiptHeader: Record "Return Receipt Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '', '', 1, '', 0D);
        SalesHeader."Sell-to Country/Region Code" := CountryWithCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ReturnReceiptHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        ReturnReceiptHeader.FindFirst();

        PostedReturnReceipt.OpenView();
        PostedReturnReceipt.GotoRecord(ReturnReceiptHeader);
        Assert.IsFalse(PostedReturnReceipt."Sell-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Sell-to County'));
        PostedReturnReceipt.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptBillToCountyVisible()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReceiptHeader: Record "Return Receipt Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '', '', 1, '', 0D);
        SalesHeader."Bill-to Country/Region Code" := CountryWithCounty.Code;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ReturnReceiptHeader.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        ReturnReceiptHeader.FindFirst();

        PostedReturnReceipt.OpenView();
        PostedReturnReceipt.GotoRecord(ReturnReceiptHeader);
        Assert.IsFalse(PostedReturnReceipt."Bill-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Bill-to County'));
        PostedReturnReceipt.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderCountyVisibility()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', '', 1, '', 0D);

        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(PurchaseOrder."Buy-from County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Buy-from County'));
        PurchaseOrder."Buy-from Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(PurchaseOrder."Buy-from County".Visible(), StrSubstNo(CountyVisibleTxt, 'Buy-from County'));

        PurchaseOrder.PayToOptions.Value := 'Another Vendor';
        PurchaseOrder."Pay-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(PurchaseOrder."Pay-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Pay-to County'));
        PurchaseOrder."Pay-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(PurchaseOrder."Pay-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Pay-to County'));

        PurchaseOrder."Ship-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(PurchaseOrder."Ship-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Ship-to County'));
        PurchaseOrder."Ship-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(PurchaseOrder."Ship-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Ship-to County'));
        PurchaseOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteCountyVisibility()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Quote, '', '', 1, '', 0D);

        PurchaseQuote.OpenNew();
        PurchaseQuote."Buy-from Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(PurchaseQuote."Buy-from County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Buy-from County'));
        PurchaseQuote."Buy-from Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(PurchaseQuote."Buy-from County".Visible(), StrSubstNo(CountyVisibleTxt, 'Buy-from County'));

        PurchaseQuote.PayToOptions.Value := 'Another Vendor';
        PurchaseQuote."Pay-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(PurchaseQuote."Pay-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Pay-to County'));
        PurchaseQuote."Pay-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(PurchaseQuote."Pay-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Pay-to County'));

        PurchaseQuote."Ship-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(PurchaseQuote."Ship-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Ship-to County'));
        PurchaseQuote."Ship-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(PurchaseQuote."Ship-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Ship-to County'));
        PurchaseQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceCountyVisibility()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, '', '', 1, '', 0D);

        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(PurchaseInvoice."Buy-from County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Buy-from County'));
        PurchaseInvoice."Buy-from Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(PurchaseInvoice."Buy-from County".Visible(), StrSubstNo(CountyVisibleTxt, 'Buy-from County'));

        PurchaseInvoice.PayToOptions.Value := 'Another Vendor';
        PurchaseInvoice."Pay-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(PurchaseInvoice."Pay-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Pay-to County'));
        PurchaseInvoice."Pay-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(PurchaseInvoice."Pay-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Pay-to County'));
        PurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoCountyVisibility()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", '', '', 1, '', 0D);

        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(PurchaseCreditMemo."Buy-from County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Buy-from County'));
        PurchaseCreditMemo."Buy-from Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(PurchaseCreditMemo."Buy-from County".Visible(), StrSubstNo(CountyVisibleTxt, 'Buy-from County'));

        PurchaseCreditMemo."Pay-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(PurchaseCreditMemo."Pay-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Pay-to County'));
        PurchaseCreditMemo."Pay-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(PurchaseCreditMemo."Pay-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Pay-to County'));
        PurchaseCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderCountyVisibility()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '', '', 1, '', 0D);

        PurchaseReturnOrder.OpenNew();
        PurchaseReturnOrder."Buy-from Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(PurchaseReturnOrder."Buy-from County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Buy-from County'));
        PurchaseReturnOrder."Buy-from Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(PurchaseReturnOrder."Buy-from County".Visible(), StrSubstNo(CountyVisibleTxt, 'Buy-from County'));

        PurchaseReturnOrder."Pay-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(PurchaseReturnOrder."Pay-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Pay-to County'));
        PurchaseReturnOrder."Pay-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(PurchaseReturnOrder."Pay-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Pay-to County'));

        PurchaseReturnOrder."Ship-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(PurchaseReturnOrder."Ship-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Ship-to County'));
        PurchaseReturnOrder."Ship-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(PurchaseReturnOrder."Ship-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Ship-to County'));
        PurchaseReturnOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchReceiptBuyFromCountyNotVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', '', 1, '', 0D);
        PurchaseHeader."Buy-from Country/Region Code" := CountryWithoutCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchRcptHeader.FindFirst();

        PostedPurchaseReceipt.OpenView();
        PostedPurchaseReceipt.GotoRecord(PurchRcptHeader);
        Assert.IsFalse(PostedPurchaseReceipt."Buy-from County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Buy-from County'));
        PostedPurchaseReceipt.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchReceiptPayToCountyNotVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', '', 1, '', 0D);
        PurchaseHeader."Buy-from Country/Region Code" := CountryWithoutCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchRcptHeader.FindFirst();

        PostedPurchaseReceipt.OpenView();
        PostedPurchaseReceipt.GotoRecord(PurchRcptHeader);
        Assert.IsFalse(PostedPurchaseReceipt."Buy-from County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Buy-from County'));
        PostedPurchaseReceipt.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchReceiptBuyFromCountyVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', '', 1, '', 0D);
        PurchaseHeader."Buy-from Country/Region Code" := CountryWithCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchRcptHeader.FindFirst();

        PostedPurchaseReceipt.OpenView();
        PostedPurchaseReceipt.GotoRecord(PurchRcptHeader);
        Assert.IsFalse(PostedPurchaseReceipt."Buy-from County".Visible(), StrSubstNo(CountyVisibleTxt, 'Buy-from County'));
        PostedPurchaseReceipt.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchReceiptPayToCountyVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', '', 1, '', 0D);
        PurchaseHeader."Pay-to Country/Region Code" := CountryWithCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptHeader.SetRange("Pay-to Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        PurchRcptHeader.FindFirst();

        PostedPurchaseReceipt.OpenView();
        PostedPurchaseReceipt.GotoRecord(PurchRcptHeader);
        Assert.IsFalse(PostedPurchaseReceipt."Pay-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Pay-to County'));
        PostedPurchaseReceipt.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceBuyFromCountyNotVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', '', 1, '', 0D);
        PurchaseHeader."Buy-from Country/Region Code" := CountryWithoutCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchInvHeader.FindFirst();

        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        Assert.IsFalse(PostedPurchaseInvoice."Buy-from County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Buy-from County'));
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvoicePayToCountyNotVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', '', 1, '', 0D);
        PurchaseHeader."Pay-to Country/Region Code" := CountryWithoutCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.SetRange("Pay-to Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        PurchInvHeader.FindFirst();

        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        Assert.IsFalse(PostedPurchaseInvoice."Pay-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Pay-to County'));
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceBuyFromCountyVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', '', 1, '', 0D);
        PurchaseHeader."Buy-from Country/Region Code" := CountryWithCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchInvHeader.FindFirst();

        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        Assert.IsFalse(PostedPurchaseInvoice."Buy-from County".Visible(), StrSubstNo(CountyVisibleTxt, 'Buy-from County'));
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvoicePaylToCountyVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', '', 1, '', 0D);
        PurchaseHeader."Pay-to Country/Region Code" := CountryWithCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.SetRange("Pay-to Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        PurchInvHeader.FindFirst();

        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        Assert.IsFalse(PostedPurchaseInvoice."Pay-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Pay-to County'));
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoBuyFromCountyNotVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", '', '', 1, '', 0D);
        PurchaseHeader."Buy-from Country/Region Code" := CountryWithoutCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchCrMemoHdr.FindFirst();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.GotoRecord(PurchCrMemoHdr);
        Assert.IsFalse(PostedPurchaseCreditMemo."Buy-from County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Buy-from County'));
        PostedPurchaseCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoPayToCountyNotVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", '', '', 1, '', 0D);
        PurchaseHeader."Pay-to Country/Region Code" := CountryWithoutCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchCrMemoHdr.SetRange("Pay-to Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        PurchCrMemoHdr.FindFirst();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.GotoRecord(PurchCrMemoHdr);
        Assert.IsFalse(PostedPurchaseCreditMemo."Pay-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Pay-to County'));
        PostedPurchaseCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoBuyFromCountyVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", '', '', 1, '', 0D);
        PurchaseHeader."Buy-from Country/Region Code" := CountryWithCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchCrMemoHdr.FindFirst();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.GotoRecord(PurchCrMemoHdr);
        Assert.IsFalse(PostedPurchaseCreditMemo."Buy-from County".Visible(), StrSubstNo(CountyVisibleTxt, 'Buy-from County'));
        PostedPurchaseCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoPayToCountyVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", '', '', 1, '', 0D);
        PurchaseHeader."Pay-to Country/Region Code" := CountryWithCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchCrMemoHdr.SetRange("Pay-to Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        PurchCrMemoHdr.FindFirst();

        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.GotoRecord(PurchCrMemoHdr);
        Assert.IsFalse(PostedPurchaseCreditMemo."Pay-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Pay-to County'));
        PostedPurchaseCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedReturnShipmentBuyFromCountyNotVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '', '', 1, '', 0D);
        PurchaseHeader."Buy-from Country/Region Code" := CountryWithoutCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        ReturnShipmentHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        ReturnShipmentHeader.FindFirst();

        PostedReturnShipment.OpenView();
        PostedReturnShipment.GotoRecord(ReturnShipmentHeader);
        Assert.IsFalse(PostedReturnShipment."Buy-from County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Buy-from County'));
        PostedReturnShipment.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedReturnShipmentPayToCountyNotVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '', '', 1, '', 0D);
        PurchaseHeader."Pay-to Country/Region Code" := CountryWithoutCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        ReturnShipmentHeader.SetRange("Pay-to Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        ReturnShipmentHeader.FindFirst();

        PostedReturnShipment.OpenView();
        PostedReturnShipment.GotoRecord(ReturnShipmentHeader);
        Assert.IsFalse(PostedReturnShipment."Pay-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Pay-to County'));
        PostedReturnShipment.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedReturnShipmentBuyFromCountyVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '', '', 1, '', 0D);
        PurchaseHeader."Buy-from Country/Region Code" := CountryWithCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        ReturnShipmentHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        ReturnShipmentHeader.FindFirst();

        PostedReturnShipment.OpenView();
        PostedReturnShipment.GotoRecord(ReturnShipmentHeader);
        Assert.IsFalse(PostedReturnShipment."Buy-from County".Visible(), StrSubstNo(CountyVisibleTxt, 'Buy-from County'));
        PostedReturnShipment.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedReturnShipmentPayToCountyVisible()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '', '', 1, '', 0D);
        PurchaseHeader."Pay-to Country/Region Code" := CountryWithCounty.Code;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        ReturnShipmentHeader.SetRange("Pay-to Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        ReturnShipmentHeader.FindFirst();

        PostedReturnShipment.OpenView();
        PostedReturnShipment.GotoRecord(ReturnShipmentHeader);
        Assert.IsFalse(PostedReturnShipment."Pay-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Pay-to County'));
        PostedReturnShipment.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderCountyVisibility()
    var
        ServiceOrder: TestPage "Service Order";
    begin
        Initialize();

        ServiceOrder.OpenNew();
        ServiceOrder."Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(ServiceOrder.County.Visible(), StrSubstNo(CountyNotVisibleTxt, 'Sell-to County'));
        ServiceOrder."Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(ServiceOrder.County.Visible(), StrSubstNo(CountyVisibleTxt, 'Sell-to County'));

        ServiceOrder."Bill-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(ServiceOrder."Bill-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Bill-to County'));
        ServiceOrder."Bill-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(ServiceOrder."Bill-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Bill-to County'));

        ServiceOrder."Ship-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(ServiceOrder."Ship-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Ship-to County'));
        ServiceOrder."Ship-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(ServiceOrder."Ship-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Ship-to County'));
        ServiceOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceCountyVisibility()
    var
        ServiceInvoice: TestPage "Service Invoice";
    begin
        Initialize();

        ServiceInvoice.OpenNew();
        ServiceInvoice."Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(ServiceInvoice.County.Visible(), StrSubstNo(CountyNotVisibleTxt, 'Sell-to County'));
        ServiceInvoice."Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(ServiceInvoice.County.Visible(), StrSubstNo(CountyVisibleTxt, 'Sell-to County'));

        ServiceInvoice."Bill-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(ServiceInvoice."Bill-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Bill-to County'));
        ServiceInvoice."Bill-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(ServiceInvoice."Bill-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Bill-to County'));

        ServiceInvoice."Ship-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(ServiceInvoice."Ship-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Ship-to County'));
        ServiceInvoice."Ship-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(ServiceInvoice."Ship-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Ship-to County'));
        ServiceInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoCountyVisibility()
    var
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        Initialize();

        ServiceCreditMemo.OpenNew();
        ServiceCreditMemo."Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(ServiceCreditMemo.County.Visible(), StrSubstNo(CountyNotVisibleTxt, 'Sell-to County'));
        ServiceCreditMemo."Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(ServiceCreditMemo.County.Visible(), StrSubstNo(CountyVisibleTxt, 'Sell-to County'));

        ServiceCreditMemo."Bill-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(ServiceCreditMemo."Bill-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Bill-to County'));
        ServiceCreditMemo."Bill-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(ServiceCreditMemo."Bill-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Bill-to County'));

        ServiceCreditMemo."Ship-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(ServiceCreditMemo."Ship-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Ship-to County'));
        ServiceCreditMemo."Ship-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(ServiceCreditMemo."Ship-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Ship-to County'));
        ServiceCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceQuoteCountyVisibility()
    var
        ServiceQuote: TestPage "Service Quote";
    begin
        Initialize();

        ServiceQuote.OpenNew();
        ServiceQuote."Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(ServiceQuote.County.Visible(), StrSubstNo(CountyNotVisibleTxt, 'Sell-to County'));
        ServiceQuote."Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(ServiceQuote.County.Visible(), StrSubstNo(CountyVisibleTxt, 'Sell-to County'));

        ServiceQuote."Bill-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(ServiceQuote."Bill-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Bill-to County'));
        ServiceQuote."Bill-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(ServiceQuote."Bill-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Bill-to County'));

        ServiceQuote."Ship-to Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(ServiceQuote."Ship-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Ship-to County'));
        ServiceQuote."Ship-to Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(ServiceQuote."Ship-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Ship-to County'));
        ServiceQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUseCounty()
    var
        FormatAddress: Codeunit "Format Address";
    begin
        Initialize();

        Assert.IsFalse(FormatAddress.UseCounty(CountryWithoutCounty.Code), 'County is not used');
        Assert.IsTrue(FormatAddress.UseCounty(CountryWithCounty.Code), 'County is used');
    end;

    [Test]
    procedure ClearCountyInSalesHeaderAfterChangeCountryCode()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 413649] The fields "Bill-to County" and "Sell-to County" must be empty after validate country without county
        Initialize();

        SalesHeader.Init();
        SalesHeader.Validate("Sell-to Country/Region Code", CountryWithCounty.Code);
        SalesHeader.Validate("Sell-to County", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Bill-to Country/Region Code", CountryWithCounty.Code);
        SalesHeader.Validate("Bill-to County", LibraryUtility.GenerateGUID());

        SalesHeader.Validate("Sell-to Country/Region Code", CountryWithoutCounty.Code);
        SalesHeader.Validate("Bill-to Country/Region Code", CountryWithoutCounty.Code);

        SalesHeader.TestField("Sell-to County", '');
        SalesHeader.TestField("Bill-to County", '');
    end;

    [Test]
    procedure ClearCountyInPurchaseHeaderAfterChangeCountryCode()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 413649] The fields "Pay-to County" and "Buy-from County" must be empty after validate country without county
        Initialize();

        PurchaseHeader.Init();
        PurchaseHeader.Validate("Pay-to Country/Region Code", CountryWithCounty.Code);
        PurchaseHeader.Validate("Pay-to County", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Buy-from Country/Region Code", CountryWithCounty.Code);
        PurchaseHeader.Validate("Buy-from County", LibraryUtility.GenerateGUID());

        PurchaseHeader.Validate("Pay-to Country/Region Code", CountryWithoutCounty.Code);
        PurchaseHeader.Validate("Buy-from Country/Region Code", CountryWithoutCounty.Code);

        PurchaseHeader.TestField("Pay-to County", '');
        PurchaseHeader.TestField("Buy-from County", '');
    end;

    [Test]
    procedure ClearCountyInServiceHeaderAfterChangeCountryCode()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 413649] The fields "County" and "Bill-to County" must be empty after validate country without county
        Initialize();

        ServiceHeader.Init();
        ServiceHeader.Validate("Country/Region Code", CountryWithCounty.Code);
        ServiceHeader.Validate(County, LibraryUtility.GenerateGUID());
        ServiceHeader.Validate("Bill-to Country/Region Code", CountryWithCounty.Code);
        ServiceHeader.Validate("Bill-to County", LibraryUtility.GenerateGUID());

        ServiceHeader.Validate("Country/Region Code", CountryWithoutCounty.Code);
        ServiceHeader.Validate("Bill-to Country/Region Code", CountryWithoutCounty.Code);

        ServiceHeader.TestField(County, '');
        ServiceHeader.TestField("Bill-to County", '');
    end;

    [Test]
    procedure CompanyInfoCountyVisibility()
    var
        CompanyInformation: TestPage "Company Information";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 413649] The fields "County" must be visible only if country uses county
        Initialize();

        CompanyInformation.OpenEdit();
        CompanyInformation."Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(CompanyInformation.County.Visible(), StrSubstNo(CountyNotVisibleTxt, 'County'));
        CompanyInformation."Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(CompanyInformation.County.Visible(), StrSubstNo(CountyVisibleTxt, 'County'));
        CompanyInformation.Close();
    end;

    [Test]
    procedure CustomerTemplateCountyVisibility()
    var
        CustomerTemplCard: TestPage "Customer Templ. Card";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 413649] The fields "County" must be visible only if country uses county
        Initialize();

        CustomerTemplCard.OpenNew();
        CustomerTemplCard."Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(CustomerTemplCard.County.Visible(), StrSubstNo(CountyNotVisibleTxt, 'County'));
        CustomerTemplCard."Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(CustomerTemplCard.County.Visible(), StrSubstNo(CountyVisibleTxt, 'County'));
        CustomerTemplCard.Close();
    end;

    [Test]
    procedure EmployeeTemplateCountyVisibility()
    var
        EmployeeTemplCard: TestPage "Employee Templ. Card";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 413649] The fields "County" must be visible only if country uses county
        Initialize();

        EmployeeTemplCard.OpenNew();
        EmployeeTemplCard."Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(EmployeeTemplCard.County.Visible(), StrSubstNo(CountyNotVisibleTxt, 'County'));
        EmployeeTemplCard."Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(EmployeeTemplCard.County.Visible(), StrSubstNo(CountyVisibleTxt, 'County'));
        EmployeeTemplCard.Close();
    end;

    [Test]
    procedure VendorTemplateCountyVisibility()
    var
        VendorTemplCard: TestPage "Vendor Templ. Card";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 413649] The fields "County" must be visible only if country uses county
        Initialize();

        VendorTemplCard.OpenNew();
        VendorTemplCard."Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(VendorTemplCard.County.Visible(), StrSubstNo(CountyNotVisibleTxt, 'County'));
        VendorTemplCard."Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(VendorTemplCard.County.Visible(), StrSubstNo(CountyVisibleTxt, 'County'));
        VendorTemplCard.Close();
    end;

    [Test]
    procedure OrderAddressCountyVisibility()
    var
        OrderAddress: TestPage "Order Address";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 413649] The fields "County" must be visible only if country uses county
        Initialize();

        OrderAddress.OpenNew();
        OrderAddress."Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(OrderAddress.County.Visible(), StrSubstNo(CountyNotVisibleTxt, 'County'));
        OrderAddress."Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(OrderAddress.County.Visible(), StrSubstNo(CountyVisibleTxt, 'County'));
        OrderAddress.Close();
    end;

    [Test]
    procedure ServiceItemCountyVisibility()
    var
        CustomerWithCounty: Record Customer;
        CustomerWithoutCounty: Record Customer;
        ServiceItemCard: TestPage "Service Item Card";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 413649] The fields "County" must be visible only if country uses county
        Initialize();

        // [GIVEN] Customer "C1" having country without county code
        LibrarySales.CreateCustomer(CustomerWithoutCounty);
        CustomerWithoutCounty.Validate("Country/Region Code", CountryWithoutCounty.Code);
        CustomerWithoutCounty.Modify();

        // [GIVEN] Customer "C2" having country with county code
        LibrarySales.CreateCustomer(CustomerWithCounty);
        CustomerWithCounty.Validate("Country/Region Code", CountryWithCounty.Code);
        CustomerWithCounty.Modify();

        ServiceItemCard.OpenNew();
        ServiceItemCard."Customer No.".Value := CustomerWithoutCounty."No.";
        Assert.IsFalse(ServiceItemCard.County.Visible(), StrSubstNo(CountyNotVisibleTxt, 'County'));
        ServiceItemCard."Customer No.".Value := CustomerWithCounty."No.";
        Assert.IsTrue(ServiceItemCard.County.Visible(), StrSubstNo(CountyVisibleTxt, 'County'));
        ServiceItemCard.Close();
    end;

    [Test]
    procedure CountyCaptionListPage()
    var
        CountyCaptionTestList: TestPage "County Caption Test List";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 413649] Field County with CaptionClass = '5,1,'... on the list page has caption "County"
        Initialize();

        CountyCaptionTestList.OpenView();
        Assert.AreEqual(CountyTxt, CountyCaptionTestList.County.Caption, 'Invalid caption');
        CountyCaptionTestList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderCountyVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [SCENARIO 464217] County/State Field Missing From Blanket Sales Order Page
        Initialize();

        // Create Blanket Sales Order
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order", '', '', 1, '', 0D);

        // [GIVEN] Open Blanket Sales Order Page and Verify visibility of fields
        BlanketSalesOrder.OpenNew();
        Assert.IsFalse(BlanketSalesOrder."Sell-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Sell-to County'));
        Assert.IsTrue(BlanketSalesOrder."Sell-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Sell-to County'));
        Assert.IsFalse(BlanketSalesOrder."Bill-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Bill-to County'));
        Assert.IsTrue(BlanketSalesOrder."Bill-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Bill-to County'));
        Assert.IsFalse(BlanketSalesOrder."Ship-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Ship-to County'));
        Assert.IsTrue(BlanketSalesOrder."Ship-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Ship-to County'));
        BlanketSalesOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderCountyVisibility()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [SCENARIO 464217] County/State Field Missing From Blanket Purchase Order Page
        Initialize();

        // [GIVEN] Create Blanket Purchase Order
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order", '', '', 1, '', 0D);

        // [GIVEN] Open Blanket Purchase Order Page and Verify visibility of fields
        BlanketPurchaseOrder.OpenNew();
        Assert.IsFalse(BlanketPurchaseOrder."Buy-from County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Buy-from County'));
        Assert.IsTrue(BlanketPurchaseOrder."Buy-from County".Visible(), StrSubstNo(CountyVisibleTxt, 'Buy-from County'));
        Assert.IsFalse(BlanketPurchaseOrder."Pay-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Pay-to County'));
        Assert.IsTrue(BlanketPurchaseOrder."Pay-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Pay-to County'));
        Assert.IsFalse(BlanketPurchaseOrder."Ship-to County".Visible(), StrSubstNo(CountyNotVisibleTxt, 'Ship-to County'));
        Assert.IsTrue(BlanketPurchaseOrder."Ship-to County".Visible(), StrSubstNo(CountyVisibleTxt, 'Ship-to County'));
        BlanketPurchaseOrder.Close();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"County Visibility Test");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"County Visibility Test");

        LibraryERM.CreateCountryRegion(CountryWithoutCounty);
        CountryWithoutCounty."Address Format" := CountryWithCounty."Address Format"::"City+Post Code";
        CountryWithoutCounty.Modify();

        LibraryERM.CreateCountryRegion(CountryWithCounty);
        CountryWithCounty."Address Format" := CountryWithCounty."Address Format"::"City+County+Post Code";
        CountryWithCounty.Modify();

        LibrarySales.SetPostedNoSeriesInSetup();
        LibrarySales.SetReturnOrderNoSeriesInSetup();
        LibraryPurchase.SetPostedNoSeriesInSetup();
        LibraryPurchase.SetReturnOrderNoSeriesInSetup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"County Visibility Test");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TemplatePageHandler(var ConfigTemplates: TestPage "Config Templates")
    begin
        ConfigTemplates.First();
        ConfigTemplates.OK().Invoke();
    end;
}

