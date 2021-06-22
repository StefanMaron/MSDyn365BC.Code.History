codeunit 5771 "Whse.-Sales Release"
{

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
        WhseType: Option Inbound,Outbound;
        OldWhseType: Option Inbound,Outbound;
        IsHandled: Boolean;
    begin
        OnBeforeRelease(SalesHeader);

        with SalesHeader do begin
            IsHandled := false;
            OnBeforeReleaseSetWhseRequestSourceDocument(SalesHeader, WhseRqst, IsHandled);
            if not IsHandled then
                case "Document Type" of
                    "Document Type"::Order:
                        WhseRqst."Source Document" := WhseRqst."Source Document"::"Sales Order";
                    "Document Type"::"Return Order":
                        WhseRqst."Source Document" := WhseRqst."Source Document"::"Sales Return Order";
                    else
                        exit;
                end;

            SalesLine.SetCurrentKey("Document Type", "Document No.", "Location Code");
            SalesLine.SetRange("Document Type", "Document Type");
            SalesLine.SetRange("Document No.", "No.");
            SalesLine.SetRange(Type, SalesLine.Type::Item);
            SalesLine.SetRange("Drop Shipment", false);
            SalesLine.SetRange("Job No.", '');
            OnAfterReleaseSetFilters(SalesLine, SalesHeader);
            if SalesLine.FindSet then begin
                First := true;
                repeat
                    if (("Document Type" = "Document Type"::Order) and (SalesLine.Quantity >= 0)) or
                       (("Document Type" = "Document Type"::"Return Order") and (SalesLine.Quantity < 0))
                    then
                        WhseType := WhseType::Outbound
                    else
                        WhseType := WhseType::Inbound;

                    if First or (SalesLine."Location Code" <> OldLocationCode) or (WhseType <> OldWhseType) then
                        CreateWhseRqst(SalesHeader, SalesLine, WhseType);

                    OnAfterReleaseOnAfterCreateWhseRequest(SalesHeader, SalesLine, WhseType, First, OldWhseType, OldLocationCode);

                    First := false;
                    OldLocationCode := SalesLine."Location Code";
                    OldWhseType := WhseType;
                until SalesLine.Next = 0;
            end;

            WhseRqst.Reset();
            WhseRqst.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
            WhseRqst.SetRange(Type, WhseRqst.Type);
            WhseRqst.SetSourceFilter(DATABASE::"Sales Line", "Document Type", "No.");
            WhseRqst.SetRange("Document Status", Status::Open);
            if not WhseRqst.IsEmpty then
                WhseRqst.DeleteAll(true);
        end;

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
            WhseRqst.SetSourceFilter(DATABASE::"Sales Line", "Document Type", "No.");
            WhseRqst.SetRange("Document Status", Status::Released);
            WhseRqst.LockTable();
            if not WhseRqst.IsEmpty then
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
            WhseRqst.SetSourceFilter(DATABASE::"Sales Line", "Document Type", "No.");
            WhseRqst.SetRange("Document Status", Status::Released);
            if not WhseRqst.IsEmpty then
                WhseRqst.ModifyAll("External Document No.", "External Document No.");
        end;
    end;

    local procedure CreateWhseRqst(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; WhseType: Option Inbound,Outbound)
    var
        SalesLine2: Record "Sales Line";
    begin
        if ((WhseType = WhseType::Outbound) and
            (Location.RequireShipment(SalesLine."Location Code") or
             Location.RequirePicking(SalesLine."Location Code"))) or
           ((WhseType = WhseType::Inbound) and
            (Location.RequireReceive(SalesLine."Location Code") or
             Location.RequirePutaway(SalesLine."Location Code")))
        then begin
            SalesLine2.Copy(SalesLine);
            SalesLine2.SetRange("Location Code", SalesLine."Location Code");
            SalesLine2.SetRange("Unit of Measure Code", '');
            if SalesLine2.FindFirst then
                SalesLine2.TestField("Unit of Measure Code");

            WhseRqst.Type := WhseType;
            WhseRqst."Source Type" := DATABASE::"Sales Line";
            WhseRqst."Source Subtype" := SalesHeader."Document Type";
            WhseRqst."Source No." := SalesHeader."No.";
            WhseRqst."Shipment Method Code" := SalesHeader."Shipment Method Code";
            WhseRqst."Shipping Agent Code" := SalesHeader."Shipping Agent Code";
            WhseRqst."Shipping Advice" := SalesHeader."Shipping Advice";
            WhseRqst."Document Status" := SalesHeader.Status::Released;
            WhseRqst."Location Code" := SalesLine."Location Code";
            WhseRqst."Destination Type" := WhseRqst."Destination Type"::Customer;
            WhseRqst."Destination No." := SalesHeader."Sell-to Customer No.";
            WhseRqst."External Document No." := SalesHeader."External Document No.";
            if WhseType = WhseType::Inbound then
                WhseRqst."Expected Receipt Date" := SalesHeader."Shipment Date"
            else
                WhseRqst."Shipment Date" := SalesHeader."Shipment Date";
            SalesHeader.SetRange("Location Filter", SalesLine."Location Code");
            SalesHeader.CalcFields("Completely Shipped");
            WhseRqst."Completely Handled" := SalesHeader."Completely Shipped";
            OnBeforeCreateWhseRequest(WhseRqst, SalesHeader, SalesLine, WhseType);
            if not WhseRqst.Insert() then
                WhseRqst.Modify();
            OnAfterCreateWhseRequest(WhseRqst, SalesHeader, SalesLine, WhseType);
        end;
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
}

