namespace Microsoft.Purchases.History;

codeunit 6651 "Return Shipment - Printed"
{
    Permissions = TableData "Return Shipment Header" = rimd;
    TableNo = "Return Shipment Header";

    trigger OnRun()
    begin
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        OnBeforeModify(Rec);
        Rec.Modify();
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var ReturnShipmentHeader: Record "Return Shipment Header")
    begin
    end;
}

