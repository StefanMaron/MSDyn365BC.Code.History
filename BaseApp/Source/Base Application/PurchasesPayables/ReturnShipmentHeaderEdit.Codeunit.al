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
        ReturnShipmentHeader.Find();
        ReturnShipmentHeader."Ship-to County" := "Ship-to County";
        ReturnShipmentHeader."Ship-to Country/Region Code" := "Ship-to Country/Region Code";
        ReturnShipmentHeader."Additional Information" := "Additional Information";
        ReturnShipmentHeader."Additional Notes" := "Additional Notes";
        ReturnShipmentHeader."Additional Instructions" := "Additional Instructions";
        ReturnShipmentHeader."TDD Prepared By" := "TDD Prepared By";
        ReturnShipmentHeader."Shipment Method Code" := "Shipment Method Code";
        ReturnShipmentHeader."Shipping Agent Code" := "Shipping Agent Code";
        ReturnShipmentHeader."3rd Party Loader Type" := "3rd Party Loader Type";
        ReturnShipmentHeader."3rd Party Loader No." := "3rd Party Loader No.";
        OnBeforeReturnShipmentHeaderModify(ReturnShipmentHeader, Rec);
        ReturnShipmentHeader.TestField("No.", "No.");
        ReturnShipmentHeader.Modify();
        Rec := ReturnShipmentHeader;

        OnRunOnAfterReturnShipmentHeaderEdit(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnShipmentHeaderModify(var ReturnShipmentHeader: Record "Return Shipment Header"; ReturnShipmentHeaderRec: Record "Return Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterReturnShipmentHeaderEdit(var ReturnShipmentHeader: Record "Return Shipment Header")
    begin
    end;
}

