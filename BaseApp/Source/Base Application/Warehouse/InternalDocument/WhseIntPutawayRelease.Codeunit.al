namespace Microsoft.Warehouse.InternalDocument;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Worksheet;

codeunit 7316 "Whse. Int. Put-away Release"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'There is nothing to release for %1 %2.';
#pragma warning restore AA0470
        Text001: Label 'You cannot reopen the whse. internal put-away because warehouse worksheet lines exist that must first be handled or deleted.';
        Text002: Label 'You cannot reopen the whse. internal put-away because warehouse activity lines exist that must first be handled or deleted.';
#pragma warning restore AA0074

    procedure Release(WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header")
    var
        Location: Record Location;
        WhsePutawayRqst: Record "Whse. Put-away Request";
        WhseInternalPutawayLine: Record "Whse. Internal Put-away Line";
    begin
        if WhseInternalPutAwayHeader.Status = WhseInternalPutAwayHeader.Status::Released then
            exit;

        WhseInternalPutawayLine.SetRange("No.", WhseInternalPutAwayHeader."No.");
        WhseInternalPutawayLine.SetFilter(Quantity, '<>0');
        if not WhseInternalPutawayLine.Find('-') then
            Error(Text000, WhseInternalPutAwayHeader.TableCaption(), WhseInternalPutAwayHeader."No.");

        if WhseInternalPutAwayHeader."Location Code" <> '' then begin
            Location.Get(WhseInternalPutAwayHeader."Location Code");
            Location.TestField("Require Put-away");
        end else
            WhseInternalPutAwayHeader.CheckPutawayRequired(WhseInternalPutAwayHeader."Location Code");

        repeat
            WhseInternalPutawayLine.TestField("Item No.");
            WhseInternalPutawayLine.TestField("Unit of Measure Code");
            if Location."Directed Put-away and Pick" then
                WhseInternalPutawayLine.TestField("From Zone Code");
            if Location."Bin Mandatory" then
                WhseInternalPutawayLine.TestField("From Bin Code");
        until WhseInternalPutawayLine.Next() = 0;

        WhseInternalPutAwayHeader.Status := WhseInternalPutAwayHeader.Status::Released;
        WhseInternalPutAwayHeader.Modify();

        CreateWhsePutawayRqst(WhseInternalPutAwayHeader);

        WhsePutawayRqst.SetRange(
          "Document Type", WhsePutawayRqst."Document Type"::"Internal Put-away");
        WhsePutawayRqst.SetRange("Document No.", WhseInternalPutAwayHeader."No.");
        WhsePutawayRqst.SetRange(Status, WhseInternalPutAwayHeader.Status::Open);
        WhsePutawayRqst.DeleteAll(true);

        Commit();
    end;

    procedure Reopen(WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header")
    var
        WhsePutawayRqst: Record "Whse. Put-away Request";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        if WhseInternalPutAwayHeader.Status = WhseInternalPutAwayHeader.Status::Open then
            exit;

        WhseWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.");
        WhseWkshLine.SetRange("Whse. Document Type", WhseWkshLine."Whse. Document Type"::"Internal Put-away");
        WhseWkshLine.SetRange("Whse. Document No.", WhseInternalPutAwayHeader."No.");
        if not WhseWkshLine.IsEmpty() then
            Error(Text001);

        WhseActivLine.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type");
        WhseActivLine.SetRange("Whse. Document No.", WhseInternalPutAwayHeader."No.");
        WhseActivLine.SetRange("Whse. Document Type", WhseActivLine."Whse. Document Type"::"Internal Put-away");
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Put-away");
        OnReopenOnBeforeWhseActivLineIsEmpty(WhseInternalPutAwayHeader, WhseActivLine);
        if not WhseActivLine.IsEmpty() then
            Error(Text002);

        WhsePutawayRqst.SetRange("Document Type", WhsePutawayRqst."Document Type"::"Internal Put-away");
        WhsePutawayRqst.SetRange("Document No.", WhseInternalPutAwayHeader."No.");
        WhsePutawayRqst.SetRange(Status, WhseInternalPutAwayHeader.Status::Released);
        if WhsePutawayRqst.Find('-') then
            repeat
                WhsePutawayRqst.Status := WhseInternalPutAwayHeader.Status::Open;
                WhsePutawayRqst.Modify();
            until WhsePutawayRqst.Next() = 0;

        WhseInternalPutAwayHeader.Status := WhseInternalPutAwayHeader.Status::Open;
        WhseInternalPutAwayHeader.Modify();
    end;

    local procedure CreateWhsePutawayRqst(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header")
    var
        WhsePutawayRqst: Record "Whse. Put-away Request";
    begin
        WhsePutawayRqst."Document Type" := WhsePutawayRqst."Document Type"::"Internal Put-away";
        WhsePutawayRqst."Document No." := WhseInternalPutAwayHeader."No.";
        WhsePutawayRqst.Status := WhseInternalPutAwayHeader.Status;
        WhsePutawayRqst."Location Code" := WhseInternalPutAwayHeader."Location Code";
        WhsePutawayRqst."Zone Code" := WhseInternalPutAwayHeader."From Zone Code";
        WhsePutawayRqst."Bin Code" := WhseInternalPutAwayHeader."From Bin Code";
        WhseInternalPutAwayHeader."Document Status" := WhseInternalPutAwayHeader.GetDocumentStatus(0);
        WhsePutawayRqst."Completely Put Away" :=
          WhseInternalPutAwayHeader."Document Status" = WhseInternalPutAwayHeader."Document Status"::"Completely Put Away";
        if not WhsePutawayRqst.Insert() then
            WhsePutawayRqst.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReopenOnBeforeWhseActivLineIsEmpty(WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;
}

