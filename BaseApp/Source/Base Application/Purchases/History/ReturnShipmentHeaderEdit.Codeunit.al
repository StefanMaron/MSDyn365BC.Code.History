namespace Microsoft.Purchases.History;

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
        ReturnShipmentHeader."Ship-to County" := Rec."Ship-to County";
        ReturnShipmentHeader."Ship-to Country/Region Code" := Rec."Ship-to Country/Region Code";
        ReturnShipmentHeader."Additional Information" := Rec."Additional Information";
        ReturnShipmentHeader."Additional Notes" := Rec."Additional Notes";
        ReturnShipmentHeader."Additional Instructions" := Rec."Additional Instructions";
        ReturnShipmentHeader."TDD Prepared By" := Rec."TDD Prepared By";
        ReturnShipmentHeader."Shipment Method Code" := Rec."Shipment Method Code";
        ReturnShipmentHeader."Shipping Agent Code" := Rec."Shipping Agent Code";
        ReturnShipmentHeader."3rd Party Loader Type" := Rec."3rd Party Loader Type";
        ReturnShipmentHeader."3rd Party Loader No." := Rec."3rd Party Loader No.";
        OnBeforeReturnShipmentHeaderModify(ReturnShipmentHeader, Rec);
        ReturnShipmentHeader.TestField("No.", Rec."No.");
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

