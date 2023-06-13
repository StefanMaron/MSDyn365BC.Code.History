codeunit 7310 "Whse.-Shipment Release"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'There is nothing to release for %1 %2.';
        Text001: Label 'You cannot reopen the shipment because warehouse worksheet lines exist that must first be handled or deleted.';
        Text002: Label 'You cannot reopen the shipment because warehouse activity lines exist that must first be handled or deleted.';
        SuppressCommit: Boolean;

    procedure Release(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        Location: Record Location;
        Location2: Record Location;
        WhsePickRqst: Record "Whse. Pick Request";
        WhseShptLine: Record "Warehouse Shipment Line";
        ATOLink: Record "Assemble-to-Order Link";
        AsmLine: Record "Assembly Line";
    begin
        with WhseShptHeader do begin
            if Status = Status::Released then
                exit;

            OnBeforeRelease(WhseShptHeader);

            WhseShptLine.SetRange("No.", "No.");
            WhseShptLine.SetFilter(Quantity, '<>0');

            CheckWhseShptLinesNotEmpty(WhseShptHeader, WhseShptLine);

            if "Location Code" <> '' then
                Location.Get("Location Code");

            repeat
                WhseShptLine.TestField("Item No.");
                WhseShptLine.TestField("Unit of Measure Code");
                OnReleaseOnAfterWhseShptLineTestField(WhseShptLine, Location);
                if Location."Directed Put-away and Pick" then
                    WhseShptLine.TestField("Zone Code");
                if Location."Bin Mandatory" then begin
                    WhseShptLine.TestField("Bin Code");
                    if WhseShptLine."Assemble to Order" then begin
                        ATOLink.AsmExistsForWhseShptLine(WhseShptLine);
                        AsmLine.SetCurrentKey("Document Type", "Document No.", Type);
                        AsmLine.SetRange("Document Type", ATOLink."Assembly Document Type");
                        AsmLine.SetRange("Document No.", ATOLink."Assembly Document No.");
                        AsmLine.SetRange(Type, AsmLine.Type::Item);
                        if AsmLine.FindSet() then
                            repeat
                                if AsmLine."Location Code" = Location.Code then
                                    Location2 := Location
                                else
                                    if (AsmLine."Location Code" <> '') and (Location2.Code <> AsmLine."Location Code") then
                                        Location2.Get(AsmLine."Location Code");

                                if (AsmLine."Location Code" <> '') and Location2."Bin Mandatory" then
                                    if AsmLine.IsInventoriableItem() then
                                        if AsmLine.CalcQtyToPickBase() > 0 then
                                            AsmLine.TestField("Bin Code");
                            until AsmLine.Next() = 0;
                    end;
                end;
            until WhseShptLine.Next() = 0;

            OnAfterTestWhseShptLine(WhseShptHeader, WhseShptLine);

            Status := Status::Released;
            Modify();

            OnAfterReleaseWarehouseShipment(WhseShptHeader);

            CreateWhsePickRequest(WhseShptHeader);

            WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::Shipment);
            WhsePickRqst.SetRange("Document No.", "No.");
            WhsePickRqst.SetRange(Status, Status::Open);
            if not WhsePickRqst.IsEmpty() then
                WhsePickRqst.DeleteAll(true);
            if not SuppressCommit then
                Commit();
        end;

        OnAfterRelease(WhseShptHeader, WhseShptLine);
    end;

    procedure Reopen(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhsePickRqst: Record "Whse. Pick Request";
        PickWkshLine: Record "Whse. Worksheet Line";
        WhseActivLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        with WhseShptHeader do begin
            if Status = Status::Open then
                exit;

            IsHandled := false;
            OnBeforeReopen(WhseShptHeader, IsHandled);
            if IsHandled then
                exit;

            PickWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.");
            PickWkshLine.SetRange("Whse. Document Type", PickWkshLine."Whse. Document Type"::Shipment);
            PickWkshLine.SetRange("Whse. Document No.", "No.");
            if not PickWkshLine.IsEmpty() then
                Error(Text001);

            WhseActivLine.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type");
            WhseActivLine.SetRange("Whse. Document No.", "No.");
            WhseActivLine.SetRange("Whse. Document Type", WhseActivLine."Whse. Document Type"::Shipment);
            WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
            if not WhseActivLine.IsEmpty() then
                Error(Text002);

            WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::Shipment);
            WhsePickRqst.SetRange("Document No.", "No.");
            WhsePickRqst.SetRange(Status, Status::Released);
            if not WhsePickRqst.IsEmpty() then
                WhsePickRqst.ModifyAll(Status, WhsePickRqst.Status::Open);

            Status := Status::Open;
            Modify();
        end;

        OnAfterReopen(WhseShptHeader);
    end;

    local procedure CreateWhsePickRequest(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhsePickRequest: Record "Whse. Pick Request";
        Location: Record Location;
    begin
        with WhseShptHeader do
            if Location.RequirePicking("Location Code") then begin
                WhsePickRequest."Document Type" := WhsePickRequest."Document Type"::Shipment;
                WhsePickRequest."Document No." := "No.";
                WhsePickRequest.Status := Status;
                WhsePickRequest."Location Code" := "Location Code";
                WhsePickRequest."Zone Code" := "Zone Code";
                WhsePickRequest."Bin Code" := "Bin Code";
                CalcFields("Completely Picked");
                WhsePickRequest."Completely Picked" := "Completely Picked";
                WhsePickRequestInsert(WhsePickRequest, WhseShptHeader);
            end;
    end;

    local procedure WhsePickRequestInsert(var WhsePickRequest: Record "Whse. Pick Request"; var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWhsePickRequestInsert(WhsePickRequest, WhseShptHeader, IsHandled);
        if IsHandled then
            exit;

        if not WhsePickRequest.Insert() then
            WhsePickRequest.Modify();
        OnAfterWhsePickRequestInsert(WhsePickRequest);
    end;

    local procedure CheckWhseShptLinesNotEmpty(WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCheckWhseShptLinesNotEmpty(WhseShptHeader, WhseShptLine, IsHandled);
        if IsHandled then
            exit;

        if not WhseShptLine.Find('-') then
            Error(Text000, WhseShptHeader.TableCaption(), WhseShptHeader."No.");
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelease(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopen(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestWhseShptLine(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhsePickRequestInsert(var WhsePickRequest: Record "Whse. Pick Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRelease(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopen(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhsePickRequestInsert(var WhsePickRequest: Record "Whse. Pick Request"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseShptLinesNotEmpty(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseOnAfterWhseShptLineTestField(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; Location: Record Location)
    begin
    end;
}

