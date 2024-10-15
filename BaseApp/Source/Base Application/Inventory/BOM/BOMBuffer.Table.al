namespace Microsoft.Inventory.BOM;

using Microsoft.Assembly.Document;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Projects.Resources.Resource;

table 5870 "BOM Buffer"
{
    Caption = 'BOM Buffer';
    DataCaptionFields = "No.", Description;
    Permissions =;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; Type; Enum "BOM Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
            TableRelation = if (Type = const(Item)) Item
            else
            if (Type = const("Machine Center")) "Machine Center"
            else
            if (Type = const("Work Center")) "Work Center"
            else
            if (Type = const(Resource)) Resource;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(6; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = SystemMetadata;
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            if (Type = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("No."));
        }
        field(7; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));
        }
        field(8; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
            TableRelation = Location;
        }
        field(9; "Replenishment System"; Enum "Replenishment System")
        {
            Caption = 'Replenishment System';
            DataClassification = SystemMetadata;
        }
        field(10; Indentation; Integer)
        {
            Caption = 'Indentation';
            DataClassification = SystemMetadata;
        }
        field(11; "Is Leaf"; Boolean)
        {
            Caption = 'Is Leaf';
            DataClassification = SystemMetadata;
        }
        field(13; Bottleneck; Boolean)
        {
            Caption = 'Bottleneck';
            DataClassification = SystemMetadata;
        }
        field(15; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = SystemMetadata;
            TableRelation = "Routing Header";
        }
        field(16; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM No.';
            DataClassification = SystemMetadata;
            TableRelation = "Production BOM Header";
        }
        field(20; "Lot Size"; Decimal)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Lot Size';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(21; "Low-Level Code"; Integer)
        {
            Caption = 'Low-Level Code';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(22; "Rounding Precision"; Decimal)
        {
            Caption = 'Rounding Precision';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            InitValue = 1;
        }
        field(30; "Qty. per Parent"; Decimal)
        {
            Caption = 'Qty. per Parent';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(31; "Qty. per Top Item"; Decimal)
        {
            Caption = 'Qty. per Top Item';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(32; "Able to Make Top Item"; Decimal)
        {
            Caption = 'Able to Make Top Item';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(33; "Able to Make Parent"; Decimal)
        {
            Caption = 'Able to Make Parent';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(35; "Available Quantity"; Decimal)
        {
            Caption = 'Available Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(36; "Gross Requirement"; Decimal)
        {
            Caption = 'Gross Requirement';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(37; "Scheduled Receipts"; Decimal)
        {
            Caption = 'Scheduled Receipts';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(38; "Unused Quantity"; Decimal)
        {
            Caption = 'Unused Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(40; "Lead Time Calculation"; DateFormula)
        {
            Caption = 'Lead Time Calculation';
            DataClassification = SystemMetadata;
        }
        field(41; "Lead-Time Offset"; DateFormula)
        {
            Caption = 'Lead-Time Offset';
            DataClassification = SystemMetadata;
        }
        field(42; "Rolled-up Lead-Time Offset"; Integer)
        {
            Caption = 'Rolled-up Lead-Time Offset';
            DataClassification = SystemMetadata;
        }
        field(43; "Needed by Date"; Date)
        {
            Caption = 'Needed by Date';
            DataClassification = SystemMetadata;
        }
        field(45; "Safety Lead Time"; DateFormula)
        {
            Caption = 'Safety Lead Time';
            DataClassification = SystemMetadata;
        }
        field(50; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            DataClassification = SystemMetadata;
        }
        field(52; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(54; "Overhead Rate"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Overhead Rate';
            DataClassification = SystemMetadata;
        }
        field(55; "Scrap %"; Decimal)
        {
            BlankZero = true;
            Caption = 'Scrap %';
            DataClassification = SystemMetadata;
        }
        field(56; "Scrap Qty. per Parent"; Decimal)
        {
            Caption = 'Scrap Qty. per Parent';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(57; "Scrap Qty. per Top Item"; Decimal)
        {
            Caption = 'Scrap Qty. per Top Item';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(59; "Resource Usage Type"; Option)
        {
            Caption = 'Resource Usage Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Direct,Fixed';
            OptionMembers = Direct,"Fixed";
        }
        field(61; "Single-Level Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Single-Level Material Cost';
            DataClassification = SystemMetadata;
            DecimalPlaces = 2 : 5;
        }
        field(62; "Single-Level Capacity Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Single-Level Capacity Cost';
            DataClassification = SystemMetadata;
            DecimalPlaces = 2 : 5;
        }
        field(63; "Single-Level Subcontrd. Cost"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Single-Level Subcontrd. Cost';
            DataClassification = SystemMetadata;
            DecimalPlaces = 2 : 5;
        }
        field(64; "Single-Level Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Single-Level Cap. Ovhd Cost';
            DataClassification = SystemMetadata;
            DecimalPlaces = 2 : 5;
        }
        field(65; "Single-Level Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Single-Level Mfg. Ovhd Cost';
            DataClassification = SystemMetadata;
            DecimalPlaces = 2 : 5;
        }
        field(66; "Single-Level Scrap Cost"; Decimal)
        {
            BlankZero = true;
            Caption = 'Single-Level Scrap Cost';
            DataClassification = SystemMetadata;
            DecimalPlaces = 2 : 5;
        }
        field(71; "Rolled-up Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Rolled-up Material Cost';
            DataClassification = SystemMetadata;
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(72; "Rolled-up Capacity Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Rolled-up Capacity Cost';
            DataClassification = SystemMetadata;
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(73; "Rolled-up Subcontracted Cost"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Rolled-up Subcontracted Cost';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(74; "Rolled-up Capacity Ovhd. Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Rolled-up Capacity Ovhd. Cost';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(75; "Rolled-up Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Rolled-up Mfg. Ovhd Cost';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(76; "Rolled-up Scrap Cost"; Decimal)
        {
            BlankZero = true;
            Caption = 'Rolled-up Scrap Cost';
            DataClassification = SystemMetadata;
            DecimalPlaces = 2 : 5;
        }
        field(81; "Total Cost"; Decimal)
        {
            BlankZero = true;
            Caption = 'Total Cost';
            DataClassification = SystemMetadata;
            DecimalPlaces = 2 : 5;
        }
        field(82; "BOM Unit of Measure Code"; Code[10])
        {
            Caption = 'BOM Unit of Measure Code';
            DataClassification = SystemMetadata;
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            if (Type = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("No."));
        }
        field(83; "Qty. per BOM Line"; Decimal)
        {
            Caption = 'Qty. per BOM Line';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(84; "Inventoriable"; Boolean)
        {
            Caption = 'Inventoriable';
            DataClassification = SystemMetadata;
        }
        field(85; "Calculation Formula"; Enum "Quantity Calculation Formula")
        {
            Caption = 'Calculation Formula';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Low-Level Code")
        {
        }
        key(Key3; Type, "No.", Indentation)
        {
            SumIndexFields = "Able to Make Parent";
        }
        key(Key4; "Total Cost")
        {
        }
    }

    fieldgroups
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
        UOMMgt: Codeunit "Unit of Measure Management";
        GLSetupRead: Boolean;

        Text001: Label 'The Low-level Code for Item %1 has not been calculated.';
        Text002: Label 'The Quantity per. field in the BOM for Item %1 has not been set.';
        Text003: Label 'Routing %1 has not been certified.';
        Text004: Label 'Production BOM %1 has not been certified.';
        Text005: Label 'Item %1 is not a BOM. Therefore, the Replenishment System field must be set to Purchase.';
        Text006: Label 'Replenishment System for Item %1 is Assembly, but the item is not an assembly BOM. Verify that this is correct.';
        Text007: Label 'Replenishment System for Item %1 is Prod. Order, but the item does not have a production BOM. Verify that this is correct.';
        Text008: Label 'Item %1 is a BOM, but the Replenishment System field is not set to Assembly or Prod. Order. Verify that the value is correct.';

    procedure TransferFromItem(var EntryNo: Integer; Item: Record Item; DemandDate: Date)
    begin
        Init();
        EntryNo += 1;
        "Entry No." := EntryNo;
        Type := Type::Item;

        InitFromItem(Item);

        "Qty. per Parent" := 1;
        "Qty. per Top Item" := 1;
        "Needed by Date" := DemandDate;
        Indentation := 0;

        OnTransferFromItemCopyFields(Rec, Item);
        Insert(true);
    end;

    procedure TransferFromAsmHeader(var EntryNo: Integer; AsmHeader: Record "Assembly Header")
    var
        BOMItem: Record Item;
    begin
        Init();
        EntryNo += 1;
        "Entry No." := EntryNo;
        Type := Type::Item;

        BOMItem.Get(AsmHeader."Item No.");
        InitFromItem(BOMItem);

        "Qty. per Parent" := 1;
        "Qty. per Top Item" := 1;
        "Unit of Measure Code" := AsmHeader."Unit of Measure Code";
        "Location Code" := AsmHeader."Location Code";
        "Variant Code" := AsmHeader."Variant Code";
        "Needed by Date" := AsmHeader."Due Date";
        Indentation := 0;

        OnTransferFromAsmHeaderCopyFields(Rec, AsmHeader);
        Insert(true);
    end;

    procedure TransferFromAsmLine(var EntryNo: Integer; AsmLine: Record "Assembly Line")
    var
        BOMItem: Record Item;
    begin
        Init();
        EntryNo += 1;
        "Entry No." := EntryNo;
        Type := Type::Item;

        BOMItem.Get(AsmLine."No.");
        InitFromItem(BOMItem);

        "Qty. per Parent" := AsmLine."Quantity per";
        "Qty. per Top Item" := AsmLine."Quantity per";
        "Unit of Measure Code" := AsmLine."Unit of Measure Code";
        "Location Code" := AsmLine."Location Code";
        "Variant Code" := AsmLine."Variant Code";
        "Needed by Date" := AsmLine."Due Date";
        "Lead-Time Offset" := AsmLine."Lead-Time Offset";
        Indentation := 1;

        OnTransferFromAsmLineCopyFields(Rec, AsmLine);
        Insert(true);
    end;

    procedure TransferFromBOMComp(var EntryNo: Integer; BOMComp: Record "BOM Component"; NewIndentation: Integer; ParentQtyPer: Decimal; ParentScrapQtyPer: Decimal; NeedByDate: Date; ParentLocationCode: Code[10])
    var
        BOMItem: Record Item;
        BOMRes: Record Resource;
    begin
        Init();
        EntryNo += 1;
        "Entry No." := EntryNo;

        case BOMComp.Type of
            BOMComp.Type::Item:
                begin
                    BOMItem.Get(BOMComp."No.");
                    InitFromItem(BOMItem);
                end;
            BOMComp.Type::Resource:
                begin
                    BOMRes.Get(BOMComp."No.");
                    InitFromRes(BOMRes);
                    "Resource Usage Type" := BOMComp."Resource Usage Type";
                end;
        end;

        Description := BOMComp.Description;
        "Qty. per Parent" := BOMComp."Quantity per";
        "Qty. per Top Item" := Round(BOMComp."Quantity per" * ParentQtyPer, UOMMgt.QtyRndPrecision());

        "Scrap Qty. per Top Item" :=
          "Qty. per Top Item" - Round((ParentQtyPer - ParentScrapQtyPer) * "Qty. per Parent", UOMMgt.QtyRndPrecision());

        "Unit of Measure Code" := BOMComp."Unit of Measure Code";
        "Variant Code" := BOMComp."Variant Code";
        "Location Code" := ParentLocationCode;
        "Lead-Time Offset" := BOMComp."Lead-Time Offset";
        "Needed by Date" := NeedByDate;
        Indentation := NewIndentation;

        OnTransferFromBOMCompCopyFields(Rec, BOMComp);
        Insert(true);
    end;

    procedure TransferFromProdComp(var EntryNo: Integer; ProdBOMLine: Record "Production BOM Line"; NewIndentation: Integer; ParentQtyPer: Decimal; ParentScrapQtyPer: Decimal; ParentScrapPct: Decimal; NeedByDate: Date; ParentLocationCode: Code[10]; ParentItem: Record Item; BOMQtyPerUOM: Decimal)
    var
        BOMItem: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        CostCalculationMgt: Codeunit "Cost Calculation Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferFromProdComp(EntryNo, ProdBOMLine, NewIndentation, ParentQtyPer, ParentScrapQtyPer, ParentScrapPct, NeedByDate, ParentLocationCode, ParentItem, BOMQtyPerUOM, IsHandled);
        if not IsHandled then begin
            Init();
            EntryNo += 1;
            "Entry No." := EntryNo;
            Type := Type::Item;

            BOMItem.Get(ProdBOMLine."No.");
            InitFromItem(BOMItem);

            if ParentItem."Lot Size" = 0 then
                ParentItem."Lot Size" := 1;

            Description := ProdBOMLine.Description;
            "Qty. per Parent" :=
              CostCalculationMgt.CalcCompItemQtyBase(
                ProdBOMLine, WorkDate(),
                CostCalculationMgt.CalcQtyAdjdForBOMScrap(ParentItem."Lot Size", ParentScrapPct), ParentItem."Routing No.", true) /
              UOMMgt.GetQtyPerUnitOfMeasure(BOMItem, ProdBOMLine."Unit of Measure Code") /
              BOMQtyPerUOM / ParentItem."Lot Size";
            "Qty. per Top Item" := Round(ParentQtyPer * "Qty. per Parent", UOMMgt.QtyRndPrecision());
            "Qty. per Parent" := Round("Qty. per Parent", UOMMgt.QtyRndPrecision());

            "Scrap Qty. per Parent" := "Qty. per Parent" - (ProdBOMLine.Quantity / BOMQtyPerUOM);
            "Scrap Qty. per Top Item" :=
              "Qty. per Top Item" -
              Round((ParentQtyPer - ParentScrapQtyPer) * ("Qty. per Parent" - "Scrap Qty. per Parent"), UOMMgt.QtyRndPrecision());
            "Scrap Qty. per Parent" := Round("Scrap Qty. per Parent", UOMMgt.QtyRndPrecision());

            "Qty. per BOM Line" := ProdBOMLine."Quantity per";
            "Unit of Measure Code" := ProdBOMLine."Unit of Measure Code";
            "Variant Code" := ProdBOMLine."Variant Code";
            "Location Code" := ParentLocationCode;
            "Lead-Time Offset" := ProdBOMLine."Lead-Time Offset";
            "Needed by Date" := NeedByDate;
            Indentation := NewIndentation;
            if ProdBOMLine."Calculation Formula" = ProdBOMLine."Calculation Formula"::"Fixed Quantity" then
                "Calculation Formula" := ProdBOMLine."Calculation Formula";

            OnTransferFromProdCompCopyFields(Rec, ProdBOMLine, ParentItem, ParentQtyPer, ParentScrapQtyPer);
            Insert(true);
        end;
        OnAfterTransferFromProdComp(Rec, ProdBOMLine, ParentItem, EntryNo)
    end;

    procedure TransferFromProdOrderLine(var EntryNo: Integer; ProdOrderLine: Record "Prod. Order Line")
    var
        BOMItem: Record Item;
    begin
        Init();
        EntryNo += 1;
        "Entry No." := EntryNo;
        Type := Type::Item;

        BOMItem.Get(ProdOrderLine."Item No.");
        InitFromItem(BOMItem);

        "Scrap %" := ProdOrderLine."Scrap %";
        "Production BOM No." := ProdOrderLine."Production BOM No.";
        "Qty. per Parent" := 1;
        "Qty. per Top Item" := 1;
        "Unit of Measure Code" := ProdOrderLine."Unit of Measure Code";
        "Variant Code" := ProdOrderLine."Variant Code";
        "Location Code" := ProdOrderLine."Location Code";
        "Needed by Date" := ProdOrderLine."Due Date";
        Indentation := 0;

        OnTransferFromProdOrderLineCopyFields(Rec, ProdOrderLine);
        Insert(true);
    end;

    procedure TransferFromProdOrderComp(var EntryNo: Integer; ProdOrderComp: Record "Prod. Order Component")
    var
        BOMItem: Record Item;
    begin
        Init();
        EntryNo += 1;
        "Entry No." := EntryNo;
        Type := Type::Item;

        BOMItem.Get(ProdOrderComp."Item No.");
        InitFromItem(BOMItem);

        "Qty. per Parent" := ProdOrderComp."Quantity per";
        "Qty. per Top Item" := ProdOrderComp."Quantity per";
        "Unit of Measure Code" := ProdOrderComp."Unit of Measure Code";
        "Variant Code" := ProdOrderComp."Variant Code";
        "Location Code" := ProdOrderComp."Location Code";
        "Needed by Date" := ProdOrderComp."Due Date";
        "Lead-Time Offset" := ProdOrderComp."Lead-Time Offset";
        Indentation := 1;

        OnTransferFromProdOrderCompCopyFields(Rec, ProdOrderComp);
        Insert(true);
    end;

    procedure TransferFromProdRouting(var EntryNo: Integer; RoutingLine: Record "Routing Line"; NewIndentation: Integer; ParentQtyPer: Decimal; NeedByDate: Date; ParentLocationCode: Code[10])
    var
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        RunTimeQty: Decimal;
        SetupWaitMoveTimeQty: Decimal;
    begin
        Init();
        EntryNo += 1;
        "Entry No." := EntryNo;

        case RoutingLine.Type of
            RoutingLine.Type::"Machine Center":
                begin
                    MachineCenter.Get(RoutingLine."No.");
                    InitFromMachineCenter(MachineCenter);
                end;
            RoutingLine.Type::"Work Center":
                begin
                    WorkCenter.Get(RoutingLine."No.");
                    InitFromWorkCenter(WorkCenter);
                end;
        end;

        Description := RoutingLine.Description;
        CalcQtyPerParentFromProdRouting(RoutingLine, RunTimeQty, SetupWaitMoveTimeQty);
        "Qty. per Parent" := SetupWaitMoveTimeQty + RunTimeQty;
        "Qty. per Top Item" := SetupWaitMoveTimeQty + RunTimeQty * ParentQtyPer;
        "Location Code" := ParentLocationCode;
        "Needed by Date" := NeedByDate;
        Indentation := NewIndentation;

        OnTransferFromProdRoutingCopyFields(Rec, RoutingLine);
        Insert(true);
    end;

    procedure InitFromItem(Item: Record Item)
    var
        SKU: Record "Stockkeeping Unit";
        VersionMgt: Codeunit VersionManagement;
        ProductionBOMCheck: Codeunit "Production BOM-Check";
        VersionCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitFromItem(Rec, Item, IsHandled);
        if IsHandled then
            exit;

        Type := Type::Item;
        "No." := Item."No.";
        Description := Item.Description;
        "Unit of Measure Code" := Item."Base Unit of Measure";

        "Production BOM No." := Item."Production BOM No.";
        "Routing No." := Item."Routing No.";
        if GetSKUFromFilter(SKU, "No.") then
            "Replenishment System" := SKU."Replenishment System"
        else
            "Replenishment System" := Item."Replenishment System";
        if "Replenishment System" = "Replenishment System"::"Prod. Order" then begin
            VersionCode := VersionMgt.GetBOMVersion("Production BOM No.", WorkDate(), true);
            "BOM Unit of Measure Code" := VersionMgt.GetBOMUnitOfMeasure("Production BOM No.", VersionCode);
            ProductionBOMCheck.CheckBOM("Production BOM No.", VersionCode);
        end;

        "Lot Size" := Item."Lot Size";
        "Scrap %" := Item."Scrap %";
        "Indirect Cost %" := Item."Indirect Cost %";
        "Overhead Rate" := Item."Overhead Rate";
        "Low-Level Code" := Item."Low-Level Code";
        "Rounding Precision" := Item."Rounding Precision";
        "Lead Time Calculation" := Item."Lead Time Calculation";
        "Safety Lead Time" := Item."Safety Lead Time";
        "Inventoriable" := Item.IsInventoriableType();

        SetRange("Location Code");
        SetRange("Variant Code");

        OnAfterInitFromItem(Rec, Item, SKU);
    end;

    procedure InitFromRes(Resourse: Record Resource)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitFromRes(Rec, Resourse, IsHandled);
        if IsHandled then
            exit;

        Type := Type::Resource;
        "No." := Resourse."No.";
        Description := Resourse.Name;
        "Unit of Measure Code" := Resourse."Base Unit of Measure";

        "Replenishment System" := "Replenishment System"::Transfer;
        "Is Leaf" := true;

        OnAfterInitFromRes(Rec, Resourse);
    end;

    procedure InitFromMachineCenter(MachineCenter: Record "Machine Center")
    var
        WorkCenter: Record "Work Center";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitFromMachineCenter(Rec, MachineCenter, IsHandled);
        if IsHandled then
            exit;

        Type := Type::"Machine Center";
        "No." := MachineCenter."No.";
        Description := MachineCenter.Name;
        if MachineCenter."Work Center No." <> '' then begin
            WorkCenter.Get(MachineCenter."Work Center No.");
            "Unit of Measure Code" := WorkCenter."Unit of Measure Code";
        end;

        "Replenishment System" := "Replenishment System"::Transfer;
        "Is Leaf" := true;

        OnAfterInitFromMachineCenter(Rec, MachineCenter);
    end;

    procedure InitFromWorkCenter(WorkCenter: Record "Work Center")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitFromWorkCenter(Rec, WorkCenter, IsHandled);
        if IsHandled then
            exit;

        Type := Type::"Work Center";
        "No." := WorkCenter."No.";
        Description := WorkCenter.Name;
        "Unit of Measure Code" := WorkCenter."Unit of Measure Code";

        "Replenishment System" := "Replenishment System"::Transfer;
        "Is Leaf" := true;

        OnAfterInitFromWorkCenter(Rec, WorkCenter);
    end;

    local procedure SetAbleToMakeToZeroIfNegative()
    begin
        if "Able to Make Parent" < 0 then
            "Able to Make Parent" := 0;
        if "Able to Make Top Item" < 0 then
            "Able to Make Top Item" := 0;
    end;

    procedure UpdateAbleToMake(AvailQty: Decimal)
    var
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        QtyPerUOM: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAbleToMake(Rec, AvailQty, IsHandled);
        if IsHandled then
            exit;

        QtyPerUOM := 1;
        if Type = Type::Item then begin
            Item.Get("No.");
            QtyPerUOM := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
        end;

        if "Is Leaf" then begin
            if "Qty. per Parent" <> 0 then
                "Able to Make Parent" := Round(AvailQty / ("Qty. per Parent" * QtyPerUOM), UOMMgt.QtyRndPrecision());
            if "Qty. per Top Item" <> 0 then
                "Able to Make Top Item" := Round(AvailQty / ("Qty. per Top Item" * QtyPerUOM), UOMMgt.QtyRndPrecision());
        end else
            if Indentation = 0 then begin
                "Able to Make Parent" := "Able to Make Parent";
                "Able to Make Top Item" := "Able to Make Top Item";
            end else begin
                if "Qty. per Parent" <> 0 then
                    "Able to Make Parent" :=
                      Round((AvailQty + "Able to Make Parent") / ("Qty. per Parent" * QtyPerUOM), UOMMgt.QtyRndPrecision());
                if "Qty. per Top Item" <> 0 then
                    "Able to Make Top Item" :=
                      Round(AvailQty / ("Qty. per Top Item" * QtyPerUOM) + "Able to Make Top Item", UOMMgt.QtyRndPrecision());
            end;

        SetAbleToMakeToZeroIfNegative();
    end;

    procedure AddMaterialCost(SingleLvlCostAmt: Decimal; RolledUpCostAmt: Decimal)
    begin
        "Single-Level Material Cost" += SingleLvlCostAmt;
        "Rolled-up Material Cost" += RolledUpCostAmt;
    end;

    procedure AddCapacityCost(SingleLvlCostAmt: Decimal; RolledUpCostAmt: Decimal)
    begin
        "Single-Level Capacity Cost" += SingleLvlCostAmt;
        "Rolled-up Capacity Cost" += RolledUpCostAmt;
    end;

    procedure AddSubcontrdCost(SingleLvlCostAmt: Decimal; RolledUpCostAmt: Decimal)
    begin
        "Single-Level Subcontrd. Cost" += SingleLvlCostAmt;
        "Rolled-up Subcontracted Cost" += RolledUpCostAmt;
    end;

    procedure AddCapOvhdCost(SingleLvlCostAmt: Decimal; RolledUpCostAmt: Decimal)
    begin
        "Single-Level Cap. Ovhd Cost" += SingleLvlCostAmt;
        "Rolled-up Capacity Ovhd. Cost" += RolledUpCostAmt;
    end;

    procedure AddMfgOvhdCost(SingleLvlCostAmt: Decimal; RolledUpCostAmt: Decimal)
    begin
        "Single-Level Mfg. Ovhd Cost" += SingleLvlCostAmt;
        "Rolled-up Mfg. Ovhd Cost" += RolledUpCostAmt;
    end;

    procedure AddScrapCost(SingleLvlCostAmt: Decimal; RolledUpCostAmt: Decimal)
    begin
        "Single-Level Scrap Cost" += SingleLvlCostAmt;
        "Rolled-up Scrap Cost" += RolledUpCostAmt;
    end;

    procedure GetItemCosts()
    var
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        TestField(Type, Type::Item);
        Item.Get("No.");

        "Unit Cost" := Item."Unit Cost";
        "Single-Level Material Cost" := "Unit Cost";
        "Rolled-up Material Cost" := "Single-Level Material Cost";

        if "Qty. per Parent" <> 0 then
            "Single-Level Scrap Cost" := "Single-Level Material Cost" * "Scrap Qty. per Parent" / "Qty. per Parent";
        if "Qty. per Top Item" <> 0 then
            "Rolled-up Scrap Cost" := "Rolled-up Material Cost" * "Scrap Qty. per Top Item" / "Qty. per Top Item";
        OnGetItemCostsOnBeforeRoundCosts(Rec);
        RoundCosts(UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code") * "Qty. per Top Item");

        OnAfterGetItemCosts(Rec, Item);
    end;

    procedure GetItemUnitCost()
    var
        Item: Record Item;
    begin
        TestField(Type, Type::Item);
        Item.Get("No.");

        "Unit Cost" := Item."Unit Cost";
        "Single-Level Material Cost" :=
          RoundUnitAmt(Item."Unit Cost", UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code") * "Qty. per Top Item");
        "Rolled-up Material Cost" :=
          RoundUnitAmt(Item."Unit Cost", UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code") * "Qty. per Top Item");
    end;

    procedure GetResCosts()
    var
        Res: Record Resource;
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        TestField(Type, Type::Resource);
        Res.Get("No.");

        "Unit Cost" := Res."Unit Cost";
        "Indirect Cost %" := Res."Indirect Cost %";

        "Single-Level Capacity Cost" := Res."Direct Unit Cost";
        "Single-Level Cap. Ovhd Cost" := Res."Unit Cost" - Res."Direct Unit Cost";

        "Rolled-up Capacity Cost" := Res."Direct Unit Cost";
        "Rolled-up Capacity Ovhd. Cost" := Res."Unit Cost" - Res."Direct Unit Cost";

        if "Resource Usage Type" = "Resource Usage Type"::Fixed then
            RoundCosts(UOMMgt.GetResQtyPerUnitOfMeasure(Res, "Unit of Measure Code") * "Qty. per Parent")
        else
            RoundCosts(UOMMgt.GetResQtyPerUnitOfMeasure(Res, "Unit of Measure Code") * "Qty. per Top Item");
    end;

    local procedure GetSKUFromFilter(var SKU: Record "Stockkeeping Unit"; ItemNo: Code[20]): Boolean
    var
        LocationFilter: Text;
        VariantFilter: Text;
    begin
        LocationFilter := GetFilter("Location Code");
        if StrLen(LocationFilter) > MaxStrLen("Location Code") then
            exit(false);

        VariantFilter := GetFilter("Variant Code");
        if StrLen(VariantFilter) > MaxStrLen("Variant Code") then
            exit(false);

        exit(SKU.Get(LocationFilter, ItemNo, VariantFilter));
    end;

    procedure RoundCosts(ShareOfTotalCost: Decimal)
    begin
        "Single-Level Material Cost" := RoundUnitAmt("Single-Level Material Cost", ShareOfTotalCost);
        "Single-Level Capacity Cost" := RoundUnitAmt("Single-Level Capacity Cost", ShareOfTotalCost);
        "Single-Level Subcontrd. Cost" := RoundUnitAmt("Single-Level Subcontrd. Cost", ShareOfTotalCost);
        "Single-Level Cap. Ovhd Cost" := RoundUnitAmt("Single-Level Cap. Ovhd Cost", ShareOfTotalCost);
        "Single-Level Mfg. Ovhd Cost" := RoundUnitAmt("Single-Level Mfg. Ovhd Cost", ShareOfTotalCost);
        "Single-Level Scrap Cost" := RoundUnitAmt("Single-Level Scrap Cost", ShareOfTotalCost);

        "Rolled-up Material Cost" := RoundUnitAmt("Rolled-up Material Cost", ShareOfTotalCost);
        "Rolled-up Capacity Cost" := RoundUnitAmt("Rolled-up Capacity Cost", ShareOfTotalCost);
        "Rolled-up Subcontracted Cost" := RoundUnitAmt("Rolled-up Subcontracted Cost", ShareOfTotalCost);
        "Rolled-up Capacity Ovhd. Cost" := RoundUnitAmt("Rolled-up Capacity Ovhd. Cost", ShareOfTotalCost);
        "Rolled-up Mfg. Ovhd Cost" := RoundUnitAmt("Rolled-up Mfg. Ovhd Cost", ShareOfTotalCost);
        "Rolled-up Scrap Cost" := RoundUnitAmt("Rolled-up Scrap Cost", ShareOfTotalCost);

        OnAfterRoundCosts(Rec, ShareOfTotalCost);
    end;

    local procedure RoundUnitAmt(Amt: Decimal; ShareOfCost: Decimal) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRoundUnitAmt(Amt, ShareOfCost, IsHandled, Result);
        if IsHandled then
            exit(Result);

        GetGLSetup();
        exit(Round(Amt * ShareOfCost, GLSetup."Unit-Amount Rounding Precision"));
    end;

    procedure CalcOvhdCost()
    var
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        LotSize: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcOvhdCost(Rec, IsHandled);
        if IsHandled then
            exit;

        LotSize := 1;
        if "Lot Size" <> 0 then
            LotSize := "Lot Size";

        Item.Get("No.");

        "Overhead Rate" :=
          RoundUnitAmt("Overhead Rate", UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code") * "Qty. per Top Item");

        "Single-Level Mfg. Ovhd Cost" +=
          (("Single-Level Material Cost" +
            "Single-Level Capacity Cost" +
            "Single-Level Subcontrd. Cost" +
            "Single-Level Cap. Ovhd Cost") *
           "Indirect Cost %" / 100) +
          ("Overhead Rate" * LotSize);
        "Single-Level Mfg. Ovhd Cost" := RoundUnitAmt("Single-Level Mfg. Ovhd Cost", 1);

        "Rolled-up Mfg. Ovhd Cost" +=
          (("Rolled-up Material Cost" +
            "Rolled-up Capacity Cost" +
            "Rolled-up Subcontracted Cost" +
            "Rolled-up Capacity Ovhd. Cost" +
            "Rolled-up Mfg. Ovhd Cost") *
           "Indirect Cost %" / 100) +
          ("Overhead Rate" * LotSize);
        "Rolled-up Mfg. Ovhd Cost" := RoundUnitAmt("Rolled-up Mfg. Ovhd Cost", 1);
    end;

    procedure CalcDirectCost(): Decimal
    begin
        exit(
          "Single-Level Material Cost" +
          "Single-Level Capacity Cost" +
          "Single-Level Subcontrd. Cost");
    end;

    procedure CalcIndirectCost(): Decimal
    begin
        exit("Single-Level Mfg. Ovhd Cost" + "Single-Level Cap. Ovhd Cost");
    end;

    procedure CalcUnitCost()
    begin
        "Total Cost" := CalcDirectCost() + CalcIndirectCost();
        "Unit Cost" := 0;
        if "Qty. per Top Item" <> 0 then
            "Unit Cost" := Round("Total Cost" / "Qty. per Top Item", 0.00001);
        OnAfterCalcUnitCost(Rec);
    end;

    local procedure CalcQtyPerParentFromProdRouting(RoutingLine: Record "Routing Line"; var RunTimeQty: Decimal; var SetupWaitMoveTimeQty: Decimal)
    var
        WorkCenter: Record "Work Center";
        CalendarMgt: Codeunit "Shop Calendar Management";
        SetupTimeFactor: Decimal;
        RunTimeFactor: Decimal;
        WaitTimeFactor: Decimal;
        MoveTimeFactor: Decimal;
        CurrentTimeFactor: Decimal;
        LotSizeFactor: Decimal;
    begin
        SetupTimeFactor := CalendarMgt.TimeFactor(RoutingLine."Setup Time Unit of Meas. Code");
        RunTimeFactor := CalendarMgt.TimeFactor(RoutingLine."Run Time Unit of Meas. Code");
        WaitTimeFactor := CalendarMgt.TimeFactor(RoutingLine."Wait Time Unit of Meas. Code");
        MoveTimeFactor := CalendarMgt.TimeFactor(RoutingLine."Move Time Unit of Meas. Code");

        if RoutingLine."Lot Size" = 0 then
            LotSizeFactor := 1
        else
            LotSizeFactor := RoutingLine."Lot Size";

        RunTimeQty := RoutingLine."Run Time" * RunTimeFactor / LotSizeFactor;
        SetupWaitMoveTimeQty :=
          (RoutingLine."Setup Time" * SetupTimeFactor + RoutingLine."Wait Time" * WaitTimeFactor +
          RoutingLine."Move Time" * MoveTimeFactor) / LotSizeFactor;

        if "Unit of Measure Code" = '' then begin
            // select base UOM from Setup/Run/Wait/Move UOMs
            CurrentTimeFactor := SetupTimeFactor;
            "Unit of Measure Code" := RoutingLine."Setup Time Unit of Meas. Code";
            if CurrentTimeFactor > RunTimeFactor then begin
                CurrentTimeFactor := RunTimeFactor;
                "Unit of Measure Code" := RoutingLine."Run Time Unit of Meas. Code";
            end;
            if CurrentTimeFactor > WaitTimeFactor then begin
                CurrentTimeFactor := WaitTimeFactor;
                "Unit of Measure Code" := RoutingLine."Wait Time Unit of Meas. Code";
            end;
            if CurrentTimeFactor > MoveTimeFactor then begin
                CurrentTimeFactor := MoveTimeFactor;
                "Unit of Measure Code" := RoutingLine."Move Time Unit of Meas. Code";
            end;
        end;

        if not WorkCenter.Get(RoutingLine."Work Center No.") then
            WorkCenter.Init();

        RunTimeQty :=
          Round(RunTimeQty / CalendarMgt.TimeFactor("Unit of Measure Code"), WorkCenter."Calendar Rounding Precision");
        SetupWaitMoveTimeQty :=
          Round(SetupWaitMoveTimeQty / CalendarMgt.TimeFactor("Unit of Measure Code"), WorkCenter."Calendar Rounding Precision");
    end;

    local procedure IsLowLevelOk(LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log") Result: Boolean
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsLowLevelOk(Rec, Result, IsHandled, LogWarning, BOMWarningLog);
        if IsHandled then
            exit(Result);

        if Type <> Type::Item then
            exit(true);
        if "No." = '' then
            exit(true);

        Item.Get("No.");
        if TraverseIsLowLevelOk(Item) then
            exit(true);

        if LogWarning then
            BOMWarningLog.SetWarning(StrSubstNo(Text001, Item."No."), DATABASE::Item, Item.GetPosition());
    end;

    local procedure TraverseIsLowLevelOk(ParentItem: Record Item): Boolean
    var
        ParentBOMBuffer: Record "BOM Buffer";
        ChildItem: Record Item;
    begin
        if Type <> Type::Item then
            exit(true);
        if "No." = '' then
            exit(true);

        ParentItem.Get("No.");
        ParentBOMBuffer := Rec;
        while (Next() <> 0) and (ParentBOMBuffer.Indentation < Indentation) do
            if (ParentBOMBuffer.Indentation + 1 = Indentation) and (Type = Type::Item) and ("No." <> '') then begin
                ChildItem.Get("No.");
                if ParentItem."Low-Level Code" >= ChildItem."Low-Level Code" then begin
                    Rec := ParentBOMBuffer;
                    exit(false);
                end;
            end;

        Rec := ParentBOMBuffer;
        exit(true);
    end;

    local procedure IsQtyPerOk(LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log"): Boolean
    var
        Item: Record Item;
        CopyOfBOMBuffer: Record "BOM Buffer";
        ProdBOMHeader: Record "Production BOM Header";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsQtyPerOk(Rec, BOMWarningLog, LogWarning, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Qty. per Parent" <> 0 then
            exit(true);
        if "No." = '' then
            exit(true);
        if Indentation = 0 then
            exit(true);
        if Type in [Type::"Machine Center", Type::"Work Center"] then
            exit(true);

        if LogWarning then begin
            CopyOfBOMBuffer.Copy(Rec);
            Reset();
            SetRange(Indentation, 0, Indentation);
            SetRange(Type, Type::Item);
            while (Next(-1) <> 0) and (Indentation >= CopyOfBOMBuffer.Indentation) do
                ;
            if "Entry No." <> CopyOfBOMBuffer."Entry No." then begin
                Item.Get("No.");
                Item.CalcFields("Assembly BOM");
                if Item."Assembly BOM" then
                    BOMWarningLog.SetWarning(StrSubstNo(Text002, Item."No."), DATABASE::Item, Item.GetPosition())
                else
                    if ProdBOMHeader.Get(Item."Production BOM No.") then
                        BOMWarningLog.SetWarning(StrSubstNo(Text002, Item."No."), DATABASE::"Production BOM Header", ProdBOMHeader.GetPosition())
            end;
            Copy(CopyOfBOMBuffer);
        end;
    end;

    local procedure IsProdBOMOk(LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log"): Boolean
    var
        ProdBOMHeader: Record "Production BOM Header";
    begin
        if "Production BOM No." = '' then
            exit(true);
        ProdBOMHeader.Get("Production BOM No.");
        if ProdBOMHeader.Status = ProdBOMHeader.Status::Certified then
            exit(true);

        if LogWarning then
            BOMWarningLog.SetWarning(StrSubstNo(Text004, ProdBOMHeader."No."), DATABASE::"Production BOM Header", ProdBOMHeader.GetPosition());
    end;

    local procedure IsRoutingOk(LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log"): Boolean
    var
        RoutingHeader: Record "Routing Header";
    begin
        if "Routing No." = '' then
            exit(true);
        RoutingHeader.Get("Routing No.");
        if RoutingHeader.Status = RoutingHeader.Status::Certified then
            exit(true);

        if LogWarning then
            BOMWarningLog.SetWarning(StrSubstNo(Text003, RoutingHeader."No."), DATABASE::"Routing Header", RoutingHeader.GetPosition());
    end;

    local procedure IsReplenishmentOk(LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log"): Boolean
    var
        Item: Record Item;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsReplenishmentOk(Rec, BOMWarningLog, LogWarning, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Type <> Type::Item then
            exit(true);
        if "No." = '' then
            exit(true);

        Item.Get("No.");
        if "Is Leaf" then begin
            if Item."Replenishment System" in ["Replenishment System"::Purchase, "Replenishment System"::Transfer] then
                exit(true);
            if LogWarning then
                BOMWarningLog.SetWarning(StrSubstNo(Text005, Item."No."), DATABASE::Item, Item.GetPosition());
        end else begin
            if Item."Replenishment System" in ["Replenishment System"::"Prod. Order", "Replenishment System"::Assembly] then
                exit(IsBOMOk(LogWarning, BOMWarningLog));
            if LogWarning then
                BOMWarningLog.SetWarning(StrSubstNo(Text008, Item."No."), DATABASE::Item, Item.GetPosition());
        end;
    end;

    local procedure IsBOMOk(LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log") Result: Boolean
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsBOMOk(Rec, Result, IsHandled, LogWarning, BOMWarningLog);
        if IsHandled then
            exit(Result);

        if Type <> Type::Item then
            exit(true);
        if "No." = '' then
            exit(true);

        Item.Get("No.");
        case Item."Replenishment System" of
            Item."Replenishment System"::Assembly:
                begin
                    Item.CalcFields("Assembly BOM");
                    if Item."Assembly BOM" then
                        exit(true);
                    if LogWarning then
                        BOMWarningLog.SetWarning(StrSubstNo(Text006, Item."No."), DATABASE::Item, Item.GetPosition());
                end;
            Item."Replenishment System"::"Prod. Order":
                begin
                    if Item."Production BOM No." <> '' then
                        exit(true);
                    if LogWarning then
                        BOMWarningLog.SetWarning(StrSubstNo(Text007, Item."No."), DATABASE::Item, Item.GetPosition());
                end;
            else
                exit(true);
        end;
    end;

    procedure IsLineOk(LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log") Result: Boolean
    begin
        Result :=
          IsLowLevelOk(LogWarning, BOMWarningLog) and
          IsQtyPerOk(LogWarning, BOMWarningLog) and
          IsProdBOMOk(LogWarning, BOMWarningLog) and
          IsRoutingOk(LogWarning, BOMWarningLog) and
          IsReplenishmentOk(LogWarning, BOMWarningLog);

        OnAfterIsLineOk(Rec, LogWarning, BOMWarningLog, Result);
    end;

    procedure AreAllLinesOk(var BOMWarningLog: Record "BOM Warning Log") IsOk: Boolean
    var
        CopyOfBOMBuffer: Record "BOM Buffer";
    begin
        IsOk := true;
        CopyOfBOMBuffer.Copy(Rec);

        BOMWarningLog.Reset();
        BOMWarningLog.DeleteAll();

        Reset();
        if FindSet() then
            repeat
                if not IsLineOk(true, BOMWarningLog) then
                    IsOk := false;
            until Next() = 0;
        Copy(CopyOfBOMBuffer);
    end;

    local procedure GetGLSetup()
    begin
        if GLSetupRead then
            exit;
        GLSetup.Get();
        GLSetupRead := true;
    end;

    procedure SetLocationVariantFiltersFrom(var ItemFilter: Record Item)
    begin
        SetFilter("Location Code", ItemFilter.GetFilter("Location Filter"));
        SetFilter("Variant Code", ItemFilter.GetFilter("Variant Filter"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcUnitCost(var BOMBuffer: Record "BOM Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemCosts(var BOMBuffer: Record "BOM Buffer"; Item: Record Item);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromItem(var BOMBuffer: Record "BOM Buffer"; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromRes(var BOMBuffer: Record "BOM Buffer"; Resource: Record Resource);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromMachineCenter(var BOMBuffer: Record "BOM Buffer"; MachineCenter: Record "Machine Center");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromWorkCenter(var BOMBuffer: Record "BOM Buffer"; WorkCenter: Record "Work Center");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsLineOk(var BOMBuffer: Record "BOM Buffer"; LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundCosts(var BOMBuffer: Record "BOM Buffer"; ShareOfTotalCost: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdComp(var BOMBuffer: Record "BOM Buffer"; ProductionBOMLine: Record "Production BOM Line"; ParentItem: Record Item; var EntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcOvhdCost(var BOMBuffer: Record "BOM Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitFromItem(var BOMBuffer: Record "BOM Buffer"; Item: Record Item; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsBOMOk(var BOMBuffer: Record "BOM Buffer"; var Result: Boolean; var IsHandled: Boolean; var LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsLowLevelOk(var BOMBuffer: Record "BOM Buffer"; var Result: Boolean; var IsHandled: Boolean; var LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitFromRes(var BOMBuffer: Record "BOM Buffer"; Resource: Record Resource; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitFromMachineCenter(var BOMBuffer: Record "BOM Buffer"; MachineCenter: Record "Machine Center"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnbeforeInitFromWorkCenter(var BOMBuffer: Record "BOM Buffer"; WorkCenter: Record "Work Center"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferFromProdComp(var EntryNo: Integer; ProductionBOMLine: Record "Production BOM Line"; NewIndentation: Integer; ParentQtyPer: Decimal; ParentScrapQtyPer: Decimal; ParentScrapPct: Decimal; NeedByDate: Date; ParentLocationCode: Code[10]; ParentItem: Record Item; BOMQtyPerUOM: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAbleToMake(var BOMBuffer: Record "BOM Buffer"; var AvailQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetItemCostsOnBeforeRoundCosts(var BOMBuffer: Record "BOM Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromItemCopyFields(var BOMBuffer: Record "BOM Buffer"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromAsmHeaderCopyFields(var BOMBuffer: Record "BOM Buffer"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromAsmLineCopyFields(var BOMBuffer: Record "BOM Buffer"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromBOMCompCopyFields(var BOMBuffer: Record "BOM Buffer"; BOMComponent: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromProdCompCopyFields(var BOMBuffer: Record "BOM Buffer"; ProductionBOMLine: Record "Production BOM Line"; ParentItem: Record Item; ParentQtyPer: Decimal; ParentScrapQtyPer: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromProdOrderLineCopyFields(var BOMBuffer: Record "BOM Buffer"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromProdOrderCompCopyFields(var BOMBuffer: Record "BOM Buffer"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromProdRoutingCopyFields(var BOMBuffer: Record "BOM Buffer"; RoutingLine: Record "Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsQtyPerOk(var BOMBuffer: Record "BOM Buffer"; var BOMWarningLog: Record "BOM Warning Log"; LogWarning: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsReplenishmentOk(var BOMBuffer: Record "BOM Buffer"; var BOMWarningLog: Record "BOM Warning Log"; LogWarning: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundUnitAmt(Amt: Decimal; ShareOfCost: Decimal; var IsHandled: Boolean; var ReturnValue: Decimal)
    begin
    end;
}

