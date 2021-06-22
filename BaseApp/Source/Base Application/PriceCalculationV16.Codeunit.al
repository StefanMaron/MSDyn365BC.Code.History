codeunit 7002 "Price Calculation - V16" implements "Price Calculation"
{
    trigger OnRun()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        PriceCalculationSetup.SetRange(Implementation, PriceCalculationSetup.Implementation::"Business Central (Version 16.0)");
        PriceCalculationSetup.DeleteAll();
        AddSupportedSetup(PriceCalculationSetup);
        PriceCalculationSetup.ModifyAll(Default, true);
    end;

    var
        CurrPriceCalculationSetup: Record "Price Calculation Setup";
        CurrLineWithPrice: Interface "Line With Price";
        TempTableErr: Label 'The table passed as a parameter must be temporary.';

    procedure GetLine(var Line: Variant)
    begin
        CurrLineWithPrice.GetLine(Line);
    end;

    procedure Init(NewLineWithPrice: Interface "Line With Price"; PriceCalculationSetup: Record "Price Calculation Setup")
    begin
        CurrLineWithPrice := NewLineWithPrice;
        CurrPriceCalculationSetup := PriceCalculationSetup;
    end;

    procedure ApplyDiscount()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        AmountType: Enum "Price Amount Type";
        FoundPrice: Boolean;
    begin
        if not CurrLineWithPrice.IsDiscountAllowed() then
            exit;
        CurrLineWithPrice.Verify();
        if not CurrLineWithPrice.CopyToBuffer(PriceCalculationBufferMgt) then
            exit;
        if FindLines(AmountType::Discount, TempPriceListLine, PriceCalculationBufferMgt, false) then
            FoundPrice := CalcBestAmount(AmountType::Discount, PriceCalculationBufferMgt, TempPriceListLine);
        if not FoundPrice then
            PriceCalculationBufferMgt.FillBestLine(AmountType::Discount, TempPriceListLine);
        CurrLineWithPrice.SetPrice(AmountType::Discount, TempPriceListLine);
    end;

    procedure ApplyPrice(CalledByFieldNo: Integer)
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        AmountType: Enum "Price Amount Type";
        FoundPrice: Boolean;
    begin
        CurrLineWithPrice.Verify();
        if not CurrLineWithPrice.CopyToBuffer(PriceCalculationBufferMgt) then
            exit;
        AmountType := AmountTypeFromPriceType(CurrPriceCalculationSetup.Type);
        if FindLines(AmountType, TempPriceListLine, PriceCalculationBufferMgt, false) then
            FoundPrice := CalcBestAmount(AmountType, PriceCalculationBufferMgt, TempPriceListLine);
        if not FoundPrice then
            PriceCalculationBufferMgt.FillBestLine(AmountType, TempPriceListLine);
        if CurrLineWithPrice.IsPriceUpdateNeeded(AmountType, FoundPrice, CalledByFieldNo) then
            CurrLineWithPrice.SetPrice(AmountType, TempPriceListLine);
        CurrLineWithPrice.Update(AmountType);
    end;

    procedure CountDiscount(ShowAll: Boolean) Result: Integer;
    begin

    end;

    procedure CountPrice(ShowAll: Boolean) Result: Integer;
    begin

    end;

    procedure FindDiscount(var TempPriceListLine: Record "Price List Line"; ShowAll: Boolean) Found: Boolean;
    var
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        AmountType: Enum "Price Amount Type";
    begin
        Found := FindLines(AmountType::Discount, TempPriceListLine, PriceCalculationBufferMgt, ShowAll);
    end;

    procedure FindPrice(var TempPriceListLine: Record "Price List Line"; ShowAll: Boolean) Found: Boolean;
    var
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        AmountType: Enum "Price Amount Type";
    begin
        AmountType := AmountTypeFromPriceType(CurrPriceCalculationSetup.Type);
        Found := FindLines(AmountType, TempPriceListLine, PriceCalculationBufferMgt, ShowAll);
    end;

    procedure IsDiscountExists(ShowAll: Boolean) Result: Boolean;
    begin

    end;

    procedure IsPriceExists(ShowAll: Boolean) Result: Boolean;
    begin

    end;

    procedure PickDiscount()
    var
        AmountType: enum "Price Amount Type";
    begin
        Pick(AmountType::Discount);
    end;

    procedure PickPrice()
    var
        AmountType: enum "Price Amount Type";
    begin
        AmountType := AmountTypeFromPriceType(CurrPriceCalculationSetup.Type);
        Pick(AmountType);
    end;

    local procedure Pick(AmountType: enum "Price Amount Type")
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
    begin
        CurrLineWithPrice.Verify();
        if not CurrLineWithPrice.CopyToBuffer(PriceCalculationBufferMgt) then
            exit;
        if FindLines(AmountType, TempPriceListLine, PriceCalculationBufferMgt, false) then
            if PAGE.RunModal(PAGE::"Get Price Line", TempPriceListLine) = ACTION::LookupOK then begin
                CurrLineWithPrice.SetPrice(AmountType, TempPriceListLine);
                CurrLineWithPrice.ValidatePrice(AmountType);
            end;
    end;

    procedure ShowPrices(var TempPriceListLine: Record "Price List Line")
    begin
    end;

    local procedure AddSupportedSetup(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    begin
        TempPriceCalculationSetup.Init();
        TempPriceCalculationSetup.Validate(Implementation, TempPriceCalculationSetup.Implementation::"Business Central (Version 16.0)");
        TempPriceCalculationSetup.Method := TempPriceCalculationSetup.Method::"Lowest Price";
        TempPriceCalculationSetup.Enabled := not IsDisabled();
        TempPriceCalculationSetup.Type := TempPriceCalculationSetup.Type::Purchase;
        TempPriceCalculationSetup.Insert(true);
        TempPriceCalculationSetup.Type := TempPriceCalculationSetup.Type::Sale;
        TempPriceCalculationSetup.Insert(true);
    end;

    local procedure IsDisabled() Result: Boolean;
    begin
        OnIsDisabled(Result);
    end;

    local procedure PickBestLine(AmountType: Enum "Price Amount Type"; PriceListLine: Record "Price List Line"; var BestPriceListLine: Record "Price List Line"; var FoundBestLine: Boolean)
    begin
        if IsImprovedLine(PriceListLine, BestPriceListLine) or not IsDegradedLine(PriceListLine, BestPriceListLine) then begin
            if IsImprovedLine(PriceListLine, BestPriceListLine) and not IsDegradedLine(PriceListLine, BestPriceListLine) then
                Clear(BestPriceListLine);
            if IsBetterLine(PriceListLine, AmountType, BestPriceListLine) then begin
                BestPriceListLine := PriceListLine;
                FoundBestLine := true;
            end;
        end;
        OnAfterPickBestLine(AmountType, PriceListLine, BestPriceListLine, FoundBestLine);
    end;

    local procedure IsDegradedLine(PriceListLine: Record "Price List Line"; BestPriceListLine: Record "Price List Line") Result: Boolean
    begin
        Result :=
            IsBlankedValue(PriceListLine."Currency Code", BestPriceListLine."Currency Code") or
            IsBlankedValue(PriceListLine."Variant Code", BestPriceListLine."Variant Code");
    end;

    local procedure IsBlankedValue(LineValue: Text; BestLineValue: Text): Boolean
    begin
        exit((BestLineValue <> '') and (LineValue = ''));
    end;

    local procedure IsImprovedLine(PriceListLine: Record "Price List Line"; BestPriceListLine: Record "Price List Line") Result: Boolean
    begin
        Result :=
            IsSetValue(PriceListLine."Currency Code", BestPriceListLine."Currency Code") or
            IsSetValue(PriceListLine."Variant Code", BestPriceListLine."Variant Code");
    end;

    local procedure IsSetValue(LineValue: Text; BestLineValue: Text): Boolean
    begin
        exit((BestLineValue = '') and (LineValue <> ''));
    end;

    procedure IsBetterLine(var PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; BestPriceListLine: Record "Price List Line") Result: Boolean;
    begin
        case AmountType of
            AmountType::Price:
                Result := IsBetterPrice(PriceListLine, PriceListLine."Unit Price", BestPriceListLine);
            AmountType::Cost:
                Result := IsBetterPrice(PriceListLine, PriceListLine."Unit Cost", BestPriceListLine);
            AmountType::Discount:
                Result := PriceListLine."Line Discount %" > BestPriceListLine."Line Discount %";
        end;
        OnAfterIsBetterLine(PriceListLine, AmountType, BestPriceListLine, Result);
    end;

    local procedure IsBetterPrice(var PriceListLine: Record "Price List Line"; Price: Decimal; BestPriceListLine: Record "Price List Line"): Boolean;
    begin
        PriceListLine."Line Amount" := Price * (1 - PriceListLine."Line Discount %" / 100);
        if not BestPriceListLine.IsRealLine() then
            exit(true);
        exit(PriceListLine."Line Amount" < BestPriceListLine."Line Amount");
    end;

    procedure AmountTypeFromPriceType(PriceType: enum "Price Type") AmountType: Enum "Price Amount Type";
    begin
        case PriceType of
            PriceType::Sale:
                AmountType := AmountType::Price;
            PriceType::Purchase:
                AmountType := AmountType::Cost;
        end;
    end;

    procedure FindLines(
        AmountType: Enum "Price Amount Type";
        var TempPriceListLine: Record "Price List Line" temporary;
        var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        ShowAll: Boolean) FoundLines: Boolean;
    var
        PriceListLine: Record "Price List Line";
        PriceSource: Record "Price Source";
        PriceAssetList: Codeunit "Price Asset List";
        PriceSourceList: Codeunit "Price Source List";
        Level: array[2] of Integer;
        CurrLevel: Integer;
    begin
        if not TempPriceListLine.IsTemporary() then
            Error(TempTableErr);

        TempPriceListLine.Reset();
        TempPriceListLine.DeleteAll();

        PriceCalculationBufferMgt.SetFiltersOnPriceListLine(PriceListLine, AmountType, ShowAll);
        PriceCalculationBufferMgt.GetAssets(PriceAssetList);
        PriceCalculationBufferMgt.GetSources(PriceSourceList);
        PriceSourceList.GetMinMaxLevel(Level);
        for CurrLevel := Level[2] downto Level[1] do
            if not FoundLines then
                if PriceSourceList.First(PriceSource, CurrLevel) then
                    repeat
                        if PriceSource.IsForAmountType(AmountType) then begin
                            FoundLines :=
                                FoundLines or CopyLinesBySource(PriceListLine, PriceSource, PriceAssetList, TempPriceListLine);
                            PriceCalculationBufferMgt.RestoreFilters(PriceListLine);
                        end;
                    until not PriceSourceList.Next(PriceSource);

        exit(not TempPriceListLine.IsEmpty());
    end;

    procedure CopyLinesBySource(
        var PriceListLine: Record "Price List Line";
        PriceSource: Record "Price Source";
        var PriceAssetList: Codeunit "Price Asset List";
        var TempPriceListLine: Record "Price List Line" temporary) FoundLines: Boolean;
    var
        PriceAsset: Record "Price Asset";
        Level: array[2] of Integer;
        CurrLevel: Integer;
    begin
        PriceAssetList.GetMinMaxLevel(Level);
        for CurrLevel := Level[2] downto Level[1] do
            if not FoundLines then
                if PriceAssetList.First(PriceAsset, CurrLevel) then
                    repeat
                        FoundLines :=
                            FoundLines or CopyLinesBySource(PriceListLine, PriceSource, PriceAsset, TempPriceListLine);
                    until not PriceAssetList.Next(PriceAsset);
    end;

    procedure CopyLinesBySource(
        var PriceListLine: Record "Price List Line";
        PriceSource: Record "Price Source";
        PriceAsset: Record "Price Asset";
        var TempPriceListLine: Record "Price List Line" temporary): Boolean;
    begin
        PriceSource.FilterPriceLines(PriceListLine);
        PriceAsset.FilterPriceLines(PriceListLine);
        exit(PriceListLine.CopyFilteredLinesToTemporaryBuffer(TempPriceListLine));
    end;

    procedure CalcBestAmount(AmountType: Enum "Price Amount Type"; var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt."; var PriceListLine: Record "Price List Line") FoundBestPrice: Boolean;
    var
        BestPriceListLine: Record "Price List Line";
    begin
        if PriceListLine.FindSet() then
            repeat
                if PriceCalculationBufferMgt.IsInMinQty(PriceListLine) then begin
                    PriceCalculationBufferMgt.ConvertAmount(AmountType, PriceListLine);
                    PickBestLine(AmountType, PriceListLine, BestPriceListLine, FoundBestPrice);
                end;
            until PriceListLine.Next() = 0;
        if FoundBestPrice then
            PriceListLine := BestPriceListLine;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation Mgt.", 'OnFindSupportedSetup', '', false, false)]
    local procedure OnFindImplementationHandler(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    begin
        AddSupportedSetup(TempPriceCalculationSetup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnCompanyInitializeHandler()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        // New company gets "Best Price" calculation by default.
        /*
        AddSupportedSetup(TempPriceCalculationSetup);
        PriceCalculationSetup.DeleteAll();
        if TempPriceCalculationSetup.FindSet() then
            repeat
                PriceCalculationSetup := TempPriceCalculationSetup;
                PriceCalculationSetup.Default := true;
                PriceCalculationSetup.Insert();
            until TempPriceCalculationSetup.Next() = 0;
        */
        PriceCalculationMgt.Run();
    end;


    [IntegrationEvent(true, false)]
    local procedure OnAfterIsBetterLine(PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; BestPriceListLine: Record "Price List Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPickBestLine(AmountType: Enum "Price Amount Type"; PriceListLine: Record "Price List Line"; var BestPriceListLine: Record "Price List Line"; var FoundBestLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsDisabled(var Disabled: Boolean)
    begin
    end;
}