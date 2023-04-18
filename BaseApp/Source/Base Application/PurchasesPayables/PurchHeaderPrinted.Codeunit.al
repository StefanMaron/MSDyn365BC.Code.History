codeunit 317 "Purch.Header-Printed"
{
    TableNo = "Purchase Header";

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
    local procedure OnBeforeModify(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var PurchaseHeader: Record "Purchase Header"; var SuppressCommit: Boolean)
    begin
    end;
}

