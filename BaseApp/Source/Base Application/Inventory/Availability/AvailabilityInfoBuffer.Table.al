﻿namespace Microsoft.Inventory.Availability;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;

table 520 "Availability Info. Buffer"
{
    Caption = 'Availability Information Buffer';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;
        }
        field(3; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
        }
        field(4; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(5; "Package No."; Code[50])
        {
            Caption = 'Package No.';
        }
        field(6; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(7; Quality; Option)
        {
            Caption = 'Quality';
            OptionCaption = ' ,Good,Average,Bad';
            OptionMembers = " ",Good,"Average",Bad;
            FieldClass = FlowField;
            CalcFormula = lookup("Lot No. Information"."Test Quality" where("Item No." = field("Item No."),
                                                                            "Lot No." = field("Lot No.")));
        }
        field(8; "Certificate Number"; Code[20])
        {
            Caption = 'Certificate Number';
            FieldClass = FlowField;
            CalcFormula = lookup("Lot No. Information"."Certificate Number" where("Item No." = field("Item No."),
                                                                                  "Lot No." = field("Lot No.")));
        }
        field(9; Blocked; Boolean)
        {
            Caption = 'Blocked';
            FieldClass = FlowField;
            CalcFormula = lookup("Lot No. Information".Blocked where("Item No." = field("Item No."),
                                                                     "Lot No." = field("Lot No.")));
        }
        field(20; Inventory; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry"."Remaining Quantity" where("Item No." = field("Item No."),
                                                                             Open = const(true),
                                                                             "Lot No." = field("Lot No. Filter"),
                                                                             "Location Code" = field("Location Code Filter"),
                                                                             "Variant Code" = field("Variant Code Filter")));
            Caption = 'Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(21; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(23; "Variant Code Filter"; Code[10])
        {
            Caption = 'Variant Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Variant";
        }
        field(24; "Location Code Filter"; Code[10])
        {
            Caption = 'Location Code Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(25; "Lot No. Filter"; Code[50])
        {
            Caption = 'Lot No. Filter';
            FieldClass = FlowFilter;
        }
        field(30; "Qty. In Hand"; Decimal)
        {
            Caption = 'Qty. in Hand';
        }
        field(31; "Gross Requirement"; Decimal)
        {
            Caption = 'Gross Requirement';
        }
        field(32; "Planned Order Receipt"; Decimal)
        {
            Caption = 'Planned Order Receipt';
        }
        field(33; "Scheduled Receipt"; Decimal)
        {
            Caption = 'Scheduled Receipt';
        }
        field(34; "Available Inventory"; Decimal)
        {
            Caption = 'Available Inventory';
        }
        field(503; "Qty. on Sales Order"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("Item No."),
                                                                            "Source Type" = const(37),
                                                                            "Source Subtype" = const("1"),
                                                                            "Reservation Status" = filter(Reservation | Tracking | Surplus),
                                                                            "Lot No." = field("Lot No. Filter"),
                                                                            "Location Code" = field("Location Code Filter"),
                                                                            "Variant Code" = field("Variant Code Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Qty. on Sales Orders';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(504; "Qty. on Service Order"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("Item No."),
                                                                            "Source Type" = const(5902),
                                                                            "Source Subtype" = const("1"),
                                                                            "Reservation Status" = filter(Reservation | Tracking | Surplus),
                                                                            "Lot No." = field("Lot No. Filter"),
                                                                            "Location Code" = field("Location Code Filter"),
                                                                            "Variant Code" = field("Variant Code Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Qty. on Service Orders';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(505; "Qty. on Job Order"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("Item No."),
                                                                            "Source Type" = const(1003),
                                                                            "Source Subtype" = const("2"),
                                                                            "Reservation Status" = filter(Reservation | Tracking | Surplus),
                                                                            "Lot No." = field("Lot No. Filter"),
                                                                            "Location Code" = field("Location Code Filter"),
                                                                            "Variant Code" = field("Variant Code Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Qty. on Project Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(506; "Qty. on Component Lines"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("Item No."),
                                                                            "Source Type" = const(5407),
                                                                            "Source Subtype" = filter("1" .. "3"),
                                                                            "Reservation Status" = filter(Reservation | Tracking | Surplus),
                                                                            "Lot No." = field("Lot No. Filter"),
                                                                            "Location Code" = field("Location Code Filter"),
                                                                            "Variant Code" = field("Variant Code Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Res. Qty. on Prod. Order Comp.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(507; "Qty. on Trans. Order Shipment"; Decimal)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("Item No."),
                                                                            "Source Type" = const(5741),
                                                                            "Source Subtype" = const("0"),
                                                                            "Reservation Status" = filter(Reservation | Tracking | Surplus),
                                                                            "Lot No." = field("Lot No. Filter"),
                                                                            "Location Code" = field("Location Code Filter"),
                                                                            "Variant Code" = field("Variant Code Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Qty. on Transfer Order Shipment';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(509; "Qty. on Asm. Component"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("Item No."),
                                                                            "Source Type" = const(901),
                                                                            "Source Subtype" = const("1"),
                                                                            "Reservation Status" = filter(Reservation | Tracking | Surplus),
                                                                            "Lot No." = field("Lot No. Filter"),
                                                                            "Location Code" = field("Location Code Filter"),
                                                                            "Variant Code" = field("Variant Code Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Qty. on Asm. Comp.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(510; "Qty. on Purch. Return"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("Item No."),
                                                                            "Source Type" = const(39),
                                                                            "Source Subtype" = const("5"),
                                                                            "Reservation Status" = filter(Reservation | Tracking | Surplus),
                                                                            "Lot No." = field("Lot No. Filter"),
                                                                            "Location Code" = field("Location Code Filter"),
                                                                            "Variant Code" = field("Variant Code Filter"),
                                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Qty. on Purch. Returns';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(511; "Qty. on Purch. Order"; Decimal)
        {
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("Item No."),
                                                                          "Source Type" = const(39),
                                                                          "Source Subtype" = const("1"),
                                                                          "Reservation Status" = filter(Reservation | Tracking | Surplus),
                                                                          "Lot No." = field("Lot No. Filter"),
                                                                          "Location Code" = field("Location Code Filter"),
                                                                          "Variant Code" = field("Variant Code Filter"),
                                                                          "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Qty. on Purch. Orders';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(512; "Planned Order Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("Item No."),
                                                                          "Source Type" = const(5406),
                                                                          "Source Subtype" = const("1"),
                                                                          "Reservation Status" = const(Prospect),
                                                                          "Lot No." = field("Lot No. Filter"),
                                                                          "Location Code" = field("Location Code Filter"),
                                                                          "Variant Code" = field("Variant Code Filter"),
                                                                          "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Planned Order Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(513; "Purch. Req. Receipt (Qty.)"; Decimal)
        {
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("Item No."),
                                                                          "Source Type" = const(246),
                                                                          "Source Subtype" = const("0"),
                                                                          "Reservation Status" = const(Prospect),
                                                                          "Lot No." = field("Lot No. Filter"),
                                                                          "Location Code" = field("Location Code Filter"),
                                                                          "Variant Code" = field("Variant Code Filter"),
                                                                          "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Purch. Req. Receipt (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(514; "Qty. on Prod. Receipt"; Decimal)
        {
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("Item No."),
                                                                          "Source Type" = const(5406),
                                                                          "Source Subtype" = filter("2" .. "3"),
                                                                          "Reservation Status" = filter(Reservation | Tracking | Surplus),
                                                                          "Lot No." = field("Lot No. Filter"),
                                                                          "Location Code" = field("Location Code Filter"),
                                                                          "Variant Code" = field("Variant Code Filter"),
                                                                          "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Qty. on Prod. Receipt';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(516; "Qty. on Trans. Order Receipt"; Decimal)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("Item No."),
                                                                          "Source Type" = const(5741),
                                                                          "Source Subtype" = const("1"),
                                                                          "Reservation Status" = filter(Reservation | Tracking | Surplus),
                                                                          "Lot No." = field("Lot No. Filter"),
                                                                          "Location Code" = field("Location Code Filter"),
                                                                          "Variant Code" = field("Variant Code Filter"),
                                                                          "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Qty. on Transfer Order Receipt';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(517; "Qty. on Assembly Order"; Decimal)
        {
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("Item No."),
                                                                          "Source Type" = const(900),
                                                                          "Source Subtype" = const("1"),
                                                                          "Reservation Status" = filter(Reservation | Tracking | Surplus),
                                                                          "Lot No." = field("Lot No. Filter"),
                                                                          "Location Code" = field("Location Code Filter"),
                                                                          "Variant Code" = field("Variant Code Filter"),
                                                                          "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Qty. on Assembly Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(518; "Qty. on Sales Return"; Decimal)
        {
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("Item No."),
                                                                          "Source Type" = const(37),
                                                                          "Source Subtype" = const("5"),
                                                                          "Reservation Status" = filter(Reservation | Tracking | Surplus),
                                                                          "Lot No." = field("Lot No. Filter"),
                                                                          "Location Code" = field("Location Code Filter"),
                                                                          "Variant Code" = field("Variant Code Filter"),
                                                                          "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Qty. on Sales Return';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000777; "Qty. on Prod. Order"; Decimal)
        {
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Item No." = field("Item No."),
                                                                          "Source Type" = const(5406),
                                                                          "Source Subtype" = filter("1" .. "3"),
                                                                          "Reservation Status" = filter(Reservation | Tracking | Surplus),
                                                                          "Lot No." = field("Lot No. Filter"),
                                                                          "Location Code" = field("Location Code Filter"),
                                                                          "Variant Code" = field("Variant Code Filter"),
                                                                          "Expected Receipt Date" = field("Date Filter")));
            Caption = 'Qty. on Prod. Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Lot No.", "Serial No.", "Package No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    internal procedure LookupInventory(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemLedgerEntry.SetRange("Item No.", "Item No.");
        ItemLedgerEntry.SetRange("Lot No.", "Lot No.");
        ItemLedgerEntry.SetRange(Open, true);

        if Rec.GetFilter("Location Code Filter") <> '' then
            ItemLedgerEntry.SetRange("Location Code", Rec.GetFilter("Location Code Filter"));

        if Rec.GetFilter("Variant Code Filter") <> '' then
            ItemLedgerEntry.SetRange("Variant Code", Rec.GetFilter("Variant Code Filter"));
    end;

    internal procedure LookupGrossRequirement(var TempReservationEntry: Record "Reservation Entry" temporary)
    begin
        LookupReservationEntryForQtyOnSalesOrder(TempReservationEntry);
        LookupReservationEntryForQtyOnServiceOrder(TempReservationEntry);
        LookupReservationEntryForQtyOnJobOrder(TempReservationEntry);
        LookupReservationEntryForQtyOnCompLines(TempReservationEntry);
        LookupReservationEntryForQtyOnTransOrdShipment(TempReservationEntry);
        LookupReservationEntryForQtyOnAssemComp(TempReservationEntry);
        LookupReservationEntryForQtyOnPurchReturn(TempReservationEntry);
    end;

    internal procedure LookupPlannedOrderReceipt(var TempReservationEntry: Record "Reservation Entry" temporary)
    begin
        LookupReservationEntryForQtyOnPlannedOrderReceipt(TempReservationEntry);
        LookupReservationEntryForQtyOnPurchReqReceipt(TempReservationEntry);
    end;

    internal procedure LookupScheduledReceipt(var TempReservationEntry: Record "Reservation Entry" temporary)
    begin
        LookupReservationEntryForQtyOnProdReceipt(TempReservationEntry);
        LookupReservationEntryForQtyOnPurchOrder(TempReservationEntry);
        LookupReservationEntryForQtyOnTransOrderReceipt(TempReservationEntry);
        LookupReservationEntryForQtyOnAssemblyOrder(TempReservationEntry);
        LookupReservationEntryForQtyOnSalesReturn(TempReservationEntry);
    end;

    internal procedure LookupAvailableInventory(var TempReservationEntry: Record "Reservation Entry" temporary)
    begin
        LookupReservationEntryForQtyOnSalesOrder(TempReservationEntry);
        LookupReservationEntryForQtyOnServiceOrder(TempReservationEntry);
        LookupReservationEntryForQtyOnJobOrder(TempReservationEntry);
        LookupReservationEntryForQtyOnCompLines(TempReservationEntry);
        LookupReservationEntryForQtyOnTransOrdShipment(TempReservationEntry);
        LookupReservationEntryForQtyOnAssemComp(TempReservationEntry);
        LookupReservationEntryForQtyOnPurchReturn(TempReservationEntry);
        LookupReservationEntryForQtyOnPlannedOrderReceipt(TempReservationEntry);
        LookupReservationEntryForQtyOnPurchReqReceipt(TempReservationEntry);
        LookupReservationEntryForQtyOnProdReceipt(TempReservationEntry);
        LookupReservationEntryForQtyOnPurchOrder(TempReservationEntry);
        LookupReservationEntryForQtyOnTransOrderReceipt(TempReservationEntry);
        LookupReservationEntryForQtyOnAssemblyOrder(TempReservationEntry);
        LookupReservationEntryForQtyOnSalesReturn(TempReservationEntry);
    end;

    local procedure LookupReservationEntryForQtyOnSalesOrder(var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Sales Line",
            Format(ReservationEntry."Source Subtype"::"1"),
            GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            ReservationDateFilterOption::"Shipment Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnServiceOrder(var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Service Line",
            Format(ReservationEntry."Source Subtype"::"1"),
            GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            ReservationDateFilterOption::"Shipment Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnJobOrder(var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Job Planning Line",
            Format(ReservationEntry."Source Subtype"::"2"),
            GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            ReservationDateFilterOption::"Shipment Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnCompLines(var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Prod. Order Component",
            GetRangeFilter(ReservationEntry."Source Subtype"::"1", ReservationEntry."Source Subtype"::"3"),
            GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            ReservationDateFilterOption::"Shipment Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnTransOrdShipment(var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Transfer Line",
            Format(ReservationEntry."Source Subtype"::"0"),
            GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            ReservationDateFilterOption::"Shipment Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnAssemComp(var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Assembly Line",
            Format(ReservationEntry."Source Subtype"::"1"),
            GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            ReservationDateFilterOption::"Shipment Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnPurchReturn(var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Purchase Line",
            Format(ReservationEntry."Source Subtype"::"5"),
            GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            ReservationDateFilterOption::"Shipment Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnPlannedOrderReceipt(var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Prod. Order Line",
            Format(ReservationEntry."Source Subtype"::"1"),
            Format(ReservationEntry."Reservation Status"::Prospect),
            ReservationDateFilterOption::"Expected Recipt Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnPurchReqReceipt(var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Requisition Line",
            Format(ReservationEntry."Source Subtype"::"0"),
            Format(ReservationEntry."Reservation Status"::Prospect),
            ReservationDateFilterOption::"Expected Recipt Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnProdReceipt(var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Prod. Order Line",
            GetRangeFilter(ReservationEntry."Source Subtype"::"2", ReservationEntry."Source Subtype"::"3"),
            GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            ReservationDateFilterOption::"Expected Recipt Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnPurchOrder(var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Purchase Line",
            Format(ReservationEntry."Source Subtype"::"1"),
            GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            ReservationDateFilterOption::"Expected Recipt Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnTransOrderReceipt(var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Transfer Line",
            Format(ReservationEntry."Source Subtype"::"1"),
            GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            ReservationDateFilterOption::"Expected Recipt Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnAssemblyOrder(var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Assembly Header",
            Format(ReservationEntry."Source Subtype"::"1"),
            GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            ReservationDateFilterOption::"Expected Recipt Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnSalesReturn(var TempReservationEntry: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Sales Line",
            Format(ReservationEntry."Source Subtype"::"5"),
            GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            ReservationDateFilterOption::"Expected Recipt Date"
        );
    end;

    local procedure AddEntriesForLookUp(
        var TempReservationEntry: Record "Reservation Entry" temporary;
        SourceType: Integer;
        SourceSubTypeFilter: Text;
        ReservationStatusFilter: Text;
        DateFilterOption: Option ReservationDateFilterOption
    )
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", "Item No.");
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetFilter("Source Subtype", SourceSubTypeFilter);
        ReservationEntry.SetFilter("Reservation Status", ReservationStatusFilter);
        ReservationEntry.SetRange("Lot No.", "Lot No.");
        if Rec.GetFilter("Location Code Filter") <> '' then
            ReservationEntry.SetRange("Location Code", Rec.GetFilter("Location Code Filter"));
        if Rec.GetFilter("Variant Code Filter") <> '' then
            ReservationEntry.SetRange("Variant Code", Rec.GetFilter("Variant Code Filter"));

        if DateFilterOption = ReservationDateFilterOption::"Shipment Date" then
            ReservationEntry.SetFilter("Shipment Date", Rec.GetFilter("Date Filter"))
        else
            ReservationEntry.SetFilter("Expected Receipt Date", Rec.GetFilter("Date Filter"));

        if ReservationEntry.FindSet() then
            repeat
                TempReservationEntry.Init();
                TempReservationEntry := ReservationEntry;
                TempReservationEntry.Insert();
            until ReservationEntry.Next() = 0;
    end;

    local procedure GetRangeFilter(FromVariant: Variant; ToVariant: Variant): Text
    var
        FilterTxt: Label '%1..%2', Comment = '%1, %2', Locked = true;
    begin
        exit(StrSubstNo(FilterTxt, FromVariant, ToVariant))
    end;

    local procedure GetOptionFilter(Option1Variant: Variant; Option2Variant: Variant; Option3Variant: Variant): Text
    var
        FilterTxt: Label '%1|%2|%3', Comment = '%1, %2, %3', Locked = true;
    begin
        exit(StrSubstNo(FilterTxt, Option1Variant, Option2Variant, Option3Variant));
    end;

    var
        ReservationDateFilterOption: Option "Shipment Date","Expected Recipt Date";
}

