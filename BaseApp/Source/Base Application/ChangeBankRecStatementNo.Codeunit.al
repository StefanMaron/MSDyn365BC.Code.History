codeunit 1253 "Change Bank Rec. Statement No."
{
    Permissions = TableData "Bank Acc. Reconciliation" = rimd,
                  TableData "Bank Acc. Reconciliation Line" = rimd,
                  TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rm;
    TableNo = "Bank Acc. Reconciliation";

    trigger OnRun()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        NewStatementNo: Code[20];
    begin
        BankAccReconciliation := Rec;

        if GetNewStatementNo(BankAccReconciliation, NewStatementNo) then begin
            ChangeStatementNo(BankAccReconciliation, NewStatementNo);
            Rec := BankAccReconciliation;
        end;
    end;

    local procedure GetNewStatementNo(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var NewStatementNo: Code[20]): Boolean
    var
        ChangeBankRecStatementNo: Page "Change Bank Rec. Statement No.";
    begin
        ChangeBankRecStatementNo.SetBankAccReconciliation(BankAccReconciliation);
        if ChangeBankRecStatementNo.RunModal() = Action::OK then begin
            NewStatementNo := ChangeBankRecStatementNo.GetNewStatementNo();
            exit(NewStatementNo <> BankAccReconciliation."Statement No.");
        end;
        exit(false);
    end;

    local procedure ChangeStatementNo(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; NewStatementNo: Code[20])
    var
        TempBankAccReconciliation: Record "Bank Acc. Reconciliation" temporary;
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
    begin
        UpdateAppliedBankLedgerEntries(BankAccReconciliation, NewStatementNo);
        UpdateAppliedCheckLedgerEntries(BankAccReconciliation, NewStatementNo);

        MoveBankAccReconiliationToBuffers(BankAccReconciliation, TempBankAccReconciliation, TempBankAccReconciliationLine);

        CreateBankAccReconciliationWithNewStatementNo(
            BankAccReconciliation, TempBankAccReconciliation, TempBankAccReconciliationLine, NewStatementNo);
    end;

    local procedure MoveBankAccReconiliationToBuffers(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var TempBankAccReconciliation: Record "Bank Acc. Reconciliation" temporary; var TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        TempBankAccReconciliation.TransferFields(BankAccReconciliation);
        TempBankAccReconciliation.Insert();
        BankAccReconciliation.Delete();

        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        if BankAccReconciliationLine.FindSet() then
            repeat
                TempBankAccReconciliationLine.TransferFields(BankAccReconciliationLine);
                TempBankAccReconciliationLine.Insert();
            until BankAccReconciliationLine.Next() = 0;
        BankAccReconciliationLine.DeleteAll();
    end;

    local procedure CreateBankAccReconciliationWithNewStatementNo(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var TempBankAccReconciliation: Record "Bank Acc. Reconciliation" temporary; var TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary; NewStatementNo: Code[20])
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliation.TransferFields(TempBankAccReconciliation);
        BankAccReconciliation."Statement No." := NewStatementNo;
        BankAccReconciliation.Insert();

        if TempBankAccReconciliationLine.FindSet() then
            repeat
                BankAccReconciliationLine.TransferFields(TempBankAccReconciliationLine);
                BankAccReconciliationLine."Statement No." := NewStatementNo;
                BankAccReconciliationLine.Insert();
            until TempBankAccReconciliationLine.Next() = 0;
    end;

    local procedure UpdateAppliedBankLedgerEntries(BankAccReconciliation: Record "Bank Acc. Reconciliation"; NewStatementNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange("Statement Status", BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied");
        if not BankAccountLedgerEntry.IsEmpty() then
            BankAccountLedgerEntry.ModifyAll("Statement No.", NewStatementNo);
    end;

    local procedure UpdateAppliedCheckLedgerEntries(BankAccReconciliation: Record "Bank Acc. Reconciliation"; NewStatementNo: Code[20])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        CheckLedgerEntry.SetRange("Statement Status", CheckLedgerEntry."Statement Status"::"Check Entry Applied");
        if not CheckLedgerEntry.IsEmpty() then
            CheckLedgerEntry.ModifyAll("Statement No.", NewStatementNo);
    end;
}