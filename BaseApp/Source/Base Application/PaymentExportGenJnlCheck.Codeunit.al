codeunit 1211 "Payment Export Gen. Jnl Check"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        CheckPaymentExportGenJnl(Rec);
    end;

    var
        EmptyPaymentDetailsErr: Label '%1 or %2 must be used for payments.', Comment = '%1=Field;%2=Field';
        SimultaneousPaymentDetailsErr: Label '%1 and %2 cannot be used simultaneously for payments.', Comment = '%1=Field;%2=Field';
        WrongBalAccountErr: Label '%1 for the %2 is different from %3 on %4: %5.', Comment = '%1=Field;%1=Table;%3=Value;%4=Table;%5=Value';
        MustBeVendorEmployeeOrCustomerErr: Label 'The account must be a vendor, customer or employee account.';
        MustBeVendEmplPmtOrCustRefundErr: Label 'Only vendor and employee payments and customer refunds are allowed.';
        MustBePositiveErr: Label 'The amount must be positive.';
        FieldBlankErr: Label '%1 must have a value in %2.', Comment = '%1=table name, %2=field name. Example: Customer must have a value in Name.';
        FieldKeyBlankErr: Label '%1 %2 must have a value in %3.', Comment = '%1=table name, %2=key field value, %3=field name. Example: Customer 10000 must have a value in Name.';
        TempGenJournalBatch: Record "Gen. Journal Batch" temporary;
        WrongBankPaymentTypeErr: Label '%1 must be either %2 or %3.', Comment = '%1=Bank Payment Type field caption, %2=Electronic Payment bank payment type, %3=Electronic Payment-IAT bank payment type';

    local procedure CheckPaymentExportGenJnl(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        Handled: Boolean;
    begin
        with GenJournalLine do begin
            DeletePaymentFileErrors;
            GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");

            if not TempGenJournalBatch.Get("Journal Template Name", "Journal Batch Name") then
                CheckGenJournalBatch(GenJournalLine, GenJnlBatch);

            if "Payment Method Code" = '' then
                AddFieldEmptyError(GenJournalLine, TableCaption, FieldCaption("Payment Method Code"), '');

            if ("Recipient Bank Account" <> '') and ("Creditor No." <> '') then
                InsertPaymentFileError(StrSubstNo(SimultaneousPaymentDetailsErr,
                    FieldCaption("Recipient Bank Account"), FieldCaption("Creditor No.")));

            if "Bal. Account Type" <> "Bal. Account Type"::"Bank Account" then
                InsertPaymentFileError(StrSubstNo(WrongBalAccountErr, FieldCaption("Bal. Account Type"),
                    TableCaption, "Bal. Account Type"::"Bank Account", GenJnlBatch.TableCaption, GenJnlBatch.Name));

            if "Bal. Account No." <> GenJnlBatch."Bal. Account No." then
                InsertPaymentFileError(StrSubstNo(WrongBalAccountErr, FieldCaption("Bal. Account No."),
                    TableCaption, GenJnlBatch."Bal. Account No.", GenJnlBatch.TableCaption, GenJnlBatch.Name));

            if Amount <= 0 then
                InsertPaymentFileError(MustBePositiveErr);

            if (("Account Type" = "Account Type"::"Bank Account") or
                ("Bal. Account Type" = "Bal. Account Type"::"Bank Account")) and
               (("Bank Payment Type" <> "Bank Payment Type"::"Electronic Payment") and
                ("Bank Payment Type" <> "Bank Payment Type"::"Electronic Payment-IAT"))
            then
                InsertPaymentFileError(StrSubstNo(WrongBankPaymentTypeErr, FieldCaption("Bank Payment Type"),
                    "Bank Payment Type"::"Electronic Payment", "Bank Payment Type"::"Electronic Payment-IAT"));

            OnPaymentExportGenJnlCheck(GenJournalLine, Handled);
            if not Handled then begin
                if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::Employee])
                then
                    InsertPaymentFileError(MustBeVendorEmployeeOrCustomerErr);

                if (("Account Type" = "Account Type"::Vendor) and
                    ("Document Type" <> "Document Type"::Payment)) or
                   (("Account Type" = "Account Type"::Customer) and
                    ("Document Type" <> "Document Type"::Refund)) or
                   (("Account Type" = "Account Type"::Employee) and
                    ("Document Type" <> "Document Type"::Payment))
                then
                    InsertPaymentFileError(MustBeVendEmplPmtOrCustRefundErr);

                if not ("Account Type" = "Account Type"::Employee) and
                   ("Recipient Bank Account" = '') and ("Creditor No." = '')
                then
                    InsertPaymentFileError(StrSubstNo(EmptyPaymentDetailsErr,
                        FieldCaption("Recipient Bank Account"), FieldCaption("Creditor No.")));
            end;
        end;
    end;

    procedure AddFieldEmptyError(var GenJnlLine: Record "Gen. Journal Line"; TableCaption: Text; FieldCaption: Text; KeyValue: Text)
    var
        ErrorText: Text;
    begin
        if KeyValue = '' then
            ErrorText := StrSubstNo(FieldBlankErr, TableCaption, FieldCaption)
        else
            ErrorText := StrSubstNo(FieldKeyBlankErr, TableCaption, KeyValue, FieldCaption);
        GenJnlLine.InsertPaymentFileError(ErrorText);
    end;

    procedure AddBatchEmptyError(var GenJnlLine: Record "Gen. Journal Line"; FieldCaption: Text; KeyValue: Variant)
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        AddFieldEmptyError(GenJnlLine, GenJnlBatch.TableCaption, FieldCaption, Format(KeyValue));
    end;

    local procedure CheckGenJournalBatch(GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    var
        BankAccount: Record "Bank Account";
    begin
        TempGenJournalBatch := GenJournalBatch;
        TempGenJournalBatch.Insert;

        GenJournalBatch.OnCheckGenJournalLineExportRestrictions;

        if not GenJournalBatch."Allow Payment Export" then
            AddBatchEmptyError(GenJournalLine, GenJournalBatch.FieldCaption("Allow Payment Export"), '');

        if GenJournalBatch."Bal. Account Type" <> GenJournalBatch."Bal. Account Type"::"Bank Account" then
            AddBatchEmptyError(GenJournalLine, GenJournalBatch.FieldCaption("Bal. Account Type"), GenJournalBatch."Bal. Account Type");

        if GenJournalBatch."Bal. Account No." = '' then
            AddBatchEmptyError(GenJournalLine, GenJournalBatch.FieldCaption("Bal. Account No."), GenJournalBatch."Bal. Account No.");

        if BankAccount.Get(GenJournalBatch."Bal. Account No.") then
            if BankAccount."Payment Export Format" = '' then
                GenJournalLine.InsertPaymentFileError(
                  StrSubstNo(FieldBlankErr, BankAccount.FieldCaption("Payment Export Format"), BankAccount.TableCaption));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPaymentExportGenJnlCheck(var GenJournalLine: Record "Gen. Journal Line"; var Handled: Boolean)
    begin
    end;
}

