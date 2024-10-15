namespace Microsoft.Service.Document;

using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;

codeunit 5995 "Service Warehouse Mgt."
{
    var
#if not CLEAN23
        WMSManagement: Codeunit "WMS Management";
#endif
        WhseValidateSourceHeader: Codeunit "Whse. Validate Source Header";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocLine', '', false, false)]
    local procedure OnShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    var
        ServiceLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        if SourceType = Database::"Service Line" then begin
            ServiceLine.Reset();
            ServiceLine.SetRange("Document Type", SourceSubType);
            ServiceLine.SetRange("Document No.", SourceNo);
            ServiceLine.SetRange("Line No.", SourceLineNo);
            IsHandled := false;
#if not CLEAN23
            WMSManagement.RunOnShowSourceDocLineOnBeforeShowServiceLines(ServiceLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
#endif
            OnBeforeShowServiceLines(ServiceLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
            if not IsHandled then
                ShowServiceLines(ServiceLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocAttachedLines', '', false, false)]
    local procedure OnShowSourceDocAttachedLines(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        ServiceLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        if SourceType = Database::"Service Line" then begin
            ServiceLine.Reset();
            ServiceLine.SetRange("Document Type", SourceSubType);
            ServiceLine.SetRange("Document No.", SourceNo);
            ServiceLine.SetRange("Attached to Line No.", SourceLineNo);
            IsHandled := false;
            OnBeforeShowAttachedServiceLines(ServiceLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
            if not IsHandled then
                ShowServiceLines(ServiceLine);
        end;
    end;

    local procedure ShowServiceLines(var ServiceLine: Record "Service Line")
    begin
        Page.Run(Page::"Service Line List", ServiceLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowServiceLines(var ServiceLine: Record "Service Line"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowAttachedServiceLines(var ServiceLine: Record "Service Line"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    procedure ServiceLineVerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line")
    var
        NewRecordRef: RecordRef;
        OldRecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN23
        WhseValidateSourceLine.RunOnBeforeServiceLineVerifyChange(NewServiceLine, OldServiceLine, IsHandled);
#endif
        OnBeforeServiceLineVerifyChange(NewServiceLine, OldServiceLine, IsHandled);
        if IsHandled then
            exit;

        if not WhseValidateSourceLine.WhseLinesExist(
             DATABASE::"Service Line", NewServiceLine."Document Type".AsInteger(), NewServiceLine."Document No.", NewServiceLine."Line No.", 0,
             NewServiceLine.Quantity)
        then
            exit;

        NewRecordRef.GetTable(NewServiceLine);
        OldRecordRef.GetTable(OldServiceLine);
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewServiceLine.FieldNo(Type));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewServiceLine.FieldNo("No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewServiceLine.FieldNo("Location Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewServiceLine.FieldNo(Quantity));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewServiceLine.FieldNo("Variant Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewServiceLine.FieldNo("Unit of Measure Code"));

        OnAfterServiceLineVerifyChange(NewRecordRef, OldRecordRef);
#if not CLEAN23
        WhseValidateSourceLine.RunOnAfterServiceLineVerifyChange(NewRecordRef, OldRecordRef);
#endif
    end;

    procedure ServiceLineDelete(var ServiceLine: Record "Service Line")
    begin
        if WhseValidateSourceLine.WhseLinesExist(
             DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.",
             ServiceLine."Line No.", 0, ServiceLine.Quantity)
        then
            WhseValidateSourceLine.RaiseCannotBeDeletedErr(ServiceLine.TableCaption());

        OnAfterServiceLineDelete(ServiceLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Validate Source Line", 'OnWhseLineExistOnBeforeCheckShipment', '', false, false)]
    local procedure OnWhseLineExistOnBeforeCheckShipment(SourceType: Integer; SourceSubType: Option; SourceQty: Decimal; var CheckShipment: Boolean)
    begin
        CheckShipment := CheckShipment or
            ((SourceType = DATABASE::"Service Line") and (SourceSubType = 1));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceLineVerifyChange(var NewRecordRef: RecordRef; var OldRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceLineDelete(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceLineVerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Request", 'OnShowSourceDocumentCard', '', false, false)]
    local procedure OnShowSourceDocumentCard(var WarehouseRequest: Record "Warehouse Request")
    var
        ServiceHeader: Record "Service Header";
    begin
        case WarehouseRequest."Source Document" of
            "Warehouse Request Source Document"::"Service Order":
                begin
                    ServiceHeader.Get(WarehouseRequest."Source Subtype", WarehouseRequest."Source No.");
                    PAGE.Run(PAGE::"Service Order", ServiceHeader);
                end;
        end;
    end;

    procedure ServiceHeaderVerifyChange(var NewServiceHeader: Record "Service Header"; var OldServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        if NewServiceHeader."Shipping Advice" = OldServiceHeader."Shipping Advice" then
            exit;

        ServiceLine.Reset();
        ServiceLine.SetRange("Document Type", OldServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", OldServiceHeader."No.");
        if ServiceLine.Find('-') then
            repeat
                WhseValidateSourceHeader.ChangeWarehouseLines(
                    DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.", 0,
                    NewServiceHeader."Shipping Advice");
            until ServiceLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Source Filter", 'OnSetFiltersOnSourceTables', '', false, false)]
    local procedure OnSetFiltersOnSourceTables(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var GetSourceDocuments: Report "Get Source Documents"; var WarehouseRequest: Record "Warehouse Request")
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        ServiceHeader.SetFilter("Customer No.", WarehouseSourceFilter."Customer No. Filter");

        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetFilter("No.", WarehouseSourceFilter."Item No. Filter");
        ServiceLine.SetFilter("Variant Code", WarehouseSourceFilter."Variant Code Filter");
        ServiceLine.SetFilter("Unit of Measure Code", WarehouseSourceFilter."Unit of Measure Filter");
        ServiceLine.SetFilter("Planned Delivery Date", WarehouseSourceFilter."Planned Delivery Date");
        ServiceLine.SetFilter("Shipping Agent Code", WarehouseSourceFilter."Shipping Agent Code Filter");
        ServiceLine.SetFilter("Shipping Agent Service Code", WarehouseSourceFilter."Shipping Agent Service Filter");

        OnSetFiltersOnSourceTablesOnBeforeSetServiceTableView(WarehouseSourceFilter, WarehouseRequest, ServiceHeader, ServiceLine);
        GetSourceDocuments.SetTableView(ServiceHeader);
        GetSourceDocuments.SetTableView(ServiceLine);
    end;

    procedure FromServiceLine2ShptLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceLine: Record "Service Line"): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceHeader: Record "Service Header";
        WhseCreateSourceDocument: Codeunit "Whse.-Create Source Document";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
#if not CLEAN23
        WhseCreateSourceDocument.RunOnBeforeFromService2ShptLine(WarehouseShipmentHeader, ServiceLine, Result, IsHandled);
#endif
        OnBeforeFromService2ShptLine(WarehouseShipmentHeader, ServiceLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        OnBeforeFromService2ShptLineOnAfterGetServiceHeader(ServiceHeader, WarehouseShipmentHeader);

        WarehouseShipmentLine.InitNewLine(WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.SetSource(DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.");
        ServiceLine.TestField("Unit of Measure Code");
        WarehouseShipmentLine.SetItemData(
            ServiceLine."No.", ServiceLine.Description, ServiceLine."Description 2", ServiceLine."Location Code",
            ServiceLine."Variant Code", ServiceLine."Unit of Measure Code", ServiceLine."Qty. per Unit of Measure",
            ServiceLine."Qty. Rounding Precision", ServiceLine."Qty. Rounding Precision (Base)");
#if not CLEAN23
        WhseCreateSourceDocument.RunOnFromServiceLine2ShptLineOnAfterInitNewLine(WarehouseShipmentLine, WarehouseShipmentHeader, ServiceLine);
#endif
        OnFromServiceLine2ShptLineOnAfterInitNewLine(WarehouseShipmentLine, WarehouseShipmentHeader, ServiceLine);
        WhseCreateSourceDocument.SetQtysOnShptLine(
            WarehouseShipmentLine, Abs(ServiceLine."Outstanding Quantity"), Abs(ServiceLine."Outstanding Qty. (Base)"));
        if ServiceLine."Document Type" = ServiceLine."Document Type"::Order then
            WarehouseShipmentLine."Due Date" := ServiceLine.GetDueDate();
        if WarehouseShipmentHeader."Shipment Date" = 0D then
            WarehouseShipmentLine."Shipment Date" := ServiceLine.GetShipmentDate()
        else
            WarehouseShipmentLine."Shipment Date" := WarehouseShipmentHeader."Shipment Date";
        WarehouseShipmentLine."Destination Type" := WarehouseShipmentLine."Destination Type"::Customer;
        WarehouseShipmentLine."Destination No." := ServiceLine."Bill-to Customer No.";
        WarehouseShipmentLine."Shipping Advice" := ServiceHeader."Shipping Advice";
        if WarehouseShipmentLine."Location Code" = WarehouseShipmentHeader."Location Code" then
            WarehouseShipmentLine."Bin Code" := WarehouseShipmentHeader."Bin Code";
        if WarehouseShipmentLine."Bin Code" = '' then
            WarehouseShipmentLine."Bin Code" := ServiceLine."Bin Code";
        WhseCreateSourceDocument.UpdateShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
#if not CLEAN23
        WhseCreateSourceDocument.RunOnFromServiceLine2ShptLineOnBeforeCreateShptLine(WarehouseShipmentLine, WarehouseShipmentHeader, ServiceHeader, ServiceLine);
#endif
        OnFromServiceLine2ShptLineOnBeforeCreateShptLine(WarehouseShipmentLine, WarehouseShipmentHeader, ServiceHeader, ServiceLine);
        WhseCreateSourceDocument.CreateShipmentLine(WarehouseShipmentLine);
#if not CLEAN23
        WhseCreateSourceDocument.RunOnAfterCreateShptLineFromServiceLine(WarehouseShipmentLine, WarehouseShipmentHeader, ServiceLine);
#endif
        OnAfterCreateShptLineFromServiceLine(WarehouseShipmentLine, WarehouseShipmentHeader, ServiceLine);
        exit(not WarehouseShipmentLine.HasErrorOccured());
    end;

    procedure CheckIfFromServiceLine2ShptLine(ServiceLine: Record "Service Line"): Boolean
    begin
        exit(CheckIfFromServiceLine2ShptLine(ServiceLine, "Reservation From Stock"::" "));
    end;

    procedure CheckIfFromServiceLine2ShptLine(ServiceLine: Record "Service Line"; ReservedFromStock: Enum "Reservation From Stock"): Boolean
    begin
        if not ServiceLine.CheckIfServiceLineMeetsReservedFromStockSetting(Abs(ServiceLine."Outstanding Qty. (Base)"), ReservedFromStock) then
            exit(false);

        ServiceLine.CalcFields("Whse. Outstanding Qty. (Base)");
        exit(
          (Abs(ServiceLine."Outstanding Qty. (Base)") > Abs(ServiceLine."Whse. Outstanding Qty. (Base)")) and
          (ServiceLine."Qty. to Consume (Base)" = 0));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateShptLineFromServiceLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromService2ShptLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceLine: Record "Service Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromServiceLine2ShptLineOnAfterInitNewLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromServiceLine2ShptLineOnBeforeCreateShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromService2ShptLineOnAfterGetServiceHeader(ServiceHeader: Record "Service Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFiltersOnSourceTablesOnBeforeSetServiceTableView(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var WarehouseRequest: Record "Warehouse Request"; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;
}