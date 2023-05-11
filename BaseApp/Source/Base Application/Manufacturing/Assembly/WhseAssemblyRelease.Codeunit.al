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
        with AssemblyHeader do begin
            FilterAssemblyLine(AssemblyLine, "Document Type", "No.");
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
            WhseRqst.SetRange("Source Subtype", "Document Type");
            WhseRqst.SetRange("Source No.", "No.");
            WhseRqst.SetRange("Document Status", Status::Open);
            WhseRqst.DeleteAll(true);
        end;
    end;

    procedure Reopen(AssemblyHeader: Record "Assembly Header")
    begin
        with AssemblyHeader do begin
            if "Document Type" = "Document Type"::Order then
                WhseRqst.Type := WhseRqst.Type::Outbound;

            WhseRqst.Reset();
            WhseRqst.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
            WhseRqst.SetRange(Type, WhseRqst.Type);
            WhseRqst.SetRange("Source Type", DATABASE::"Assembly Line");
            WhseRqst.SetRange("Source Subtype", "Document Type");
            WhseRqst.SetRange("Source No.", "No.");
            WhseRqst.SetRange("Document Status", Status::Released);
            WhseRqst.LockTable();
            if not WhseRqst.IsEmpty() then
                WhseRqst.ModifyAll("Document Status", WhseRqst."Document Status"::Open);

            WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::Assembly);
            WhsePickRqst.SetRange("Document No.", "No.");
            WhsePickRqst.SetRange(Status, Status::Released);
            if not WhsePickRqst.IsEmpty() then
                WhsePickRqst.ModifyAll(Status, WhsePickRqst.Status::Open);
        end;
    end;

    local procedure CreateWhseRqst(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    var
        AssemblyLine2: Record "Assembly Line";
        Location: Record Location;
    begin
        GetLocation(Location, AssemblyLine."Location Code");
        OnBeforeCreateWhseRqst(AssemblyHeader, AssemblyLine, Location);
        if not Location."Require Pick" then
            exit;

        AssemblyLine2.Copy(AssemblyLine);
        AssemblyLine2.SetRange("Location Code", AssemblyLine."Location Code");
        AssemblyLine2.SetRange("Unit of Measure Code", '');
        if AssemblyLine2.FindFirst() then
            AssemblyLine2.TestField("Unit of Measure Code");

        if Location."Require Shipment" then begin
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
        end else begin
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
        exit(not AssemblyLine.Find('-'));
    end;

    procedure DeleteLine(AssemblyLine: Record "Assembly Line")
    var
        AssemblyLine2: Record "Assembly Line";
        Location: Record Location;
        KeepWhseRqst: Boolean;
    begin
        with AssemblyLine do begin
            if Type <> Type::Item then
                exit;
            KeepWhseRqst := false;
            if Location.Get("Location Code") then;
            FilterAssemblyLine(AssemblyLine2, "Document Type", "Document No.");
            AssemblyLine2.SetFilter("Line No.", '<>%1', "Line No.");
            AssemblyLine2.SetRange("Location Code", "Location Code");
            AssemblyLine2.SetFilter("Remaining Quantity", '<>0');
            if AssemblyLine2.Find('-') then
                // Other lines for same location exist in the order.
                repeat
                    if (not AssemblyLine2.CompletelyPicked()) or
                       (not (Location."Require Pick" and Location."Require Shipment"))
                    then
                        KeepWhseRqst := true; // if lines are incompletely picked.
                until (AssemblyLine2.Next() = 0) or KeepWhseRqst;

            OnDeleteLineOnBeforeDeleteWhseRqst(AssemblyLine2, KeepWhseRqst);

            if not KeepWhseRqst then
                if Location."Require Shipment" then
                    DeleteWhsePickRqst(AssemblyLine, false)
                else
                    DeleteWhseRqst(AssemblyLine, false);
        end;
    end;

    local procedure DeleteWhsePickRqst(AssemblyLine: Record "Assembly Line"; DeleteAllWhsePickRqst: Boolean)
    begin
        with AssemblyLine do begin
            WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::Assembly);
            WhsePickRqst.SetRange("Document No.", "Document No.");
            if not DeleteAllWhsePickRqst then begin
                WhsePickRqst.SetRange("Document Subtype", "Document Type");
                WhsePickRqst.SetRange("Location Code", "Location Code");
            end;
            if not WhsePickRqst.IsEmpty() then
                WhsePickRqst.DeleteAll(true);
        end;
    end;

    local procedure DeleteWhseRqst(AssemblyLine: Record "Assembly Line"; DeleteAllWhseRqst: Boolean)
    var
        WhseRqst: Record "Warehouse Request";
    begin
        with AssemblyLine do begin
            if not DeleteAllWhseRqst then
                case true of
                    "Remaining Quantity" > 0:
                        WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
                    "Remaining Quantity" < 0:
                        WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
                    "Remaining Quantity" = 0:
                        exit;
                end;
            WhseRqst.SetRange("Source Type", DATABASE::"Assembly Line");
            WhseRqst.SetRange("Source No.", "Document No.");
            if not DeleteAllWhseRqst then begin
                WhseRqst.SetRange("Source Subtype", "Document Type");
                WhseRqst.SetRange("Location Code", "Location Code");
            end;
            if not WhseRqst.IsEmpty() then
                WhseRqst.DeleteAll(true);
        end;
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

