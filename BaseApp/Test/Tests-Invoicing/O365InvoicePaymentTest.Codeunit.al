codeunit 138907 "O365 Invoice Payment Test"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Sales] [Invoice] [Payment] [UT]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        O365SalesInvoicePayment: Codeunit "O365 Sales Invoice Payment";
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        MarkedPaidMsg: Label 'Invoice payment was registered.';
        MarkedUnpaidMsg: Label 'Payment registration was removed.';
        MarkAsUnpaidConfirmQst: Label 'Cancel this payment registration?';

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,MarkAsPaidHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PayPostedInvoice()
    var
        PostedSalesDocumentNo: Code[20];
    begin
        // [SCENARIO] User pays an invoice with single click and NO dialogs
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A posted sales invoice
        PostedSalesDocumentNo := CreatePostedSalesInvoice;

        // [WHEN] The user calls pay invoice
        LibraryVariableStorage.Enqueue(MarkedPaidMsg);
        O365SalesInvoicePayment.MarkAsPaid(PostedSalesDocumentNo);

        // [THEN] The customer ledger entry for the invoice is closed
        AssertSalesInvoiceClosed(PostedSalesDocumentNo);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,MarkAsPaidHandler,MessageHandler,MarkAsUnpaidConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelPostedInvoice()
    var
        PostedSalesDocumentNo: Code[20];
    begin
        // [SCENARIO] User cancels a paid invoice with single click and NO dialogs
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A posted sales invoice
        PostedSalesDocumentNo := CreatePostedSalesInvoice;

        // [GIVEN] The invoice is paid
        LibraryVariableStorage.Enqueue(MarkedPaidMsg);
        O365SalesInvoicePayment.MarkAsPaid(PostedSalesDocumentNo);

        // [WHEN] The user cancels payment of the invoice
        LibraryVariableStorage.Enqueue(MarkedUnpaidMsg);
        O365SalesInvoicePayment.CancelSalesInvoicePayment(PostedSalesDocumentNo);

        // [THEN] The customer ledger entry for the invoice is open
        AssertSalesInvoiceOpen(PostedSalesDocumentNo);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,MarkAsUnpaidConfirmHandler')]
    [Scope('OnPrem')]
    procedure FailCancelAutoPaidInvoice()
    var
        SalesHeader: Record "Sales Header";
        PaymentMethod: Record "Payment Method";
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        PostedSalesDocumentNo: Code[20];
    begin
        // [SCENARIO] User cancels an automatically paid invoice with single click and NO dialogs
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A posted sales invoice that is automatically being paid
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibraryERM.CreatePaymentMethodWithBalAccount(PaymentMethod);
        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);
        SalesHeader.Modify(true);
        PostedSalesDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] The invoice is paid
        Assert.IsTrue(
          O365SalesInvoicePayment.GetPaymentCustLedgerEntry(DummyCustLedgerEntry, PostedSalesDocumentNo),
          'The invoice should be paid automatically using the given balance account.');

        // [GIVEN] The invoice is being marked as unpaid
        // [THEN] An error occurs "You can only reverse entries that were posted from a journal."
        asserterror O365SalesInvoicePayment.CancelSalesInvoicePayment(PostedSalesDocumentNo);
        Assert.ExpectedError('You can only reverse entries that were posted from a journal.');

        // [THEN] The invoice is still marked as paid (I.E. no changes were made, no commits were executed)
        Assert.IsTrue(
          O365SalesInvoicePayment.GetPaymentCustLedgerEntry(DummyCustLedgerEntry, PostedSalesDocumentNo),
          'The invoice should still be paid after cancel sales invoice payment fails (no commits were executed).');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,PartialPaymentMarkAsPaidHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartialPaymentsForPostedInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesDocumentNo: Code[20];
    begin
        // [SCENARIO] User makes a partial payment for an invoice
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A posted sales invoice
        PostedSalesDocumentNo := CreatePostedSalesInvoice;

        // [WHEN] The user makes two partial payments
        LibraryVariableStorage.Enqueue(MarkedPaidMsg);
        O365SalesInvoicePayment.MarkAsPaid(PostedSalesDocumentNo);
        LibraryVariableStorage.Enqueue(MarkedPaidMsg);
        O365SalesInvoicePayment.MarkAsPaid(PostedSalesDocumentNo);

        // [THEN] The customer ledger entry for the invoice is open
        AssertSalesInvoiceOpen(PostedSalesDocumentNo);

        // [THEN] The sales invoice is partially paid
        SalesInvoiceHeader.Get(PostedSalesDocumentNo);
        SalesInvoiceHeader.CalcFields(Amount, "Remaining Amount");
        Assert.AreNotEqual(SalesInvoiceHeader.Amount, SalesInvoiceHeader."Remaining Amount", 'Sales invoice must be partially paid');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,PartialPaymentMarkAsPaidHandler,MessageHandler,MarkAsUnpaidConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelPartialPaymentsForPostedInvoice()
    var
        TempO365PaymentHistoryBuffer: Record "O365 Payment History Buffer" temporary;
        PostedSalesDocumentNo: Code[20];
    begin
        // [SCENARIO] User cancels a partial payment for an invoice
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A posted sales invoice
        PostedSalesDocumentNo := CreatePostedSalesInvoice;

        // [GIVEN] The user makes two partial payments
        LibraryVariableStorage.Enqueue(MarkedPaidMsg);
        O365SalesInvoicePayment.MarkAsPaid(PostedSalesDocumentNo);
        LibraryVariableStorage.Enqueue(MarkedPaidMsg);
        O365SalesInvoicePayment.MarkAsPaid(PostedSalesDocumentNo);

        // [WHEN] The user cancels the first payment
        // [THEN] An error is thrown
        TempO365PaymentHistoryBuffer.FillPaymentHistory(PostedSalesDocumentNo);
        Assert.AreEqual(2, TempO365PaymentHistoryBuffer.Count, 'There must be two payments for the invoice.');
        TempO365PaymentHistoryBuffer.FindSet;
        asserterror TempO365PaymentHistoryBuffer.CancelPayment;

        // [WHEN] The user cancels the second payment
        LibraryVariableStorage.Enqueue(MarkedUnpaidMsg);
        TempO365PaymentHistoryBuffer.Next;
        TempO365PaymentHistoryBuffer.CancelPayment;

        // [THEN] There are only one payment left
        TempO365PaymentHistoryBuffer.FillPaymentHistory(PostedSalesDocumentNo);
        Assert.AreEqual(1, TempO365PaymentHistoryBuffer.Count, 'After cancelling one payment there should only be one left.');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend,PaymentMethodMarkAsPaidHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PaymentMethodForPayment()
    var
        TempO365PaymentHistoryBuffer: Record "O365 Payment History Buffer" temporary;
        PostedSalesDocumentNo: Code[20];
        PaymentMethodCode: Code[10];
    begin
        // [SCENARIO 184609] Payment method specified for payment copied to the payment history
        Initialize;
        LibraryLowerPermissions.SetInvoiceApp;

        // [GIVEN] A posted sales invoice
        PostedSalesDocumentNo := CreatePostedSalesInvoice;

        // [GIVEN] Payment method XXX
        PaymentMethodCode := CreatePaymentMethod;

        // [WHEN] The user makes payment with payment method XXX
        LibraryVariableStorage.Enqueue(PaymentMethodCode);
        LibraryVariableStorage.Enqueue(MarkedPaidMsg);
        O365SalesInvoicePayment.MarkAsPaid(PostedSalesDocumentNo);

        // [THEN] Payment history entry for the payment has payment method = XXX
        TempO365PaymentHistoryBuffer.FillPaymentHistory(PostedSalesDocumentNo);
        TempO365PaymentHistoryBuffer.TestField("Payment Method", PaymentMethodCode);
    end;

    local procedure Initialize()
    var
        AccountingPeriod: Record "Accounting Period";
        O365C2GraphEventSettings: Record "O365 C2Graph Event Settings";
        O365SalesInitialSetup: Codeunit "O365 Sales Initial Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Invoice Payment Test");
        LibraryVariableStorage.AssertEmpty;
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Invoice Payment Test");

        // Ensure WORKDATE does not drift too far from the accounting period start date
        AccountingPeriod.DeleteAll();
        AccountingPeriod.SetRange("New Fiscal Year", true);
        if not AccountingPeriod.FindLast then begin
            AccountingPeriod.Init();
            AccountingPeriod."Starting Date" := CalcDate('<CY+1D>', WorkDate);
            AccountingPeriod."New Fiscal Year" := true;
            AccountingPeriod.Insert();
        end;

        WorkDate(AccountingPeriod."Starting Date");
        DeletePaymentMethodsNotForInvoicing;

        O365SalesInitialSetup.HideConfirmDialog;
        O365SalesInitialSetup.Run;
        IsInitialized := true;

        if not O365C2GraphEventSettings.Get then
            O365C2GraphEventSettings.Insert(true);

        O365C2GraphEventSettings.SetEventsEnabled(false);
        O365C2GraphEventSettings.Modify();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Invoice Payment Test");
    end;

    local procedure AssertSalesInvoiceOpen(PostedSalesDocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", PostedSalesDocumentNo);
        CustLedgerEntry.FindFirst;
        Assert.AreEqual(0, CustLedgerEntry."Closed by Entry No.", 'Invoice should not be paid.');
    end;

    local procedure AssertSalesInvoiceClosed(PostedSalesDocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", PostedSalesDocumentNo);
        CustLedgerEntry.FindFirst;
        Assert.AreNotEqual(0, CustLedgerEntry."Closed by Entry No.", 'Invoice should be paid.');
        CustLedgerEntry.Get(CustLedgerEntry."Closed by Entry No.");
    end;

    local procedure CreatePostedSalesInvoice(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true))
    end;

    local procedure CreatePaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethodWithBalAccount(PaymentMethod);
        PaymentMethod.Validate("Use for Invoicing", true);
        PaymentMethod.Modify(true);
        exit(PaymentMethod.Code);
    end;

    local procedure DeletePaymentMethodsNotForInvoicing()
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetRange("Use for Invoicing", false);
        PaymentMethod.DeleteAll();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MarkAsPaidHandler(var O365MarkAsPaid: TestPage "O365 Mark As Paid")
    begin
        O365MarkAsPaid.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PartialPaymentMarkAsPaidHandler(var O365MarkAsPaid: TestPage "O365 Mark As Paid")
    var
        CurrentAmount: Decimal;
    begin
        Evaluate(CurrentAmount, O365MarkAsPaid.AmountReceived.Value);
        O365MarkAsPaid.AmountReceived.Value(Format(Round(CurrentAmount / 10, 0.01)));
        O365MarkAsPaid.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentMethodMarkAsPaidHandler(var O365MarkAsPaid: TestPage "O365 Mark As Paid")
    begin
        O365MarkAsPaid.PaymentMethod.Value(LibraryVariableStorage.DequeueText);
        O365MarkAsPaid.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.AreEqual(ExpectedMessage, Message, '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure MarkAsUnpaidConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(MarkAsUnpaidConfirmQst, Question, '');
        Reply := true;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

