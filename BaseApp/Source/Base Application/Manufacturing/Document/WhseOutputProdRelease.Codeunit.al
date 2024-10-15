namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Request;

codeunit 7325 "Whse.-Output Prod. Release"
{
    trigger OnRun()
    begin
    end;

    var
        Location: Record Location;
        WhseRqst: Record "Warehouse Request";
        ProdOrderLine: Record "Prod. Order Line";
        WhseRqstCreated: Boolean;

    procedure Release(ProdHeader: Record "Production Order"): Boolean
    var
        LocationCode2: Code[10];
    begin
        WhseRqstCreated := false;
        if ProdHeader.Status <> ProdHeader.Status::Released then
            exit;

        OnBeforeRelease(ProdHeader);
        LocationCode2 := '';
        with ProdHeader do begin
            ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.");
            ProdOrderLine.SetRange(Status, Status);
            ProdOrderLine.SetRange("Prod. Order No.", "No.");
            if ProdOrderLine.Find('-') then
                repeat
                    if ProdOrderLine."Location Code" <> LocationCode2 then
                        CreateWhseRqst(ProdOrderLine, ProdHeader);
                    LocationCode2 := ProdOrderLine."Location Code";
                until ProdOrderLine.Next() = 0;
        end;
        exit(WhseRqstCreated);
    end;

    local procedure CreateWhseRqst(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrder: Record "Production Order")
    var
        ProdOrderLine2: Record "Prod. Order Line";
    begin
        GetLocation(ProdOrderLine."Location Code");
        if Location.Code <> '' then
            if Location."Prod. Output Whse. Handling" <> Location."Prod. Output Whse. Handling"::"Inventory Put-away" then
                exit;

        ProdOrderLine2.Copy(ProdOrderLine);
        ProdOrderLine2.SetRange("Location Code", ProdOrderLine."Location Code");
        ProdOrderLine2.SetRange("Unit of Measure Code", '');
        if ProdOrderLine2.FindFirst() then
            ProdOrderLine2.TestField("Unit of Measure Code");

        WhseRqst.Init();
        WhseRqst.Type := WhseRqst.Type::Inbound;
        WhseRqst."Location Code" := ProdOrderLine."Location Code";
        WhseRqst."Source Type" := Database::"Prod. Order Line";
        WhseRqst."Source No." := ProdOrderLine."Prod. Order No.";
        WhseRqst."Source Subtype" := ProdOrderLine.Status;
        WhseRqst."Source Document" := WhseRqst."Source Document"::"Prod. Output";
        WhseRqst."Document Status" := WhseRqst."Document Status"::Released;
        WhseRqst."Completely Handled" := ProdOrderCompletelyHandled(ProdOrder, ProdOrderLine."Location Code");
        WhseRqst.SetDestinationType(ProdOrder);
        OnBeforeWhseRequestInsert(WhseRqst, ProdOrderLine, ProdOrder);
        if not WhseRqst.Insert() then
            WhseRqst.Modify();

        WhseRqstCreated := true;

        OnAfterCreateWhseRqst(ProdOrder, ProdOrderLine, WhseRqst);
    end;

    procedure DeleteLine(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderLine2: Record "Prod. Order Line";
        KeepWhseRqst: Boolean;
    begin
        with ProdOrderLine do begin
            KeepWhseRqst := false;
            GetLocation(ProdOrderLine2."Location Code");
            if (Location."Prod. Output Whse. Handling" = Location."Prod. Output Whse. Handling"::"Inventory Put-away") and (not Location."Directed Put-away and Pick") then begin
                ProdOrderLine2.Reset();
                ProdOrderLine2.SetRange(Status, Status);
                ProdOrderLine2.SetRange("Prod. Order No.", "Prod. Order No.");
                ProdOrderLine2.SetRange("Location Code", "Location Code");
                if ProdOrderLine2.Find('-') then
                    repeat
                        if ((ProdOrderLine2.Status <> Status) or
                            (ProdOrderLine2."Prod. Order No." <> "Prod. Order No.") or
                            (ProdOrderLine2."Line No." <> "Line No.")) and
                           (ProdOrderLine2."Remaining Quantity" <> 0)
                        then
                            KeepWhseRqst := true;
                    until (ProdOrderLine2.Next() = 0) or KeepWhseRqst;
            end;

            if not KeepWhseRqst then
                DeleteWhseRqst(ProdOrderLine, false);
        end;

        OnAfterDeleteLine(ProdOrderLine, KeepWhseRqst);
    end;

    local procedure DeleteWhseRqst(ProdOrderLine: Record "Prod. Order Line"; DeleteAllWhseRqst: Boolean)
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        with ProdOrderLine do begin
            WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
            WarehouseRequest.SetRange("Source Type", Database::"Prod. Order Line");
            WarehouseRequest.SetRange("Source No.", "Prod. Order No.");
            if not DeleteAllWhseRqst then begin
                WarehouseRequest.SetRange("Source Subtype", Status);
                WarehouseRequest.SetRange("Location Code", "Location Code");
            end;
            WarehouseRequest.DeleteAll(true);
        end;
    end;

    procedure FinishedDelete(var ProdHeader: Record "Production Order")
    begin
        with ProdHeader do begin
            ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.");
            ProdOrderLine.SetRange(Status, Status);
            ProdOrderLine.SetRange("Prod. Order No.", "No.");
            if ProdOrderLine.Find('-') then
                DeleteWhseRqst(ProdOrderLine, true);
        end;
    end;

    local procedure ProdOrderCompletelyHandled(ProdOrder: Record "Production Order"; LocationCode: Code[10]): Boolean
    var
        ProdOrderLine2: Record "Prod. Order Line";
    begin
        ProdOrderLine2.SetRange(Status, ProdOrder.Status);
        ProdOrderLine2.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine2.SetRange("Location Code", LocationCode);
        ProdOrderLine2.SetFilter("Remaining Quantity", '<>0');
        exit(ProdOrderLine2.IsEmpty());
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode <> Location.Code then
            if LocationCode = '' then
                Location.GetLocationSetup(LocationCode, Location)
            else
                Location.Get(LocationCode);
    end;

    procedure CheckWhseRqst(ProductionOrder: Record "Production Order"): Boolean
    var
        ProdOrderLine2: Record "Prod. Order Line";
    begin
        WhseRqstCreated := true;
        with ProductionOrder do begin
            ProdOrderLine2.SetCurrentKey(Status, "Prod. Order No.");
            ProdOrderLine2.SetRange(Status, Status);
            ProdOrderLine2.SetRange("Prod. Order No.", "No.");
            if ProdOrderLine2.Find('-') then
                repeat
                    GetLocation(ProdOrderLine2."Location Code");
                    if Location.Code <> '' then
                        if Location."Prod. Output Whse. Handling" <> Location."Prod. Output Whse. Handling"::"Inventory Put-away" then
                            WhseRqstCreated := false
                        else
                            if not WhseRqst.Get(
                                 WhseRqst.Type::Inbound,
                                 ProdOrderLine2."Location Code",
                                 Database::"Prod. Order Line",
                                 ProdOrderLine2.Status,
                                 ProdOrderLine2."Prod. Order No.")
                            then
                                WhseRqstCreated := false;
                    OnAfterCheckWhseRqstProdOrderLine(ProdOrderLine2, WhseRqst, WhseRqstCreated);
                until (ProdOrderLine2.Next() = 0) or not WhseRqstCreated;
        end;
        exit(WhseRqstCreated);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseRqstProdOrderLine(ProdOrderLine: Record "Prod. Order Line"; WhseRequest: Record "Warehouse Request"; var WhseRequestCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseRqst(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteLine(ProdOrderLine: Record "Prod. Order Line"; KeepWhseRqst: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRelease(var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseRequestInsert(var WarehouseRequest: Record "Warehouse Request"; ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
    end;
}

