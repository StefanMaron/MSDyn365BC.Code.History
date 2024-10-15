codeunit 318 "Purch.Rcpt.-Printed"
{
    Permissions = TableData "Purch. Rcpt. Header" = rimd;
    TableNo = "Purch. Rcpt. Header";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec, SuppressCommit);
        Find();
        "No. Printed" := "No. Printed" + 1;
        OnBeforeModify(Rec);
        Modify();
        if not SuppressCommit then
            Commit();
    end;

    var
        SuppressCommit: Boolean;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var PurchRcptHeader: Record "Purch. Rcpt. Header"; var SuppressCommit: Boolean)
    begin
    end;
}

