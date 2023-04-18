table 5530 "Inventory Event Buffer"
{
    Caption = 'Inventory Event Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(9; "Source Line ID"; RecordID)
        {
            Caption = 'Source Line ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = Item;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(12; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = Location;
        }
        field(14; "Availability Date"; Date)
        {
            Caption = 'Availability Date';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(15; Type; Enum "Inventory Event Buffer Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20; "Remaining Quantity (Base)"; Decimal)
        {
            Caption = 'Remaining Quantity (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(21; Positive; Boolean)
        {
            Caption = 'Positive';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(22; "Transfer Direction"; Enum "Transfer Direction")
        {
            Caption = 'Transfer Direction';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(23; "Reserved Quantity (Base)"; Decimal)
        {
            Caption = 'Reserved Quantity (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(29; "Action Message"; Enum "Action Message Type")
        {
            Caption = 'Action Message';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(31; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(32; "Forecast Type"; Option)
        {
            Caption = 'Forecast Type';
            DataClassification = SystemMetadata;
            Editable = false;
            OptionCaption = ',Sales,Component';
            OptionMembers = ,Sales,Component;
        }
        field(33; "Derived from Blanket Order"; Boolean)
        {
            Caption = 'Derived from Blanket Order';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(34; "Ref. Order No."; Code[20])
        {
            Caption = 'Ref. Order No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(35; "Orig. Quantity (Base)"; Decimal)
        {
            Caption = 'Orig. Quantity (Base)';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(37; "Ref. Order Type"; Option)
        {
            Caption = 'Ref. Order Type';
            DataClassification = SystemMetadata;
            Editable = false;
            OptionCaption = ' ,Purchase,Prod. Order,Assembly,Transfer';
            OptionMembers = " ",Purchase,"Prod. Order",Assembly,Transfer;
        }
        field(38; "Ref. Order Line No."; Integer)
        {
            Caption = 'Ref. Order Line No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Availability Date", Type)
        {
        }
    }

    fieldgroups
    {
    }

    var
        RecRef: RecordRef;

    procedure TransferFromSales(SalesLine: Record "Sales Line")
    var
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        RemQty: Decimal;
    begin
        if SalesLine.Type <> SalesLine.Type::Item then
            exit;

        Init();
        RecRef.GetTable(SalesLine);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := SalesLine."No.";
        "Variant Code" := SalesLine."Variant Code";
        "Location Code" := SalesLine."Location Code";
        "Availability Date" := SalesLine."Shipment Date";
        Type := Type::Sale;
        SalesLineReserve.ReservQuantity(SalesLine, RemQty, "Remaining Quantity (Base)");
        SalesLine.CalcFields("Reserved Qty. (Base)");
        "Remaining Quantity (Base)" := -"Remaining Quantity (Base)";
        "Reserved Quantity (Base)" := -SalesLine."Reserved Qty. (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);
        "Derived from Blanket Order" := SalesLine."Blanket Order No." <> '';
        if "Derived from Blanket Order" then begin
            "Ref. Order No." := SalesLine."Blanket Order No.";
            "Ref. Order Line No." := SalesLine."Blanket Order Line No.";
        end;

        OnAfterTransferFromSales(Rec, SalesLine);
    end;

    procedure TransferFromSalesReturn(SalesLine: Record "Sales Line")
    var
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        RemQty: Decimal;
    begin
        if SalesLine.Type <> SalesLine.Type::Item then
            exit;

        Init();
        RecRef.GetTable(SalesLine);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := SalesLine."No.";
        "Variant Code" := SalesLine."Variant Code";
        "Location Code" := SalesLine."Location Code";
        "Availability Date" := SalesLine."Shipment Date";
        Type := Type::Sale;
        SalesLineReserve.ReservQuantity(SalesLine, RemQty, "Remaining Quantity (Base)");
        SalesLine.CalcFields("Reserved Qty. (Base)");
        "Remaining Quantity (Base)" := -"Remaining Quantity (Base)";
        "Reserved Quantity (Base)" := -SalesLine."Reserved Qty. (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);
        "Derived from Blanket Order" := SalesLine."Blanket Order No." <> '';
        if "Derived from Blanket Order" then begin
            "Ref. Order No." := SalesLine."Blanket Order No.";
            "Ref. Order Line No." := SalesLine."Blanket Order Line No.";
        end;

        OnAfterTransferFromSalesReturn(Rec, SalesLine);
    end;

    procedure TransferFromProdComp(ProdOrderComp: Record "Prod. Order Component")
    begin
        Init();
        RecRef.GetTable(ProdOrderComp);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := ProdOrderComp."Item No.";
        "Variant Code" := ProdOrderComp."Variant Code";
        "Location Code" := ProdOrderComp."Location Code";
        "Availability Date" := ProdOrderComp."Due Date";
        Type := Type::Component;
        ProdOrderComp.CalcFields("Reserved Qty. (Base)");
        "Remaining Quantity (Base)" := -ProdOrderComp."Remaining Qty. (Base)";
        "Reserved Quantity (Base)" := -ProdOrderComp."Reserved Qty. (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);

        OnAfterTransferFromProdComp(Rec, ProdOrderComp);
    end;

    procedure TransferFromJobNeed(JobPlanningLine: Record "Job Planning Line")
    begin
        if JobPlanningLine.Type <> JobPlanningLine.Type::Item then
            exit;

        Init();
        RecRef.GetTable(JobPlanningLine);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := JobPlanningLine."No.";
        "Variant Code" := JobPlanningLine."Variant Code";
        "Location Code" := JobPlanningLine."Location Code";
        "Availability Date" := JobPlanningLine."Planning Date";
        Type := Type::Job;
        JobPlanningLine.CalcFields("Reserved Qty. (Base)");
        "Remaining Quantity (Base)" := -JobPlanningLine."Remaining Qty. (Base)";
        "Reserved Quantity (Base)" := -JobPlanningLine."Reserved Qty. (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);

        OnAfterTransferFromJobNeed(Rec, JobPlanningLine);
    end;

    procedure TransferFromServiceNeed(ServLine: Record "Service Line")
    var
        ServLineReserve: Codeunit "Service Line-Reserve";
        RemQty: Decimal;
    begin
        if ServLine.Type <> ServLine.Type::Item then
            exit;

        Init();
        RecRef.GetTable(ServLine);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := ServLine."No.";
        "Variant Code" := ServLine."Variant Code";
        "Location Code" := ServLine."Location Code";
        "Availability Date" := ServLine."Needed by Date";
        Type := Type::Service;
        ServLineReserve.ReservQuantity(ServLine, RemQty, "Remaining Quantity (Base)");
        ServLine.CalcFields("Reserved Qty. (Base)");
        "Remaining Quantity (Base)" := -"Remaining Quantity (Base)";
        "Reserved Quantity (Base)" := -ServLine."Reserved Qty. (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);

        OnAfterTransferFromServiceNeed(Rec, ServLine);
    end;

    procedure TransferFromOutboundTransOrder(TransLine: Record "Transfer Line")
    begin
        Init();
        RecRef.GetTable(TransLine);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := TransLine."Item No.";
        "Variant Code" := TransLine."Variant Code";
        "Location Code" := TransLine."Transfer-from Code";
        "Availability Date" := TransLine."Shipment Date";
        Type := Type::Transfer;
        TransLine.CalcFields("Reserved Qty. Outbnd. (Base)");
        "Remaining Quantity (Base)" := -TransLine."Outstanding Qty. (Base)";
        "Reserved Quantity (Base)" := -TransLine."Reserved Qty. Outbnd. (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);
        "Transfer Direction" := "Transfer Direction"::Outbound;

        OnAfterTransferFromOutboundTransfer(Rec, TransLine);
    end;

    procedure TransferFromPlanProdComp(PlngComp: Record "Planning Component")
    var
        ReqLine: Record "Requisition Line";
    begin
        Init();
        ReqLine.Get(PlngComp."Worksheet Template Name", PlngComp."Worksheet Batch Name", PlngComp."Worksheet Line No.");
        RecRef.GetTable(PlngComp);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := PlngComp."Item No.";
        "Variant Code" := PlngComp."Variant Code";
        "Location Code" := PlngComp."Location Code";
        "Availability Date" := PlngComp."Due Date";
        Type := Type::Plan;
        PlngComp.CalcFields("Reserved Qty. (Base)");
        "Remaining Quantity (Base)" := -PlngComp."Expected Quantity (Base)";
        "Reserved Quantity (Base)" := -PlngComp."Reserved Qty. (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);
        "Action Message" := ReqLine."Action Message";
        "Ref. Order No." := ReqLine."Ref. Order No.";
        "Ref. Order Type" := GetRefOrderTypeFromReqLine(ReqLine."Ref. Order Type");

        OnAfterTransferFromPlanProdComp(Rec, PlngComp, ReqLine);
    end;

    procedure TransferFromReqLineTransDemand(ReqLine: Record "Requisition Line")
    begin
        if ReqLine.Type <> ReqLine.Type::Item then
            exit;

        Init();
        RecRef.GetTable(ReqLine);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := ReqLine."No.";
        "Variant Code" := ReqLine."Variant Code";
        "Location Code" := ReqLine."Transfer-from Code";
        "Availability Date" := ReqLine."Transfer Shipment Date";
        Type := Type::Transfer;
        ReqLine.CalcFields("Reserved Qty. (Base)");
        "Remaining Quantity (Base)" := -ReqLine."Quantity (Base)";
        "Reserved Quantity (Base)" := -ReqLine."Reserved Qty. (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);
        "Action Message" := ReqLine."Action Message";
        "Ref. Order No." := ReqLine."Ref. Order No.";
        "Ref. Order Type" := GetRefOrderTypeFromReqLine(ReqLine."Ref. Order Type");
        // Notice: Planned outbound transfer uses an opposite direction of transfer
        "Transfer Direction" := "Transfer Direction"::Inbound;

        OnAfterTransferFromReqLineTransDemand(Rec, ReqLine);
    end;

    procedure TransferInventoryQty(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        Init();
        RecRef.GetTable(ItemLedgEntry);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := ItemLedgEntry."Item No.";
        "Variant Code" := ItemLedgEntry."Variant Code";
        "Location Code" := ItemLedgEntry."Location Code";
        "Availability Date" := 0D;
        Type := Type::Inventory;
        "Remaining Quantity (Base)" := ItemLedgEntry."Remaining Quantity";

        "Reserved Quantity (Base)" := CalcReservedQuantity(ItemLedgEntry);

        Positive := not ("Remaining Quantity (Base)" < 0);

        OnAfterTransferInventoryQty(Rec, ItemLedgEntry);
    end;

    procedure TransferFromPurchase(PurchLine: Record "Purchase Line")
    var
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
    begin
        if PurchLine.Type <> PurchLine.Type::Item then
            exit;

        Init();
        RecRef.GetTable(PurchLine);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := PurchLine."No.";
        "Variant Code" := PurchLine."Variant Code";
        "Location Code" := PurchLine."Location Code";
        "Availability Date" := PurchLine."Expected Receipt Date";
        Type := Type::Purchase;
        PurchLine.CalcFields("Reserved Qty. (Base)");
        "Remaining Quantity (Base)" := -PurchLineReserve.ReservQuantity(PurchLine);
        "Reserved Quantity (Base)" := PurchLine."Reserved Qty. (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);

        OnAfterTransferFromPurchase(Rec, PurchLine);
    end;

    procedure TransferFromPurchReturn(PurchLine: Record "Purchase Line")
    var
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
    begin
        if PurchLine.Type <> PurchLine.Type::Item then
            exit;

        Init();
        RecRef.GetTable(PurchLine);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := PurchLine."No.";
        "Variant Code" := PurchLine."Variant Code";
        "Location Code" := PurchLine."Location Code";
        "Availability Date" := PurchLine."Expected Receipt Date";
        Type := Type::Purchase;
        PurchLine.CalcFields("Reserved Qty. (Base)");
        "Remaining Quantity (Base)" := -PurchLineReserve.ReservQuantity(PurchLine);
        "Reserved Quantity (Base)" := PurchLine."Reserved Qty. (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);

        OnAfterTransferFromPurchReturn(Rec, PurchLine);
    end;

    procedure TransferFromProdOrder(ProdOrderLine: Record "Prod. Order Line")
    begin
        Init();
        RecRef.GetTable(ProdOrderLine);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := ProdOrderLine."Item No.";
        "Variant Code" := ProdOrderLine."Variant Code";
        "Location Code" := ProdOrderLine."Location Code";
        "Availability Date" := ProdOrderLine."Due Date";
        Type := Type::Production;
        ProdOrderLine.CalcFields("Reserved Qty. (Base)");
        "Remaining Quantity (Base)" := ProdOrderLine."Remaining Qty. (Base)";
        "Reserved Quantity (Base)" := ProdOrderLine."Reserved Qty. (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);

        OnAfterTransferFromProdOrder(Rec, ProdOrderLine);
    end;

    procedure TransferFromInboundTransOrder(TransLine: Record "Transfer Line")
    begin
        Init();
        RecRef.GetTable(TransLine);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := TransLine."Item No.";
        "Variant Code" := TransLine."Variant Code";
        "Location Code" := TransLine."Transfer-to Code";
        "Availability Date" := TransLine."Receipt Date";
        Type := Type::Transfer;
        TransLine.CalcFields("Reserved Qty. Inbnd. (Base)", "Reserved Qty. Shipped (Base)");
        "Remaining Quantity (Base)" := TransLine."Quantity (Base)" - TransLine."Qty. Received (Base)";
        "Reserved Quantity (Base)" := TransLine."Reserved Qty. Inbnd. (Base)" + TransLine."Reserved Qty. Shipped (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);
        "Transfer Direction" := "Transfer Direction"::Inbound;

        OnAfterTransferFromInboundTransOrder(Rec, TransLine);
    end;

    procedure TransferFromReqLine(ReqLine: Record "Requisition Line"; AtLocation: Code[10]; AtDate: Date; DeltaQtyBase: Decimal; RecID: RecordID)
    begin
        if ReqLine.Type <> ReqLine.Type::Item then
            exit;

        Init();
        "Source Line ID" := RecID;
        "Item No." := ReqLine."No.";
        "Variant Code" := ReqLine."Variant Code";
        "Location Code" := AtLocation;
        "Availability Date" := AtDate;
        Type := Type::Plan;
        ReqLine.CalcFields("Reserved Qty. (Base)");
        "Remaining Quantity (Base)" := DeltaQtyBase;
        "Reserved Quantity (Base)" := ReqLine."Reserved Qty. (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);
        "Action Message" := ReqLine."Action Message";
        "Ref. Order No." := ReqLine."Ref. Order No.";
        "Ref. Order Type" := GetRefOrderTypeFromReqLine(ReqLine."Ref. Order Type");

        OnAfterTransferFromReqLine(Rec, ReqLine);
    end;

    procedure TransferFromForecast(ProdForecastEntry: Record "Production Forecast Entry"; UnconsumedQtyBase: Decimal; ForecastOnLocation: Boolean)
    begin
        TransferFromForecast(ProdForecastEntry, UnconsumedQtyBase, ForecastOnLocation, false);
    end;

    procedure TransferFromForecast(ProdForecastEntry: Record "Production Forecast Entry"; UnconsumedQtyBase: Decimal; ForecastOnLocation: Boolean; ForecastOnVariant: Boolean)
    begin
        Init();
        RecRef.GetTable(ProdForecastEntry);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := ProdForecastEntry."Item No.";
        "Variant Code" := '';
        if ForecastOnLocation then
            "Location Code" := ProdForecastEntry."Location Code"
        else
            "Location Code" := '';
        if ForecastOnVariant then
            "Variant Code" := ProdForecastEntry."Variant Code"
        else
            "Variant Code" := '';
        "Availability Date" := ProdForecastEntry."Forecast Date";
        Type := Type::Forecast;
        if ProdForecastEntry."Component Forecast" then
            "Forecast Type" := "Forecast Type"::Component
        else
            "Forecast Type" := "Forecast Type"::Sales;
        "Remaining Quantity (Base)" := -UnconsumedQtyBase;
        "Reserved Quantity (Base)" := 0;
        "Orig. Quantity (Base)" := -ProdForecastEntry."Forecast Quantity (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);

        OnAfterTransferFromForecast(Rec, ProdForecastEntry);
    end;

    procedure TransferFromSalesBlanketOrder(SalesLine: Record "Sales Line"; UnconsumedQtyBase: Decimal)
    begin
        if SalesLine.Type <> SalesLine.Type::Item then
            exit;

        Init();
        RecRef.GetTable(SalesLine);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := SalesLine."No.";
        "Variant Code" := SalesLine."Variant Code";
        "Location Code" := SalesLine."Location Code";
        "Availability Date" := SalesLine."Shipment Date";
        Type := Type::"Blanket Sales Order";
        "Remaining Quantity (Base)" := -UnconsumedQtyBase;
        "Reserved Quantity (Base)" := 0;
        "Orig. Quantity (Base)" := -SalesLine."Quantity (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);

        OnAfterTransferFromSalesBlanketOrder(Rec, SalesLine);
    end;

    procedure PlanRevertEntry(InvtEventBuf: Record "Inventory Event Buffer"; ParentActionMessage: Enum "Action Message Type")
    begin
        Rec := InvtEventBuf;
        Type := Type::"Plan Revert";
        "Remaining Quantity (Base)" := -"Remaining Quantity (Base)";
        "Reserved Quantity (Base)" := 0;
        Positive := not ("Remaining Quantity (Base)" < 0);
        "Action Message" := ParentActionMessage;
        "Attached to Line No." := InvtEventBuf."Entry No.";
    end;

    procedure TransferFromAsmOrder(AssemblyHeader: Record "Assembly Header")
    begin
        Init();
        Type := Type::"Assembly Order";
        RecRef.GetTable(AssemblyHeader);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := AssemblyHeader."Item No.";
        "Variant Code" := AssemblyHeader."Variant Code";
        "Location Code" := AssemblyHeader."Location Code";
        "Availability Date" := AssemblyHeader."Due Date";
        AssemblyHeader.CalcFields("Reserved Qty. (Base)");
        "Remaining Quantity (Base)" := AssemblyHeader."Remaining Quantity (Base)";
        "Reserved Quantity (Base)" := AssemblyHeader."Reserved Qty. (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);

        OnAfterTransferFromAsmOrder(Rec, AssemblyHeader);
    end;

    procedure TransferFromAsmOrderLine(AssemblyLine: Record "Assembly Line")
    begin
        Init();
        Type := Type::"Assembly Component";
        RecRef.GetTable(AssemblyLine);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := AssemblyLine."No.";
        "Variant Code" := AssemblyLine."Variant Code";
        "Location Code" := AssemblyLine."Location Code";
        "Availability Date" := AssemblyLine."Due Date";
        AssemblyLine.CalcFields("Reserved Qty. (Base)");
        "Remaining Quantity (Base)" := -AssemblyLine."Remaining Quantity (Base)";
        "Reserved Quantity (Base)" := -AssemblyLine."Reserved Qty. (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);

        OnAfterTransferFromAsmOrderLine(Rec, AssemblyLine);
    end;

    local procedure GetRefOrderTypeFromReqLine(ReqLineRefOrderType: Option): Integer
    var
        ReqLine: Record "Requisition Line";
    begin
        case ReqLineRefOrderType of
            ReqLine."Ref. Order Type"::" ":
                exit("Ref. Order Type"::" ");
            ReqLine."Ref. Order Type"::Purchase:
                exit("Ref. Order Type"::Purchase);
            ReqLine."Ref. Order Type"::"Prod. Order":
                exit("Ref. Order Type"::"Prod. Order");
            ReqLine."Ref. Order Type"::Transfer:
                exit("Ref. Order Type"::Transfer);
            ReqLine."Ref. Order Type"::Assembly:
                exit("Ref. Order Type"::Assembly);
        end;
    end;

    procedure CalcReservedQuantity(ItemLedgEntry: Record "Item Ledger Entry"): Decimal
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetRange("Source ID", '');
        ReservEntry.SetRange("Source Type", DATABASE::"Item Ledger Entry");
        ReservEntry.SetRange("Source Subtype", 0);
        ReservEntry.SetRange("Item No.", ItemLedgEntry."Item No.");
        ReservEntry.SetRange("Location Code", ItemLedgEntry."Location Code");
        ReservEntry.SetRange("Variant Code", ItemLedgEntry."Variant Code");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.CalcSums("Quantity (Base)");
        exit(ReservEntry."Quantity (Base)");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromSales(var InventoryEventBuffer: Record "Inventory Event Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromSalesReturn(var InventoryEventBuffer: Record "Inventory Event Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdComp(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromJobNeed(var InventoryEventBuffer: Record "Inventory Event Buffer"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromServiceNeed(var InventoryEventBuffer: Record "Inventory Event Buffer"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromOutboundTransfer(var InventoryEventBuffer: Record "Inventory Event Buffer"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPlanProdComp(var InventoryEventBuffer: Record "Inventory Event Buffer"; PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromReqLineTransDemand(var InventoryEventBuffer: Record "Inventory Event Buffer"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferInventoryQty(var InventoryEventBuffer: Record "Inventory Event Buffer"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPurchase(var InventoryEventBuffer: Record "Inventory Event Buffer"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPurchReturn(var InventoryEventBuffer: Record "Inventory Event Buffer"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromInboundTransOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromReqLine(var InventoryEventBuffer: Record "Inventory Event Buffer"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromForecast(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdForecastEntry: Record "Production Forecast Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromSalesBlanketOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromAsmOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromAsmOrderLine(var InventoryEventBuffer: Record "Inventory Event Buffer"; AssemblyLine: Record "Assembly Line")
    begin
    end;
}

