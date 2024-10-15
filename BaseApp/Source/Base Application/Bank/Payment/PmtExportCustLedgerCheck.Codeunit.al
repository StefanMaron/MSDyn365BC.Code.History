namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Sales.Receivables;

codeunit 1213 "Pmt. Export Cust. Ledger Check"
{
    TableNo = "Cust. Ledger Entry";

    trigger OnRun()
    begin
        CheckDocumentType(Rec);
        CheckRefundInfo(Rec);
        CheckPaymentMethod(Rec);
        CheckBalAccountType(Rec);
        CheckBankAccount(Rec);
        CheckBalAccountNo(Rec);

        OnPmtExportCustLedgerCheck(Rec);
    end;

    var
        RecipientBankAccMissingErr: Label '%1 for one or more %2 is not specified.', Comment = '%1=Field;%2=Table';
        WrongFieldValueErr: Label '%1 for one or more %2 is different from %3.', Comment = '%1=Field;%2=Table;%3=Value';
#pragma warning disable AA0470
        MissingPmtMethodErr: Label '%1 must be used for payments.';
#pragma warning restore AA0470

    local procedure CheckDocumentType(var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        CustLedgEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry2.Copy(CustLedgEntry);
        CustLedgEntry2.SetFilter("Document Type", '<>%1', CustLedgEntry2."Document Type"::Refund);

        if not CustLedgEntry2.IsEmpty() then
            Error(WrongFieldValueErr,
              CustLedgEntry2.FieldCaption("Document Type"), CustLedgEntry2.TableCaption(), CustLedgEntry2."Document Type"::Refund);
    end;

    local procedure CheckRefundInfo(var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        CustLedgEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry2.Copy(CustLedgEntry);
        CustLedgEntry2.SetRange("Recipient Bank Account", '');

        if not CustLedgEntry2.IsEmpty() then
            Error(RecipientBankAccMissingErr, CustLedgEntry2.FieldCaption("Recipient Bank Account"), CustLedgEntry2.TableCaption());
    end;

    local procedure CheckPaymentMethod(var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        CustLedgEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry2.Copy(CustLedgEntry);
        CustLedgEntry2.SetRange("Payment Method Code", '');

        if not CustLedgEntry2.IsEmpty() then
            Error(MissingPmtMethodErr, CustLedgEntry2.FieldCaption("Payment Method Code"));
    end;

    local procedure CheckBalAccountType(var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        CustLedgEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry2.Copy(CustLedgEntry);
        CustLedgEntry2.SetFilter("Bal. Account Type", '<>%1', CustLedgEntry2."Bal. Account Type"::"Bank Account");

        if not CustLedgEntry2.IsEmpty() then
            Error(WrongFieldValueErr, CustLedgEntry2.FieldCaption("Bal. Account Type"),
              CustLedgEntry2.TableCaption(), CustLedgEntry2."Bal. Account Type"::"Bank Account");
    end;

    local procedure CheckBalAccountNo(var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        CustLedgEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry2.Copy(CustLedgEntry);
        CustLedgEntry2.SetRange("Bal. Account Type", CustLedgEntry2."Bal. Account Type"::"Bank Account");
        CustLedgEntry2.SetFilter("Bal. Account No.", '<>%1', CustLedgEntry."Bal. Account No.");

        if not CustLedgEntry2.IsEmpty() then
            Error(WrongFieldValueErr, CustLedgEntry2.FieldCaption("Bal. Account No."),
              CustLedgEntry2.TableCaption(), CustLedgEntry."Bal. Account No.");
    end;

    local procedure CheckBankAccount(var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(CustLedgEntry."Bal. Account No.");
        BankAccount.TestField("Payment Export Format");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPmtExportCustLedgerCheck(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

