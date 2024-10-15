namespace Microsoft.Inventory.Tracking;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;

table 99000853 "Inventory Profile"
{
    Caption = 'Inventory Profile';
    DataClassification = CustomerContent;

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
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."),
                                                       Code = field("Variant Code"));
        }
        field(13; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(14; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
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
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';
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
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";

        IncorrectSourceTypeErr: Label 'Tab99000853, TransferToTrackingEntry: Illegal Source Type: %1.';

    procedure TransferFromItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        "Source Type" := Database::"Item Ledger Entry";
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
        ItemLedgerEntry.SetReservationFilters(ReservationEntry);
        AutoReservedQty := TransferBindings(ReservationEntry, TrackingReservationEntry);
        "Untracked Quantity" := ItemLedgerEntry."Remaining Quantity" - ItemLedgerEntry."Reserved Quantity" + AutoReservedQty;
        "Unit of Measure Code" := ItemLedgerEntry."Unit of Measure Code";
        "Qty. per Unit of Measure" := 1;
        IsSupply := ItemLedgerEntry.Positive;
        "Due Date" := ItemLedgerEntry."Posting Date";
        CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
        if TrackingExists() then
            "Tracking Reference" := "Line No.";
        "Planning Flexibility" := "Planning Flexibility"::None;

        OnAfterTransferFromItemLedgerEntry(Rec, ItemLedgerEntry);
    end;

    procedure TransferFromSalesLine(var SalesLine: Record "Sales Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SetSource(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", '', 0);
        "Item No." := SalesLine."No.";
        "Variant Code" := SalesLine."Variant Code";
        "Location Code" := SalesLine."Location Code";
        "Bin Code" := SalesLine."Bin Code";
        SalesLine.CalcFields("Reserved Qty. (Base)");
        SalesLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := -TransferBindings(ReservationEntry, TrackingReservationEntry);
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
            ChangeSign();
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

    procedure TransferFromComponent(var ProdOrderComponent: Record "Prod. Order Component"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        SetSource(
          Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
          ProdOrderComponent."Line No.", '', ProdOrderComponent."Prod. Order Line No.");
        "Ref. Order Type" := "Ref. Order Type"::"Prod. Order";
        "Ref. Order No." := ProdOrderComponent."Prod. Order No.";
        "Ref. Line No." := ProdOrderComponent."Prod. Order Line No.";
        "Item No." := ProdOrderComponent."Item No.";
        "Variant Code" := ProdOrderComponent."Variant Code";
        "Location Code" := ProdOrderComponent."Location Code";
        "Bin Code" := ProdOrderComponent."Bin Code";
        "Due Date" := ProdOrderComponent."Due Date";
        "Due Time" := ProdOrderComponent."Due Time";
        "Planning Flexibility" := "Planning Flexibility"::None;
        "Planning Level Code" := ProdOrderComponent."Planning Level Code";
        ProdOrderComponent.CalcFields("Reserved Qty. (Base)");
        if ProdOrderComponent.Status in [ProdOrderComponent.Status::Released, ProdOrderComponent.Status::Finished] then
            ProdOrderComponent.CalcFields("Act. Consumption (Qty)");
        ProdOrderComponent.SetReservationFilters(ReservationEntry);
        AutoReservedQty := -TransferBindings(ReservationEntry, TrackingReservationEntry);
        "Untracked Quantity" := ProdOrderComponent."Remaining Qty. (Base)" - ProdOrderComponent."Reserved Qty. (Base)" + AutoReservedQty;
        Quantity := ProdOrderComponent."Expected Quantity";
        "Remaining Quantity" := ProdOrderComponent."Remaining Quantity";
        "Finished Quantity" := ProdOrderComponent."Act. Consumption (Qty)";
        "Quantity (Base)" := ProdOrderComponent."Expected Qty. (Base)";
        "Remaining Quantity (Base)" := ProdOrderComponent."Remaining Qty. (Base)";
        "Unit of Measure Code" := ProdOrderComponent."Unit of Measure Code";
        "Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" < 0;

        OnAfterTransferFromComponent(Rec, ProdOrderComponent);
    end;

    procedure TransferFromPlanComponent(var PlanningComponent: Record "Planning Component"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        AssemblyLine: Record "Assembly Line";
        ReservationEntry: Record "Reservation Entry";
        ReservedQty: Decimal;
        AutoReservedQty: Decimal;
    begin
        SetSource(
          Database::"Planning Component", 0, PlanningComponent."Worksheet Template Name", PlanningComponent."Line No.",
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
        PlanningComponent.SetReservationFilters(ReservationEntry);
        AutoReservedQty := -TransferBindings(ReservationEntry, TrackingReservationEntry);
        PlanningComponent.CalcFields("Reserved Qty. (Base)");
        "Untracked Quantity" :=
          PlanningComponent."Expected Quantity (Base)" - PlanningComponent."Reserved Qty. (Base)" + AutoReservedQty;
        case PlanningComponent."Ref. Order Type" of
            PlanningComponent."Ref. Order Type"::"Prod. Order":
                if ProdOrderComponent.Get(
                     PlanningComponent."Ref. Order Status",
                     PlanningComponent."Ref. Order No.",
                     PlanningComponent."Ref. Order Line No.",
                     PlanningComponent."Line No.")
                then begin
                    "Original Quantity" := ProdOrderComponent."Expected Quantity";
                    ProdOrderComponent.CalcFields("Reserved Qty. (Base)");
                    if ProdOrderComponent."Reserved Qty. (Base)" > 0 then begin
                        ReservedQty := ProdOrderComponent."Reserved Qty. (Base)";
                        ProdOrderComponent.SetReservationFilters(ReservationEntry);
                        CalcReservedQty(ReservationEntry, ReservedQty);
                        if ReservedQty > "Untracked Quantity" then
                            "Untracked Quantity" := 0
                        else
                            "Untracked Quantity" := "Untracked Quantity" - ReservedQty;
                    end;
                end else begin
                    "Primary Order Type" := Database::"Planning Component";
                    "Primary Order Status" := PlanningComponent."Ref. Order Status".AsInteger();
                    "Primary Order No." := PlanningComponent."Ref. Order No.";
                end;
            PlanningComponent."Ref. Order Type"::Assembly:
                if AssemblyLine.Get(
                     PlanningComponent."Ref. Order Status",
                     PlanningComponent."Ref. Order No.",
                     PlanningComponent."Ref. Order Line No.")
                then begin
                    "Original Quantity" := AssemblyLine.Quantity;
                    AssemblyLine.CalcFields("Reserved Qty. (Base)");
                    if AssemblyLine."Reserved Qty. (Base)" > 0 then begin
                        ReservedQty := AssemblyLine."Reserved Qty. (Base)";
                        AssemblyLine.SetReservationFilters(ReservationEntry);
                        CalcReservedQty(ReservationEntry, ReservedQty);
                        if ReservedQty > "Untracked Quantity" then
                            "Untracked Quantity" := 0
                        else
                            "Untracked Quantity" := "Untracked Quantity" - ReservedQty;
                    end;
                end else begin
                    "Primary Order Type" := Database::"Planning Component";
                    "Primary Order Status" := PlanningComponent."Ref. Order Status".AsInteger();
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

    local procedure CalcReservedQty(var ReservationEntry: Record "Reservation Entry"; var ReservedQty: Decimal)
    var
        OppositeReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line",
          "Reservation Status");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange(Binding, ReservationEntry.Binding::"Order-to-Order");
        if ReservationEntry.Find('-') then begin
            // Retrieving information about primary order:
            if ReservationEntry.Positive then
                OppositeReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive)
            else
                OppositeReservationEntry := ReservationEntry;
            if "Primary Order No." = '' then begin
                "Primary Order Type" := OppositeReservationEntry."Source Type";
                "Primary Order Status" := OppositeReservationEntry."Source Subtype";
                "Primary Order No." := OppositeReservationEntry."Source ID";
                if OppositeReservationEntry."Source Type" = Database::"Prod. Order Component" then
                    "Primary Order Line" := OppositeReservationEntry."Source Prod. Order Line";
            end;

            Binding := ReservationEntry.Binding;
            repeat
                ReservedQty := ReservedQty + ReservationEntry."Quantity (Base)";
            until ReservationEntry.Next() = 0;
        end;
    end;

    procedure TransferFromPurchaseLine(var PurchaseLine: Record "Purchase Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        SetSource(Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", '', 0);
        "Item No." := PurchaseLine."No.";
        "Variant Code" := PurchaseLine."Variant Code";
        "Location Code" := PurchaseLine."Location Code";
        "Bin Code" := PurchaseLine."Bin Code";
        PurchaseLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := TransferBindings(ReservationEntry, TrackingReservationEntry);
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
            ChangeSign();
            "Planning Flexibility" := "Planning Flexibility"::None;
        end else
            "Planning Flexibility" := PurchaseLine."Planning Flexibility";
        IsSupply := "Untracked Quantity" >= 0;
        "Due Date" := PurchaseLine."Expected Receipt Date";
        "Drop Shipment" := PurchaseLine."Drop Shipment";
        "Special Order" := PurchaseLine."Special Order";

        OnAfterTransferFromPurchaseLine(Rec, PurchaseLine);
    end;

    procedure TransferFromProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        SetSource(Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", 0, '', ProdOrderLine."Line No.");
        "Item No." := ProdOrderLine."Item No.";
        "Variant Code" := ProdOrderLine."Variant Code";
        "Location Code" := ProdOrderLine."Location Code";
        "Bin Code" := ProdOrderLine."Bin Code";
        "Due Date" := ProdOrderLine."Due Date";
        "Starting Date" := ProdOrderLine."Starting Date";
        "Planning Flexibility" := ProdOrderLine."Planning Flexibility";
        "Planning Level Code" := ProdOrderLine."Planning Level Code";
        ProdOrderLine.CalcFields("Reserved Qty. (Base)");
        ProdOrderLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := TransferBindings(ReservationEntry, TrackingReservationEntry);
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

    procedure TransferFromAsmLine(var AssemblyLine: Record "Assembly Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        AssemblyLine.TestField(Type, AssemblyLine.Type::Item);
        SetSource(Database::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", '', 0);
        "Ref. Order Type" := "Ref. Order Type"::Assembly;
        "Ref. Order No." := AssemblyLine."Document No.";
        "Ref. Line No." := AssemblyLine."Line No.";
        "Item No." := AssemblyLine."No.";
        "Variant Code" := AssemblyLine."Variant Code";
        "Location Code" := AssemblyLine."Location Code";
        "Bin Code" := AssemblyLine."Bin Code";
        AssemblyLine.CalcFields("Reserved Qty. (Base)");
        AssemblyLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := -TransferBindings(ReservationEntry, TrackingReservationEntry);
        "Untracked Quantity" := AssemblyLine."Remaining Quantity (Base)" - AssemblyLine."Reserved Qty. (Base)" + AutoReservedQty;
        Quantity := AssemblyLine.Quantity;
        "Remaining Quantity" := AssemblyLine."Remaining Quantity";
        "Finished Quantity" := AssemblyLine."Consumed Quantity";
        "Quantity (Base)" := AssemblyLine."Quantity (Base)";
        "Remaining Quantity (Base)" := AssemblyLine."Remaining Quantity (Base)";
        "Unit of Measure Code" := AssemblyLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := AssemblyLine."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" < 0;
        "Due Date" := AssemblyLine."Due Date";
        "Planning Flexibility" := "Planning Flexibility"::None;

        OnAfterTransferFromAsmLine(Rec, AssemblyLine);
    end;

    procedure TransferFromAsmHeader(var AssemblyHeader: Record "Assembly Header"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        SetSource(Database::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, '', 0);
        "Item No." := AssemblyHeader."Item No.";
        "Variant Code" := AssemblyHeader."Variant Code";
        "Location Code" := AssemblyHeader."Location Code";
        "Bin Code" := AssemblyHeader."Bin Code";
        AssemblyHeader.SetReservationFilters(ReservationEntry);
        AutoReservedQty := TransferBindings(ReservationEntry, TrackingReservationEntry);
        AssemblyHeader.CalcFields("Reserved Qty. (Base)");
        "Untracked Quantity" := AssemblyHeader."Remaining Quantity (Base)" - AssemblyHeader."Reserved Qty. (Base)" + AutoReservedQty;
        "Min. Quantity" := AssemblyHeader."Reserved Qty. (Base)" - AutoReservedQty;
        Quantity := AssemblyHeader.Quantity;
        "Remaining Quantity" := AssemblyHeader."Remaining Quantity";
        "Finished Quantity" := AssemblyHeader."Assembled Quantity";
        "Quantity (Base)" := AssemblyHeader."Quantity (Base)";
        "Remaining Quantity (Base)" := AssemblyHeader."Remaining Quantity (Base)";
        "Unit of Measure Code" := AssemblyHeader."Unit of Measure Code";
        "Qty. per Unit of Measure" := AssemblyHeader."Qty. per Unit of Measure";
        "Planning Flexibility" := AssemblyHeader."Planning Flexibility";
        IsSupply := "Untracked Quantity" >= 0;
        "Due Date" := AssemblyHeader."Due Date";

        OnAfterTransferFromAsmHeader(Rec, AssemblyHeader);
    end;

    procedure TransferFromRequisitionLine(var RequisitionLine: Record "Requisition Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        RequisitionLine.TestField(Type, RequisitionLine.Type::Item);
        SetSource(
          Database::"Requisition Line", 0, RequisitionLine."Worksheet Template Name", RequisitionLine."Line No.",
          RequisitionLine."Journal Batch Name", 0);
        "Item No." := RequisitionLine."No.";
        "Variant Code" := RequisitionLine."Variant Code";
        "Location Code" := RequisitionLine."Location Code";
        "Bin Code" := RequisitionLine."Bin Code";
        RequisitionLine.CalcFields("Reserved Qty. (Base)");
        RequisitionLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := TransferBindings(ReservationEntry, TrackingReservationEntry);
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

    procedure TransferFromOutboundTransfPlan(var RequisitionLine: Record "Requisition Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        RequisitionLine.TestField(Type, RequisitionLine.Type::Item);
        SetSource(
          Database::"Requisition Line", 1, RequisitionLine."Worksheet Template Name", RequisitionLine."Line No.",
          RequisitionLine."Journal Batch Name", 0);
        "Item No." := RequisitionLine."No.";
        "Variant Code" := RequisitionLine."Variant Code";
        "Location Code" := RequisitionLine."Transfer-from Code";
        "Bin Code" := RequisitionLine."Bin Code";
        RequisitionLine.CalcFields("Reserved Qty. (Base)");
        RequisitionLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := TransferBindings(ReservationEntry, TrackingReservationEntry);
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

    procedure TransferFromOutboundTransfer(var TransferLine: Record "Transfer Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
        CurrentInventoryProfile: Record "Inventory Profile";
        TransferDirection: Enum "Transfer Direction";
        AutoReservedQty: Decimal;
        MinQtyInbnd: Decimal;
        MinQtyOutbnd: Decimal;
    begin
        SetSource(Database::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", '', 0);
        "Item No." := TransferLine."Item No.";
        "Variant Code" := TransferLine."Variant Code";
        "Location Code" := TransferLine."Transfer-from Code";

        TransferLine.CalcFields("Reserved Qty. Outbnd. (Base)", "Reserved Qty. Inbnd. (Base)");
        TransferLine.SetReservationFilters(ReservationEntry, TransferDirection::Outbound);
        AutoReservedQty := -TransferBindings(ReservationEntry, TrackingReservationEntry);
        MinQtyOutbnd := TransferLine."Reserved Qty. Outbnd. (Base)" - AutoReservedQty;

        CurrentInventoryProfile := Rec;
        TransferLine.SetReservationFilters(ReservationEntry, TransferDirection::Inbound);
        AutoReservedQty := TransferBindings(ReservationEntry, TempReservationEntry);
        MinQtyInbnd := TransferLine."Reserved Qty. Inbnd. (Base)" - AutoReservedQty;
        Rec := CurrentInventoryProfile;

        if MinQtyInbnd > MinQtyOutbnd then
            "Min. Quantity" := MinQtyInbnd
        else
            "Min. Quantity" := MinQtyOutbnd;

        "Untracked Quantity" := TransferLine."Outstanding Qty. (Base)" - MinQtyOutbnd;
        Quantity := TransferLine.Quantity;
        "Remaining Quantity" := TransferLine."Outstanding Quantity";
        "Finished Quantity" := TransferLine."Quantity Shipped";
        "Quantity (Base)" := TransferLine."Quantity (Base)";
        "Remaining Quantity (Base)" := TransferLine."Outstanding Qty. (Base)";
        "Unit of Measure Code" := TransferLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := TransferLine."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" < 0;
        "Due Date" := TransferLine."Shipment Date";
        "Planning Flexibility" := TransferLine."Planning Flexibility";

        OnAfterTransferFromOutboundTransfer(Rec, TransferLine);
    end;

    procedure TransferFromInboundTransfer(var TransferLine: Record "Transfer Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
        CurrentInventoryProfile: Record "Inventory Profile";
        TransferDirection: Enum "Transfer Direction";
        AutoReservedQty: Decimal;
        MinQtyInbnd: Decimal;
        MinQtyOutbnd: Decimal;
    begin
        SetSource(Database::"Transfer Line", 1, TransferLine."Document No.", TransferLine."Line No.", '', TransferLine."Derived From Line No.");
        "Item No." := TransferLine."Item No.";
        "Variant Code" := TransferLine."Variant Code";
        "Location Code" := TransferLine."Transfer-to Code";

        TransferLine.CalcFields("Reserved Qty. Outbnd. (Base)", "Reserved Qty. Inbnd. (Base)");
        TransferLine.SetReservationFilters(ReservationEntry, TransferDirection::Inbound);
        AutoReservedQty := TransferBindings(ReservationEntry, TrackingReservationEntry);
        MinQtyInbnd := TransferLine."Reserved Qty. Inbnd. (Base)" - AutoReservedQty;

        CurrentInventoryProfile := Rec;
        TransferLine.SetReservationFilters(ReservationEntry, TransferDirection::Outbound);
        AutoReservedQty := -TransferBindings(ReservationEntry, TempReservationEntry);
        MinQtyOutbnd := TransferLine."Reserved Qty. Outbnd. (Base)" - AutoReservedQty;
        Rec := CurrentInventoryProfile;

        if MinQtyInbnd > MinQtyOutbnd then
            "Min. Quantity" := MinQtyInbnd
        else
            "Min. Quantity" := MinQtyOutbnd;

        "Untracked Quantity" := TransferLine."Outstanding Qty. (Base)" - MinQtyInbnd;
        Quantity := TransferLine.Quantity;
        "Remaining Quantity" := TransferLine."Outstanding Quantity";
        "Finished Quantity" := TransferLine."Quantity Received";
        "Quantity (Base)" := TransferLine."Quantity (Base)";
        "Remaining Quantity (Base)" := TransferLine."Outstanding Qty. (Base)";
        "Unit of Measure Code" := TransferLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := TransferLine."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" >= 0;
        "Starting Date" := TransferLine."Shipment Date";
        "Due Date" := TransferLine."Receipt Date";
        "Planning Flexibility" := TransferLine."Planning Flexibility";

        OnAfterTransferFromInboundTransfer(Rec, TransferLine);
    end;

    procedure TransferFromServLine(var ServiceLine: Record "Service Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        ServiceLine.TestField(Type, ServiceLine.Type::Item);
        SetSource(Database::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.", '', 0);
        "Item No." := ServiceLine."No.";
        "Variant Code" := ServiceLine."Variant Code";
        "Location Code" := ServiceLine."Location Code";
        ServiceLine.CalcFields("Reserved Qty. (Base)");
        ServiceLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := -TransferBindings(ReservationEntry, TrackingReservationEntry);
        "Untracked Quantity" := ServiceLine."Outstanding Qty. (Base)" - ServiceLine."Reserved Qty. (Base)" + AutoReservedQty;
        Quantity := ServiceLine.Quantity;
        "Remaining Quantity" := ServiceLine."Outstanding Quantity";
        "Finished Quantity" := ServiceLine."Quantity Shipped";
        "Quantity (Base)" := ServiceLine."Quantity (Base)";
        "Remaining Quantity (Base)" := ServiceLine."Outstanding Qty. (Base)";
        "Unit of Measure Code" := ServiceLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := ServiceLine."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" < 0;
        "Due Date" := ServiceLine."Needed by Date";
        "Planning Flexibility" := "Planning Flexibility"::None;

        OnAfterTransferFromServLine(Rec, ServiceLine);
    end;

    procedure TransferFromJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        SetSource(
            Database::"Job Planning Line", JobPlanningLine.Status.AsInteger(), JobPlanningLine."Job No.",
            JobPlanningLine."Job Contract Entry No.", '', 0);
        "Item No." := JobPlanningLine."No.";
        "Variant Code" := JobPlanningLine."Variant Code";
        "Location Code" := JobPlanningLine."Location Code";
        JobPlanningLine.CalcFields("Reserved Qty. (Base)");
        JobPlanningLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := -TransferBindings(ReservationEntry, TrackingReservationEntry);
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

    procedure TransferBindings(var ReservationEntry: Record "Reservation Entry"; var TrackingReservationEntry: Record "Reservation Entry"): Decimal
    var
        OppositeReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
        Found: Boolean;
        InsertTracking: Boolean;
        IsHandled: Boolean;
        Result: Decimal;
    begin
        IsHandled := false;
        OnBeforeTransferBindings(ReservationEntry, TrackingReservationEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ReservationEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line",
          "Reservation Status");
        if ReservationEntry.FindSet() then
            repeat
                InsertTracking := not
                  ((ReservationEntry."Reservation Status" = ReservationEntry."Reservation Status"::Reservation) and
                   (ReservationEntry.Binding = ReservationEntry.Binding::" "));
                if InsertTracking and ReservationEntry.TrackingExists() and
                   (ReservationEntry."Source Type" <> Database::"Item Ledger Entry")
                then begin
                    TrackingReservationEntry := ReservationEntry;
                    TrackingReservationEntry.Insert();
                end;
                if (ReservationEntry."Reservation Status" = ReservationEntry."Reservation Status"::Reservation) or
                    (ReservationEntry."Reservation Status" = ReservationEntry."Reservation Status"::Tracking)
                then
                    if (ReservationEntry.Binding = ReservationEntry.Binding::"Order-to-Order")
                    then begin
                        if ReservationEntry."Reservation Status" = ReservationEntry."Reservation Status"::Reservation then
                            AutoReservedQty := AutoReservedQty + ReservationEntry."Quantity (Base)";
                        if not Found then begin
                            if ReservationEntry.Positive then
                                OppositeReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive)
                            else
                                OppositeReservationEntry := ReservationEntry;
                            if "Primary Order No." = '' then begin
                                "Primary Order Type" := OppositeReservationEntry."Source Type";
                                "Primary Order Status" := OppositeReservationEntry."Source Subtype";
                                "Primary Order No." := OppositeReservationEntry."Source ID";
                                if OppositeReservationEntry."Source Type" <> Database::"Prod. Order Component" then
                                    "Primary Order Line" := OppositeReservationEntry."Source Ref. No."
                                else
                                    "Primary Order Line" := OppositeReservationEntry."Source Prod. Order Line";
                            end;
                            OnTransferBindingsOnAfterAssignPrimaryOrderInfo(Rec, OppositeReservationEntry);
                            Binding := ReservationEntry.Binding;
                            "Disallow Cancellation" := ReservationEntry."Disallow Cancellation";
                            Found := true;
                        end;
                    end else
                        if (ReservationEntry."Reservation Status" = ReservationEntry."Reservation Status"::Reservation) and
                           (("Fixed Date" = 0D) or ("Fixed Date" > ReservationEntry."Shipment Date"))
                        then
                            "Fixed Date" := ReservationEntry."Shipment Date";
            until ReservationEntry.Next() = 0;
        exit(AutoReservedQty);
    end;

    procedure TransferQtyFromItemTrgkEntry(var TrackingReservationEntry: Record "Reservation Entry")
    begin
        "Original Quantity" := 0;
        Quantity := TrackingReservationEntry.Quantity;
        "Quantity (Base)" := TrackingReservationEntry."Quantity (Base)";
        "Finished Quantity" := 0;
        "Min. Quantity" := 0;
        "Remaining Quantity" := TrackingReservationEntry.Quantity;
        "Remaining Quantity (Base)" := TrackingReservationEntry."Quantity (Base)";
        "Untracked Quantity" := TrackingReservationEntry."Quantity (Base)";
        if not IsSupply then
            ChangeSign();
    end;

    procedure ReduceQtyByItemTracking(var NewInventoryProfile: Record "Inventory Profile")
    begin
        "Original Quantity" -= NewInventoryProfile."Original Quantity";
        Quantity -= NewInventoryProfile.Quantity;
        "Quantity (Base)" -= NewInventoryProfile."Quantity (Base)";
        "Finished Quantity" -= NewInventoryProfile."Finished Quantity";
        "Remaining Quantity" -= NewInventoryProfile."Remaining Quantity";
        "Remaining Quantity (Base)" -= NewInventoryProfile."Remaining Quantity (Base)";
        "Untracked Quantity" -= NewInventoryProfile."Untracked Quantity";
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

    procedure TransferToTrackingEntry(var TrackingReservationEntry: Record "Reservation Entry"; UseSecondaryFields: Boolean)
    var
        RequisitionLine: Record "Requisition Line";
        IsHandled: Boolean;
    begin
        case "Source Type" of
            0:
                begin
                    // Surplus, Reorder Point
                    TrackingReservationEntry."Reservation Status" := TrackingReservationEntry."Reservation Status"::Surplus;
                    TrackingReservationEntry."Suppressed Action Msg." := true;
                    exit;
                end;
            Database::"Production Forecast Entry":
                begin
                    // Will be marked as Surplus
                    TrackingReservationEntry."Reservation Status" := TrackingReservationEntry."Reservation Status"::Surplus;
                    TrackingReservationEntry.SetSource(Database::"Production Forecast Entry", 0, "Source ID", 0, '', 0);
                    TrackingReservationEntry."Suppressed Action Msg." := true;
                end;
            Database::"Sales Line":
                begin
                    if "Source Order Status" = 4 then begin
                        // Blanket Order will be marked as Surplus
                        TrackingReservationEntry."Reservation Status" := TrackingReservationEntry."Reservation Status"::Surplus;
                        TrackingReservationEntry."Suppressed Action Msg." := true;
                    end;
                    TrackingReservationEntry.SetSource(Database::"Sales Line", "Source Order Status", "Source ID", "Source Ref. No.", '', 0);
                end;
            Database::"Requisition Line":
                TrackingReservationEntry.SetSource(
                  Database::"Requisition Line", "Source Order Status", "Source ID", "Source Ref. No.", "Source Batch Name", 0);
            Database::"Purchase Line":
                TrackingReservationEntry.SetSource(
                  Database::"Purchase Line", "Source Order Status", "Source ID", "Source Ref. No.", '', 0);
            Database::"Item Ledger Entry":
                TrackingReservationEntry.SetSource(
                  Database::"Item Ledger Entry", 0, '', "Source Ref. No.", '', 0);
            Database::"Prod. Order Line":
                TrackingReservationEntry.SetSource(
                  Database::"Prod. Order Line", "Source Order Status", "Source ID", 0, '', "Source Prod. Order Line");
            Database::"Prod. Order Component":
                TrackingReservationEntry.SetSource(
                  Database::"Prod. Order Component", "Source Order Status", "Source ID", "Source Ref. No.", '', "Source Prod. Order Line");
            Database::"Planning Component":
                if UseSecondaryFields then begin
                    RequisitionLine.Get("Source ID", "Source Batch Name", "Source Prod. Order Line");
                    case RequisitionLine."Ref. Order Type" of
                        RequisitionLine."Ref. Order Type"::"Prod. Order":
                            TrackingReservationEntry.SetSource(
                              Database::"Prod. Order Component", RequisitionLine."Ref. Order Status", "Ref. Order No.", "Source Ref. No.", '', "Ref. Line No.");
                        RequisitionLine."Ref. Order Type"::Assembly:
                            TrackingReservationEntry.SetSource(
                              Database::"Assembly Line", "Source Order Status", "Ref. Order No.", "Source Ref. No.", '', "Ref. Line No.");
                    end;
                end else
                    TrackingReservationEntry.SetSource(
                      Database::"Planning Component", 0, "Source ID", "Source Ref. No.", "Source Batch Name", "Source Prod. Order Line");
            Database::"Assembly Line":
                begin
                    if "Source Order Status" = 4 then begin
                        // Blanket Order will be marked as Surplus
                        TrackingReservationEntry."Reservation Status" := TrackingReservationEntry."Reservation Status"::Surplus;
                        TrackingReservationEntry."Suppressed Action Msg." := true;
                    end;
                    TrackingReservationEntry.SetSource(Database::"Assembly Line", "Source Order Status", "Source ID", "Source Ref. No.", '', 0);
                end;
            Database::"Assembly Header":
                TrackingReservationEntry.SetSource(Database::"Assembly Header", "Source Order Status", "Source ID", "Source Ref. No.", '', 0);
            Database::"Transfer Line":
                if IsSupply then
                    TrackingReservationEntry.SetSource(Database::"Transfer Line", 1, "Source ID", "Source Ref. No.", '', "Source Prod. Order Line")
                else
                    TrackingReservationEntry.SetSource(Database::"Transfer Line", 0, "Source ID", "Source Ref. No.", '', 0);
            Database::"Service Line":
                TrackingReservationEntry.SetSource(Database::"Service Line", "Source Order Status", "Source ID", "Source Ref. No.", '', 0);
            Database::"Job Planning Line":
                TrackingReservationEntry.SetSource(Database::"Job Planning Line", "Source Order Status", "Source ID", "Source Ref. No.", '', 0);
            else begin
                IsHandled := false;
                OnTransferToTrackingEntrySourceTypeElseCase(Rec, TrackingReservationEntry, UseSecondaryFields, IsHandled);
                if not IsHandled then
                    Error(IncorrectSourceTypeErr, "Source Type");
            end;
        end;

        TrackingReservationEntry."Item No." := "Item No.";
        TrackingReservationEntry."Location Code" := "Location Code";
        TrackingReservationEntry.Description := '';
        TrackingReservationEntry."Creation Date" := Today;
        TrackingReservationEntry."Created By" := CopyStr(UserId(), 1, 50);
        TrackingReservationEntry."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
        TrackingReservationEntry."Variant Code" := "Variant Code";
        TrackingReservationEntry.Binding := Binding;
        TrackingReservationEntry."Disallow Cancellation" := "Disallow Cancellation";
        TrackingReservationEntry.CopyTrackingFromInvtProfile(Rec);
        TrackingReservationEntry."Expiration Date" := "Expiration Date";

        if IsSupply then
            TrackingReservationEntry."Quantity (Base)" := "Untracked Quantity"
        else
            TrackingReservationEntry."Quantity (Base)" := -"Untracked Quantity";

        TrackingReservationEntry.Quantity :=
          Round(TrackingReservationEntry."Quantity (Base)" / TrackingReservationEntry."Qty. per Unit of Measure", UnitofMeasureManagement.QtyRndPrecision());
        TrackingReservationEntry.Positive := TrackingReservationEntry."Quantity (Base)" > 0;

        if TrackingReservationEntry."Reservation Status" <> TrackingReservationEntry."Reservation Status"::Surplus then
            if ("Planning Level Code" > 0) or
               (Binding = Binding::"Order-to-Order")
            then
                TrackingReservationEntry."Reservation Status" := TrackingReservationEntry."Reservation Status"::Reservation
            else
                TrackingReservationEntry."Reservation Status" := TrackingReservationEntry."Reservation Status"::Tracking;

        if TrackingReservationEntry."Quantity (Base)" = 0 then begin
            TrackingReservationEntry."Expected Receipt Date" := GetExpectedReceiptDate();
            TrackingReservationEntry."Shipment Date" := "Due Date";
        end else
            if TrackingReservationEntry.Positive then
                TrackingReservationEntry."Expected Receipt Date" := GetExpectedReceiptDate()
            else
                TrackingReservationEntry."Shipment Date" := "Due Date";

        OnAfterTransferToTrackingEntry(TrackingReservationEntry, Rec, UseSecondaryFields);
    end;

    procedure ActiveInWarehouse(): Boolean
    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
    begin
        if "Source Type" = Database::"Transfer Line" then
            exit(WhseValidateSourceLine.WhseLinesExist("Source Type", 0, "Source ID", "Source Ref. No.", 0, Quantity));

        exit(
            WhseValidateSourceLine.WhseLinesExist("Source Type", "Source Order Status", "Source ID", "Source Ref. No.", 0, Quantity) or
            WhseValidateSourceLine.WhseWorkSheetLinesExistForJobOrProdOrderComponent("Source Type", "Source Order Status", "Source ID", "Source Ref. No.", 0, Quantity));
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

    procedure SetSourceFilter(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        SetRange("Source Type", SourceType);
        SetRange("Source Order Status", SourceSubtype);
        SetRange("Source ID", SourceID);
        SetRange("Source Ref. No.", SourceRefNo);
        SetRange("Source Batch Name", SourceBatchName);
        SetRange("Source Prod. Order Line", SourceProdOrderLine);
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgerEntry."Serial No.";
        "Lot No." := ItemLedgerEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgerEntry);
    end;

    procedure CopyTrackingFromInvtProfile(InventoryProfile: Record "Inventory Profile")
    begin
        "Serial No." := InventoryProfile."Serial No.";
        "Lot No." := InventoryProfile."Lot No.";

        OnAfterCopyTrackingFromInvtProfile(Rec, InventoryProfile);
    end;

    procedure CopyTrackingFromReservEntry(ReservationEntry: Record "Reservation Entry")
    begin
        "Serial No." := ReservationEntry."Serial No.";
        "Lot No." := ReservationEntry."Lot No.";

        OnAfterCopyTrackingFromReservEntry(Rec, ReservationEntry);
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

        OnAfterSetTrackingFilter(Rec, InventoryProfile);
    end;

    procedure SetTrackingFilterFromInvtProfile(InventoryProfile: Record "Inventory Profile")
    begin
        SetRange("Lot No.", InventoryProfile."Lot No.");
        SetRange("Serial No.", InventoryProfile."Serial No.");

        OnAfterSetTrackingFilterFromInvtProfile(Rec, InventoryProfile);
    end;

    procedure TrackingExists() IsTrackingExists: Boolean
    begin
        IsTrackingExists := ("Lot No." <> '') or ("Serial No." <> '');

        OnAfterTrackingExists(Rec, IsTrackingExists);
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
    local procedure OnAfterTrackingExists(InventoryProfile: Record "Inventory Profile"; var IsTrackingExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilter(var InventoryProfile: Record "Inventory Profile"; FromInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromInvtProfile(var InventoryProfile: Record "Inventory Profile"; FromInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBindingsOnAfterAssignPrimaryOrderInfo(var InventoryProfile: Record "Inventory Profile"; OppositeReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCase(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; UseSecondaryFields: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferBindings(var ReservEntry: Record "Reservation Entry"; var TrackingEntry: Record "Reservation Entry"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;
}

