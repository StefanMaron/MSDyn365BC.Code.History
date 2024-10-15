namespace Microsoft.Warehouse.InternalDocument;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Worksheet;

codeunit 7315 "Whse. Internal Pick Release"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'There is nothing to release for %1 %2.';
#pragma warning restore AA0470
        Text001: Label 'You cannot reopen the whse. internal pick because warehouse worksheet lines exist that must first be handled or deleted.';
        Text002: Label 'You cannot reopen the whse. internal pick because warehouse activity lines exist that must first be handled or deleted.';
#pragma warning restore AA0074

    procedure Release(var WhsePickHeader: Record "Whse. Internal Pick Header")
    var
        Location: Record Location;
        WhsePickRqst: Record "Whse. Pick Request";
        WhsePickLine: Record "Whse. Internal Pick Line";
    begin
        if WhsePickHeader.Status = WhsePickHeader.Status::Released then
            exit;

        OnBeforeRelease(WhsePickHeader);

        WhsePickLine.SetRange("No.", WhsePickHeader."No.");
        WhsePickLine.SetFilter(Quantity, '<>0');
        if not WhsePickLine.Find('-') then
            Error(Text000, WhsePickHeader.TableCaption(), WhsePickHeader."No.");

        if WhsePickHeader."Location Code" <> '' then begin
            Location.Get(WhsePickHeader."Location Code");
            Location.TestField("Require Pick");
        end else
            WhsePickHeader.CheckPickRequired(WhsePickHeader."Location Code");

        repeat
            WhsePickLine.TestField("Item No.");
            WhsePickLine.TestField("Unit of Measure Code");
            if Location."Directed Put-away and Pick" then
                WhsePickLine.TestField("To Zone Code");
            if Location."Bin Mandatory" then
                WhsePickLine.TestField("To Bin Code");
        until WhsePickLine.Next() = 0;

        OnAfterTestWhsePickLine(WhsePickHeader, WhsePickLine);

        WhsePickHeader.Status := WhsePickHeader.Status::Released;
        WhsePickHeader.Modify();

        OnAfterReleaseWarehousePick(WhsePickHeader);

        CreateWhsePickRqst(WhsePickHeader);

        WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::"Internal Pick");
        WhsePickRqst.SetRange("Document No.", WhsePickHeader."No.");
        WhsePickRqst.SetRange(Status, WhsePickHeader.Status::Open);
        if not WhsePickRqst.IsEmpty() then
            WhsePickRqst.DeleteAll(true);

        Commit();

        OnAfterRelease(WhsePickHeader, WhsePickLine);
    end;

    procedure Reopen(WhsePickHeader: Record "Whse. Internal Pick Header")
    var
        WhsePickRqst: Record "Whse. Pick Request";
        PickWkshLine: Record "Whse. Worksheet Line";
        WhseActivLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        if WhsePickHeader.Status = WhsePickHeader.Status::Open then
            exit;

        IsHandled := false;
        OnBeforeReopen(WhsePickHeader, IsHandled);
        if IsHandled then
            exit;

        PickWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.");
        PickWkshLine.SetRange("Whse. Document Type", PickWkshLine."Whse. Document Type"::"Internal Pick");
        PickWkshLine.SetRange("Whse. Document No.", WhsePickHeader."No.");
        if not PickWkshLine.IsEmpty() then
            Error(Text001);

        WhseActivLine.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type");
        WhseActivLine.SetRange("Whse. Document No.", WhsePickHeader."No.");
        WhseActivLine.SetRange("Whse. Document Type", WhseActivLine."Whse. Document Type"::"Internal Pick");
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        if not WhseActivLine.IsEmpty() then
            Error(Text002);

        WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::"Internal Pick");
        WhsePickRqst.SetRange("Document No.", WhsePickHeader."No.");
        WhsePickRqst.SetRange(Status, WhsePickHeader.Status::Released);
        if not WhsePickRqst.IsEmpty() then
            WhsePickRqst.ModifyAll(Status, WhsePickRqst.Status::Open);

        WhsePickHeader.Status := WhsePickHeader.Status::Open;
        WhsePickHeader.Modify();

        OnAfterReopen(WhsePickHeader);
    end;

    local procedure CreateWhsePickRqst(var WhsePickHeader: Record "Whse. Internal Pick Header")
    var
        WhsePickRqst: Record "Whse. Pick Request";
        Location: Record Location;
    begin
        if Location.RequirePicking(WhsePickHeader."Location Code") then begin
            WhsePickRqst."Document Type" := WhsePickRqst."Document Type"::"Internal Pick";
            WhsePickRqst."Document No." := WhsePickHeader."No.";
            WhsePickRqst.Status := WhsePickHeader.Status;
            WhsePickRqst."Location Code" := WhsePickHeader."Location Code";
            WhsePickRqst."Zone Code" := WhsePickHeader."To Zone Code";
            WhsePickRqst."Bin Code" := WhsePickHeader."To Bin Code";
            WhsePickHeader."Document Status" := WhsePickHeader.GetDocumentStatus(0);
            WhsePickRqst."Completely Picked" :=
              WhsePickHeader."Document Status" = WhsePickHeader."Document Status"::"Completely Picked";
            if not WhsePickRqst.Insert() then
                WhsePickRqst.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRelease(var WhseInternalPickHeader: Record "Whse. Internal Pick Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelease(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; var WhseInternalPickLine: Record "Whse. Internal Pick Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopen(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopen(var WhseInternalPickHeader: Record "Whse. Internal Pick Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestWhsePickLine(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; var WhseInternalPickLine: Record "Whse. Internal Pick Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseWarehousePick(var WhseInternalPickHeader: Record "Whse. Internal Pick Header")
    begin
    end;
}

