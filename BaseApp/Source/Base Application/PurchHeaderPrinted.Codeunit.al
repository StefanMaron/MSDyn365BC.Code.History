codeunit 317 "Purch.Header-Printed"
{
    TableNo = "Purchase Header";

    trigger OnRun()
    begin
        Find;
        "No. Printed" := "No. Printed" + 1;
        OnBeforeModify(Rec);
        Modify;
        if not SuppressCommit then
            Commit;
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
}

