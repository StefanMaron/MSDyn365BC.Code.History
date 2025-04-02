// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Deposit;

table 1284 "Outstanding Bank Transaction"
{
    Caption = 'Outstanding Bank Transaction';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(3; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund,,,,,,Deposit';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund,,,,,,Deposit;
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(5; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            Caption = 'Amount';
        }
        field(8; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Bank Account Ledger Entry,Check Ledger Entry';
            OptionMembers = "Bank Account Ledger Entry","Check Ledger Entry";
        }
        field(9; Applied; Boolean)
        {
            Caption = 'Applied';
        }
        field(10; "Statement Type"; Option)
        {
            Caption = 'Statement Type';
            OptionCaption = 'Bank Reconciliation,Payment Application';
            OptionMembers = "Bank Reconciliation","Payment Application";
        }
        field(11; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
        }
        field(10010; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(10011; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
    }

    keys
    {
        key(Key1; "External Document No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; Type)
        {
        }
    }

    fieldgroups
    {
    }

    procedure DrillDown(BankAccNo: Code[20]; TransactionType: Option; StatementType: Integer; StatementNo: Code[20])
    var
        TempOutstandingBankTransaction: Record "Outstanding Bank Transaction" temporary;
    begin
        CreateTempOutstandingBankTrxs(TempOutstandingBankTransaction, BankAccNo, StatementType, StatementNo);
        SetOutstandingBankTrxFilter(TempOutstandingBankTransaction, TransactionType);
        RunOustandingBankTrxsPage(TempOutstandingBankTransaction, TransactionType);
    end;

    procedure CreateTempOutstandingBankTrxs(var TempOutstandingBankTransaction: Record "Outstanding Bank Transaction" temporary; BankAccNo: Code[20]; StatementType: Integer; StatementNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        TempOutstandingBankTransactionCopy: Record "Outstanding Bank Transaction" temporary;
        RemainingAmt: Decimal;
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccNo);
        BankAccountLedgerEntry.SetRange(Open, true);
        TempOutstandingBankTransactionCopy.DeleteAll();
        if BankAccountLedgerEntry.FindSet() then
            repeat
                RemainingAmt := BankAccountLedgerEntry.Amount - GetAppliedAmount(BankAccountLedgerEntry."Entry No.");
                if RemainingAmt <> 0 then begin
                    TempOutstandingBankTransaction.Init();
                    CreateTheDepositHeaderLine(TempOutstandingBankTransaction, TempOutstandingBankTransactionCopy, BankAccountLedgerEntry);
                    TempOutstandingBankTransaction."Posting Date" := BankAccountLedgerEntry."Posting Date";
                    TempOutstandingBankTransaction."Document Type" := BankAccountLedgerEntry."Document Type".AsInteger();
                    TempOutstandingBankTransaction."Document No." := BankAccountLedgerEntry."Document No.";
                    TempOutstandingBankTransaction."Bank Account No." := BankAccountLedgerEntry."Bank Account No.";
                    TempOutstandingBankTransaction.Description := BankAccountLedgerEntry.Description;
                    TempOutstandingBankTransaction.Amount := RemainingAmt;
                    TempOutstandingBankTransaction."Entry No." := BankAccountLedgerEntry."Entry No.";
                    TempOutstandingBankTransaction."Statement Type" := StatementType;
                    TempOutstandingBankTransaction."Statement No." := StatementNo;
                    BankAccountLedgerEntry.CalcFields("Check Ledger Entries");
                    if BankAccountLedgerEntry."Check Ledger Entries" > 0 then
                        TempOutstandingBankTransaction.Type := TempOutstandingBankTransaction.Type::"Check Ledger Entry"
                    else
                        TempOutstandingBankTransaction.Type := TempOutstandingBankTransaction.Type::"Bank Account Ledger Entry";
                    TempOutstandingBankTransaction.Insert();
                end;
            until BankAccountLedgerEntry.Next() = 0;
    end;

    procedure CreateTheDepositHeaderLine(var TempOutstandingBankTransaction: Record "Outstanding Bank Transaction" temporary; var TempOutstandingBankTransactionCopy: Record "Outstanding Bank Transaction" temporary; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    var
        PostedDepositHeader: Record "Posted Deposit Header";
        PostedDepositLine: Record "Posted Deposit Line";
    begin
        PostedDepositLine.SetRange("Document Type", BankAccountLedgerEntry."Document Type");
        PostedDepositLine.SetRange("Document No.", BankAccountLedgerEntry."Document No.");
        if PostedDepositLine.FindFirst() then begin
            PostedDepositHeader.Get(PostedDepositLine."Deposit No.");
            TempOutstandingBankTransaction.Init();
            TempOutstandingBankTransactionCopy.SetRange("External Document No.", BankAccountLedgerEntry."External Document No.");
            if not TempOutstandingBankTransactionCopy.FindFirst() then begin
                TempOutstandingBankTransaction."Posting Date" := PostedDepositHeader."Posting Date";
                TempOutstandingBankTransaction."Document No." := PostedDepositHeader."No.";
                TempOutstandingBankTransaction."Document Type" := TempOutstandingBankTransaction."Document Type"::Deposit;
                TempOutstandingBankTransaction."Bank Account No." := PostedDepositHeader."Bank Account No.";
                TempOutstandingBankTransaction.Description := PostedDepositHeader."Posting Description";
                TempOutstandingBankTransaction.Amount := PostedDepositHeader."Total Deposit Amount";
                TempOutstandingBankTransaction.Indentation := 0;
                TempOutstandingBankTransaction."Entry No." := 0;
                TempOutstandingBankTransaction."External Document No." := BankAccountLedgerEntry."External Document No.";
                TempOutstandingBankTransaction.Insert();
                TempOutstandingBankTransactionCopy.Copy(TempOutstandingBankTransaction);
                TempOutstandingBankTransactionCopy.Insert();
            end;
            TempOutstandingBankTransaction.Indentation := 1;
        end else
            TempOutstandingBankTransaction.Indentation := 0;
    end;

    procedure GetCurrencyCode(): Code[10]
    var
        BankAcc: Record "Bank Account";
    begin
        if ("Bank Account No." = BankAcc."No.") or BankAcc.Get("Bank Account No.") then
            exit(BankAcc."Currency Code");

        exit('');
    end;

    local procedure SetOutstandingBankTrxFilter(var TempOutstandingBankTransaction: Record "Outstanding Bank Transaction" temporary; TransactionType: Option)
    begin
        TempOutstandingBankTransaction.Reset();
        TempOutstandingBankTransaction.FilterGroup := 2;
        TempOutstandingBankTransaction.SetRange(Type, TransactionType);
        TempOutstandingBankTransaction.SetRange(Applied, false);
        TempOutstandingBankTransaction.FilterGroup := 0;
    end;

    local procedure RunOustandingBankTrxsPage(var TempOutstandingBankTransaction: Record "Outstanding Bank Transaction" temporary; TransactionType: Option)
    var
        OutstandingBankTransactions: Page "Outstanding Bank Transactions";
    begin
        OutstandingBankTransactions.SetRecords(TempOutstandingBankTransaction);
        OutstandingBankTransactions.SetPageCaption(TransactionType);
        OutstandingBankTransactions.SetTableView(TempOutstandingBankTransaction);
        OutstandingBankTransactions.Run();
    end;

    procedure CopyFromBankAccLedgerEntry(BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; BankTransacType: Integer; StatementType: Integer; StatementNo: Code[20]; RemainingAmt: Decimal; IndentationValue: Integer)
    begin
        Init();
        "Entry No." := BankAccountLedgerEntry."Entry No.";
        "Posting Date" := BankAccountLedgerEntry."Posting Date";
        "Document Type" := BankAccountLedgerEntry."Document Type".AsInteger();
        "Document No." := BankAccountLedgerEntry."Document No.";
        "Bank Account No." := BankAccountLedgerEntry."Bank Account No.";
        Description := BankAccountLedgerEntry.Description;
        Amount := RemainingAmt;
        Type := BankTransacType;
        "Statement Type" := StatementType;
        "Statement No." := StatementNo;
        Indentation := IndentationValue;
        Insert();
    end;

    procedure GetAppliedAmount(EntryNo: Integer) AppliedAmt: Decimal
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.SetRange("Applies-to Entry No.", EntryNo);
        if AppliedPaymentEntry.FindSet() then
            repeat
                AppliedAmt += AppliedPaymentEntry."Applied Amount";
            until AppliedPaymentEntry.Next() = 0;

        exit(AppliedAmt);
    end;

    procedure GetRemainingAmount(EntryNo: Integer) RemainingAmt: Decimal
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.SetRange("Applies-to Entry No.", EntryNo);
        if not AppliedPaymentEntry.FindFirst() then
            exit;

        RemainingAmt := AppliedPaymentEntry.GetRemAmt();
        exit(RemainingAmt);
    end;
}
