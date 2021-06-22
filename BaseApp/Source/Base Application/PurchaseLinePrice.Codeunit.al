codeunit 7021 "Purchase Line - Price" implements "Line With Price"
{
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        PriceSourceList: Codeunit "Price Source List";
        CurrPriceType: Enum "Price Type";
        PriceCalculated: Boolean;
        DiscountIsAllowed: Boolean;
        IsSKU: Boolean;

    procedure GetTableNo(): Integer
    begin
        exit(Database::"Purchase Line")
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)
    begin
        PurchaseLine := Line;
        CurrPriceType := PriceType;
        PriceCalculated := false;
        DiscountIsAllowed := true;
        IsSKU := StockkeepingUnit.Get(PurchaseLine."Location Code", PurchaseLine."No.", PurchaseLine."Variant Code");
        AddSources();
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Header: Variant; Line: Variant)
    begin
        ClearAll();
        PurchaseHeader := Header;
        SetLine(PriceType, Line);
    end;

    procedure SetSources(var NewPriceSourceList: codeunit "Price Source List")
    begin
        PriceSourceList.Copy(NewPriceSourceList);
    end;

    procedure GetLine(var Line: Variant)
    begin
        Line := PurchaseLine;
    end;

    procedure GetLine(var Header: Variant; var Line: Variant)
    begin
        Header := PurchaseHeader;
        Line := PurchaseLine;
    end;

    procedure GetPriceType(): Enum "Price Type"
    begin
        exit(CurrPriceType);
    end;

    procedure IsPriceUpdateNeeded(AmountType: enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer) Result: Boolean;
    begin
        if PurchaseLine."Prepmt. Amt. Inv." <> 0 then
            Result := false
        else
            if FoundPrice then
                Result := true
            else
                Result :=
                    Result or
                    not ((CalledByFieldNo = PurchaseLine.FieldNo(Quantity)) or
                        ((CalledByFieldNo = PurchaseLine.FieldNo("Variant Code")) and not IsSKU));
    end;

    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := DiscountIsAllowed or not PriceCalculated;
    end;

    procedure Verify()
    begin
        PurchaseLine.TestField("Qty. per Unit of Measure");
        if PurchaseHeader."Currency Code" <> '' then
            PurchaseHeader.TestField("Currency Factor");
    end;

    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean
    begin
        DtldPriceCalculationSetup.Init();
        DtldPriceCalculationSetup.Type := CurrPriceType;
        DtldPriceCalculationSetup.Method := PurchaseLine."Price Calculation Method";
        DtldPriceCalculationSetup."Asset Type" := GetAssetType();
        DtldPriceCalculationSetup."Asset No." := PurchaseLine."No.";
        exit(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var PriceCalculationBuffer: Record "Price Calculation Buffer"): Boolean;
    begin
        PriceCalculationBuffer."Price Type" := CurrPriceType;
        PriceCalculationBuffer."Asset Type" := GetAssetType();
        PriceCalculationBuffer."Asset No." := PurchaseLine."No.";
        exit((PriceCalculationBuffer."Asset Type" <> PriceCalculationBuffer."Asset Type"::" ") and (PriceCalculationBuffer."Asset No." <> ''));
    end;

    procedure GetAssetType() AssetType: Enum "Price Asset Type";
    begin
        case PurchaseLine.Type of
            PurchaseLine.Type::Item:
                AssetType := AssetType::Item;
            PurchaseLine.Type::"G/L Account":
                AssetType := AssetType::"G/L Account";
            PurchaseLine.Type::Resource:
                AssetType := AssetType::Resource;
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
    var
        Item: Record Item;
        Resource: Record Resource;
    begin
        PriceCalculationBuffer."Variant Code" := PurchaseLine."Variant Code";
        PriceCalculationBuffer."Location Code" := PurchaseLine."Location Code";
        case PriceCalculationBuffer."Asset Type" of
            PriceCalculationBuffer."Asset Type"::Item:
                begin
                    PriceCalculationBuffer."Is SKU" := IsSKU;
                    if PriceCalculationBuffer."Is SKU" then
                        PriceCalculationBuffer."Unit Price" := StockkeepingUnit."Last Direct Cost"
                    else begin
                        Item.Get(PriceCalculationBuffer."Asset No.");
                        PriceCalculationBuffer."Unit Price" := Item."Last Direct Cost";
                    end;
                end;
            PriceCalculationBuffer."Asset Type"::Resource:
                begin
                    Resource.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."Unit Price" := Resource."Direct Unit Cost";
                end;
        end;
        PriceCalculationBuffer."Document Date" := GetDocumentDate();

        // Currency
        PriceCalculationBuffer.Validate("Currency Code", PurchaseHeader."Currency Code");
        PriceCalculationBuffer."Currency Factor" := PurchaseHeader."Currency Factor";

        // Tax
        PriceCalculationBuffer."Prices Including Tax" := PurchaseHeader."Prices Including VAT";
        PriceCalculationBuffer."Tax %" := PurchaseLine."VAT %";
        PriceCalculationBuffer."VAT Calculation Type" := PurchaseLine."VAT Calculation Type";
        PriceCalculationBuffer."VAT Bus. Posting Group" := PurchaseLine."VAT Bus. Posting Group";
        PriceCalculationBuffer."VAT Prod. Posting Group" := PurchaseLine."VAT Prod. Posting Group";

        // UoM
        PriceCalculationBuffer.Quantity := Abs(PurchaseLine.Quantity);
        PriceCalculationBuffer."Unit of Measure Code" := PurchaseLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := PurchaseLine."Qty. per Unit of Measure";
        // Discounts
        PriceCalculationBuffer."Line Discount %" := PurchaseLine."Line Discount %";
        PriceCalculationBuffer."Allow Line Disc." := IsDiscountAllowed();
        PriceCalculationBuffer."Allow Invoice Disc." := PurchaseLine."Allow Invoice Disc.";
    end;

    local procedure AddSources()
    var
        SourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Init();
        PriceSourceList.Add(SourceType::"All Vendors");
        PriceSourceList.Add(SourceType::Vendor, PurchaseHeader."Buy-from Vendor No.");
        PriceSourceList.Add(SourceType::Contact, PurchaseHeader."Buy-from Contact No.");
        PriceSourceList.Add(SourceType::Campaign, PurchaseHeader."Campaign No.");
    end;

    local procedure GetDocumentDate() DocumentDate: Date;
    begin
        if PurchaseHeader."Document Type" in [PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Document Type"::"Credit Memo"] then
            DocumentDate := PurchaseHeader."Posting Date"
        else
            DocumentDate := PurchaseHeader."Order Date";
        if DocumentDate = 0D then
            DocumentDate := WorkDate();
    end;

    procedure SetPrice(AmountType: enum "Price Amount Type"; PriceListLine: Record "Price List Line")
    begin
        case AmountType of
            AmountType::Cost:
                if PurchaseLine.Type in [PurchaseLine.Type::Item, PurchaseLine.Type::Resource] then begin
                    PurchaseLine."Direct Unit Cost" := PriceListLine."Unit Cost";
                    PurchaseLine."Allow Invoice Disc." := PriceListLine."Allow Invoice Disc.";
                    if PriceListLine.IsRealLine() then
                        DiscountIsAllowed := PriceListLine."Allow Line Disc.";
                    PriceCalculated := true;
                end;
            AmountType::Discount:
                PurchaseLine."Line Discount %" := PriceListLine."Line Discount %";
        end;
    end;

    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
        case AmountType of
            AmountType::Discount:
                PurchaseLine.Validate("Line Discount %");
            AmountType::Cost:
                PurchaseLine.Validate("Direct Unit Cost");
        end;
    end;

    procedure Update(AmountType: enum "Price Amount Type")
    begin
        if not IsDiscountAllowed() then
            PurchaseLine."Line Discount %" := 0;
    end;
}