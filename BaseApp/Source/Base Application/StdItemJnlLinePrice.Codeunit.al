codeunit 7027 "Std. Item Jnl. Line - Price" implements "Line With Price"
{
    var
        StandardItemJournalLine: Record "Standard Item Journal Line";
        PriceSourceList: Codeunit "Price Source List";
        CurrPriceType: Enum "Price Type";
        PriceCalculated: Boolean;
        DiscountIsAllowed: Boolean;
        IsSKU: Boolean;

    procedure GetTableNo(): Integer
    begin
        exit(Database::"Standard Item Journal Line")
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        ClearAll();
        StandardItemJournalLine := Line;
        CurrPriceType := PriceType;
        PriceCalculated := false;
        DiscountIsAllowed := true;
        IsSKU :=
            StockkeepingUnit.Get(
                StandardItemJournalLine."Location Code", StandardItemJournalLine."Item No.", StandardItemJournalLine."Variant Code");
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
        Line := StandardItemJournalLine;
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
                        not (CalledByFieldNo in
                            [StandardItemJournalLine.FieldNo(Quantity),
                            StandardItemJournalLine.FieldNo("Variant Code")]);
                AmountType::Cost:
                    Result :=
                        Result or
                        not ((CalledByFieldNo = StandardItemJournalLine.FieldNo(Quantity)) or
                            ((CalledByFieldNo = StandardItemJournalLine.FieldNo("Variant Code")) and not IsSKU))
            end;
    end;

    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := DiscountIsAllowed or not PriceCalculated;
    end;

    procedure Verify()
    begin

    end;

    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean
    begin
        DtldPriceCalculationSetup.Init();
        DtldPriceCalculationSetup.Type := CurrPriceType;
        DtldPriceCalculationSetup.Method := StandardItemJournalLine."Price Calculation Method";
        DtldPriceCalculationSetup."Asset Type" := GetAssetType();
        DtldPriceCalculationSetup."Asset No." := StandardItemJournalLine."Item No.";
        exit(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var PriceCalculationBuffer: Record "Price Calculation Buffer"): Boolean;
    begin
        PriceCalculationBuffer."Price Type" := CurrPriceType;
        PriceCalculationBuffer."Asset Type" := GetAssetType();
        PriceCalculationBuffer."Asset No." := StandardItemJournalLine."Item No.";
        exit((PriceCalculationBuffer."Asset Type" <> PriceCalculationBuffer."Asset Type"::" ") and (PriceCalculationBuffer."Asset No." <> ''));
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
        PriceCalculationBuffer."Variant Code" := StandardItemJournalLine."Variant Code";
        PriceCalculationBuffer."Location Code" := StandardItemJournalLine."Location Code";
        PriceCalculationBuffer.Validate("Currency Code", '');

        // Tax
        PriceCalculationBuffer."Prices Including Tax" := false;
        // UoM
        PriceCalculationBuffer.Quantity := Abs(StandardItemJournalLine.Quantity);
        PriceCalculationBuffer."Unit of Measure Code" := StandardItemJournalLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := StandardItemJournalLine."Qty. per Unit of Measure";
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

    procedure SetPrice(AmountType: Enum "Price Amount Type"; PriceListLine: Record "Price List Line")
    begin
        case AmountType of
            AmountType::Price:
                begin
                    StandardItemJournalLine."Unit Amount" := PriceListLine."Unit Price";
                    if PriceListLine.IsRealLine() then
                        DiscountIsAllowed := PriceListLine."Allow Line Disc.";
                    PriceCalculated := true;
                end;
            AmountType::Cost:
                StandardItemJournalLine."Unit Amount" := PriceListLine."Unit Cost";
        end;
    end;

    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
        case AmountType of
            AmountType::Price,
            AmountType::Cost:
                StandardItemJournalLine.Validate("Unit Amount");
        end;
    end;

    procedure Update(AmountType: enum "Price Amount Type")
    begin
    end;
}