codeunit 5770 "Whse.-Service Release"
{

    trigger OnRun()
    begin
    end;

    var
        WhseRqst: Record "Warehouse Request";
        ServiceLine: Record "Service Line";
        Location: Record Location;
        OldLocationCode: Code[10];
        First: Boolean;

    procedure Release(ServiceHeader: Record "Service Header")
    var
        WhseType: Enum "Warehouse Request Type";
        OldWhseType: Enum "Warehouse Request Type";
    begin
        OnBeforeRelease(ServiceHeader);

        if ServiceHeader."Document Type" <> "Service Document Type"::Order then
            exit;

        WhseRqst."Source Document" := WhseRqst."Source Document"::"Service Order";

        ServiceLine.SetCurrentKey("Document Type", "Document No.", "Location Code");
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetRange("Job No.", '');
        OnAfterReleaseSetFilters(ServiceLine, ServiceHeader);
        if ServiceLine.FindSet() then begin
            First := true;
            repeat
                if (ServiceHeader."Document Type" = "Service Document Type"::Order) and (ServiceLine.Quantity >= 0) then
                    WhseType := WhseType::Outbound
                else
                    WhseType := WhseType::Inbound;

                if First or (ServiceLine."Location Code" <> OldLocationCode) or (WhseType <> OldWhseType) then
                    CreateWarehouseRequest(ServiceHeader, ServiceLine, WhseType);

                OnAfterCreateWhseRqst(ServiceHeader, ServiceLine, WhseType.AsInteger());

                First := false;
                OldLocationCode := ServiceLine."Location Code";
                OldWhseType := WhseType;
            until ServiceLine.Next() = 0;
        end;
        SetWhseRqstFiltersByStatus(ServiceHeader, WhseRqst, ServiceHeader."Release Status"::Open);
        WhseRqst.DeleteAll(true);

        OnAfterRelease(ServiceHeader);
    end;

    procedure Reopen(ServiceHeader: Record "Service Header")
    var
        WhseRqst: Record "Warehouse Request";
    begin
        OnBeforeReopen(ServiceHeader);

        WhseRqst.Type := WhseRqst.Type::Outbound;
        SetWhseRqstFiltersByStatus(ServiceHeader, WhseRqst, ServiceHeader."Release Status"::"Released to Ship");
        WhseRqst.LockTable();
        if WhseRqst.FindSet() then
            repeat
                WhseRqst."Document Status" := ServiceHeader."Release Status"::Open;
                WhseRqst.Modify();
            until WhseRqst.Next() = 0;

        OnAfterReopen(ServiceHeader);
    end;

    procedure CreateWarehouseRequest(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; WhseType: Enum "Warehouse Request Type")
    var
        ServiceLine2: Record "Service Line";
    begin
        if ((WhseType = WhseType::Outbound) and
            (Location.RequireShipment(ServiceLine."Location Code") or
             Location.RequirePicking(ServiceLine."Location Code"))) or
           ((WhseType = WhseType::Inbound) and
            (Location.RequireReceive(ServiceLine."Location Code") or
             Location.RequirePutaway(ServiceLine."Location Code")))
        then begin
            ServiceLine2.Copy(ServiceLine);
            ServiceLine2.SetRange("Location Code", ServiceLine."Location Code");
            ServiceLine2.SetRange("Unit of Measure Code", '');
            if ServiceLine2.FindFirst() then
                ServiceLine2.TestField("Unit of Measure Code");

            WhseRqst.Type := WhseType;
            WhseRqst."Source Type" := DATABASE::"Service Line";
            WhseRqst."Source Subtype" := ServiceHeader."Document Type".AsInteger();
            WhseRqst."Source No." := ServiceHeader."No.";
            WhseRqst."Shipping Advice" := ServiceHeader."Shipping Advice";
            WhseRqst."Document Status" := ServiceHeader."Release Status"::"Released to Ship";
            WhseRqst."Location Code" := ServiceLine."Location Code";
            WhseRqst."Destination Type" := "Warehouse Destination Type"::Customer;
            WhseRqst."Destination No." := ServiceHeader."Bill-to Customer No.";
            WhseRqst."External Document No." := '';
            WhseRqst."Shipment Date" := ServiceLine.GetShipmentDate;
            WhseRqst."Shipment Method Code" := ServiceHeader."Shipment Method Code";
            WhseRqst."Shipping Agent Code" := ServiceHeader."Shipping Agent Code";
            WhseRqst."Completely Handled" := CalcCompletelyShipped(ServiceLine);
            OnBeforeCreateWhseRequest(WhseRqst, ServiceHeader, ServiceLine);
            if not WhseRqst.Insert() then
                WhseRqst.Modify();
        end;
    end;

    local procedure CalcCompletelyShipped(ServiceLine: Record "Service Line"): Boolean
    var
        ServiceLineWithItem: Record "Service Line";
    begin
        with ServiceLineWithItem do begin
            SetRange("Document Type", ServiceLine."Document Type");
            SetRange("Document No.", ServiceLine."Document No.");
            SetRange("Location Code", ServiceLine."Location Code");
            SetRange(Type, Type::Item);
            SetRange("Completely Shipped", false);
            exit(IsEmpty);
        end;
    end;

    local procedure SetWhseRqstFiltersByStatus(ServiceHeader: Record "Service Header"; var WarehouseRequest: Record "Warehouse Request"; Status: Option)
    begin
        WarehouseRequest.Reset;
        WarehouseRequest.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type);
        WarehouseRequest.SetRange("Source Type", DATABASE::"Service Line");
        WarehouseRequest.SetRange("Source Subtype", ServiceHeader."Document Type");
        WarehouseRequest.SetRange("Source No.", ServiceHeader."No.");
        WarehouseRequest.SetRange("Document Status", Status);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseRqst(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; WhseType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelease(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseSetFilters(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopen(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseRequest(var WarehouseRequest: Record "Warehouse Request"; ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRelease(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopen(var ServiceHeader: Record "Service Header")
    begin
    end;
}

