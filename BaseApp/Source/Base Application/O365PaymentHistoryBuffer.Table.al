table 2105 "O365 Payment History Buffer"
{
    Caption = 'O365 Payment History Buffer';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
#if CLEAN21
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; "Ledger Entry No."; Integer)
        {
            Caption = 'Ledger Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Entry";
        }
        field(2; Type; Enum "Gen. Journal Document Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(3; Amount; Decimal)
        {
            AutoFormatExpression = '1';
            AutoFormatType = 10;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(4; "Date Received"; Date)
        {
            Caption = 'Date Received';
            DataClassification = SystemMetadata;
        }
        field(5; "Payment Method"; Code[10])
        {
            Caption = 'Payment Method';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Ledger Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Date Received", Type, Amount, "Payment Method")
        {
        }
    }
#if not CLEAN21
    var
        CanOnlyCancelPaymentsErr: Label 'Only payment registrations can be canceled.';
        CanOnlyCancelLastPaymentErr: Label 'Only the last payment registration can be canceled.';
        DevMsgNotTemporaryErr: Label 'This function can only be used when the record is temporary.';
        O365SalesInvoicePayment: Codeunit "O365 Sales Invoice Payment";
        MarkAsUnpaidConfirmQst: Label 'Cancel this payment registration?';

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure FillPaymentHistory(SalesInvoiceDocumentNo: Code[20])
    var
        InvoiceCustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if not IsTemporary then
            Error(DevMsgNotTemporaryErr);

        Reset();
        DeleteAll();
        InvoiceCustLedgerEntry.SetRange("Document Type", InvoiceCustLedgerEntry."Document Type"::Invoice);
        InvoiceCustLedgerEntry.SetRange("Document No.", SalesInvoiceDocumentNo);
        if not InvoiceCustLedgerEntry.FindFirst() then
            exit;

        if PaymentCustLedgerEntry.Get(InvoiceCustLedgerEntry."Closed by Entry No.") then
            CopyFromCustomerLedgerEntry(PaymentCustLedgerEntry);

        PaymentCustLedgerEntry.SetCurrentKey("Closed by Entry No.");
        PaymentCustLedgerEntry.SetRange("Closed by Entry No.", InvoiceCustLedgerEntry."Entry No.");
        if PaymentCustLedgerEntry.FindSet() then
            repeat
                CopyFromCustomerLedgerEntry(PaymentCustLedgerEntry);
            until PaymentCustLedgerEntry.Next() = 0;
    end;

    local procedure CopyFromCustomerLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.CalcFields("Amount (LCY)");
        Init();
        "Ledger Entry No." := CustLedgerEntry."Entry No.";
        Type := CustLedgerEntry."Document Type";
        Amount := CustLedgerEntry."Amount (LCY)";
        if Type = Type::Payment then
            Amount := -Amount;
        "Date Received" := CustLedgerEntry."Posting Date";
        "Payment Method" := CustLedgerEntry."Payment Method Code";
        Insert(true);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure CancelPayment(): Boolean
    var
        TempO365PaymentHistoryBuffer: Record "O365 Payment History Buffer" temporary;
    begin
        if Type <> Type::Payment then
            Error(CanOnlyCancelPaymentsErr);
        TempO365PaymentHistoryBuffer.Copy(Rec, true);
        TempO365PaymentHistoryBuffer.SetFilter("Ledger Entry No.", '>%1', "Ledger Entry No.");
        if not TempO365PaymentHistoryBuffer.IsEmpty() then
            Error(CanOnlyCancelLastPaymentErr);
        if not Confirm(MarkAsUnpaidConfirmQst) then
            exit(false);

        O365SalesInvoicePayment.CancelCustLedgerEntry("Ledger Entry No.");
        exit(true);
    end;
#endif
}

