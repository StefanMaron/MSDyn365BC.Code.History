﻿namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Reflection;
using System.Utilities;

codeunit 1221 "SEPA CT-Fill Export Buffer"
{
    Permissions = TableData "Payment Export Data" = rimd;
    TableNo = "Payment Export Data";

    trigger OnRun()
    begin
    end;

    var
        HasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        FieldIsBlankErr: Label 'Field %1 must be specified.', Comment = '%1=field name, e.g. Post Code.';
        SameBankErr: Label 'All lines must have the same bank account as the balancing account.';
        RemitMsg: Label '%1 %2', Comment = '%1=Document type, %2=Document no., e.g. Invoice A123';

    procedure FillExportBuffer(var GenJnlLine: Record "Gen. Journal Line"; var PaymentExportData: Record "Payment Export Data")
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        GeneralLedgerSetup: Record "General Ledger Setup";
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
        TempInteger: Record "Integer" temporary;
        VendorBankAccount: Record "Vendor Bank Account";
        CustomerBankAccount: Record "Customer Bank Account";
        CreditTransferRegister: Record "Credit Transfer Register";
        CreditTransferEntry: Record "Credit Transfer Entry";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        MessageID: Code[20];
    begin
        TempGenJnlLine.CopyFilters(GenJnlLine);
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Prepare Source", TempGenJnlLine);

        TempGenJnlLine.Reset();
        TempGenJnlLine.FindSet();
        BankAccount.Get(TempGenJnlLine."Bal. Account No.");
        BankAccount.TestField(IBAN);
        BankAccount.GetBankExportImportSetup(BankExportImportSetup);
        BankExportImportSetup.TestField("Check Export Codeunit");
        TempGenJnlLine.DeletePaymentFileBatchErrors();
        repeat
            CODEUNIT.Run(BankExportImportSetup."Check Export Codeunit", TempGenJnlLine);
            if TempGenJnlLine."Bal. Account No." <> BankAccount."No." then
                TempGenJnlLine.InsertPaymentFileError(SameBankErr);
        until TempGenJnlLine.Next() = 0;

        if TempGenJnlLine.HasPaymentFileErrorsInBatch() then begin
            Commit();
            Error(HasErrorsErr);
        end;

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("LCY Code");

        MessageID := BankAccount.GetCreditTransferMessageNo();
        OnFillExportBufferOnAfterGetMessageID(TempGenJnlLine, MessageID);
        CreditTransferRegister.CreateNew(MessageID, BankAccount."No.");
        OnFillExportBufferOnAfterCreateNewRegister(CreditTransferRegister, BankExportImportSetup);

        PaymentExportData.Reset();
        if PaymentExportData.FindLast() then;

        TempGenJnlLine.FindSet();
        repeat
            PaymentExportData.Init();
            PaymentExportData."Entry No." += 1;
            PaymentExportData.SetPreserveNonLatinCharacters(BankExportImportSetup."Preserve Non-Latin Characters");
            PaymentExportData.SetBankAsSenderBank(BankAccount);
            PaymentExportData."Transfer Date" := TempGenJnlLine."Posting Date";
            if TempGenJnlLine."Bill No." <> '' then
                PaymentExportData."Document No." := TempGenJnlLine."Bill No."
            else
                PaymentExportData."Document No." := TempGenJnlLine."Document No.";
            PaymentExportData."Applies-to Ext. Doc. No." := TempGenJnlLine."Applies-to Ext. Doc. No.";
            PaymentExportData.Amount := TempGenJnlLine.Amount;
            if TempGenJnlLine."Currency Code" = '' then
                PaymentExportData."Currency Code" := GeneralLedgerSetup."LCY Code"
            else
                PaymentExportData."Currency Code" := TempGenJnlLine."Currency Code";

            case TempGenJnlLine."Account Type" of
                TempGenJnlLine."Account Type"::Customer:
                    begin
                        Customer.Get(TempGenJnlLine."Account No.");
                        CustomerBankAccount.Get(Customer."No.", TempGenJnlLine."Recipient Bank Account");
                        PaymentExportData.SetCustomerAsRecipient(Customer, CustomerBankAccount);
                        OnFillExportBufferOnAfterSetCustomerAsRecipient(PaymentExportData, TempGenJnlLine, Customer, CustomerBankAccount);
                    end;
                TempGenJnlLine."Account Type"::Vendor:
                    begin
                        Vendor.Get(TempGenJnlLine."Account No.");
                        VendorBankAccount.Get(Vendor."No.", TempGenJnlLine."Recipient Bank Account");
                        PaymentExportData.SetVendorAsRecipient(Vendor, VendorBankAccount);
                        OnFillExportBufferOnAfterSetVendorAsRecipient(PaymentExportData, TempGenJnlLine, Vendor, VendorBankAccount);
                    end;
                TempGenJnlLine."Account Type"::Employee:
                    begin
                        Employee.Get(TempGenJnlLine."Account No.");
                        PaymentExportData.SetEmployeeAsRecipient(Employee);
                    end;
                TempGenJnlLine."Account Type"::"Bank Account":
                    begin
                        BankAccount.Get(TempGenJnlLine."Account No.");
                        PaymentExportData.SetBankAsRecipient(BankAccount);
                        OnFillExportBufferOnAfterSetBankAsRecipient(PaymentExportData, TempGenJnlLine, BankAccount);
                    end;
                else
                    OnFillExportBufferOnSetAsRecipient(GenJnlLine, PaymentExportData, TempGenJnlLine, CreditTransferRegister);
            end;

            PaymentExportData.Validate(PaymentExportData."SEPA Instruction Priority", PaymentExportData."SEPA Instruction Priority"::NORMAL);
            PaymentExportData.Validate(PaymentExportData."SEPA Payment Method", PaymentExportData."SEPA Payment Method"::TRF);
            PaymentExportData.Validate(PaymentExportData."SEPA Charge Bearer", PaymentExportData."SEPA Charge Bearer"::SLEV);
            PaymentExportData."SEPA Batch Booking" := false;
            PaymentExportData.SetCreditTransferIDs(MessageID);

            if PaymentExportData."Applies-to Ext. Doc. No." <> '' then
                PaymentExportData.AddRemittanceText(StrSubstNo(RemitMsg, TempGenJnlLine."Applies-to Doc. Type", PaymentExportData."Applies-to Ext. Doc. No."))
            else
                PaymentExportData.AddRemittanceText(TempGenJnlLine.Description);
            if TempGenJnlLine."Message to Recipient" <> '' then
                PaymentExportData.AddRemittanceText(TempGenJnlLine."Message to Recipient");

            ValidatePaymentExportData(PaymentExportData, TempGenJnlLine);
            OnFillExportBufferOnBeforeInsertPaymentExportData(PaymentExportData, TempGenJnlLine);
            PaymentExportData.Insert(true);
            OnFillExportBufferOnAfterInsertPaymentExportData(PaymentExportData, TempGenJnlLine, BankExportImportSetup);
            TempInteger.DeleteAll();
            GetAppliesToDocEntryNumbers(TempGenJnlLine, TempInteger);
            if TempInteger.FindSet() then
                repeat
                    CreateNewCreditTransferEntry(
                        PaymentExportData, CreditTransferEntry, CreditTransferRegister, TempGenJnlLine, 0, TempInteger.Number);
                until TempInteger.Next() = 0
            else
                CreateNewCreditTransferEntry(
                    PaymentExportData, CreditTransferEntry, CreditTransferRegister, TempGenJnlLine,
                    CreditTransferEntry."Entry No." + 1, TempGenJnlLine.GetAppliesToDocEntryNo());
        until TempGenJnlLine.Next() = 0;

        OnAfterFillExportBuffer(PaymentExportData, BankExportImportSetup);
    end;

    local procedure CreateNewCreditTransferEntry(var PaymentExportData: Record "Payment Export Data"; var CreditTransferEntry: Record "Credit Transfer Entry"; CreditTransferRegister: Record "Credit Transfer Register"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; EntryNo: Integer; LedgerEntryNo: Integer)
    begin
        CreditTransferEntry.CreateNew(
            CreditTransferRegister."No.", EntryNo,
            TempGenJnlLine."Account Type", TempGenJnlLine."Account No.", LedgerEntryNo,
            PaymentExportData."Transfer Date", PaymentExportData."Currency Code", PaymentExportData.Amount,
            CopyStr(PaymentExportData."End-to-End ID", 1, MaxStrLen(PaymentExportData."End-to-End ID")),
            TempGenJnlLine."Recipient Bank Account", TempGenJnlLine."Message to Recipient");

        OnAfterCreateNewCreditTransferEntry(PaymentExportData, CreditTransferEntry, TempGenJnlLine);
    end;

    internal procedure GetAppliesToDocEntryNumbers(GenJournalLine: Record "Gen. Journal Line"; var TempInteger: Record "Integer" temporary)
    var
        AccNo: Code[20];
        AccType: Enum "Gen. Journal Account Type";
    begin
        if GenJournalLine."Bal. Account Type" in [GenJournalLine."Account Type"::Customer, GenJournalLine."Account Type"::Vendor, GenJournalLine."Account Type"::Employee] then begin
            AccType := GenJournalLine."Bal. Account Type";
            AccNo := GenJournalLine."Bal. Account No.";
        end else begin
            AccType := GenJournalLine."Account Type";
            AccNo := GenJournalLine."Account No.";
        end;
        case AccType of
            GenJournalLine."Account Type"::Customer:
                GetAppliesToDocCustLedgEntries(GenJournalLine, TempInteger, AccNo);
            GenJournalLine."Account Type"::Vendor:
                GetAppliesToDocVendLedgEntries(GenJournalLine, TempInteger, AccNo);
            GenJournalLine."Account Type"::Employee:
                GetAppliesToDocEmplLedgEntries(GenJournalLine, TempInteger, AccNo);
            else
                OnGetAppliesToDocEntryNumbersCaseElse(GenJournalLine, TempInteger, AccNo);
        end;
    end;

    local procedure GetAppliesToDocCustLedgEntries(GenJournalLine: Record "Gen. Journal Line"; var TempInteger: Record "Integer" temporary; AccNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetCurrentKey("Customer No.", "Document No.");
        CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange(Open, true);
        case true of
            GenJournalLine."Applies-to Doc. No." <> '':
                begin
                    CustLedgEntry.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
                    CustLedgEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
                end;
            GenJournalLine."Applies-to ID" <> '':
                begin
                    CustLedgEntry.SetCurrentKey("Customer No.", CustLedgEntry."Applies-to ID");
                    CustLedgEntry.SetRange("Applies-to ID", GenJournalLine."Applies-to ID");
                end;
            else
                exit;
        end;
        GetEntriesFromSet(TempInteger, CustLedgEntry);
    end;

    local procedure GetAppliesToDocVendLedgEntries(GenJournalLine: Record "Gen. Journal Line"; var TempInteger: Record "Integer" temporary; AccNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetCurrentKey("Vendor No.", "Document No.");
        VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange(Open, true);
        case true of
            GenJournalLine."Applies-to Doc. No." <> '':
                begin
                    VendLedgEntry.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
                    VendLedgEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
                end;
            GenJournalLine."Applies-to ID" <> '':
                begin
                    VendLedgEntry.SetCurrentKey("Vendor No.", VendLedgEntry."Applies-to ID");
                    VendLedgEntry.SetRange("Applies-to ID", GenJournalLine."Applies-to ID");
                end;
            else
                exit;
        end;
        GetEntriesFromSet(TempInteger, VendLedgEntry);
    end;

    local procedure GetAppliesToDocEmplLedgEntries(GenJournalLine: Record "Gen. Journal Line"; var TempInteger: Record "Integer" temporary; AccNo: Code[20])
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
    begin
        EmplLedgEntry.SetCurrentKey("Employee No.", "Document No.");
        EmplLedgEntry.SetRange("Employee No.", AccNo);
        EmplLedgEntry.SetRange(Open, true);
        case true of
            GenJournalLine."Applies-to Doc. No." <> '':
                begin
                    EmplLedgEntry.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
                    EmplLedgEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
                end;
            GenJournalLine."Applies-to ID" <> '':
                begin
                    EmplLedgEntry.SetCurrentKey("Employee No.", EmplLedgEntry."Applies-to ID");
                    EmplLedgEntry.SetRange("Applies-to ID", GenJournalLine."Applies-to ID");
                end;
            else
                exit;
        end;
        GetEntriesFromSet(TempInteger, EmplLedgEntry);
    end;

    local procedure GetEntriesFromSet(var TempInteger: Record "Integer" temporary; RecVariant: Variant)
    var
        FieldRef: FieldRef;
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(RecVariant);
        FieldRef := RecordRef.FieldIndex(1);
        if RecordRef.FindSet() then
            repeat
                TempInteger.Number := FieldRef.Value();
                TempInteger.Insert();
            until RecordRef.Next() = 0;
    end;

    local procedure ValidatePaymentExportData(var PaymentExportData: Record "Payment Export Data"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        ValidatePaymentExportDataField(PaymentExportData, GenJnlLine, PaymentExportData.FieldName("Sender Bank Account No."));
        ValidatePaymentExportDataField(PaymentExportData, GenJnlLine, PaymentExportData.FieldName("Recipient Name"));
        ValidatePaymentExportDataField(PaymentExportData, GenJnlLine, PaymentExportData.FieldName("Recipient Bank Acc. No."));
        ValidatePaymentExportDataField(PaymentExportData, GenJnlLine, PaymentExportData.FieldName("Transfer Date"));
        ValidatePaymentExportDataField(PaymentExportData, GenJnlLine, PaymentExportData.FieldName("Payment Information ID"));
        ValidatePaymentExportDataField(PaymentExportData, GenJnlLine, PaymentExportData.FieldName("End-to-End ID"));
    end;

    local procedure ValidatePaymentExportDataField(var PaymentExportData: Record "Payment Export Data"; var GenJnlLine: Record "Gen. Journal Line"; FieldName: Text)
    var
        "Field": Record "Field";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(PaymentExportData);
        Field.SetRange(TableNo, RecRef.Number);
        Field.SetRange(FieldName, FieldName);
        Field.FindFirst();
        FieldRef := RecRef.Field(Field."No.");
        if (Field.Type = Field.Type::Text) and (Format(FieldRef.Value) <> '') then
            exit;
        if (Field.Type = Field.Type::Code) and (Format(FieldRef.Value) <> '') then
            exit;
        if (Field.Type = Field.Type::Decimal) and (Format(FieldRef.Value) <> '0') then
            exit;
        if (Field.Type = Field.Type::Integer) and (Format(FieldRef.Value) <> '0') then
            exit;
        if (Field.Type = Field.Type::Date) and (Format(FieldRef.Value) <> '0D') then
            exit;

        PaymentExportData.AddGenJnlLineErrorText(GenJnlLine, StrSubstNo(FieldIsBlankErr, Field."Field Caption"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateNewCreditTransferEntry(var PaymentExportData: Record "Payment Export Data"; var CreditTransferEntry: Record "Credit Transfer Entry"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillExportBuffer(var PaymentExportData: Record "Payment Export Data"; BankExportImportSetup: Record "Bank Export/Import Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillExportBufferOnAfterGetMessageID(var TempGenJnlLine: Record "Gen. Journal Line" temporary; var MessageID: code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillExportBufferOnAfterCreateNewRegister(var CreditTransferRegister: Record "Credit Transfer Register"; var BankExportImportSetup: Record "Bank Export/Import Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillExportBufferOnAfterSetCustomerAsRecipient(var PaymentExportData: Record "Payment Export Data"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; Customer: Record Customer; CustomerBankAccount: Record "Customer Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillExportBufferOnAfterSetVendorAsRecipient(var PaymentExportData: Record "Payment Export Data"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; Vendor: Record Vendor; VendorBankAccount: Record "Vendor Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillExportBufferOnAfterSetBankAsRecipient(var PaymentExportData: Record "Payment Export Data"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillExportBufferOnAfterInsertPaymentExportData(var PaymentExportData: Record "Payment Export Data"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; BankExportImportSetup: Record "Bank Export/Import Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillExportBufferOnBeforeInsertPaymentExportData(var PaymentExportData: Record "Payment Export Data"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillExportBufferOnSetAsRecipient(var GenJnlLine: Record "Gen. Journal Line"; var PaymentExportData: Record "Payment Export Data"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; var CreditTransferRegister: Record "Credit Transfer Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAppliesToDocEntryNumbersCaseElse(var GenJournalLine: Record "Gen. Journal Line"; var TempInteger: Record Integer temporary; AccNo: Code[20])
    begin
    end;
}

