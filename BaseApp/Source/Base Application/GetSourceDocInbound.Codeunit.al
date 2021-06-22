codeunit 5751 "Get Source Doc. Inbound"
{

    trigger OnRun()
    begin
    end;

    var
        GetSourceDocuments: Report "Get Source Documents";

    local procedure CreateWhseReceiptHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"): Boolean
    var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        if WarehouseRequest.IsEmpty then
            exit(false);

        Clear(GetSourceDocuments);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetTableView(WarehouseRequest);
        GetSourceDocuments.SetHideDialog(true);
        GetSourceDocuments.RunModal;

        OnBeforeGetSourceDocumentsRun(GetSourceDocuments, WarehouseRequest);
        GetSourceDocuments.GetLastReceiptHeader(WhseReceiptHeader);
        OnAfterCreateWhseReceiptHeaderFromWhseRequest(WhseReceiptHeader);
        exit(true);
    end;

    procedure GetInboundDocs(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WhseGetSourceFilterRec: Record "Warehouse Source Filter";
        WhseSourceFilterSelection: Page "Filters to Get Source Docs.";
    begin
        WhseReceiptHeader.Find;
        WhseSourceFilterSelection.SetOneCreatedReceiptHeader(WhseReceiptHeader);
        WhseGetSourceFilterRec.FilterGroup(2);
        WhseGetSourceFilterRec.SetRange(Type, WhseGetSourceFilterRec.Type::Inbound);
        WhseGetSourceFilterRec.FilterGroup(0);
        WhseSourceFilterSelection.SetTableView(WhseGetSourceFilterRec);
        WhseSourceFilterSelection.RunModal;

        UpdateReceiptHeaderStatus(WhseReceiptHeader);

        OnAfterGetInboundDocs(WhseReceiptHeader);
    end;

    procedure GetSingleInboundDoc(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WhseRqst: Record "Warehouse Request";
        SourceDocSelection: Page "Source Documents";
        IsHandled: Boolean;
    begin
        OnBeforeGetSingleInboundDoc(WhseReceiptHeader, IsHandled);
        if IsHandled then
            exit;

        Clear(GetSourceDocuments);
        WhseReceiptHeader.Find;

        WhseRqst.FilterGroup(2);
        WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
        WhseRqst.SetRange("Location Code", WhseReceiptHeader."Location Code");
        WhseRqst.FilterGroup(0);
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        WhseRqst.SetRange("Completely Handled", false);

        SourceDocSelection.LookupMode(true);
        SourceDocSelection.SetTableView(WhseRqst);
        if SourceDocSelection.RunModal <> ACTION::LookupOK then
            exit;
        SourceDocSelection.GetResult(WhseRqst);

        GetSourceDocuments.SetOneCreatedReceiptHeader(WhseReceiptHeader);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetTableView(WhseRqst);
        GetSourceDocuments.RunModal;

        UpdateReceiptHeaderStatus(WhseReceiptHeader);

        OnAfterGetSingleInboundDoc(WhseReceiptHeader);
    end;

    procedure CreateFromPurchOrder(PurchHeader: Record "Purchase Header")
    begin
        OnBeforeCreateFromPurchOrder(PurchHeader);
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
    begin
        OnBeforeCreateFromSalesReturnOrder(SalesHeader);
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
    begin
        OnBeforeCreateFromInbndTransferOrder(TransHeader);
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
        if WhsePutAwayDocSelection.RunModal <> ACTION::LookupOK then
            exit;

        WhsePutAwayDocSelection.GetResult(WhsePutAwayRqst);

        GetWhseSourceDocuments.SetWhseWkshName(
          CurrentWkshTemplateName, CurrentWkshName, LocationCode);

        GetWhseSourceDocuments.UseRequestPage(false);
        GetWhseSourceDocuments.SetTableView(WhsePutAwayRqst);
        GetWhseSourceDocuments.RunModal;
    end;

    local procedure GetRequireReceiveRqst(var WhseRqst: Record "Warehouse Request")
    var
        Location: Record Location;
        LocationCode: Text;
    begin
        if WhseRqst.FindSet then begin
            repeat
                if Location.RequireReceive(WhseRqst."Location Code") then
                    LocationCode += WhseRqst."Location Code" + '|';
            until WhseRqst.Next = 0;
            if LocationCode <> '' then begin
                LocationCode := CopyStr(LocationCode, 1, StrLen(LocationCode) - 1);
                if LocationCode[1] = '|' then
                    LocationCode := '''''' + LocationCode;
            end;
            WhseRqst.SetFilter("Location Code", LocationCode);
        end;
    end;

    local procedure FindWarehouseRequestForPurchaseOrder(var WhseRqst: Record "Warehouse Request"; PurchHeader: Record "Purchase Header")
    begin
        with PurchHeader do begin
            TestField(Status, Status::Released);
            WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
            WhseRqst.SetRange("Source Type", DATABASE::"Purchase Line");
            WhseRqst.SetRange("Source Subtype", "Document Type");
            WhseRqst.SetRange("Source No.", "No.");
            WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
            GetRequireReceiveRqst(WhseRqst);
        end;

        OnAfterFindWarehouseRequestForPurchaseOrder(WhseRqst, PurchHeader);
    end;

    local procedure FindWarehouseRequestForSalesReturnOrder(var WhseRqst: Record "Warehouse Request"; SalesHeader: Record "Sales Header")
    begin
        with SalesHeader do begin
            TestField(Status, Status::Released);
            WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
            WhseRqst.SetRange("Source Type", DATABASE::"Sales Line");
            WhseRqst.SetRange("Source Subtype", "Document Type");
            WhseRqst.SetRange("Source No.", "No.");
            WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
            GetRequireReceiveRqst(WhseRqst);
        end;

        OnAfterFindWarehouseRequestForSalesReturnOrder(WhseRqst, SalesHeader);
    end;

    local procedure FindWarehouseRequestForInbndTransferOrder(var WhseRqst: Record "Warehouse Request"; TransHeader: Record "Transfer Header")
    begin
        with TransHeader do begin
            TestField(Status, Status::Released);
            WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
            WhseRqst.SetRange("Source Type", DATABASE::"Transfer Line");
            WhseRqst.SetRange("Source Subtype", 1);
            WhseRqst.SetRange("Source No.", "No.");
            WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
            GetRequireReceiveRqst(WhseRqst);
        end;

        OnAfterFindWarehouseRequestForInbndTransferOrder(WhseRqst, TransHeader);
    end;

    local procedure OpenWarehouseReceiptPage()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        GetSourceDocuments.GetLastReceiptHeader(WarehouseReceiptHeader);
        PAGE.Run(PAGE::"Warehouse Receipt", WarehouseReceiptHeader);
    end;

    local procedure UpdateReceiptHeaderStatus(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        with WarehouseReceiptHeader do begin
            Find;
            "Document Status" := GetHeaderStatus(0);
            Modify;
        end;
    end;

    local procedure ShowDialog(WhseReceiptCreated: Boolean)
    begin
        GetSourceDocuments.ShowReceiptDialog;
        if WhseReceiptCreated then
            OpenWarehouseReceiptPage;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseReceiptHeaderFromWhseRequest(var WhseReceiptHeader: Record "Warehouse Receipt Header");
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
    local procedure OnAfterGetInboundDocs(WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSingleInboundDoc(WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromPurchOrder(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromSalesReturnOrder(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromInbndTransferOrder(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSingleInboundDoc(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceDocumentsRun(var GetSourceDocuments: Report "Get Source Documents"; WarehouseRequest: Record "Warehouse Request")
    begin
    end;
}

