codeunit 11704 "Issue Bank Statement + Print"
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
        IssuedSuccessfullyMsg: Label 'Bank statement was successfully issued.';

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
        Message(IssuedSuccessfullyMsg);

        IssuedBankStmtHdr.Get(BankStmtHdr."Last Issuing No.");
        IssuedBankStmtHdr.SetRecFilter;

        if Selection = 2 then
            IssuedBankStmtHdr.CreatePmtReconJnl(false);

        IssuedBankStmtHdr.PrintRecords(false);
    end;
}

