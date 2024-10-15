namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Request;

codeunit 904 "Whse.-Assembly Release"
{

    trigger OnRun()
    begin
    end;

    var
        WhseRqst: Record "Warehouse Request";
        WhsePickRqst: Record "Whse. Pick Request";

    procedure Release(AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        LocationOutput: Record Location;
        OldLocationCode: Code[10];
        First: Boolean;
    begin
        if AssemblyHeader."Location Code" <> '' then begin
            LocationOutput.SetLoadFields("Directed Put-away and Pick");
            if LocationOutput.Get(AssemblyHeader."Location Code") then
                if LocationOutput."Directed Put-away and Pick" then
                    AssemblyHeader.TestField("Unit of Measure Code");
        end;

        OldLocationCode := '';
        FilterAssemblyLine(AssemblyLine, AssemblyHeader."Document Type", AssemblyHeader."No.");
        if AssemblyLine.Find('-') then begin
            First := true;
            repeat
                if First or (AssemblyLine."Location Code" <> OldLocationCode) then
                    CreateWhseRqst(AssemblyHeader, AssemblyLine);

                First := false;
                OldLocationCode := AssemblyLine."Location Code";
            until AssemblyLine.Next() = 0;
        end;

        WhseRqst.Reset();
        WhseRqst.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WhseRqst.SetRange(Type, WhseRqst.Type);
        WhseRqst.SetRange("Source Type", DATABASE::"Assembly Line");
        WhseRqst.SetRange("Source Subtype", AssemblyHeader."Document Type");
        WhseRqst.SetRange("Source No.", AssemblyHeader."No.");
        WhseRqst.SetRange("Document Status", AssemblyHeader.Status::Open);
        WhseRqst.DeleteAll(true);
    end;

    procedure Reopen(AssemblyHeader: Record "Assembly Header")
    begin
        if AssemblyHeader."Document Type" = AssemblyHeader."Document Type"::Order then
            WhseRqst.Type := WhseRqst.Type::Outbound;

        WhseRqst.Reset();
        WhseRqst.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WhseRqst.SetRange(Type, WhseRqst.Type);
        WhseRqst.SetRange("Source Type", DATABASE::"Assembly Line");
        WhseRqst.SetRange("Source Subtype", AssemblyHeader."Document Type");
        WhseRqst.SetRange("Source No.", AssemblyHeader."No.");
        WhseRqst.SetRange("Document Status", AssemblyHeader.Status::Released);
        WhseRqst.LockTable();
        if not WhseRqst.IsEmpty() then
            WhseRqst.ModifyAll("Document Status", WhseRqst."Document Status"::Open);

        WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::Assembly);
        WhsePickRqst.SetRange("Document No.", AssemblyHeader."No.");
        WhsePickRqst.SetRange(Status, AssemblyHeader.Status::Released);
        if not WhsePickRqst.IsEmpty() then
            WhsePickRqst.ModifyAll(Status, WhsePickRqst.Status::Open);
    end;

    local procedure CreateWhseRqst(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    var
        AssemblyLine2: Record "Assembly Line";
        Location: Record Location;
    begin
        GetLocation(Location, AssemblyLine."Location Code");
        OnBeforeCreateWhseRqst(AssemblyHeader, AssemblyLine, Location);
        if Location."Asm. Consump. Whse. Handling" = Enum::"Asm. Consump. Whse. Handling"::"No Warehouse Handling" then
            exit;

        AssemblyLine2.Copy(AssemblyLine);
        AssemblyLine2.SetRange("Location Code", AssemblyLine."Location Code");
        AssemblyLine2.SetRange("Unit of Measure Code", '');
        if AssemblyLine2.FindFirst() then
            AssemblyLine2.TestField("Unit of Measure Code");

        case Location."Asm. Consump. Whse. Handling" of
            Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)",
            Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)":
                begin
                    WhsePickRqst.Init();
                    WhsePickRqst."Document Type" := WhsePickRqst."Document Type"::Assembly;
                    WhsePickRqst."Document Subtype" := AssemblyLine."Document Type".AsInteger();
                    WhsePickRqst."Document No." := AssemblyLine."Document No.";
                    WhsePickRqst.Status := WhsePickRqst.Status::Released;
                    WhsePickRqst."Location Code" := AssemblyLine."Location Code";
                    WhsePickRqst."Completely Picked" := AssemblyHeader.CompletelyPicked();
                    if WhsePickRqst."Completely Picked" and (not AssemblyLine.CompletelyPicked()) then
                        WhsePickRqst."Completely Picked" := false;
                    if not WhsePickRqst.Insert() then
                        WhsePickRqst.Modify();
                end;
            Enum::"Asm. Consump. Whse. Handling"::"Inventory Movement":
                begin
                    WhseRqst.Init();
                    case AssemblyHeader."Document Type" of
                        AssemblyHeader."Document Type"::Order:
                            WhseRqst.Type := WhseRqst.Type::Outbound;
                    end;
                    WhseRqst."Source Document" := WhseRqst."Source Document"::"Assembly Consumption";
                    WhseRqst."Source Type" := DATABASE::"Assembly Line";
                    WhseRqst."Source Subtype" := AssemblyLine."Document Type".AsInteger();
                    WhseRqst."Source No." := AssemblyLine."Document No.";
                    WhseRqst."Document Status" := WhseRqst."Document Status"::Released;
                    WhseRqst."Location Code" := AssemblyLine."Location Code";
                    WhseRqst."Destination Type" := WhseRqst."Destination Type"::Item;
                    WhseRqst."Destination No." := AssemblyHeader."Item No.";
                    WhseRqst."Completely Handled" := AssemblyCompletelyHandled(AssemblyHeader, AssemblyLine."Location Code");
                    OnBeforeWhseRequestInsert(WhseRqst, AssemblyLine, AssemblyHeader);
                    if not WhseRqst.Insert() then
                        WhseRqst.Modify();
                end;
        end;
    end;

    local procedure GetLocation(var Location: Record Location; LocationCode: Code[10])
    begin
        if LocationCode <> Location.Code then
            if LocationCode = '' then begin
                Location.GetLocationSetup(LocationCode, Location);
                Location.Code := '';
            end else
                Location.Get(LocationCode);
    end;

    local procedure FilterAssemblyLine(var AssemblyLine: Record "Assembly Line"; DocumentType: Enum "Assembly Document Type"; DocumentNo: Code[20])
    begin
        AssemblyLine.SetCurrentKey("Document Type", "Document No.", Type, "Location Code");
        AssemblyLine.SetRange("Document Type", DocumentType);
        AssemblyLine.SetRange("Document No.", DocumentNo);
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
    end;

    local procedure AssemblyCompletelyHandled(AssemblyHeader: Record "Assembly Header"; LocationCode: Code[10]): Boolean
    var
        AssemblyLine: Record "Assembly Line";
    begin
        FilterAssemblyLine(AssemblyLine, AssemblyHeader."Document Type", AssemblyHeader."No.");
        AssemblyLine.SetRange("Location Code", LocationCode);
        AssemblyLine.SetFilter("Remaining Quantity", '<>0');
        exit(AssemblyLine.IsEmpty());
    end;

    procedure DeleteLine(AssemblyLine: Record "Assembly Line")
    var
        AssemblyLine2: Record "Assembly Line";
        Location: Record Location;
        KeepWhseRqst: Boolean;
    begin
        if AssemblyLine.Type <> AssemblyLine.Type::Item then
            exit;

        KeepWhseRqst := false;
        if Location.Get(AssemblyLine."Location Code") then;
        FilterAssemblyLine(AssemblyLine2, AssemblyLine."Document Type", AssemblyLine."Document No.");
        AssemblyLine2.SetFilter("Line No.", '<>%1', AssemblyLine."Line No.");
        AssemblyLine2.SetRange("Location Code", AssemblyLine."Location Code");
        AssemblyLine2.SetFilter("Remaining Quantity", '<>0');
        if AssemblyLine2.Find('-') then
            // Other lines for same location exist in the order.
            repeat
                if (not AssemblyLine2.CompletelyPicked()) or
                    (Location."Asm. Consump. Whse. Handling" <> Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)")
                then
                    KeepWhseRqst := true; // if lines are incompletely picked.
            until (AssemblyLine2.Next() = 0) or KeepWhseRqst;

        OnDeleteLineOnBeforeDeleteWhseRqst(AssemblyLine2, KeepWhseRqst);

        if not KeepWhseRqst then
            if Location."Asm. Consump. Whse. Handling" in [Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)"] then
                DeleteWhsePickRqst(AssemblyLine, false)
            else
                DeleteWhseRqst(AssemblyLine, false);
    end;

    local procedure DeleteWhsePickRqst(AssemblyLine: Record "Assembly Line"; DeleteAllWhsePickRqst: Boolean)
    begin
        WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::Assembly);
        WhsePickRqst.SetRange("Document No.", AssemblyLine."Document No.");
        if not DeleteAllWhsePickRqst then begin
            WhsePickRqst.SetRange("Document Subtype", AssemblyLine."Document Type");
            WhsePickRqst.SetRange("Location Code", AssemblyLine."Location Code");
        end;
        if not WhsePickRqst.IsEmpty() then
            WhsePickRqst.DeleteAll(true);
    end;

    local procedure DeleteWhseRqst(AssemblyLine: Record "Assembly Line"; DeleteAllWhseRqst: Boolean)
    var
        WhseRqst2: Record "Warehouse Request";
    begin
        if not DeleteAllWhseRqst then
            case true of
                AssemblyLine."Remaining Quantity" > 0:
                    WhseRqst2.SetRange(Type, WhseRqst2.Type::Outbound);
                AssemblyLine."Remaining Quantity" < 0:
                    WhseRqst2.SetRange(Type, WhseRqst2.Type::Inbound);
                AssemblyLine."Remaining Quantity" = 0:
                    exit;
            end;
        WhseRqst2.SetRange("Source Type", DATABASE::"Assembly Line");
        WhseRqst2.SetRange("Source No.", AssemblyLine."Document No.");
        if not DeleteAllWhseRqst then begin
            WhseRqst2.SetRange("Source Subtype", AssemblyLine."Document Type");
            WhseRqst2.SetRange("Location Code", AssemblyLine."Location Code");
        end;
        if not WhseRqst2.IsEmpty() then
            WhseRqst2.DeleteAll(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseRqst(AssemblyHeader: Record "Assembly Header"; AssemblyLine: Record "Assembly Line"; var Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteLineOnBeforeDeleteWhseRqst(var AssemblyLine: Record "Assembly Line"; var KeepWhseRequest: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseRequestInsert(var WarehouseRequest: Record "Warehouse Request"; AssemblyLine: Record "Assembly Line"; AssemblyHeader: Record "Assembly Header")
    begin
    end;
}

