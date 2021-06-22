codeunit 2831 "Native - Payments"
{

    trigger OnRun()
    begin
    end;

    var
        AppliesToInvoiceIDFilterNotSpecifiedErr: Label 'You must set the "appliesToInvoiceId" filter to get the payments.', Locked = true;
        AppliesToInvoiceIDFilterDoesNotMatchInvoiceErr: Label 'The "appliesToInvoiceId" filter does not match to a posted sales invoice.', Locked = true;
        NoDetailedCustomerLedgerEntryForPaymentErr: Label 'No Detailed Customer Ledger Entry could be found for the payment of the invoice.';

    procedure InsertJournalLine(NativePayment: Record "Native - Payment"; var GenJournalLine: Record "Gen. Journal Line")
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlTemplate: Record "Gen. Journal Template";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        PaymentRegistrationSetup.Get(UserId);
        PaymentRegistrationSetup.ValidateMandatoryFields(true);
        GenJnlTemplate.Get(PaymentRegistrationSetup."Journal Template Name");
        GenJnlBatch.Get(PaymentRegistrationSetup."Journal Template Name", PaymentRegistrationSetup."Journal Batch Name");

        GenJournalLine.SetRange("Journal Template Name", PaymentRegistrationSetup."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", PaymentRegistrationSetup."Journal Batch Name");
        if GenJournalLine.FindLast then
            GenJournalLine.SetFilter("Line No.", '>%1', GenJournalLine."Line No.");

        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := PaymentRegistrationSetup."Journal Template Name";
        GenJournalLine."Journal Batch Name" := PaymentRegistrationSetup."Journal Batch Name";
        GenJournalLine."Line No." += 10000;

        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Invoice;

        GenJournalLine.Validate("Posting Date", NativePayment."Payment Date");
        GenJournalLine."Document No." := NoSeriesMgt.GetNextNo(GenJnlBatch."No. Series", GenJournalLine."Posting Date", false);
        GenJournalLine.Validate("Bal. Account Type", PaymentRegistrationSetup.GetGLBalAccountType);
        GenJournalLine.Validate("Account No.", NativePayment."Customer No.");
        GenJournalLine.Validate(Amount, NativePayment.Amount);
        GenJournalLine.Validate("Bal. Account No.", PaymentRegistrationSetup."Bal. Account No.");
        GenJournalLine.Validate("Payment Method Code", NativePayment."Payment Method Code");
        GenJournalLine.Validate("Applies-to Doc. No.", NativePayment."Applies-to Invoice No.");

        GenJournalLine.Insert(true);
    end;

    procedure PostJournal(GenJournalLine: Record "Gen. Journal Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);
    end;

    procedure LoadAllPayments(var NativePayment: Record "Native - Payment")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if SalesInvoiceHeader.FindSet then begin
            repeat
                LoadPayments(NativePayment, SalesInvoiceHeader.Id);
            until SalesInvoiceHeader.Next = 0;
        end;
    end;

    procedure LoadPayments(var NativePayment: Record "Native - Payment"; AppliesToInvoiceIdFilter: Text)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InvoiceCustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentCustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentNo: Integer;
    begin
        if AppliesToInvoiceIdFilter = '' then
            Error(AppliesToInvoiceIDFilterNotSpecifiedErr);

        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetRange(Id, AppliesToInvoiceIdFilter);
        if not SalesInvoiceHeader.FindFirst then
            Error(AppliesToInvoiceIDFilterDoesNotMatchInvoiceErr);

        InvoiceCustLedgerEntry.SetRange("Document Type", InvoiceCustLedgerEntry."Document Type"::Invoice);
        InvoiceCustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        if not InvoiceCustLedgerEntry.FindFirst then
            exit;

        PaymentCustLedgerEntry.SetCurrentKey("Closed by Entry No.");
        PaymentCustLedgerEntry.SetRange("Closed by Entry No.", InvoiceCustLedgerEntry."Entry No.");
        if PaymentCustLedgerEntry.FindSet then begin
            repeat
                PaymentNo += 10000;
                Clear(NativePayment);
                NativePayment."Payment No." := PaymentNo;
                NativePayment."Applies-to Invoice Id" := AppliesToInvoiceIdFilter;
                SetValuesFromCustomerLedgerEntry(NativePayment, PaymentCustLedgerEntry);
                NativePayment.Insert();
            until PaymentCustLedgerEntry.Next = 0;
        end;

        if PaymentCustLedgerEntry.Get(InvoiceCustLedgerEntry."Closed by Entry No.") then begin
            PaymentNo += 10000;
            Clear(NativePayment);
            NativePayment."Payment No." := PaymentNo;
            NativePayment."Applies-to Invoice Id" := AppliesToInvoiceIdFilter;
            SetValuesFromCustomerLedgerEntry(NativePayment, PaymentCustLedgerEntry);
            NativePayment.Insert();
        end;
    end;

    local procedure SetValuesFromCustomerLedgerEntry(var NativePayment: Record "Native - Payment"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.CalcFields("Amount (LCY)");
        with NativePayment do begin
            Validate("Customer No.", CustLedgerEntry."Customer No.");
            "Payment Date" := CustLedgerEntry."Posting Date";
            Amount := -CustLedgerEntry."Amount (LCY)";
            Validate("Applies-to Invoice No.", CustLedgerEntry."Applies-to Doc. No.");
            Validate("Payment Method Code", CustLedgerEntry."Payment Method Code");
            Validate("Ledger Entry No.", CustLedgerEntry."Entry No.");
        end;
    end;

    procedure CancelCustLedgerEntry(CustomerLedgerEntry: Integer)
    var
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
        if not DetailedCustLedgEntry.FindLast then
            Error(NoDetailedCustomerLedgerEntryForPaymentErr);

        CustEntryApplyPostedEntries.PostUnApplyCustomerCommit(
          DetailedCustLedgEntry, DetailedCustLedgEntry."Document No.", DetailedCustLedgEntry."Posting Date", false);

        ReversalEntry.SetHideWarningDialogs;
        ReversalEntry.ReverseTransaction(PaymentCustLedgerEntry."Transaction No.");
    end;
}

