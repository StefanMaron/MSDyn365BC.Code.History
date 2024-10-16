namespace Microsoft.Warehouse.Request;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using System.Text;
using System.Reflection;

codeunit 5751 "Get Source Doc. Inbound"
{

    trigger OnRun()
    begin
    end;

    var
        GetSourceDocuments: Report "Get Source Documents";
        ServVendDocNo: Code[20];

    procedure SetServVendDocNo(NewServVendDocNo: Code[20]);
    begin
        ServVendDocNo := NewServVendDocNo;
    end;

    local procedure CreateWhseReceiptHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request") Result: Boolean
    var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateWhseReceiptHeaderFromWhseRequest(GetSourceDocuments, WarehouseRequest, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if WarehouseRequest.IsEmpty() then
            exit(false);

        Clear(GetSourceDocuments);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetTableView(WarehouseRequest);
        GetSourceDocuments.SetHideDialog(true);
        OnBeforeGetSourceDocumentsRun(GetSourceDocuments, WarehouseRequest, ServVendDocNo);
        GetSourceDocuments.RunModal();

        GetSourceDocuments.GetLastReceiptHeader(WhseReceiptHeader);
        OnAfterCreateWhseReceiptHeaderFromWhseRequest(WhseReceiptHeader, WarehouseRequest, GetSourceDocuments);
        exit(true);
    end;

    procedure GetInboundDocs(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WhseGetSourceFilter: Record "Warehouse Source Filter";
        WhseSourceFilterSelection: Page "Filters to Get Source Docs.";
    begin
        WhseReceiptHeader.Find();
        WhseSourceFilterSelection.SetOneCreatedReceiptHeader(WhseReceiptHeader);
        WhseGetSourceFilter.FilterGroup(2);
        WhseGetSourceFilter.SetRange(Type, WhseGetSourceFilter.Type::Inbound);
        WhseGetSourceFilter.FilterGroup(0);
        WhseSourceFilterSelection.SetTableView(WhseGetSourceFilter);
        WhseSourceFilterSelection.RunModal();

        OnGetInboundDocsBeforeUpdateReceiptHeaderStatus(WhseReceiptHeader);
        UpdateReceiptHeaderStatus(WhseReceiptHeader);

        OnAfterGetInboundDocs(WhseReceiptHeader);
    end;

    procedure GetSingleInboundDoc(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WhseRqst: Record "Warehouse Request";
        IsHandled: Boolean;
    begin
        OnBeforeGetSingleInboundDoc(WhseReceiptHeader, IsHandled);
        if IsHandled then
            exit;

        Clear(GetSourceDocuments);
        WhseReceiptHeader.Find();

        SetWarehouseRequestFilters(WhseRqst, WhseReceiptHeader);

        GetSourceDocForHeader(WhseReceiptHeader, WhseRqst);

        UpdateReceiptHeaderStatus(WhseReceiptHeader);

        OnAfterGetSingleInboundDoc(WhseReceiptHeader);
    end;

    local procedure GetSourceDocForHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseRequest: Record "Warehouse Request")
    var
        SourceDocSelection: Page "Source Documents";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSourceDocForHeader(WarehouseReceiptHeader, WarehouseRequest, IsHandled, GetSourceDocuments);
        if IsHandled then
            exit;

        SourceDocSelection.LookupMode(true);
        SourceDocSelection.SetTableView(WarehouseRequest);
        if SourceDocSelection.RunModal() <> ACTION::LookupOK then
            exit;
        SourceDocSelection.GetResult(WarehouseRequest);

        GetSourceDocuments.SetOneCreatedReceiptHeader(WarehouseReceiptHeader);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetTableView(WarehouseRequest);
        GetSourceDocuments.RunModal();
    end;

    local procedure SetWarehouseRequestFilters(var WhseRqst: Record "Warehouse Request"; WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        WhseRqst.FilterGroup(2);
        WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
        WhseRqst.SetRange("Location Code", WhseReceiptHeader."Location Code");
        WhseRqst.FilterGroup(0);
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        WhseRqst.SetRange("Completely Handled", false);

        OnAfterSetWarehouseRequestFilters(WhseRqst, WhseReceiptHeader);
    end;

    procedure CreateFromPurchOrder(PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateFromPurchOrder(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        ShowDialog(CreateFromPurchOrderHideDialog(PurchHeader));
    end;

    procedure CreateFromPurchOrderHideDialog(PurchHeader: Record "Purchase Header"): Boolean
    var
        WhseRqst: Record "Warehouse Request";
    begin
        FindWarehouseRequestForPurchaseOrder(WhseRqst, PurchHeader);
        exit(CreateWhseReceiptHeaderFromWhseRequest(WhseRqst));
    end;

    procedure CreateFromSalesReturnOrder(SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateFromSalesReturnOrder(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        ShowDialog(CreateFromSalesReturnOrderHideDialog(SalesHeader));
    end;

    procedure CreateFromSalesReturnOrderHideDialog(SalesHeader: Record "Sales Header"): Boolean
    var
        WhseRqst: Record "Warehouse Request";
    begin
        FindWarehouseRequestForSalesReturnOrder(WhseRqst, SalesHeader);
        exit(CreateWhseReceiptHeaderFromWhseRequest(WhseRqst));
    end;

    procedure CreateFromInbndTransferOrder(TransHeader: Record "Transfer Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateFromInbndTransferOrder(TransHeader, IsHandled);
        if IsHandled then
            exit;

        ShowDialog(CreateFromInbndTransferOrderHideDialog(TransHeader));
    end;

    procedure CreateFromInbndTransferOrderHideDialog(TransHeader: Record "Transfer Header"): Boolean
    var
        WhseRqst: Record "Warehouse Request";
    begin
        FindWarehouseRequestForInbndTransferOrder(WhseRqst, TransHeader);
        exit(CreateWhseReceiptHeaderFromWhseRequest(WhseRqst));
    end;

    procedure GetSingleWhsePutAwayDoc(CurrentWkshTemplateName: Code[10]; CurrentWkshName: Code[10]; LocationCode: Code[10])
    var
        WhsePutAwayRqst: Record "Whse. Put-away Request";
        GetWhseSourceDocuments: Report "Get Inbound Source Documents";
        WhsePutAwayDocSelection: Page "Put-away Selection";
    begin
        WhsePutAwayRqst.FilterGroup(2);
        WhsePutAwayRqst.SetRange("Completely Put Away", false);
        WhsePutAwayRqst.SetRange("Location Code", LocationCode);
        WhsePutAwayRqst.FilterGroup(0);

        WhsePutAwayDocSelection.LookupMode(true);
        WhsePutAwayDocSelection.SetTableView(WhsePutAwayRqst);
        if WhsePutAwayDocSelection.RunModal() <> ACTION::LookupOK then
            exit;

        WhsePutAwayDocSelection.GetResult(WhsePutAwayRqst);

        OnGetSingleWhsePutAwayDocOnAfterGetResultWhsePutAwayRqst(WhsePutAwayRqst);

        GetWhseSourceDocuments.SetWhseWkshName(
          CurrentWkshTemplateName, CurrentWkshName, LocationCode);

        GetWhseSourceDocuments.UseRequestPage(false);
        GetWhseSourceDocuments.SetTableView(WhsePutAwayRqst);
        GetWhseSourceDocuments.RunModal();
    end;

    procedure GetRequireReceiveRqst(var WhseRqst: Record "Warehouse Request")
    var
        Location: Record Location;
        LocationList: List of [Code[20]];
        LocationCodeFilter: Text;
        IsHandled: Boolean;
        BlankLocationExists: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetRequireReceiveRqst(WhseRqst, IsHandled);
        if IsHandled then
            exit;

        if WhseRqst.FindSet() then begin
            repeat
                if Location.RequireReceive(WhseRqst."Location Code") then begin
                    if WhseRqst."Location Code" = '' then
                        BlankLocationExists := true;
                    if not LocationList.Contains(WhseRqst."Location Code") then
                        LocationList.Add(WhseRqst."Location Code");
                end;
            until WhseRqst.Next() = 0;

            GenerateLocationCodeFilter(LocationList, LocationCodeFilter, BlankLocationExists);

            WhseRqst.SetFilter("Location Code", LocationCodeFilter);
        end;
    end;

    local procedure FindWarehouseRequestForPurchaseOrder(var WhseRqst: Record "Warehouse Request"; PurchHeader: Record "Purchase Header")
    begin
        PurchHeader.TestField(Status, PurchHeader.Status::Released);
        WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
        WhseRqst.SetRange("Source Type", Database::"Purchase Line");
        WhseRqst.SetRange("Source Subtype", PurchHeader."Document Type");
        WhseRqst.SetRange("Source No.", PurchHeader."No.");
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        GetRequireReceiveRqst(WhseRqst);

        OnAfterFindWarehouseRequestForPurchaseOrder(WhseRqst, PurchHeader);
    end;

    local procedure FindWarehouseRequestForSalesReturnOrder(var WhseRqst: Record "Warehouse Request"; SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField(Status, SalesHeader.Status::Released);
        WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
        WhseRqst.SetRange("Source Type", Database::"Sales Line");
        WhseRqst.SetRange("Source Subtype", SalesHeader."Document Type");
        WhseRqst.SetRange("Source No.", SalesHeader."No.");
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        GetRequireReceiveRqst(WhseRqst);

        OnAfterFindWarehouseRequestForSalesReturnOrder(WhseRqst, SalesHeader);
    end;

    local procedure FindWarehouseRequestForInbndTransferOrder(var WhseRqst: Record "Warehouse Request"; TransHeader: Record "Transfer Header")
    begin
        TransHeader.TestField(Status, TransHeader.Status::Released);
        WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
        WhseRqst.SetRange("Source Type", Database::"Transfer Line");
        WhseRqst.SetRange("Source Subtype", 1);
        WhseRqst.SetRange("Source No.", TransHeader."No.");
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        GetRequireReceiveRqst(WhseRqst);

        OnAfterFindWarehouseRequestForInbndTransferOrder(WhseRqst, TransHeader);
    end;

    local procedure OpenWarehouseReceiptPage()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        GetSourceDocuments.GetLastReceiptHeader(WarehouseReceiptHeader);
        IsHandled := false;
        OnOpenWarehouseReceiptPage(WarehouseReceiptHeader, ServVendDocNo, IsHandled, GetSourceDocuments);
        if not IsHandled then begin            
            WMSManagement.CheckUserIsWhseEmployeeForLocation(WarehouseReceiptHeader."Location Code", true);
            PAGE.Run(PAGE::"Warehouse Receipt", WarehouseReceiptHeader);
        end
    end;

    local procedure UpdateReceiptHeaderStatus(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        WarehouseReceiptHeader.Find();
        WarehouseReceiptHeader."Document Status" := WarehouseReceiptHeader.GetHeaderStatus(0);
        WarehouseReceiptHeader.Modify();
    end;

    local procedure ShowDialog(WhseReceiptCreated: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDialog(GetSourceDocuments, WhseReceiptCreated, IsHandled);
        if IsHandled then
            exit;

        GetSourceDocuments.ShowReceiptDialog();
        if WhseReceiptCreated then
            OpenWarehouseReceiptPage();
    end;

    local procedure GenerateLocationCodeFilter(LocationList: List of [Code[20]]; var LocationCodeFilter: Text; BlankLocationExists: Boolean)
    var
        TypeHelper: Codeunit "Type Helper";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        LocationFilter: Code[20];
        WarehouseLocationAddToFilter: TextBuilder;
    begin
        if LocationList.Count() >= (TypeHelper.GetMaxNumberOfParametersInSQLQuery() - 100) then
            exit;

        if LocationList.Count() = 0 then
            exit;

        foreach LocationFilter in LocationList do begin
            if WarehouseLocationAddToFilter.Length() > 0 then
                WarehouseLocationAddToFilter.Append('|');
            WarehouseLocationAddToFilter.Append(SelectionFilterManagement.AddQuotes(LocationFilter));
        end;

        LocationCodeFilter := WarehouseLocationAddToFilter.ToText();

        if BlankLocationExists then
            if LocationCodeFilter = '' then
                LocationCodeFilter := ''''''
            else
                LocationCodeFilter += '|' + '''''';
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseReceiptHeaderFromWhseRequest(var WhseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseRequest: Record "Warehouse Request"; var GetSourceDocuments: Report "Get Source Documents");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForPurchaseOrder(var WarehouseRequest: Record "Warehouse Request"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForSalesReturnOrder(var WarehouseRequest: Record "Warehouse Request"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForInbndTransferOrder(var WarehouseRequest: Record "Warehouse Request"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetInboundDocs(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSingleInboundDoc(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWarehouseRequestFilters(var WarehouseRequest: Record "Warehouse Request"; WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromPurchOrder(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromSalesReturnOrder(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromInbndTransferOrder(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseReceiptHeaderFromWhseRequest(var GetSourceDocuments: Report "Get Source Documents"; var WarehouseRequest: Record "Warehouse Request"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRequireReceiveRqst(var WarehouseRequest: Record "Warehouse Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceDocForHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseRequest: Record "Warehouse Request"; var IsHandled: Boolean; var GetSourceDocuments: Report "Get Source Documents")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSingleInboundDoc(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDialog(var GetSourceDocuments: Report "Get Source Documents"; var WhseReceiptCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceDocumentsRun(var GetSourceDocuments: Report "Get Source Documents"; var WarehouseRequest: Record "Warehouse Request"; ServVendDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSingleWhsePutAwayDocOnAfterGetResultWhsePutAwayRqst(var WhsePutAwayRequest: Record "Whse. Put-away Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenWarehouseReceiptPage(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; ServVendDocNo: Code[20]; var IsHandled: Boolean; var GetSourceDocuments: Report "Get Source Documents")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetInboundDocsBeforeUpdateReceiptHeaderStatus(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;
}

