codeunit 7008 "Price Calculation Buffer Mgt."
{
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        PriceListLineFiltered: Record "Price List Line";
        PriceAssetList: Codeunit "Price Asset List";
        PriceSourceList: Codeunit "Price Source List";
        UnitAmountRoundingPrecision: Decimal;
        PricesInclVATErr: Label 'Prices including VAT cannot be calculated because the VAT Calculation Type field contains %1.',
            Comment = '%1 - VAT Calculation Type field value';

    procedure AddAsset(AssetType: Enum "Price Asset Type"; AssetNo: Code[20])
    begin
        PriceAssetList.Add(AssetType, AssetNo);
    end;

    procedure AddSource(SourceType: Enum "Price Source Type"; ParentSourceNo: Code[20]; SourceNo: Code[20])
    begin
        PriceSourceList.Add(SourceType, ParentSourceNo, SourceNo);
    end;

    procedure AddSource(SourceType: Enum "Price Source Type"; SourceNo: Code[20])
    begin
        PriceSourceList.Add(SourceType, SourceNo);
    end;

    procedure AddSource(SourceType: Enum "Price Source Type")
    begin
        PriceSourceList.Add(SourceType);
    end;

    procedure GetAsset(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset.Init();
        PriceAsset.Validate("Asset Type", PriceCalculationBuffer."Asset Type");
        PriceAsset.Validate("Asset No.", PriceCalculationBuffer."Asset No.");
        PriceAsset."Unit of Measure Code" := PriceCalculationBuffer."Unit of Measure Code";
        PriceAsset."Variant Code" := PriceCalculationBuffer."Variant Code";
    end;

    procedure GetAssets(var NewPriceAssetList: Codeunit "Price Asset List")
    begin
        NewPriceAssetList.Copy(PriceAssetList);
    end;

    procedure GetBuffer(var ResultPriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
        ResultPriceCalculationBuffer := PriceCalculationBuffer;
    end;

    procedure GetSource(SourceType: Enum "Price Source Type") SourceNo: Code[20];
    begin
        SourceNo := PriceSourceList.GetValue(SourceType);
    end;

    procedure GetSources(var TempPriceSource: Record "Price Source" temporary): Boolean;
    begin
        exit(PriceSourceList.GetList(TempPriceSource));
    end;

    procedure GetSources(var NewPriceSourceList: Codeunit "Price Source List")
    begin
        NewPriceSourceList.Copy(PriceSourceList);
    end;

    procedure SetAssets(var NewPriceAssetList: Codeunit "Price Asset List")
    begin
        PriceAssetList.Copy(NewPriceAssetList);
    end;

    procedure SetSources(var NewPriceSourceList: Codeunit "Price Source List")
    begin
        PriceSourceList.Copy(NewPriceSourceList);
    end;

    procedure Set(NewPriceCalculationBuffer: Record "Price Calculation Buffer"; var PriceSourceList: Codeunit "Price Source List")
    begin
        PriceCalculationBuffer := NewPriceCalculationBuffer;
        CalcUnitAmountRoundingPrecision();

        PriceAssetList.Init();
        PriceAssetList.Add(PriceCalculationBuffer);

        SetSources(PriceSourceList);
    end;

    local procedure CalcUnitAmountRoundingPrecision()
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if PriceCalculationBuffer."Currency Code" <> '' then begin
            Currency.Get(PriceCalculationBuffer."Currency Code");
            Currency.TestField("Unit-Amount Rounding Precision");
            UnitAmountRoundingPrecision := Currency."Unit-Amount Rounding Precision";
        end else begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetup.TestField("Unit-Amount Rounding Precision");
            UnitAmountRoundingPrecision := GeneralLedgerSetup."Unit-Amount Rounding Precision";
        end;
    end;

    local procedure RoundPrice(var Price: Decimal)
    begin
        Price := Round(Price, UnitAmountRoundingPrecision);
    end;

    procedure IsInMinQty(PriceListLine: Record "Price List Line"): Boolean
    begin
        if PriceListLine."Unit of Measure Code" = '' then
            exit(PriceListLine."Minimum Quantity" <= PriceCalculationBuffer."Qty. per Unit of Measure" * PriceCalculationBuffer.Quantity);
        exit(PriceListLine."Minimum Quantity" <= PriceCalculationBuffer.Quantity);
    end;

    procedure ConvertAmount(AmountType: Enum "Price Amount Type"; var PriceListLine: Record "Price List Line")
    begin
        case AmountType of
            AmountType::Price:
                ConvertAmount(PriceListLine, PriceListLine."Unit Price");
            AmountType::Cost:
                ConvertAmount(PriceListLine, PriceListLine."Unit Cost");
        end;
    end;

    local procedure ConvertAmount(var PriceListLine: Record "Price List Line"; var Amount: Decimal)
    var
        CurrExchRate: Record "Currency Exchange Rate";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if PriceListLine."Price Includes VAT" then begin
            VATPostingSetup.Get(PriceListLine."VAT Bus. Posting Gr. (Price)", PriceCalculationBuffer."VAT Prod. Posting Group");
            if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Sales Tax" then
                Error(PricesInclVATErr, VATPostingSetup."VAT Calculation Type");

            case PriceCalculationBuffer."VAT Calculation Type" of
                VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                VATPostingSetup."VAT Calculation Type"::"Full VAT":
                    if PriceCalculationBuffer."Prices Including Tax" then begin
                        if PriceCalculationBuffer."VAT Bus. Posting Group" <> PriceListLine."VAT Bus. Posting Gr. (Price)" then // ? to test
                            Amount := Amount * (100 + PriceCalculationBuffer."Tax %") / (100 + VATPostingSetup."VAT %");
                    end else
                        Amount := Amount / (1 + VATPostingSetup."VAT %" / 100);
            end;
        end else
            if PriceCalculationBuffer."Prices Including Tax" then
                Amount := Amount * (1 + PriceCalculationBuffer."Tax %" / 100);

        if PriceListLine."Unit of Measure Code" = '' then
            Amount := Amount * PriceCalculationBuffer."Qty. per Unit of Measure";

        if (PriceCalculationBuffer."Currency Code" <> '') and (PriceListLine."Currency Code" = '') then
            Amount :=
                CurrExchRate.ExchangeAmtLCYToFCY(
                    PriceCalculationBuffer."Document Date", PriceCalculationBuffer."Currency Code", Amount, PriceCalculationBuffer."Currency Factor");
        RoundPrice(Amount);
        // Set "Line Discount %" for PickBestLine
        if PriceCalculationBuffer."Allow Line Disc." then
            PriceListLine."Line Discount %" := PriceCalculationBuffer."Line Discount %"
        else
            PriceListLine."Line Discount %" := 0;
    end;

    procedure FillBestLine(AmountType: Enum "Price Amount Type"; var PriceListLine: Record "Price List Line")
    var
        PriceAssetInterface: Interface "Price Asset";
    begin
        Clear(PriceListLine);
        PriceAssetInterface := PriceCalculationBuffer."Asset Type";
        PriceAssetInterface.FillBestLine(PriceCalculationBuffer, AmountType, PriceListLine);
        ConvertAmount(AmountType, PriceListLine);
        PriceListLine."Allow Line Disc." := PriceCalculationBuffer."Allow Line Disc.";
        PriceListLine."Allow Invoice Disc." := PriceCalculationBuffer."Allow Invoice Disc.";
    end;

    procedure SetFiltersOnPriceListLine(var PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; ShowAll: Boolean)
    begin
        PriceListLine.SetFilter("Amount Type", '%1|%2', AmountType, PriceListLine."Amount Type"::Any);
        if PriceCalculationBuffer."Work Type Code" <> '' then
            PriceListLine.SetRange("Work Type Code", PriceCalculationBuffer."Work Type Code");

        PriceListLine.SetFilter("Ending Date", '%1|>=%2', 0D, PriceCalculationBuffer."Document Date");
        if not ShowAll then begin
            PriceListLine.SetFilter("Currency Code", '%1|%2', PriceCalculationBuffer."Currency Code", '');
            if PriceCalculationBuffer."Unit of Measure Code" <> '' then
                PriceListLine.SetFilter("Unit of Measure Code", '%1|%2', PriceCalculationBuffer."Unit of Measure Code", '');
            PriceListLine.SetRange("Starting Date", 0D, PriceCalculationBuffer."Document Date");
        end;
        OnAfterSetFilters(PriceListLine, AmountType, PriceCalculationBuffer, ShowAll);
        PriceListLineFiltered.CopyFilters(PriceListLine);
    end;

    procedure RestoreFilters(var PriceListLine: Record "Price List Line")
    begin
        PriceListLine.Reset();
        PriceListLine.CopyFilters(PriceListLineFiltered);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; var PriceCalculationBuffer: Record "Price Calculation Buffer"; ShowAll: Boolean)
    begin
    end;
}