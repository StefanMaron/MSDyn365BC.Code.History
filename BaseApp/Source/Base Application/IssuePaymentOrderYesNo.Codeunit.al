#if not CLEAN19
codeunit 11707 "Issue Payment Order (Yes/No)"
{
    TableNo = "Payment Order Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    trigger OnRun()
    begin
        PmtOrdHdr.Copy(Rec);
        Code();
        Rec := PmtOrdHdr;
    end;

    var
        PmtOrdHdr: Record "Payment Order Header";
        IssueQst: Label '&Issue,Issue and &export';

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

        if Selection = 2 then begin
            IssuedPmtOrdHdr.Get(PmtOrdHdr."Last Issuing No.");
            IssuedPmtOrdHdr.ExportPmtOrd();
        end;
    end;
}
#endif
