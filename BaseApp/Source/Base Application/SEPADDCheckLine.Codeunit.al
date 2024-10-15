codeunit 1233 "SEPA DD-Check Line"
{
    TableNo = "Direct Debit Collection Entry";

    trigger OnRun()
    begin
        DeletePaymentFileErrors;
        CheckCollectionEntry(Rec);
    end;

    var
        EuroCurrErr: Label 'Only transactions in euro (EUR) are allowed.';
        FieldBlankErr: Label '%1 must have a value in %2.', Comment = '%1=field name, %2=table name. Example: Name must have a value in Customer.';
        FieldKeyBlankErr: Label '%1 must have a value in %2 %3.', Comment = '%1=field name, %2= table name, %3=key field value. Example: Name must have a value in Customer 10000.';
        MustBeCustomerErr: Label 'The customer %1 does not exist.';
        MustBePositiveErr: Label 'The amount must be positive.';
        NotActiveMandateErr: Label 'The mandate %1 is not active.';
        PartnerTypeErr: Label 'The customer''s %1, %2, must be equal to the %1, %3, specified in the collection.', Comment = '%1 = Partner Type; %2 = Company/Person; %3 = Company/Person.';
        TransferDateErr: Label 'The earliest possible transfer date is today.';
        TransferDateAddnlInfoTxt: Label 'You can use the Reset Transfer Date action to eliminate the error.';
        SummarizeNotAllowedErr: Label 'You cannot export a SEPA customer payment that is applied to multiple documents. Make sure that the Summarize per field in the Suggest Customer Payments window is blank.';
        UnappliedLinesNotAllowedErr: Label 'Payment slip line %1 must be applied to a customer invoice.';
        AccTypeErr: Label 'Only customer transactions are allowed.';
        BankAccErr: Label 'You must use customer bank account, %1, which you specified in the selected direct debit mandate.';
        SelectedRecordTxt: Label 'the currently selected record';
        PartnerTypeBlankErr: Label '%1 must be filled.', Comment = 'Partner Type must be filled.';
        ExportWithoutIBANAndSWIFTErr: Label 'Either the Bank Account No. and Bank Branch No. fields or the SWIFT Code and IBAN fields must be filled in for %1 %2.', Comment = '%1= table name, %2=key field value. Example: Either the Bank Account No. and Bank Branch No. fields or the SWIFT Code and IBAN fields must be filled in for Customer Bank Account ECA.';

    [Scope('OnPrem')]
    procedure CheckCollectionEntry(DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        DirectDebitCollection: Record "Direct Debit Collection";
        GLSetup: Record "General Ledger Setup";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        GLSetup.Get;
        with DirectDebitCollectionEntry do begin
            if "Transfer Amount" <= 0 then
                InsertPaymentFileError(MustBePositiveErr);

            if ("Currency Code" <> GLSetup.GetCurrencyCode('EUR')) and not GLSetup."SEPA Non-Euro Export" then
                InsertPaymentFileError(EuroCurrErr);

            if "Transfer Date" < Today then
                InsertPaymentFileErrorWithDetails(TransferDateErr, TransferDateAddnlInfoTxt);

            if not Customer.Get("Customer No.") then begin
                InsertPaymentFileError(StrSubstNo(MustBeCustomerErr, "Customer No."));
                exit;
            end;

            if Customer.Name = '' then
                AddFieldEmptyError(DirectDebitCollectionEntry, Customer.TableCaption, Customer.FieldCaption(Name), "Customer No.");

            DirectDebitCollection.Get("Direct Debit Collection No.");
            if Customer."Partner Type" <> DirectDebitCollection."Partner Type" then
                InsertPaymentFileError(StrSubstNo(PartnerTypeErr, Customer.FieldCaption("Partner Type"), Customer."Partner Type",
                    DirectDebitCollection."Partner Type"));

            if DirectDebitCollection."Partner Type" = DirectDebitCollection."Partner Type"::" " then
                InsertPaymentFileError(StrSubstNo(PartnerTypeBlankErr, DirectDebitCollection.FieldCaption("Partner Type")));

            if "Mandate ID" = '' then
                AddFieldEmptyError(DirectDebitCollectionEntry, SelectedRecordTxt, FieldCaption("Mandate ID"), "Mandate ID")
            else begin
                SEPADirectDebitMandate.Get("Mandate ID");
                if SEPADirectDebitMandate."Date of Signature" = 0D then
                    AddFieldEmptyError(
                      DirectDebitCollectionEntry, SEPADirectDebitMandate.TableCaption, SEPADirectDebitMandate.FieldCaption("Date of Signature"),
                      "Mandate ID");
                if not SEPADirectDebitMandate.IsMandateActive("Transfer Date") then
                    InsertPaymentFileError(StrSubstNo(NotActiveMandateErr, "Mandate ID"));

                if SEPADirectDebitMandate."Customer Bank Account Code" = '' then
                    AddFieldEmptyError(
                      DirectDebitCollectionEntry, SEPADirectDebitMandate.TableCaption,
                      SEPADirectDebitMandate.FieldCaption("Customer Bank Account Code"), SEPADirectDebitMandate.ID)
                else begin
                    CustomerBankAccount.Get(Customer."No.", SEPADirectDebitMandate."Customer Bank Account Code");
                    if not GLSetup."SEPA Export w/o Bank Acc. Data" then begin
                        if CustomerBankAccount."SWIFT Code" = '' then
                            AddFieldEmptyError(
                              DirectDebitCollectionEntry, CustomerBankAccount.TableCaption, CustomerBankAccount.FieldCaption("SWIFT Code"),
                              CustomerBankAccount.Code);
                        if CustomerBankAccount.IBAN = '' then
                            AddFieldEmptyError(
                              DirectDebitCollectionEntry, CustomerBankAccount.TableCaption, CustomerBankAccount.FieldCaption(IBAN),
                              CustomerBankAccount.Code);
                    end else
                        if (CustomerBankAccount."Bank Account No." = '') or (CustomerBankAccount."Bank Branch No." = '') then
                            if (CustomerBankAccount."SWIFT Code" = '') or (CustomerBankAccount.IBAN = '') then
                                InsertPaymentFileError(
                                  StrSubstNo(ExportWithoutIBANAndSWIFTErr, CustomerBankAccount.TableCaption(), CustomerBankAccount.Code));
                end;
            end;
        end;
    end;

    local procedure AddFieldEmptyError(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; TableCaption: Text; FieldCaption: Text; KeyValue: Text)
    var
        ErrorText: Text;
    begin
        if KeyValue = '' then
            ErrorText := StrSubstNo(FieldBlankErr, FieldCaption, TableCaption)
        else
            ErrorText := StrSubstNo(FieldKeyBlankErr, FieldCaption, TableCaption, KeyValue);
        DirectDebitCollectionEntry.InsertPaymentFileError(ErrorText);
    end;

    [Scope('OnPrem')]
    procedure CheckPaymentLine(DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; PaymentLine: Record "Payment Line"; var AppliesToEntryNo: Integer): Boolean
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if PaymentLine."Account Type" <> PaymentLine."Account Type"::Customer then
            DirectDebitCollectionEntry.InsertPaymentFileError(AccTypeErr);

        if SEPADirectDebitMandate.Get(PaymentLine."Direct Debit Mandate ID") then
            if SEPADirectDebitMandate."Customer Bank Account Code" <> PaymentLine."Bank Account Code" then
                DirectDebitCollectionEntry.InsertPaymentFileError(StrSubstNo(BankAccErr, SEPADirectDebitMandate."Customer Bank Account Code"));

        if (PaymentLine."Applies-to Doc. No." = '') and (PaymentLine."Applies-to ID" = '') then
            DirectDebitCollectionEntry.InsertPaymentFileError(StrSubstNo(UnappliedLinesNotAllowedErr, PaymentLine."Line No."))
        else begin
            PaymentLine.GetAppliesToDocCustLedgEntry(CustLedgerEntry);
            if CustLedgerEntry.Count > 1 then
                DirectDebitCollectionEntry.InsertPaymentFileError(SummarizeNotAllowedErr);
            CustLedgerEntry.FindFirst;
            if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Invoice then
                DirectDebitCollectionEntry.InsertPaymentFileError(StrSubstNo(UnappliedLinesNotAllowedErr, PaymentLine."Line No."));
            AppliesToEntryNo := CustLedgerEntry."Entry No.";
        end;

        exit(not DirectDebitCollectionEntry.HasPaymentFileErrors);
    end;
}

