codeunit 11720 "Exp. Launcher SEPA"
{
    TableNo = "Issued Payment Order Header";

    trigger OnRun()
    var
        IssuedPmtOrdHdr: Record "Issued Payment Order Header";
        BankAcc: Record "Bank Account";
        GenJnlLn: Record "Gen. Journal Line";
    begin
        IssuedPmtOrdHdr.Copy(Rec);

        BankAcc.Get("Bank Account No.");
        BankAcc.TestField("Payment Jnl. Template Name");
        BankAcc.TestField("Payment Jnl. Batch Name");

        GenJnlLn.SetRange("Journal Template Name", BankAcc."Payment Jnl. Template Name");
        GenJnlLn.SetRange("Journal Batch Name", BankAcc."Payment Jnl. Batch Name");
        GenJnlLn.SetRange("Document No.", IssuedPmtOrdHdr."No.");
        if not GenJnlLn.IsEmpty then
            GenJnlLn.DeleteAll(true);

        IssuedPmtOrdHdr.CreatePmtJnl(
          BankAcc."Payment Jnl. Template Name", BankAcc."Payment Jnl. Batch Name");

        GenJnlLn.FindFirst;

        Commit;
        if not CODEUNIT.Run(CODEUNIT::"SEPA CT-Export File", GenJnlLn) then begin
            PAGE.Run(PAGE::"Payment Journal", GenJnlLn);
            Error(GetLastErrorText);
        end;

        GenJnlLn.DeleteAll(true);
    end;
}

