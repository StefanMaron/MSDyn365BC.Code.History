table 99000853 "Inventory Profile"
{
    Caption = 'Inventory Profile';

    fields
    {
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Attribute Priority"; Integer)
        {
            Caption = 'Attribute Priority';
        }
        field(5; "Order Priority"; Integer)
        {
            Caption = 'Order Priority';
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."),
                                                       Code = FIELD("Variant Code"));
        }
        field(13; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(14; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));
        }
        field(15; IsSupply; Boolean)
        {
            Caption = 'IsSupply';
        }
        field(16; "Order Relation"; Option)
        {
            Caption = 'Order Relation';
            OptionCaption = 'Normal,Safety Stock,Reorder Point';
            OptionMembers = Normal,"Safety Stock","Reorder Point";
        }
        field(21; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(22; "Source Order Status"; Integer)
        {
            Caption = 'Source Order Status';
        }
        field(23; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(24; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(25; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
        }
        field(26; "Source Prod. Order Line"; Integer)
        {
            Caption = 'Source Prod. Order Line';
        }
        field(27; "Primary Order Status"; Integer)
        {
            Caption = 'Primary Order Status';
        }
        field(28; "Primary Order No."; Code[20])
        {
            Caption = 'Primary Order No.';
        }
        field(29; "Primary Order Line"; Integer)
        {
            Caption = 'Primary Order Line';
        }
        field(30; "Primary Order Type"; Integer)
        {
            Caption = 'Primary Order Type';
        }
        field(31; "Original Quantity"; Decimal)
        {
            Caption = 'Original Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(32; "Remaining Quantity (Base)"; Decimal)
        {
            Caption = 'Remaining Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(33; "Untracked Quantity"; Decimal)
        {
            Caption = 'Untracked Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(34; "Original Due Date"; Date)
        {
            Caption = 'Original Due Date';
        }
        field(35; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(36; "Planning Flexibility"; Enum "Inventory Planning Flexibility")
        {
            Caption = 'Planning Flexibility';
        }
        field(37; "Fixed Date"; Date)
        {
            Caption = 'Fixed Date';
        }
        field(38; "Action Message"; Enum "Action Message Type")
        {
            Caption = 'Action Message';
        }
        field(39; Binding; Enum "Reservation Binding")
        {
            Caption = 'Binding';
            Editable = false;
        }
        field(40; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(41; "Min. Quantity"; Decimal)
        {
            Caption = 'Min. Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(42; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(43; "Planning Line No."; Integer)
        {
            Caption = 'Planning Line No.';
        }
        field(44; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
        }
        field(45; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
        }
        field(46; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(47; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(48; "Finished Quantity"; Decimal)
        {
            Caption = 'Finished Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(50; "Planning Level Code"; Integer)
        {
            Caption = 'Planning Level Code';
            Editable = false;
        }
        field(51; "Planning Line Phase"; Option)
        {
            Caption = 'Planning Line Phase';
            OptionCaption = ' ,Line Created,Routing Created,Exploded';
            OptionMembers = " ","Line Created","Routing Created",Exploded;
        }
        field(52; "Due Time"; Time)
        {
            Caption = 'Due Time';
        }
        field(53; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;
        }
        field(54; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
        }
        field(55; "Special Order"; Boolean)
        {
            Caption = 'Special Order';
        }
        field(56; "Ref. Order No."; Code[20])
        {
            Caption = 'Ref. Order No.';
            Editable = false;
        }
        field(57; "Ref. Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Ref. Line No.';
            Editable = false;
        }
        field(58; "Derived from Blanket Order"; Boolean)
        {
            Caption = 'Derived from Blanket Order';
        }
        field(59; "Ref. Blanket Order No."; Code[20])
        {
            Caption = 'Ref. Blanket Order No.';
        }
        field(60; "Tracking Reference"; Integer)
        {
            Caption = 'Tracking Reference';
        }
        field(61; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
        }
        field(62; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(63; "Max. Quantity"; Decimal)
        {
            Caption = 'Max. Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(64; "Safety Stock Quantity"; Decimal)
        {
            Caption = 'Safety Stock Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(65; "Is Exception Order"; Boolean)
        {
            Caption = 'Is Exception Order';
        }
        field(66; "Transfer Location Not Planned"; Boolean)
        {
            Caption = 'Transfer Location Not Planned';
        }
        field(67; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            Editable = false;
        }
        field(68; "Ref. Order Type"; Option)
        {
            Caption = 'Ref. Order Type';
            Editable = false;
            OptionCaption = ' ,Purchase,Prod. Order,Transfer,Assembly';
            OptionMembers = " ",Purchase,"Prod. Order",Transfer,Assembly;
        }
        field(69; "Disallow Cancellation"; Boolean)
        {
            Caption = 'Disallow Cancellation';
        }
        field(70; "MPS Order"; Boolean)
        {
            Caption = 'MPS Order';
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Variant Code", "Location Code", "Due Date", "Attribute Priority", "Order Priority")
        {
        }
        key(Key3; "Item No.", "Variant Code", "Location Code", IsSupply, "Primary Order Status", "Primary Order No.", "Due Date", "Order Priority")
        {
        }
        key(Key4; "Source Type", "Source Order Status", "Source ID", "Source Batch Name", "Source Ref. No.", "Source Prod. Order Line", IsSupply, "Due Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label 'Tab99000853, TransferToTrackingEntry: Illegal Source Type: %1.';
        UOMMgt: Codeunit "Unit of Measure Management";

    procedure TransferFromItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; var TrackingReservEntry: Record "Reservation Entry")
    var
        ReservEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        "Source Type" := DATABASE::"Item Ledger Entry";
        "Source Ref. No." := ItemLedgerEntry."Entry No.";
        "Item No." := ItemLedgerEntry."Item No.";
        "Variant Code" := ItemLedgerEntry."Variant Code";
        "Location Code" := ItemLedgerEntry."Location Code";
        Quantity := ItemLedgerEntry.Quantity;
        "Remaining Quantity" := ItemLedgerEntry."Remaining Quantity";
        "Finished Quantity" := Quantity - "Remaining Quantity";
        "Quantity (Base)" := ItemLedgerEntry.Quantity;
        "Remaining Quantity (Base)" := ItemLedgerEntry."Remaining Quantity";
        ItemLedgerEntry.CalcFields("Reserved Quantity");
        ItemLedgerEntry.SetReservationFilters(ReservEntry);
        AutoReservedQty := TransferBindings(ReservEntry, TrackingReservEntry);
        "Untracked Quantity" := ItemLedgerEntry."Remaining Quantity" - ItemLedgerEntry."Reserved Quantity" + AutoReservedQty;
        "Unit of Measure Code" := ItemLedgerEntry."Unit of Measure Code";
        "Qty. per Unit of Measure" := 1;
        IsSupply := ItemLedgerEntry.Positive;
        "Due Date" := ItemLedgerEntry."Posting Date";
        CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
        if TrackingExists then
            "Tracking Reference" := "Line No.";
        "Planning Flexibility" := "Planning Flexibility"::None;

        OnAfterTransferFromItemLedgerEntry(Rec, ItemLedgerEntry);
    end;

    procedure TransferFromSalesLine(var SalesLine: Record "Sales Line"; var TrackingReservEntry: Record "Reservation Entry")
    var
        ReservEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SetSource(DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.", '', 0);
        "Item No." := SalesLine."No.";
        "Variant Code" := SalesLine."Variant Code";
        "Location Code" := SalesLine."Location Code";
        "Bin Code" := SalesLine."Bin Code";
        SalesLine.CalcFields("Reserved Qty. (Base)");
        SalesLine.SetReservationFilters(ReservEntry);
        AutoReservedQty := -TransferBindings(ReservEntry, TrackingReservEntry);
        if SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" then begin
            SalesLine."Reserved Qty. (Base)" := -SalesLine."Reserved Qty. (Base)";
            AutoReservedQty := -AutoReservedQty;
        end;
        "Untracked Quantity" := SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)" + AutoReservedQty;
        Quantity := SalesLine.Quantity;
        "Remaining Quantity" := SalesLine."Outstanding Quantity";
        "Finished Quantity" := SalesLine."Quantity Shipped";
        "Quantity (Base)" := SalesLine."Quantity (Base)";
        "Remaining Quantity (Base)" := SalesLine."Outstanding Qty. (Base)";
        "Unit of Measure Code" := SalesLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := SalesLine."Qty. per Unit of Measure";
        if SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" then
            ChangeSign;
        IsSupply := "Untracked Quantity" < 0;
        "Due Date" := SalesLine."Shipment Date";
        "Planning Flexibility" := "Planning Flexibility"::None;
        if SalesLine."Blanket Order No." <> '' then begin
            "Sell-to Customer No." := SalesLine."Sell-to Customer No.";
            "Derived from Blanket Order" := true;
            "Ref. Blanket Order No." := SalesLine."Blanket Order No.";
        end;
        "Drop Shipment" := SalesLine."Drop Shipment";
        "Special Order" := SalesLine."Special Order";

        OnAfterTransferFromSalesLine(Rec, SalesLine);
    end;

    procedure TransferFromComponent(var ProdOrderComp: Record "Prod. Order Component"; var TrackingReservEntry: Record "Reservation Entry")
    var
        ReservEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        SetSource(
          DATABASE::"Prod. Order Component", ProdOrderComp.Status, ProdOrderComp."Prod. Order No.",
          ProdOrderComp."Line No.", '', ProdOrderComp."Prod. Order Line No.");
        "Ref. Order Type" := "Ref. Order Type"::"Prod. Order";
        "Ref. Order No." := ProdOrderComp."Prod. Order No.";
        "Ref. Line No." := ProdOrderComp."Prod. Order Line No.";
        "Item No." := ProdOrderComp."Item No.";
        "Variant Code" := ProdOrderComp."Variant Code";
        "Location Code" := ProdOrderComp."Location Code";
        "Bin Code" := ProdOrderComp."Bin Code";
        "Due Date" := ProdOrderComp."Due Date";
        "Due Time" := ProdOrderComp."Due Time";
        "Planning Flexibility" := "Planning Flexibility"::None;
        "Planning Level Code" := ProdOrderComp."Planning Level Code";
        ProdOrderComp.CalcFields("Reserved Qty. (Base)");
        if ProdOrderComp.Status in [ProdOrderComp.Status::Released, ProdOrderComp.Status::Finished] then
            ProdOrderComp.CalcFields("Act. Consumption (Qty)");
        ProdOrderComp.SetReservationFilters(ReservEntry);
        AutoReservedQty := -TransferBindings(ReservEntry, TrackingReservEntry);
        "Untracked Quantity" := ProdOrderComp."Remaining Qty. (Base)" - ProdOrderComp."Reserved Qty. (Base)" + AutoReservedQty;
        Quantity := ProdOrderComp."Expected Quantity";
        "Remaining Quantity" := ProdOrderComp."Remaining Quantity";
        "Finished Quantity" := ProdOrderComp."Act. Consumption (Qty)";
        "Quantity (Base)" := ProdOrderComp."Expected Qty. (Base)";
        "Remaining Quantity (Base)" := ProdOrderComp."Remaining Qty. (Base)";
        "Unit of Measure Code" := ProdOrderComp."Unit of Measure Code";
        "Qty. per Unit of Measure" := ProdOrderComp."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" < 0;

        OnAfterTransferFromComponent(Rec, ProdOrderComp);
    end;

    procedure TransferFromPlanComponent(var PlanningComponent: Record "Planning Component"; var TrackingReservEntry: Record "Reservation Entry")
    var
        ProdOrderComp: Record "Prod. Order Component";
        AsmLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        ReservedQty: Decimal;
        AutoReservedQty: Decimal;
    begin
        SetSource(
          DATABASE::"Planning Component", 0, PlanningComponent."Worksheet Template Name", PlanningComponent."Line No.",
          PlanningComponent."Worksheet Batch Name", PlanningComponent."Worksheet Line No.");
        "Ref. Order Type" := PlanningComponent."Ref. Order Type";
        "Ref. Order No." := PlanningComponent."Ref. Order No.";
        "Ref. Line No." := PlanningComponent."Ref. Order Line No.";
        "Item No." := PlanningComponent."Item No.";
        "Variant Code" := PlanningComponent."Variant Code";
        "Location Code" := PlanningComponent."Location Code";
        "Bin Code" := PlanningComponent."Bin Code";
        "Due Date" := PlanningComponent."Due Date";
        "Due Time" := PlanningComponent."Due Time";
        "Planning Flexibility" := "Planning Flexibility"::None;
        "Planning Level Code" := PlanningComponent."Planning Level Code";
        PlanningComponent.SetReservationFilters(ReservEntry);
        AutoReservedQty := -TransferBindings(ReservEntry, TrackingReservEntry);
        "Untracked Quantity" :=
          PlanningComponent."Expected Quantity (Base)" - PlanningComponent."Reserved Qty. (Base)" + AutoReservedQty;
        case PlanningComponent."Ref. Order Type" of
            PlanningComponent."Ref. Order Type"::"Prod. Order":
                if ProdOrderComp.Get(
                     PlanningComponent."Ref. Order Status",
                     PlanningComponent."Ref. Order No.",
                     PlanningComponent."Ref. Order Line No.",
                     PlanningComponent."Line No.")
                then begin
                    "Original Quantity" := ProdOrderComp."Expected Quantity";
                    ProdOrderComp.CalcFields("Reserved Qty. (Base)");
                    if ProdOrderComp."Reserved Qty. (Base)" > 0 then begin
                        ReservedQty := ProdOrderComp."Reserved Qty. (Base)";
                        ProdOrderComp.SetReservationFilters(ReservEntry);
                        CalcReservedQty(ReservEntry, ReservedQty);
                        if ReservedQty > "Untracked Quantity" then
                            "Untracked Quantity" := 0
                        else
                            "Untracked Quantity" := "Untracked Quantity" - ReservedQty;
                    end;
                end else begin
                    "Primary Order Type" := DATABASE::"Planning Component";
                    "Primary Order Status" := PlanningComponent."Ref. Order Status";
                    "Primary Order No." := PlanningComponent."Ref. Order No.";
                end;
            PlanningComponent."Ref. Order Type"::Assembly:
                if AsmLine.Get(
                     PlanningComponent."Ref. Order Status",
                     PlanningComponent."Ref. Order No.",
                     PlanningComponent."Ref. Order Line No.")
                then begin
                    "Original Quantity" := AsmLine.Quantity;
                    AsmLine.CalcFields("Reserved Qty. (Base)");
                    if AsmLine."Reserved Qty. (Base)" > 0 then begin
                        ReservedQty := AsmLine."Reserved Qty. (Base)";
                        AsmLine.SetReservationFilters(ReservEntry);
                        CalcReservedQty(ReservEntry, ReservedQty);
                        if ReservedQty > "Untracked Quantity" then
                            "Untracked Quantity" := 0
                        else
                            "Untracked Quantity" := "Untracked Quantity" - ReservedQty;
                    end;
                end else begin
                    "Primary Order Type" := DATABASE::"Planning Component";
                    "Primary Order Status" := PlanningComponent."Ref. Order Status";
                    "Primary Order No." := PlanningComponent."Ref. Order No.";
                end;
        end;
        Quantity := PlanningComponent."Expected Quantity";
        "Remaining Quantity" := PlanningComponent."Expected Quantity";
        "Finished Quantity" := 0;
        "Quantity (Base)" := PlanningComponent."Expected Quantity (Base)";
        "Remaining Quantity (Base)" := PlanningComponent."Expected Quantity (Base)";
        "Unit of Measure Code" := PlanningComponent."Unit of Measure Code";
        "Qty. per Unit of Measure" := PlanningComponent."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" < 0;

        OnAfterTransferFromPlanComponent(Rec, PlanningComponent);
    end;

    local procedure CalcReservedQty(var ReservEntry: Record "Reservation Entry"; var ReservedQty: Decimal)
    var
        OppositeReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line",
          "Reservation Status");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.SetRange(Binding, ReservEntry.Binding::"Order-to-Order");
        if ReservEntry.Find('-') then begin
            // Retrieving information about primary order:
            if ReservEntry.Positive then
                OppositeReservEntry.Get(ReservEntry."Entry No.", not ReservEntry.Positive)
            else
                OppositeReservEntry := ReservEntry;
            if "Primary Order No." = '' then begin
                "Primary Order Type" := OppositeReservEntry."Source Type";
                "Primary Order Status" := OppositeReservEntry."Source Subtype";
                "Primary Order No." := OppositeReservEntry."Source ID";
                if OppositeReservEntry."Source Type" = DATABASE::"Prod. Order Component" then
                    "Primary Order Line" := OppositeReservEntry."Source Prod. Order Line";
            end;

            Binding := ReservEntry.Binding;
            repeat
                ReservedQty := ReservedQty + ReservEntry."Quantity (Base)";
            until ReservEntry.Next = 0;
        end;
    end;

    procedure TransferFromPurchaseLine(var PurchaseLine: Record "Purchase Line"; var TrackingReservEntry: Record "Reservation Entry")
    var
        ReservEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        SetSource(DATABASE::"Purchase Line", PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.", '', 0);
        "Item No." := PurchaseLine."No.";
        "Variant Code" := PurchaseLine."Variant Code";
        "Location Code" := PurchaseLine."Location Code";
        "Bin Code" := PurchaseLine."Bin Code";
        PurchaseLine.SetReservationFilters(ReservEntry);
        AutoReservedQty := TransferBindings(ReservEntry, TrackingReservEntry);
        PurchaseLine.CalcFields("Reserved Qty. (Base)");
        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Return Order" then begin
            AutoReservedQty := -AutoReservedQty;
            PurchaseLine."Reserved Qty. (Base)" := -PurchaseLine."Reserved Qty. (Base)";
        end;
        "Untracked Quantity" := PurchaseLine."Outstanding Qty. (Base)" - PurchaseLine."Reserved Qty. (Base)" + AutoReservedQty;
        "Min. Quantity" := PurchaseLine."Reserved Qty. (Base)" - AutoReservedQty;
        Quantity := PurchaseLine.Quantity;
        "Remaining Quantity" := PurchaseLine."Outstanding Quantity";
        "Finished Quantity" := PurchaseLine."Quantity Received";
        "Quantity (Base)" := PurchaseLine."Quantity (Base)";
        "Remaining Quantity (Base)" := PurchaseLine."Outstanding Qty. (Base)";
        "Unit of Measure Code" := PurchaseLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := PurchaseLine."Qty. per Unit of Measure";
        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Return Order" then begin
            ChangeSign;
            "Planning Flexibility" := "Planning Flexibility"::None;
        end else
            "Planning Flexibility" := PurchaseLine."Planning Flexibility";
        IsSupply := "Untracked Quantity" >= 0;
        "Due Date" := PurchaseLine."Expected Receipt Date";
        "Drop Shipment" := PurchaseLine."Drop Shipment";
        "Special Order" := PurchaseLine."Special Order";

        OnAfterTransferFromPurchaseLine(Rec, PurchaseLine);
    end;

    procedure TransferFromProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; var TrackingReservEntry: Record "Reservation Entry")
    var
        ReservEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        SetSource(DATABASE::"Prod. Order Line", ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", 0, '', ProdOrderLine."Line No.");
        "Item No." := ProdOrderLine."Item No.";
        "Variant Code" := ProdOrderLine."Variant Code";
        "Location Code" := ProdOrderLine."Location Code";
        "Bin Code" := ProdOrderLine."Bin Code";
        "Due Date" := ProdOrderLine."Due Date";
        "Starting Date" := ProdOrderLine."Starting Date";
        "Planning Flexibility" := ProdOrderLine."Planning Flexibility";
        "Planning Level Code" := ProdOrderLine."Planning Level Code";
        ProdOrderLine.CalcFields("Reserved Qty. (Base)");
        ProdOrderLine.SetReservationFilters(ReservEntry);
        AutoReservedQty := TransferBindings(ReservEntry, TrackingReservEntry);
        "Untracked Quantity" := ProdOrderLine."Remaining Qty. (Base)" - ProdOrderLine."Reserved Qty. (Base)" + AutoReservedQty;
        "Min. Quantity" := ProdOrderLine."Reserved Qty. (Base)" - AutoReservedQty;
        Quantity := ProdOrderLine.Quantity;
        "Remaining Quantity" := ProdOrderLine."Remaining Quantity";
        "Finished Quantity" := ProdOrderLine."Finished Quantity";
        "Quantity (Base)" := ProdOrderLine."Quantity (Base)";
        "Remaining Quantity (Base)" := ProdOrderLine."Remaining Qty. (Base)";
        "Unit of Measure Code" := ProdOrderLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := ProdOrderLine."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" >= 0;

        OnAfterTransferFromProdOrderLine(Rec, ProdOrderLine);
    end;

    procedure TransferFromAsmLine(var AsmLine: Record "Assembly Line"; var TrackingReservEntry: Record "Reservation Entry")
    var
        ReservEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        AsmLine.TestField(Type, AsmLine.Type::Item);
        SetSource(DATABASE::"Assembly Line", AsmLine."Document Type", AsmLine."Document No.", AsmLine."Line No.", '', 0);
        "Ref. Order Type" := "Ref. Order Type"::Assembly;
        "Ref. Order No." := AsmLine."Document No.";
        "Ref. Line No." := AsmLine."Line No.";
        "Item No." := AsmLine."No.";
        "Variant Code" := AsmLine."Variant Code";
        "Location Code" := AsmLine."Location Code";
        "Bin Code" := AsmLine."Bin Code";
        AsmLine.CalcFields("Reserved Qty. (Base)");
        AsmLine.SetReservationFilters(ReservEntry);
        AutoReservedQty := -TransferBindings(ReservEntry, TrackingReservEntry);
        "Untracked Quantity" := AsmLine."Remaining Quantity (Base)" - AsmLine."Reserved Qty. (Base)" + AutoReservedQty;
        Quantity := AsmLine.Quantity;
        "Remaining Quantity" := AsmLine."Remaining Quantity";
        "Finished Quantity" := AsmLine."Consumed Quantity";
        "Quantity (Base)" := AsmLine."Quantity (Base)";
        "Remaining Quantity (Base)" := AsmLine."Remaining Quantity (Base)";
        "Unit of Measure Code" := AsmLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := AsmLine."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" < 0;
        "Due Date" := AsmLine."Due Date";
        "Planning Flexibility" := "Planning Flexibility"::None;

        OnAfterTransferFromAsmLine(Rec, AsmLine);
    end;

    procedure TransferFromAsmHeader(var AsmHeader: Record "Assembly Header"; var TrackingReservEntry: Record "Reservation Entry")
    var
        ReservEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        SetSource(DATABASE::"Assembly Header", AsmHeader."Document Type", AsmHeader."No.", 0, '', 0);
        "Item No." := AsmHeader."Item No.";
        "Variant Code" := AsmHeader."Variant Code";
        "Location Code" := AsmHeader."Location Code";
        "Bin Code" := AsmHeader."Bin Code";
        AsmHeader.SetReservationFilters(ReservEntry);
        AutoReservedQty := TransferBindings(ReservEntry, TrackingReservEntry);
        AsmHeader.CalcFields("Reserved Qty. (Base)");
        "Untracked Quantity" := AsmHeader."Remaining Quantity (Base)" - AsmHeader."Reserved Qty. (Base)" + AutoReservedQty;
        "Min. Quantity" := AsmHeader."Reserved Qty. (Base)" - AutoReservedQty;
        Quantity := AsmHeader.Quantity;
        "Remaining Quantity" := AsmHeader."Remaining Quantity";
        "Finished Quantity" := AsmHeader."Assembled Quantity";
        "Quantity (Base)" := AsmHeader."Quantity (Base)";
        "Remaining Quantity (Base)" := AsmHeader."Remaining Quantity (Base)";
        "Unit of Measure Code" := AsmHeader."Unit of Measure Code";
        "Qty. per Unit of Measure" := AsmHeader."Qty. per Unit of Measure";
        "Planning Flexibility" := AsmHeader."Planning Flexibility";
        IsSupply := "Untracked Quantity" >= 0;
        "Due Date" := AsmHeader."Due Date";

        OnAfterTransferFromAsmHeader(Rec, AsmHeader);
    end;

    procedure TransferFromRequisitionLine(var RequisitionLine: Record "Requisition Line"; var TrackingEntry: Record "Reservation Entry")
    var
        ReservEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        RequisitionLine.TestField(Type, RequisitionLine.Type::Item);
        SetSource(
          DATABASE::"Requisition Line", 0, RequisitionLine."Worksheet Template Name", RequisitionLine."Line No.",
          RequisitionLine."Journal Batch Name", 0);
        "Item No." := RequisitionLine."No.";
        "Variant Code" := RequisitionLine."Variant Code";
        "Location Code" := RequisitionLine."Location Code";
        "Bin Code" := RequisitionLine."Bin Code";
        RequisitionLine.CalcFields("Reserved Qty. (Base)");
        RequisitionLine.SetReservationFilters(ReservEntry);
        AutoReservedQty := TransferBindings(ReservEntry, TrackingEntry);
        "Untracked Quantity" := RequisitionLine."Quantity (Base)" - RequisitionLine."Reserved Qty. (Base)" + AutoReservedQty;
        "Min. Quantity" := RequisitionLine."Reserved Qty. (Base)" - AutoReservedQty;
        Quantity := RequisitionLine.Quantity;
        "Finished Quantity" := 0;
        "Remaining Quantity" := RequisitionLine.Quantity;
        "Quantity (Base)" := RequisitionLine."Quantity (Base)";
        "Remaining Quantity (Base)" := RequisitionLine."Quantity (Base)";
        "Unit of Measure Code" := RequisitionLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := RequisitionLine."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" >= 0;
        "Due Date" := RequisitionLine."Due Date";
        "Planning Flexibility" := RequisitionLine."Planning Flexibility";

        OnAfterTransferFromRequisitionLine(Rec, RequisitionLine);
    end;

    procedure TransferFromOutboundTransfPlan(var RequisitionLine: Record "Requisition Line"; var TrackingEntry: Record "Reservation Entry")
    var
        ReservEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        RequisitionLine.TestField(Type, RequisitionLine.Type::Item);
        SetSource(
          DATABASE::"Requisition Line", 1, RequisitionLine."Worksheet Template Name", RequisitionLine."Line No.",
          RequisitionLine."Journal Batch Name", 0);
        "Item No." := RequisitionLine."No.";
        "Variant Code" := RequisitionLine."Variant Code";
        "Location Code" := RequisitionLine."Transfer-from Code";
        "Bin Code" := RequisitionLine."Bin Code";
        RequisitionLine.CalcFields("Reserved Qty. (Base)");
        RequisitionLine.SetReservationFilters(ReservEntry);
        AutoReservedQty := TransferBindings(ReservEntry, TrackingEntry);
        "Untracked Quantity" := RequisitionLine."Quantity (Base)" - RequisitionLine."Reserved Qty. (Base)" + AutoReservedQty;
        "Min. Quantity" := RequisitionLine."Reserved Qty. (Base)" - AutoReservedQty;
        Quantity := RequisitionLine.Quantity;
        "Finished Quantity" := 0;
        "Remaining Quantity" := RequisitionLine.Quantity;
        "Quantity (Base)" := RequisitionLine."Quantity (Base)";
        "Remaining Quantity (Base)" := RequisitionLine."Quantity (Base)";
        "Unit of Measure Code" := RequisitionLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := RequisitionLine."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" <= 0;
        "Due Date" := RequisitionLine."Transfer Shipment Date";

        OnAfterTransferFromOutboundTransfPlan(Rec, RequisitionLine);
    end;

    procedure TransferFromOutboundTransfer(var TransLine: Record "Transfer Line"; var TrackingEntry: Record "Reservation Entry")
    var
        ReservEntry: Record "Reservation Entry";
        DummyTempTrackingEntry: Record "Reservation Entry" temporary;
        CrntInvProfile: Record "Inventory Profile";
        AutoReservedQty: Decimal;
        MinQtyInbnd: Decimal;
        MinQtyOutbnd: Decimal;
    begin
        SetSource(DATABASE::"Transfer Line", 0, TransLine."Document No.", TransLine."Line No.", '', 0);
        "Item No." := TransLine."Item No.";
        "Variant Code" := TransLine."Variant Code";
        "Location Code" := TransLine."Transfer-from Code";

        TransLine.CalcFields("Reserved Qty. Outbnd. (Base)", "Reserved Qty. Inbnd. (Base)");
        TransLine.SetReservationFilters(ReservEntry, 0);
        AutoReservedQty := -TransferBindings(ReservEntry, TrackingEntry);
        MinQtyOutbnd := TransLine."Reserved Qty. Outbnd. (Base)" - AutoReservedQty;

        CrntInvProfile := Rec;
        TransLine.SetReservationFilters(ReservEntry, 1);
        AutoReservedQty := TransferBindings(ReservEntry, DummyTempTrackingEntry);
        MinQtyInbnd := TransLine."Reserved Qty. Inbnd. (Base)" - AutoReservedQty;
        Rec := CrntInvProfile;

        if MinQtyInbnd > MinQtyOutbnd then
            "Min. Quantity" := MinQtyInbnd
        else
            "Min. Quantity" := MinQtyOutbnd;

        "Untracked Quantity" := TransLine."Outstanding Qty. (Base)" - MinQtyOutbnd;
        Quantity := TransLine.Quantity;
        "Remaining Quantity" := TransLine."Outstanding Quantity";
        "Finished Quantity" := TransLine."Quantity Shipped";
        "Quantity (Base)" := TransLine."Quantity (Base)";
        "Remaining Quantity (Base)" := TransLine."Outstanding Qty. (Base)";
        "Unit of Measure Code" := TransLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := TransLine."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" < 0;
        "Due Date" := TransLine."Shipment Date";
        "Planning Flexibility" := TransLine."Planning Flexibility";

        OnAfterTransferFromOutboundTransfer(Rec, TransLine);
    end;

    procedure TransferFromInboundTransfer(var TransLine: Record "Transfer Line"; var TrackingReservEntry: Record "Reservation Entry")
    var
        ReservEntry: Record "Reservation Entry";
        DummyTempTrackingEntry: Record "Reservation Entry" temporary;
        CrntInvProfile: Record "Inventory Profile";
        AutoReservedQty: Decimal;
        MinQtyInbnd: Decimal;
        MinQtyOutbnd: Decimal;
    begin
        SetSource(DATABASE::"Transfer Line", 1, TransLine."Document No.", TransLine."Line No.", '', TransLine."Derived From Line No.");
        "Item No." := TransLine."Item No.";
        "Variant Code" := TransLine."Variant Code";
        "Location Code" := TransLine."Transfer-to Code";

        TransLine.CalcFields("Reserved Qty. Outbnd. (Base)", "Reserved Qty. Inbnd. (Base)");
        TransLine.SetReservationFilters(ReservEntry, 1);
        AutoReservedQty := TransferBindings(ReservEntry, TrackingReservEntry);
        MinQtyInbnd := TransLine."Reserved Qty. Inbnd. (Base)" - AutoReservedQty;

        CrntInvProfile := Rec;
        TransLine.SetReservationFilters(ReservEntry, 0);
        AutoReservedQty := -TransferBindings(ReservEntry, DummyTempTrackingEntry);
        MinQtyOutbnd := TransLine."Reserved Qty. Outbnd. (Base)" - AutoReservedQty;
        Rec := CrntInvProfile;

        if MinQtyInbnd > MinQtyOutbnd then
            "Min. Quantity" := MinQtyInbnd
        else
            "Min. Quantity" := MinQtyOutbnd;

        "Untracked Quantity" := TransLine."Outstanding Qty. (Base)" - MinQtyInbnd;
        Quantity := TransLine.Quantity;
        "Remaining Quantity" := TransLine."Outstanding Quantity";
        "Finished Quantity" := TransLine."Quantity Received";
        "Quantity (Base)" := TransLine."Quantity (Base)";
        "Remaining Quantity (Base)" := TransLine."Outstanding Qty. (Base)";
        "Unit of Measure Code" := TransLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := TransLine."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" >= 0;
        "Starting Date" := TransLine."Shipment Date";
        "Due Date" := TransLine."Receipt Date";
        "Planning Flexibility" := TransLine."Planning Flexibility";

        OnAfterTransferFromInboundTransfer(Rec, TransLine);
    end;

    procedure TransferFromServLine(var ServLine: Record "Service Line"; var TrackingReservEntry: Record "Reservation Entry")
    var
        ReservEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        ServLine.TestField(Type, ServLine.Type::Item);
        SetSource(DATABASE::"Service Line", ServLine."Document Type", ServLine."Document No.", ServLine."Line No.", '', 0);
        "Item No." := ServLine."No.";
        "Variant Code" := ServLine."Variant Code";
        "Location Code" := ServLine."Location Code";
        ServLine.CalcFields("Reserved Qty. (Base)");
        ServLine.SetReservationFilters(ReservEntry);
        AutoReservedQty := -TransferBindings(ReservEntry, TrackingReservEntry);
        "Untracked Quantity" := ServLine."Outstanding Qty. (Base)" - ServLine."Reserved Qty. (Base)" + AutoReservedQty;
        Quantity := ServLine.Quantity;
        "Remaining Quantity" := ServLine."Outstanding Quantity";
        "Finished Quantity" := ServLine."Quantity Shipped";
        "Quantity (Base)" := ServLine."Quantity (Base)";
        "Remaining Quantity (Base)" := ServLine."Outstanding Qty. (Base)";
        "Unit of Measure Code" := ServLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := ServLine."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" < 0;
        "Due Date" := ServLine."Needed by Date";
        "Planning Flexibility" := "Planning Flexibility"::None;

        OnAfterTransferFromServLine(Rec, ServLine);
    end;

    procedure TransferFromJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; var TrackingReservEntry: Record "Reservation Entry")
    var
        ReservEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        SetSource(
          DATABASE::"Job Planning Line", JobPlanningLine.Status, JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", '', 0);
        "Item No." := JobPlanningLine."No.";
        "Variant Code" := JobPlanningLine."Variant Code";
        "Location Code" := JobPlanningLine."Location Code";
        JobPlanningLine.CalcFields("Reserved Qty. (Base)");
        JobPlanningLine.SetReservationFilters(ReservEntry);
        AutoReservedQty := -TransferBindings(ReservEntry, TrackingReservEntry);
        "Untracked Quantity" := JobPlanningLine."Remaining Qty. (Base)" - JobPlanningLine."Reserved Qty. (Base)" + AutoReservedQty;
        Quantity := JobPlanningLine.Quantity;
        "Remaining Quantity" := JobPlanningLine."Remaining Qty.";
        "Finished Quantity" := JobPlanningLine."Qty. Posted";
        "Quantity (Base)" := JobPlanningLine."Quantity (Base)";
        "Remaining Quantity (Base)" := JobPlanningLine."Remaining Qty. (Base)";
        "Unit of Measure Code" := JobPlanningLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := JobPlanningLine."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" < 0;
        "Due Date" := JobPlanningLine."Planning Date";
        "Planning Flexibility" := "Planning Flexibility"::None;

        OnAfterTransferFromJobPlanningLine(Rec, JobPlanningLine);
    end;

    procedure TransferBindings(var ReservEntry: Record "Reservation Entry"; var TrackingEntry: Record "Reservation Entry"): Decimal
    var
        OppositeReservEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
        Found: Boolean;
        InsertTracking: Boolean;
    begin
        ReservEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line",
          "Reservation Status");
        if ReservEntry.FindSet then
            repeat
                InsertTracking := not
                  ((ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Reservation) and
                   (ReservEntry.Binding = ReservEntry.Binding::" "));
                if InsertTracking and ReservEntry.TrackingExists and
                   (ReservEntry."Source Type" <> DATABASE::"Item Ledger Entry")
                then begin
                    TrackingEntry := ReservEntry;
                    TrackingEntry.Insert();
                end;
                if ReservEntry."Reservation Status" < ReservEntry."Reservation Status"::Surplus
                then
                    if (ReservEntry.Binding = ReservEntry.Binding::"Order-to-Order")
                    then begin
                        if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Reservation then
                            AutoReservedQty := AutoReservedQty + ReservEntry."Quantity (Base)";
                        if not Found then begin
                            if ReservEntry.Positive then
                                OppositeReservEntry.Get(ReservEntry."Entry No.", not ReservEntry.Positive)
                            else
                                OppositeReservEntry := ReservEntry;
                            if "Primary Order No." = '' then begin
                                "Primary Order Type" := OppositeReservEntry."Source Type";
                                "Primary Order Status" := OppositeReservEntry."Source Subtype";
                                "Primary Order No." := OppositeReservEntry."Source ID";
                                if OppositeReservEntry."Source Type" <> DATABASE::"Prod. Order Component" then
                                    "Primary Order Line" := OppositeReservEntry."Source Ref. No."
                                else
                                    "Primary Order Line" := OppositeReservEntry."Source Prod. Order Line";
                            end;
                            Binding := ReservEntry.Binding;
                            "Disallow Cancellation" := ReservEntry."Disallow Cancellation";
                            Found := true;
                        end;
                    end else
                        if (ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Reservation) and
                           (("Fixed Date" = 0D) or ("Fixed Date" > ReservEntry."Shipment Date"))
                        then
                            "Fixed Date" := ReservEntry."Shipment Date";
            until ReservEntry.Next = 0;
        exit(AutoReservedQty);
    end;

    procedure TransferQtyFromItemTrgkEntry(var ItemTrackingEntry: Record "Reservation Entry")
    begin
        "Original Quantity" := 0;
        Quantity := ItemTrackingEntry.Quantity;
        "Quantity (Base)" := ItemTrackingEntry."Quantity (Base)";
        "Finished Quantity" := 0;
        "Min. Quantity" := 0;
        "Remaining Quantity" := ItemTrackingEntry.Quantity;
        "Remaining Quantity (Base)" := ItemTrackingEntry."Quantity (Base)";
        "Untracked Quantity" := ItemTrackingEntry."Quantity (Base)";
        if not IsSupply then
            ChangeSign;
    end;

    procedure ReduceQtyByItemTracking(var NewInvProfile: Record "Inventory Profile")
    begin
        "Original Quantity" -= NewInvProfile."Original Quantity";
        Quantity -= NewInvProfile.Quantity;
        "Quantity (Base)" -= NewInvProfile."Quantity (Base)";
        "Finished Quantity" -= NewInvProfile."Finished Quantity";
        "Remaining Quantity" -= NewInvProfile."Remaining Quantity";
        "Remaining Quantity (Base)" -= NewInvProfile."Remaining Quantity (Base)";
        "Untracked Quantity" -= NewInvProfile."Untracked Quantity";
    end;

    procedure ChangeSign()
    begin
        "Original Quantity" := -"Original Quantity";
        "Remaining Quantity (Base)" := -"Remaining Quantity (Base)";
        "Untracked Quantity" := -"Untracked Quantity";
        "Quantity (Base)" := -"Quantity (Base)";
        Quantity := -Quantity;
        "Remaining Quantity" := -"Remaining Quantity";
        "Finished Quantity" := -"Finished Quantity";
    end;

    procedure TransferToTrackingEntry(var TrkgReservEntry: Record "Reservation Entry"; UseSecondaryFields: Boolean)
    var
        ReqLine: Record "Requisition Line";
        IsHandled: Boolean;
    begin
        case "Source Type" of
            0:
                begin
                    // Surplus, Reorder Point
                    TrkgReservEntry."Reservation Status" := TrkgReservEntry."Reservation Status"::Surplus;
                    TrkgReservEntry."Suppressed Action Msg." := true;
                    exit;
                end;
            DATABASE::"Production Forecast Entry":
                begin
                    // Will be marked as Surplus
                    TrkgReservEntry."Reservation Status" := TrkgReservEntry."Reservation Status"::Surplus;
                    TrkgReservEntry.SetSource(DATABASE::"Production Forecast Entry", 0, "Source ID", 0, '', 0);
                    TrkgReservEntry."Suppressed Action Msg." := true;
                end;
            DATABASE::"Sales Line":
                begin
                    if "Source Order Status" = 4 then begin
                        // Blanket Order will be marked as Surplus
                        TrkgReservEntry."Reservation Status" := TrkgReservEntry."Reservation Status"::Surplus;
                        TrkgReservEntry."Suppressed Action Msg." := true;
                    end;
                    TrkgReservEntry.SetSource(DATABASE::"Sales Line", "Source Order Status", "Source ID", "Source Ref. No.", '', 0);
                end;
            DATABASE::"Requisition Line":
                TrkgReservEntry.SetSource(
                  DATABASE::"Requisition Line", "Source Order Status", "Source ID", "Source Ref. No.", "Source Batch Name", 0);
            DATABASE::"Purchase Line":
                TrkgReservEntry.SetSource(
                  DATABASE::"Purchase Line", "Source Order Status", "Source ID", "Source Ref. No.", '', 0);
            DATABASE::"Item Ledger Entry":
                TrkgReservEntry.SetSource(
                  DATABASE::"Item Ledger Entry", 0, '', "Source Ref. No.", '', 0);
            DATABASE::"Prod. Order Line":
                TrkgReservEntry.SetSource(
                  DATABASE::"Prod. Order Line", "Source Order Status", "Source ID", 0, '', "Source Prod. Order Line");
            DATABASE::"Prod. Order Component":
                TrkgReservEntry.SetSource(
                  DATABASE::"Prod. Order Component", "Source Order Status", "Source ID", "Source Ref. No.", '', "Source Prod. Order Line");
            DATABASE::"Planning Component":
                if UseSecondaryFields then begin
                    ReqLine.Get("Source ID", "Source Batch Name", "Source Prod. Order Line");
                    case ReqLine."Ref. Order Type" of
                        ReqLine."Ref. Order Type"::"Prod. Order":
                            TrkgReservEntry.SetSource(
                              DATABASE::"Prod. Order Component", "Source Order Status", "Ref. Order No.", "Source Ref. No.", '', "Ref. Line No.");
                        ReqLine."Ref. Order Type"::Assembly:
                            TrkgReservEntry.SetSource(
                              DATABASE::"Assembly Line", "Source Order Status", "Ref. Order No.", "Source Ref. No.", '', "Ref. Line No.");
                    end;
                end else
                    TrkgReservEntry.SetSource(
                      DATABASE::"Planning Component", 0, "Source ID", "Source Ref. No.", "Source Batch Name", "Source Prod. Order Line");
            DATABASE::"Assembly Line":
                begin
                    if "Source Order Status" = 4 then begin
                        // Blanket Order will be marked as Surplus
                        TrkgReservEntry."Reservation Status" := TrkgReservEntry."Reservation Status"::Surplus;
                        TrkgReservEntry."Suppressed Action Msg." := true;
                    end;
                    TrkgReservEntry.SetSource(DATABASE::"Assembly Line", "Source Order Status", "Source ID", "Source Ref. No.", '', 0);
                end;
            DATABASE::"Assembly Header":
                TrkgReservEntry.SetSource(DATABASE::"Assembly Header", "Source Order Status", "Source ID", "Source Ref. No.", '', 0);
            DATABASE::"Transfer Line":
                if IsSupply then
                    TrkgReservEntry.SetSource(DATABASE::"Transfer Line", 1, "Source ID", "Source Ref. No.", '', "Source Prod. Order Line")
                else
                    TrkgReservEntry.SetSource(DATABASE::"Transfer Line", 0, "Source ID", "Source Ref. No.", '', 0);
            DATABASE::"Service Line":
                TrkgReservEntry.SetSource(DATABASE::"Service Line", "Source Order Status", "Source ID", "Source Ref. No.", '', 0);
            DATABASE::"Job Planning Line":
                TrkgReservEntry.SetSource(DATABASE::"Job Planning Line", "Source Order Status", "Source ID", "Source Ref. No.", '', 0);
            else begin
                    IsHandled := false;
                    OnTransferToTrackingEntrySourceTypeElseCase(Rec, TrkgReservEntry, UseSecondaryFields, IsHandled);
                    if not IsHandled then
                        Error(Text000, "Source Type");
                end;
        end;

        TrkgReservEntry."Item No." := "Item No.";
        TrkgReservEntry."Location Code" := "Location Code";
        TrkgReservEntry.Description := '';
        TrkgReservEntry."Creation Date" := Today;
        TrkgReservEntry."Created By" := UserId;
        TrkgReservEntry."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
        TrkgReservEntry."Variant Code" := "Variant Code";
        TrkgReservEntry.Binding := Binding;
        TrkgReservEntry."Disallow Cancellation" := "Disallow Cancellation";
        TrkgReservEntry.CopyTrackingFromInvtProfile(Rec);
        TrkgReservEntry."Expiration Date" := "Expiration Date";

        if IsSupply then
            TrkgReservEntry."Quantity (Base)" := "Untracked Quantity"
        else
            TrkgReservEntry."Quantity (Base)" := -"Untracked Quantity";

        TrkgReservEntry.Quantity :=
          Round(TrkgReservEntry."Quantity (Base)" / TrkgReservEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
        TrkgReservEntry.Positive := TrkgReservEntry."Quantity (Base)" > 0;

        if TrkgReservEntry."Reservation Status" <> TrkgReservEntry."Reservation Status"::Surplus then
            if ("Planning Level Code" > 0) or
               (Binding = Binding::"Order-to-Order")
            then
                TrkgReservEntry."Reservation Status" := TrkgReservEntry."Reservation Status"::Reservation
            else
                TrkgReservEntry."Reservation Status" := TrkgReservEntry."Reservation Status"::Tracking;

        if TrkgReservEntry."Quantity (Base)" = 0 then begin
            TrkgReservEntry."Expected Receipt Date" := GetExpectedReceiptDate;
            TrkgReservEntry."Shipment Date" := "Due Date";
        end else
            if TrkgReservEntry.Positive then
                TrkgReservEntry."Expected Receipt Date" := GetExpectedReceiptDate
            else
                TrkgReservEntry."Shipment Date" := "Due Date";

        OnAfterTransferToTrackingEntry(TrkgReservEntry, Rec, UseSecondaryFields);
    end;

    procedure ActiveInWarehouse(): Boolean
    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
    begin
        if "Source Type" = DATABASE::"Transfer Line" then
            exit(WhseValidateSourceLine.WhseLinesExist("Source Type", 0, "Source ID", "Source Ref. No.", 0, Quantity));

        exit(WhseValidateSourceLine.WhseLinesExist("Source Type", "Source Order Status", "Source ID", "Source Ref. No.", 0, Quantity));
    end;

    local procedure GetExpectedReceiptDate(): Date
    begin
        if "Action Message" in ["Action Message"::Reschedule, "Action Message"::"Resched. & Chg. Qty."] then
            exit("Original Due Date");
        exit("Due Date");
    end;

    procedure SetSource(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        "Source Type" := SourceType;
        "Source Order Status" := SourceSubtype;
        "Source ID" := SourceID;
        "Source Ref. No." := SourceRefNo;
        "Source Batch Name" := SourceBatchName;
        "Source Prod. Order Line" := SourceProdOrderLine;
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgEntry."Serial No.";
        "Lot No." := ItemLedgEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    procedure CopyTrackingFromInvtProfile(InvtProfile: Record "Inventory Profile")
    begin
        "Serial No." := InvtProfile."Serial No.";
        "Lot No." := InvtProfile."Lot No.";

        OnAfterCopyTrackingFromInvtProfile(Rec, InvtProfile);
    end;

    procedure CopyTrackingFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        "Serial No." := ReservEntry."Serial No.";
        "Lot No." := ReservEntry."Lot No.";

        OnAfterCopyTrackingFromReservEntry(Rec, ReservEntry);
    end;

    procedure SetTrackingFilter(InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Serial No." <> '' then
            SetRange("Serial No.", InventoryProfile."Serial No.")
        else
            SetRange("Serial No.");
        if InventoryProfile."Lot No." <> '' then
            SetRange("Lot No.", InventoryProfile."Lot No.")
        else
            SetRange("Lot No.");
    end;

    procedure TrackingExists(): Boolean
    begin
        exit(("Lot No." <> '') or ("Serial No." <> ''));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var InventoryProfile: Record "Inventory Profile"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromInvtProfile(var InventoryProfile: Record "Inventory Profile"; FromInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromReservEntry(var InventoryProfile: Record "Inventory Profile"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromItemLedgerEntry(var InventoryProfile: Record "Inventory Profile"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromSalesLine(var InventoryProfile: Record "Inventory Profile"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromComponent(var InventoryProfile: Record "Inventory Profile"; ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPlanComponent(var InventoryProfile: Record "Inventory Profile"; PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPurchaseLine(var InventoryProfile: Record "Inventory Profile"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdOrderLine(var InventoryProfile: Record "Inventory Profile"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromAsmLine(var InventoryProfile: Record "Inventory Profile"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromAsmHeader(var InventoryProfile: Record "Inventory Profile"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromRequisitionLine(var InventoryProfile: Record "Inventory Profile"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromInboundTransfer(var InventoryProfile: Record "Inventory Profile"; TransLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromOutboundTransfPlan(var InventoryProfile: Record "Inventory Profile"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromOutboundTransfer(var InventoryProfile: Record "Inventory Profile"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromServLine(var InventoryProfile: Record "Inventory Profile"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromJobPlanningLine(var InventoryProfile: Record "Inventory Profile"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferToTrackingEntry(var ReservationEntry: Record "Reservation Entry"; InventoryProfile: Record "Inventory Profile"; UseSecondaryFields: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCase(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; UseSecondaryFields: Boolean; var IsHandled: Boolean)
    begin
    end;
}

