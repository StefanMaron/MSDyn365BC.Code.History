// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 12178 "SEPA CT CBI-Check Line"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        Rec.DeletePaymentFileErrors();
        CheckGenJnlLine(Rec);
        CheckCustVend(Rec);
    end;

    var
        MustBeBankAccErr: Label 'The balancing account must be a bank account.';
        MustBeVendorOrCustomerErr: Label 'The account must be a vendor or customer account.';
        MustBeVendPmtOrCustRefundErr: Label 'Only vendor payments and customer refunds are allowed.';
        MustBePositiveErr: Label 'The amount must be positive.';
        TransferDateErr: Label 'The earliest possible transfer date is today.';
        EuroCurrErr: Label 'Only transactions in euro (EUR) are allowed.';
        MissingBankAccErr: Label '%1 has no bank account.', Comment = '%1=customer or vendor.';
        FieldBlankErr: Label '%1 must have a value in %2.', Comment = '%1=table name, %2=field name. Example: Customer must have a value in Name.';
        FieldKeyBlankErr: Label '%1 %2 must have a value in %3.', Comment = '%1=table name, %2=key field value, %3=field name. Example: Customer 10000 must have a value in Name.';

    [Scope('OnPrem')]
    procedure CheckGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        with GenJnlLine do begin
            if "Bal. Account Type" <> "Bal. Account Type"::"Bank Account" then
                InsertPaymentFileError(MustBeBankAccErr);

            if "Bal. Account No." = '' then
                AddFieldEmptyError(GenJnlLine, TableCaption(), FieldCaption("Bal. Account No."), '');

            if "Recipient Bank Account" = '' then
                AddFieldEmptyError(GenJnlLine, TableCaption(), FieldCaption("Recipient Bank Account"), '');

            if not ("Account Type" in ["Account Type"::Vendor, "Account Type"::Customer]) then
                InsertPaymentFileError(MustBeVendorOrCustomerErr);

            if (("Account Type" = "Account Type"::Vendor) and ("Document Type" <> "Document Type"::Payment)) or
               (("Account Type" = "Account Type"::Customer) and ("Document Type" <> "Document Type"::Refund))
            then
                InsertPaymentFileError(StrSubstNo(MustBeVendPmtOrCustRefundErr));

            if Amount <= 0 then
                InsertPaymentFileError(MustBePositiveErr);

            if "Currency Code" <> GLSetup.GetCurrencyCode('EUR') then
                InsertPaymentFileError(EuroCurrErr);

            if "Posting Date" < Today then
                InsertPaymentFileError(TransferDateErr);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckCustVend(var GenJnlLine: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        Vendor: Record Vendor;
    begin
        with GenJnlLine do begin
            if "Account No." = '' then begin
                InsertPaymentFileError(MustBeVendorOrCustomerErr);
                exit;
            end;
            case "Account Type" of
                "Account Type"::Customer:
                    begin
                        Customer.Get("Account No.");
                        if Customer.Name = '' then
                            AddFieldEmptyError(GenJnlLine, Customer.TableCaption(), Customer.FieldCaption(Name), "Account No.");
                        if "Recipient Bank Account" = '' then
                            InsertPaymentFileError(StrSubstNo(MissingBankAccErr, Customer.TableCaption()))
                        else begin
                            CustomerBankAccount.Get(Customer."No.", "Recipient Bank Account");
                            if CustomerBankAccount."SWIFT Code" = '' then
                                AddFieldEmptyError(
                                  GenJnlLine, CustomerBankAccount.TableCaption(), CustomerBankAccount.FieldCaption("SWIFT Code"),
                                  "Recipient Bank Account");
                            if CustomerBankAccount.IBAN = '' then
                                AddFieldEmptyError(
                                  GenJnlLine, CustomerBankAccount.TableCaption(), CustomerBankAccount.FieldCaption(IBAN), "Recipient Bank Account");
                        end;
                    end;
                "Account Type"::Vendor:
                    begin
                        Vendor.Get("Account No.");
                        if Vendor.Name = '' then
                            AddFieldEmptyError(GenJnlLine, Vendor.TableCaption(), Vendor.FieldCaption(Name), "Account No.");
                        if "Recipient Bank Account" = '' then
                            InsertPaymentFileError(StrSubstNo(MissingBankAccErr, Vendor.TableCaption()));
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
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
}

