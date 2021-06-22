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
        IsInitialized: Boolean;
        DoYouWantPostAndPrintTok: Label 'Do you want to post and print';
        ChangeCurrencyConfirmQst: Label 'If you change %1, the existing service lines will be deleted and the program will create new service lines based on the new information on the header.\Do you want to change the %1?';

    [Test]
    [HandlerFunctions('StrMenuHandler,ServiceShipmentReportHandler,ServiceInvoiceReportHandler')]
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
    [HandlerFunctions('ConfirmHandlerWithValidation,ServiceInvoiceReportHandler')]
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
    [HandlerFunctions('ConfirmHandlerWithValidation,ServiceCreditMemoReportHandler')]
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

    local procedure SetCurrencyCodeOnOrderAndVerify(ServiceOrder: TestPage "Service Order"; CurrencyCode: Code[10])
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(ChangeCurrencyConfirmQst, ServiceHeader.FieldCaption("Currency Code")));
        LibraryVariableStorage.Enqueue(true);
        ServiceOrder."Currency Code".SetValue(CurrencyCode);
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
    procedure ServiceInvoiceReportHandler(var ServiceInvoice: Report "Service - Invoice")
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoReportHandler(var ServiceCreditMemo: Report "Service - Credit Memo")
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

