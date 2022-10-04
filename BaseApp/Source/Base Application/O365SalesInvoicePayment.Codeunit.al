codeunit 2105 "O365 Sales Invoice Payment"
{
    trigger OnRun()
    begin
    end;
#if not CLEAN21
    var
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        NoDetailedCustomerLedgerEntryForPaymentErr: Label 'No Detailed Customer Ledger Entry could be found for the payment of the invoice.';
        MarkedPaidMsg: Label 'Invoice payment was registered.';
        MarkedUnpaidMsg: Label 'Payment registration was removed.';
        SentInvoiceCategoryLbl: Label 'AL Sent Invoice', Locked = true;
        InvoicePartiallyPaidTelemetryTxt: Label 'Invoice has been partially paid.', Locked = true;
        InvoiceFullyPaidTelemetryTxt: Label 'Invoice has been fully paid.', Locked = true;
        InvoicePaymentRemovedTelemetryTxt: Label 'Invoice payment has been removed.', Locked = true;
        PostingPaymentDialogMsg: Label 'We are applying your payment, this will take a moment.';

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure ShowHistory(SalesInvoiceDocumentNo: Code[20]): Boolean
    var
        O365PaymentHistoryList: Page "O365 Payment History List";
    begin
        O365PaymentHistoryList.ShowHistory(SalesInvoiceDocumentNo);
        if O365PaymentHistoryList.RunModal() <> ACTION::OK then
            exit(false);

        // The returned action is OK even when X is selected: find if records have been deleted
        exit(O365PaymentHistoryList.RecordDeleted());
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    [Scope('OnPrem')]
    procedure MarkAsPaid(SalesInvoiceDocumentNo: Code[20]): Boolean
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        O365MarkAsPaid: Page "O365 Mark As Paid";
        PaymentPostingWindow: Dialog;
    begin
        if not SalesInvoiceHeader.Get(SalesInvoiceDocumentNo) then
            exit(false);

        if not CalculatePaymentRegistrationBuffer(SalesInvoiceDocumentNo, TempPaymentRegistrationBuffer) then
            exit(false);

        O365MarkAsPaid.SetPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);

        if O365MarkAsPaid.RunModal() = ACTION::OK then begin
            PaymentPostingWindow.HideSubsequentDialogs(true);
            PaymentPostingWindow.Open('#1#################################');
            PaymentPostingWindow.Update(1, PostingPaymentDialogMsg);

            PaymentRegistrationMgt.Post(TempPaymentRegistrationBuffer, false);

            PaymentPostingWindow.Close();

            SalesInvoiceHeader.CalcFields("Amount Including VAT");
            if TempPaymentRegistrationBuffer."Amount Received" <> SalesInvoiceHeader."Amount Including VAT" then
                Session.LogMessage('0000246', InvoicePartiallyPaidTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SentInvoiceCategoryLbl)
            else
                Session.LogMessage('0000247', InvoiceFullyPaidTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SentInvoiceCategoryLbl);

            Message(MarkedPaidMsg);
            exit(true);
        end;

        exit(false);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure CancelSalesInvoicePayment(SalesInvoiceDocumentNo: Code[20]): Boolean
    var
        TempO365PaymentHistoryBuffer: Record "O365 Payment History Buffer" temporary;
    begin
        TempO365PaymentHistoryBuffer.FillPaymentHistory(SalesInvoiceDocumentNo);
        case TempO365PaymentHistoryBuffer.Count of
            0:
                exit(true); // All payments for the invoice has already been cancelled :)
            1:
                if TempO365PaymentHistoryBuffer.FindFirst() then
                    exit(TempO365PaymentHistoryBuffer.CancelPayment());
            else
                // There are multiple payments, so show the history list instead and let the user specify the entries to cancel
                exit(ShowHistory(SalesInvoiceDocumentNo));
        end;
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure CancelCustLedgerEntry(CustomerLedgerEntry: Integer)
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        PaymentCustLedgerEntry: Record "Cust. Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        if not PaymentCustLedgerEntry.Get(CustomerLedgerEntry) then
            exit;

        // Get detailed ledger entry for the payment, making sure it's a payment
        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::Payment);
        DetailedCustLedgEntry.SetRange("Document No.", PaymentCustLedgerEntry."Document No.");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustomerLedgerEntry);
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        if not DetailedCustLedgEntry.FindLast() then
            Error(NoDetailedCustomerLedgerEntryForPaymentErr);

        ApplyUnapplyParameters."Document No." := DetailedCustLedgEntry."Document No.";
        ApplyUnapplyParameters."Posting Date" := DetailedCustLedgEntry."Posting Date";
        CustEntryApplyPostedEntries.PostUnApplyCustomerCommit(DetailedCustLedgEntry, ApplyUnapplyParameters, false);

        ReversalEntry.SetHideWarningDialogs();
        ReversalEntry.ReverseTransaction(PaymentCustLedgerEntry."Transaction No.");

        Session.LogMessage('0000248', InvoicePaymentRemovedTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SentInvoiceCategoryLbl);

        Message(MarkedUnpaidMsg);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure GetPaymentCustLedgerEntry(var PaymentCustLedgerEntry: Record "Cust. Ledger Entry"; SalesInvoiceDocumentNo: Code[20]): Boolean
    var
        InvoiceCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Find the customer ledger entry related to the invoice
        InvoiceCustLedgerEntry.SetRange("Document Type", InvoiceCustLedgerEntry."Document Type"::Invoice);
        InvoiceCustLedgerEntry.SetRange("Document No.", SalesInvoiceDocumentNo);
        if not InvoiceCustLedgerEntry.FindFirst() then
            exit(false); // The invoice does not exist

        // find the customer ledger entry related to the payment of the invoice
        if not PaymentCustLedgerEntry.Get(InvoiceCustLedgerEntry."Closed by Entry No.") then
            exit(false); // The invoice has not been closed

        exit(true);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure CalculatePaymentRegistrationBuffer(SalesInvoiceDocumentNo: Code[20]; var PaymentRegistrationBuffer: Record "Payment Registration Buffer"): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Returns whether the table has been filled
        if not SalesInvoiceHeader.Get(SalesInvoiceDocumentNo) then
            exit(false);

        if not CollectRemainingPayments(SalesInvoiceDocumentNo, PaymentRegistrationBuffer) then
            exit(false); // Invoice has already been paid

        PaymentRegistrationBuffer.Validate("Payment Made", true);
        PaymentRegistrationBuffer.Validate("Limit Amount Received", true);
        PaymentRegistrationBuffer.Modify(true);

        exit(true);
    end;
