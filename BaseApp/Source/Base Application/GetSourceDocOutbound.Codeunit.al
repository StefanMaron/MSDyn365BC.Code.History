codeunit 5752 "Get Source Doc. Outbound"
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'If %1 is %2 in %3 no. %4, then all associated lines where type is %5 must use the same location.';
        Text002: Label 'The warehouse shipment was not created because the Shipping Advice field is set to Complete, and item no. %1 is not available in location code %2.\\You can create the warehouse shipment by either changing the Shipping Advice field to Partial in %3 no. %4 or by manually filling in the warehouse shipment document.';
        Text003: Label 'The warehouse shipment was not created because an open warehouse shipment exists for the Sales Header and Shipping Advice is %1.\\You must add the item(s) as new line(s) to the existing warehouse shipment or change Shipping Advice to Partial.';
        Text004: Label 'No %1 was found. The warehouse shipment could not be created.';
        GetSourceDocuments: Report "Get Source Documents";

    local procedure CreateWhseShipmentHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"): Boolean
    begin
        if WarehouseRequest.IsEmpty then
            exit(false);

        Clear(GetSourceDocuments);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetTableView(WarehouseRequest);
        GetSourceDocuments.SetHideDialog(true);
        GetSourceDocuments.RunModal;

        OnAfterCreateWhseShipmentHeaderFromWhseRequest(WarehouseRequest);

        exit(true);
    end;

    procedure GetOutboundDocs(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhseGetSourceFilterRec: Record "Warehouse Source Filter";
        WhseSourceFilterSelection: Page "Filters to Get Source Docs.";
    begin
        WhseShptHeader.Find;
        WhseSourceFilterSelection.SetOneCreatedShptHeader(WhseShptHeader);
        WhseGetSourceFilterRec.FilterGroup(2);
        WhseGetSourceFilterRec.SetRange(Type, WhseGetSourceFilterRec.Type::Outbound);
        WhseGetSourceFilterRec.FilterGroup(0);
        WhseSourceFilterSelection.SetTableView(WhseGetSourceFilterRec);
        WhseSourceFilterSelection.RunModal;

        UpdateShipmentHeaderStatus(WhseShptHeader);

        OnAfterGetOutboundDocs(WhseShptHeader);
    end;

    procedure GetSingleOutboundDoc(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhseRqst: Record "Warehouse Request";
        SourceDocSelection: Page "Source Documents";
        IsHandled: Boolean;
    begin
        OnBeforeGetSingleOutboundDoc(WhseShptHeader, IsHandled);
        if IsHandled then
            exit;

        Clear(GetSourceDocuments);
        WhseShptHeader.Find;

        WhseRqst.FilterGroup(2);
        WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
        WhseRqst.SetRange("Location Code", WhseShptHeader."Location Code");
        WhseRqst.FilterGroup(0);
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        WhseRqst.SetRange("Completely Handled", false);

        SourceDocSelection.LookupMode(true);
        SourceDocSelection.SetTableView(WhseRqst);
        if SourceDocSelection.RunModal <> ACTION::LookupOK then
            exit;
        SourceDocSelection.GetResult(WhseRqst);

        GetSourceDocuments.SetOneCreatedShptHeader(WhseShptHeader);
        GetSourceDocuments.SetSkipBlocked(true);
        GetSourceDocuments.UseRequestPage(false);
        WhseRqst.SetRange("Location Code", WhseShptHeader."Location Code");
        GetSourceDocuments.SetTableView(WhseRqst);
        GetSourceDocuments.RunModal;

        UpdateShipmentHeaderStatus(WhseShptHeader);

        OnAfterGetSingleOutboundDoc(WhseShptHeader);
    end;

    procedure CreateFromSalesOrder(SalesHeader: Record "Sales Header")
    begin
        ShowResult(CreateFromSalesOrderHideDialog(SalesHeader));
    end;

    procedure CreateFromSalesOrderHideDialog(SalesHeader: Record "Sales Header"): Boolean
    var
        WhseRqst: Record "Warehouse Request";
    begin
        if not SalesHeader.IsApprovedForPosting then
            exit(false);

        FindWarehouseRequestForSalesOrder(WhseRqst, SalesHeader);

        if WhseRqst.IsEmpty then
            exit(false);

        CreateWhseShipmentHeaderFromWhseRequest(WhseRqst);
        exit(true);
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
        if WhsePickDocSelection.RunModal <> ACTION::LookupOK then
            exit;
        WhsePickDocSelection.GetResult(WhsePickRqst);

        GetWhseSourceDocuments.SetPickWkshName(
          CurrentWhseWkshTemplate, CurrentWhseWkshName, LocationCode);
        GetWhseSourceDocuments.UseRequestPage(false);
        GetWhseSourceDocuments.SetTableView(WhsePickRqst);
        GetWhseSourceDocuments.RunModal;
    end;

    procedure CheckSalesHeader(SalesHeader: Record "Sales Header"; ShowError: Boolean): Boolean
    var
        SalesLine: Record "Sales Line";
        CurrItemVariant: Record "Item Variant";
        SalesOrder: Page "Sales Order";
        QtyOutstandingBase: Decimal;
        RecordNo: Integer;
        TotalNoOfRecords: Integer;
        LocationCode: Code[10];
    begin
        OnBeforeCheckSalesHeader(SalesHeader, ShowError);

        with SalesHeader do begin
            if "Shipping Advice" = "Shipping Advice"::Partial then
                exit(false);

            SalesLine.SetCurrentKey("Document Type", Type, "No.", "Variant Code");
            SalesLine.SetRange("Document Type", "Document Type");
            SalesLine.SetRange("Document No.", "No.");
            SalesLine.SetRange(Type, SalesLine.Type::Item);
            OnCheckSalesHeaderOnAfterSetLineFilters(SalesLine, SalesHeader);
            if SalesLine.FindSet then
                repeat
                    if SalesLine.IsInventoriableItem then
                        SalesLine.Mark(true);
                until SalesLine.Next = 0;
            SalesLine.MarkedOnly(true);

            if SalesLine.FindSet then begin
                LocationCode := SalesLine."Location Code";
                SetItemVariant(CurrItemVariant, SalesLine."No.", SalesLine."Variant Code");
                TotalNoOfRecords := SalesLine.Count();
                repeat
                    RecordNo += 1;

                    if SalesLine."Location Code" <> LocationCode then begin
                        if ShowError then
                            Error(Text001, FieldCaption("Shipping Advice"), "Shipping Advice",
                              SalesOrder.Caption, "No.", SalesLine.Type);
                        exit(true);
                    end;

                    if EqualItemVariant(CurrItemVariant, SalesLine."No.", SalesLine."Variant Code") then
                        QtyOutstandingBase += SalesLine."Outstanding Qty. (Base)"
                    else begin
                        if CheckAvailability(
                             CurrItemVariant, QtyOutstandingBase, SalesLine."Location Code",
                             SalesOrder.Caption, DATABASE::"Sales Line", "Document Type", "No.", ShowError)
                        then
                            exit(true);
                        SetItemVariant(CurrItemVariant, SalesLine."No.", SalesLine."Variant Code");
                        QtyOutstandingBase := SalesLine."Outstanding Qty. (Base)";
                    end;
                    if RecordNo = TotalNoOfRecords then begin // last record
                        if CheckAvailability(
                             CurrItemVariant, QtyOutstandingBase, SalesLine."Location Code",
                             SalesOrder.Caption, DATABASE::"Sales Line", "Document Type", "No.", ShowError)
                        then
                            exit(true);
                    end;
                until SalesLine.Next = 0; // sorted by item
            end;
        end;
    end;

    procedure CheckTransferHeader(TransferHeader: Record "Transfer Header"; ShowError: Boolean): Boolean
    var
        TransferLine: Record "Transfer Line";
        CurrItemVariant: Record "Item Variant";
        TransferOrder: Page "Transfer Order";
        QtyOutstandingBase: Decimal;
        RecordNo: Integer;
        TotalNoOfRecords: Integer;
    begin
        OnBeforeCheckTransferHeader(TransferHeader, ShowError);

        with TransferHeader do begin
            if "Shipping Advice" = "Shipping Advice"::Partial then
                exit(false);

            TransferLine.SetCurrentKey("Item No.");
            TransferLine.SetRange("Document No.", "No.");
            OnCheckTransferHeaderOnAfterSetLineFilters(TransferLine, TransferHeader);
            if TransferLine.FindSet then begin
                SetItemVariant(CurrItemVariant, TransferLine."Item No.", TransferLine."Variant Code");
                TotalNoOfRecords := TransferLine.Count();
                repeat
                    RecordNo += 1;
                    if EqualItemVariant(CurrItemVariant, TransferLine."Item No.", TransferLine."Variant Code") then
                        QtyOutstandingBase += TransferLine."Outstanding Qty. (Base)"
                    else begin
                        if CheckAvailability(
                             CurrItemVariant, QtyOutstandingBase, TransferLine."Transfer-from Code",
                             TransferOrder.Caption, DATABASE::"Transfer Line", 0, "No.", ShowError)
                        then // outbound
                            exit(true);
                        SetItemVariant(CurrItemVariant, TransferLine."Item No.", TransferLine."Variant Code");
                        QtyOutstandingBase := TransferLine."Outstanding Qty. (Base)";
                    end;
                    if RecordNo = TotalNoOfRecords then begin // last record
                        if CheckAvailability(
                             CurrItemVariant, QtyOutstandingBase, TransferLine."Transfer-from Code",
                             TransferOrder.Caption, DATABASE::"Transfer Line", 0, "No.", ShowError)
                        then // outbound
                            exit(true);
                    end;
                until TransferLine.Next = 0; // sorted by item
            end;
        end;
    end;

    local procedure CheckAvailability(CurrItemVariant: Record "Item Variant"; QtyBaseNeeded: Decimal; LocationCode: Code[10]; FormCaption: Text[1024]; SourceType: Integer; SourceSubType: Integer; SourceID: Code[20]; ShowError: Boolean): Boolean
    var
        Item: Record Item;
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        QtyReservedForOrder: Decimal;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAvailability(
          CurrItemVariant, QtyBaseNeeded, LocationCode, FormCaption, SourceType, SourceSubType, SourceID, ShowError, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with Item do begin
            Get(CurrItemVariant."Item No.");
            SetRange("Location Filter", LocationCode);
            SetRange("Variant Filter", CurrItemVariant.Code);
            CalcFields(Inventory, "Reserved Qty. on Inventory");

            // find qty reserved for this order
            ReservEntry.SetSourceFilter(SourceType, SourceSubType, SourceID, -1, true);
            ReservEntry.SetRange("Item No.", CurrItemVariant."Item No.");
            ReservEntry.SetRange("Location Code", LocationCode);
            ReservEntry.SetRange("Variant Code", CurrItemVariant.Code);
            ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
            if ReservEntry.FindSet then
                repeat
                    ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
                    QtyReservedForOrder += ReservEntry2."Quantity (Base)";
                until ReservEntry.Next = 0;

            if Inventory - ("Reserved Qty. on Inventory" - QtyReservedForOrder) < QtyBaseNeeded then begin
                if ShowError then
                    Error(Text002, CurrItemVariant."Item No.", LocationCode, FormCaption, SourceID);
                exit(true);
            end;
        end;
    end;

    local procedure OpenWarehouseShipmentPage()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        GetSourceDocuments.GetLastShptHeader(WarehouseShipmentHeader);
        PAGE.Run(PAGE::"Warehouse Shipment", WarehouseShipmentHeader);
    end;

    local procedure GetRequireShipRqst(var WhseRqst: Record "Warehouse Request")
    var
        Location: Record Location;
        LocationCode: Text;
    begin
        if WhseRqst.FindSet then begin
            repeat
                if Location.RequireShipment(WhseRqst."Location Code") then
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
        with SalesHeader do begin
            TestField(Status, Status::Released);
            if WhseShpmntConflict("Document Type", "No.", "Shipping Advice") then
                Error(Text003, Format("Shipping Advice"));
            CheckSalesHeader(SalesHeader, true);
            WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
            WhseRqst.SetSourceFilter(DATABASE::"Sales Line", "Document Type", "No.");
            WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
            GetRequireShipRqst(WhseRqst);
        end;

        OnAfterFindWarehouseRequestForSalesOrder(WhseRqst, SalesHeader);
    end;

    local procedure FindWarehouseRequestForPurchReturnOrder(var WhseRqst: Record "Warehouse Request"; PurchHeader: Record "Purchase Header")
    begin
        with PurchHeader do begin
            TestField(Status, Status::Released);
            WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
            WhseRqst.SetSourceFilter(DATABASE::"Purchase Line", "Document Type", "No.");
            WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
            GetRequireShipRqst(WhseRqst);
        end;

        OnAfterFindWarehouseRequestForPurchReturnOrder(WhseRqst, PurchHeader);
    end;

    local procedure FindWarehouseRequestForOutbndTransferOrder(var WhseRqst: Record "Warehouse Request"; TransHeader: Record "Transfer Header")
    begin
        with TransHeader do begin
            TestField(Status, Status::Released);
            CheckTransferHeader(TransHeader, true);
            WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
            WhseRqst.SetSourceFilter(DATABASE::"Transfer Line", 0, "No.");
            WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
            GetRequireShipRqst(WhseRqst);
        end;

        OnAfterFindWarehouseRequestForOutbndTransferOrder(WhseRqst, TransHeader);
    end;

    local procedure FindWarehouseRequestForServiceOrder(var WhseRqst: Record "Warehouse Request"; ServiceHeader: Record "Service Header")
    begin
        with ServiceHeader do begin
            TestField("Release Status", "Release Status"::"Released to Ship");
            WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
            WhseRqst.SetSourceFilter(DATABASE::"Service Line", "Document Type", "No.");
            WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
            GetRequireShipRqst(WhseRqst);
        end;

        OnAfterFindWarehouseRequestForServiceOrder(WhseRqst, ServiceHeader);
    end;

    local procedure UpdateShipmentHeaderStatus(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        with WarehouseShipmentHeader do begin
            Find;
            "Document Status" := GetDocumentStatus(0);
            Modify;
        end;
    end;

    local procedure ShowResult(WhseShipmentCreated: Boolean)
    var
        WarehouseRequest: Record "Warehouse Request";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowResult(WhseShipmentCreated, IsHandled);
        if IsHandled then
            exit;

        if WhseShipmentCreated then begin
            GetSourceDocuments.ShowShipmentDialog;
            OpenWarehouseShipmentPage;
        end else
            Message(Text004, WarehouseRequest.TableCaption);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseShipmentHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request")
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
    local procedure OnBeforeCheckTransferHeader(var TransferHeader: Record "Transfer Header"; var ShowError: Boolean)
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
    local procedure OnBeforeCreateFromServiceOrder(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesHeaderOnAfterSetLineFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
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
    local procedure OnBeforeShowResult(WhseShipmentCreated: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSingleWhsePickDocOnWhsePickRqstSetFilters(var WhsePickRequest: Record "Whse. Pick Request"; CurrentWhseWkshTemplate: Code[10]; CurrentWhseWkshName: Code[10]; LocationCode: Code[10])
    begin
    end;
}

