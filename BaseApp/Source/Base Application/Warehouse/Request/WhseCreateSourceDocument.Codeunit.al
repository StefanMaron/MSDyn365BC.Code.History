namespace Microsoft.Warehouse.Request;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Document;

codeunit 5750 "Whse.-Create Source Document"
{

    trigger OnRun()
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Sales Warehouse Mgt.', '23.0')]
    procedure FromSalesLine2ShptLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line") Result: Boolean
    var
        SalesWarehouseMgt: Codeunit Microsoft.Sales.Document."Sales Warehouse Mgt.";
    begin
        exit(SalesWarehouseMgt.FromSalesLine2ShptLine(WarehouseShipmentHeader, SalesLine));
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Sales Warehouse Mgt.', '23.0')]
    procedure SalesLine2ReceiptLine(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line"): Boolean
    var
        SalesWarehouseMgt: Codeunit Microsoft.Sales.Document."Sales Warehouse Mgt.";
    begin
        exit(SalesWarehouseMgt.SalesLine2ReceiptLine(WarehouseReceiptHeader, SalesLine));
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Service Warehouse Mgt.', '23.0')]
    procedure FromServiceLine2ShptLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceLine: Record Microsoft.Service.Document."Service Line"): Boolean
    var
        ServiceWarehouseMgt: Codeunit Microsoft.Service.Document."Service Warehouse Mgt.";
    begin
        exit(ServiceWarehouseMgt.FromServiceLine2ShptLine(WarehouseShipmentHeader, ServiceLine));
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Purchases Warehouse Mgt.', '23.0')]
    procedure FromPurchLine2ShptLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line") Result: Boolean
    var
        PurchasesWarehouseMgt: Codeunit Microsoft.Purchases.Document."Purchases Warehouse Mgt.";
    begin
        exit(PurchasesWarehouseMgt.FromPurchLine2ShptLine(WarehouseShipmentHeader, PurchaseLine));
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Purchases Warehouse Mgt.', '23.0')]
    procedure PurchLine2ReceiptLine(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"): Boolean
    var
        PurchasesWarehouseMgt: Codeunit Microsoft.Purchases.Document."Purchases Warehouse Mgt.";
    begin
        exit(PurchasesWarehouseMgt.PurchLine2ReceiptLine(WarehouseReceiptHeader, PurchaseLine));
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Transfer Warehouse Mgt.', '23.0')]
    procedure FromTransLine2ShptLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line") Result: Boolean
    var
        TransferWarehouseMgt: Codeunit Microsoft.Inventory.Transfer."Transfer Warehouse Mgt.";
    begin
        exit(TransferWarehouseMgt.FromTransLine2ShptLine(WarehouseShipmentHeader, TransferLine));
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Transfer Warehouse Mgt.', '23.0')]
    procedure TransLine2ReceiptLine(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line") Result: Boolean
    var
        TransferWarehouseMgt: Codeunit Microsoft.Inventory.Transfer."Transfer Warehouse Mgt.";
    begin
        exit(TransferWarehouseMgt.TransLine2ReceiptLine(WarehouseReceiptHeader, TransferLine));
    end;
#endif

    internal procedure CreateShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        Item: Record Item;
    begin
        Item."No." := WarehouseShipmentLine."Item No.";
        Item.ItemSKUGet(Item, WarehouseShipmentLine."Location Code", WarehouseShipmentLine."Variant Code");
        WarehouseShipmentLine."Shelf No." := Item."Shelf No.";
        OnBeforeWhseShptLineInsert(WarehouseShipmentLine);
        WarehouseShipmentLine.Insert();
        OnAfterWhseShptLineInsert(WarehouseShipmentLine);
        WarehouseShipmentLine.CreateWhseItemTrackingLines();

        OnAfterCreateShptLine(WarehouseShipmentLine);
    end;

    internal procedure SetQtysOnShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; Qty: Decimal; QtyBase: Decimal)
    var
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetQtysOnShptLine(WarehouseShipmentLine, Qty, QtyBase, IsHandled);
        if not IsHandled then begin
            WarehouseShipmentLine.Quantity := Qty;
            WarehouseShipmentLine."Qty. (Base)" := QtyBase;
            WarehouseShipmentLine.InitOutstandingQtys();
            WarehouseShipmentLine.CheckSourceDocLineQty();
            if Location.Get(WarehouseShipmentLine."Location Code") then
                WarehouseShipmentLine.CheckBin(0, 0);
        end;

        OnAfterSetQtysOnShptLine(WarehouseShipmentLine, Qty, QtyBase);
    end;

    internal procedure CreateReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateReceiptLine(WarehouseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        Item."No." := WarehouseReceiptLine."Item No.";
        Item.ItemSKUGet(Item, WarehouseReceiptLine."Location Code", WarehouseReceiptLine."Variant Code");
        WarehouseReceiptLine."Shelf No." := Item."Shelf No.";
        WarehouseReceiptLine.Status := WarehouseReceiptLine.GetLineStatus();
        OnBeforeWhseReceiptLineInsert(WarehouseReceiptLine);
        WarehouseReceiptLine.Insert();
        OnAfterWhseReceiptLineInsert(WarehouseReceiptLine);
    end;

    internal procedure SetQtysOnRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; Qty: Decimal; QtyBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetQtysOnRcptLine(WarehouseReceiptLine, Qty, QtyBase, IsHandled);
        if IsHandled then
            exit;

        WarehouseReceiptLine.Quantity := Qty;
        WarehouseReceiptLine."Qty. (Base)" := QtyBase;
        WarehouseReceiptLine.InitOutstandingQtys();

        OnAfterSetQtysOnRcptLine(WarehouseReceiptLine, Qty, QtyBase);
    end;

    internal procedure UpdateShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateShptLine(WarehouseShipmentLine, WarehouseShipmentHeader, IsHandled);
        if IsHandled then
            exit;

        if WarehouseShipmentHeader."Zone Code" <> '' then
            WarehouseShipmentLine.Validate("Zone Code", WarehouseShipmentHeader."Zone Code");
        if WarehouseShipmentHeader."Bin Code" <> '' then
            WarehouseShipmentLine.Validate("Bin Code", WarehouseShipmentHeader."Bin Code");
    end;

    internal procedure UpdateReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader, IsHandled);
        if not IsHandled then begin
            if WarehouseReceiptHeader."Zone Code" <> '' then
                WarehouseReceiptLine.Validate("Zone Code", WarehouseReceiptHeader."Zone Code");
            if WarehouseReceiptHeader."Bin Code" <> '' then
                WarehouseReceiptLine.Validate("Bin Code", WarehouseReceiptHeader."Bin Code");
            if WarehouseReceiptHeader."Cross-Dock Zone Code" <> '' then
                WarehouseReceiptLine.Validate("Cross-Dock Zone Code", WarehouseReceiptHeader."Cross-Dock Zone Code");
            if WarehouseReceiptHeader."Cross-Dock Bin Code" <> '' then
                WarehouseReceiptLine.Validate("Cross-Dock Bin Code", WarehouseReceiptHeader."Cross-Dock Bin Code");
            OnAfterUpdateReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader);
        end;
    end;

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Sales Warehouse Mgt.', '23.0')]
    procedure CheckIfFromSalesLine2ShptLine(SalesLine: Record Microsoft.Sales.Document."Sales Line"): Boolean
    var
        SalesWarehouseMgt: Codeunit Microsoft.Sales.Document."Sales Warehouse Mgt.";
    begin
        exit(SalesWarehouseMgt.CheckIfFromSalesLine2ShptLine(SalesLine));
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Service Warehouse Mgt.', '23.0')]
    procedure CheckIfFromServiceLine2ShptLin(ServiceLine: Record Microsoft.Service.Document."Service Line"): Boolean
    var
        ServiceWarehouseMgt: Codeunit Microsoft.Service.Document."Service Warehouse Mgt.";
    begin
        exit(ServiceWarehouseMgt.CheckIfFromServiceLine2ShptLine(ServiceLine));
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Sales Warehouse Mgt.', '23.0')]
    procedure CheckIfSalesLine2ReceiptLine(SalesLine: Record Microsoft.Sales.Document."Sales Line"): Boolean
    var
        SalesWarehouseMgt: Codeunit Microsoft.Sales.Document."Sales Warehouse Mgt.";
    begin
        exit(SalesWarehouseMgt.CheckIfSalesLine2ReceiptLine(SalesLine));
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Purchases Warehouse Mgt.', '23.0')]
    procedure CheckIfFromPurchLine2ShptLine(PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"): Boolean
    var
        PurchasesWarehouseMgt: Codeunit Microsoft.Purchases.Document."Purchases Warehouse Mgt.";
    begin
        exit(PurchasesWarehouseMgt.CheckIfFromPurchLine2ShptLine(PurchaseLine));
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Purchases Warehouse Mgt.', '23.0')]
    procedure CheckIfPurchLine2ReceiptLine(PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"): Boolean
    var
        PurchasesWarehouseMgt: Codeunit Microsoft.Purchases.Document."Purchases Warehouse Mgt.";
    begin
        exit(PurchasesWarehouseMgt.CheckIfPurchLine2ReceiptLine(PurchaseLine));
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Transfer Warehouse Mgt.', '23.0')]
    procedure CheckIfFromTransLine2ShptLine(TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"): Boolean
    var
        TransferWarehouseMgt: Codeunit Microsoft.Inventory.Transfer."Transfer Warehouse Mgt.";
    begin
        exit(TransferWarehouseMgt.CheckIfFromTransLine2ShptLine(TransferLine));
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by same procedure in codeunit Transfer Warehouse Mgt.', '23.0')]
    procedure CheckIfTransLine2ReceiptLine(TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"): Boolean
    var
        TransferWarehouseMgt: Codeunit Microsoft.Inventory.Transfer."Transfer Warehouse Mgt.";
    begin
        exit(TransferWarehouseMgt.CheckIfTransLine2ReceiptLine(TransferLine));
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

#if not CLEAN23
    internal procedure RunOnAfterCreateShptLineFromSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line"; SalesHeader: Record Microsoft.Sales.Document."Sales Header")
    begin
        OnAfterCreateShptLineFromSalesLine(WarehouseShipmentLine, WarehouseShipmentHeader, SalesLine, SalesHeader);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnAfterCreateShptLineFromSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line"; SalesHeader: Record Microsoft.Sales.Document."Sales Header")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterCreateRcptLineFromSalesLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
        OnAfterCreateRcptLineFromSalesLine(WarehouseReceiptLine, WarehouseReceiptHeader, SalesLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnAfterCreateRcptLineFromSalesLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterCreateShptLineFromServiceLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        OnAfterCreateShptLineFromServiceLine(WarehouseShipmentLine, WarehouseShipmentHeader, ServiceLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Service Warehouse Mgt.', '23.0')]
    local procedure OnAfterCreateShptLineFromServiceLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterCreateShptLineFromPurchLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
        OnAfterCreateShptLineFromPurchLine(WarehouseShipmentLine, WarehouseShipmentHeader, PurchaseLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Purchases Warehouse Mgt.', '23.0')]
    local procedure OnAfterCreateShptLineFromPurchLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterCreateRcptLineFromPurchLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
        OnAfterCreateRcptLineFromPurchLine(WarehouseReceiptLine, WarehouseReceiptHeader, PurchaseLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Purchases Warehouse Mgt.', '23.0')]
    local procedure OnAfterCreateRcptLineFromPurchLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterCreateShptLineFromTransLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; TransferHeader: Record Microsoft.Inventory.Transfer."Transfer Header")
    begin
        OnAfterCreateShptLineFromTransLine(WarehouseShipmentLine, WarehouseShipmentHeader, TransferLine, TransferHeader);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Transfer Warehouse Mgt.', '23.0')]
    local procedure OnAfterCreateShptLineFromTransLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; TransferHeader: Record Microsoft.Inventory.Transfer."Transfer Header")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterCreateRcptLineFromTransLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line")
    begin
        OnAfterCreateRcptLineFromTransLine(WarehouseReceiptLine, WarehouseReceiptHeader, TransferLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Transfer Warehouse Mgt.', '23.0')]
    local procedure OnAfterCreateRcptLineFromTransLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnAfterInitNewWhseShptLine(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line"; AssembleToOrder: Boolean)
    begin
        OnAfterInitNewWhseShptLine(WhseShptLine, WhseShptHeader, SalesLine, AssembleToOrder);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnAfterInitNewWhseShptLine(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line"; AssembleToOrder: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetQtysOnRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; Qty: Decimal; QtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseReceiptLineInsert(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseShptLineInsert(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

#if not CLEAN23
    internal procedure RunOnBeforeCheckIfSalesLine2ReceiptLine(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeCheckIfSalesLine2ReceiptLine(SalesLine, ReturnValue, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnBeforeCheckIfSalesLine2ReceiptLine(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnBeforeCheckIfSalesLine2ShptLine(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeCheckIfSalesLine2ShptLine(SalesLine, ReturnValue, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnBeforeCheckIfSalesLine2ShptLine(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnBeforeCheckIfPurchLine2ReceiptLine(var PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeCheckIfPurchLine2ReceiptLine(PurchaseLine, ReturnValue, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Purchases Warehouse Mgt.', '23.0')]
    local procedure OnBeforeCheckIfPurchLine2ReceiptLine(var PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnBeforeCheckIfPurchLine2ShptLine(var PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeCheckIfPurchLine2ShptLine(PurchaseLine, ReturnValue, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Purchases Warehouse Mgt.', '23.0')]
    local procedure OnBeforeCheckIfPurchLine2ShptLine(var PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnBeforeCheckIfTransLine2ReceiptLine(var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
        OnBeforeCheckIfTransLine2ReceiptLine(TransferLine, IsHandled, ReturnValue);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Transfer Warehouse Mgt.', '23.0')]
    local procedure OnBeforeCheckIfTransLine2ReceiptLine(var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnBeforeCheckIfTransLine2ShipmentLine(var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
        OnBeforeCheckIfTransLine2ShipmentLine(TransferLine, IsHandled, ReturnValue);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Transfer Warehouse Mgt.', '23.0')]
    local procedure OnBeforeCheckIfTransLine2ShipmentLine(var TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnBeforeCreateReceiptLineFromSalesLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
        OnBeforeCreateReceiptLineFromSalesLine(WarehouseReceiptLine, WarehouseReceiptHeader, SalesLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnBeforeCreateReceiptLineFromSalesLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReceiptLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN23
    internal procedure RunOnBeforeCreateShptLineFromSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line"; SalesHeader: Record Microsoft.Sales.Document."Sales Header")
    begin
        OnBeforeCreateShptLineFromSalesLine(WarehouseShipmentLine, WarehouseShipmentHeader, SalesLine, SalesHeader);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnBeforeCreateShptLineFromSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line"; SalesHeader: Record Microsoft.Sales.Document."Sales Header")
    begin
    end;
#endif

#if not CLEAN23
    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by OnFromPurchLine2ShptLineOnBeforeCreateShptLine in codeunit Purchases Warehouse Mgt.', '23.0')]
    local procedure OnBeforeCreateShptLineFromPurchLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnBeforeCreateShptLineFromTransLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; TransferHeader: Record Microsoft.Inventory.Transfer."Transfer Header")
    begin
        OnBeforeCreateShptLineFromTransLine(WarehouseShipmentLine, WarehouseShipmentHeader, TransferLine, TransferHeader);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Transfer Warehouse Mgt.', '23.0')]
    local procedure OnBeforeCreateShptLineFromTransLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line"; TransferHeader: Record Microsoft.Inventory.Transfer."Transfer Header")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnBeforeFromPurchLine2ShptLine(var PurchLine: Record Microsoft.Purchases.Document."Purchase Line"; var Result: Boolean; var IsHandled: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        OnBeforeFromPurchLine2ShptLine(PurchLine, Result, IsHandled, WarehouseShipmentHeader);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Purchases Warehouse Mgt.', '23.0')]
    local procedure OnBeforeFromPurchLine2ShptLine(var PurchLine: Record Microsoft.Purchases.Document."Purchase Line"; var Result: Boolean; var IsHandled: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnBeforeFromTransLine2ShptLine(var TransLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var Result: Boolean; var IsHandled: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        OnBeforeFromTransLine2ShptLine(TransLine, Result, IsHandled, WarehouseShipmentHeader);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Transfer Warehouse Mgt.', '23.0')]
    local procedure OnBeforeFromTransLine2ShptLine(var TransLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var Result: Boolean; var IsHandled: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnBeforeFromSalesLine2ShptLine(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeFromSalesLine2ShptLine(SalesLine, Result, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnBeforeFromSalesLine2ShptLine(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnBeforePurchLine2ReceiptLine(WhseReceiptHeader: Record "Warehouse Receipt Header"; var PurchLine: Record Microsoft.Purchases.Document."Purchase Line"; var IsHandled: Boolean; var Result: Boolean)
    begin
        OnBeforePurchLine2ReceiptLine(WhseReceiptHeader, PurchLine, IsHandled, Result);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Purchases Warehouse Mgt.', '23.0')]
    local procedure OnBeforePurchLine2ReceiptLine(WhseReceiptHeader: Record "Warehouse Receipt Header"; var PurchLine: Record Microsoft.Purchases.Document."Purchase Line"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetQtysOnShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Qty: Decimal; var QtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN23
    internal procedure RunOnBeforeTransLine2ReceiptLine(WhseReceiptHeader: Record "Warehouse Receipt Header"; var TransLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeTransLine2ReceiptLine(WhseReceiptHeader, TransLine, Result, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Transfer Warehouse Mgt.', '23.0')]
    local procedure OnBeforeTransLine2ReceiptLine(WhseReceiptHeader: Record "Warehouse Receipt Header"; var TransLine: Record Microsoft.Inventory.Transfer."Transfer Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseReceiptLineInsert(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseShptLineInsert(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetQtysOnRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; Qty: Decimal; QtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN23
    internal procedure RunOnBeforeUpdateRcptLineFromTransLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line")
    begin
        OnBeforeUpdateRcptLineFromTransLine(WarehouseReceiptLine, TransferLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Transfer Warehouse Mgt.', '23.0')]
    local procedure OnBeforeUpdateRcptLineFromTransLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnSalesLine2ReceiptLineOnAfterInitNewLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; WhseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
        OnSalesLine2ReceiptLineOnAfterInitNewLine(WhseReceiptLine, WhseReceiptHeader, SalesLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnSalesLine2ReceiptLineOnAfterInitNewLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; WhseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnSalesLine2ReceiptLineOnBeforeUpdateReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
        OnSalesLine2ReceiptLineOnBeforeUpdateReceiptLine(WarehouseReceiptLine, SalesLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnSalesLine2ReceiptLineOnBeforeUpdateReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnFromServiceLine2ShptLineOnAfterInitNewLine(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        OnFromServiceLine2ShptLineOnAfterInitNewLine(WhseShptLine, WhseShptHeader, ServiceLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Service Warehouse Mgt.', '23.0')]
    local procedure OnFromServiceLine2ShptLineOnAfterInitNewLine(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnFromServiceLine2ShptLineOnBeforeCreateShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceHeader: Record Microsoft.Service.Document."Service Header"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        OnFromServiceLine2ShptLineOnBeforeCreateShptLine(WarehouseShipmentLine, WarehouseShipmentHeader, ServiceHeader, ServiceLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Service Warehouse Mgt.', '23.0')]
    local procedure OnFromServiceLine2ShptLineOnBeforeCreateShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceHeader: Record Microsoft.Service.Document."Service Header"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnFromPurchLine2ShptLineOnAfterInitNewLine(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header"; PurchLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
        OnFromPurchLine2ShptLineOnAfterInitNewLine(WhseShptLine, WhseShptHeader, PurchLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Purchases Warehouse Mgt.', '23.0')]
    local procedure OnFromPurchLine2ShptLineOnAfterInitNewLine(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header"; PurchLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnFromPurchLine2ShptLineOnBeforeCreateShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
        OnFromPurchLine2ShptLineOnBeforeCreateShptLine(WarehouseShipmentLine, WarehouseShipmentHeader, PurchaseLine);
        OnBeforeCreateShptLineFromPurchLine(WarehouseShipmentLine, WarehouseShipmentHeader, PurchaseLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Purchases Warehouse Mgt.', '23.0')]
    local procedure OnFromPurchLine2ShptLineOnBeforeCreateShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnPurchLine2ReceiptLineOnAfterInitNewLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; WhseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; var IsHandled: Boolean)
    begin
        OnPurchLine2ReceiptLineOnAfterInitNewLine(WhseReceiptLine, WhseReceiptHeader, PurchaseLine, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Purchases Warehouse Mgt.', '23.0')]
    local procedure OnPurchLine2ReceiptLineOnAfterInitNewLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; WhseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnPurchLine2ReceiptLineOnAfterSetQtysOnRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
        OnPurchLine2ReceiptLineOnAfterSetQtysOnRcptLine(WarehouseReceiptLine, PurchaseLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Purchases Warehouse Mgt.', '23.0')]
    local procedure OnPurchLine2ReceiptLineOnAfterSetQtysOnRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnPurchLine2ReceiptLineOnAfterUpdateReceiptLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; var WhseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
        OnPurchLine2ReceiptLineOnAfterUpdateReceiptLine(WhseReceiptLine, WhseReceiptHeader, PurchaseLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Purchases Warehouse Mgt.', '23.0')]
    local procedure OnPurchLine2ReceiptLineOnAfterUpdateReceiptLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; var WhseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnFromTransLine2ShptLineOnAfterInitNewLine(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line")
    begin
        OnFromTransLine2ShptLineOnAfterInitNewLine(WhseShptLine, WhseShptHeader, TransferLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Transfer Warehouse Mgt.', '23.0')]
    local procedure OnFromTransLine2ShptLineOnAfterInitNewLine(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader: Record "Warehouse Shipment Header"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnTransLine2ReceiptLineOnAfterInitNewLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; WhseReceiptHeader: Record "Warehouse Receipt Header"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line")
    begin
        OnTransLine2ReceiptLineOnAfterInitNewLine(WhseReceiptLine, WhseReceiptHeader, TransferLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Transfer Warehouse Mgt.', '23.0')]
    local procedure OnTransLine2ReceiptLineOnAfterInitNewLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; WhseReceiptHeader: Record "Warehouse Receipt Header"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line")
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnFromSalesLine2ShptLineOnBeforeCreateShipmentLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line"; var TotalOutstandingWhseShptQty: Decimal; var TotalOutstandingWhseShptQtyBase: Decimal)
    begin
        OnFromSalesLine2ShptLineOnBeforeCreateShipmentLine(WarehouseShipmentHeader, SalesLine, TotalOutstandingWhseShptQty, TotalOutstandingWhseShptQtyBase);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnFromSalesLine2ShptLineOnBeforeCreateShipmentLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line"; var TotalOutstandingWhseShptQty: Decimal; var TotalOutstandingWhseShptQtyBase: Decimal)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header");
    begin
    end;

#if not CLEAN23
    internal procedure RunOnBeforeSalesLine2ReceiptLine(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeSalesLine2ReceiptLine(WarehouseReceiptHeader, SalesLine, Result, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnBeforeSalesLine2ReceiptLine(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record Microsoft.Sales.Document."Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnBeforeFromService2ShptLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceLine: Record Microsoft.Service.Document."Service Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeFromService2ShptLine(WarehouseShipmentHeader, ServiceLine, Result, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Service Warehouse Mgt.', '23.0')]
    local procedure OnBeforeFromService2ShptLine(WarehouseShptHeader: Record "Warehouse Shipment Header"; ServiceLine: Record Microsoft.Service.Document."Service Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN23
    internal procedure RunOnFromSalesLine2ShptLineOnBeforeCreateATOShipmentLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; AsmHeader: Record Microsoft.Assembly.Document."Assembly Header"; var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var ATOWhseShptLineQty: Decimal; var ATOWhseShptLineQtyBase: Decimal)
    begin
        OnFromSalesLine2ShptLineOnBeforeCreateATOShipmentLine(WarehouseShipmentHeader, AsmHeader, SalesLine, ATOWhseShptLineQty, ATOWhseShptLineQtyBase);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit Sales Warehouse Mgt.', '23.0')]
    local procedure OnFromSalesLine2ShptLineOnBeforeCreateATOShipmentLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; AsmHeader: Record Microsoft.Assembly.Document."Assembly Header"; var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var ATOWhseShptLineQty: Decimal; var ATOWhseShptLineQtyBase: Decimal)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetQtysOnShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Qty: Decimal; var QtyBase: Decimal)
    begin
    end;
}
