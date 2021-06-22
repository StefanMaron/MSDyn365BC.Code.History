codeunit 7022 "Item Journal Line - Price" implements "Line With Price"
{
    var
        ItemJournalLine: Record "Item Journal Line";
        PriceSourceList: Codeunit "Price Source List";
        CurrPriceType: Enum "Price Type";
        PriceCalculated: Boolean;
        DiscountIsAllowed: Boolean;
        IsSKU: Boolean;

    procedure GetTableNo(): Integer
    begin
        exit(Database::"Item Journal Line")
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        ClearAll();
        ItemJournalLine := Line;
        CurrPriceType := PriceType;
        PriceCalculated := false;
        DiscountIsAllowed := true;
        IsSKU := StockkeepingUnit.Get(ItemJournalLine."Location Code", ItemJournalLine."No.", ItemJournalLine."Variant Code");
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
        Line := ItemJournalLine;
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
            case AmountType of
                AmountType::Price:
                    Result :=
                        Result or
                        not (CalledByFieldNo in [ItemJournalLine.FieldNo(Quantity), ItemJournalLine.FieldNo("Variant Code")]);
                AmountType::Cost:
                    Result :=
                        Result or
                        not ((CalledByFieldNo = ItemJournalLine.FieldNo(Quantity)) or
                            ((CalledByFieldNo = ItemJournalLine.FieldNo("Variant Code")) and not IsSKU))
            end;
    end;

    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := DiscountIsAllowed or not PriceCalculated;
    end;

    procedure Verify()
    begin
        ItemJournalLine.TestField("Qty. per Unit of Measure");
    end;

    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean
    begin
        DtldPriceCalculationSetup.Init();
        DtldPriceCalculationSetup.Type := CurrPriceType;
        DtldPriceCalculationSetup.Method := ItemJournalLine."Price Calculation Method";
        DtldPriceCalculationSetup."Asset Type" := GetAssetType();
        DtldPriceCalculationSetup."Asset No." := ItemJournalLine."Item No.";
        exit(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var PriceCalculationBuffer: Record "Price Calculation Buffer"): Boolean
    begin
        PriceCalculationBuffer."Price Type" := CurrPriceType;
        PriceCalculationBuffer."Asset Type" := GetAssetType();
        PriceCalculationBuffer."Asset No." := ItemJournalLine."Item No.";
        exit(PriceCalculationBuffer."Asset No." <> '');
    end;

    procedure GetAssetType() AssetType: Enum "Price Asset Type";
    begin
        exit(AssetType::Item);
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
    begin
        Item.Get(PriceCalculationBuffer."Asset No.");
        PriceCalculationBuffer."VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
        PriceCalculationBuffer."Variant Code" := ItemJournalLine."Variant Code";
        PriceCalculationBuffer."Location Code" := ItemJournalLine."Location Code";
        PriceCalculationBuffer."Is SKU" := IsSKU;
        PriceCalculationBuffer."Document Date" := ItemJournalLine."Posting Date";
        PriceCalculationBuffer.Validate("Currency Code", '');

        // Tax
        PriceCalculationBuffer."Prices Including Tax" := false;
        // UoM
        PriceCalculationBuffer.Quantity := Abs(ItemJournalLine.Quantity);
        PriceCalculationBuffer."Unit of Measure Code" := ItemJournalLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := ItemJournalLine."Qty. per Unit of Measure";
        // Discounts
        PriceCalculationBuffer."Allow Line Disc." := IsDiscountAllowed();
        PriceCalculationBuffer."Allow Invoice Disc." := false;
    end;

    local procedure AddSources()
    var
        SourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Init();
        case CurrPriceType of
            CurrPriceType::Sale:
                PriceSourceList.Add(SourceType::"All Customers");
            CurrPriceType::Purchase:
                PriceSourceList.Add(SourceType::"All Vendors");
        end;
    end;

    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
        case AmountType of
            AmountType::Price,
            AmountType::Cost:
                ItemJournalLine.Validate("Unit Amount");
        end;
    end;

    procedure SetPrice(AmountType: enum "Price Amount Type"; PriceListLine: Record "Price List Line")
    begin
        case AmountType of
            AmountType::Price:
                begin
                    ItemJournalLine."Unit Amount" := PriceListLine."Unit Price";
                    if PriceListLine.IsRealLine() then
                        DiscountIsAllowed := PriceListLine."Allow Line Disc.";
                    PriceCalculated := true;
                end;
            AmountType::Cost:
                ItemJournalLine."Unit Amount" := PriceListLine."Unit Cost";
        end;
    end;

    procedure Update(AmountType: enum "Price Amount Type")
    begin
    end;
}