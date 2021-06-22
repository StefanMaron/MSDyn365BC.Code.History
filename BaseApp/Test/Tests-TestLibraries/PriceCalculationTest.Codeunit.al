codeunit 130514 "Price Calculation - Test" implements "Price Calculation"
{
    trigger OnRun()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        PriceCalculationSetup.SetRange(Implementation, GetID());
        PriceCalculationSetup.DeleteAll();
        AddSupportedSetup(PriceCalculationSetup);
        PriceCalculationSetup.ModifyAll(Default, true);
    end;

    var
        CurrLineWithPrice: Interface "Line With Price";

    procedure GetID(): Integer
    begin
        exit(Codeunit::"Price Calculation - Test");
    end;

    procedure GetLine(var Line: Variant)
    begin
        CurrLineWithPrice.GetLine(Line);
    end;

    procedure Init(NewLineWithPrice: Interface "Line With Price"; PriceCalculationSetup: Record "Price Calculation Setup")
    begin
        CurrLineWithPrice := NewLineWithPrice;
    end;

    procedure ApplyDiscount()
    begin
    end;

    procedure ApplyPrice(CalledByFieldNo: Integer)
    begin
    end;

    procedure CountDiscount(ShowAll: Boolean) Result: Integer;
    begin
    end;

    procedure CountPrice(ShowAll: Boolean) Result: Integer;
    begin
    end;

    procedure FindDiscount(var TempPriceListLine: Record "Price List Line"; ShowAll: Boolean) Found: Boolean;
    begin
    end;

    procedure FindPrice(var TempPriceListLine: Record "Price List Line"; ShowAll: Boolean) Found: Boolean;
    begin
    end;

    procedure IsDiscountExists(ShowAll: Boolean) Result: Boolean;
    begin
    end;

    procedure IsPriceExists(ShowAll: Boolean) Result: Boolean;
    begin
    end;

    procedure PickDiscount()
    begin
    end;

    procedure PickPrice()
    begin
    end;

    local procedure IsDisabled() Result: Boolean;
    begin
        OnIsDisabled(Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsDisabled(var Disabled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation Mgt.", 'OnFindSupportedSetup', '', false, false)]
    local procedure OnFindImplementationHandler(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    begin
        AddSupportedSetup(TempPriceCalculationSetup);
    end;

    local procedure AddSupportedSetup(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    begin
        TempPriceCalculationSetup.Init();
        TempPriceCalculationSetup.Validate(Implementation, TempPriceCalculationSetup.Implementation::Test);
        TempPriceCalculationSetup.Method := TempPriceCalculationSetup.Method::"Test Price";
        TempPriceCalculationSetup.Enabled := not IsDisabled();
        TempPriceCalculationSetup.Type := TempPriceCalculationSetup.Type::Purchase;
        TempPriceCalculationSetup.Insert(true);
        TempPriceCalculationSetup.Type := TempPriceCalculationSetup.Type::Sale;
        TempPriceCalculationSetup.Insert(true);
        /*
        TempPriceCalculationSetup.Init();
        TempPriceCalculationSetup.Validate(Implementation, TempPriceCalculationSetup.Implementation::Test);
        TempPriceCalculationSetup.Method := TempPriceCalculationSetup.Method::"Lowest Price";
        TempPriceCalculationSetup.Enabled := not IsDisabled();
        TempPriceCalculationSetup.Type := TempPriceCalculationSetup.Type::Purchase;
        TempPriceCalculationSetup."Asset Type" := TempPriceCalculationSetup."Asset Type"::Resource;
        TempPriceCalculationSetup.Insert(true);
        TempPriceCalculationSetup.Type := TempPriceCalculationSetup.Type::Sale;
        TempPriceCalculationSetup."Asset Type" := TempPriceCalculationSetup."Asset Type"::Item;
        TempPriceCalculationSetup.Insert(true);*/
    end;

    procedure ShowPrices(var TempPriceListLine: Record "Price List Line")
    begin
    end;
}