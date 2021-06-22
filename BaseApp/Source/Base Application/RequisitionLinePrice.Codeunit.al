codeunit 7025 "Requisition Line - Price" implements "Line With Price"
{
    var
        RequisitionLine: Record "Requisition Line";
        PriceSourceList: Codeunit "Price Source List";
        CurrPriceType: Enum "Price Type";
        PriceCalculated: Boolean;
        DiscountIsAllowed: Boolean;
        IsSKU: Boolean;

    procedure GetTableNo(): Integer
    begin
        exit(Database::"Requisition Line")
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        ClearAll();
        RequisitionLine := Line;
        CurrPriceType := PriceType;
        PriceCalculated := false;
        DiscountIsAllowed := true;
        if RequisitionLine.Type = RequisitionLine.Type::Item then
            IsSKU := StockkeepingUnit.Get(RequisitionLine."Location Code", RequisitionLine."No.", RequisitionLine."Variant Code");
        AddSources();
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Header: Variant; Line: Variant)
    begin
        Setline(PriceType, Line);
    end;

    procedure SetSources(var NewPriceSourceList: codeunit "Price Source List")
    begin
        PriceSourceList.Copy(NewPriceSourceList);
    end;

    procedure GetLine(var Line: Variant)
    begin
        Line := RequisitionLine;
    end;

    procedure GetLine(var Header: Variant; var Line: Variant)
    begin
        Clear(Header);
        GetLine(Line);
    end;

    procedure GetPriceType(): Enum "Price Type"
    begin
        exit(CurrPriceType);
    end;

    procedure IsPriceUpdateNeeded(AmountType: enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer) Result: Boolean;
    begin
        if FoundPrice then
            Result := true
        else
            Result :=
                Result or
                not ((CalledByFieldNo = RequisitionLine.FieldNo(Quantity)) or
                    ((CalledByFieldNo = RequisitionLine.FieldNo("Variant Code")) and not IsSKU))
    end;

    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := DiscountIsAllowed or not PriceCalculated;
    end;

    procedure Verify()
    begin
        RequisitionLine.TestField("Qty. per Unit of Measure");
        if RequisitionLine."Currency Code" <> '' then
            RequisitionLine.TestField("Currency Factor");
    end;

    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean
    begin
        DtldPriceCalculationSetup.Init();
        DtldPriceCalculationSetup.Type := CurrPriceType;
        DtldPriceCalculationSetup.Method := RequisitionLine."Price Calculation Method";
        DtldPriceCalculationSetup."Asset Type" := GetAssetType();
        DtldPriceCalculationSetup."Asset No." := RequisitionLine."No.";
        exit(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var PriceCalculationBuffer: Record "Price Calculation Buffer"): Boolean;
    begin
        PriceCalculationBuffer."Price Type" := CurrPriceType;
        PriceCalculationBuffer."Asset Type" := GetAssetType();
        PriceCalculationBuffer."Asset No." := RequisitionLine."No.";
        exit((PriceCalculationBuffer."Asset Type" <> PriceCalculationBuffer."Asset Type"::" ") and (PriceCalculationBuffer."Asset No." <> ''));
    end;

    procedure GetAssetType() AssetType: Enum "Price Asset Type";
    begin
        case RequisitionLine.Type of
            RequisitionLine.Type::Item:
                AssetType := AssetType::Item;
            RequisitionLine.Type::"G/L Account":
                AssetType := AssetType::"G/L Account";
            else
                AssetType := AssetType::" ";
        end;
    end;

    procedure CopyToBuffer(var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt."): Boolean
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
    begin
        PriceCalculationBuffer.Init();
        if not SetAssetSource(PriceCalculationBuffer) then
            exit(false);

        FillBuffer(PriceCalculationBuffer);
        PriceCalculationBufferMgt.Set(PriceCalculationBuffer, PriceSourceList);
        exit(true);
    end;

    local procedure FillBuffer(var PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
        PriceCalculationBuffer."Variant Code" := RequisitionLine."Variant Code";
        PriceCalculationBuffer."Location Code" := RequisitionLine."Location Code";
        PriceCalculationBuffer."Is SKU" := IsSKU;
        PriceCalculationBuffer."Document Date" := RequisitionLine."Order Date";

        // Currency
        PriceCalculationBuffer.Validate("Currency Code", RequisitionLine."Currency Code");
        PriceCalculationBuffer."Currency Factor" := RequisitionLine."Currency Factor";

        // Tax
        PriceCalculationBuffer."Prices Including Tax" := false;
        // UoM
        PriceCalculationBuffer.Quantity := Abs(RequisitionLine.Quantity);
        PriceCalculationBuffer."Unit of Measure Code" := RequisitionLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := RequisitionLine."Qty. per Unit of Measure";
        // Discounts
        PriceCalculationBuffer."Line Discount %" := RequisitionLine."Line Discount %";
        PriceCalculationBuffer."Allow Line Disc." := IsDiscountAllowed();
        PriceCalculationBuffer."Allow Invoice Disc." := false;
    end;

    local procedure AddSources()
    var
        SourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Init();
        PriceSourceList.Add(SourceType::Vendor, RequisitionLine."Vendor No.");
    end;

    procedure SetPrice(AmountType: Enum "Price Amount Type"; PriceListLine: Record "Price List Line")
    begin
        case AmountType of
            AmountType::Cost:
                begin
                    RequisitionLine."Direct Unit Cost" := PriceListLine."Unit Cost";
                    if PriceListLine.IsRealLine() then
                        DiscountIsAllowed := PriceListLine."Allow Line Disc.";
                    PriceCalculated := true;
                end;
            AmountType::Discount:
                RequisitionLine."Line Discount %" := PriceListLine."Line Discount %";
        end;
    end;

    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
        case AmountType of
            AmountType::Discount:
                RequisitionLine.Validate("Line Discount %");
            AmountType::Cost:
                RequisitionLine.Validate("Direct Unit Cost");
        end;
    end;

    procedure Update(AmountType: enum "Price Amount Type")
    begin
        if not IsDiscountAllowed() then
            RequisitionLine."Line Discount %" := 0;
    end;
}