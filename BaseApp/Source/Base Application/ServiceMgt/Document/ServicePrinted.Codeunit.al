namespace Microsoft.Service.Document;

codeunit 5905 "Service-Printed"
{
    TableNo = "Service Header";

    trigger OnRun()
    begin
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        OnBeforeModify(Rec);
        Rec.Modify();
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var ServiceHeader: Record "Service Header")
    begin
    end;
}

