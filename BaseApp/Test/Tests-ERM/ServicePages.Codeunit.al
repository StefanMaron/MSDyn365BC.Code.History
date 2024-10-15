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
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;
        DoYouWantPostAndPrintTok: Label 'Do you want to post and print';
        ChangeCurrencyConfirmQst: Label 'If you change %1, the existing service lines will be deleted and the program will create new service lines based on the new information on the header.\Do you want to change the %1?';

    [Test]
    [HandlerFunctions('StrMenuHandler,ServiceShipmentCZReportHandler,ServiceInvoiceCZReportHandler')]
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
    [HandlerFunctions('ConfirmHandlerWithValidation,ServiceInvoiceCZReportHandler')]
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
    [HandlerFunctions('ConfirmHandlerWithValidation,ServiceCreditMemoCZReportHandler')]
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

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Pages");

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Pages");

        Commit;
        IsInitialized := true;

        LibraryERMCountryData.UpdateSalesReceivablesSetup;
        LibraryService.SetupServiceMgtNoSeries;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Pages");
    end;

    local procedure SetCurrencyCodeOnOrderAndVerify(ServiceOrder: TestPage "Service Order";CurrencyCode: Code[10])
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
    procedure ServiceShipmentCZReportHandler(var ServiceShipmentCZ: Report "Service - Shipment CZ")
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceCZReportHandler(var ServiceInvoiceCZ: Report "Service - Invoice CZ")
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoCZReportHandler(var ServiceCreditMemoCZ: Report "Service - Credit Memo CZ")
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

