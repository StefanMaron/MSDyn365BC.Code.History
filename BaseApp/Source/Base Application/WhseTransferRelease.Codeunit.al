codeunit 5773 "Whse.-Transfer Release"
{

    trigger OnRun()
    begin
    end;

    var
        Location: Record Location;
        WhseMgt: Codeunit "Whse. Management";
        CalledFromTransferOrder: Boolean;

    procedure Release(TransHeader: Record "Transfer Header")
    var
        WhseRqst: Record "Warehouse Request";
    begin
        OnBeforeRelease(TransHeader);

        with TransHeader do begin
            InitializeWhseRequest(WhseRqst, TransHeader, Status::Released);

            if Location.RequireReceive("Transfer-to Code") or Location.RequirePutaway("Transfer-to Code") then
                CreateInboundWhseRequest(WhseRqst, TransHeader);
            if Location.RequireShipment("Transfer-from Code") or Location.RequirePicking("Transfer-from Code") then
                CreateOutboundWhseRequest(WhseRqst, TransHeader);

            DeleteOpenWhseRequest("No.");
        end;

        OnAfterRelease(TransHeader);
    end;

    procedure Reopen(TransHeader: Record "Transfer Header")
    var
        WhseRqst: Record "Warehouse Request";
    begin
        OnBeforeReopen(TransHeader);

        with TransHeader do begin
            if WhseRqst.Get(WhseRqst.Type::Inbound, "Transfer-to Code", DATABASE::"Transfer Line", 1, "No.") then begin
                WhseRqst."Document Status" := Status::Open;
                WhseRqst.Modify();
            end;
            if WhseRqst.Get(WhseRqst.Type::Outbound, "Transfer-from Code", DATABASE::"Transfer Line", 0, "No.") then begin
                WhseRqst."Document Status" := Status::Open;
                WhseRqst.Modify();
            end;
        end;

        OnAfterReopen(TransHeader);
    end;

    [Scope('OnPrem')]
    procedure UpdateExternalDocNoForReleasedOrder(TransHeader: Record "Transfer Header")
    var
        WhseRqst: Record "Warehouse Request";
    begin
        with TransHeader do begin
            if WhseRqst.Get(WhseRqst.Type::Inbound, "Transfer-to Code", DATABASE::"Transfer Line", 1, "No.") then begin
                WhseRqst."External Document No." := "External Document No.";
                WhseRqst.Modify();
            end;
            if WhseRqst.Get(WhseRqst.Type::Outbound, "Transfer-from Code", DATABASE::"Transfer Line", 0, "No.") then begin
                WhseRqst."External Document No." := "External Document No.";
                WhseRqst.Modify();
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
            "Source Document" := WhseMgt.GetSourceDocument("Source Type", "Source Subtype");
            "Expected Receipt Date" := TransferHeader."Receipt Date";
            "Location Code" := TransferHeader."Transfer-to Code";
            "Completely Handled" := TransferHeader."Completely Received";
            "Shipment Method Code" := TransferHeader."Shipment Method Code";
            "Shipping Agent Code" := TransferHeader."Shipping Agent Code";
            "Destination No." := TransferHeader."Transfer-to Code";
            OnBeforeCreateWhseRequest(WarehouseRequest, TransferHeader);
            if CalledFromTransferOrder then begin
                if Modify then;
            end else
                if not Insert() then
                    Modify;
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
            "Source Document" := WhseMgt.GetSourceDocument("Source Type", "Source Subtype");
            "Location Code" := TransferHeader."Transfer-from Code";
            "Completely Handled" := TransferHeader."Completely Shipped";
            "Shipment Method Code" := TransferHeader."Shipment Method Code";
            "Shipping Agent Code" := TransferHeader."Shipping Agent Code";
            "Shipping Advice" := TransferHeader."Shipping Advice";
            "Shipment Date" := TransferHeader."Shipment Date";
            "Destination No." := TransferHeader."Transfer-from Code";
            OnBeforeCreateWhseRequest(WarehouseRequest, TransferHeader);
            if not Insert() then
                Modify;
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
            if not IsEmpty then
                DeleteAll(true);
        end;
    end;

    procedure SetCallFromTransferOrder(CalledFromTransferOrder2: Boolean)
    begin
        CalledFromTransferOrder := CalledFromTransferOrder2;
    end;

    local procedure CheckUnitOfMeasureCode(DocumentNo: Code[20])
    var
        TransLine: Record "Transfer Line";
    begin
        TransLine.SetRange("Document No.", DocumentNo);
        TransLine.SetRange("Unit of Measure Code", '');
        TransLine.SetFilter("Item No.", '<>%1', '');
        if TransLine.FindFirst then
            TransLine.TestField("Unit of Measure Code");
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
}

