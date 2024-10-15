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
        SelectedRecordTxt: Label 'the currently selected record';
        PartnerTypeBlankErr: Label '%1 must be filled.', Comment = 'Partner Type must be filled.';

    local procedure CheckCollectionEntry(DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        DirectDebitCollection: Record "Direct Debit Collection";
        GLSetup: Record "General Ledger Setup";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CHMgt: Codeunit CHMgt;
        SwissExport: Boolean;
    begin
        SwissExport := CHMgt.IsSwissSEPADDExport(DirectDebitCollectionEntry."Direct Debit Collection No.");
        GLSetup.Get;
        with DirectDebitCollectionEntry do begin
            if "Transfer Amount" <= 0 then
                InsertPaymentFileError(MustBePositiveErr);

            if not SwissExport and ("Currency Code" <> GLSetup.GetCurrencyCode('EUR')) then
                InsertPaymentFileError(EuroCurrErr);

            if "Transfer Date" < Today then
                InsertPaymentFileError(TransferDateErr);

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
                    if CustomerBankAccount."SWIFT Code" = '' then
                        AddFieldEmptyError(
                          DirectDebitCollectionEntry, CustomerBankAccount.TableCaption, CustomerBankAccount.FieldCaption("SWIFT Code"),
                          CustomerBankAccount.Code);
                    if CustomerBankAccount.IBAN = '' then
                        AddFieldEmptyError(
                          DirectDebitCollectionEntry, CustomerBankAccount.TableCaption, CustomerBankAccount.FieldCaption(IBAN),
                          CustomerBankAccount.Code);
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
}

