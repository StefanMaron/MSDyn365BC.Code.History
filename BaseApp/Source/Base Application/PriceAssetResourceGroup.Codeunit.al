codeunit 7044 "Price Asset - Resource Group" implements "Price Asset"
{
    var
        ResourceGroup: Record "Resource Group";
        UnitofMeasure: Record "Unit of Measure";

    procedure GetNo(var PriceAsset: Record "Price Asset")
    begin
        if ResourceGroup.GetBySystemId(PriceAsset."Asset ID") then begin
            PriceAsset."Unit of Measure Code" := '';
            PriceAsset."Asset No." := ResourceGroup."No.";
        end else
            PriceAsset.InitAsset();
    end;

    procedure GetId(var PriceAsset: Record "Price Asset")
    begin
        if ResourceGroup.Get(PriceAsset."Asset No.") then begin
            PriceAsset."Unit of Measure Code" := '';
            PriceAsset."Asset ID" := ResourceGroup.SystemId;
        end else
            PriceAsset.InitAsset();
    end;

    procedure IsLookupOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        if ResourceGroup.Get(PriceAsset."Asset No.") then;
        if Page.RunModal(Page::"Resource Groups", ResourceGroup) = ACTION::LookupOK then begin
            PriceAsset.Validate("Asset No.", ResourceGroup."No.");
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
        if not PriceListLine.IsEmpty() then
            exit(true);
        PriceListLine.SetRange("Work Type Code");
    end;

    procedure PutRelatedAssetsToList(PriceAsset: Record "Price Asset"; var PriceAssetList: Codeunit "Price Asset List")
    begin
        PriceAssetList.SetLevel(PriceAsset.Level + 1);
        PriceAssetList.Add(PriceAsset."Asset Type"::Resource); // All Resources
    end;

    procedure FillFromBuffer(var PriceAsset: Record "Price Asset"; PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
        PriceAsset.NewEntry(PriceCalculationBuffer."Asset Type", PriceAsset.Level);
        PriceAsset.Validate("Asset No.", PriceCalculationBuffer."Asset No.");
        PriceAsset."Unit of Measure Code" := PriceCalculationBuffer."Unit of Measure Code";
    end;
}