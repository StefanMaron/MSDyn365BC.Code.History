codeunit 7315 "Whse. Internal Pick Release"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'There is nothing to release for %1 %2.';
        Text001: Label 'You cannot reopen the whse. internal pick because warehouse worksheet lines exist that must first be handled or deleted.';
        Text002: Label 'You cannot reopen the whse. internal pick because warehouse activity lines exist that must first be handled or deleted.';

    procedure Release(var WhsePickHeader: Record "Whse. Internal Pick Header")
    var
        Location: Record Location;
        WhsePickRqst: Record "Whse. Pick Request";
        WhsePickLine: Record "Whse. Internal Pick Line";
    begin
        with WhsePickHeader do begin
            if Status = Status::Released then
                exit;

            WhsePickLine.SetRange("No.", "No.");
            WhsePickLine.SetFilter(Quantity, '<>0');
            if not WhsePickLine.Find('-') then
                Error(Text000, TableCaption, "No.");

            if "Location Code" <> '' then begin
                Location.Get("Location Code");
                Location.TestField("Require Pick");
            end else
                CheckPickRequired("Location Code");

            repeat
                WhsePickLine.TestField("Item No.");
                WhsePickLine.TestField("Unit of Measure Code");
                if Location."Directed Put-away and Pick" then
                    WhsePickLine.TestField("To Zone Code");
                if Location."Bin Mandatory" then
                    WhsePickLine.TestField("To Bin Code");
            until WhsePickLine.Next = 0;

            Status := Status::Released;
            Modify;

            CreateWhsePickRqst(WhsePickHeader);

            WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::"Internal Pick");
            WhsePickRqst.SetRange("Document No.", "No.");
            WhsePickRqst.SetRange(Status, Status::Open);
            if not WhsePickRqst.IsEmpty then
                WhsePickRqst.DeleteAll(true);

            Commit();
        end;
    end;

    procedure Reopen(WhsePickHeader: Record "Whse. Internal Pick Header")
    var
        WhsePickRqst: Record "Whse. Pick Request";
        PickWkshLine: Record "Whse. Worksheet Line";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        with WhsePickHeader do begin
            if Status = Status::Open then
                exit;

            PickWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.");
            PickWkshLine.SetRange("Whse. Document Type", PickWkshLine."Whse. Document Type"::"Internal Pick");
            PickWkshLine.SetRange("Whse. Document No.", "No.");
            if not PickWkshLine.IsEmpty then
                Error(Text001);

            WhseActivLine.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type");
            WhseActivLine.SetRange("Whse. Document No.", "No.");
            WhseActivLine.SetRange("Whse. Document Type", WhseActivLine."Whse. Document Type"::"Internal Pick");
            WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
            if not WhseActivLine.IsEmpty then
                Error(Text002);

            WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::"Internal Pick");
            WhsePickRqst.SetRange("Document No.", "No.");
            WhsePickRqst.SetRange(Status, Status::Released);
            if not WhsePickRqst.IsEmpty then
                WhsePickRqst.ModifyAll(Status, WhsePickRqst.Status::Open);

            Status := Status::Open;
            Modify;
        end;
    end;

    local procedure CreateWhsePickRqst(var WhsePickHeader: Record "Whse. Internal Pick Header")
    var
        WhsePickRqst: Record "Whse. Pick Request";
        Location: Record Location;
    begin
        with WhsePickHeader do
            if Location.RequirePicking("Location Code") then begin
                WhsePickRqst."Document Type" := WhsePickRqst."Document Type"::"Internal Pick";
                WhsePickRqst."Document No." := "No.";
                WhsePickRqst.Status := Status;
                WhsePickRqst."Location Code" := "Location Code";
                WhsePickRqst."Zone Code" := "To Zone Code";
                WhsePickRqst."Bin Code" := "To Bin Code";
                "Document Status" := GetDocumentStatus(0);
                WhsePickRqst."Completely Picked" :=
                  "Document Status" = "Document Status"::"Completely Picked";
                if not WhsePickRqst.Insert() then
                    WhsePickRqst.Modify();
            end;
    end;
}

