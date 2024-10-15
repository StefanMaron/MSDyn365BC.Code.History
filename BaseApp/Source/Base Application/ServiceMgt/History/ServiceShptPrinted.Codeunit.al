namespace Microsoft.Service.History;

codeunit 5903 "Service Shpt.-Printed"
{
    Permissions = TableData "Service Shipment Header" = rimd;
    TableNo = "Service Shipment Header";

    trigger OnRun()
    begin
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        OnBeforeModify(Rec);
        Rec.Modify();
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var ServiceShipmentHeader: Record "Service Shipment Header")
    begin
    end;
}

