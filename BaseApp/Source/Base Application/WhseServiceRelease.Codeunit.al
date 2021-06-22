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
        WhseType: Option Inbound,Outbound;
        OldWhseType: Option Inbound,Outbound;
    begin
        OnBeforeRelease(ServiceHeader);

        with ServiceHeader do begin
            if "Document Type" <> "Document Type"::Order then
                exit;

            WhseRqst."Source Document" := WhseRqst."Source Document"::"Service Order";

            ServiceLine.SetCurrentKey("Document Type", "Document No.", "Location Code");
            ServiceLine.SetRange("Document Type", "Document Type");
            ServiceLine.SetRange("Document No.", "No.");
            ServiceLine.SetRange(Type, ServiceLine.Type::Item);
            ServiceLine.SetRange("Job No.", '');
            OnAfterReleaseSetFilters(ServiceLine, ServiceHeader);
            if ServiceLine.FindSet then begin
                First := true;
                repeat
                    if ("Document Type" = "Document Type"::Order) and (ServiceLine.Quantity >= 0) then
                        WhseType := WhseType::Outbound
                    else
                        WhseType := WhseType::Inbound;

                    if First or (ServiceLine."Location Code" <> OldLocationCode) or (WhseType <> OldWhseType) then
                        CreateWhseRqst(ServiceHeader, ServiceLine, WhseType);

                    OnAfterCreateWhseRqst(ServiceHeader, ServiceLine, WhseType);

                    First := false;
                    OldLocationCode := ServiceLine."Location Code";
                    OldWhseType := WhseType;
                until ServiceLine.Next = 0;
            end;
            SetWhseRqstFiltersByStatus(ServiceHeader, WhseRqst, "Release Status"::Open);
            WhseRqst.DeleteAll(true);
        end;

        OnAfterRelease(ServiceHeader);
    end;

    procedure Reopen(ServiceHeader: Record "Service Header")
    var
        WhseRqst: Record "Warehouse Request";
    begin
        OnBeforeReopen(ServiceHeader);

        with ServiceHeader do begin
            WhseRqst.Type := WhseRqst.Type::Outbound;
            SetWhseRqstFiltersByStatus(ServiceHeader, WhseRqst, "Release Status"::"Released to Ship");
            WhseRqst.LockTable();
            if WhseRqst.FindSet then
                repeat
                    WhseRqst."Document Status" := "Release Status"::Open;
                    WhseRqst.Modify();
                until WhseRqst.Next = 0;
        end;

        OnAfterReopen(ServiceHeader);
    end;

    local procedure CreateWhseRqst(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; WhseType: Option Inbound,Outbound)
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
            if ServiceLine2.FindFirst then
                ServiceLine2.TestField("Unit of Measure Code");

            with WhseRqst do begin
                Type := WhseType;
                "Source Type" := DATABASE::"Service Line";
                "Source Subtype" := ServiceHeader."Document Type";
                "Source No." := ServiceHeader."No.";
                "Shipping Advice" := ServiceHeader."Shipping Advice";
                "Document Status" := ServiceHeader."Release Status"::"Released to Ship";
                "Location Code" := ServiceLine."Location Code";
                "Destination Type" := "Destination Type"::Customer;
                "Destination No." := ServiceHeader."Bill-to Customer No.";
                "External Document No." := '';
                "Shipment Date" := ServiceLine.GetShipmentDate;
                "Shipment Method Code" := ServiceHeader."Shipment Method Code";
                "Shipping Agent Code" := ServiceHeader."Shipping Agent Code";
                "Completely Handled" := CalcCompletelyShipped(ServiceLine);
                OnBeforeCreateWhseRequest(WhseRqst, ServiceHeader, ServiceLine);
                if not Insert() then
                    Modify;
            end;
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

    local procedure SetWhseRqstFiltersByStatus(ServiceHeader: Record "Service Header"; var WarehouseRequest: Record "Warehouse Request"; Status: Option Open,"Released to Ship",,"Pending Approval","Pending Prepayment")
    begin
        with WarehouseRequest do begin
            Reset;
            SetCurrentKey("Source Type", "Source Subtype", "Source No.");
            SetRange(Type, Type);
            SetRange("Source Type", DATABASE::"Service Line");
            SetRange("Source Subtype", ServiceHeader."Document Type");
            SetRange("Source No.", ServiceHeader."No.");
            SetRange("Document Status", Status);
        end;
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

