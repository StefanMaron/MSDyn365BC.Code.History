codeunit 7017 "Price List Management"
{
    procedure AddLines(var PriceListHeader: Record "Price List Header")
    var
        PriceLineFilters: Record "Price Line Filters";
        SuggestPriceLine: Page "Suggest Price Lines";
    begin
        PriceLineFilters.Initialize(PriceListHeader, false);
        SuggestPriceLine.SetRecord(PriceLineFilters);
        if SuggestPriceLine.RunModal() = Action::OK then begin
            SuggestPriceLine.GetRecord(PriceLineFilters);
            AddLines(PriceListHeader, PriceLineFilters);
        end;
    end;

    procedure AddLines(var ToPriceListHeader: Record "Price List Header"; PriceLineFilters: Record "Price Line Filters")
    var
        PriceAsset: Record "Price Asset";
        RecRef: RecordRef;
    begin
        RecRef.Open(PriceLineFilters."Table Id");
        if PriceLineFilters."Asset Filter" <> '' then
            RecRef.SetView(PriceLineFilters."Asset Filter");
        if RecRef.FindSet() then begin
            PriceAsset."Price Type" := ToPriceListHeader."Price Type";
            PriceAsset.Validate("Asset Type", PriceLineFilters."Asset Type");
            repeat
                PriceAsset.Validate("Asset ID", RecRef.Field(RecRef.SystemIdNo()).Value());
                if PriceAsset."Asset No." <> '' then
                    AddLine(ToPriceListHeader, PriceAsset, PriceLineFilters);
            until RecRef.Next() = 0;
        end;
        RecRef.Close();
    end;

    local procedure AddLine(var ToPriceListHeader: Record "Price List Header"; PriceAsset: Record "Price Asset"; PriceLineFilters: Record "Price Line Filters")
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine."Price List Code" := ToPriceListHeader.Code;
        PriceListLine."Line No." := 0; // autoincrement
        PriceListLine.CopyFrom(ToPriceListHeader);
        PriceListLine.Status := PriceListLine.Status::Draft;
        PriceListLine."Amount Type" := "Price Amount Type"::Price;
        PriceListLine.CopyFrom(PriceAsset);
        PriceListLine.Validate("Minimum Quantity", PriceLineFilters."Minimum Quantity");
        AdjustAmount(PriceAsset."Unit Price", PriceLineFilters);
        case ToPriceListHeader."Price Type" of
            "Price Type"::Sale:
                PriceListLine.Validate("Unit Price", PriceAsset."Unit Price");
            "Price Type"::Purchase:
                begin
                    PriceListLine.Validate("Direct Unit Cost", PriceAsset."Unit Price");
                    AdjustAmount(PriceAsset."Unit Price 2", PriceLineFilters);
                    PriceListLine.Validate("Unit Cost", PriceAsset."Unit Price 2");
                end;
        end;
        PriceListLine.Insert(true);
    end;

    local procedure AdjustAmount(var Price: Decimal; PriceLineFilters: Record "Price Line Filters")
    var
        NewPrice: Decimal;
    begin
        if Price = 0 then
            exit;

        NewPrice := ConvertCurrency(Price, PriceLineFilters);
        NewPrice := NewPrice * PriceLineFilters."Adjustment Factor";

        if not ApplyRoundingMethod(PriceLineFilters."Rounding Method Code", NewPrice) then
            NewPrice := Round(NewPrice, PriceLineFilters."Amount Rounding Precision");

        Price := NewPrice;
    end;

    local procedure ConvertCurrency(Price: Decimal; PriceLineFilters: Record "Price Line Filters") NewPrice: Decimal;
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        NewPrice := Price;
        if PriceLineFilters."From Currency Code" <> PriceLineFilters."To Currency Code" then
            if PriceLineFilters."From Currency Code" = '' then
                NewPrice :=
                    Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                            PriceLineFilters."Exchange Rate Date", PriceLineFilters."To Currency Code", Price,
                            CurrExchRate.ExchangeRate(PriceLineFilters."Exchange Rate Date", PriceLineFilters."To Currency Code")),
                        PriceLineFilters."Amount Rounding Precision")
            else
                if PriceLineFilters."To Currency Code" = '' then
                    NewPrice :=
                        Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                                PriceLineFilters."Exchange Rate Date", PriceLineFilters."From Currency Code", Price,
                                CurrExchRate.ExchangeRate(PriceLineFilters."Exchange Rate Date", PriceLineFilters."From Currency Code")),
                            PriceLineFilters."Amount Rounding Precision")
                else
                    NewPrice :=
                        Round(
                            CurrExchRate.ExchangeAmtFCYToFCY(
                                PriceLineFilters."Exchange Rate Date",
                                PriceLineFilters."From Currency Code", PriceLineFilters."To Currency Code",
                                Price),
                            PriceLineFilters."Amount Rounding Precision");
    end;

    local procedure ApplyRoundingMethod(RoundingMethodCode: Code[10]; var Price: Decimal) Rounded: Boolean;
    var
        RoundingMethod: Record "Rounding Method";
    begin
        if Price <= 0 then
            exit(false);

        if RoundingMethodCode <> '' then begin
            RoundingMethod.SetRange(Code, RoundingMethodCode);
            RoundingMethod.SetFilter("Minimum Amount", '<=%1', Price);
            if RoundingMethod.FindLast() then begin
                Price := Price + RoundingMethod."Amount Added Before";
                if RoundingMethod.Precision > 0 then
                    Price :=
                      Round(
                        Price,
                        RoundingMethod.Precision, CopyStr('=><', RoundingMethod.Type + 1, 1));
                Price := Price + RoundingMethod."Amount Added After";
                Rounded := true;
            end;
        end;
        if Price < 0 then
            Price := 0;
    end;

    procedure CopyLines(var ToPriceListHeader: Record "Price List Header")
    var
        PriceLineFilters: Record "Price Line Filters";
        SuggestPriceLine: Page "Suggest Price Lines";
    begin
        PriceLineFilters.Initialize(ToPriceListHeader, true);
        SuggestPriceLine.SetRecord(PriceLineFilters);
        if SuggestPriceLine.RunModal() = Action::OK then begin
            SuggestPriceLine.GetRecord(PriceLineFilters);
            CopyLines(ToPriceListHeader, PriceLineFilters);
        end;
    end;

    procedure CopyLines(var ToPriceListHeader: Record "Price List Header"; PriceLineFilters: Record "Price Line Filters")
    var
        FromPriceListHeader: Record "Price List Header";
        FromPriceListLine: Record "Price List Line";
    begin
        FromPriceListHeader.Get(PriceLineFilters."From Price List Code");
        if PriceLineFilters."Price Line Filter" <> '' then
            FromPriceListLine.SetView(PriceLineFilters."Price Line Filter");
        FromPriceListLine.SetRange("Price List Code", PriceLineFilters."From Price List Code");
        if FromPriceListLine.FindSet() then
            repeat
                CopyLine(PriceLineFilters, FromPriceListLine, ToPriceListHeader);
            until FromPriceListLine.Next() = 0;
    end;

    local procedure CopyLine(PriceLineFilters: Record "Price Line Filters"; FromPriceListLine: Record "Price List Line"; ToPriceListHeader: Record "Price List Header")
    var
        ToPriceListLine: Record "Price List Line";
    begin
        ToPriceListLine := FromPriceListLine;
        ToPriceListLine."Price List Code" := PriceLineFilters."To Price List Code";
        ToPriceListLine.CopyFrom(ToPriceListHeader);
        ToPriceListLine.Status := ToPriceListLine.Status::Draft;
        AdjustAmount(ToPriceListLine."Unit Price", PriceLineFilters);
        AdjustAmount(ToPriceListLine."Direct Unit Cost", PriceLineFilters);
        ToPriceListLine."Line No." := 0;
        ToPriceListLine.Insert(true);
    end;

    procedure FindDuplicatePrices(PriceListHeader: Record "Price List Header"; SearchInside: Boolean; var DuplicatePriceLine: Record "Duplicate Price Line") Found: Boolean;
    var
        PriceListLine: Record "Price List Line";
        DuplicatePriceListLine: Record "Price List Line";
        LineNo: Integer;
    begin
        DuplicatePriceLine.Reset();
        DuplicatePriceLine.DeleteAll();

        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        if PriceListLine.FindSet() then
            repeat
                if not DuplicatePriceLine.Get(PriceListLine."Price List Code", PriceListLine."Line No.") then
                    if FindDuplicatePrice(PriceListLine, SearchInside, DuplicatePriceListLine) then
                        if DuplicatePriceLine.Get(DuplicatePriceListLine."Price List Code", DuplicatePriceListLine."Line No.") then
                            DuplicatePriceLine.Add(LineNo, DuplicatePriceLine."Line No.", PriceListLine)
                        else
                            DuplicatePriceLine.Add(LineNo, PriceListLine, DuplicatePriceListLine);
            until PriceListLine.Next() = 0;
        Found := LineNo > 0;
    end;

    local procedure FindDuplicatePrice(PriceListLine: Record "Price List Line"; SearchInside: Boolean; var DuplicatePriceListLine: Record "Price List Line"): Boolean;
    begin
        DuplicatePriceListLine.Reset();
        if SearchInside then begin
            DuplicatePriceListLine.SetRange("Price List Code", PriceListLine."Price List Code");
            DuplicatePriceListLine.SetFilter("Line No.", '<>%1', PriceListLine."Line No.");
        end else begin
            DuplicatePriceListLine.SetFilter("Price List Code", '<>%1', PriceListLine."Price List Code");
            SetHeadersFilters(PriceListLine, DuplicatePriceListLine);
        end;
        SetAssetFilters(PriceListLine, DuplicatePriceListLine);
        OnBeforeFindDuplicatePriceListLine(PriceListLine, DuplicatePriceListLine);
        exit(DuplicatePriceListLine.FindFirst());
    end;

    local procedure SetHeadersFilters(PriceListLine: Record "Price List Line"; var DuplicatePriceListLine: Record "Price List Line")
    begin
        DuplicatePriceListLine.SetRange("Price Type", PriceListLine."Price Type");
        DuplicatePriceListLine.SetRange(Status, "Price Status"::Active);
        DuplicatePriceListLine.SetRange("Source Type", PriceListLine."Source Type");
        DuplicatePriceListLine.SetRange("Parent Source No.", PriceListLine."Parent Source No.");
        DuplicatePriceListLine.SetRange("Source No.", PriceListLine."Source No.");
        DuplicatePriceListLine.SetRange("Currency Code", PriceListLine."Currency Code");
        DuplicatePriceListLine.SetRange("Starting Date", PriceListLine."Starting Date");
    end;

    local procedure SetAssetFilters(PriceListLine: Record "Price List Line"; var DuplicatePriceListLine: Record "Price List Line")
    begin
        if PriceListLine."Amount Type" in ["Price Amount Type"::Price, "Price Amount Type"::Discount] then
            DuplicatePriceListLine.SetFilter("Amount Type", '%1|%2', PriceListLine."Amount Type", "Price Amount Type"::Any);
        DuplicatePriceListLine.SetRange("Asset Type", PriceListLine."Asset Type");
        DuplicatePriceListLine.SetRange("Asset No.", PriceListLine."Asset No.");
        DuplicatePriceListLine.SetRange("Unit of Measure Code", PriceListLine."Unit of Measure Code");
        DuplicatePriceListLine.SetRange("Minimum Quantity", PriceListLine."Minimum Quantity");
        case PriceListLine."Asset Type" of
            "Price Asset Type"::Item:
                DuplicatePriceListLine.SetRange("Variant Code", PriceListLine."Variant Code");
            "Price Asset Type"::Resource:
                DuplicatePriceListLine.SetRange("Work Type Code", PriceListLine."Work Type Code");
        end;
    end;

    procedure ResolveDuplicatePrices(PriceListHeader: Record "Price List Header"; var DuplicatePriceLine: Record "Duplicate Price Line") Resolved: Boolean;
    var
        PriceListLine: Record "Price List Line";
        DuplicatePriceLines: Page "Duplicate Price Lines";
    begin
        DuplicatePriceLines.Set(PriceListHeader."Price Type", PriceListHeader."Amount Type", DuplicatePriceLine);
        DuplicatePriceLines.LookupMode(true);
        if DuplicatePriceLines.RunModal() = Action::LookupOK then begin
            DuplicatePriceLines.GetLines(DuplicatePriceLine);
            DuplicatePriceLine.SetRange(Remove, true);
            if DuplicatePriceLine.FindSet() then
                repeat
                    if PriceListLine.Get(DuplicatePriceLine."Price List Code", DuplicatePriceLine."Price List Line No.") then
                        PriceListLine.Delete();
                until DuplicatePriceLine.Next() = 0;
            Resolved := true;
            Commit();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindDuplicatePriceListLine(PriceListLine: Record "Price List Line"; var DuplicatePriceListLine: Record "Price List Line")
    begin
    end;
}
