namespace Microsoft.Service.History;

codeunit 5903 "Service Shpt.-Printed"
{
    Permissions = TableData "Service Shipment Header" = rimd;
    TableNo = "Service Shipment Header";

    trigger OnRun()
    begin
        OnBeforeRun(Rec, SuppressCommit);

        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        OnBeforeModify(Rec);
        Rec.Modify();
        if not SuppressCommit then
            Commit();
    end;

    var
        SuppressCommit: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var ServiceShipmentHeader: Record "Service Shipment Header"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var ServiceShipmentHeader: Record "Service Shipment Header")
    begin
    end;
}

