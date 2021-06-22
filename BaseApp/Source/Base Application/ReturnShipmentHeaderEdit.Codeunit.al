codeunit 1406 "Return Shipment Header - Edit"
{
    Permissions = TableData "Return Shipment Header" = rm;
    TableNo = "Return Shipment Header";

    trigger OnRun()
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        ReturnShipmentHeader := Rec;
        ReturnShipmentHeader.LockTable;
        ReturnShipmentHeader.Find;
        ReturnShipmentHeader."Ship-to County" := "Ship-to County";
        ReturnShipmentHeader."Ship-to Country/Region Code" := "Ship-to Country/Region Code";
        ReturnShipmentHeader.TestField("No.", "No.");
        ReturnShipmentHeader.Modify;
        Rec := ReturnShipmentHeader;
    end;
}