#endif
    procedure CollectRemainingPayments(SalesInvoiceDocumentNo: Code[20]; var PaymentRegistrationBuffer: Record "Payment Registration Buffer"): Boolean
    begin
        PaymentRegistrationBuffer.PopulateTable();
        PaymentRegistrationBuffer.SetRange("Document Type", PaymentRegistrationBuffer."Document Type"::Invoice);
        PaymentRegistrationBuffer.SetRange("Document No.", SalesInvoiceDocumentNo);
        exit(PaymentRegistrationBuffer.FindFirst());
    end;
#if not CLEAN21
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure SetPaypalDefault()
    var
        DummyPaymentServiceSetup: Record "Payment Service Setup";
        PaypalAccountProxy: Codeunit "Paypal Account Proxy";
    begin
        DummyPaymentServiceSetup.OnDoNotIncludeAnyPaymentServicesOnAllDocuments();
        PaypalAccountProxy.SetAlwaysIncludePaypalOnDocuments(true, true);
        UpdatePaymentServicesForInvoicesQuotesAndOrders();
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure SetMspayDefault()
    var
        DummyPaymentServiceSetup: Record "Payment Service Setup";
        PaypalAccountProxy: Codeunit "Paypal Account Proxy";
    begin
        DummyPaymentServiceSetup.OnDoNotIncludeAnyPaymentServicesOnAllDocuments();
        PaypalAccountProxy.SetAlwaysIncludeMsPayOnDocuments(true, true);
        UpdatePaymentServicesForInvoicesQuotesAndOrders();
    end;
#endif
    procedure UpdatePaymentServicesForInvoicesQuotesAndOrders()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetFilter("Document Type", '%1|%2|%3', SalesHeader."Document Type"::Invoice,
          SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Order);

        if SalesHeader.FindSet(true, false) then
            repeat
                SalesHeader.SetDefaultPaymentServices();
                SalesHeader.Modify(true);
            until SalesHeader.Next() = 0;
    end;
#if not CLEAN21
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure OnPayPalEmailSetToEmpty()
    begin
        SetMspayDefault();
    end;
#endif
}

