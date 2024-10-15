codeunit 5774 "Whse.-Production Release"
{

    trigger OnRun()
    begin
    end;

    var
        Location: Record Location;
        WhseRqst: Record "Warehouse Request";
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

        with ProdOrder do begin
            ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Location Code");
            ProdOrderComp.SetRange(Status, Status);
            ProdOrderComp.SetRange("Prod. Order No.", "No.");
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
        end;

        OnAfterRelease(ProdOrder);
    end;

    local procedure CreateWhseRqst(var ProdOrderComp: Record "Prod. Order Component"; var ProdOrder: Record "Production Order")
    var
        ProdOrderComp2: Record "Prod. Order Component";
    begin
        GetLocation(ProdOrderComp."Location Code");
        if not Location."Require Pick" then
            exit;

        if (ProdOrderComp."Flushing Method" = ProdOrderComp."Flushing Method"::"Pick + Forward") and
           (ProdOrderComp."Routing Link Code" = '')
        then
            exit;

        ProdOrderComp2.Copy(ProdOrderComp);
        ProdOrderComp2.SetRange("Location Code", ProdOrderComp."Location Code");
        ProdOrderComp2.SetRange("Unit of Measure Code", '');
        if ProdOrderComp2.FindFirst then
            ProdOrderComp2.TestField("Unit of Measure Code");

        if Location."Require Shipment" then begin
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
            WhseRqst.Init();
            if ProdOrderComp."Remaining Quantity" > 0 then
                WhseRqst.Type := WhseRqst.Type::Outbound
            else
                WhseRqst.Type := WhseRqst.Type::Inbound;
            WhseRqst."Location Code" := ProdOrderComp."Location Code";
            WhseRqst."Source Type" := DATABASE::"Prod. Order Component";
            WhseRqst."Source No." := ProdOrderComp."Prod. Order No.";
            WhseRqst."Source Subtype" := ProdOrderComp.Status.AsInteger();
            WhseRqst."Source Document" := WhseRqst."Source Document"::"Prod. Consumption";
            WhseRqst."Document Status" := WhseRqst."Document Status"::Released;
            WhseRqst.SetDestinationType(ProdOrder);
            WhseRqst."Destination No." := ProdOrder."Source No.";
            WhseRqst."Completely Handled" :=
              ProdOrderCompletelyHandled(ProdOrder, ProdOrderComp."Location Code");
            OnBeforeCreateWhseRequest(WhseRqst, ProdOrderComp, ProdOrder);
            if not WhseRqst.Insert() then
                WhseRqst.Modify();
        end;
    end;

    procedure ReleaseLine(var ProdOrderComp: Record "Prod. Order Component"; var OldProdOrderComp: Record "Prod. Order Component")
    var
        ProdOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        WhsePickRequest: Record "Whse. Pick Request";
        IsHandled: Boolean;
    begin
        OnBeforeReleaseLine(ProdOrderComp, OldProdOrderComp, IsHandled);
        if IsHandled then
            exit;

        with ProdOrderComp do begin
            GetLocation("Location Code");
            if Location."Require Pick" then
                if Location."Require Shipment" then begin
                    if "Remaining Quantity" > 0 then begin
                        WhsePickRequest.Init();
                        WhsePickRequest."Document Type" := WhsePickRequest."Document Type"::Production;
                        WhsePickRequest."Document Subtype" := Status.AsInteger();
                        WhsePickRequest."Document No." := "Prod. Order No.";
                        WhsePickRequest.Status := WhsePickRequest.Status::Released;
                        WhsePickRequest."Completely Picked" :=
                          ProdOrderCompletelyPicked("Location Code", "Prod. Order No.", Status, "Line No.");
                        if WhsePickRequest."Completely Picked" and (not "Completely Picked") then
                            WhsePickRequest."Completely Picked" := false;
                        WhsePickRequest."Location Code" := "Location Code";
                        OnBeforeCreateWhsePickRequest(WhsePickRqst, ProdOrderComp, ProdOrder);
                        if not WhsePickRequest.Insert() then
                            WhsePickRequest.Modify();
                    end;
                end else
                    if "Remaining Quantity" <> 0 then begin
                        if "Remaining Quantity" > 0 then
                            WarehouseRequest.Type := WarehouseRequest.Type::Outbound
                        else
                            WarehouseRequest.Type := WarehouseRequest.Type::Inbound;
                        ProdOrder.Get(Status, "Prod. Order No.");
                        WarehouseRequest.Init();
                        WarehouseRequest."Location Code" := "Location Code";
                        WarehouseRequest."Source Type" := DATABASE::"Prod. Order Component";
                        WarehouseRequest."Source No." := "Prod. Order No.";
                        WarehouseRequest."Source Subtype" := Status.AsInteger();
                        WarehouseRequest."Source Document" := WarehouseRequest."Source Document"::"Prod. Consumption";
                        WarehouseRequest."Document Status" := WarehouseRequest."Document Status"::Released;
                        WarehouseRequest.SetDestinationType(ProdOrder);
                        OnBeforeWarehouseRequestUpdate(WarehouseRequest, ProdOrderComp);
                        if not WarehouseRequest.Insert() then
                            WarehouseRequest.Modify();
                    end;

            if ("Line No." = OldProdOrderComp."Line No.") and
               (("Location Code" <> OldProdOrderComp."Location Code") or
                (("Remaining Quantity" * OldProdOrderComp."Remaining Quantity") <= 0))
            then
                DeleteLine(OldProdOrderComp);
        end;
    end;

    procedure DeleteLine(ProdOrderComp: Record "Prod. Order Component")
    var
        ProdOrderComp2: Record "Prod. Order Component";
        KeepWhseRqst: Boolean;
    begin
        with ProdOrderComp do begin
            KeepWhseRqst := false;
            GetLocation("Location Code");
            ProdOrderComp2.SetCurrentKey(Status, "Prod. Order No.", "Location Code");
            ProdOrderComp2.SetRange(Status, Status);
            ProdOrderComp2.SetRange("Prod. Order No.", "Prod. Order No.");
            ProdOrderComp2.SetRange("Location Code", "Location Code");
            ProdOrderComp2.SetFilter(
              "Flushing Method", '%1|%2|%3',
              ProdOrderComp2."Flushing Method"::Manual,
              ProdOrderComp2."Flushing Method"::"Pick + Forward",
              ProdOrderComp2."Flushing Method"::"Pick + Backward");
            ProdOrderComp2.SetRange("Planning Level Code", 0);
            ProdOrderComp2.SetFilter("Remaining Quantity", '<>0');
            if ProdOrderComp2.Find('-') then
                repeat
                    if ((ProdOrderComp2.Status <> Status) or
                        (ProdOrderComp2."Prod. Order No." <> "Prod. Order No.") or
                        (ProdOrderComp2."Prod. Order Line No." <> "Prod. Order Line No.") or
                        (ProdOrderComp2."Line No." <> "Line No.")) and
                       ((not ProdOrderComp2."Completely Picked") or
                        (not (Location."Require Pick" and Location."Require Shipment")))
                    then
                        KeepWhseRqst := true;
                until (ProdOrderComp2.Next() = 0) or KeepWhseRqst;

            if not KeepWhseRqst then begin
                if Location."Require Shipment" then
                    DeleteWhsePickRqst(ProdOrderComp, false)
                else
                    DeleteWhseRqst(ProdOrderComp, false);
            end;
        end;

        OnAfterDeleteLine(ProdOrderComp);
    end;

    local procedure DeleteWhsePickRqst(ProdOrderComp: Record "Prod. Order Component"; DeleteAllWhsePickRqst: Boolean)
    var
        WhseRqst: Record "Whse. Pick Request";
    begin
        with ProdOrderComp do begin
            WhsePickRqst.SetRange("Document Type", WhseRqst."Document Type"::Production);
            WhsePickRqst.SetRange("Document No.", "Prod. Order No.");
            if not DeleteAllWhsePickRqst then begin
                WhsePickRqst.SetRange("Document Subtype", Status);
                WhsePickRqst.SetRange("Location Code", "Location Code");
            end;
            if not WhsePickRqst.IsEmpty() then
                WhsePickRqst.DeleteAll(true);
        end;
    end;

    local procedure DeleteWhseRqst(ProdOrderComp: Record "Prod. Order Component"; DeleteAllWhseRqst: Boolean)
    var
        WhseRqst: Record "Warehouse Request";
    begin
        with ProdOrderComp do begin
            if not DeleteAllWhseRqst then
                case true of
                    "Remaining Quantity" > 0:
                        WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
                    "Remaining Quantity" < 0:
                        WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
                    "Remaining Quantity" = 0:
                        exit;
                end;
            WhseRqst.SetRange("Source Type", DATABASE::"Prod. Order Component");
            WhseRqst.SetRange("Source No.", "Prod. Order No.");
            if not DeleteAllWhseRqst then begin
                WhseRqst.SetRange("Source Subtype", Status);
                WhseRqst.SetRange("Location Code", "Location Code");
            end;
            if not WhseRqst.IsEmpty() then
                WhseRqst.DeleteAll(true);
        end;
    end;

    procedure FinishedDelete(var ProdOrder: Record "Production Order")
    begin
        with ProdOrder do begin
            ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Location Code");
            ProdOrderComp.SetRange(Status, Status);
            ProdOrderComp.SetRange("Prod. Order No.", "No.");
            if ProdOrderComp.Find('-') then begin
                DeleteWhsePickRqst(ProdOrderComp, true);
                DeleteWhseRqst(ProdOrderComp, true);
            end;
        end;
    end;

    local procedure ProdOrderCompletelyPicked(LocationCode: Code[10]; ProdOrderNo: Code[20]; ProdOrderStatus: Enum "Production Order Status"; CompLineNo: Integer): Boolean
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Location Code");
        ProdOrderComp.SetRange(Status, ProdOrderStatus);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComp.SetRange("Location Code", LocationCode);
        ProdOrderComp.SetFilter("Line No.", '<>%1', CompLineNo);
        ProdOrderComp.SetRange("Flushing Method", ProdOrderComp."Flushing Method"::Manual);
        ProdOrderComp.SetRange("Planning Level Code", 0);
        ProdOrderComp.SetRange("Completely Picked", false);
        exit(not ProdOrderComp.FindFirst);
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
        exit(not ProdOrderComp.FindFirst);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode <> Location.Code then begin
            if LocationCode = '' then begin
                Location.GetLocationSetup(LocationCode, Location);
                Location.Code := '';
            end else
                Location.Get(LocationCode);
        end;
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

