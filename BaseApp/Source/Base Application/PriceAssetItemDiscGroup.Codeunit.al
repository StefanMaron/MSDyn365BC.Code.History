codeunit 7042 "Price Asset - Item Disc. Group" implements "Price Asset"
{
    var
        ItemDiscountGroup: Record "Item Discount Group";
        UnitofMeasure: Record "Unit of Measure";

    procedure GetNo(var PriceAsset: Record "Price Asset")
    begin
        if ItemDiscountGroup.GetBySystemId(PriceAsset."Asset ID") then begin
            PriceAsset."Unit of Measure Code" := '';
            PriceAsset."Asset No." := ItemDiscountGroup.Code;
        end else
            PriceAsset.InitAsset();
    end;

    procedure GetId(var PriceAsset: Record "Price Asset")
    begin
        if ItemDiscountGroup.Get(PriceAsset."Asset No.") then begin
            PriceAsset."Unit of Measure Code" := '';
            PriceAsset."Asset ID" := ItemDiscountGroup.SystemId;
        end else
            PriceAsset.InitAsset();
    end;

    procedure IsLookupOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        if ItemDiscountGroup.Get(PriceAsset."Asset No.") then;
        if Page.RunModal(Page::"Item Disc. Groups", ItemDiscountGroup) = ACTION::LookupOK then begin
            PriceAsset.Validate("Asset No.", ItemDiscountGroup.Code);
            exit(true)
        end;
    end;

    procedure ValidateUnitOfMeasure(var PriceAsset: Record "Price Asset"): Boolean
    begin
        UnitofMeasure.Get(PriceAsset."Unit of Measure Code");
    end;

    procedure IsLookupUnitOfMeasureOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        if UnitofMeasure.Get(PriceAsset."Unit of Measure Code") then;
        if Page.RunModal(Page::"Units of Measure", UnitofMeasure) = ACTION::LookupOK then begin
            PriceAsset.Validate("Unit of Measure Code", UnitofMeasure.Code);
            exit(true);
        end;
    end;

    procedure IsLookupVariantOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        exit(false)
    end;

    procedure IsAssetNoRequired(): Boolean;
    begin
        exit(true)
    end;

    procedure FillBestLine(PriceCalculationBuffer: Record "Price Calculation Buffer"; AmountType: Enum "Price Amount Type"; var PriceListLine: Record "Price List Line")
    begin
    end;

    procedure FilterPriceLines(PriceAsset: Record "Price Asset"; var PriceListLine: Record "Price List Line") Result: Boolean;
    begin
        PriceListLine.SetRange("Asset Type", PriceAsset."Asset Type");
        PriceListLine.SetRange("Asset No.", PriceAsset."Asset No.");
        PriceListLine.SetRange("Variant Code");
    end;

    procedure PutRelatedAssetsToList(PriceAsset: Record "Price Asset"; var PriceAssetList: Codeunit "Price Asset List")
    begin
    end;

    procedure FillFromBuffer(var PriceAsset: Record "Price Asset"; PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
        PriceAsset.NewEntry(PriceCalculationBuffer."Asset Type", PriceAsset.Level);
        PriceAsset.Validate("Asset No.", PriceCalculationBuffer."Asset No.");
        PriceAsset."Unit of Measure Code" := PriceCalculationBuffer."Unit of Measure Code";
    end;
}