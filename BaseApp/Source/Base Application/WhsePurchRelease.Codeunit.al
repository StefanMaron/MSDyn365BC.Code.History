codeunit 5772 "Whse.-Purch. Release"
{
    Permissions = TableData "Warehouse Request" = rimd;

    trigger OnRun()
    begin
    end;

    var
        WhseRqst: Record "Warehouse Request";
        PurchLine: Record "Purchase Line";
        Location: Record Location;
        OldLocationCode: Code[10];
        First: Boolean;

    procedure Release(PurchHeader: Record "Purchase Header")
    var
        WhseType: Option Inbound,Outbound;
        OldWhseType: Option Inbound,Outbound;
    begin
        OnBeforeRelease(PurchHeader);

        with PurchHeader do begin
            case "Document Type" of
                "Document Type"::Order:
                    WhseRqst."Source Document" := WhseRqst."Source Document"::"Purchase Order";
                "Document Type"::"Return Order":
                    WhseRqst."Source Document" := WhseRqst."Source Document"::"Purchase Return Order";
                else
                    exit;
            end;

            PurchLine.SetCurrentKey("Document Type", "Document No.", "Location Code");
            PurchLine.SetRange("Document Type", "Document Type");
            PurchLine.SetRange("Document No.", "No.");
            PurchLine.SetRange(Type, PurchLine.Type::Item);
            PurchLine.SetRange("Drop Shipment", false);
            PurchLine.SetRange("Job No.", '');
            PurchLine.SetRange("Work Center No.", '');
            OnAfterReleaseSetFilters(PurchLine, PurchHeader);
            if PurchLine.Find('-') then begin
                First := true;
                repeat
                    if (("Document Type" = "Document Type"::Order) and (PurchLine.Quantity >= 0)) or
                       (("Document Type" = "Document Type"::"Return Order") and (PurchLine.Quantity < 0))
                    then
                        WhseType := WhseType::Inbound
                    else
                        WhseType := WhseType::Outbound;
                    if First or (PurchLine."Location Code" <> OldLocationCode) or (WhseType <> OldWhseType) then
                        CreateWhseRqst(PurchHeader, PurchLine, WhseType);

                    OnReleaseOnAfterCreateWhseRequest(PurchHeader, PurchLine, WhseType);

                    First := false;
                    OldLocationCode := PurchLine."Location Code";
                    OldWhseType := WhseType;
                until PurchLine.Next = 0;
            end;

            FilterWarehouseRequest(WhseRqst, PurchHeader, WhseRqst."Document Status"::Open);
            if not WhseRqst.IsEmpty then
                WhseRqst.DeleteAll(true);
        end;

        OnAfterRelease(PurchHeader);
    end;

    procedure Reopen(PurchHeader: Record "Purchase Header")
    begin
        OnBeforeReopen(PurchHeader);

        with PurchHeader do begin
            FilterWarehouseRequest(WhseRqst, PurchHeader, WhseRqst."Document Status"::Released);
            if not WhseRqst.IsEmpty then
                WhseRqst.ModifyAll("Document Status", WhseRqst."Document Status"::Open);
        end;

        OnAfterReopen(PurchHeader);
    end;

    [Scope('OnPrem')]
    procedure UpdateExternalDocNoForReleasedOrder(PurchHeader: Record "Purchase Header")
    begin
        with PurchHeader do begin
            FilterWarehouseRequest(WhseRqst, PurchHeader, WhseRqst."Document Status"::Released);
            if not WhseRqst.IsEmpty then
                WhseRqst.ModifyAll("External Document No.", "Vendor Shipment No.");
        end;
    end;

    local procedure CreateWhseRqst(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; WhseType: Option Inbound,Outbound)
    var
        PurchLine2: Record "Purchase Line";
    begin
        if ((WhseType = WhseType::Outbound) and
            (Location.RequireShipment(PurchLine."Location Code") or
             Location.RequirePicking(PurchLine."Location Code"))) or
           ((WhseType = WhseType::Inbound) and
            (Location.RequireReceive(PurchLine."Location Code") or
             Location.RequirePutaway(PurchLine."Location Code")))
        then begin
            PurchLine2.Copy(PurchLine);
            PurchLine2.SetRange("Location Code", PurchLine."Location Code");
            PurchLine2.SetRange("Unit of Measure Code", '');
            if PurchLine2.FindFirst then
                PurchLine2.TestField("Unit of Measure Code");

            WhseRqst.Type := WhseType;
            WhseRqst."Source Type" := DATABASE::"Purchase Line";
            WhseRqst."Source Subtype" := PurchHeader."Document Type";
            WhseRqst."Source No." := PurchHeader."No.";
            WhseRqst."Shipment Method Code" := PurchHeader."Shipment Method Code";
            WhseRqst."Document Status" := PurchHeader.Status::Released;
            WhseRqst."Location Code" := PurchLine."Location Code";
            WhseRqst."Destination Type" := WhseRqst."Destination Type"::Vendor;
            WhseRqst."Destination No." := PurchHeader."Buy-from Vendor No.";
            WhseRqst."External Document No." := PurchHeader."Vendor Shipment No.";
            if WhseType = WhseType::Inbound then
                WhseRqst."Expected Receipt Date" := PurchHeader."Expected Receipt Date"
            else
                WhseRqst."Shipment Date" := PurchHeader."Expected Receipt Date";
            PurchHeader.SetRange("Location Filter", PurchLine."Location Code");
            PurchHeader.CalcFields("Completely Received");
            WhseRqst."Completely Handled" := PurchHeader."Completely Received";
            OnBeforeCreateWhseRequest(WhseRqst, PurchHeader, PurchLine, WhseType);
            if not WhseRqst.Insert() then
                WhseRqst.Modify();
            OnAfterCreateWhseRqst(WhseRqst, PurchHeader, PurchLine, WhseType);
        end;
    end;

    local procedure FilterWarehouseRequest(var WarehouseRequest: Record "Warehouse Request"; PurchaseHeader: Record "Purchase Header"; DocumentStatus: Option)
    begin
        with WarehouseRequest do begin
            Reset;
            SetCurrentKey("Source Type", "Source Subtype", "Source No.");
            SetRange("Source Type", DATABASE::"Purchase Line");
            SetRange("Source Subtype", PurchaseHeader."Document Type");
            SetRange("Source No.", PurchaseHeader."No.");
            SetRange("Document Status", DocumentStatus);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseRqst(var WhseRqst: Record "Warehouse Request"; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; WhseType: Option Inbound,Outbound)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseRequest(var WhseRqst: Record "Warehouse Request"; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; WhseType: Option Inbound,Outbound)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelease(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopen(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRelease(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopen(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseOnAfterCreateWhseRequest(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; WhseType: Option Inbound,Outbound)
    begin
    end;
}

