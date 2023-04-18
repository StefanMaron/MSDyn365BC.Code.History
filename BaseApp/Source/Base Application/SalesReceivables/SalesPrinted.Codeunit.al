codeunit 313 "Sales-Printed"
{
    Permissions = TableData "Sales Header" = rm;
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec, SuppressCommit);
        Find();
        "No. Printed" := "No. Printed" + 1;
        OnBeforeModify(Rec);
        Modify();
        if not SuppressCommit then
            Commit();
        OnAfterOnRun(Rec);
    end;

    var
        SuppressCommit: Boolean;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesHeader: Record "Sales Header"; var SuppressCommit: Boolean)
    begin
    end;
}

