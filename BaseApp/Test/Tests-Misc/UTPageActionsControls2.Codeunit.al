codeunit 134348 "UT Page Actions & Controls - 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UI]
    end;

    var
        Assert: Codeunit Assert;
        FilterHasBeenChangedErr: Label 'Filter has been changed.';
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPermissions: Codeunit "Library - Permissions";
        IsInitialized: Boolean;
        PageFieldVisibleErr: Label '%1 must be visible.';
        PageFieldEditableErr: Label '%1 must be editable.';
        CustomerCardTxt: Label 'Customer Card';
        VendorCardTxt: Label 'Vendor Card';

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicesDrillDowns()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        DetailedCustLedgEntries: TestPage "Detailed Cust. Ledg. Entries";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        PostedDocumentNo: array[3] of Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 315881] "Amount", "Amount Incl. VAT", "Remaining Amount" and "Closed" drilldown is possible on "Posted Sales Invoices" page
        Initialize();

        for Index := 1 to ArrayLen(PostedDocumentNo) do
            PostedDocumentNo[Index] := PostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        PostedSalesInvoices.OpenView();
        PostedSalesInvoices.FILTER.SetFilter("No.", GetDocNofilter(PostedDocumentNo));
        PostedSalesInvoices.Next();

        PostedSalesInvoice.Trap();
        PostedSalesInvoices.Amount.DrillDown();
        PostedSalesInvoice."No.".AssertEquals(PostedDocumentNo[2]);
        PostedSalesInvoice.Next();
        PostedSalesInvoice."No.".AssertEquals(PostedDocumentNo[1]);
        PostedSalesInvoice.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        PostedSalesInvoice.Trap();
        PostedSalesInvoices."Amount Including VAT".DrillDown();
        PostedSalesInvoice."No.".AssertEquals(PostedDocumentNo[2]);
        PostedSalesInvoice.Next();
        PostedSalesInvoice."No.".AssertEquals(PostedDocumentNo[1]);
        PostedSalesInvoice.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        DetailedCustLedgEntries.Trap();
        PostedSalesInvoices."Remaining Amount".DrillDown();
        DetailedCustLedgEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        CustomerLedgerEntries.Trap();
        PostedSalesInvoices.Closed.DrillDown();
        CustomerLedgerEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemosDrillDown()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        DetailedCustLedgEntries: TestPage "Detailed Cust. Ledg. Entries";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        PostedDocumentNo: array[3] of Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 315881] "Amount", "Amount Incl. VAT", "Remaining Amount" and "Closed" drilldown is possible on "Posted Sales Credit Memos" page
        Initialize();

        for Index := 1 to ArrayLen(PostedDocumentNo) do
            PostedDocumentNo[Index] := PostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        PostedSalesCreditMemos.OpenView();
        PostedSalesCreditMemos.FILTER.SetFilter("No.", GetDocNofilter(PostedDocumentNo));
        PostedSalesCreditMemos.Next();

        PostedSalesCreditMemo.Trap();
        PostedSalesCreditMemos.Amount.DrillDown();
        PostedSalesCreditMemo."No.".AssertEquals(PostedDocumentNo[2]);
        PostedSalesCreditMemo.Next();
        PostedSalesCreditMemo."No.".AssertEquals(PostedDocumentNo[1]);
        PostedSalesCreditMemo.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        PostedSalesCreditMemo.Trap();
        PostedSalesCreditMemos."Amount Including VAT".DrillDown();
        PostedSalesCreditMemo."No.".AssertEquals(PostedDocumentNo[2]);
        PostedSalesCreditMemo.Next();
        PostedSalesCreditMemo."No.".AssertEquals(PostedDocumentNo[1]);
        PostedSalesCreditMemo.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        DetailedCustLedgEntries.Trap();
        PostedSalesCreditMemos."Remaining Amount".DrillDown();
        DetailedCustLedgEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        CustomerLedgerEntries.Trap();
        PostedSalesCreditMemos.Paid.DrillDown();
        CustomerLedgerEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoicesDrillDowns()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        DetailedVendorLedgEntries: TestPage "Detailed Vendor Ledg. Entries";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PostedDocumentNo: array[3] of Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Purchases] [Invoice]
        // [SCENARIO 315881] "Amount", "Amount Incl. VAT", "Remaining Amount" and "Closed" drilldown is possible on "Posted Purchase Invoices" page
        Initialize();

        for Index := 1 to ArrayLen(PostedDocumentNo) do
            PostedDocumentNo[Index] := PostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        PostedPurchaseInvoices.OpenView();
        PostedPurchaseInvoices.FILTER.SetFilter("No.", GetDocNofilter(PostedDocumentNo));
        PostedPurchaseInvoices.Next();

        PostedPurchaseInvoice.Trap();
        PostedPurchaseInvoices.Amount.DrillDown();
        PostedPurchaseInvoice."No.".AssertEquals(PostedDocumentNo[2]);
        PostedPurchaseInvoice.Next();
        PostedPurchaseInvoice."No.".AssertEquals(PostedDocumentNo[1]);
        PostedPurchaseInvoice.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        PostedPurchaseInvoice.Trap();
        PostedPurchaseInvoices."Amount Including VAT".DrillDown();
        PostedPurchaseInvoice."No.".AssertEquals(PostedDocumentNo[2]);
        PostedPurchaseInvoice.Next();
        PostedPurchaseInvoice."No.".AssertEquals(PostedDocumentNo[1]);
        PostedPurchaseInvoice.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        DetailedVendorLedgEntries.Trap();
        PostedPurchaseInvoices."Remaining Amount".DrillDown();
        DetailedVendorLedgEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        VendorLedgerEntries.Trap();
        PostedPurchaseInvoices.Closed.DrillDown();
        VendorLedgerEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseCreditMemosDrillDown()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseCreditMemos: TestPage "Posted Purchase Credit Memos";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        DetailedVendorLedgEntries: TestPage "Detailed Vendor Ledg. Entries";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PostedDocumentNo: array[3] of Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Purchases] [Credit Memo]
        // [SCENARIO 315881]"Amount", "Amount Incl. VAT", "Remaining Amount" and "Closed" drilldown is possible on "Posted Purchase Credit Memos" page
        Initialize();

        for Index := 1 to ArrayLen(PostedDocumentNo) do
            PostedDocumentNo[Index] := PostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        PostedPurchaseCreditMemos.OpenView();
        PostedPurchaseCreditMemos.FILTER.SetFilter("No.", GetDocNofilter(PostedDocumentNo));
        PostedPurchaseCreditMemos.Next();

        PostedPurchaseCreditMemo.Trap();
        PostedPurchaseCreditMemos.Amount.DrillDown();
        PostedPurchaseCreditMemo."No.".AssertEquals(PostedDocumentNo[2]);
        PostedPurchaseCreditMemo.Next();
        PostedPurchaseCreditMemo."No.".AssertEquals(PostedDocumentNo[1]);
        PostedPurchaseCreditMemo.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        PostedPurchaseCreditMemo.Trap();
        PostedPurchaseCreditMemos."Amount Including VAT".DrillDown();
        PostedPurchaseCreditMemo."No.".AssertEquals(PostedDocumentNo[2]);
        PostedPurchaseCreditMemo.Next();
        PostedPurchaseCreditMemo."No.".AssertEquals(PostedDocumentNo[1]);
        PostedPurchaseCreditMemo.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        DetailedVendorLedgEntries.Trap();
        PostedPurchaseCreditMemos."Remaining Amount".DrillDown();
        DetailedVendorLedgEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        VendorLedgerEntries.Trap();
        PostedPurchaseCreditMemos.Paid.DrillDown();
        VendorLedgerEntries.Close();
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SepaSetupFieldSEPANonEuroExport()
    var
        GeneralLedgerSetup: TestPage "General Ledger Setup";
    begin
        // [FEATURE] [SEPA]
        // [SCENARIO 327227] On page General Ledger Setup field "SEPANonEuroExport" is visible and editable.
        Initialize();

        GeneralLedgerSetup.OpenEdit();
        Assert.IsTrue(
          GeneralLedgerSetup.SEPANonEuroExport.Visible,
          StrSubstNo(PageFieldVisibleErr, GeneralLedgerSetup.SEPANonEuroExport.Caption));
        Assert.IsTrue(
          GeneralLedgerSetup.SEPANonEuroExport.Editable,
          StrSubstNo(PageFieldEditableErr, GeneralLedgerSetup.SEPANonEuroExport.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SepaSetupFieldSEPANonEuroExportSaas()
    var
        GeneralLedgerSetup: TestPage "General Ledger Setup";
    begin
        // [FEATURE] [SEPA]
        // [SCENARIO 327227] On page General Ledger Setup field "SEPANonEuroExport" is visible and editable.

        Initialize();

        LibraryPermissions.SetTestabilitySoftwareAsAService(true);

        GeneralLedgerSetup.OpenEdit();
        Assert.IsTrue(
          GeneralLedgerSetup.SEPANonEuroExport.Visible,
          StrSubstNo(PageFieldVisibleErr, GeneralLedgerSetup.SEPANonEuroExport.Caption));
        Assert.IsTrue(
          GeneralLedgerSetup.SEPANonEuroExport.Editable,
          StrSubstNo(PageFieldEditableErr, GeneralLedgerSetup.SEPANonEuroExport.Caption));

        LibraryPermissions.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SepaSetupFieldSEPAExportWoBankAccData()
    var
        GeneralLedgerSetup: TestPage "General Ledger Setup";
    begin
        // [FEATURE] [SEPA]
        // [SCENARIO 327227] On page General Ledger Setup field "SEPAExportWoBankAccData" is visible and editable.
        Initialize();

        GeneralLedgerSetup.OpenEdit();
        Assert.IsTrue(
          GeneralLedgerSetup.SEPAExportWoBankAccData.Visible,
          StrSubstNo(PageFieldVisibleErr, GeneralLedgerSetup.SEPAExportWoBankAccData.Caption));
        Assert.IsTrue(
          GeneralLedgerSetup.SEPAExportWoBankAccData.Editable,
          StrSubstNo(PageFieldEditableErr, GeneralLedgerSetup.SEPAExportWoBankAccData.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SepaSetupFieldSEPAExportWoBankAccDataSaas()
    var
        GeneralLedgerSetup: TestPage "General Ledger Setup";
    begin
        // [FEATURE] [SEPA]
        // [SCENARIO 327227] On page General Ledger Setup field "SEPAExportWoBankAccData" is visible and editable.
        Initialize();

        LibraryPermissions.SetTestabilitySoftwareAsAService(true);

        GeneralLedgerSetup.OpenEdit();
        Assert.IsTrue(
          GeneralLedgerSetup.SEPAExportWoBankAccData.Visible,
          StrSubstNo(PageFieldVisibleErr, GeneralLedgerSetup.SEPAExportWoBankAccData.Caption));
        Assert.IsTrue(
          GeneralLedgerSetup.SEPAExportWoBankAccData.Editable,
          StrSubstNo(PageFieldEditableErr, GeneralLedgerSetup.SEPAExportWoBankAccData.Caption));

        LibraryPermissions.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice_CustomerNo_Visible_OnPrem()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO 338236] "Customer No." field must be visible by default on Sales Invoice card page
        Initialize();

        LibraryPermissions.SetTestabilitySoftwareAsAService(false);
        SalesInvoice.OpenView();
        Assert.IsTrue(SalesInvoice."Sell-to Customer No.".Visible(), '');
        LibraryPermissions.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice_CustomerNo_Visible_SaaS()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO 338236] "Customer No." field must be visible by default on Sales Invoice card page
        Initialize();

        LibraryPermissions.SetTestabilitySoftwareAsAService(true);
        SalesInvoice.OpenView();
        Assert.IsTrue(SalesInvoice."Sell-to Customer No.".Visible(), '');
        LibraryPermissions.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromCustomerListDateFilter()
    var
        CustomerList: TestPage "Customer List";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        CustomerList.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerList.FILTER.GetFilter("Date Filter"), 'Customer List');

        CustomerCard.Trap();
        CustomerList.Edit.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);

        CustomerCard.Close();
        CustomerList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesOrderDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        LibrarySales.CreateSalesOrder(SalesHeader);

        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesOrder.FILTER.GetFilter("Date Filter"), 'Sales Order');

        CustomerCard.Trap();
        SalesOrder.Customer.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);

        CustomerCard.Close();
        SalesOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesOrderListDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesOrderList: TestPage "Sales Order List";
    begin
        Initialize();

        LibrarySales.CreateSalesOrder(SalesHeader);

        SalesOrderList.OpenView();
        SalesOrderList.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesOrderList.FILTER.GetFilter("Date Filter"), 'Sales Order List');

        // There is not Customer Card action on Sales Order List.

        SalesOrderList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesInvoiceDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        LibrarySales.CreateSalesInvoice(SalesHeader);

        SalesInvoice.OpenView();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesInvoice.FILTER.GetFilter("Date Filter"), 'Sales Invoice');

        CustomerCard.Trap();
        SalesInvoice.Function_CustomerCard.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);

        CustomerCard.Close();
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesInvoiceListDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceList: TestPage "Sales Invoice List";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        LibrarySales.CreateSalesInvoice(SalesHeader);

        SalesInvoiceList.OpenView();
        SalesInvoiceList.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesInvoiceList.FILTER.GetFilter("Date Filter"), 'Sales Invoice List');

        CustomerCard.Trap();
        SalesInvoiceList.CustomerAction.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);

        CustomerCard.Close();
        SalesInvoiceList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesCreditMemoDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        LibrarySales.CreateSalesCreditMemo(SalesHeader);

        SalesCreditMemo.OpenView();
        SalesCreditMemo.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesCreditMemo.FILTER.GetFilter("Date Filter"), 'Sales Credit Memo');

        CustomerCard.Trap();
        SalesCreditMemo.Customer.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);
        CustomerCard.Close();

        CustomerCard.Trap();
        SalesCreditMemo.CreditMemo_CustomerCard.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);
        CustomerCard.Close();

        SalesCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesCreditMemoListDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemos: TestPage "Sales Credit Memos";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        SalesCreditMemos.OpenView();
        SalesCreditMemos.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesCreditMemos.FILTER.GetFilter("Date Filter"), 'Sales Credit Memos');

        CustomerCard.Trap();
        SalesCreditMemos.Customer.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);

        CustomerCard.Close();
        SalesCreditMemos.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesQuoteDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader, LibrarySales.CreateCustomerNo);

        SalesQuote.OpenView();
        SalesQuote.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesQuote.FILTER.GetFilter("Date Filter"), 'Sales Quote');

        CustomerCard.Trap();
        SalesQuote.Customer.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);

        CustomerCard.Close();
        SalesQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardFromSalesQuoteListDateFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesQuotes: TestPage "Sales Quotes";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();

        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader, LibrarySales.CreateCustomerNo);

        SalesQuotes.OpenView();
        SalesQuotes.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(GetExpectedDateFilter(), SalesQuotes.FILTER.GetFilter("Date Filter"), 'Sales Quotes');

        CustomerCard.Trap();
        SalesQuotes.Customer.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), CustomerCard.FILTER.GetFilter("Date Filter"), CustomerCardTxt);

        CustomerCard.Close();
        SalesQuotes.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromVendorListDateFilter()
    var
        VendorList: TestPage "Vendor List";
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();

        LibraryPurchase.CreateVendorNo;

        VendorList.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), VendorList.FILTER.GetFilter("Date Filter"), 'Vendor List');

        VendorCard.Trap();
        VendorList.Edit.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), VendorCard.FILTER.GetFilter("Date Filter"), VendorCardTxt);

        VendorCard.Close();
        VendorList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseOrderDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        PurchaseOrder.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseOrder.FILTER.GetFilter("Date Filter"), 'Purchase Order');

        VendorCard.Trap();
        PurchaseOrder.Vendor.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), VendorCard.FILTER.GetFilter("Date Filter"), VendorCardTxt);

        VendorCard.Close();
        PurchaseOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseOrderListDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseOrderList.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseOrderList.FILTER.GetFilter("Date Filter"), 'Purchase Order List');

        // There is not Vendord Card action on Purchase Order List.
        PurchaseOrderList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseInvoiceDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        PurchaseInvoice.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseInvoice.FILTER.GetFilter("Date Filter"), 'Purchase Invoice');

        VendorCard.Trap();
        PurchaseInvoice.Vendor.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), VendorCard.FILTER.GetFilter("Date Filter"), VendorCardTxt);

        VendorCard.Close();
        PurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseInvoiceListDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoices: TestPage "Purchase Invoices";
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        PurchaseInvoices.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseInvoices.FILTER.GetFilter("Date Filter"), 'Purchase Invoices');

        VendorCard.Trap();
        PurchaseInvoices.Vendor.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), VendorCard.FILTER.GetFilter("Date Filter"), VendorCardTxt);

        VendorCard.Close();
        PurchaseInvoices.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseCreditMemoDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);

        PurchaseCreditMemo.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseCreditMemo.FILTER.GetFilter("Date Filter"), 'Purchase Credit Memo');

        VendorCard.Trap();
        PurchaseCreditMemo.Vendor.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), VendorCard.FILTER.GetFilter("Date Filter"), VendorCardTxt);

        VendorCard.Close();
        PurchaseCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseCreditMemoListDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);

        PurchaseCreditMemos.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseCreditMemos.FILTER.GetFilter("Date Filter"), 'Purchase Credit Memos');

        VendorCard.Trap();
        PurchaseCreditMemos.Vendor.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), VendorCard.FILTER.GetFilter("Date Filter"), VendorCardTxt);

        VendorCard.Close();
        PurchaseCreditMemos.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseQuoteDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
        VendorCard: TestPage "Vendor Card";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);

        PurchaseQuote.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseQuote.FILTER.GetFilter("Date Filter"), 'Purchase Quote');

        VendorCard.Trap();
        PurchaseQuote.Vendor.Invoke();
        Assert.AreEqual(GetExpectedDateFilter(), VendorCard.FILTER.GetFilter("Date Filter"), VendorCardTxt);

        VendorCard.Close();
        PurchaseQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardFromPurchaseQuoteListDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);

        PurchaseQuotes.OpenView();
        Assert.AreEqual(GetExpectedDateFilter(), PurchaseQuotes.FILTER.GetFilter("Date Filter"), 'Purchase Quotes');

        // There is not Vendor Card action on Purchase Quotes
        PurchaseQuotes.Close();
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        IsInitialized := true;

        UpdateNoSeriesOnPurchaseSetup();
        UpdateNoSeriesOnSalesSetup();

        LibraryERM.DisableClosingUnreleasedOrdersMsg();

        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SavePurchasesSetup();
    end;

    local procedure PostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup, LibraryRandom.RandDecInRange(100, 200, 2));
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Option): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader,
          SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, LibraryRandom.RandDecInRange(100, 200, 2));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure GetDocNofilter(DocumentNo: array[3] of Code[20]): Text
    begin
        exit(StrSubstNo('%1..%2', DocumentNo[1], DocumentNo[3]));
    end;

    local procedure GetExpectedDateFilter(): Text
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Date Filter", 0D, WorkDate());
        exit(SalesHeader.GetFilter("Date Filter"));
    end;

    local procedure UpdateNoSeriesOnSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Return Order Nos." := LibraryERM.CreateNoSeriesCode;
        SalesReceivablesSetup.Modify();
    end;

    local procedure UpdateNoSeriesOnPurchaseSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Return Order Nos." := LibraryERM.CreateNoSeriesCode;
        PurchasesPayablesSetup.Modify();
    end;
}

