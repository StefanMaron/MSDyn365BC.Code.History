codeunit 5402 "Unit of Measure Management"
{

    trigger OnRun()
    begin
    end;

    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        Text001: Label 'Quantity per unit of measure must be defined.';

    procedure GetQtyPerUnitOfMeasure(Item: Record Item; UnitOfMeasureCode: Code[10]) QtyPerUnitOfMeasure: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetQtyPerUnitOfMeasure(Item, UnitOfMeasureCode, QtyPerUnitOfMeasure, IsHandled);
        if IsHandled then
            exit(QtyPerUnitOfMeasure);

        Item.TestField("No.");
        if UnitOfMeasureCode in [Item."Base Unit of Measure", ''] then
            exit(1);
        if (Item."No." <> ItemUnitOfMeasure."Item No.") or
           (UnitOfMeasureCode <> ItemUnitOfMeasure.Code)
        then
            ItemUnitOfMeasure.Get(Item."No.", UnitOfMeasureCode);
        ItemUnitOfMeasure.TestField("Qty. per Unit of Measure");
        exit(ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    procedure GetResQtyPerUnitOfMeasure(Resource: Record Resource; UnitOfMeasureCode: Code[10]) QtyPerUnitOfMeasure: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetResQtyPerUnitOfMeasure(Resource, UnitOfMeasureCode, QtyPerUnitOfMeasure, IsHandled);
        if IsHandled then
            exit(QtyPerUnitOfMeasure);

        Resource.TestField("No.");
        if UnitOfMeasureCode in [Resource."Base Unit of Measure", ''] then
            exit(1);
        if (Resource."No." <> ResourceUnitOfMeasure."Resource No.") or
           (UnitOfMeasureCode <> ResourceUnitOfMeasure.Code)
        then
            ResourceUnitOfMeasure.Get(Resource."No.", UnitOfMeasureCode);
        ResourceUnitOfMeasure.TestField("Qty. per Unit of Measure");
        exit(ResourceUnitOfMeasure."Qty. per Unit of Measure");
    end;

    procedure CalcBaseQty(Qty: Decimal; QtyPerUOM: Decimal): Decimal
    begin
        exit(CalcBaseQty('', '', '', Qty, QtyPerUOM));
    end;

    procedure CalcBaseQty(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; QtyBase: Decimal; QtyPerUOM: Decimal) QtyRounded: Decimal
    begin
        QtyRounded := RoundQty(QtyBase * QtyPerUOM);

        OnAfterCalcBaseQtyPerUnitOfMeasure(ItemNo, VariantCode, UOMCode, QtyPerUOM, QtyBase, QtyRounded);
    end;

    procedure CalcQtyFromBase(QtyBase: Decimal; QtyPerUOM: Decimal): Decimal
    begin
        exit(CalcQtyFromBase('', '', '', QtyBase, QtyPerUOM));
    end;

    procedure CalcQtyFromBase(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; QtyBase: Decimal; QtyPerUOM: Decimal) QtyRounded: Decimal
    begin
        if QtyPerUOM = 0 then
            Error(Text001);

        QtyRounded := RoundQty(QtyBase / QtyPerUOM);

        OnAfterCalcQtyFromBasePerUnitOfMeasure(ItemNo, VariantCode, UOMCode, QtyPerUOM, QtyBase, QtyRounded);
    end;

    procedure RoundQty(Qty: Decimal): Decimal
    begin
        exit(Round(Qty, QtyRndPrecision));
    end;

    procedure RoundToItemRndPrecision(Qty: Decimal; ItemRndPrecision: Decimal): Decimal
    begin
        exit(Round(RoundQty(Qty), ItemRndPrecision, '>'));
    end;

    procedure QtyRndPrecision(): Decimal
    var
        RoundingPrecision: Decimal;
    begin
        OnBeforeQtyRndPrecision(RoundingPrecision);
        if RoundingPrecision = 0 then
            RoundingPrecision := 0.00001;
        exit(RoundingPrecision);
    end;

    procedure CubageRndPrecision(): Decimal
    var
        RoundingPrecision: Decimal;
    begin
        OnBeforeCubageRndPrecision(RoundingPrecision);
        if RoundingPrecision = 0 then
            RoundingPrecision := 0.00001;
        exit(RoundingPrecision);
    end;

    procedure TimeRndPrecision(): Decimal
    var
        RoundingPrecision: Decimal;
    begin
        OnBeforeTimeRndPrecision(RoundingPrecision);
        if RoundingPrecision = 0 then
            RoundingPrecision := 0.00001;
        exit(RoundingPrecision);
    end;

    procedure WeightRndPrecision(): Decimal
    var
        RoundingPrecision: Decimal;
    begin
        OnBeforeWeightRndPrecision(RoundingPrecision);
        if RoundingPrecision = 0 then
            RoundingPrecision := 0.00001;
        exit(RoundingPrecision);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBaseQtyPerUnitOfMeasure(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; QtyBase: Decimal; QtyPerUOM: Decimal; var QtyRounded: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyFromBasePerUnitOfMeasure(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; QtyBase: Decimal; QtyPerUOM: Decimal; var QtyRounded: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetQtyPerUnitOfMeasure(Item: Record Item; UnitOfMeasureCode: Code[10]; var QtyPerUnitOfMeasure: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetResQtyPerUnitOfMeasure(Resource: Record Resource; ResUnitOfMeasureCode: Code[10]; var QtyPerUnitOfMeasure: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCubageRndPrecision(var RoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeQtyRndPrecision(var RoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTimeRndPrecision(var RoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWeightRndPrecision(var RoundingPrecision: Decimal)
    begin
    end;
}

