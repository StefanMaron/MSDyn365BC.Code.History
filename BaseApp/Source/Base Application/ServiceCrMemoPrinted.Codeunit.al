codeunit 5904 "Service Cr. Memo-Printed"
{
    Permissions = TableData "Service Cr.Memo Header" = rimd;
    TableNo = "Service Cr.Memo Header";

    trigger OnRun()
    begin
        OnBeforeRun(Rec, SuppressCommit);
        Find();
        "No. Printed" := "No. Printed" + 1;
        OnBeforeModify(Rec);
        Modify();
        if not SuppressCommit then
            Commit();
    end;

    var
        SuppressCommit: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var SuppressCommit: Boolean)
    begin
    end;
}

