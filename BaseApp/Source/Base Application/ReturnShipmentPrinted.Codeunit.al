codeunit 6651 "Return Shipment - Printed"
{
    Permissions = TableData "Return Shipment Header" = rimd;
    TableNo = "Return Shipment Header";

    trigger OnRun()
    begin
        Find;
        "No. Printed" := "No. Printed" + 1;
        OnBeforeModify(Rec);
        Modify;
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var ReturnShipmentHeader: Record "Return Shipment Header")
    begin
    end;
}

