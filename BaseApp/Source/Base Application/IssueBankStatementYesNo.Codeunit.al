codeunit 11703 "Issue Bank Statement (Yes/No)"
{
    TableNo = "Bank Statement Header";

    trigger OnRun()
    begin
        BankStmtHdr.Copy(Rec);
        Code;
        Rec := BankStmtHdr;
    end;

    var
        BankStmtHdr: Record "Bank Statement Header";
        IssueQst: Label '&Issue,Issue and &create payment reconciliation journal';

    [Scope('OnPrem')]
    procedure "Code"()
    var
        IssuedBankStmtHdr: Record "Issued Bank Statement Header";
        Selection: Integer;
    begin
        Selection := StrMenu(IssueQst, 1);
        if Selection = 0 then
            exit;

        CODEUNIT.Run(CODEUNIT::"Issue Bank Statement", BankStmtHdr);
        Commit();

        if Selection = 2 then begin
            IssuedBankStmtHdr.Get(BankStmtHdr."Last Issuing No.");
            IssuedBankStmtHdr.SetRecFilter;
            IssuedBankStmtHdr.CreatePmtReconJnl(false);
        end;
    end;
}

