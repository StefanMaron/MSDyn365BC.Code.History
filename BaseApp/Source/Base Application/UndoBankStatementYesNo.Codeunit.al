codeunit 1340 "Undo Bank Statement (Yes/No)"
{
    Permissions = TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rm,
                  TableData "Bank Acc. Reconciliation" = ri,
                  TableData "Bank Acc. Reconciliation Line" = ri,
                  TableData "Bank Account Statement" = rd,
                  TableData "Bank Account Statement Line" = rd;
    TableNo = "Bank Account Statement";

    trigger OnRun()
    var
        BankAccountStatement: Record "Bank Account Statement";
    begin
        BankAccountStatement.Copy(Rec);
        Code(BankAccountStatement);
        Rec := BankAccountStatement;
    end;

    var
        UndoBankStatementQst: Label 'Do you want to reverse this bank statement and automatically create a new bank reconciliation with the same information?';

    local procedure Code(var BankAccountStatement: Record "Bank Account Statement")
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        StatementNo: Code[20];
    begin
        if not Confirm(UndoBankStatementQst) then
            exit;

        StatementNo := UndoBankAccountStatement(BankAccountStatement);

        BankAccReconciliation.Get(
            BankAccReconciliation."Statement Type"::"Bank Reconciliation",
            BankAccountStatement."Bank Account No.",
            StatementNo);
        Page.Run(Page::"Bank Acc. Reconciliation", BankAccReconciliation);
    end;

    procedure UndoBankAccountStatement(BankAccountStatement: Record "Bank Account Statement"): code[20]
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountStatementLine: Record "Bank Account Statement Line";
    begin
        BankAccount.Get(BankAccountStatement."Bank Account No.");
        BankAccount."Balance Last Statement" := BankAccountStatement."Balance Last Statement";
        BankAccount.Modify();

        BankAccReconciliation.Init();
        BankAccReconciliation.TransferFields(BankAccountStatement);
        BankAccReconciliation."Statement No." := '';
        BankAccReconciliation.Validate("Bank Account No.");
        BankAccReconciliation.Insert(true);

        BankAccountStatementLine.SetRange("Bank Account No.", BankAccountStatement."Bank Account No.");
        BankAccountStatementLine.SetRange("Statement No.", BankAccountStatement."Statement No.");
        if BankAccountStatementLine.FindSet() then
            repeat
                BankAccReconciliationLine.Init();
                BankAccReconciliationLine.TransferFields(BankAccountStatementLine);
                BankAccReconciliationLine."Statement No." := BankAccReconciliation."Statement No.";
                BankAccReconciliationLine.Insert();

                UndoBankEntries(BankAccountStatementLine, BankAccReconciliation."Statement No.");
            until BankAccountStatementLine.Next() = 0;

        BankAccountStatementLine.DeleteAll();
        BankAccountStatement.Delete();

        exit(BankAccReconciliation."Statement No.");
    end;

    local procedure UndoBankEntries(BankAccountStatementLine: Record "Bank Account Statement Line"; NewStatementNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountStatementLine."Bank Account No.");
        BankAccountLedgerEntry.SetRange("Statement No.", BankAccountStatementLine."Statement No.");
        BankAccountLedgerEntry.SetRange("Statement Line No.", BankAccountStatementLine."Statement Line No.");
        if BankAccountLedgerEntry.FindSet(true, true) then
            repeat
                CheckLedgerEntry.SetCurrentKey("Bank Account Ledger Entry No.");
                CheckLedgerEntry.SetRange("Bank Account Ledger Entry No.", BankAccountLedgerEntry."Entry No.");
                if CheckLedgerEntry.FindSet(true) then begin
                    repeat
                        CheckLedgerEntry."Statement No." := NewStatementNo;
                        CheckLedgerEntry."Statement Status" := CheckLedgerEntry."Statement Status"::"Check Entry Applied";
                        CheckLedgerEntry.Open := true;
                        CheckLedgerEntry.Modify();
                    until CheckLedgerEntry.Next() = 0;

                    BankAccountLedgerEntry."Statement Status" := BankAccountLedgerEntry."Statement Status"::"Check Entry Applied";
                    BankAccountLedgerEntry."Statement No." := '';
                    BankAccountLedgerEntry."Statement Line No." := 0;
                end else begin
                    BankAccountLedgerEntry."Statement No." := NewStatementNo;
                    BankAccountLedgerEntry."Statement Status" := BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied";
                end;

                BankAccountLedgerEntry."Remaining Amount" := BankAccountLedgerEntry.Amount;
                BankAccountLedgerEntry.Open := true;
                BankAccountLedgerEntry.Modify();
            until BankAccountLedgerEntry.Next() = 0;

        BankAccountStatementLine.FilterManyToOneMatches(BankAccRecMatchBuffer);
        if BankAccRecMatchBuffer.FindFirst() then begin
            BankAccountLedgerEntry.Reset();
            BankAccountLedgerEntry.SetRange("Entry No.", BankAccRecMatchBuffer."Ledger Entry No.");
            if BankAccountLedgerEntry.FindFirst() then begin

                CheckLedgerEntry.SetCurrentKey("Bank Account Ledger Entry No.");
                CheckLedgerEntry.SetRange("Bank Account Ledger Entry No.", BankAccountLedgerEntry."Entry No.");
                if CheckLedgerEntry.FindSet(true) then begin
                    repeat
                        CheckLedgerEntry."Statement No." := NewStatementNo;
                        CheckLedgerEntry."Statement Status" := CheckLedgerEntry."Statement Status"::"Check Entry Applied";
                        CheckLedgerEntry.Open := true;
                        CheckLedgerEntry.Modify();
                    until CheckLedgerEntry.Next() = 0;

                    BankAccountLedgerEntry."Statement Status" := BankAccountLedgerEntry."Statement Status"::"Check Entry Applied";
                    BankAccountLedgerEntry."Statement No." := '';
                    BankAccountLedgerEntry."Statement Line No." := 0;
                end else begin
                    BankAccountLedgerEntry."Statement No." := NewStatementNo;
                    BankAccountLedgerEntry."Statement Status" := BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied";
                end;

                BankAccountLedgerEntry."Remaining Amount" := BankAccountLedgerEntry.Amount;
                BankAccountLedgerEntry.Open := true;
                BankAccountLedgerEntry.Modify();

            end;
            BankAccRecMatchBuffer.Rename(NewStatementNo,
                                         BankAccRecMatchBuffer."Statement Line No.",
                                         BankAccRecMatchBuffer."Bank Account No.",
                                         BankAccRecMatchBuffer."Match ID");
            BankAccRecMatchBuffer."Is Processed" := false;
            BankAccRecMatchBuffer.Modify();
        end;
    end;
}
