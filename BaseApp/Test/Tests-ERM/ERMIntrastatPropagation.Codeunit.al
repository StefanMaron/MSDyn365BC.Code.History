codeunit 134149 "ERM Intrastat Propagation"
{
    Subtype = Test;

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
        LibraryLowerPermissions.SetO365BusFull;
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
        Initialize;
        LibraryLowerPermissions.SetO365BusinessPremium;

        // [WHEN] Service Order is created
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);

        // [THEN] "Transaction Type" field = Intrastat Setup "Default Trans. - Purchase"
        ServiceHeader.TestField("Transaction Type", GetDefaultTransactionType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceDefaultTransactionType()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 295133] Intrastat Setup field "Default Trans. - Purchase" gets auto-filled in in new Service Invoices
        Initialize;
        LibraryLowerPermissions.SetO365BusinessPremium;

        // [WHEN] Service Invoice is created
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);

        // [THEN] "Transaction Type" field = Intrastat Setup "Default Trans. - Purchase"
        ServiceHeader.TestField("Transaction Type", GetDefaultTransactionType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoDefaultTransactionType()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 295133] Intrastat Setup field "Default Trans. - Return" gets auto-filled in in new Service Credit Memos
        Initialize;
        LibraryLowerPermissions.SetO365BusinessPremium;

        // [WHEN] Service Credit Memo is created
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo);

        // [THEN] "Transaction Type" field = Intrastat Setup "Default Trans. - Return"
        ServiceHeader.TestField("Transaction Type", GetDefaultReturnTransactionType);
    end;

    local procedure Initialize()
    var
        IntrastatSetup: Record "Intrastat Setup";
    begin
        if IsInitialized then
            exit;
        IsInitialized := true;
        LibraryService.SetupServiceMgtNoSeries;
        LibraryERM.FindIntrastatSetup(IntrastatSetup);
        LibraryERM.SetDefaultTransactionTypesInIntrastatSetup;

        Commit();
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
}

