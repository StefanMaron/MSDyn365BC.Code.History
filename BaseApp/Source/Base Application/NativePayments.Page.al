page 2831 "Native - Payments"
{
    Caption = 'nativePayments', Locked = true;
    DelayedInsert = true;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Native - Payment";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(paymentNo; "Payment No.")
                {
                    ApplicationArea = All;
                    Caption = 'paymentNo', Locked = true;
                    Editable = false;

                    trigger OnValidate()
                    begin
                        Error(PaymentNoShouldNotBeSpecifiedErr);
                    end;
                }
                field(customerId; "Customer Id")
                {
                    ApplicationArea = All;
                    Caption = 'customerId', Locked = true;

                    trigger OnValidate()
                    var
                        Customer: Record Customer;
                    begin
                        Customer.SetRange(Id, "Customer Id");
                        if not Customer.FindFirst then
                            Error(CustomerIdDoesNotMatchACustomerErr);

                        "Customer No." := Customer."No.";
                    end;
                }
                field(paymentDate; "Payment Date")
                {
                    ApplicationArea = All;
                    Caption = 'paymentDate', Locked = true;
                }
                field(amount; Amount)
                {
                    ApplicationArea = All;
                    Caption = 'amount', Locked = true;

                    trigger OnValidate()
                    begin
                        if Amount <= 0 then
                            Error(AmountShouldBePositiveErr);

                        Amount := -Amount;
                    end;
                }
                field(appliesToInvoiceId; "Applies-to Invoice Id")
                {
                    ApplicationArea = All;
                    Caption = 'appliesToInvoiceId', Locked = true;

                    trigger OnValidate()
                    var
                        SalesInvoiceHeader: Record "Sales Invoice Header";
                    begin
                        SalesInvoiceHeader.Reset();
                        SalesInvoiceHeader.SetRange(Id, "Applies-to Invoice Id");
                        if not SalesInvoiceHeader.FindFirst then
                            Error(AppliesToInvoiceIdDoesNotMatchAPostedInvoiceErr);

                        "Applies-to Invoice No." := SalesInvoiceHeader."No.";

                        if "Customer No." = '' then begin
                            if SalesInvoiceHeader."Bill-to Customer No." <> '' then
                                "Customer No." := SalesInvoiceHeader."Bill-to Customer No."
                            else
                                "Customer No." := SalesInvoiceHeader."Sell-to Customer No.";
                        end;
                    end;
                }
                field(paymentMethodId; "Payment Method Id")
                {
                    ApplicationArea = All;
                    Caption = 'paymentMethodId', Locked = true;

                    trigger OnValidate()
                    var
                        PaymentMethod: Record "Payment Method";
                    begin
                        PaymentMethod.SetRange(Id, "Payment Method Id");
                        if not PaymentMethod.FindFirst then
                            Error(PaymentMethodIdDoesNotMatchAPaymentMethodErr);

                        "Payment Method Code" := PaymentMethod.Code;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnDeleteRecord(): Boolean
    begin
        if not TempNativePayment.FindLast then
            exit(false);

        if RecordId <> TempNativePayment.RecordId then
            Error(CanOnlyCancelLastPaymentErr);

        NativePayments.CancelCustLedgerEntry("Ledger Entry No.");
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        AppliesToInvoiceIdFilter: Text;
        FilterView: Text;
    begin
        if not PaymentsLoaded then begin
            FilterView := GetView;
            AppliesToInvoiceIdFilter := GetFilter("Applies-to Invoice Id");
            if AppliesToInvoiceIdFilter <> '' then
                NativePayments.LoadPayments(TempNativePayment, AppliesToInvoiceIdFilter)
            else
                NativePayments.LoadAllPayments(TempNativePayment);
            Copy(TempNativePayment, true);

            SetView(FilterView);
            if not FindFirst then
                exit(false);
            PaymentsLoaded := true;
        end;

        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CheckNecessaryFields;

        // It does not get validated automatically
        Validate("Applies-to Invoice Id", "Applies-to Invoice Id");

        VerifyPaymentDate("Payment Date", "Applies-to Invoice Id");
        CheckIfAmountExceedsRemainingAmount(Amount, "Applies-to Invoice No.", "Payment Date");

        NativePayments.InsertJournalLine(Rec, GenJournalLine);
        NativePayments.PostJournal(GenJournalLine);

        NativePayments.LoadPayments(Rec, "Applies-to Invoice Id");
        FindLast;

        exit(false);
    end;

    var
        PaymentNoShouldNotBeSpecifiedErr: Label 'The paymentNo field must not be specified.';
        CustomerIdDoesNotMatchACustomerErr: Label 'The customerId field does not match an existing customer.', Locked = true;
        AppliesToInvoiceIdDoesNotMatchAPostedInvoiceErr: Label 'The appliesToInvoiceId field must be the ID of an Open, Paid, Corrective, or Canceled Invoice.', Locked = true;
        PaymentMethodIdDoesNotMatchAPaymentMethodErr: Label 'The paymentMethodId field does not match a payment method.', Locked = true;
        AmountShouldBePositiveErr: Label 'The amount must be a positive number.';
        AppliesToInvoiceIdShouldBeSpecifiedErr: Label 'The appliesToInvoiceId field must be specified.';
        PaymentMethodIdShouldBeSpecifiedErr: Label 'The paymentMethodId field must be specified.';
        AmountExceedsRemainingAmountErr: Label 'The amount exceeds the remaining amount of the invoice.';
        AmountExceedsRemainingDiscountAmountErr: Label 'The amount exceeds the remaining amount after discount of the invoice.';
        TempNativePayment: Record "Native - Payment" temporary;
        NativePayments: Codeunit "Native - Payments";
        PaymentsLoaded: Boolean;
        CanOnlyCancelLastPaymentErr: Label 'Only the last payment can be canceled.';
        PaymentDateBeforeInvoicePostingDateErr: Label 'The payment date has to be after the invoice date of the invoice the payment is applied to.';

    local procedure CheckNecessaryFields()
    var
        BlankGUID: Guid;
    begin
        if "Applies-to Invoice Id" = BlankGUID then
            Error(AppliesToInvoiceIdShouldBeSpecifiedErr);

        if "Payment Method Id" = BlankGUID then
            Error(PaymentMethodIdShouldBeSpecifiedErr);
    end;

    procedure CheckIfAmountExceedsRemainingAmount(PaymentAmount: Decimal; InvoiceNumber: Code[20]; PostingDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalRemainingAmount: Decimal;
        RemAmountAfterDiscount: Decimal;
        PmtDiscountDate: Date;
    begin
        CustLedgerEntry.SetRange("Document No.", InvoiceNumber);
        CustLedgerEntry.FindFirst;
        CustLedgerEntry.CalcFields("Remaining Amount");
        OriginalRemainingAmount := CustLedgerEntry."Remaining Amount";
        RemAmountAfterDiscount := OriginalRemainingAmount - CustLedgerEntry."Remaining Pmt. Disc. Possible";
        PmtDiscountDate := CustLedgerEntry."Pmt. Discount Date";

        if Abs(PaymentAmount) > Abs(OriginalRemainingAmount) then
            Error(AmountExceedsRemainingAmountErr);

        if (PostingDate <= PmtDiscountDate) and
           (Abs(PaymentAmount) > RemAmountAfterDiscount)
        then
            Error(AmountExceedsRemainingDiscountAmountErr);
    end;

    local procedure VerifyPaymentDate(PaymentDate: Date; InvoiceId: Guid)
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
    begin
        SalesInvoiceEntityAggregate.SetRange(Id, InvoiceId);
        SalesInvoiceEntityAggregate.FindFirst;
        if PaymentDate < SalesInvoiceEntityAggregate."Document Date" then
            Error(PaymentDateBeforeInvoicePostingDateErr);
    end;
}

