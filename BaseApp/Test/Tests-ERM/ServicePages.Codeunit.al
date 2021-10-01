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
        LibraryInventory: Codeunit "Library - Inventory";
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
        ServiceInvoice: TestPage "Service Invoices";
    begin
        // [FEATURE] [Print] [Post] [Invoice]
        // [SCENARIO 268383] Stan does not see confirmation to close Service Invoices card page when document fully invoiced with printing documents
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

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderCatchErrorPost()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceOrder: TestPage "Service Order";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post on Service Order page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Order
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Order, Customer."No.");
        // [GIVEN] Open Service Order page
        ServiceOrder.OpenEdit();
        ServiceOrder.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ServiceOrder.Post.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderCatchErrorPostPrint()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceOrder: TestPage "Service Order";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post and Print on Service Order page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Order
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Order, Customer."No.");
        // [GIVEN] Open Service Order page
        ServiceOrder.OpenEdit();
        ServiceOrder.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceOrder."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrdersCatchErrorPost()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceOrders: TestPage "Service Orders";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post on Service Orders page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Order
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Order, Customer."No.");
        // [GIVEN] Open Service Orders page
        ServiceOrders.OpenView();
        ServiceOrders.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ServiceOrders.Post.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrdersCatchErrorPostPrint()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceOrders: TestPage "Service Orders";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post and Print on Service Orders page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Order
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Order, Customer."No.");
        // [GIVEN] Open Service Orders page
        ServiceOrders.OpenView();
        ServiceOrders.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceOrders."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceCatchErrorPost()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceInvoice: TestPage "Service Invoice";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Invoice]
        // [SCENARIO 395037] Action Post on Service Invoice page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Invoice
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Invoice, Customer."No.");
        // [GIVEN] Open Service Invoice page
        ServiceInvoice.OpenEdit();
        ServiceInvoice.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ServiceInvoice.Post.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceCatchErrorPostPrint()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceInvoice: TestPage "Service Invoice";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Invoice]
        // [SCENARIO 395037] Action Post and Print on Service Invoice page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Invoice
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Invoice, Customer."No.");
        // [GIVEN] Open Service Invoice page
        ServiceInvoice.OpenEdit();
        ServiceInvoice.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceInvoice."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('PostAndSendConfirmationModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceCatchErrorPostSend()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceInvoice: TestPage "Service Invoice";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Invoice]
        // [SCENARIO 395037] Action Post and Send on Service Invoice page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Invoice
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Invoice, Customer."No.");
        // [GIVEN] Open Service Invoice page
        ServiceInvoice.OpenEdit();
        ServiceInvoice.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Send is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceInvoice.PostAndSend.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceInvoicesCatchErrorPost()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceInvoices: TestPage "Service Invoices";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Invoice]
        // [SCENARIO 395037] Action Post on Service Invoices page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Invoices
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Invoice, Customer."No.");
        // [GIVEN] Open Service Invoice page
        ServiceInvoices.OpenView();
        ServiceInvoices.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ServiceInvoices."P&ost".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceInvoicesCatchErrorPostPrint()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceInvoices: TestPage "Service Invoices";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Invoice]
        // [SCENARIO 395037] Action Post and Print on Service Invoices page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Invoices
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Invoice, Customer."No.");
        // [GIVEN] Open Service Invoice page
        ServiceInvoices.OpenView();
        ServiceInvoices.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceInvoices."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('PostAndSendConfirmationModalPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoicesCatchErrorPostSend()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceInvoices: TestPage "Service Invoices";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Invoice]
        // [SCENARIO 395037] Action Post and Send on Service Invoices page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Invoices
        CreateServiceDocument(ServiceHeader, "Service Document Type"::Invoice, Customer."No.");
        // [GIVEN] Open Service Invoice page
        ServiceInvoices.OpenView();
        ServiceInvoices.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Send is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceInvoices.PostAndSend.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoCatchErrorPost()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceCreditMemo: TestPage "Service Credit Memo";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Invoice]
        // [SCENARIO 395037] Action Post on Service Credit Memo page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Credit Memo
        CreateServiceDocument(ServiceHeader, "Service Document Type"::"Credit Memo", Customer."No.");
        // [GIVEN] Open Service Credit Memo page
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ServiceCreditMemo.Post.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoCatchErrorPostPrint()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceCreditMemo: TestPage "Service Credit Memo";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Credit Memo]
        // [SCENARIO 395037] Action Post and Print on Service Credit Memo page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Credit Memo
        CreateServiceDocument(ServiceHeader, "Service Document Type"::"Credit Memo", Customer."No.");
        // [GIVEN] Open Service Credit Memo page
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceCreditMemo."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('PostAndSendConfirmationModalPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoCatchErrorPostSend()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceCreditMemo: TestPage "Service Credit Memo";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Credit Memo]
        // [SCENARIO 395037] Action Post and Send on Service Credit Memo page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Credit Memo
        CreateServiceDocument(ServiceHeader, "Service Document Type"::"Credit Memo", Customer."No.");
        // [GIVEN] Open Service Credit Memo page
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Send is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceCreditMemo.PostAndSend.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemosCatchErrorPost()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceCreditMemos: TestPage "Service Credit Memos";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Credit Memo]
        // [SCENARIO 395037] Action Post on Service Credit Memos page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Credit Memos
        CreateServiceDocument(ServiceHeader, "Service Document Type"::"Credit Memo", Customer."No.");
        // [GIVEN] Open Service Credit Memo page
        ServiceCreditMemos.OpenView();
        ServiceCreditMemos.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ServiceCreditMemos."P&ost".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemosCatchErrorPostPrint()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceCreditMemos: TestPage "Service Credit Memos";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Credit Memo]
        // [SCENARIO 395037] Action Post and Print on Service Credit Memos page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Credit Memos
        CreateServiceDocument(ServiceHeader, "Service Document Type"::"Credit Memo", Customer."No.");
        // [GIVEN] Open Service Credit Memo page
        ServiceCreditMemos.OpenView();
        ServiceCreditMemos.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceCreditMemos."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [HandlerFunctions('PostAndSendConfirmationModalPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemosCatchErrorPostSend()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServiceCreditMemos: TestPage "Service Credit Memos";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Credit Memo]
        // [SCENARIO 395037] Action Post and Send on Service Credit Memos page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Create Customer with empty Receivables Account of customer posting group
        CreateCustomerWithEmptyReceivableAccount(Customer);

        // [GIVEN] Create Service Credit Memos
        CreateServiceDocument(ServiceHeader, "Service Document Type"::"Credit Memo", Customer."No.");
        // [GIVEN] Open Service Credit Memo page
        ServiceCreditMemos.OpenView();
        ServiceCreditMemos.Filter.SetFilter("No.", ServiceHeader."No.");
        ErrorMessages.Trap();

        // [WHEN] Action Post and Send is being selected
        LibraryVariableStorage.Enqueue(3); // Ship & Invoice posting option
        ErrorMessages.Trap();
        ServiceCreditMemos.PostAndSend.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
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

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, DocumentType, CustomerNo);
    end;

    local procedure CreateCustomerWithEmptyReceivableAccount(var Customer: Record Customer)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup."Receivables Account" := '';
        CustomerPostingGroup.Modify();

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", FindPaymentMethodWithBalanceAccount());
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Modify(true);
    end;

    local procedure FindPaymentMethodWithBalanceAccount(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetFilter("Bal. Account No.", '<>''''');
        PaymentMethod.FindFirst;
        exit(PaymentMethod.Code);
    end;

    local procedure UpdateServiceLineWithRandomQtyAndPrice(var ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer)
    begin
        UpdateServiceLine(
          ServiceLine, ServiceItemLineNo,
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure UpdateServiceLine(var ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer; Quantity: Decimal; UnitPrice: Decimal)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Modify(true);
    end;

    local procedure SetCurrencyCodeOnOrderAndVerify(ServiceOrder: TestPage "Service Order"; CurrencyCode: Code[10])
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(ChangeCurrencyConfirmQst, ServiceHeader.FieldCaption("Currency Code")));
        LibraryVariableStorage.Enqueue(true);
        ServiceOrder."Currency Code".SetValue(CurrencyCode);
    end;

    local procedure VerifyRecievablesAccountError(Description: Text)
    var
        DummyCustomerPostingGroup: Record "Customer Posting Group";
    begin
        Assert.ExpectedMessage(DummyCustomerPostingGroup.FieldCaption("Receivables Account"), Description);
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

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndSendConfirmationModalPageHandler(var PostandSendConfirmation: TestPage "Post and Send Confirmation")
    begin
        PostandSendConfirmation.Yes.Invoke;
    end;
}

