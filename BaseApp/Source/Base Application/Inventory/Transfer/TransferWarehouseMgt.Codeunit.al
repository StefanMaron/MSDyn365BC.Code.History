namespace Microsoft.Inventory.Transfer;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;

codeunit 5993 "Transfer Warehouse Mgt."
{
    var
#if not CLEAN23
        WMSManagement: Codeunit "WMS Management";
#endif
        WhseValidateSourceHeader: Codeunit "Whse. Validate Source Header";
        WhseCreateSourceDocument: Codeunit "Whse.-Create Source Document";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocLine', '', false, false)]
    local procedure OnShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    var
        TransferLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        if SourceType = Database::"Transfer Line" then begin
            TransferLine.Reset();
            TransferLine.SetRange("Document No.", SourceNo);
            TransferLine.SetRange("Line No.", SourceLineNo);
            IsHandled := false;
#if not CLEAN23
            WMSManagement.RunOnShowSourceDocLineOnBeforeShowTransLines(TransferLine, SourceNo, SourceLineNo, IsHandled);
#endif
            OnBeforeShowTransferLines(TransferLine, SourceNo, SourceLineNo, IsHandled);
            if not IsHandled then
                ShowTransferLines(TransferLine);
        end;
    end;

    local procedure ShowTransferLines(var TransferLine: Record "Transfer Line")
    begin
        Page.Run(Page::"Transfer Lines", TransferLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocCard', '', false, false)]
    local procedure OnShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20])
    var
        TransferHeader: Record "Transfer Header";
    begin
        if SourceType = DATABASE::"Transfer Line" then
            if TransferHeader.Get(SourceNo) then
                PAGE.RunModal(PAGE::"Transfer Order", TransferHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowPostedSourceDoc', '', false, false)]
    local procedure OnShowPostedSourceDoc(PostedSourceDoc: Option; PostedSourceNo: Code[20])
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        PostedSourceDocEnum: Enum "Warehouse Shipment Posted Source Document";
    begin
        PostedSourceDocEnum := Enum::"Warehouse Shipment Posted Source Document".FromInteger(PostedSourceDoc);
        case PostedSourceDocEnum of
            PostedSourceDocEnum::"Posted Transfer Shipment":
                begin
                    TransferShipmentHeader.Reset();
                    TransferShipmentHeader.SetRange("No.", PostedSourceNo);
                    PAGE.RunModal(PAGE::"Posted Transfer Shipment", TransferShipmentHeader);
                end;
            PostedSourceDocEnum::"Posted Transfer Receipt":
                begin
                    TransferReceiptHeader.Reset();
                    TransferReceiptHeader.SetRange("No.", PostedSourceNo);
                    PAGE.RunModal(PAGE::"Posted Transfer Receipt", TransferReceiptHeader);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowTransferLines(var TransferLine: Record "Transfer Line"; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Validate Source Line", 'OnWhseLineExistOnBeforeCheckReceipt', '', false, false)]
    local procedure OnWhseLineExistOnBeforeCheckReceipt(SourceType: Integer; SourceSubType: Option; SourceQty: Decimal; var CheckReceipt: Boolean)
    begin
        CheckReceipt := CheckReceipt or
           ((SourceType = DATABASE::"Transfer Line") and (SourceSubType = 1));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Validate Source Line", 'OnWhseLineExistOnBeforeCheckShipment', '', false, false)]
    local procedure OnWhseLineExistOnBeforeCheckShipment(SourceType: Integer; SourceSubType: Option; SourceQty: Decimal; var CheckShipment: Boolean)
    begin
        CheckShipment := CheckShipment or
            ((SourceType = DATABASE::"Transfer Line") and (SourceSubType = 0));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Request", 'OnShowSourceDocumentCard', '', false, false)]
    local procedure OnShowSourceDocumentCard(var WarehouseRequest: Record "Warehouse Request")
    var
        TransferHeader: Record "Transfer Header";
    begin
        case WarehouseRequest."Source Document" of
            "Warehouse Request Source Document"::"Inbound Transfer",
            "Warehouse Request Source Document"::"Outbound Transfer":
                begin
                    TransferHeader.Get(WarehouseRequest."Source No.");
                    PAGE.Run(PAGE::"Transfer Order", TransferHeader);
                end;
        end;
    end;

    procedure TransHeaderVerifyChange(var NewTransferHeader: Record "Transfer Header"; var OldTransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
    begin
        with NewTransferHeader do begin
            if "Shipping Advice" = OldTransferHeader."Shipping Advice" then
                exit;

            TransferLine.Reset();
            TransferLine.SetRange("Document No.", OldTransferHeader."No.");
            if TransferLine.Find('-') then
                repeat
                    WhseValidateSourceHeader.ChangeWarehouseLines(
                        DATABASE::"Transfer Line", 0,// Outbound Transfer
                        TransferLine."Document No.", TransferLine."Line No.", 0, "Shipping Advice");
                until TransferLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Source Filter", 'OnSetFiltersOnSourceTables', '', false, false)]
    local procedure OnSetFiltersOnSourceTables(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var GetSourceDocuments: Report "Get Source Documents"; var WarehouseRequest: Record "Warehouse Request")
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetFilter("Item No.", WarehouseSourceFilter."Item No. Filter");
        TransferLine.SetFilter("Variant Code", WarehouseSourceFilter."Variant Code Filter");
        TransferLine.SetFilter("Unit of Measure Code", WarehouseSourceFilter."Unit of Measure Filter");
        TransferLine.SetFilter("In-Transit Code", WarehouseSourceFilter."In-Transit Code Filter");
        TransferLine.SetFilter("Transfer-from Code", WarehouseSourceFilter."Transfer-from Code Filter");
        TransferLine.SetFilter("Transfer-to Code", WarehouseSourceFilter."Transfer-to Code Filter");
        TransferLine.SetFilter("Shipment Date", WarehouseSourceFilter."Shipment Date");
        TransferLine.SetFilter("Receipt Date", WarehouseSourceFilter."Receipt Date");
        TransferLine.SetFilter("Shipping Agent Code", WarehouseSourceFilter."Shipping Agent Code Filter");
        TransferLine.SetFilter("Shipping Agent Service Code", WarehouseSourceFilter."Shipping Agent Service Filter");

        OnSetFiltersOnSourceTablesOnBeforeSetTransferTableView(WarehouseSourceFilter, WarehouseRequest, TransferLine);
        GetSourceDocuments.SetTableView(TransferLine);
    end;

    procedure FromTransLine2ShptLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record "Transfer Line") Result: Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        TransferHeader: Record "Transfer Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN23
        WhseCreateSourceDocument.RunOnBeforeFromTransLine2ShptLine(TransferLine, Result, IsHandled, WarehouseShipmentHeader);
#endif
        OnBeforeFromTransLine2ShptLine(TransferLine, Result, IsHandled, WarehouseShipmentHeader);
        if IsHandled then
            exit(Result);

        with WarehouseShipmentLine do begin
            InitNewLine(WarehouseShipmentHeader."No.");
            SetSource(DATABASE::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.");
            TransferLine.TestField("Unit of Measure Code");
            SetItemData(
              TransferLine."Item No.", TransferLine.Description, TransferLine."Description 2", TransferLine."Transfer-from Code",
              TransferLine."Variant Code", TransferLine."Unit of Measure Code", TransferLine."Qty. per Unit of Measure",
              TransferLine."Qty. Rounding Precision", TransferLine."Qty. Rounding Precision (Base)");
#if not CLEAN23
            WhseCreateSourceDocument.RunOnFromTransLine2ShptLineOnAfterInitNewLine(WarehouseShipmentLine, WarehouseShipmentHeader, TransferLine);
#endif
            IsHandled := false;
            OnFromTransLine2ShptLineOnAfterInitNewLine(WarehouseShipmentLine, WarehouseShipmentHeader, TransferLine, IsHandled);
            if not IsHandled then
                WhseCreateSourceDocument.SetQtysOnShptLine(WarehouseShipmentLine, TransferLine."Outstanding Quantity", TransferLine."Outstanding Qty. (Base)");
            "Due Date" := TransferLine."Shipment Date";
            if WarehouseShipmentHeader."Shipment Date" = 0D then
                "Shipment Date" := WorkDate()
            else
                "Shipment Date" := WarehouseShipmentHeader."Shipment Date";
            "Destination Type" := "Destination Type"::Location;
            "Destination No." := TransferLine."Transfer-to Code";
            if TransferHeader.Get(TransferLine."Document No.") then
                "Shipping Advice" := TransferHeader."Shipping Advice";
            if "Location Code" = WarehouseShipmentHeader."Location Code" then
                "Bin Code" := WarehouseShipmentHeader."Bin Code";
            if "Bin Code" = '' then
                "Bin Code" := TransferLine."Transfer-from Bin Code";
            WhseCreateSourceDocument.UpdateShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
#if not CLEAN23
            WhseCreateSourceDocument.RunOnBeforeCreateShptLineFromTransLine(WarehouseShipmentLine, WarehouseShipmentHeader, TransferLine, TransferHeader);
#endif
            OnBeforeCreateShptLineFromTransLine(WarehouseShipmentLine, WarehouseShipmentHeader, TransferLine, TransferHeader);
            WhseCreateSourceDocument.CreateShipmentLine(WarehouseShipmentLine);
#if not CLEAN23
            WhseCreateSourceDocument.RunOnAfterCreateShptLineFromTransLine(WarehouseShipmentLine, WarehouseShipmentHeader, TransferLine, TransferHeader);
#endif
            OnAfterCreateShptLineFromTransLine(WarehouseShipmentLine, WarehouseShipmentHeader, TransferLine, TransferHeader);
            exit(not HasErrorOccured());
        end;
    end;

    procedure TransLine2ReceiptLine(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; TransferLine: Record "Transfer Line") Result: Boolean
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        WhseInbndOtsdgQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN23
        WhseCreateSourceDocument.RunOnBeforeTransLine2ReceiptLine(WarehouseReceiptHeader, TransferLine, Result, IsHandled);
#endif
        OnBeforeTransLine2ReceiptLine(WarehouseReceiptHeader, TransferLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with WarehouseReceiptLine do begin
            InitNewLine(WarehouseReceiptHeader."No.");
            SetSource(DATABASE::"Transfer Line", 1, TransferLine."Document No.", TransferLine."Line No.");
            TransferLine.TestField("Unit of Measure Code");
            SetItemData(
              TransferLine."Item No.", TransferLine.Description, TransferLine."Description 2", TransferLine."Transfer-to Code",
              TransferLine."Variant Code", TransferLine."Unit of Measure Code", TransferLine."Qty. per Unit of Measure",
              TransferLine."Qty. Rounding Precision", TransferLine."Qty. Rounding Precision (Base)");
#if not CLEAN23
            WhseCreateSourceDocument.RunOnTransLine2ReceiptLineOnAfterInitNewLine(WarehouseReceiptLine, WarehouseReceiptHeader, TransferLine);
#endif
            OnTransLine2ReceiptLineOnAfterInitNewLine(WarehouseReceiptLine, WarehouseReceiptHeader, TransferLine);
            Validate("Qty. Received", TransferLine."Quantity Received");
            TransferLine.CalcFields("Whse. Inbnd. Otsdg. Qty (Base)");
            WhseInbndOtsdgQty :=
              UnitOfMeasureManagement.CalcQtyFromBase(
                TransferLine."Item No.", TransferLine."Variant Code", TransferLine."Unit of Measure Code",
                TransferLine."Whse. Inbnd. Otsdg. Qty (Base)", TransferLine."Qty. per Unit of Measure");
            WhseCreateSourceDocument.SetQtysOnRcptLine(
               WarehouseReceiptLine,
               TransferLine."Quantity Received" + TransferLine."Qty. in Transit" - WhseInbndOtsdgQty,
               TransferLine."Qty. Received (Base)" + TransferLine."Qty. in Transit (Base)" - TransferLine."Whse. Inbnd. Otsdg. Qty (Base)");
            "Due Date" := TransferLine."Receipt Date";
            "Starting Date" := WorkDate();
            if "Location Code" = WarehouseReceiptHeader."Location Code" then
                "Bin Code" := WarehouseReceiptHeader."Bin Code";
            if "Bin Code" = '' then
                "Bin Code" := TransferLine."Transfer-To Bin Code";
#if not CLEAN23
            WhseCreateSourceDocument.RunOnBeforeUpdateRcptLineFromTransLine(WarehouseReceiptLine, TransferLine);
#endif
            OnBeforeUpdateRcptLineFromTransLine(WarehouseReceiptLine, TransferLine);
            WhseCreateSourceDocument.UpdateReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader);
            WhseCreateSourceDocument.CreateReceiptLine(WarehouseReceiptLine);
#if not CLEAN23
            WhseCreateSourceDocument.RunOnAfterCreateRcptLineFromTransLine(WarehouseReceiptLine, WarehouseReceiptHeader, TransferLine);
#endif
            OnAfterCreateRcptLineFromTransLine(WarehouseReceiptLine, WarehouseReceiptHeader, TransferLine);
            exit(not HasErrorOccured());
        end;
    end;

    procedure CheckIfFromTransLine2ShptLine(TransferLine: Record "Transfer Line"): Boolean
    begin
        exit(CheckIfFromTransLine2ShptLine(TransferLine, "Reservation From Stock"::" "));
    end;

    procedure CheckIfFromTransLine2ShptLine(TransferLine: Record "Transfer Line"; ReservedFromStock: Enum "Reservation From Stock"): Boolean
    var
        Location: Record Location;
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
#if not CLEAN23
        WhseCreateSourceDocument.RunOnBeforeCheckIfTransLine2ShipmentLine(TransferLine, IsHandled, ReturnValue);
#endif
        OnBeforeCheckIfTransLine2ShipmentLine(TransferLine, IsHandled, ReturnValue);
        if IsHandled then
            exit(ReturnValue);

        if Location.GetLocationSetup(TransferLine."Transfer-from Code", Location) then
            if Location."Use As In-Transit" then
                exit(false);

        if not TransferLine.CheckIfTransferLineMeetsReservedFromStockSetting(TransferLine."Outstanding Qty. (Base)", ReservedFromStock) then
            exit(false);

        TransferLine.CalcFields("Whse Outbnd. Otsdg. Qty (Base)");
        exit(TransferLine."Outstanding Qty. (Base)" > TransferLine."Whse Outbnd. Otsdg. Qty (Base)");
    end;

    procedure CheckIfTransLine2ReceiptLine(TransferLine: Record "Transfer Line"): Boolean
    var
        Location: Record Location;
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
#if not CLEAN23
        WhseCreateSourceDocument.RunOnBeforeCheckIfTransLine2ReceiptLine(TransferLine, IsHandled, ReturnValue);
#endif
        OnBeforeCheckIfTransLine2ReceiptLine(TransferLine, IsHandled, ReturnValue);
        if IsHandled then
            exit(ReturnValue);

        TransferLine.CalcFields("Whse. Inbnd. Otsdg. Qty (Base)");
        if Location.GetLocationSetup(TransferLine."Transfer-to Code", Location) then
            if Location."Use As In-Transit" then
                exit(false);
        exit(TransferLine."Qty. in Transit (Base)" > TransferLine."Whse. Inbnd. Otsdg. Qty (Base)");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromTransLine2ShptLine(var TransferLine: Record "Transfer Line"; var Result: Boolean; var IsHandled: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromTransLine2ShptLineOnAfterInitNewLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateShptLineFromTransLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateShptLineFromTransLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransLine2ReceiptLine(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var TransferLine: Record "Transfer Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransLine2ReceiptLineOnAfterInitNewLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRcptLineFromTransLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateRcptLineFromTransLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfTransLine2ShipmentLine(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfTransLine2ReceiptLine(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFiltersOnSourceTablesOnBeforeSetTransferTableView(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var WarehouseRequest: Record "Warehouse Request"; var TransferLine: Record "Transfer Line")
    begin
    end;
}