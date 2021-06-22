codeunit 7041 "Price Asset - Item" implements "Price Asset"
{
    var
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";

    procedure GetNo(var PriceAsset: Record "Price Asset")
    begin
        if Item.GetBySystemId(PriceAsset."Asset ID") then begin
            PriceAsset."Unit of Measure Code" := Item."Base Unit of Measure";
            PriceAsset."Asset No." := Item."No.";
        end else
            PriceAsset.InitAsset();
    end;

    procedure GetId(var PriceAsset: Record "Price Asset")
    begin
        if Item.Get(PriceAsset."Asset No.") then begin
            PriceAsset."Unit of Measure Code" := Item."Base Unit of Measure";
            PriceAsset."Asset ID" := Item.SystemId;
        end else
            PriceAsset.InitAsset();
    end;

    procedure IsLookupOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        if Item.Get(PriceAsset."Asset No.") then;
        if Page.RunModal(Page::"Item List", Item) = ACTION::LookupOK then begin
            PriceAsset.Validate("Asset No.", Item."No.");
            exit(true);
        end;
    end;

    procedure ValidateUnitOfMeasure(var PriceAsset: Record "Price Asset"): Boolean
    begin
        ItemUnitofMeasure.Get(PriceAsset."Asset No.", PriceAsset."Unit of Measure Code");
    end;

    procedure IsLookupUnitOfMeasureOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        if ItemUnitofMeasure.Get(PriceAsset."Asset No.", PriceAsset."Unit of Measure Code") then;
        if Page.RunModal(Page::"Item Units of Measure", ItemUnitofMeasure) = ACTION::LookupOK then begin
            PriceAsset.Validate("Unit of Measure Code", ItemUnitofMeasure.Code);
            exit(true);
        end;
    end;

    procedure IsLookupVariantOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        if ItemVariant.Get(PriceAsset."Variant Code", PriceAsset."Asset No.") then;
        if Page.RunModal(Page::"Item Variants", ItemVariant) = ACTION::LookupOK then begin
            PriceAsset.Validate("Variant Code", ItemVariant.Code);
            exit(true);
        end;
    end;

    procedure IsAssetNoRequired(): Boolean;
    begin
        exit(true)
    end;

    procedure FillBestLine(PriceCalculationBuffer: Record "Price Calculation Buffer"; AmountType: Enum "Price Amount Type"; var PriceListLine: Record "Price List Line")
    begin
        Item.Get(PriceCalculationBuffer."Asset No.");
        PriceListLine."VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
        PriceListLine."Unit of Measure Code" := '';
        PriceListLine."Currency Code" := '';
        case AmountType of
            AmountType::Price:
                begin
                    PriceListLine."VAT Bus. Posting Gr. (Price)" := Item."VAT Bus. Posting Gr. (Price)";
                    PriceListLine."Price Includes VAT" := Item."Price Includes VAT";
                    PriceListLine."Unit Price" := Item."Unit Price";
                end;
            AmountType::Cost:
                begin
                    PriceListLine."Price Includes VAT" := false;
                    CopyCostFromSKU(PriceCalculationBuffer, Item."Last Direct Cost");
                    PriceListLine."Unit Cost" := Item."Last Direct Cost";
                end;
        end;
    end;

    local procedure CopyCostFromSKU(PriceCalculationBuffer: Record "Price Calculation Buffer"; var UnitCost: Decimal)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        if StockkeepingUnit.Get(PriceCalculationBuffer."Location Code", PriceCalculationBuffer."Asset No.", PriceCalculationBuffer."Variant Code") then
            if StockkeepingUnit."Last Direct Cost" <> 0 then
                UnitCost := StockkeepingUnit."Last Direct Cost";
    end;

    procedure FilterPriceLines(PriceAsset: Record "Price Asset"; var PriceListLine: Record "Price List Line") Result: Boolean;
    begin
        PriceListLine.SetRange("Asset Type", PriceAsset."Asset Type");
        PriceListLine.SetRange("Asset No.", PriceAsset."Asset No.");
        PriceListLine.SetFilter("Variant Code", '%1|%2', PriceAsset."Variant Code", '');
    end;

    procedure PutRelatedAssetsToList(PriceAsset: Record "Price Asset"; var PriceAssetList: Codeunit "Price Asset List")
    begin
        Item.Get(PriceAsset."Asset No.");
        if Item."Item Disc. Group" <> '' then begin
            PriceAssetList.SetLevel(PriceAsset.Level);
            PriceAssetList.Add(PriceAsset."Asset Type"::"Item Discount Group", Item."Item Disc. Group");
        end;
    end;

    procedure FillFromBuffer(var PriceAsset: Record "Price Asset"; PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
        PriceAsset.NewEntry(PriceCalculationBuffer."Asset Type", PriceAsset.Level);
        PriceAsset.Validate("Asset No.", PriceCalculationBuffer."Asset No.");
        PriceAsset."Variant Code" := PriceCalculationBuffer."Variant Code";
        PriceAsset."Unit of Measure Code" := PriceCalculationBuffer."Unit of Measure Code";
    end;
}