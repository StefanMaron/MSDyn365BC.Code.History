codeunit 11734 "Cash Document-Post + Print"
{
    TableNo = "Cash Document Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
        CashDocumentHeader.Copy(Rec);
        Code;
        Rec := CashDocumentHeader;
    end;

    var
        CashDocumentHeader: Record "Cash Document Header";
        WithoutConfirmation: Boolean;

    [Scope('OnPrem')]
    procedure PostWithoutConfirmation(var ParmCashDocumentHeader: Record "Cash Document Header")
    begin
        WithoutConfirmation := true;
        CashDocumentHeader.Copy(ParmCashDocumentHeader);
        Code;
        ParmCashDocumentHeader := CashDocumentHeader;
    end;

    local procedure "Code"()
    begin
        if WithoutConfirmation then
            CODEUNIT.Run(CODEUNIT::"Cash Document-Post", CashDocumentHeader)
        else
            CODEUNIT.Run(CODEUNIT::"Cash Document-Post (Yes/No)", CashDocumentHeader);

        GetReport(CashDocumentHeader);
        Commit();
    end;

    [Scope('OnPrem')]
    procedure GetReport(var CashDocumentHeader: Record "Cash Document Header")
    var
        PostedCashDocHeader: Record "Posted Cash Document Header";
    begin
        PostedCashDocHeader.Get(CashDocumentHeader."Cash Desk No.", CashDocumentHeader."No.");
        PostedCashDocHeader.SetRecFilter;
        PostedCashDocHeader.PrintRecords(false);
    end;
}

