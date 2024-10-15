codeunit 7001 "Price Calculation Mgt."
{
    trigger OnRun()
    begin
        RefreshSetup();
    end;

    var
        ExtendedPriceFeatureIdTok: Label 'SalesPrices', Locked = true;
        NotImplementedMethodErr: Label 'Method %1 does not have active implementations for %2 price type.', Comment = '%1 - method name, %2 - price type name';
        FeatureIsOffErr: Label 'Extended price calculation feature is not enabled.';

    procedure RefreshSetup() Updated: Boolean;
    var
        TempPriceCalculationSetup: Record "Price Calculation Setup" temporary;
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        if not IsExtendedPriceCalculationEnabled() then
            exit(false);

        OnFindSupportedSetup(TempPriceCalculationSetup);
        if PriceCalculationSetup.FindSet() then
            repeat
                if TempPriceCalculationSetup.Get(PriceCalculationSetup.Code) then
                    TempPriceCalculationSetup.Delete()
                else begin
                    PriceCalculationSetup.Delete();
                    Updated := true;
                end;
            until PriceCalculationSetup.Next() = 0;
        if PriceCalculationSetup.MoveFrom(TempPriceCalculationSetup) then
            Updated := true;
    end;

    procedure GetHandler(LineWithPrice: Interface "Line With Price"; var PriceCalculation: Interface "Price Calculation") Result: Boolean;
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        Result := FindSetup(LineWithPrice, PriceCalculationSetup);
        PriceCalculation := PriceCalculationSetup.Implementation;
        PriceCalculation.Init(LineWithPrice, PriceCalculationSetup);
    end;

    procedure VerifyMethodImplemented(Method: Enum "Price Calculation Method"; PriceType: Enum "Price Type")
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        if PriceType = PriceType::Any then
            PriceCalculationSetup.SetFilter(Type, '>%1', PriceType)
        else
            PriceCalculationSetup.SetRange(Type, PriceType);
        PriceCalculationSetup.SetRange(Method, Method);
        PriceCalculationSetup.SetRange(Enabled, true);
        if PriceCalculationSetup.IsEmpty() then
            Error(NotImplementedMethodErr, Method, PriceType);
    end;

    procedure FindSetup(LineWithPrice: Interface "Line With Price"; var PriceCalculationSetup: Record "Price Calculation Setup"): Boolean;
    var
        DtldPriceCalcSetup: Record "Dtld. Price Calculation Setup";
        PriceCalculationDtldSetup: Codeunit "Price Calculation Dtld. Setup";
    begin
        if not IsExtendedPriceCalculationEnabled() then begin
            PriceCalculationSetup.Method := PriceCalculationSetup.Method::"Lowest Price";
            PriceCalculationSetup.Implementation := PriceCalculationSetup.Implementation::"Business Central (Version 15.0)";
            exit(true);
        end;

        if not LineWithPrice.SetAssetSourceForSetup(DtldPriceCalcSetup) then
            exit(false);

        if DtldPriceCalcSetup.Method = DtldPriceCalcSetup.Method::" " then
            DtldPriceCalcSetup.Method := DtldPriceCalcSetup.Method::"Lowest Price";

        if PriceCalculationDtldSetup.FindSetup(DtldPriceCalcSetup) then
            if PriceCalculationSetup.Get(DtldPriceCalcSetup."Setup Code") then
                exit(true);

        PriceCalculationSetup.Reset();
        PriceCalculationSetup.SetRange(Enabled, true);
        PriceCalculationSetup.SetRange(Default, true);
        PriceCalculationSetup.SetRange(Method, DtldPriceCalcSetup.Method);
        PriceCalculationSetup.SetRange(Type, DtldPriceCalcSetup.Type);
        PriceCalculationSetup.SetRange("Asset Type", DtldPriceCalcSetup."Asset Type");
        if PriceCalculationSetup.FindFirst() then
            exit(true);
        PriceCalculationSetup.SetRange("Asset Type", PriceCalculationSetup."Asset Type"::" ");
        if PriceCalculationSetup.FindFirst() then
            exit(true);

        Clear(PriceCalculationSetup);
        exit(false);
    end;

    procedure IsExtendedPriceCalculationEnabled() FeatureEnabled: Boolean;
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        FeatureEnabled := FeatureManagementFacade.IsEnabled(ExtendedPriceFeatureIdTok);
        OnIsExtendedPriceCalculationEnabled(FeatureEnabled);
    end;

    procedure GetFeatureKey(): Text[50]
    begin
        exit(ExtendedPriceFeatureIdTok);
    end;

    procedure TestIsEnabled()
    begin
        if not IsExtendedPriceCalculationEnabled() then
            Error(FeatureIsOffErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsExtendedPriceCalculationEnabled(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSupportedSetup(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    begin
    end;
}