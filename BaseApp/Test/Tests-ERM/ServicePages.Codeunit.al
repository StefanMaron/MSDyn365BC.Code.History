codeunit 136150 "Service Pages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service] [UI]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        IsInitialized: Boolean;
        DoYouWantPostAndPrintTok: Label 'Do you want to post and print';
        ChangeCurrencyConfirmQst: Label 'If you change %1, the existing service lines will be deleted and the program will create new service lines based on the new information on the header.\Do you want to change the %1?';

    [Test]
    [HandlerFunctions('StrMenuHandler,ServiceShipmentReportHandler,ServiceInvoiceSalesTaxReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderPostAndPrint()
    var
        ServiceHeader: Record "Service Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ServiceOrder: TestPage "Service Order";
    begin
        // [FEATURE] [Print] [Post] [Order]
        // [SCENARIO 268383] Stan does not see confirmation to close service order card page when document fully shiped and invoiced with printing documents
        Initialize;

        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::Order);

        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option

        ServiceOrder.OpenEdit;
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder."Post and &Print".Invoke; // Post and Print

        NotificationLifecycleMgt.RecallAllNotifications;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithValidation,ServiceInvoiceSalesTaxReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoicePostAndPrint()
    var
        ServiceHeader: Record "Service Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [FEATURE] [Print] [Post] [Invoice]
        // [SCENARIO 268383] Stan does not see confirmation to close service invoice card page when document fully invoiced with printing documents
        Initialize;

        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::Invoice);

        LibraryVariableStorage.Enqueue(DoYouWantPostAndPrintTok);
        LibraryVariableStorage.Enqueue(true);

        ServiceInvoice.OpenEdit;
        ServiceInvoice.GotoRecord(ServiceHeader);
        ServiceInvoice."Post and &Print".Invoke; // Post and Print

        NotificationLifecycleMgt.RecallAllNotifications;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithValidation,ServiceCreditMemoSalesTaxReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoPostAndPrint()
    var
        ServiceHeader: Record "Service Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // [FEATURE] [Print] [Post] [Credit Memo]
        // [SCENARIO 268383] Stan does not see confirmation to close service credit memo card page when document fully invoiced with printing documents
        Initialize;

        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");

        LibraryVariableStorage.Enqueue(DoYouWantPostAndPrintTok);
        LibraryVariableStorage.Enqueue(true);

        ServiceCreditMemo.OpenEdit;
        ServiceCreditMemo.GotoRecord(ServiceHeader);
        ServiceCreditMemo."Post and &Print".Invoke; // Post and Print

        NotificationLifecycleMgt.RecallAllNotifications;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithValidation')]
    [Scope('OnPrem')]
    procedure ServiceOrderChangeCurrency()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [FCY] [Order]
        // [SCENARIO 308004] Confirmation message to recreate service lines must appear when Stan clears "Currency Code" field on Service Order.
        Initialize;
  
        ExchangeRate := LibraryRandom.RandIntInRange(10, 20);
        CurrencyCode :=
          LibraryERM.CreateCurrencyWithExchangeRate(LibraryRandom.RandDate(-10), ExchangeRate, ExchangeRate);
        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::Order);
  
        ServiceOrder.OpenEdit;
        ServiceOrder.Filter.SetFilter("No.", ServiceHeader."No.");
  
        SetCurrencyCodeOnOrderAndVerify(ServiceOrder, CurrencyCode);
        LibraryVariableStorage.AssertEmpty;
  
        SetCurrencyCodeOnOrderAndVerify(ServiceOrder, '');
        LibraryVariableStorage.AssertEmpty;
  
        ServiceOrder.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceQuoteFromCustomerCard()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Ship-to Address] [UT]
        // [SCENARIO 387958] It is possible to create Service Quote from Customer's Card having Ship-to Code.
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");

        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);

        ServiceHeader.Init();
        ServiceHeader.Validate("Document Type", ServiceHeader."Document Type"::Quote);
        ServiceHeader."Customer No." := Customer."No.";
        ServiceHeader.Validate("Customer No.");
        ServiceHeader.Insert(true);

        ServiceHeader.TestField("No.");
        ServiceHeader.TestField("Ship-to Code", ShipToAddress.Code);
    end;

    [Test]
    procedure ShipToAddressOnServiceInvoiceWhenSetCustomer()
    var
        Customer: Record Customer;
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ShipToAddress: Record "Ship-to Address";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [FEATURE] [Ship-to Code]
        // [SCENARIO 418143] Ship-to Address fields on Service Invoice page when Customer is set and Ship-to Code is not set.
        Initialize();

        // [GIVEN] Customer with Address and with Ship-to Address, these addresses has different field values.
        LibrarySales.CreateCustomerWithAddress(Customer);
        LibraryWarehouse.CreateLocation(Location);
        UpdateLocationOnCustomer(Customer, Location.Code);
        CreateShipToAddress(ShipToAddress, Customer."No.");

        // [WHEN] Create Service Invoice and set Customer for it. Open Service Invoice page.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceInvoice.OpenEdit();
        ServiceInvoice.Filter.SetFilter("No.", ServiceHeader."No.");

        // [THEN] Ship-to Code is blank. Ship-to Address fields are set from Customer.
        VerifyShipToFieldsAreFromCustomer(ServiceInvoice, Customer);
    end;

    [Test]
    procedure ShipToAddressOnServiceInvoiceWhenSetShipToCode()
    var
        Customer: Record Customer;
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ShipToAddress: Record "Ship-to Address";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [FEATURE] [Ship-to Code]
        // [SCENARIO 418143] Ship-to Address fields on Service Invoice page when Ship-to Code is set.
        Initialize();

        // [GIVEN] Customer with Address and with Ship-to Address "A1", these addresses has different field values.
        LibrarySales.CreateCustomerWithAddress(Customer);
        LibraryWarehouse.CreateLocation(Location);
        UpdateLocationOnCustomer(Customer, Location.Code);
        CreateShipToAddress(ShipToAddress, Customer."No.");

        // [GIVEN] Service Invoice with Customer. Opened Service Invoice page.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceInvoice.OpenEdit();
        ServiceInvoice.Filter.SetFilter("No.", ServiceHeader."No.");

        // [WHEN] Set Ship-to Code to "A1".
        ServiceInvoice."Ship-to Code".SetValue(ShipToAddress.Code);

        // [THEN] Ship-to Code is "A1". Ship-to Address fields are set from Ship-to Address record.
        VerifyShipToFieldsAreFromShipToAddress(ServiceInvoice, ShipToAddress);
    end;

    [Test]
    procedure ShipToAddressOnServiceInvoiceWhenClearShipToCode()
    var
        Customer: Record Customer;
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ShipToAddress: Record "Ship-to Address";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [FEATURE] [Ship-to Code]
        // [SCENARIO 418143] Ship-to Address fields on Service Invoice page when Ship-to Code is set and then cleared.
        Initialize();

        // [GIVEN] Customer with Address and with Ship-to Address "A1", these addresses has different field values.
        LibrarySales.CreateCustomerWithAddress(Customer);
        LibraryWarehouse.CreateLocation(Location);
        UpdateLocationOnCustomer(Customer, Location.Code);
        CreateShipToAddress(ShipToAddress, Customer."No.");

        // [GIVEN] Service Invoice with Customer and with Ship-to Code "A1". Opened Service Invoice page.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        UpdateShipToCodeOnServiceHeader(ServiceHeader, ShipToAddress.Code);
        ServiceInvoice.OpenEdit();
        ServiceInvoice.Filter.SetFilter("No.", ServiceHeader."No.");

        // [WHEN] Clear Ship-to Code.
        ServiceInvoice."Ship-to Code".SetValue('');

        // [THEN] Ship-to Code is blank. Ship-to Address fields are set from Customer.
        VerifyShipToFieldsAreFromCustomer(ServiceInvoice, Customer);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Pages");

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Pages");

        Commit();
        IsInitialized := true;

        LibraryERMCountryData.UpdateSalesReceivablesSetup;
        LibraryService.SetupServiceMgtNoSeries;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Pages");
    end;

    local procedure CreateShipToAddress(var ShipToAddress: Record "Ship-to Address"; CustomerNo: Code[20])
    var
        PostCode: Record "Post Code";
        Location: Record Location;
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibraryWarehouse.CreateLocation(Location);

        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        ShipToAddress.Validate(Address, LibraryUtility.GenerateGUID);
        ShipToAddress.Validate("Address 2", LibraryUtility.GenerateGUID);
        ShipToAddress.Validate("Location Code", Location.Code);
        ShipToAddress.Validate("Country/Region Code", PostCode."Country/Region Code");
        ShipToAddress.Validate(City, PostCode.City);
        ShipToAddress.Validate("Post Code", PostCode.Code);
        ShipToAddress.Modify(true);
    end;

    local procedure UpdateLocationOnCustomer(var Customer: Record Customer; LocationCode: Code[10])
    begin
        Customer.Validate("Location Code", LocationCode);
        Customer.Modify(true);
    end;

    local procedure UpdateShipToCodeOnServiceHeader(var ServiceHeader: Record "Service Header"; ShipToCode: Code[10])
    begin
        ServiceHeader.Validate("Ship-to Code", ShipToCode);
        ServiceHeader.Modify(true);
    end;

    local procedure SetCurrencyCodeOnOrderAndVerify(ServiceOrder: TestPage "Service Order";CurrencyCode: Code[10])
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(ChangeCurrencyConfirmQst, ServiceHeader.FieldCaption("Currency Code")));
        LibraryVariableStorage.Enqueue(true);
        ServiceOrder."Currency Code".SetValue(CurrencyCode);
    end;

    local procedure VerifyShipToFieldsAreFromCustomer(var ServiceInvoice: TestPage "Service Invoice"; Customer: Record Customer)
    begin
        Assert.AreEqual('', ServiceInvoice."Ship-to Code".Value, '');
        Assert.AreEqual(Customer.Address, ServiceInvoice."Ship-to Address".Value, '');
        Assert.AreEqual(Customer."Address 2", ServiceInvoice."Ship-to Address 2".Value, '');
        Assert.AreEqual(Customer."Post Code", ServiceInvoice."Ship-to Post Code".Value, '');
        Assert.AreEqual(Customer.City, ServiceInvoice."Ship-to City".Value, '');
        Assert.AreEqual(Customer."Country/Region Code", ServiceInvoice."Ship-to Country/Region Code".Value, '');
        Assert.AreEqual(Customer."Location Code", ServiceInvoice."Location Code".Value, '');
    end;

    local procedure VerifyShipToFieldsAreFromShipToAddress(var ServiceInvoice: TestPage "Service Invoice"; ShipToAddress: Record "Ship-to Address")
    begin
        Assert.AreEqual(ShipToAddress.Code, ServiceInvoice."Ship-to Code".Value, '');
        Assert.AreEqual(ShipToAddress.Address, ServiceInvoice."Ship-to Address".Value, '');
        Assert.AreEqual(ShipToAddress."Address 2", ServiceInvoice."Ship-to Address 2".Value, '');
        Assert.AreEqual(ShipToAddress."Post Code", ServiceInvoice."Ship-to Post Code".Value, '');
        Assert.AreEqual(ShipToAddress.City, ServiceInvoice."Ship-to City".Value, '');
        Assert.AreEqual(ShipToAddress."Country/Region Code", ServiceInvoice."Ship-to Country/Region Code".Value, '');
        Assert.AreEqual(ShipToAddress."Location Code", ServiceInvoice."Location Code".Value, '');
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger;
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ServiceShipmentReportHandler(var ServiceShipment: Report "Service - Shipment")
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceSalesTaxReportHandler(var ServiceInvoiceSalesTax: Report "Service Invoice-Sales Tax")
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoSalesTaxReportHandler(var ServiceCreditMemoSalesTax: Report "Service Credit Memo-Sales Tax")
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerWithValidation(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Question);
        Reply := LibraryVariableStorage.DequeueBoolean;
    end;
}

