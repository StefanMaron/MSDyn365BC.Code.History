namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Setup;
using Microsoft.Warehouse.Request;

codeunit 5774 "Whse.-Production Release"
{

    trigger OnRun()
    begin
    end;

    var
        Location: Record Location;
        WarehouseRequest: Record "Warehouse Request";
        WhsePickRqst: Record "Whse. Pick Request";
        ProdOrderComp: Record "Prod. Order Component";

    procedure Release(ProdOrder: Record "Production Order")
    var
        LocationCode2: Code[10];
        CurrentSignFactor: Integer;
        OldSignFactor: Integer;
    begin
        if ProdOrder.Status <> ProdOrder.Status::Released then
            exit;

        OnBeforeReleaseWhseProdOrder(ProdOrder);

        LocationCode2 := '';
        OldSignFactor := 0;
        ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Location Code");
        ProdOrderComp.SetRange(Status, ProdOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetFilter(
          "Flushing Method",
          '%1|%2|%3',
          ProdOrderComp."Flushing Method"::Manual,
          ProdOrderComp."Flushing Method"::"Pick + Forward",
          ProdOrderComp."Flushing Method"::"Pick + Backward");
        ProdOrderComp.SetRange("Planning Level Code", 0);
        ProdOrderComp.SetFilter("Remaining Quantity", '<>0');
        if ProdOrderComp.Find('-') then
            CreateWhseRqst(ProdOrderComp, ProdOrder);
        repeat
            CurrentSignFactor := SignFactor(ProdOrderComp.Quantity);
            if (ProdOrderComp."Location Code" <> LocationCode2) or
               (CurrentSignFactor <> OldSignFactor)
            then
                CreateWhseRqst(ProdOrderComp, ProdOrder);
            LocationCode2 := ProdOrderComp."Location Code";
            OldSignFactor := CurrentSignFactor;
        until ProdOrderComp.Next() = 0;

        OnAfterRelease(ProdOrder);
    end;

    local procedure CreateWhseRqst(var ProdOrderComp: Record "Prod. Order Component"; var ProdOrder: Record "Production Order")
    var
        ProdOrderComp2: Record "Prod. Order Component";
    begin
        GetLocation(ProdOrderComp."Location Code");
        if ((not Location."Require Pick") and (Location."Prod. Consump. Whse. Handling" = Location."Prod. Consump. Whse. Handling"::"No Warehouse Handling")) then
            exit;

        if (ProdOrderComp."Flushing Method" = ProdOrderComp."Flushing Method"::"Pick + Forward") and
           (ProdOrderComp."Routing Link Code" = '')
        then
            exit;

        ProdOrderComp2.Copy(ProdOrderComp);
        ProdOrderComp2.SetRange("Location Code", ProdOrderComp."Location Code");
        ProdOrderComp2.SetRange("Unit of Measure Code", '');
        if ProdOrderComp2.FindFirst() then
            ProdOrderComp2.TestField("Unit of Measure Code");

        if Location."Prod. Consump. Whse. Handling" in [Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)"] then begin
            if ProdOrderComp."Remaining Quantity" > 0 then begin
                WhsePickRqst.Init();
                WhsePickRqst."Document Type" := WhsePickRqst."Document Type"::Production;
                WhsePickRqst."Document Subtype" := ProdOrderComp.Status.AsInteger();
                WhsePickRqst."Document No." := ProdOrderComp."Prod. Order No.";
                WhsePickRqst.Status := WhsePickRqst.Status::Released;
                WhsePickRqst."Location Code" := ProdOrderComp."Location Code";
                WhsePickRqst."Completely Picked" :=
                    ProdOrderCompletelyPicked(
                        ProdOrderComp."Location Code", ProdOrder."No.", ProdOrder.Status, ProdOrderComp."Line No.");
                if WhsePickRqst."Completely Picked" and (not ProdOrderComp."Completely Picked") then
                    WhsePickRqst."Completely Picked" := false;
                OnBeforeCreateWhsePickRequest(WhsePickRqst, ProdOrderComp, ProdOrder);
                if not WhsePickRqst.Insert() then
                    WhsePickRqst.Modify();
            end
        end else begin
            WarehouseRequest.Init();
            if ProdOrderComp."Remaining Quantity" > 0 then
                WarehouseRequest.Type := WarehouseRequest.Type::Outbound
            else
                WarehouseRequest.Type := WarehouseRequest.Type::Inbound;
            WarehouseRequest."Location Code" := ProdOrderComp."Location Code";
            WarehouseRequest."Source Type" := Database::"Prod. Order Component";
            WarehouseRequest."Source No." := ProdOrderComp."Prod. Order No.";
            WarehouseRequest."Source Subtype" := ProdOrderComp.Status.AsInteger();
            WarehouseRequest."Source Document" := WarehouseRequest."Source Document"::"Prod. Consumption";
            WarehouseRequest."Document Status" := WarehouseRequest."Document Status"::Released;
            WarehouseRequest.SetDestinationType(ProdOrder);
            WarehouseRequest."Destination No." := ProdOrder."Source No.";
            WarehouseRequest."Completely Handled" :=
              ProdOrderCompletelyHandled(ProdOrder, ProdOrderComp."Location Code");
            OnBeforeCreateWhseRequest(WarehouseRequest, ProdOrderComp, ProdOrder);
            if not WarehouseRequest.Insert() then
                WarehouseRequest.Modify();
        end;
    end;

    procedure ReleaseLine(var ProdOrderComponent: Record "Prod. Order Component"; var OldProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        WhsePickRequest: Record "Whse. Pick Request";
        IsHandled: Boolean;
    begin
        OnBeforeReleaseLine(ProdOrderComponent, OldProdOrderComponent, IsHandled);
        if IsHandled then
            exit;

        GetLocation(ProdOrderComponent."Location Code");
        if Location."Prod. Consump. Whse. Handling" in [Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement",
                                                        Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)"]
        then
            if ProdOrderComponent."Remaining Quantity" <> 0 then begin
                if ProdOrderComponent."Remaining Quantity" > 0 then
                    WarehouseRequest.Type := WarehouseRequest.Type::Outbound
                else
                    WarehouseRequest.Type := WarehouseRequest.Type::Inbound;
                ProdOrder.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.");
                WarehouseRequest.Init();
                WarehouseRequest."Location Code" := ProdOrderComponent."Location Code";
                WarehouseRequest."Source Type" := Database::"Prod. Order Component";
                WarehouseRequest."Source No." := ProdOrderComponent."Prod. Order No.";
                WarehouseRequest."Source Subtype" := ProdOrderComponent.Status.AsInteger();
                WarehouseRequest."Source Document" := WarehouseRequest."Source Document"::"Prod. Consumption";
                WarehouseRequest."Document Status" := WarehouseRequest."Document Status"::Released;
                WarehouseRequest.SetDestinationType(ProdOrder);
                OnBeforeWarehouseRequestUpdate(WarehouseRequest, ProdOrderComponent);
                if not WarehouseRequest.Insert() then
                    WarehouseRequest.Modify();
            end;

        if Location."Prod. Consump. Whse. Handling" = Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)" then
            if ProdOrderComponent."Remaining Quantity" > 0 then begin
                WhsePickRequest.Init();
                WhsePickRequest."Document Type" := WhsePickRequest."Document Type"::Production;
                WhsePickRequest."Document Subtype" := ProdOrderComponent.Status.AsInteger();
                WhsePickRequest."Document No." := ProdOrderComponent."Prod. Order No.";
                WhsePickRequest.Status := WhsePickRequest.Status::Released;
                WhsePickRequest."Completely Picked" :=
                  ProdOrderCompletelyPicked(ProdOrderComponent."Location Code", ProdOrderComponent."Prod. Order No.", ProdOrderComponent.Status, ProdOrderComponent."Line No.");
                if WhsePickRequest."Completely Picked" and (not ProdOrderComponent."Completely Picked") then
                    WhsePickRequest."Completely Picked" := false;
                WhsePickRequest."Location Code" := ProdOrderComponent."Location Code";
                OnBeforeCreateWhsePickRequest(WhsePickRqst, ProdOrderComponent, ProdOrder);
                if not WhsePickRequest.Insert() then
                    WhsePickRequest.Modify();
            end;

        if (ProdOrderComponent."Line No." = OldProdOrderComponent."Line No.") and
           ((ProdOrderComponent."Location Code" <> OldProdOrderComponent."Location Code") or
            (ProdOrderComponent."Remaining Quantity" <= 0))
        then
            DeleteLine(OldProdOrderComponent);
    end;

    procedure DeleteLine(ProdOrderComp: Record "Prod. Order Component")
    var
        ProdOrderComp2: Record "Prod. Order Component";
        KeepWhseRqst: Boolean;
    begin
        KeepWhseRqst := false;
        GetLocation(ProdOrderComp."Location Code");
        ProdOrderComp2.SetCurrentKey(Status, "Prod. Order No.", "Location Code");
        ProdOrderComp2.SetRange(Status, ProdOrderComp.Status);
        ProdOrderComp2.SetRange("Prod. Order No.", ProdOrderComp."Prod. Order No.");
        ProdOrderComp2.SetRange("Location Code", ProdOrderComp."Location Code");
        ProdOrderComp2.SetFilter(
          "Flushing Method", '%1|%2|%3',
          ProdOrderComp2."Flushing Method"::Manual,
          ProdOrderComp2."Flushing Method"::"Pick + Forward",
          ProdOrderComp2."Flushing Method"::"Pick + Backward");
        ProdOrderComp2.SetRange("Planning Level Code", 0);
        ProdOrderComp2.SetFilter("Remaining Quantity", '<>0');
        if ProdOrderComp2.Find('-') then
            repeat
                if ((ProdOrderComp2.Status <> ProdOrderComp.Status) or
                    (ProdOrderComp2."Prod. Order No." <> ProdOrderComp."Prod. Order No.") or
                    (ProdOrderComp2."Prod. Order Line No." <> ProdOrderComp."Prod. Order Line No.") or
                    (ProdOrderComp2."Line No." <> ProdOrderComp."Line No.")) and
                   ((not ProdOrderComp2."Completely Picked") or
                    (not (Location."Require Pick" and Location."Require Shipment")))
                then
                    KeepWhseRqst := true;
            until (ProdOrderComp2.Next() = 0) or KeepWhseRqst;

        if not KeepWhseRqst then
            if Location."Require Shipment" then
                DeleteWhsePickRqst(ProdOrderComp, false)
            else
                DeleteWhseRqst(ProdOrderComp, false);

        OnAfterDeleteLine(ProdOrderComp);
    end;

    local procedure DeleteWhsePickRqst(ProdOrderComp: Record "Prod. Order Component"; DeleteAllWhsePickRqst: Boolean)
    var
        WhseRqst: Record "Whse. Pick Request";
    begin
        WhsePickRqst.SetRange("Document Type", WhseRqst."Document Type"::Production);
        WhsePickRqst.SetRange("Document No.", ProdOrderComp."Prod. Order No.");
        if not DeleteAllWhsePickRqst then begin
            WhsePickRqst.SetRange("Document Subtype", ProdOrderComp.Status);
            WhsePickRqst.SetRange("Location Code", ProdOrderComp."Location Code");
        end;
        if not WhsePickRqst.IsEmpty() then
            WhsePickRqst.DeleteAll(true);
    end;

    local procedure DeleteWhseRqst(ProdOrderComp: Record "Prod. Order Component"; DeleteAllWhseRqst: Boolean)
    var
        WarehouseRequest2: Record "Warehouse Request";
    begin
        if not DeleteAllWhseRqst then
            case true of
                ProdOrderComp."Remaining Quantity" > 0:
                    WarehouseRequest2.SetRange(Type, WarehouseRequest.Type::Outbound);
                ProdOrderComp."Remaining Quantity" < 0:
                    WarehouseRequest2.SetRange(Type, WarehouseRequest.Type::Inbound);
                ProdOrderComp."Remaining Quantity" = 0:
                    exit;
            end;
        WarehouseRequest2.SetRange("Source Type", Database::"Prod. Order Component");
        WarehouseRequest2.SetRange("Source No.", ProdOrderComp."Prod. Order No.");
        if not DeleteAllWhseRqst then begin
            WarehouseRequest2.SetRange("Source Subtype", ProdOrderComp.Status);
            WarehouseRequest2.SetRange("Location Code", ProdOrderComp."Location Code");
        end;
        if not WarehouseRequest2.IsEmpty() then
            WarehouseRequest2.DeleteAll(true);
    end;

    procedure FinishedDelete(var ProdOrder: Record "Production Order")
    begin
        ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Location Code");
        ProdOrderComp.SetRange(Status, ProdOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderComp.Find('-') then begin
            DeleteWhsePickRqst(ProdOrderComp, true);
            DeleteWhseRqst(ProdOrderComp, true);
        end;
    end;

    local procedure ProdOrderCompletelyPicked(LocationCode: Code[10]; ProdOrderNo: Code[20]; ProdOrderStatus: Enum "Production Order Status"; CompLineNo: Integer): Boolean
    var
        ProdOrderComp2: Record "Prod. Order Component";
    begin
        ProdOrderComp2.SetCurrentKey(Status, "Prod. Order No.", "Location Code");
        ProdOrderComp2.SetRange(Status, ProdOrderStatus);
        ProdOrderComp2.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComp2.SetRange("Location Code", LocationCode);
        ProdOrderComp2.SetFilter("Line No.", '<>%1', CompLineNo);
        ProdOrderComp2.SetRange("Flushing Method", ProdOrderComp."Flushing Method"::Manual);
        ProdOrderComp2.SetRange("Planning Level Code", 0);
        ProdOrderComp2.SetRange("Completely Picked", false);
        exit(ProdOrderComp2.IsEmpty());
    end;

    local procedure ProdOrderCompletelyHandled(ProdOrder: Record "Production Order"; LocationCode: Code[10]): Boolean
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Location Code");
        ProdOrderComp.SetRange(Status, ProdOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Location Code", LocationCode);
        ProdOrderComp.SetFilter(
          "Flushing Method", '%1|%2|%3',
          ProdOrderComp."Flushing Method"::Manual,
          ProdOrderComp."Flushing Method"::"Pick + Forward",
          ProdOrderComp."Flushing Method"::"Pick + Backward");
        ProdOrderComp.SetRange("Planning Level Code", 0);
        ProdOrderComp.SetFilter("Remaining Quantity", '<>0');
        exit(ProdOrderComp.IsEmpty());
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode <> Location.Code then
            if LocationCode = '' then begin
                Location.GetLocationSetup(LocationCode, Location);
                Location.Code := '';
            end else
                Location.Get(LocationCode);

        OnAfterGetLocation(Location, LocationCode);
    end;

    local procedure SignFactor(Quantity: Decimal): Integer
    begin
        if Quantity > 0 then
            exit(1);
        exit(-1);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteLine(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLocation(var Location: Record Location; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelease(var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseRequest(var WarehouseRequest: Record "Warehouse Request"; ProdOrderComp: Record "Prod. Order Component"; ProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhsePickRequest(var WhsePickRequest: Record "Whse. Pick Request"; ProdOrderComp: Record "Prod. Order Component"; ProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseLine(var ProdOrderComp: Record "Prod. Order Component"; var OldProdOrderComp: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseWhseProdOrder(var ProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWarehouseRequestUpdate(var WarehouseRequest: Record "Warehouse Request"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;
}

