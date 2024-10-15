#if not CLEAN22
codeunit 134149 "ERM Intrastat Propagation"
{
    Subtype = Test;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    trigger OnRun()
    begin
        // [FEATURE] [Intrastat]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateTariffNoIfNotExists()
    var
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
    begin
        // [FEATURE] [Tariff Number]
        // [GIVEN] Tariff number "TARIFF NUM" does not exists
        Initialize();

        LibraryLowerPermissions.SetO365BusFull();
        TariffNumber.DeleteAll();
        Assert.RecordCount(TariffNumber, 0);

        // [WHEN] Not existing Tariff number is request to be linked to item
        Item.Init();
        Item.Validate("Tariff No.", 'TARIFF NUM');
        Item.Insert();

        // [THEN] Tariff number exists
        TariffNumber.Get('TARIFF NUM');
        TariffNumber.Delete(); // Cleanup
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderDefaultTransactionType()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Order]
        // [SCENARIO 295133] Intrastat Setup field "Default Trans. - Purchase" gets auto-filled in in new Service Orders
        Initialize();
        LibraryLowerPermissions.SetO365BusinessPremium();

        // [WHEN] Service Order is created
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [THEN] "Transaction Type" field = Intrastat Setup "Default Trans. - Purchase"
        ServiceHeader.TestField("Transaction Type", GetDefaultTransactionType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceDefaultTransactionType()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 295133] Intrastat Setup field "Default Trans. - Purchase" gets auto-filled in in new Service Invoices
        Initialize();
        LibraryLowerPermissions.SetO365BusinessPremium();

        // [WHEN] Service Invoice is created
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        // [THEN] "Transaction Type" field = Intrastat Setup "Default Trans. - Purchase"
        ServiceHeader.TestField("Transaction Type", GetDefaultTransactionType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoDefaultTransactionType()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 295133] Intrastat Setup field "Default Trans. - Return" gets auto-filled in in new Service Credit Memos
        Initialize();
        LibraryLowerPermissions.SetO365BusinessPremium();

        // [WHEN] Service Credit Memo is created
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());

        // [THEN] "Transaction Type" field = Intrastat Setup "Default Trans. - Return"
        ServiceHeader.TestField("Transaction Type", GetDefaultReturnTransactionType());
    end;

    [Test]
    procedure SalesInvDefaultTransactionSpecification()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 433410] Intrastat Setup field "Default Trans. Spec. Code" gets auto-filled in the new Sales Invoice

        Initialize();
        LibraryLowerPermissions.SetO365BusinessPremium();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.TestField("Transaction Specification", GetDefaultTransactionSpecification());
    end;

    [Test]
    procedure SalesCrMemoDefaultTransactionSpecification()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 433410] Intrastat Setup field "Default Trans. Spec. Code" gets auto-filled in the new Sales Credit Memo

        Initialize();
        LibraryLowerPermissions.SetO365BusinessPremium();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        SalesHeader.TestField("Transaction Specification", GetDefaultReturnTransactionSpecification());
    end;

    [Test]
    procedure ServiceInvDefaultTransactionSpecification()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 433410] Intrastat Setup field "Default Trans. Spec. Code" gets auto-filled in the new Service Invoice

        Initialize();
        LibraryLowerPermissions.SetO365BusinessPremium();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        ServiceHeader.TestField("Transaction Specification", GetDefaultTransactionSpecification());
    end;

    [Test]
    procedure ServiceCrMemoDefaultTransactionSpecification()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 433410] Intrastat Setup field "Default Trans. Spec. Code" gets auto-filled in the new Service Credit Memo

        Initialize();
        LibraryLowerPermissions.SetO365BusinessPremium();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        ServiceHeader.TestField("Transaction Specification", GetDefaultReturnTransactionSpecification());
    end;

    [Test]
    procedure PurchaseInvDefaultTransactionSpecification()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 433410] Intrastat Setup field "Default Trans. Spec. Code" gets auto-filled in the new Purchase Invoice

        Initialize();
        LibraryLowerPermissions.SetO365BusinessPremium();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Shipment Method Code" := '';
        Vendor.Modify();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.TestField("Transaction Specification", GetDefaultTransactionSpecification());
    end;

    [Test]
    procedure PurchaseCrMemoDefaultTransactionSpecification()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 433410] Intrastat Setup field "Default Trans. Spec. Code" gets auto-filled in the new Purchase Credit Memo

        Initialize();
        LibraryLowerPermissions.SetO365BusinessPremium();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Shipment Method Code" := '';
        Vendor.Modify();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        PurchaseHeader.TestField("Transaction Specification", GetDefaultReturnTransactionSpecification());
    end;

    local procedure Initialize()
    var
        IntrastatSetup: Record "Intrastat Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Intrastat Propagation");

        if IsInitialized then
            exit;

        IsInitialized := true;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Intrastat Propagation");
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERM.FindIntrastatSetup(IntrastatSetup);
        LibraryERM.SetDefaultTransactionTypesInIntrastatSetup();
        LibraryERM.SetDefaultTransactionSpecificationInIntrastatSetup();

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Intrastat Propagation");
    end;

    local procedure GetDefaultTransactionType(): Code[10]
    var
        IntrastatSetup: Record "Intrastat Setup";
    begin
        IntrastatSetup.Get();
        exit(IntrastatSetup."Default Trans. - Purchase");
    end;

    local procedure GetDefaultReturnTransactionType(): Code[10]
    var
        IntrastatSetup: Record "Intrastat Setup";
    begin
        IntrastatSetup.Get();
        exit(IntrastatSetup."Default Trans. - Return");
    end;

    local procedure GetDefaultTransactionSpecification(): Code[10]
    var
        IntrastatSetup: Record "Intrastat Setup";
    begin
        IntrastatSetup.Get();
        exit(IntrastatSetup."Default Trans. Spec. Code");
    end;

    local procedure GetDefaultReturnTransactionSpecification(): Code[10]
    var
        IntrastatSetup: Record "Intrastat Setup";
    begin
        IntrastatSetup.Get();
        exit(IntrastatSetup."Default Trans. Spec. Ret. Code");
    end;
}
#endif