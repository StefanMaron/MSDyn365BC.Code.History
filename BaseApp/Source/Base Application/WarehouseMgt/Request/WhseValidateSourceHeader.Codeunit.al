namespace Microsoft.Warehouse.Request;

using Microsoft.Foundation.Shipping;
#if not CLEAN23
using Microsoft.Inventory.Transfer;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
#endif
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Worksheet;

codeunit 5781 "Whse. Validate Source Header"
{
#if not CLEAN23
    var
        SalesWarehouseMgt: Codeunit "Sales Warehouse Mgt.";
        ServiceWarehouseMgt: Codeunit "Service Warehouse Mgt.";
        TransferWarehouseMgt: Codeunit "Transfer Warehouse Mgt.";
#endif

    trigger OnRun()
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Sales Warehouse Mgt.', '23.0')]
    procedure SalesHeaderVerifyChange(var NewSalesHeader: Record "Sales Header"; var OldSalesHeader: Record "Sales Header")
    begin
        SalesWarehouseMgt.SalesHeaderVerifyChange(NewSalesHeader, OldSalesHeader);
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Service Warehouse Mgt.', '23.0')]
    procedure ServiceHeaderVerifyChange(var NewServiceHeader: Record "Service Header"; var OldServiceHeader: Record "Service Header")
    begin
        ServiceWarehouseMgt.ServiceHeaderVerifyChange(NewServiceHeader, OldServiceHeader);
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Service Warehouse Mgt.', '23.0')]
    procedure TransHeaderVerifyChange(var NewTransferHeader: Record "Transfer Header"; var OldTransferHeader: Record "Transfer Header")
    begin
        TransferWarehouseMgt.TransHeaderVerifyChange(NewTransferHeader, OldTransferHeader);
    end;
#endif

    internal procedure ChangeWarehouseLines(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; ShipAdvice: Enum "Sales Header Shipping Advice")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WarehouseShipmentLine.Reset();
        WarehouseShipmentLine.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, false);
        if not WarehouseShipmentLine.IsEmpty() then
            WarehouseShipmentLine.ModifyAll("Shipping Advice", ShipAdvice);

        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, false);
        if not WarehouseActivityLine.IsEmpty() then
            WarehouseActivityLine.ModifyAll("Shipping Advice", ShipAdvice);

        WhseWorksheetLine.Reset();
        WhseWorksheetLine.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, false);
        if not WhseWorksheetLine.IsEmpty() then
            WhseWorksheetLine.ModifyAll("Shipping Advice", ShipAdvice);
    end;

#if not CLEAN23
    internal procedure RunOnBeforeSalesHeaderVerifyChange(var NewSalesHeader: Record "Sales Header"; var OldSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
        OnBeforeSalesHeaderVerifyChange(NewSalesHeader, OldSalesHeader, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnBeforeSalesHeaderVerifyChange(var NewSalesHeader: Record "Sales Header"; var OldSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
#endif
}

