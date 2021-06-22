codeunit 7043 "Price Asset - Resource" implements "Price Asset"
{
    var
        Resource: Record Resource;
        ResourceUnitofMeasure: Record "Resource Unit of Measure";

    procedure GetNo(var PriceAsset: Record "Price Asset")
    begin
        if Resource.GetBySystemId(PriceAsset."Asset ID") then begin
            PriceAsset."Unit of Measure Code" := Resource."Base Unit of Measure";
            PriceAsset."Asset No." := Resource."No.";
        end else
            PriceAsset.InitAsset();
    end;

    procedure GetId(var PriceAsset: Record "Price Asset")
    begin
        if Resource.Get(PriceAsset."Asset No.") then begin
            PriceAsset."Unit of Measure Code" := Resource."Base Unit of Measure";
            PriceAsset."Asset ID" := Resource.SystemId;
        end else
            PriceAsset.InitAsset();
    end;

    procedure IsLookupOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        if Resource.Get(PriceAsset."Asset No.") then;
        if Page.RunModal(Page::"Resource List", Resource) = ACTION::LookupOK then begin
            PriceAsset.Validate("Asset No.", Resource."No.");
            exit(true);
        end;
    end;

    procedure ValidateUnitOfMeasure(var PriceAsset: Record "Price Asset"): Boolean
    begin
        ResourceUnitofMeasure.Get(PriceAsset."Asset No.", PriceAsset."Unit of Measure Code");
    end;

    procedure IsLookupUnitOfMeasureOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        if ResourceUnitofMeasure.Get(PriceAsset."Asset No.", PriceAsset."Unit of Measure Code") then;
        if Page.RunModal(Page::"Resource Units of Measure", ResourceUnitofMeasure) = ACTION::LookupOK then begin
            PriceAsset.Validate("Unit of Measure Code", ResourceUnitofMeasure.Code);
            exit(true);
        end;
    end;

    procedure IsLookupVariantOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        exit(false)
    end;

    procedure IsAssetNoRequired(): Boolean;
    begin
        exit(false)
    end;

    procedure FillBestLine(PriceCalculationBuffer: Record "Price Calculation Buffer"; AmountType: Enum "Price Amount Type"; var PriceListLine: Record "Price List Line")
    begin
        Resource.Get(PriceCalculationBuffer."Asset No.");
        PriceListLine."Currency Code" := '';
        case AmountType of
            AmountType::Price:
                PriceListLine."Unit Price" := Resource."Unit Price";
            AmountType::Cost:
                PriceListLine."Unit Cost" := Resource."Direct Unit Cost";
        end;
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
        if PriceAsset."Asset No." = '' then
            exit;

        Resource.Get(PriceAsset."Asset No.");
        if Resource."Resource Group No." <> '' then begin
            PriceAssetList.SetLevel(PriceAsset.Level + 1);
            PriceAssetList.Add(PriceAsset."Asset Type"::"Resource Group", Resource."Resource Group No.");
        end else begin
            PriceAssetList.SetLevel(PriceAsset.Level + 1);
            PriceAssetList.Add(PriceAsset."Asset Type"::Resource); // All Resources
        end;
    end;

    procedure FillFromBuffer(var PriceAsset: Record "Price Asset"; PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
        PriceAsset.NewEntry(PriceCalculationBuffer."Asset Type", PriceAsset.Level);
        PriceAsset.Validate("Asset No.", PriceCalculationBuffer."Asset No.");
        PriceAsset."Unit of Measure Code" := PriceCalculationBuffer."Unit of Measure Code";
    end;
}