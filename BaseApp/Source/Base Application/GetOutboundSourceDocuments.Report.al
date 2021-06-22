report 7304 "Get Outbound Source Documents"
{
    Caption = 'Get Outbound Source Documents';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Whse. Pick Request"; "Whse. Pick Request")
        {
            DataItemTableView = SORTING("Document Type", "Document Subtype", "Document No.", "Location Code") WHERE(Status = CONST(Released), "Completely Picked" = CONST(false));
            RequestFilterFields = "Document Type", "Document No.";
            dataitem("Warehouse Shipment Header"; "Warehouse Shipment Header")
            {
                DataItemLink = "No." = FIELD("Document No.");
                DataItemTableView = SORTING("No.");
                dataitem("Warehouse Shipment Line"; "Warehouse Shipment Line")
                {
                    DataItemLink = "No." = FIELD("No.");
                    DataItemTableView = SORTING("No.", "Line No.");

                    trigger OnAfterGetRecord()
                    var
                        ATOLink: Record "Assemble-to-Order Link";
                        ATOAsmLine: Record "Assembly Line";
                    begin
                        if not "Assemble to Order" then begin
                            CalcFields("Pick Qty.", "Pick Qty. (Base)");
                            if "Qty. (Base)" > "Qty. Picked (Base)" + "Pick Qty. (Base)" then begin
                                if "Destination Type" = "Destination Type"::Customer then begin
                                    TestField("Destination No.");
                                    Cust.Get("Destination No.");
                                    Cust.CheckBlockedCustOnDocs(Cust, "Source Document", false, false);
                                end;

                                if WhsePickWkshCreate.FromWhseShptLine(PickWkshTemplate, PickWkshName, "Warehouse Shipment Line") then
                                    LineCreated := true;
                            end;
                        end else
                            if ATOLink.AsmExistsForWhseShptLine("Warehouse Shipment Line") then begin
                                ATOAsmLine.SetRange("Document Type", ATOLink."Assembly Document Type");
                                ATOAsmLine.SetRange("Document No.", ATOLink."Assembly Document No.");
                                if ATOAsmLine.FindSet then
                                    repeat
                                        ProcessAsmLineFromWhseShpt(ATOAsmLine, "Warehouse Shipment Line");
                                    until ATOAsmLine.Next = 0;
                            end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Qty. Outstanding", '>0');
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if "Whse. Pick Request"."Document Type" <>
                       "Whse. Pick Request"."Document Type"::Shipment
                    then
                        CurrReport.Break();

                    OnWhseShipHeaderOnPreDataItem("Warehouse Shipment Header");
                end;
            }
            dataitem("Whse. Internal Pick Header"; "Whse. Internal Pick Header")
            {
                DataItemLink = "No." = FIELD("Document No.");
                DataItemTableView = SORTING("No.");
                dataitem("Whse. Internal Pick Line"; "Whse. Internal Pick Line")
                {
                    DataItemLink = "No." = FIELD("No.");
                    DataItemTableView = SORTING("No.", "Line No.");

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields("Pick Qty.", "Pick Qty. (Base)");
                        if "Qty. (Base)" > "Qty. Picked (Base)" + "Pick Qty. (Base)" then begin
                            if WhsePickWkshCreate.FromWhseInternalPickLine(
                                 PickWkshTemplate, PickWkshName, LocationCode, "Whse. Internal Pick Line")
                            then
                                LineCreated := true;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Qty. Outstanding", '>0');
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if "Whse. Pick Request"."Document Type" <> "Whse. Pick Request"."Document Type"::"Internal Pick" then
                        CurrReport.Break();
                end;
            }
            dataitem("Production Order"; "Production Order")
            {
                DataItemLink = Status = FIELD("Document Subtype"), "No." = FIELD("Document No.");
                DataItemTableView = SORTING(Status, "No.") WHERE(Status = CONST(Released));
                dataitem("Prod. Order Component"; "Prod. Order Component")
                {
                    DataItemLink = Status = FIELD(Status), "Prod. Order No." = FIELD("No.");
                    DataItemTableView = SORTING(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.") WHERE("Flushing Method" = FILTER(Manual | "Pick + Forward" | "Pick + Backward"), "Planning Level Code" = CONST(0));

                    trigger OnAfterGetRecord()
                    var
                        ToBinCode: Code[20];
                    begin
                        if ("Flushing Method" = "Flushing Method"::"Pick + Forward") and ("Routing Link Code" = '') then
                            CurrReport.Skip();

                        GetLocation("Location Code");
                        ToBinCode := "Bin Code";

                        CalcFields("Pick Qty.");
                        if "Expected Quantity" > "Qty. Picked" + "Pick Qty." then
                            if WhsePickWkshCreate.FromProdOrderCompLine(
                                 PickWkshTemplate, PickWkshName, Location.Code,
                                 ToBinCode, "Prod. Order Component")
                            then
                                LineCreated := true;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Location Code", "Whse. Pick Request"."Location Code");
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if "Whse. Pick Request"."Document Type" <> "Whse. Pick Request"."Document Type"::Production then
                        CurrReport.Break();
                end;
            }
            dataitem("Assembly Header"; "Assembly Header")
            {
                DataItemLink = "Document Type" = FIELD("Document Subtype"), "No." = FIELD("Document No.");
                DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Order));
                dataitem("Assembly Line"; "Assembly Line")
                {
                    DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                    DataItemTableView = SORTING("Document Type", "Document No.", Type, "Location Code") WHERE(Type = CONST(Item));

                    trigger OnAfterGetRecord()
                    begin
                        ProcessAsmLineFromAsmLine("Assembly Line");
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Location Code", "Whse. Pick Request"."Location Code");
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if "Whse. Pick Request"."Document Type" <> "Whse. Pick Request"."Document Type"::Assembly then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                OnBeforeWhsePickRequestOnAfterGetRecord("Whse. Pick Request", PickWkshTemplate, PickWkshName, LocationCode, LineCreated);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if not HideDialog then
            if not LineCreated then
                Error(Text000);

        Completed := true;
    end;

    trigger OnPreReport()
    begin
        LineCreated := false;
    end;

    var
        Text000: Label 'There are no Warehouse Worksheet Lines created.';
        Location: Record Location;
        Cust: Record Customer;
        WhsePickWkshCreate: Codeunit "Whse. Worksheet-Create";
        PickWkshTemplate: Code[10];
        PickWkshName: Code[10];
        LocationCode: Code[10];
        Completed: Boolean;
        LineCreated: Boolean;
        HideDialog: Boolean;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure NotCancelled(): Boolean
    begin
        exit(Completed);
    end;

    procedure SetPickWkshName(PickWkshTemplate2: Code[10]; PickWkshName2: Code[10]; LocationCode2: Code[10])
    begin
        PickWkshTemplate := PickWkshTemplate2;
        PickWkshName := PickWkshName2;
        LocationCode := LocationCode2;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure IsPickToBeMadeForAsmLine(AsmLine: Record "Assembly Line"): Boolean
    begin
        with AsmLine do begin
            GetLocation("Location Code");

            CalcFields("Pick Qty.");
            if Location."Require Shipment" then
                exit(Quantity > "Qty. Picked" + "Pick Qty.");

            exit("Quantity to Consume" > "Qty. Picked" + "Pick Qty.");
        end;
    end;

    local procedure ProcessAsmLineFromAsmLine(AsmLine: Record "Assembly Line")
    begin
        if IsPickToBeMadeForAsmLine(AsmLine) then
            if WhsePickWkshCreate.FromAssemblyLine(PickWkshTemplate, PickWkshName, AsmLine) then
                LineCreated := true;
    end;

    local procedure ProcessAsmLineFromWhseShpt(AsmLine: Record "Assembly Line"; WhseShptLine: Record "Warehouse Shipment Line")
    begin
        if IsPickToBeMadeForAsmLine(AsmLine) then
            if WhsePickWkshCreate.FromAssemblyLineInATOWhseShpt(PickWkshTemplate, PickWkshName, AsmLine, WhseShptLine) then
                LineCreated := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhsePickRequestOnAfterGetRecord(var WhsePickRequest: Record "Whse. Pick Request"; PickWkshTemplate: Code[10]; PickWkshName: Code[10]; LocationCode: Code[10]; var LineCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseShipHeaderOnPreDataItem(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;
}

