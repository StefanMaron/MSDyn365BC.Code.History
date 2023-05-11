codeunit 5773 "Whse.-Transfer Release"
{

    trigger OnRun()
    begin
    end;

    var
        Location: Record Location;
        WhseManagement: Codeunit "Whse. Management";
        CalledFromTransferOrder: Boolean;

    procedure Release(TransferHeader: Record "Transfer Header")
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        OnBeforeRelease(TransferHeader);

        InitializeWhseRequest(WarehouseRequest, TransferHeader, TransferHeader.Status::Released);

        if ShouldCreateInboundWhseRequest(TransferHeader."Transfer-to Code") then
            CreateInboundWhseRequest(WarehouseRequest, TransferHeader);
        if ShouldCreateOutboundWhseRequest(TransferHeader."Transfer-from Code") then
            CreateOutboundWhseRequest(WarehouseRequest, TransferHeader);

        DeleteOpenWhseRequest(TransferHeader."No.");

        OnAfterRelease(TransferHeader);
    end;

    procedure Reopen(TransferHeader: Record "Transfer Header")
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        OnBeforeReopen(TransferHeader);

        with TransferHeader do begin
            if WarehouseRequest.Get("Warehouse Request Type"::Inbound, "Transfer-to Code", DATABASE::"Transfer Line", 1, "No.") then begin
                WarehouseRequest."Document Status" := Status::Open;
                WarehouseRequest.Modify();
            end;
            if WarehouseRequest.Get("Warehouse Request Type"::Outbound, "Transfer-from Code", DATABASE::"Transfer Line", 0, "No.") then begin
                WarehouseRequest."Document Status" := Status::Open;
                WarehouseRequest.Modify();
            end;
        end;

        OnAfterReopen(TransferHeader);
    end;

    [Scope('OnPrem')]
    procedure UpdateExternalDocNoForReleasedOrder(TransferHeader: Record "Transfer Header")
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        with TransferHeader do begin
            if WarehouseRequest.Get("Warehouse Request Type"::Inbound, "Transfer-to Code", DATABASE::"Transfer Line", 1, "No.") then begin
                WarehouseRequest."External Document No." := "External Document No.";
                WarehouseRequest.Modify();
            end;
            if WarehouseRequest.Get("Warehouse Request Type"::Outbound, "Transfer-from Code", DATABASE::"Transfer Line", 0, "No.") then begin
                WarehouseRequest."External Document No." := "External Document No.";
                WarehouseRequest.Modify();
            end;
        end;
    end;

    procedure InitializeWhseRequest(var WarehouseRequest: Record "Warehouse Request"; TransferHeader: Record "Transfer Header"; DocumentStatus: Option)
    begin
        with WarehouseRequest do begin
            "Source Type" := DATABASE::"Transfer Line";
            "Source No." := TransferHeader."No.";
            "Document Status" := DocumentStatus;
            "Destination Type" := "Destination Type"::Location;
            "External Document No." := TransferHeader."External Document No.";
        end;
    end;

    procedure CreateInboundWhseRequest(var WarehouseRequest: Record "Warehouse Request"; TransferHeader: Record "Transfer Header")
    begin
        with WarehouseRequest do begin
            CheckUnitOfMeasureCode(TransferHeader."No.");
            TransferHeader.SetRange("Location Filter", TransferHeader."Transfer-to Code");
            TransferHeader.CalcFields("Completely Received");

            Type := Type::Inbound;
            "Source Subtype" := 1;
            "Source Document" := WhseManagement.GetWhseRqstSourceDocument("Source Type", "Source Subtype");
            "Expected Receipt Date" := TransferHeader."Receipt Date";
            "Location Code" := TransferHeader."Transfer-to Code";
            "Completely Handled" := TransferHeader."Completely Received";
            "Shipment Method Code" := TransferHeader."Shipment Method Code";
            "Shipping Agent Code" := TransferHeader."Shipping Agent Code";
            "Shipping Agent Service Code" := TransferHeader."Shipping Agent Service Code";
            "Destination No." := TransferHeader."Transfer-to Code";
            OnBeforeCreateWhseRequest(WarehouseRequest, TransferHeader);
            if CalledFromTransferOrder then begin
                if Modify() then;
            end else
                if not Insert() then
                    Modify();
        end;

        OnAfterCreateInboundWhseRequest(WarehouseRequest, TransferHeader);
    end;

    procedure CreateOutboundWhseRequest(var WarehouseRequest: Record "Warehouse Request"; TransferHeader: Record "Transfer Header")
    begin
        with WarehouseRequest do begin
            CheckUnitOfMeasureCode(TransferHeader."No.");
            TransferHeader.SetRange("Location Filter", TransferHeader."Transfer-from Code");
            TransferHeader.CalcFields("Completely Shipped");

            Type := Type::Outbound;
            "Source Subtype" := 0;
            "Source Document" := WhseManagement.GetWhseRqstSourceDocument("Source Type", "Source Subtype");
            "Location Code" := TransferHeader."Transfer-from Code";
            "Completely Handled" := TransferHeader."Completely Shipped";
            "Shipment Method Code" := TransferHeader."Shipment Method Code";
            "Shipping Agent Code" := TransferHeader."Shipping Agent Code";
            "Shipping Agent Service Code" := TransferHeader."Shipping Agent Service Code";
            "Shipping Advice" := TransferHeader."Shipping Advice";
            "Shipment Date" := TransferHeader."Shipment Date";
            "Destination No." := TransferHeader."Transfer-from Code";
            OnBeforeCreateWhseRequest(WarehouseRequest, TransferHeader);
            if not Insert() then
                Modify();
        end;

        OnAfterCreateOutboundWhseRequest(WarehouseRequest, TransferHeader);
    end;

    local procedure DeleteOpenWhseRequest(TransferOrderNo: Code[20])
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        with WarehouseRequest do begin
            SetCurrentKey("Source Type", "Source No.");
            SetRange("Source Type", DATABASE::"Transfer Line");
            SetRange("Source No.", TransferOrderNo);
            SetRange("Document Status", "Document Status"::Open);
            if not IsEmpty() then
                DeleteAll(true);
        end;
    end;

    procedure SetCallFromTransferOrder(CalledFromTransferOrder2: Boolean)
    begin
        CalledFromTransferOrder := CalledFromTransferOrder2;
    end;

    local procedure CheckUnitOfMeasureCode(DocumentNo: Code[20])
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", DocumentNo);
        TransferLine.SetRange("Unit of Measure Code", '');
        TransferLine.SetFilter("Item No.", '<>%1', '');
        OnCheckUnitOfMeasureCodeOnAfterTransLineSetFilters(TransferLine, DocumentNo);
        if TransferLine.FindFirst() then
            TransferLine.TestField("Unit of Measure Code");
    end;


    local procedure ShouldCreateInboundWhseRequest(LocationCode: Code[10]) ShouldCreate: Boolean
    begin
        ShouldCreate := Location.RequireReceive(LocationCode) or Location.RequirePutaway(LocationCode);

        OnAfterShouldCreateInboundWhseRequest(LocationCode, ShouldCreate);
    end;

    local procedure ShouldCreateOutboundWhseRequest(LocationCode: Code[10]) ShouldCreate: Boolean;
    begin
        ShouldCreate := Location.RequireShipment(LocationCode) or Location.RequirePicking(LocationCode);

        OnAfterShouldCreateOutboundWhseRequest(LocationCode, ShouldCreate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInboundWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateOutboundWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseRequest(var WarehouseRequest: Record "Warehouse Request"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelease(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopen(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRelease(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopen(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckUnitOfMeasureCodeOnAfterTransLineSetFilters(var TransLine: Record "Transfer Line"; DocumentNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldCreateInboundWhseRequest(LocationCode: Code[20]; var ShouldCreate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldCreateOutboundWhseRequest(LocationCode: Code[20]; var ShouldCreate: Boolean)
    begin
    end;
}

