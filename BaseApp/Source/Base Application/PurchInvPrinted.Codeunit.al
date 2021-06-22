codeunit 319 "Purch. Inv.-Printed"
{
    Permissions = TableData "Purch. Inv. Header" = rimd;
    TableNo = "Purch. Inv. Header";

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
    local procedure OnBeforeModify(var PurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;
}

