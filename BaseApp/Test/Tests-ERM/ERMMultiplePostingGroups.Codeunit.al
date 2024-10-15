codeunit 134195 "ERM Multiple Posting Groups"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Posting Group]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        BlockedTestFieldErr: Label 'Blocked must be equal to ''No''';
        TestFieldCodeErr: Label 'TestField';
        AccountCategory: Option ,Assets,Liabilities,Equity,Income,"Cost of Goods Sold",Expense;
        GenProdPostingGroupTestFieldErr: Label 'Gen. Prod. Posting Group must have a value in G/L Account: No.=%1. It cannot be zero or empty.';

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesOrderCustomerPostingGroupIsNotEditable()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(false);

        SalesOrder.OpenNew();
        Assert.IsFalse(SalesOrder."Customer Posting Group".Editable, 'Customer Posting Group is editable in Sales Order page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesOrderCustomerPostingGroupIsEditable()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(true);

        SalesOrder.OpenNew();
        Assert.IsTrue(SalesOrder."Customer Posting Group".Editable, 'Customer Posting Group is not editable in Sales Order page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesInvoiceCustomerPostingGroupIsNotEditable()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(false);

        SalesInvoice.OpenNew();
        Assert.IsFalse(SalesInvoice."Customer Posting Group".Editable, 'Customer Posting Group is editable in Sales Invoice page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesInvoiceCustomerPostingGroupIsEditable()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(true);

        SalesInvoice.OpenNew();
        Assert.IsTrue(SalesInvoice."Customer Posting Group".Editable, 'Customer Posting Group is not editable in Sales Invoice page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesCreditMemoCustomerPostingGroupIsNotEditable()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(false);

        SalesCreditMemo.OpenNew();
        Assert.IsFalse(SalesCreditMemo."Customer Posting Group".Editable, 'Customer Posting Group is editable in Sales Credit Memo page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesCreditMemoCustomerPostingGroupIsEditable()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(true);

        SalesCreditMemo.OpenNew();
        Assert.IsTrue(SalesCreditMemo."Customer Posting Group".Editable, 'Customer Posting Group is not editable in Sales Credit Memo page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesReturnOrderCustomerPostingGroupIsNotEditable()
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(false);

        SalesReturnOrder.OpenNew();
        Assert.IsFalse(SalesReturnOrder."Customer Posting Group".Editable, 'Customer Posting Group is editable in Sales Return Order page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesReturnOrderCustomerPostingGroupIsEditable()
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(true);

        SalesReturnOrder.OpenNew();
        Assert.IsTrue(SalesReturnOrder."Customer Posting Group".Editable, 'Customer Posting Group is not editable in Sales Return Order page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseOrderVendorPostingGroupIsNotEditable()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(false);

        PurchaseOrder.OpenNew();
        Assert.IsFalse(PurchaseOrder."Vendor Posting Group".Editable, 'Vendor Posting Group is editable in Purchase Order page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseOrderVendorPostingGroupIsEditable()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(true);

        PurchaseOrder.OpenNew();
        Assert.IsTrue(PurchaseOrder."Vendor Posting Group".Editable, 'Vendor Posting Group is not editable in Purchase Order page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseInvoiceVendorPostingGroupIsNotEditable()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(false);

        PurchaseInvoice.OpenNew();
        Assert.IsFalse(PurchaseInvoice."Vendor Posting Group".Editable, 'Vendor Posting Group is editable in Purchase Invoice page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseInvoiceVendorPostingGroupIsEditable()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(true);

        PurchaseInvoice.OpenNew();
        Assert.IsTrue(PurchaseInvoice."Vendor Posting Group".Editable, 'Vendor Posting Group is not editable in Purchase Invoice page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseCreditMemoVendorPostingGroupIsNotEditable()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(false);

        PurchaseCreditMemo.OpenNew();
        Assert.IsFalse(PurchaseCreditMemo."Vendor Posting Group".Editable, 'Vendor Posting Group is editable in Purchase Credit Memo page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseCreditMemoVendorPostingGroupIsEditable()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(true);

        PurchaseCreditMemo.OpenNew();
        Assert.IsTrue(PurchaseCreditMemo."Vendor Posting Group".Editable, 'Vendor Posting Group is not editable in Purchase Credit Memo page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseReturnOrderCustomerPostingGroupIsNotEditable()
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(false);

        PurchaseReturnOrder.OpenNew();
        Assert.IsFalse(PurchaseReturnOrder."Vendor Posting Group".Editable, 'Customer Posting Group is editable in Purchase Return Order page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseReturnOrderCustomerPostingGroupIsEditable()
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(true);

        PurchaseReturnOrder.OpenNew();
        Assert.IsTrue(PurchaseReturnOrder."Vendor Posting Group".Editable, 'Vendor Posting Group is not editable in Purchase Return Order page');
    end;


    [Test]
    [Scope('OnPrem')]
    procedure CheckServiceInvoiceCustomerPostingGroupIsNotEditable()
    var
        ServiceInvoice: TestPage "Service Invoice";
    begin
        Initialize();

        SetServiceAllowMultiplePostingGroups(false);

        ServiceInvoice.OpenNew();
        Assert.IsFalse(ServiceInvoice."Customer Posting Group".Editable, 'Customer Posting Group is editable in Service Invoice page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckServiceInvoiceCustomerPostingGroupIsEditable()
    var
        ServiceInvoice: TestPage "Service Invoice";
    begin
        Initialize();

        SetServiceAllowMultiplePostingGroups(true);

        ServiceInvoice.OpenNew();
        Assert.IsTrue(ServiceInvoice."Customer Posting Group".Editable, 'Customer Posting Group is not editable in Service Invoice page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckServiceCreditMemoCustomerPostingGroupIsNotEditable()
    var
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        Initialize();

        SetServiceAllowMultiplePostingGroups(false);

        ServiceCreditMemo.OpenNew();
        Assert.IsFalse(ServiceCreditMemo."Customer Posting Group".Editable, 'Customer Posting Group is editable in Service Credit Memo page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckServiceCreditMemoCustomerPostingGroupIsEditable()
    var
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        Initialize();

        SetServiceAllowMultiplePostingGroups(true);

        ServiceCreditMemo.OpenNew();
        Assert.IsTrue(ServiceCreditMemo."Customer Posting Group".Editable, 'Customer Posting Group is not editable in Service Credit Memo page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFinanceChargeMemoCustomerPostingGroupIsNotEditable()
    var
        FinanceChargeMemo: TestPage "Finance Charge Memo";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(false);

        FinanceChargeMemo.OpenNew();
        Assert.IsFalse(FinanceChargeMemo."Customer Posting Group".Editable, 'Customer Posting Group is editable in Finance Charge Memo page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFinanceChargeMemoCustomerPostingGroupIsEditable()
    var
        FinanceChargeMemo: TestPage "Finance Charge Memo";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(true);

        FinanceChargeMemo.OpenNew();
        Assert.IsTrue(FinanceChargeMemo."Customer Posting Group".Editable, 'Customer Posting Group is not editable in Finance Charge Memo page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostSalesInvoiceWithAnotherCustomerPostingGroup()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        Initialize();

        SetSalesAllowMultiplePostingGroups(true);

        // Create sales invoice, change customer posting group and post
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, "Sales Document Type"::Invoice, Customer."No.", '', 1, '', 0D);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        SalesHeader.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        SalesHeader.Modify();

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Check customer posting group code in posted records
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.FindFirst();
        Assert.AreEqual(
            CustLedgerEntry."Customer Posting Group", CustomerPostingGroup.Code,
            'Customer Posting Group in Customer Ledger Entry is not correct.');

        SalesInvoiceHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvoiceHeader.FindFirst();
        Assert.AreEqual(
            SalesInvoiceHeader."Customer Posting Group", CustomerPostingGroup.Code,
            'Customer Posting Group in Sales Invoice Header is not correct.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostPurchaseInvoiceWithAnotherVendorPostingGroup()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        Initialize();

        SetPurchAllowMultiplePostingGroups(true);

        // Create sales invoice, change customer posting group and post
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Invoice, Vendor."No.", '', 1, '', 0D);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        PurchaseHeader.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        PurchaseHeader.Modify();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Check vendor posting group code in posted records
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindFirst();
        Assert.AreEqual(
            VendorLedgerEntry."Vendor Posting Group", VendorPostingGroup.Code,
            'Vendor Posting Group in Vendor Ledger Entry is not correct.');

        PurchInvHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchInvHeader.FindFirst();
        Assert.AreEqual(
            PurchInvHeader."Vendor Posting Group", VendorPostingGroup.Code,
            'Vendor Posting Group in Purchase Invoice Header is not correct.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Multiple Posting Groups");

        // Lazy Setup.
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Multiple Posting Groups");

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Multiple Posting Groups");
    end;

    local procedure SetSalesAllowMultiplePostingGroups(AllowMultiplePostingGroups: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup."Allow Multiple Posting Groups" := AllowMultiplePostingGroups;
        SalesSetup.Modify();
    end;

    local procedure SetServiceAllowMultiplePostingGroups(AllowMultiplePostingGroups: Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup."Allow Multiple Posting Groups" := AllowMultiplePostingGroups;
        ServiceMgtSetup.Modify();
    end;

    local procedure SetPurchAllowMultiplePostingGroups(AllowMultiplePostingGroups: Boolean)
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup."Allow Multiple Posting Groups" := AllowMultiplePostingGroups;
        PurchSetup.Modify();
    end;
}

