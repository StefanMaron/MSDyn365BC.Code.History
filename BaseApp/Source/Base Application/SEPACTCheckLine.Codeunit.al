codeunit 1223 "SEPA CT-Check Line"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        DeletePaymentFileErrors;
        CheckGenJnlLine(Rec);
        CheckBank(Rec);
        CheckCustVendEmpl(Rec);
    end;

    var
        MustBeBankAccErr: Label 'The balancing account must be a bank account.';
        MustBeVendorEmployeeOrCustomerErr: Label 'The account must be a vendor, customer or employee account.';
        MustBeVendEmplPmtOrCustRefundErr: Label 'Only vendor and employee payments and customer refunds are allowed.';
        MustBePositiveErr: Label 'The amount must be positive.';
        TransferDateErr: Label 'The earliest possible transfer date is today.';
        EuroCurrErr: Label 'Only transactions in euro (EUR) are allowed, because the %1 bank account is set up to use the %2 export format.', Comment = '%1= bank account No, %2 export format; Example: Only transactions in euro (EUR) are allowed, because the GIRO bank account is set up to use the SEPACT export format.';
        FieldBlankErr: Label 'The %1 field must be filled.', Comment = '%1= field name. Example: The Name field must be filled.';
        FieldKeyBlankErr: Label '%1 %2 must have a value in %3.', Comment = '%1=table name, %2=key field value, %3=field name. Example: Customer 10000 must have a value in Name.';

    local procedure CheckGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GLSetup: Record "General Ledger Setup";
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGenJnlLine(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        if GenJournalBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name") then
            GenJournalBatch.OnCheckGenJournalLineExportRestrictions;

        with GenJnlLine do begin
            if "Bal. Account Type" <> "Bal. Account Type"::"Bank Account" then
                InsertPaymentFileError(MustBeBankAccErr);

            if "Bal. Account No." = '' then
                AddFieldEmptyError(GenJnlLine, TableCaption, FieldCaption("Bal. Account No."), '');

            if "Recipient Bank Account" = '' then
                AddFieldEmptyError(GenJnlLine, TableCaption, FieldCaption("Recipient Bank Account"), '');

            if not ("Account Type" in ["Account Type"::Vendor, "Account Type"::Customer, "Account Type"::Employee]) then
                InsertPaymentFileError(MustBeVendorEmployeeOrCustomerErr);

            if (("Account Type" = "Account Type"::Vendor) and ("Document Type" <> "Document Type"::Payment)) or
               (("Account Type" = "Account Type"::Customer) and ("Document Type" <> "Document Type"::Refund)) or
               (("Account Type" = "Account Type"::Employee) and ("Document Type" <> "Document Type"::Payment))
            then
                InsertPaymentFileError(StrSubstNo(MustBeVendEmplPmtOrCustRefundErr));

            if Amount <= 0 then
                InsertPaymentFileError(MustBePositiveErr);

            if ("Currency Code" <> GLSetup.GetCurrencyCode('EUR')) and not GLSetup."SEPA Non-Euro Export" then begin
                BankAccount.Get("Bal. Account No.");
                InsertPaymentFileError(StrSubstNo(EuroCurrErr, "Bal. Account No.", BankAccount."Payment Export Format"));
            end;

            if "Posting Date" < Today then
                InsertPaymentFileError(TransferDateErr);
        end;

        OnAfterCheckGenJnlLine(GenJnlLine);
    end;

    local procedure CheckBank(var GenJnlLine: Record "Gen. Journal Line")
    var
        BankAccount: Record "Bank Account";
    begin
        with GenJnlLine do
            if BankAccount.Get("Bal. Account No.") then begin
                if BankAccount.IBAN = '' then
                    AddFieldEmptyError(GenJnlLine, BankAccount.TableCaption, BankAccount.FieldCaption(IBAN), "Bal. Account No.");
            end;
    end;

    local procedure CheckCustVendEmpl(var GenJnlLine: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        Employee: Record Employee;
    begin
        with GenJnlLine do begin
            if "Account No." = '' then begin
                InsertPaymentFileError(MustBeVendorEmployeeOrCustomerErr);
                exit;
            end;
            case "Account Type" of
                "Account Type"::Customer:
                    begin
                        Customer.Get("Account No.");
                        if Customer.Name = '' then
                            AddFieldEmptyError(GenJnlLine, Customer.TableCaption, Customer.FieldCaption(Name), "Account No.");
                        if "Recipient Bank Account" <> '' then begin
                            CustomerBankAccount.Get(Customer."No.", "Recipient Bank Account");
                            if CustomerBankAccount.IBAN = '' then
                                AddFieldEmptyError(
                                  GenJnlLine, CustomerBankAccount.TableCaption, CustomerBankAccount.FieldCaption(IBAN), "Recipient Bank Account");
                        end;
                    end;
                "Account Type"::Vendor:
                    begin
                        Vendor.Get("Account No.");
                        if Vendor.Name = '' then
                            AddFieldEmptyError(GenJnlLine, Vendor.TableCaption, Vendor.FieldCaption(Name), "Account No.");
                        if "Recipient Bank Account" <> '' then begin
                            VendorBankAccount.Get(Vendor."No.", "Recipient Bank Account");
                            if VendorBankAccount.IBAN = '' then
                                AddFieldEmptyError(
                                  GenJnlLine, VendorBankAccount.TableCaption, VendorBankAccount.FieldCaption(IBAN), "Recipient Bank Account");
                        end;
                    end;
                "Account Type"::Employee:
                    begin
                        Employee.Get("Account No.");
                        if Employee.FullName = '' then
                            AddFieldEmptyError(GenJnlLine, Employee.TableCaption, Employee.FieldCaption("First Name"), "Account No.");
                        if "Recipient Bank Account" <> '' then begin
                            if Employee.IBAN = '' then
                                AddFieldEmptyError(
                                  GenJnlLine, Employee.TableCaption, Employee.FieldCaption(IBAN), "Recipient Bank Account");
                        end;
                    end;
            end;
        end;
    end;

    local procedure AddFieldEmptyError(var GenJnlLine: Record "Gen. Journal Line"; TableCaption: Text; FieldCaption: Text; KeyValue: Text)
    var
        ErrorText: Text;
    begin
        if KeyValue = '' then
            ErrorText := StrSubstNo(FieldBlankErr, FieldCaption)
        else
            ErrorText := StrSubstNo(FieldKeyBlankErr, TableCaption, KeyValue, FieldCaption);
        GenJnlLine.InsertPaymentFileError(ErrorText);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

