codeunit 10001 "Shipment Line - Edit"
{
    Permissions = TableData "Sales Shipment Line" = imd;
    TableNo = "Sales Shipment Line";

    trigger OnRun()
    begin
        SalesShipmentLine := Rec;
        SalesShipmentLine.LockTable();
        SalesShipmentLine.Find;
        SalesShipmentLine."Package Tracking No." := "Package Tracking No.";
        SalesShipmentLine.Modify();
        Rec := SalesShipmentLine;
    end;

    var
        SalesShipmentLine: Record "Sales Shipment Line";
}

