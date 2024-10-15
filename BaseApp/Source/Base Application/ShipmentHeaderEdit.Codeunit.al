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
        SalesShptHeader.LockTable;
        SalesShptHeader.Find;
        SalesShptHeader."Shipping Agent Code" := "Shipping Agent Code";
        SalesShptHeader."Shipping Agent Service Code" := "Shipping Agent Service Code";
        SalesShptHeader."Package Tracking No." := "Package Tracking No.";
        SalesShptHeader."3rd Party Loader Type" := "3rd Party Loader Type";
        SalesShptHeader."3rd Party Loader No." := "3rd Party Loader No.";
        SalesShptHeader."Shipment Method Code" := "Shipment Method Code";
        SalesShptHeader."Additional Information" := "Additional Information";
        SalesShptHeader."Additional Notes" := "Additional Notes";
        SalesShptHeader."Additional Instructions" := "Additional Instructions";
        SalesShptHeader."TDD Prepared By" := "TDD Prepared By";
        OnBeforeSalesShptHeaderModify(SalesShptHeader, Rec);
        SalesShptHeader.TestField("No.", "No.");
        SalesShptHeader.Modify;
        Rec := SalesShptHeader;
    end;

    var
        SalesShptHeader: Record "Sales Shipment Header";

    [Scope('OnPrem')]
    procedure ModifyReturnShipment(var ReturnShptHeader2: Record "Return Shipment Header")
    var
        ReturnShptHeader: Record "Return Shipment Header";
    begin
        ReturnShptHeader := ReturnShptHeader2;
        ReturnShptHeader.LockTable;
        ReturnShptHeader.Find;
        with ReturnShptHeader2 do begin
            ReturnShptHeader."Shipping Agent Code" := "Shipping Agent Code";
            ReturnShptHeader."Shipment Method Code" := "Shipment Method Code";
            ReturnShptHeader."3rd Party Loader Type" := "3rd Party Loader Type";
            ReturnShptHeader."3rd Party Loader No." := "3rd Party Loader No.";
            ReturnShptHeader."Additional Information" := "Additional Information";
            ReturnShptHeader."Additional Notes" := "Additional Notes";
            ReturnShptHeader."Additional Instructions" := "Additional Instructions";
            ReturnShptHeader."TDD Prepared By" := "TDD Prepared By";
            OnBeforeReturnShptHeaderModify(ReturnShptHeader, ReturnShptHeader2);
            ReturnShptHeader.Modify;
        end;
        ReturnShptHeader2 := ReturnShptHeader;
    end;

    [Scope('OnPrem')]
    procedure ModifyTransferShipment(var TransferShptHeader2: Record "Transfer Shipment Header")
    var
        TransferShptHeader: Record "Transfer Shipment Header";
    begin
        TransferShptHeader := TransferShptHeader2;
        TransferShptHeader.LockTable;
        TransferShptHeader.Find;
        with TransferShptHeader2 do begin
            TransferShptHeader."Transport Reason Code" := "Transport Reason Code";
            TransferShptHeader."Goods Appearance" := "Goods Appearance";
            TransferShptHeader."Gross Weight" := "Gross Weight";
            TransferShptHeader."Net Weight" := "Net Weight";
            TransferShptHeader."Parcel Units" := "Parcel Units";
            TransferShptHeader.Volume := Volume;
            TransferShptHeader."Shipping Notes" := "Shipping Notes";
            TransferShptHeader."3rd Party Loader Type" := "3rd Party Loader Type";
            TransferShptHeader."3rd Party Loader No." := "3rd Party Loader No.";
            TransferShptHeader."Shipping Starting Date" := "Shipping Starting Date";
            TransferShptHeader."Shipping Starting Time" := "Shipping Starting Time";
            TransferShptHeader."Package Tracking No." := "Package Tracking No.";
            TransferShptHeader."Additional Information" := "Additional Information";
            TransferShptHeader."Additional Notes" := "Additional Notes";
            TransferShptHeader."Additional Instructions" := "Additional Instructions";
            TransferShptHeader."TDD Prepared By" := "TDD Prepared By";
            OnBeforeTransferShptHeaderModify(TransferShptHeader, TransferShptHeader2);
            TransferShptHeader.Modify;
        end;
        TransferShptHeader2 := TransferShptHeader;
    end;

    [Scope('OnPrem')]
    procedure ModifyServiceShipment(var ServiceShptHeader2: Record "Service Shipment Header")
    var
        ServiceShptHeader: Record "Service Shipment Header";
    begin
        ServiceShptHeader := ServiceShptHeader2;
        ServiceShptHeader.LockTable;
        ServiceShptHeader.Find;
        with ServiceShptHeader2 do begin
            ServiceShptHeader."Shipping Agent Code" := "Shipping Agent Code";
            ServiceShptHeader."Shipment Method Code" := "Shipment Method Code";
            ServiceShptHeader."3rd Party Loader Type" := "3rd Party Loader Type";
            ServiceShptHeader."3rd Party Loader No." := "3rd Party Loader No.";
            ServiceShptHeader."Additional Information" := "Additional Information";
            ServiceShptHeader."Additional Notes" := "Additional Notes";
            ServiceShptHeader."Additional Instructions" := "Additional Instructions";
            ServiceShptHeader."TDD Prepared By" := "TDD Prepared By";
            OnBeforeServiceShptHeaderModify(ServiceShptHeader, ServiceShptHeader2);
            ServiceShptHeader.Modify;
        end;
        ServiceShptHeader2 := ServiceShptHeader;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShptHeaderModify(var SalesShptHeader: Record "Sales Shipment Header"; FromSalesShptHeader: Record "Sales Shipment Header")
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

