namespace Microsoft.Inventory.Item;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.UOM;
using Microsoft.Integration.Dataverse;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;

table 5404 "Item Unit of Measure"
{
    Caption = 'Item Unit of Measure';
    LookupPageID = "Item Units of Measure";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;

            trigger OnValidate()
            begin
                CalcWeight();
            end;
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = "Unit of Measure";
        }
        field(3; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            InitValue = 1;

            trigger OnValidate()
            var
                BaseItemUoM: Record "Item Unit of Measure";
            begin
                if "Qty. per Unit of Measure" <= 0 then
                    FieldError("Qty. per Unit of Measure", Text000);
                if xRec."Qty. per Unit of Measure" <> "Qty. per Unit of Measure" then
                    CheckNoEntriesWithUoM();
                Item.Get("Item No.");
                if Item."Base Unit of Measure" = Code then
                    TestField("Qty. per Unit of Measure", 1)
                else
                    if BaseItemUoM.Get(Rec."Item No.", Item."Base Unit of Measure") then
                        CheckQtyPerUoMPrecision(Rec, BaseItemUoM."Qty. Rounding Precision");
                CalcWeight();
            end;
        }
        field(4; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;

            trigger OnValidate()
            var
                ItemUoM: Record "Item Unit of Measure";
            begin
                if xRec."Qty. Rounding Precision" <> "Qty. Rounding Precision" then begin
                    CheckNoEntriesWithUoM();
                    Item.Get(Rec."Item No.");
                    ItemUoM.SetFilter("Item No.", Rec."Item No.");
                    ItemUoM.SetFilter(Code, '<>%1', Item."Base Unit of Measure");
                    if (ItemUoM.FindSet()) then
                        repeat
                            CheckQtyPerUoMPrecision(ItemUoM, Rec."Qty. Rounding Precision");
                        until (ItemUoM.Next() = 0);
                    Session.LogMessage('0000FAR', StrSubstNo(UoMQtyRoundingPrecisionChangedTxt, xRec."Qty. Rounding Precision", "Qty. Rounding Precision", Item.SystemId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', UoMLoggingTelemetryCategoryTxt);
                end;
            end;
        }
        field(721; "Coupled to Dataverse"; Boolean)
        {
            Caption = 'Coupled to Dynamics 365 Sales';
            FieldClass = FlowField;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::"Item Unit of Measure")));
        }
        field(7300; Length; Decimal)
        {
            Caption = 'Length';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcCubage();
            end;
        }
        field(7301; Width; Decimal)
        {
            Caption = 'Width';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcCubage();
            end;
        }
        field(7302; Height; Decimal)
        {
            Caption = 'Height';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcCubage();
            end;
        }
        field(7303; Cubage; Decimal)
        {
            Caption = 'Cubage';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(7304; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Qty. per Unit of Measure")
        {
        }
        key(Key3; "Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", "Qty. per Unit of Measure")
        {
        }
    }

    trigger OnDelete()
    begin
        if Rec.Code <> '' then begin
            TestItemUOM();
            CheckNoEntriesWithUoM();
        end;
    end;

    trigger OnInsert()
    begin
        TestField(Code);
    end;

    trigger OnRename()
    begin
        TestItemUOM();
    end;

    var
        Item: Record Item;

        Text000: Label 'must be greater than 0';
        Text001: Label 'You cannot rename %1 %2 for item %3 because it is the item''s %4 and there are one or more open ledger entries for the item.';
        CannotModifyBaseUnitOfMeasureErr: Label 'You cannot modify item unit of measure %1 for item %2 because it is the item''s base unit of measure.', Comment = '%1 Value of Measure (KG, PCS...), %2 Item ID';
        CannotModifySalesUnitOfMeasureErr: Label 'You cannot modify item unit of measure %1 for item %2 because it is the item''s sales unit of measure.', Comment = '%1 Value of Measure (KG, PCS...), %2 Item ID';
        CannotModifyPurchUnitOfMeasureErr: Label 'You cannot modify item unit of measure %1 for item %2 because it is the item''s purchase unit of measure.', Comment = '%1 Value of Measure (KG, PCS...), %2 Item ID';
        CannotModifyPutAwayUnitOfMeasureErr: Label 'You cannot modify item unit of measure %1 for item %2 because it is the item''s put-away unit of measure.', Comment = '%1 Value of Measure (KG, PCS...), %2 Item ID';
        CannotModifyUnitOfMeasureErr: Label 'You cannot modify %1 %2 for item %3 because non-zero %5 with %2 exists in %4.', Comment = '%1 Table name (Item Unit of measure), %2 Value of Measure (KG, PCS...), %3 Item ID, %4 Entry Table Name, %5 Field Caption';
        CannotModifyUOMWithWhseEntriesErr: Label 'You cannot modify %1 %2 for item %3 because there are one or more warehouse adjustment entries for the item.', Comment = '%1 = Item Unit of Measure %2 = Code %3 = Item No.';
        QtyPerUoMRoundPrecisionNotAlignedErr: Label 'The quantity per unit of measure %1 for item %2 does not align with the quantity rounding precision %3 for the current base unit of measure.', Comment = '%1 = Qty. per Unit of Measure value, %2 = Item Code, %3 = Qty. Rounding Precision value';
        UoMLoggingTelemetryCategoryTxt: Label 'AL UoM Logging.', Locked = true;
        UoMQtyRoundingPrecisionChangedTxt: Label 'Base UoM Qty. Rounding Precision changed from %1 to %2, for item: %3.', Locked = true;

    local procedure CalcCubage()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCubage(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        Cubage := Length * Width * Height;

        OnAfterCalcCubage(Rec);
    end;

    procedure CalcWeight()
    begin
        if Item."No." <> "Item No." then
            Item.Get("Item No.");

        Weight := "Qty. per Unit of Measure" * Item."Net Weight";

        OnAfterCalcWeight(Rec);
    end;

    local procedure TestNoOpenEntriesExist()
    var
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if Item.Get("Item No.") then
            if Item."Base Unit of Measure" = xRec.Code then begin
                ItemLedgEntry.SetCurrentKey("Item No.", Open);
                ItemLedgEntry.SetRange("Item No.", "Item No.");
                ItemLedgEntry.SetRange(Open, true);
                if not ItemLedgEntry.IsEmpty() then
                    Error(Text001, TableCaption(), xRec.Code, "Item No.", Item.FieldCaption("Base Unit of Measure"));
            end;
    end;

    local procedure TestNoWhseAdjmtEntriesExist()
    var
        WhseEntry: Record "Warehouse Entry";
        Location: Record Location;
        Bin: Record Bin;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestNoWhseAdjmtEntriesExist(Rec, IsHandled);
        if IsHandled then
            exit;

        WhseEntry.SetRange("Item No.", "Item No.");
        WhseEntry.SetRange("Unit of Measure Code", xRec.Code);
        if Location.FindSet() then
            repeat
                if Bin.Get(Location.Code, Location."Adjustment Bin Code") then begin
                    WhseEntry.SetRange("Zone Code", Bin."Zone Code");
                    if not WhseEntry.IsEmpty() then
                        Error(CannotModifyUOMWithWhseEntriesErr, TableCaption(), xRec.Code, "Item No.");
                end;
            until Location.Next() = 0;
    end;

    procedure TestItemSetup()
    begin
        if Item.Get("Item No.") then begin
            if Item."Base Unit of Measure" = xRec.Code then
                Error(CannotModifyBaseUnitOfMeasureErr, xRec.Code, "Item No.");
            if Item."Sales Unit of Measure" = xRec.Code then
                Error(CannotModifySalesUnitOfMeasureErr, xRec.Code, "Item No.");
            if Item."Purch. Unit of Measure" = xRec.Code then
                Error(CannotModifyPurchUnitOfMeasureErr, xRec.Code, "Item No.");
            if Item."Put-away Unit of Measure Code" = xRec.Code then
                Error(CannotModifyPutAwayUnitOfMeasureErr, xRec.Code, "Item No.");
        end;
        OnAfterTestItemSetup(Rec, xRec);
    end;

    local procedure TestItemUOM()
    begin
        TestItemSetup();
        TestNoOpenEntriesExist();
        TestNoWhseAdjmtEntriesExist();
    end;

    procedure CheckNoEntriesWithUoM()
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", "Item No.");
        WarehouseEntry.SetRange("Unit of Measure Code", Code);
        WarehouseEntry.CalcSums("Qty. (Base)", Quantity);
        if (WarehouseEntry."Qty. (Base)" <> 0) or (WarehouseEntry.Quantity <> 0) then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption(), xRec.Code, "Item No.", WarehouseEntry.TableCaption(),
              WarehouseEntry.FieldCaption(Quantity));

        CheckNoOutstandingQty();
    end;

    local procedure CheckNoOutstandingQty()
    begin
        CheckNoOutstandingQtyPurchLine();
        CheckNoOutstandingQtySalesLine();
        CheckNoOutstandingQtyTransferLine();
        CheckNoRemQtyProdOrderLine();
        CheckNoRemQtyProdOrderComponent();
        CheckNoOutstandingQtyServiceLine();
        CheckNoRemQtyAssemblyHeader();
        CheckNoRemQtyAssemblyLine();

        OnAfterCheckNoOutstandingQty(Rec, xRec);
    end;

    local procedure CheckNoOutstandingQtyPurchLine()
    var
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoOutstandingQtyPurchLine(Rec, xRec, PurchLine, IsHandled);
        if IsHandled then
            exit;

        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("No.", "Item No.");
        PurchLine.SetRange("Unit of Measure Code", Code);
        PurchLine.SetFilter("Outstanding Quantity", '<>%1', 0);
        if not PurchLine.IsEmpty() then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption(), xRec.Code, "Item No.",
              PurchLine.TableCaption(), PurchLine.FieldCaption("Qty. to Receive"));
    end;

    local procedure CheckNoOutstandingQtySalesLine()
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoOutstandingQtySalesLine(Rec, xRec, SalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", "Item No.");
        SalesLine.SetRange("Unit of Measure Code", Code);
        SalesLine.SetFilter("Outstanding Quantity", '<>%1', 0);
        if not SalesLine.IsEmpty() then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption(), xRec.Code, "Item No.",
              SalesLine.TableCaption(), SalesLine.FieldCaption("Qty. to Ship"));
    end;

    local procedure CheckNoOutstandingQtyTransferLine()
    var
        TransferLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoOutstandingQtyTransferLine(Rec, xRec, TransferLine, IsHandled);
        if IsHandled then
            exit;

        TransferLine.SetRange("Item No.", "Item No.");
        TransferLine.SetRange("Unit of Measure Code", Code);
        TransferLine.SetFilter("Outstanding Quantity", '<>%1', 0);
        if not TransferLine.IsEmpty() then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption(), xRec.Code, "Item No.",
              TransferLine.TableCaption(), TransferLine.FieldCaption("Qty. to Ship"));
    end;

    local procedure CheckNoRemQtyProdOrderLine()
    var
        ProdOrderLine: Record "Prod. Order Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoRemQtyProdOrderLine(Rec, xRec, ProdOrderLine, IsHandled);
        if IsHandled then
            exit;

        ProdOrderLine.SetRange("Item No.", "Item No.");
        ProdOrderLine.SetRange("Unit of Measure Code", Code);
        ProdOrderLine.SetFilter("Remaining Quantity", '<>%1', 0);
        ProdOrderLine.SetFilter(Status, '<>%1', ProdOrderLine.Status::Finished);
        if not ProdOrderLine.IsEmpty() then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption(), xRec.Code, "Item No.",
              ProdOrderLine.TableCaption(), ProdOrderLine.FieldCaption("Remaining Quantity"));
    end;

    local procedure CheckNoRemQtyProdOrderComponent()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoRemQtyProdOrderComponent(Rec, xRec, ProdOrderComponent, IsHandled);
        if IsHandled then
            exit;

        ProdOrderComponent.SetRange("Item No.", "Item No.");
        ProdOrderComponent.SetRange("Unit of Measure Code", Code);
        ProdOrderComponent.SetFilter("Remaining Quantity", '<>%1', 0);
        ProdOrderComponent.SetFilter(Status, '<>%1', ProdOrderComponent.Status::Finished);
        if not ProdOrderComponent.IsEmpty() then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption(), xRec.Code, "Item No.",
              ProdOrderComponent.TableCaption(), ProdOrderComponent.FieldCaption("Remaining Quantity"));
    end;

    local procedure CheckNoOutstandingQtyServiceLine()
    var
        ServiceLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoOutstandingQtyServiceLine(Rec, xRec, ServiceLine, IsHandled);
        if IsHandled then
            exit;

        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetRange("No.", "Item No.");
        ServiceLine.SetRange("Unit of Measure Code", Code);
        ServiceLine.SetFilter("Outstanding Quantity", '<>%1', 0);
        if not ServiceLine.IsEmpty() then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption(), xRec.Code, "Item No.",
              ServiceLine.TableCaption(), ServiceLine.FieldCaption("Qty. to Ship"));
    end;

    local procedure CheckNoRemQtyAssemblyHeader()
    var
        AssemblyHeader: Record "Assembly Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoRemQtyAssemblyHeader(Rec, xRec, AssemblyHeader, IsHandled);
        if IsHandled then
            exit;

        AssemblyHeader.SetRange("Item No.", "Item No.");
        AssemblyHeader.SetRange("Unit of Measure Code", Code);
        AssemblyHeader.SetFilter("Remaining Quantity", '<>%1', 0);
        if not AssemblyHeader.IsEmpty() then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption(), xRec.Code, "Item No.",
              AssemblyHeader.TableCaption(), AssemblyHeader.FieldCaption("Remaining Quantity"));
    end;

    local procedure CheckNoRemQtyAssemblyLine()
    var
        AssemblyLine: Record "Assembly Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoRemQtyAssemblyLine(Rec, xRec, AssemblyLine, IsHandled);
        if IsHandled then
            exit;

        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.SetRange("No.", "Item No.");
        AssemblyLine.SetRange("Unit of Measure Code", Code);
        AssemblyLine.SetFilter("Remaining Quantity", '<>%1', 0);
        if not AssemblyLine.IsEmpty() then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption(), xRec.Code, "Item No.",
              AssemblyLine.TableCaption(), AssemblyLine.FieldCaption("Remaining Quantity"));
    end;

    local procedure CheckQtyPerUoMPrecision(ItemUoM: Record "Item Unit of Measure"; BaseRoundingPrecision: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQtyPerUoMPrecision(ItemUoM, BaseRoundingPrecision, IsHandled);
        if IsHandled then
            exit;

        if BaseRoundingPrecision <> 0 then
            if ItemUoM."Qty. per Unit of Measure" mod BaseRoundingPrecision <> 0 then
                Error(QtyPerUoMRoundPrecisionNotAlignedErr,
                    ItemUoM."Qty. per Unit of Measure",
                    ItemUoM.Code,
                    BaseRoundingPrecision);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcCubage(var ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcWeight(var ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestItemSetup(var Rec: Record "Item Unit of Measure"; xRec: Record "Item Unit of Measure")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCubage(var ItemUnitOfMeasure: Record "Item Unit of Measure"; var xItemUnitOfMeasure: Record "Item Unit of Measure"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoRemQtyAssemblyLine(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure"; var AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoOutstandingQtySalesLine(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoRemQtyAssemblyHeader(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure"; var AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoRemQtyProdOrderLine(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoRemQtyProdOrderComponent(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure"; var ProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoOutstandingQtyPurchLine(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoOutstandingQtyServiceLine(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure"; var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoOutstandingQtyTransferLine(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure"; var TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyPerUoMPrecision(ItemUnitofMeasure: Record "Item Unit of Measure"; BaseRoundingPrecision: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoWhseAdjmtEntriesExist(ItemUnitOfMeasure: Record "Item Unit of Measure"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckNoOutstandingQty(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
    end;
}

