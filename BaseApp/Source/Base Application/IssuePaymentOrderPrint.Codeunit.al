codeunit 11708 "Issue Payment Order + Print"
{
    TableNo = "Payment Order Header";

    trigger OnRun()
    begin
        PmtOrdHdr.Copy(Rec);
        Code;
        Rec := PmtOrdHdr;
    end;

    var
        PmtOrdHdr: Record "Payment Order Header";
        IssueQst: Label '&Issue,Issue and &export';
        IssuedSuccesfullyMsg: Label 'Payment Order was successfully issued.';

    local procedure "Code"()
    var
        IssuedPmtOrdHdr: Record "Issued Payment Order Header";
        Selection: Integer;
    begin
        Selection := StrMenu(IssueQst, 1);
        if Selection = 0 then
            exit;

        CODEUNIT.Run(CODEUNIT::"Issue Payment Order", PmtOrdHdr);
        Commit();
        Message(IssuedSuccesfullyMsg);

        IssuedPmtOrdHdr.Get(PmtOrdHdr."Last Issuing No.");

        if Selection = 2 then
            IssuedPmtOrdHdr.ExportPmtOrd;

        PrintPaymentOrder(IssuedPmtOrdHdr);
    end;

    local procedure PrintPaymentOrder(var IssuedPmtOrdHdr: Record "Issued Payment Order Header")
    begin
        IssuedPmtOrdHdr.SetRecFilter;
        IssuedPmtOrdHdr.PrintRecords(false);
    end;
}

