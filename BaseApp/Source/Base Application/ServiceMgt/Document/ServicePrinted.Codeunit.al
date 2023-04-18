codeunit 5905 "Service-Printed"
{
    TableNo = "Service Header";

    trigger OnRun()
    begin
        Find();
        "No. Printed" := "No. Printed" + 1;
        OnBeforeModify(Rec);
        Modify();
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var ServiceHeader: Record "Service Header")
    begin
    end;
}

