codeunit 372 "Bank Acc. Recon. Post+Print"
{
    TableNo = "Bank Acc. Reconciliation";

    trigger OnRun()
    begin
        BankAccRecon.Copy(Rec);

        if not Confirm(Text000, false) then
            exit;

        CODEUNIT.Run(CODEUNIT::"Bank Acc. Reconciliation Post", BankAccRecon);
        Rec := BankAccRecon;
        Commit();

        if BankAccStmt.Get("Bank Account No.", "Statement No.") then
            DocPrint.PrintBankAccStmt(BankAccStmt);
    end;

    var
        Text000: Label 'Do you want to post and print the Reconciliation?';
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccStmt: Record "Bank Account Statement";
        DocPrint: Codeunit "Document-Print";
}

