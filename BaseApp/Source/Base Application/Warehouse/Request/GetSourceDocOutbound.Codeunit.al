namespace Microsoft.Warehouse.Request;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Worksheet;

codeunit 5752 "Get Source Doc. Outbound"
{

    trigger OnRun()
    begin
    end;

    var
        GetSourceDocuments: Report "Get Source Documents";

        Text001: Label 'If %1 is %2 in %3 no. %4, then all associated lines where type is %5 must use the same location.';
        Text002: Label 'The warehouse shipment was not created because the Shipping Advice field is set to Complete, and item no. %1 is not available in location code %2.\\You can create the warehouse shipment by either changing the Shipping Advice field to Partial in %3 no. %4 or by manually filling in the warehouse shipment document.';
        Text003: Label 'The warehouse shipment was not created because an open warehouse shipment exists for the Sales Header and Shipping Advice is %1.\\You must add the item(s) as new line(s) to the existing warehouse shipment or change Shipping Advice to Partial.';

    local procedure CreateWhseShipmentHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request") Result: Boolean
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateWhseShipmentHeaderFromWhseRequest(WarehouseRequest, Result, IsHandled, GetSourceDocuments);
        if IsHandled then
            exit(Result);

        if WarehouseRequest.IsEmpty() then
            exit(false);

        Clear(GetSourceDocuments);
        OnCreateWhseShipmentHeaderFromWhseRequestOnAfterClearGetSourceDocuments(WarehouseRequest, GetSourceDocuments);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetTableView(WarehouseRequest);
        GetSourceDocuments.SetHideDialog(true);
        GetSourceDocuments.RunModal();

        GetSourceDocuments.GetLastShptHeader(WhseShptHeader);
        OnAfterCreateWhseShipmentHeaderFromWhseRequest(WarehouseRequest, WhseShptHeader);

        exit(true);
    end;

    procedure GetOutboundDocs(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhseGetSourceFilter: Record "Warehouse Source Filter";
        WhseSourceFilterSelection: Page "Filters to Get Source Docs.";
    begin
        WhseShptHeader.Find();
        WhseSourceFilterSelection.SetOneCreatedShptHeader(WhseShptHeader);
        WhseGetSourceFilter.FilterGroup(2);
        WhseGetSourceFilter.SetRange(Type, WhseGetSourceFilter.Type::Outbound);
        WhseGetSourceFilter.FilterGroup(0);
        WhseSourceFilterSelection.SetTableView(WhseGetSourceFilter);
        WhseSourceFilterSelection.RunModal();

        OnGetOutboundDocsOnBeforeUpdateShipmentHeaderStatus(WhseShptHeader);
        UpdateShipmentHeaderStatus(WhseShptHeader);

        OnAfterGetOutboundDocs(WhseShptHeader);
    end;

    procedure GetSingleOutboundDoc(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhseRqst: Record "Warehouse Request";
        IsHandled: Boolean;
    begin
        OnBeforeGetSingleOutboundDoc(WhseShptHeader, IsHandled);
        if IsHandled then
            exit;

        Clear(GetSourceDocuments);
        WhseShptHeader.Find();

        WhseRqst.FilterGroup(2);
        WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
        WhseRqst.SetRange("Location Code", WhseShptHeader."Location Code");
        OnGetSingleOutboundDocOnSetFilterGroupFilters(WhseRqst, WhseShptHeader);
        WhseRqst.FilterGroup(0);
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        WhseRqst.SetRange("Completely Handled", false);
        OnGetSingleOutboundDocOnAfterSetFilters(WhseRqst, WhseShptHeader);

        GetSourceDocForHeader(WhseShptHeader, WhseRqst);

        UpdateShipmentHeaderStatus(WhseShptHeader);

        OnAfterGetSingleOutboundDoc(WhseShptHeader);
    end;

    local procedure GetSourceDocForHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseRequest: Record "Warehouse Request")
    var
        SourceDocSelection: Page "Source Documents";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSourceDocForHeader(WarehouseShipmentHeader, WarehouseRequest, IsHandled);
        if IsHandled then
            exit;

        SourceDocSelection.LookupMode(true);
        SourceDocSelection.SetTableView(WarehouseRequest);
        if SourceDocSelection.RunModal() <> ACTION::LookupOK then
            exit;
        SourceDocSelection.GetResult(WarehouseRequest);

        GetSourceDocuments.SetOneCreatedShptHeader(WarehouseShipmentHeader);
        GetSourceDocuments.SetSkipBlocked(true);
        GetSourceDocuments.UseRequestPage(false);
        WarehouseRequest.SetRange("Location Code", WarehouseShipmentHeader."Location Code");
        GetSourceDocuments.SetTableView(WarehouseRequest);
        GetSourceDocuments.RunModal();
    end;

    procedure CreateFromSalesOrder(SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateFromSalesOrder(SalesHeader, IsHandled);
        if not IsHandled then
            ShowResult(CreateFromSalesOrderHideDialog(SalesHeader));
    end;

    procedure CreateFromSalesOrderHideDialog(SalesHeader: Record "Sales Header"): Boolean
    var
        WhseRqst: Record "Warehouse Request";
    begin
        if not SalesHeader.IsApprovedForPosting() then
            exit(false);

        FindWarehouseRequestForSalesOrder(WhseRqst, SalesHeader);
        exit(CreateWhseShipmentHeaderFromWhseRequest(WhseRqst));
    end;

    procedure CreateFromPurchaseReturnOrder(PurchHeader: Record "Purchase Header")
    begin
        OnBeforeCreateFromPurchaseReturnOrder(PurchHeader);
        ShowResult(CreateFromPurchReturnOrderHideDialog(PurchHeader));
    end;

    procedure CreateFromPurchReturnOrderHideDialog(PurchHeader: Record "Purchase Header"): Boolean
    var
        WhseRqst: Record "Warehouse Request";
    begin
        FindWarehouseRequestForPurchReturnOrder(WhseRqst, PurchHeader);
        exit(CreateWhseShipmentHeaderFromWhseRequest(WhseRqst));
    end;

    procedure CreateFromOutbndTransferOrder(TransHeader: Record "Transfer Header")
    begin
        OnBeforeCreateFromOutbndTransferOrder(TransHeader);
        ShowResult(CreateFromOutbndTransferOrderHideDialog(TransHeader));
    end;

    procedure CreateFromOutbndTransferOrderHideDialog(TransHeader: Record "Transfer Header"): Boolean
    var
        WhseRqst: Record "Warehouse Request";
    begin
        FindWarehouseRequestForOutbndTransferOrder(WhseRqst, TransHeader);
        exit(CreateWhseShipmentHeaderFromWhseRequest(WhseRqst));
    end;

    procedure CreateFromServiceOrder(ServiceHeader: Record "Service Header")
    begin
        OnBeforeCreateFromServiceOrder(ServiceHeader);
        ShowResult(CreateFromServiceOrderHideDialog(ServiceHeader));
    end;

    procedure CreateFromServiceOrderHideDialog(ServiceHeader: Record "Service Header"): Boolean
    var
        WhseRqst: Record "Warehouse Request";
    begin
        FindWarehouseRequestForServiceOrder(WhseRqst, ServiceHeader);
        exit(CreateWhseShipmentHeaderFromWhseRequest(WhseRqst));
    end;

    procedure GetSingleWhsePickDoc(CurrentWhseWkshTemplate: Code[10]; CurrentWhseWkshName: Code[10]; LocationCode: Code[10])
    var
        PickWkshName: Record "Whse. Worksheet Name";
        WhsePickRqst: Record "Whse. Pick Request";
        GetWhseSourceDocuments: Report "Get Outbound Source Documents";
        WhsePickDocSelection: Page "Pick Selection";
    begin
        PickWkshName.Get(CurrentWhseWkshTemplate, CurrentWhseWkshName, LocationCode);

        WhsePickRqst.FilterGroup(2);
        WhsePickRqst.SetRange(Status, WhsePickRqst.Status::Released);
        WhsePickRqst.SetRange("Completely Picked", false);
        WhsePickRqst.SetRange("Location Code", LocationCode);
        OnGetSingleWhsePickDocOnWhsePickRqstSetFilters(WhsePickRqst, CurrentWhseWkshTemplate, CurrentWhseWkshName, LocationCode);
        WhsePickRqst.FilterGroup(0);

        WhsePickDocSelection.LookupMode(true);
        WhsePickDocSelection.SetTableView(WhsePickRqst);
        if WhsePickDocSelection.RunModal() <> ACTION::LookupOK then
            exit;
        WhsePickDocSelection.GetResult(WhsePickRqst);

        GetWhseSourceDocuments.SetPickWkshName(
          CurrentWhseWkshTemplate, CurrentWhseWkshName, LocationCode);
        GetWhseSourceDocuments.UseRequestPage(false);
        GetWhseSourceDocuments.SetTableView(WhsePickRqst);
        GetWhseSourceDocuments.RunModal();
    end;

    procedure CheckSalesHeader(SalesHeader: Record "Sales Header"; ShowError: Boolean) Result: Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        OnBeforeCheckSalesHeader(SalesHeader, ShowError);

        if SalesHeader."Shipping Advice" = SalesHeader."Shipping Advice"::Partial then
            exit(false);

        SalesLine.SetCurrentKey("Document Type", Type, "No.", "Variant Code");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        OnCheckSalesHeaderOnAfterSetLineFilters(SalesLine, SalesHeader);
        CheckSalesHeaderMarkSalesLines(SalesHeader, SalesLine);

        exit(CheckSalesLines(SalesHeader, SalesLine, ShowError));
    end;

    local procedure CheckSalesLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ShowError: Boolean) Result: Boolean
    var
        CurrItemVariant: Record "Item Variant";
        SalesOrder: Page "Sales Order";
        QtyOutstandingBase: Decimal;
        RecordNo: Integer;
        TotalNoOfRecords: Integer;
        LocationCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesLines(SalesHeader, SalesLine, ShowError, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if SalesLine.FindSet() then begin
            LocationCode := SalesLine."Location Code";
            SetItemVariant(CurrItemVariant, SalesLine."No.", SalesLine."Variant Code");
            TotalNoOfRecords := SalesLine.Count();
            repeat
                RecordNo += 1;

                if SalesLine."Location Code" <> LocationCode then begin
                    if ShowError then
                        Error(Text001, SalesHeader.FieldCaption(SalesHeader."Shipping Advice"), SalesHeader."Shipping Advice",
                          SalesOrder.Caption, SalesHeader."No.", SalesLine.Type);
                    exit(true);
                end;

                if EqualItemVariant(CurrItemVariant, SalesLine."No.", SalesLine."Variant Code") then
                    QtyOutstandingBase += SalesLine."Outstanding Qty. (Base)"
                else begin
                    if CheckSalesHeaderOnBeforeCheckAvailability(SalesHeader, SalesLine, ShowError, Result) then
                        exit(Result);

                    if CheckAvailability(
                         CurrItemVariant, QtyOutstandingBase, SalesLine."Location Code",
                         SalesOrder.Caption(), Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", ShowError)
                    then
                        exit(true);
                    SetItemVariant(CurrItemVariant, SalesLine."No.", SalesLine."Variant Code");
                    if CheckSalesHeaderOnAfterSetItemVariant(Result) then
                        exit(Result);
                    QtyOutstandingBase := SalesLine."Outstanding Qty. (Base)";
                end;
                if RecordNo = TotalNoOfRecords then begin
                    // last record
                    if CheckSalesHeaderOnBeforeCheckAvailability(SalesHeader, SalesLine, ShowError, Result) then
                        exit(Result);

                    if CheckAvailability(
                         CurrItemVariant, QtyOutstandingBase, SalesLine."Location Code",
                         SalesOrder.Caption(), Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", ShowError)
                    then
                        exit(true);
                end;
            until SalesLine.Next() = 0;
            // sorted by item
        end;
    end;

    local procedure CheckSalesHeaderMarkSalesLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesHeaderMarkSalesLines(SalesLine, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if SalesLine.FindSet() then
            repeat
                if SalesLine.IsInventoriableItem() then
                    SalesLine.Mark(true);
            until SalesLine.Next() = 0;
        SalesLine.MarkedOnly(true);
    end;

    local procedure CheckSalesHeaderOnAfterSetItemVariant(var Result: Boolean) IsHandled: Boolean
    begin
        OnCheckSalesHeaderOnAfterSetItemVariant(Result, IsHandled);
    end;

    local procedure CheckSalesHeaderOnBeforeCheckAvailability(SalesHeader: Record "Sales Header"; SalesLine: record "Sales Line"; ShowError: Boolean; var Result: Boolean) IsHandled: Boolean
    begin
        OnCheckSalesHeaderOnBeforeCheckAvailability(SalesHeader, SalesLine, ShowError, Result, IsHandled);
    end;

    procedure CheckTransferHeader(TransferHeader: Record "Transfer Header"; ShowError: Boolean): Boolean
    var
        TransferLine: Record "Transfer Line";
        CurrItemVariant: Record "Item Variant";
        TransferOrder: Page "Transfer Order";
        QtyOutstandingBase: Decimal;
        RecordNo: Integer;
        TotalNoOfRecords: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTransferHeader(TransferHeader, ShowError, IsHandled);
        if IsHandled then
            exit;

        if TransferHeader."Shipping Advice" = TransferHeader."Shipping Advice"::Partial then
            exit(false);

        TransferLine.SetCurrentKey("Item No.");
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        OnCheckTransferHeaderOnAfterSetLineFilters(TransferLine, TransferHeader);
        if TransferLine.FindSet() then begin
            SetItemVariant(CurrItemVariant, TransferLine."Item No.", TransferLine."Variant Code");
            TotalNoOfRecords := TransferLine.Count();
            repeat
                RecordNo += 1;
                if EqualItemVariant(CurrItemVariant, TransferLine."Item No.", TransferLine."Variant Code") then
                    QtyOutstandingBase += TransferLine."Outstanding Qty. (Base)"
                else begin
                    if CheckAvailability(
                         CurrItemVariant, QtyOutstandingBase, TransferLine."Transfer-from Code",
                         TransferOrder.Caption(), Database::"Transfer Line", 0, TransferHeader."No.", ShowError)
                    then
                        // outbound
                        exit(true);
                    SetItemVariant(CurrItemVariant, TransferLine."Item No.", TransferLine."Variant Code");
                    QtyOutstandingBase := TransferLine."Outstanding Qty. (Base)";
                end;
                if RecordNo = TotalNoOfRecords then
                    // last record
                    if CheckAvailability(
                         CurrItemVariant, QtyOutstandingBase, TransferLine."Transfer-from Code",
                         TransferOrder.Caption(), Database::"Transfer Line", 0, TransferHeader."No.", ShowError)
                    then
                        // outbound
                        exit(true);
            until TransferLine.Next() = 0;
            // sorted by item
        end;
    end;

    procedure CheckAvailability(CurrItemVariant: Record "Item Variant"; QtyBaseNeeded: Decimal; LocationCode: Code[10]; FormCaption: Text[1024]; SourceType: Integer; SourceSubType: Integer; SourceID: Code[20]; ShowError: Boolean): Boolean
    var
        Item: Record Item;
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        QtyReservedForOrder: Decimal;
        IsHandled: Boolean;
        Result: Boolean;
        NotAvailable: Boolean;
        ErrorMessage: Text;
    begin
        IsHandled := false;
        OnBeforeCheckAvailability(
          CurrItemVariant, QtyBaseNeeded, LocationCode, FormCaption, SourceType, SourceSubType, SourceID, ShowError, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Item.Get(CurrItemVariant."Item No.");
        Item.SetRange("Location Filter", LocationCode);
        Item.SetRange("Variant Filter", CurrItemVariant.Code);
        Item.CalcFields(Inventory, "Reserved Qty. on Inventory");
        // find qty reserved for this order
        ReservEntry.SetSourceFilter(SourceType, SourceSubType, SourceID, -1, true);
        ReservEntry.SetRange("Item No.", CurrItemVariant."Item No.");
        ReservEntry.SetRange("Location Code", LocationCode);
        ReservEntry.SetRange("Variant Code", CurrItemVariant.Code);
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        if ReservEntry.FindSet() then
            repeat
                ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
                QtyReservedForOrder += ReservEntry2."Quantity (Base)";
            until ReservEntry.Next() = 0;

        NotAvailable := Item.Inventory - (Item."Reserved Qty. on Inventory" - QtyReservedForOrder) < QtyBaseNeeded;
        ErrorMessage := StrSubstNo(Text002, CurrItemVariant."Item No.", LocationCode, FormCaption, SourceID);
        if AfterCheckAvailability(NotAvailable, ShowError, ErrorMessage, Result) then
            exit(Result);
    end;

    local procedure AfterCheckAvailability(NotAvailable: Boolean; ShowError: Boolean; ErrorMessage: Text; var Result: Boolean) IsHandled: Boolean;
    begin
        OnAfterCheckAvailability(NotAvailable, ShowError, ErrorMessage, Result, IsHandled);
        if IsHandled then
            exit(true);

        if NotAvailable then begin
            if ShowError then
                Error(ErrorMessage);
            exit(true);
        end;
    end;

    local procedure OpenWarehouseShipmentPage()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenWarehouseShipmentPage(GetSourceDocuments, IsHandled);
        if IsHandled then
            exit;

        GetSourceDocuments.GetLastShptHeader(WarehouseShipmentHeader);
        PAGE.Run(PAGE::"Warehouse Shipment", WarehouseShipmentHeader);
    end;

    local procedure GetRequireShipRqst(var WhseRqst: Record "Warehouse Request")
    var
        Location: Record Location;
        LocationCode: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetRequireShipRqst(WhseRqst, IsHandled);
        if IsHandled then
            exit;

        if WhseRqst.FindSet() then begin
            repeat
                if Location.RequireShipment(WhseRqst."Location Code") then
                    LocationCode += WhseRqst."Location Code" + '|';
            until WhseRqst.Next() = 0;
            if LocationCode <> '' then begin
                LocationCode := CopyStr(LocationCode, 1, StrLen(LocationCode) - 1);
                if LocationCode[1] = '|' then
                    LocationCode := '''''' + LocationCode;
            end;
            WhseRqst.SetFilter("Location Code", LocationCode);
        end;
    end;

    local procedure SetItemVariant(var CurrItemVariant: Record "Item Variant"; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        CurrItemVariant."Item No." := ItemNo;
        CurrItemVariant.Code := VariantCode;
    end;

    local procedure EqualItemVariant(CurrItemVariant: Record "Item Variant"; ItemNo: Code[20]; VariantCode: Code[10]): Boolean
    begin
        exit((CurrItemVariant."Item No." = ItemNo) and (CurrItemVariant.Code = VariantCode));
    end;

    local procedure FindWarehouseRequestForSalesOrder(var WhseRqst: Record "Warehouse Request"; SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField(Status, SalesHeader.Status::Released);
        CheckWhseShipmentConflict(SalesHeader);
        CheckSalesHeader(SalesHeader, true);
        WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
        WhseRqst.SetSourceFilter(Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        OnFindWarehouseRequestForSalesOrderOnAfterWhseRqstSetFilters(WhseRqst, SalesHeader);
        GetRequireShipRqst(WhseRqst);

        OnAfterFindWarehouseRequestForSalesOrder(WhseRqst, SalesHeader);
    end;

    local procedure FindWarehouseRequestForPurchReturnOrder(var WhseRqst: Record "Warehouse Request"; PurchHeader: Record "Purchase Header")
    begin
        PurchHeader.TestField(Status, PurchHeader.Status::Released);
        WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
        WhseRqst.SetSourceFilter(Database::"Purchase Line", PurchHeader."Document Type".AsInteger(), PurchHeader."No.");
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        OnFindWarehouseRequestForPurchReturnOrderOnAfterWhseRqstSetFilters(WhseRqst, PurchHeader);
        GetRequireShipRqst(WhseRqst);

        OnAfterFindWarehouseRequestForPurchReturnOrder(WhseRqst, PurchHeader);
    end;

    local procedure FindWarehouseRequestForOutbndTransferOrder(var WhseRqst: Record "Warehouse Request"; TransHeader: Record "Transfer Header")
    begin
        TransHeader.TestField(Status, TransHeader.Status::Released);
        CheckTransferHeader(TransHeader, true);
        WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
        WhseRqst.SetSourceFilter(Database::"Transfer Line", 0, TransHeader."No.");
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        OnFindWarehouseRequestForOutbndTransferOrderOnAfterWhseRqstSetFilters(WhseRqst, TransHeader);
        GetRequireShipRqst(WhseRqst);

        OnAfterFindWarehouseRequestForOutbndTransferOrder(WhseRqst, TransHeader);
    end;

    local procedure FindWarehouseRequestForServiceOrder(var WhseRqst: Record "Warehouse Request"; ServiceHeader: Record "Service Header")
    begin
        ServiceHeader.TestField("Release Status", ServiceHeader."Release Status"::"Released to Ship");
        WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
        WhseRqst.SetSourceFilter(Database::"Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.");
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        OnFindWarehouseRequestForServiceOrderOnAfterSetWhseRqstFilters(WhseRqst, ServiceHeader);
        GetRequireShipRqst(WhseRqst);

        OnAfterFindWarehouseRequestForServiceOrder(WhseRqst, ServiceHeader);
    end;

    local procedure CheckWhseShipmentConflict(SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseShipmentConflict(SalesHeader, IsHandled);
        if not IsHandled then
            if SalesHeader.WhseShipmentConflict(SalesHeader."Document Type", SalesHeader."No.", SalesHeader."Shipping Advice") then
                Error(Text003, Format(SalesHeader."Shipping Advice"));
    end;

    local procedure UpdateShipmentHeaderStatus(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        WarehouseShipmentHeader.Find();
        WarehouseShipmentHeader."Document Status" := WarehouseShipmentHeader.GetDocumentStatus(0);
        WarehouseShipmentHeader.Modify();
    end;

    local procedure ShowResult(WhseShipmentCreated: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowResult(WhseShipmentCreated, IsHandled, GetSourceDocuments);
        if IsHandled then
            exit;

        GetSourceDocuments.ShowShipmentDialog();
        if WhseShipmentCreated then
            OpenWarehouseShipmentPage();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckAvailability(NotAvailable: Boolean; ShowError: Boolean; ErrorMessage: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseShipmentHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForSalesOrder(var WarehouseRequest: Record "Warehouse Request"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForPurchReturnOrder(var WarehouseRequest: Record "Warehouse Request"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForOutbndTransferOrder(var WarehouseRequest: Record "Warehouse Request"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForServiceOrder(var WarehouseRequest: Record "Warehouse Request"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetOutboundDocs(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSingleOutboundDoc(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAvailability(CurrItemVariant: Record "Item Variant"; QtyBaseNeeded: Decimal; LocationCode: Code[10]; FormCaption: Text[1024]; SourceType: Integer; SourceSubType: Integer; SourceID: Code[20]; ShowError: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesHeader(var SalesHeader: Record "Sales Header"; var ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ShowError: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransferHeader(var TransferHeader: Record "Transfer Header"; var ShowError: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromPurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromOutbndTransferOrder(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromSalesOrder(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromServiceOrder(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseShipmentHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var Rusult: Boolean; var IsHandled: Boolean; var GetSourceDocuments: Report "Get Source Documents")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseShipmentHeaderFromWhseRequestOnAfterClearGetSourceDocuments(var WarehouseRequest: Record "Warehouse Request"; var GetSourceDocuments: Report "Get Source Documents")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenWarehouseShipmentPage(var GetSourceDocuments: Report "Get Source Documents"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesHeaderMarkSalesLines(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceDocForHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseRequest: Record "Warehouse Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRequireShipRqst(var WarehouseRequest: Record "Warehouse Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesHeaderOnAfterSetLineFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesHeaderOnAfterSetItemVariant(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesHeaderOnBeforeCheckAvailability(SalesHeader: Record "Sales Header"; SalesLine: record "Sales Line"; ShowError: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckTransferHeaderOnAfterSetLineFilters(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSingleOutboundDoc(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowResult(WhseShipmentCreated: Boolean; var IsHandled: Boolean; var GetSourceDocuments: Report "Get Source Documents");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindWarehouseRequestForPurchReturnOrderOnAfterWhseRqstSetFilters(var WhseRqst: Record "Warehouse Request"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindWarehouseRequestForSalesOrderOnAfterWhseRqstSetFilters(var WhseRqst: Record "Warehouse Request"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindWarehouseRequestForOutbndTransferOrderOnAfterWhseRqstSetFilters(var WhseRqst: Record "Warehouse Request"; var TransferOrder: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindWarehouseRequestForServiceOrderOnAfterSetWhseRqstFilters(var WarehouseRequest: Record "Warehouse Request"; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSingleWhsePickDocOnWhsePickRqstSetFilters(var WhsePickRequest: Record "Whse. Pick Request"; CurrentWhseWkshTemplate: Code[10]; CurrentWhseWkshName: Code[10]; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSingleOutboundDocOnSetFilterGroupFilters(var WhseRqst: Record "Warehouse Request"; WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSingleOutboundDocOnAfterSetFilters(var WhseRqst: Record "Warehouse Request"; WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseShipmentConflict(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetOutboundDocsOnBeforeUpdateShipmentHeaderStatus(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;
}

