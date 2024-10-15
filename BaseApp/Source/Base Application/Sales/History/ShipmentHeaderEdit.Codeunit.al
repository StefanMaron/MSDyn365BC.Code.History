namespace Microsoft.Sales.History;

using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.History;
using Microsoft.Service.History;

codeunit 391 "Shipment Header - Edit"
{
    Permissions = TableData "Sales Shipment Header" = rm,
                  TableData "Transfer Shipment Header" = m,
                  TableData "Service Shipment Header" = m,
                  TableData "Return Shipment Header" = m;
    TableNo = "Sales Shipment Header";

    trigger OnRun()
    begin
        SalesShptHeader := Rec;
        SalesShptHeader.LockTable();
        SalesShptHeader.Find();
        SalesShptHeader."Shipping Agent Code" := Rec."Shipping Agent Code";
        SalesShptHeader."Shipping Agent Service Code" := Rec."Shipping Agent Service Code";
        SalesShptHeader."Package Tracking No." := Rec."Package Tracking No.";
        SalesShptHeader."3rd Party Loader Type" := Rec."3rd Party Loader Type";
        SalesShptHeader."3rd Party Loader No." := Rec."3rd Party Loader No.";
        SalesShptHeader."Shipment Method Code" := Rec."Shipment Method Code";
        SalesShptHeader."Additional Information" := Rec."Additional Information";
        SalesShptHeader."Additional Notes" := Rec."Additional Notes";
        SalesShptHeader."Additional Instructions" := Rec."Additional Instructions";
        SalesShptHeader."TDD Prepared By" := Rec."TDD Prepared By";
        OnBeforeSalesShptHeaderModify(SalesShptHeader, Rec);
        SalesShptHeader.TestField("No.", Rec."No.");
        SalesShptHeader.Modify();
        Rec := SalesShptHeader;

        OnRunOnAfterSalesShptHeaderEdit(Rec);
    end;

    var
        SalesShptHeader: Record "Sales Shipment Header";

    [Scope('OnPrem')]
    procedure ModifyReturnShipment(var ReturnShptHeader2: Record "Return Shipment Header")
    var
        ReturnShptHeader: Record "Return Shipment Header";
    begin
        ReturnShptHeader := ReturnShptHeader2;
        ReturnShptHeader.LockTable();
        ReturnShptHeader.Find();
        ReturnShptHeader."Shipping Agent Code" := ReturnShptHeader2."Shipping Agent Code";
        ReturnShptHeader."Shipment Method Code" := ReturnShptHeader2."Shipment Method Code";
        ReturnShptHeader."3rd Party Loader Type" := ReturnShptHeader2."3rd Party Loader Type";
        ReturnShptHeader."3rd Party Loader No." := ReturnShptHeader2."3rd Party Loader No.";
        ReturnShptHeader."Additional Information" := ReturnShptHeader2."Additional Information";
        ReturnShptHeader."Additional Notes" := ReturnShptHeader2."Additional Notes";
        ReturnShptHeader."Additional Instructions" := ReturnShptHeader2."Additional Instructions";
        ReturnShptHeader."TDD Prepared By" := ReturnShptHeader2."TDD Prepared By";
        OnBeforeReturnShptHeaderModify(ReturnShptHeader, ReturnShptHeader2);
        ReturnShptHeader.Modify();
        ReturnShptHeader2 := ReturnShptHeader;
    end;

    [Scope('OnPrem')]
    procedure ModifyTransferShipment(var TransferShptHeader2: Record "Transfer Shipment Header")
    var
        TransferShptHeader: Record "Transfer Shipment Header";
    begin
        TransferShptHeader := TransferShptHeader2;
        TransferShptHeader.LockTable();
        TransferShptHeader.Find();
        TransferShptHeader."Transport Reason Code" := TransferShptHeader2."Transport Reason Code";
        TransferShptHeader."Goods Appearance" := TransferShptHeader2."Goods Appearance";
        TransferShptHeader."Gross Weight" := TransferShptHeader2."Gross Weight";
        TransferShptHeader."Net Weight" := TransferShptHeader2."Net Weight";
        TransferShptHeader."Parcel Units" := TransferShptHeader2."Parcel Units";
        TransferShptHeader.Volume := TransferShptHeader2.Volume;
        TransferShptHeader."Shipping Notes" := TransferShptHeader2."Shipping Notes";
        TransferShptHeader."3rd Party Loader Type" := TransferShptHeader2."3rd Party Loader Type";
        TransferShptHeader."3rd Party Loader No." := TransferShptHeader2."3rd Party Loader No.";
        TransferShptHeader."Shipping Starting Date" := TransferShptHeader2."Shipping Starting Date";
        TransferShptHeader."Shipping Starting Time" := TransferShptHeader2."Shipping Starting Time";
        TransferShptHeader."Package Tracking No." := TransferShptHeader2."Package Tracking No.";
        TransferShptHeader."Additional Information" := TransferShptHeader2."Additional Information";
        TransferShptHeader."Additional Notes" := TransferShptHeader2."Additional Notes";
        TransferShptHeader."Additional Instructions" := TransferShptHeader2."Additional Instructions";
        TransferShptHeader."TDD Prepared By" := TransferShptHeader2."TDD Prepared By";
        OnBeforeTransferShptHeaderModify(TransferShptHeader, TransferShptHeader2);
        TransferShptHeader.Modify();
        TransferShptHeader2 := TransferShptHeader;
    end;

    [Scope('OnPrem')]
    procedure ModifyServiceShipment(var ServiceShptHeader2: Record "Service Shipment Header")
    var
        ServiceShptHeader: Record "Service Shipment Header";
    begin
        ServiceShptHeader := ServiceShptHeader2;
        ServiceShptHeader.LockTable();
        ServiceShptHeader.Find();
        ServiceShptHeader."Shipping Agent Code" := ServiceShptHeader2."Shipping Agent Code";
        ServiceShptHeader."Shipment Method Code" := ServiceShptHeader2."Shipment Method Code";
        ServiceShptHeader."3rd Party Loader Type" := ServiceShptHeader2."3rd Party Loader Type";
        ServiceShptHeader."3rd Party Loader No." := ServiceShptHeader2."3rd Party Loader No.";
        ServiceShptHeader."Additional Information" := ServiceShptHeader2."Additional Information";
        ServiceShptHeader."Additional Notes" := ServiceShptHeader2."Additional Notes";
        ServiceShptHeader."Additional Instructions" := ServiceShptHeader2."Additional Instructions";
        ServiceShptHeader."TDD Prepared By" := ServiceShptHeader2."TDD Prepared By";
        OnBeforeServiceShptHeaderModify(ServiceShptHeader, ServiceShptHeader2);
        ServiceShptHeader.Modify();
        ServiceShptHeader2 := ServiceShptHeader;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShptHeaderModify(var SalesShptHeader: Record "Sales Shipment Header"; FromSalesShptHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSalesShptHeaderEdit(var SalesShptHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnShptHeaderModify(var ReturnShipmentHeader: Record "Return Shipment Header"; ReturnShipmentHeader2: Record "Return Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferShptHeaderModify(var TransferShipmentHeader: Record "Transfer Shipment Header"; TransferShipmentHeader2: Record "Transfer Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceShptHeaderModify(var ServiceShipmentHeader: Record "Service Shipment Header"; ServiceShipmentHeader2: Record "Service Shipment Header")
    begin
    end;
}

