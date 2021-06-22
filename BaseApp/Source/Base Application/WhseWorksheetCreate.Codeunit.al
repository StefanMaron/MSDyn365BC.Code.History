codeunit 7311 "Whse. Worksheet-Create"
{

    trigger OnRun()
    begin
    end;

    var
        WhseMgt: Codeunit "Whse. Management";

    procedure FromWhseShptLine(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; WhseShptLine: Record "Warehouse Shipment Line"): Boolean
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        TransferFromWhseShptLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, WhseShptLine);
        AdjustQtyToHandle(WhseWkshLine);
        if CreateWhseWkshLine(WhseWkshLine) then
            exit(true);
    end;

    local procedure TransferFromWhseShptLine(var WhseWkshLine: Record "Whse. Worksheet Line"; WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; WhseShptLine: Record "Warehouse Shipment Line")
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
    begin
        with WhseShptLine do begin
            WhseWkshLine.SetCurrentKey(
              "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
            WhseWkshLine.SetRange("Whse. Document Type", WhseWkshLine."Whse. Document Type"::Shipment);
            WhseWkshLine.SetRange("Whse. Document No.", "No.");
            WhseWkshLine.SetRange("Whse. Document Line No.", "Line No.");
            if WhseWkshLine.Find('-') then
                exit;

            FindLastWhseWkshLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, "Location Code");
            WhseShptHeader.Get("No.");

            WhseWkshLine.Init();
            WhseWkshLine.SetHideValidationDialog(true);
            WhseWkshLine."Line No." := WhseWkshLine."Line No." + 10000;
            WhseWkshLine."Source Type" := "Source Type";
            WhseWkshLine."Source Subtype" := "Source Subtype";
            WhseWkshLine."Source No." := "Source No.";
            WhseWkshLine."Source Line No." := "Source Line No.";
            WhseWkshLine."Source Document" := WhseMgt.GetSourceDocument("Source Type", "Source Subtype");
            WhseWkshLine."Location Code" := "Location Code";
            WhseWkshLine."Item No." := "Item No.";
            WhseWkshLine."Variant Code" := "Variant Code";
            WhseWkshLine."Unit of Measure Code" := "Unit of Measure Code";
            WhseWkshLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            WhseWkshLine.Description := Description;
            WhseWkshLine."Description 2" := "Description 2";
            WhseWkshLine."Due Date" := "Due Date";
            WhseWkshLine."Qty. Handled" := "Qty. Picked" + "Pick Qty.";
            WhseWkshLine."Qty. Handled (Base)" := "Qty. Picked (Base)" + "Pick Qty. (Base)";
            WhseWkshLine.Validate(Quantity, Quantity);
            WhseWkshLine."To Zone Code" := "Zone Code";
            WhseWkshLine."To Bin Code" := "Bin Code";
            WhseWkshLine."Shelf No." := "Shelf No.";
            WhseWkshLine."Destination Type" := "Destination Type";
            WhseWkshLine."Destination No." := "Destination No.";
            if WhseShptHeader."Shipment Date" = 0D then
                WhseWkshLine."Shipment Date" := "Shipment Date"
            else
                WhseWkshLine."Shipment Date" := WhseShptHeader."Shipment Date";
            WhseWkshLine."Shipping Advice" := "Shipping Advice";
            WhseWkshLine."Shipping Agent Code" := WhseShptHeader."Shipping Agent Code";
            WhseWkshLine."Shipping Agent Service Code" := WhseShptHeader."Shipping Agent Service Code";
            WhseWkshLine."Shipment Method Code" := WhseShptHeader."Shipment Method Code";
            WhseWkshLine."Whse. Document Type" := WhseWkshLine."Whse. Document Type"::Shipment;
            WhseWkshLine."Whse. Document No." := "No.";
            WhseWkshLine."Whse. Document Line No." := "Line No.";
        end;

        OnAfterTransferFromWhseShptLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, WhseShptLine);
    end;

    procedure FromWhseInternalPickLine(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; LocationCode: Code[10]; WhseInternalPickLine: Record "Whse. Internal Pick Line"): Boolean
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        with WhseInternalPickLine do begin
            WhseWkshLine.SetCurrentKey(
              "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
            WhseWkshLine.SetRange("Whse. Document Type", WhseWkshLine."Whse. Document Type"::"Internal Pick");
            WhseWkshLine.SetRange("Whse. Document No.", "No.");
            WhseWkshLine.SetRange("Whse. Document Line No.", "Line No.");
            if not WhseWkshLine.IsEmpty then
                exit;

            FindLastWhseWkshLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, LocationCode);

            WhseWkshLine.Init();
            WhseWkshLine.SetHideValidationDialog(true);
            WhseWkshLine."Line No." := WhseWkshLine."Line No." + 10000;
            WhseWkshLine."Location Code" := "Location Code";
            WhseWkshLine."Item No." := "Item No.";
            WhseWkshLine."Variant Code" := "Variant Code";
            WhseWkshLine."Unit of Measure Code" := "Unit of Measure Code";
            WhseWkshLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            WhseWkshLine.Description := Description;
            WhseWkshLine."Description 2" := "Description 2";
            WhseWkshLine."Due Date" := "Due Date";
            WhseWkshLine."Qty. Handled" := "Qty. Picked" + "Pick Qty.";
            WhseWkshLine."Qty. Handled (Base)" := "Qty. Picked (Base)" + "Pick Qty. (Base)";
            WhseWkshLine.Validate(Quantity, Quantity);
            WhseWkshLine."To Zone Code" := "To Zone Code";
            WhseWkshLine."To Bin Code" := "To Bin Code";
            WhseWkshLine."Shelf No." := "Shelf No.";
            WhseWkshLine."Whse. Document Type" := WhseWkshLine."Whse. Document Type"::"Internal Pick";
            WhseWkshLine."Whse. Document No." := "No.";
            WhseWkshLine."Whse. Document Line No." := "Line No.";
        end;

        OnFromWhseInternalPickLineOnAfterTransferFields(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, WhseInternalPickLine);

        if CreateWhseWkshLine(WhseWkshLine) then
            exit(true);
    end;

    procedure FromProdOrderCompLine(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; LocationCode: Code[10]; ToBinCode: Code[20]; ProdOrderCompLine: Record "Prod. Order Component"): Boolean
    var
        Bin: Record Bin;
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        with ProdOrderCompLine do begin
            WhseWkshLine.SetCurrentKey(
              "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
            WhseWkshLine.SetRange("Source Type", DATABASE::"Prod. Order Component");
            WhseWkshLine.SetRange("Source Subtype", Status);
            WhseWkshLine.SetRange("Source No.", "Prod. Order No.");
            WhseWkshLine.SetRange("Source Line No.", "Prod. Order Line No.");
            WhseWkshLine.SetRange("Source Subline No.", "Line No.");
            if not WhseWkshLine.IsEmpty then
                exit;

            FindLastWhseWkshLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, LocationCode);

            WhseWkshLine.Init();
            WhseWkshLine.SetHideValidationDialog(true);
            WhseWkshLine."Line No." := WhseWkshLine."Line No." + 10000;
            WhseWkshLine."Whse. Document Type" := WhseWkshLine."Whse. Document Type"::Production;
            WhseWkshLine."Whse. Document No." := "Prod. Order No.";
            WhseWkshLine."Whse. Document Line No." := "Prod. Order Line No.";
            WhseWkshLine."Source Type" := DATABASE::"Prod. Order Component";
            WhseWkshLine."Source Subtype" := Status;
            WhseWkshLine."Source No." := "Prod. Order No.";
            WhseWkshLine."Source Line No." := "Prod. Order Line No.";
            WhseWkshLine."Source Subline No." := "Line No.";
            WhseWkshLine."Source Document" := WhseMgt.GetSourceDocument(WhseWkshLine."Source Type", WhseWkshLine."Source Subtype");
            WhseWkshLine."Location Code" := "Location Code";
            WhseWkshLine."Item No." := "Item No.";
            WhseWkshLine."Variant Code" := "Variant Code";
            WhseWkshLine."Unit of Measure Code" := "Unit of Measure Code";
            WhseWkshLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            WhseWkshLine.Description := Description;
            WhseWkshLine."Due Date" := "Due Date";
            WhseWkshLine."Qty. Handled" := "Qty. Picked" + "Pick Qty.";
            WhseWkshLine."Qty. Handled (Base)" := "Qty. Picked (Base)" + "Pick Qty. (Base)";
            WhseWkshLine.Validate(Quantity, "Expected Quantity");
            WhseWkshLine."To Bin Code" := ToBinCode;
            if ("Location Code" <> '') and (ToBinCode <> '') then begin
                Bin.Get(LocationCode, ToBinCode);
                WhseWkshLine."To Zone Code" := Bin."Zone Code";
            end;
        end;
        OnAfterFromProdOrderCompLineCreateWhseWkshLine(WhseWkshLine, ProdOrderCompLine);
        if CreateWhseWkshLine(WhseWkshLine) then
            exit(true);
    end;

    procedure FromAssemblyLine(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; AssemblyLine: Record "Assembly Line"): Boolean
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        with AssemblyLine do begin
            if WhseWkshLineForAsmLineExists(AssemblyLine) then
                exit;

            FindLastWhseWkshLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, "Location Code");

            WhseWkshLine.Init();
            TransferAllButWhseDocDetailsFromAssemblyLine(WhseWkshLine, AssemblyLine);
            WhseWkshLine."Whse. Document Type" := WhseWkshLine."Whse. Document Type"::Assembly;
            WhseWkshLine."Whse. Document No." := "Document No.";
            WhseWkshLine."Whse. Document Line No." := "Line No.";
        end;
        if CreateWhseWkshLine(WhseWkshLine) then
            exit(true);
    end;

    procedure FromAssemblyLineInATOWhseShpt(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; AssemblyLine: Record "Assembly Line"; WhseShptLine: Record "Warehouse Shipment Line"): Boolean
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        WhseShptLine.TestField("Assemble to Order", true);

        if WhseWkshLineForAsmLineExists(AssemblyLine) then
            exit;

        TransferFromWhseShptLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, WhseShptLine);
        TransferAllButWhseDocDetailsFromAssemblyLine(WhseWkshLine, AssemblyLine);
        if CreateWhseWkshLine(WhseWkshLine) then
            exit(true);
    end;

    local procedure WhseWkshLineForAsmLineExists(AssemblyLine: Record "Assembly Line"): Boolean
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        WhseWkshLine.SetCurrentKey(
          "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
        WhseWkshLine.SetRange("Source Type", DATABASE::"Assembly Line");
        WhseWkshLine.SetRange("Source Subtype", AssemblyLine."Document Type");
        WhseWkshLine.SetRange("Source No.", AssemblyLine."Document No.");
        WhseWkshLine.SetRange("Source Line No.", AssemblyLine."Line No.");
        WhseWkshLine.SetRange("Source Subline No.", 0);
        exit(not WhseWkshLine.IsEmpty);
    end;

    local procedure TransferAllButWhseDocDetailsFromAssemblyLine(var WhseWkshLine: Record "Whse. Worksheet Line"; AssemblyLine: Record "Assembly Line")
    var
        WhseWkshLine1: Record "Whse. Worksheet Line";
        Location: Record Location;
        Bin: Record Bin;
    begin
        with AssemblyLine do begin
            WhseWkshLine.SetHideValidationDialog(true);
            FindLastWhseWkshLine(WhseWkshLine1, WhseWkshLine."Worksheet Template Name", WhseWkshLine.Name, WhseWkshLine."Location Code");
            WhseWkshLine."Line No." := WhseWkshLine1."Line No." + 10000;
            WhseWkshLine."Source Type" := DATABASE::"Assembly Line";
            WhseWkshLine."Source Subtype" := "Document Type";
            WhseWkshLine."Source No." := "Document No.";
            WhseWkshLine."Source Line No." := "Line No.";
            WhseWkshLine."Source Subline No." := 0;
            WhseWkshLine."Source Document" := WhseMgt.GetSourceDocument(WhseWkshLine."Source Type", WhseWkshLine."Source Subtype");
            WhseWkshLine."Location Code" := "Location Code";
            TestField(Type, Type::Item);
            WhseWkshLine."Item No." := "No.";
            WhseWkshLine."Variant Code" := "Variant Code";
            WhseWkshLine."Unit of Measure Code" := "Unit of Measure Code";
            WhseWkshLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            WhseWkshLine.Description := Description;
            WhseWkshLine."Description 2" := "Description 2";
            WhseWkshLine."Due Date" := "Due Date";
            CalcFields("Pick Qty.", "Pick Qty. (Base)");
            WhseWkshLine."Qty. Handled" := "Qty. Picked" + "Pick Qty.";
            WhseWkshLine."Qty. Handled (Base)" := "Qty. Picked (Base)" + "Pick Qty. (Base)";
            Location.Get("Location Code");
            if Location."Require Shipment" then
                WhseWkshLine.Validate(Quantity, Quantity)
            else
                WhseWkshLine.Validate(Quantity, "Quantity to Consume");
            WhseWkshLine."To Bin Code" := "Bin Code";
            if ("Location Code" <> '') and ("Bin Code" <> '') then begin
                Bin.Get("Location Code", "Bin Code");
                WhseWkshLine."To Zone Code" := Bin."Zone Code";
            end;
        end;
    end;

    procedure FromWhseRcptLine(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; LocationCode: Code[10]; PostedWhseRcptLine: Record "Posted Whse. Receipt Line"): Boolean
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        with PostedWhseRcptLine do begin
            if "Qty. Put Away" = Quantity then
                exit;

            WhseWkshLine.SetCurrentKey(
              "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
            WhseWkshLine.SetRange(
              "Whse. Document Type", WhseWkshLine."Whse. Document Type"::Receipt);
            WhseWkshLine.SetRange("Whse. Document No.", "No.");
            WhseWkshLine.SetRange("Whse. Document Line No.", "Line No.");
            if not WhseWkshLine.IsEmpty then
                exit;

            FindLastWhseWkshLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, LocationCode);

            WhseWkshLine.Init();
            WhseWkshLine."Line No." := WhseWkshLine."Line No." + 10000;
            WhseWkshLine."Source Type" := "Source Type";
            WhseWkshLine."Source Subtype" := "Source Subtype";
            WhseWkshLine."Source No." := "Source No.";
            WhseWkshLine."Source Line No." := "Source Line No.";
            WhseWkshLine."Source Document" := WhseMgt.GetSourceDocument("Source Type", "Source Subtype");
            WhseWkshLine."Location Code" := "Location Code";
            WhseWkshLine."Item No." := "Item No.";
            WhseWkshLine."Variant Code" := "Variant Code";
            WhseWkshLine."Unit of Measure Code" := "Unit of Measure Code";
            WhseWkshLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            WhseWkshLine.Description := Description;
            WhseWkshLine."Description 2" := "Description 2";
            WhseWkshLine."Due Date" := "Due Date";
            WhseWkshLine.Validate(Quantity, Quantity);
            WhseWkshLine.Validate("Qty. Handled", "Qty. Put Away" + "Put-away Qty.");
            WhseWkshLine."From Zone Code" := "Zone Code";
            WhseWkshLine."From Bin Code" := "Bin Code";
            WhseWkshLine."Shelf No." := "Shelf No.";
            WhseWkshLine."From Unit of Measure Code" := "Unit of Measure Code";
            WhseWkshLine."Qty. per From Unit of Measure" := "Qty. per Unit of Measure";
            WhseWkshLine."Whse. Document Type" := WhseWkshLine."Whse. Document Type"::Receipt;
            WhseWkshLine."Whse. Document No." := "No.";
            WhseWkshLine."Whse. Document Line No." := "Line No.";

            OnAfterFromWhseRcptLineCreateWhseWkshLine(WhseWkshLine, PostedWhseRcptLine);
        end;
        if CreateWhseWkshLine(WhseWkshLine) then
            exit(true);
    end;

    procedure FromWhseInternalPutawayLine(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; LocationCode: Code[10]; WhseInternalPutawayLine: Record "Whse. Internal Put-away Line"): Boolean
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        with WhseInternalPutawayLine do begin
            if "Qty. Put Away" = Quantity then
                exit;

            WhseWkshLine.SetCurrentKey(
              "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
            WhseWkshLine.SetRange(
              "Whse. Document Type", WhseWkshLine."Whse. Document Type"::"Internal Put-away");
            WhseWkshLine.SetRange("Whse. Document No.", "No.");
            WhseWkshLine.SetRange("Whse. Document Line No.", "Line No.");
            if not WhseWkshLine.IsEmpty then
                exit;

            FindLastWhseWkshLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, LocationCode);

            WhseWkshLine.Init();
            WhseWkshLine."Line No." := WhseWkshLine."Line No." + 10000;
            WhseWkshLine."Location Code" := "Location Code";
            WhseWkshLine."Item No." := "Item No.";
            WhseWkshLine."Variant Code" := "Variant Code";
            WhseWkshLine."Unit of Measure Code" := "Unit of Measure Code";
            WhseWkshLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            WhseWkshLine.Description := Description;
            WhseWkshLine."Description 2" := "Description 2";
            WhseWkshLine."Due Date" := "Due Date";
            WhseWkshLine.Validate(Quantity, Quantity);
            WhseWkshLine.Validate("Qty. Handled", "Qty. Put Away" + "Put-away Qty.");
            WhseWkshLine."From Zone Code" := "From Zone Code";
            WhseWkshLine."From Bin Code" := "From Bin Code";
            WhseWkshLine."Shelf No." := "Shelf No.";
            WhseWkshLine."From Unit of Measure Code" := "Unit of Measure Code";
            WhseWkshLine."Qty. per From Unit of Measure" := "Qty. per Unit of Measure";
            WhseWkshLine."Whse. Document Type" := WhseWkshLine."Whse. Document Type"::"Internal Put-away";
            WhseWkshLine."Whse. Document No." := "No.";
            WhseWkshLine."Whse. Document Line No." := "Line No.";
        end;

        OnFromWhseInternalPutawayLineOnAfterTransferFields(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, WhseInternalPutawayLine);

        if CreateWhseWkshLine(WhseWkshLine) then
            exit(true);
    end;

    local procedure CreateWhseWkshLine(var WhseWkshLine: Record "Whse. Worksheet Line") Created: Boolean
    var
        Item: Record Item;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        with WhseWkshLine do begin
            if "Shelf No." = '' then begin
                Item."No." := "Item No.";
                Item.ItemSKUGet(Item, "Location Code", "Variant Code");
                "Shelf No." := Item."Shelf No.";
            end;
            OnCreateWhseWkshLineOnBeforeInsert(WhseWkshLine);
            if Insert() then begin
                Created := true;
                if ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.") then
                    ItemTrackingMgt.InitTrackingSpecification(WhseWkshLine);
            end;
        end;
    end;

    local procedure FindLastWhseWkshLine(var WhseWkshLine: Record "Whse. Worksheet Line"; WkshTemplateName: Code[10]; WkshName: Code[10]; LocationCode: Code[10])
    begin
        WhseWkshLine.Reset();
        WhseWkshLine."Worksheet Template Name" := WkshTemplateName;
        WhseWkshLine.Name := WkshName;
        WhseWkshLine."Location Code" := LocationCode;
        WhseWkshLine.SetRange("Worksheet Template Name", WkshTemplateName);
        WhseWkshLine.SetRange(Name, WkshName);
        WhseWkshLine.SetRange("Location Code", LocationCode);
        WhseWkshLine.LockTable();
        if WhseWkshLine.FindLast then;
    end;

    local procedure AdjustQtyToHandle(var WhseWkshLine: Record "Whse. Worksheet Line")
    var
        TypeHelper: Codeunit "Type Helper";
        AvailQtyToPick: Decimal;
    begin
        with WhseWkshLine do begin
            AvailQtyToPick := AvailableQtyToPickExcludingQCBins;
            "Qty. to Handle" := TypeHelper.Minimum(AvailQtyToPick, "Qty. Outstanding");
            "Qty. to Handle (Base)" := CalcBaseQty("Qty. to Handle");
            CalcReservedNotFromILEQty(AvailQtyToPick, "Qty. to Handle", "Qty. to Handle (Base)");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromWhseShptLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; WhseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromProdOrderCompLineCreateWhseWkshLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromWhseRcptLineCreateWhseWkshLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseWkshLineOnBeforeInsert(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromWhseInternalPickLineOnAfterTransferFields(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; WhseInternalPickLine: Record "Whse. Internal Pick Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromWhseInternalPutawayLineOnAfterTransferFields(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line")
    begin
    end;
}

