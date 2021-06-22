codeunit 1406 "Return Shipment Header - Edit"
{
    Permissions = TableData "Return Shipment Header" = rm;
    TableNo = "Return Shipment Header";

    trigger OnRun()
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        ReturnShipmentHeader := Rec;
        ReturnShipmentHeader.LockTable();
        ReturnShipmentHeader.Find;
        ReturnShipmentHeader."Ship-to County" := "Ship-to County";
        ReturnShipmentHeader."Ship-to Country/Region Code" := "Ship-to Country/Region Code";
        OnBeforeReturnShipmentHeaderModify(ReturnShipmentHeader, Rec);
        ReturnShipmentHeader.TestField("No.", "No.");
        ReturnShipmentHeader.Modify();
        Rec := ReturnShipmentHeader;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnShipmentHeaderModify(var ReturnShipmentHeader: Record "Return Shipment Header"; ReturnShipmentHeaderRec: Record "Return Shipment Header")
    begin
    end;
}

