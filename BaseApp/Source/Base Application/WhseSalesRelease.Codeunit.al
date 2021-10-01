codeunit 5771 "Whse.-Sales Release"
{
    Permissions = TableData "Warehouse Request" = rimd;

    trigger OnRun()
    begin
    end;

    var
        WhseRqst: Record "Warehouse Request";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        OldLocationCode: Code[10];
        First: Boolean;

    procedure Release(SalesHeader: Record "Sales Header")
    var
        WhseType: Enum "Warehouse Request Type";
        OldWhseType: Enum "Warehouse Request Type";
        IsHandled: Boolean;
    begin
        OnBeforeRelease(SalesHeader);

        IsHandled := false;
        OnBeforeReleaseSetWhseRequestSourceDocument(SalesHeader, WhseRqst, IsHandled);
        if not IsHandled then
            case SalesHeader."Document Type" of
                "Sales Document Type"::Order:
                    WhseRqst."Source Document" := WhseRqst."Source Document"::"Sales Order";
                "Sales Document Type"::"Return Order":
                    WhseRqst."Source Document" := WhseRqst."Source Document"::"Sales Return Order";
                else
                    exit;
            end;

        SalesLine.SetCurrentKey("Document Type", "Document No.", "Location Code");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Drop Shipment", false);
        SalesLine.SetRange("Job No.", '');
        OnAfterReleaseSetFilters(SalesLine, SalesHeader);
        if SalesLine.FindSet() then begin
            First := true;
            repeat
                if ((SalesHeader."Document Type" = "Sales Document Type"::Order) and (SalesLine.Quantity >= 0)) or
                    ((SalesHeader."Document Type" = "Sales Document Type"::"Return Order") and (SalesLine.Quantity < 0))
                then
                    WhseType := WhseType::Outbound
                else
                    WhseType := WhseType::Inbound;

                if First or (SalesLine."Location Code" <> OldLocationCode) or (WhseType <> OldWhseType) then
                    CreateWarehouseRequest(SalesHeader, SalesLine, WhseType, WhseRqst);

                OnAfterReleaseOnAfterCreateWhseRequest(
                    SalesHeader, SalesLine, WhseType.AsInteger(), First, OldWhseType.AsInteger(), OldLocationCode);

                First := false;
                OldLocationCode := SalesLine."Location Code";
                OldWhseType := WhseType;
            until SalesLine.Next() = 0;
        end;

        OnReleaseOnAfterCreateWhseRequest(SalesHeader, SalesLine);

        WhseRqst.Reset();
        WhseRqst.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WhseRqst.SetRange(Type, WhseRqst.Type);
        WhseRqst.SetSourceFilter(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        WhseRqst.SetRange("Document Status", SalesHeader.Status::Open);
        if not WhseRqst.IsEmpty() then
            WhseRqst.DeleteAll(true);

        OnAfterRelease(SalesHeader);
    end;

    procedure Reopen(SalesHeader: Record "Sales Header")
    var
        WhseRqst: Record "Warehouse Request";
        IsHandled: Boolean;
    begin
        OnBeforeReopen(SalesHeader);

        with SalesHeader do begin
            IsHandled := false;
            OnBeforeReopenSetWhseRequestSourceDocument(SalesHeader, WhseRqst, IsHandled);

            WhseRqst.Reset();
            WhseRqst.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
            if IsHandled then
                WhseRqst.SetRange(Type, WhseRqst.Type);
            WhseRqst.SetSourceFilter(DATABASE::"Sales Line", "Document Type".AsInteger(), "No.");
            WhseRqst.SetRange("Document Status", Status::Released);
            if not WhseRqst.IsEmpty() then
                WhseRqst.ModifyAll("Document Status", WhseRqst."Document Status"::Open);
        end;

        OnAfterReopen(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure UpdateExternalDocNoForReleasedOrder(SalesHeader: Record "Sales Header")
    begin
        with SalesHeader do begin
            WhseRqst.Reset();
            WhseRqst.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
            WhseRqst.SetSourceFilter(DATABASE::"Sales Line", "Document Type".AsInteger(), "No.");
            WhseRqst.SetRange("Document Status", Status::Released);
            if not WhseRqst.IsEmpty() then
                WhseRqst.ModifyAll("External Document No.", "External Document No.");
        end;
    end;

    procedure CreateWarehouseRequest(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; WhseType: Enum "Warehouse Request Type"; var WarehouseRequest: Record "Warehouse Request")
    var
        SalesLine2: Record "Sales Line";
    begin
        if ShouldCreateWarehouseRequest(WhseType) then begin
            SalesLine2.Copy(SalesLine);
            SalesLine2.SetRange("Location Code", SalesLine."Location Code");
            SalesLine2.SetRange("Unit of Measure Code", '');
            if SalesLine2.FindFirst then
                SalesLine2.TestField("Unit of Measure Code");

            WarehouseRequest.Type := WhseType;
            WarehouseRequest."Source Type" := DATABASE::"Sales Line";
            WarehouseRequest."Source Subtype" := SalesHeader."Document Type".AsInteger();
            WarehouseRequest."Source No." := SalesHeader."No.";
            WarehouseRequest."Shipment Method Code" := SalesHeader."Shipment Method Code";
            WarehouseRequest."Shipping Agent Code" := SalesHeader."Shipping Agent Code";
            WarehouseRequest."Shipping Advice" := SalesHeader."Shipping Advice";
            WarehouseRequest."Document Status" := SalesHeader.Status::Released.AsInteger();
            WarehouseRequest."Location Code" := SalesLine."Location Code";
            WarehouseRequest."Destination Type" := WarehouseRequest."Destination Type"::Customer;
            WarehouseRequest."Destination No." := SalesHeader."Sell-to Customer No.";
            WarehouseRequest."External Document No." := SalesHeader."External Document No.";
            if WhseType = WhseType::Inbound then
                WarehouseRequest."Expected Receipt Date" := SalesHeader."Shipment Date"
            else
                WarehouseRequest."Shipment Date" := SalesHeader."Shipment Date";
            SalesHeader.SetRange("Location Filter", SalesLine."Location Code");
            SalesHeader.CalcFields("Completely Shipped");
            WarehouseRequest."Completely Handled" := SalesHeader."Completely Shipped";
            OnBeforeCreateWhseRequest(WhseRqst, SalesHeader, SalesLine, WhseType.AsInteger());
            if not WarehouseRequest.Insert() then
                WarehouseRequest.Modify();
            OnAfterCreateWhseRequest(WhseRqst, SalesHeader, SalesLine, WhseType.AsInteger());
        end;
    end;

    local procedure ShouldCreateWarehouseRequest(WhseType: Enum "Warehouse Request Type") ShouldCreate: Boolean;
    begin
        ShouldCreate :=
           ((WhseType = "Warehouse Request Type"::Outbound) and
            (Location.RequireShipment(SalesLine."Location Code") or
             Location.RequirePicking(SalesLine."Location Code"))) or
           ((WhseType = "Warehouse Request Type"::Inbound) and
            (Location.RequireReceive(SalesLine."Location Code") or
             Location.RequirePutaway(SalesLine."Location Code")));

        OnAfterShouldCreateWarehouseRequest(Location, ShouldCreate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseRequest(var WhseRqst: Record "Warehouse Request"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; WhseType: Option Inbound,Outbound)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseRequest(var WhseRqst: Record "Warehouse Request"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; WhseType: Option Inbound,Outbound)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelease(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseSetFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseOnAfterCreateWhseRequest(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; WhseType: Option; First: Boolean; OldWhseType: Option; OldLocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopen(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldCreateWarehouseRequest(Location: Record Location; var ShouldCreate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRelease(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseSetWhseRequestSourceDocument(var SalesHeader: Record "Sales Header"; var WarehouseRequest: Record "Warehouse Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopen(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenSetWhseRequestSourceDocument(var SalesHeader: Record "Sales Header"; var WarehouseRequest: Record "Warehouse Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseOnAfterCreateWhseRequest(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;
}

