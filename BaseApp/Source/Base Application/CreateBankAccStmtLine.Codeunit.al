codeunit 11719 "Create Bank Acc. Stmt Line"
{
    TableNo = "Bank Acc. Reconciliation";

    trigger OnRun()
    var
        BankAccReconLn: Record "Bank Acc. Reconciliation Line";
        BankStmtLn: Record "Bank Statement Line";
        LineNo: Integer;
    begin
        BankStmtLn.SetRange("Bank Statement No.", "Statement No.");
        if BankStmtLn.FindLast then
            LineNo := BankStmtLn."Line No.";

        BankAccReconLn.SetRange("Statement Type", "Statement Type");
        BankAccReconLn.SetRange("Bank Account No.", "Bank Account No.");
        BankAccReconLn.SetRange("Statement No.", "Statement No.");
        if BankAccReconLn.FindSet then
            repeat
                LineNo += 10000;
                BankStmtLn.Init();
                BankStmtLn."Bank Statement No." := "Statement No.";
                BankStmtLn."Line No." := LineNo;
                BankStmtLn.CopyFromBankAccReconLine(BankAccReconLn);
                BankStmtLn.Insert();
            until BankAccReconLn.Next = 0;
    end;
}

