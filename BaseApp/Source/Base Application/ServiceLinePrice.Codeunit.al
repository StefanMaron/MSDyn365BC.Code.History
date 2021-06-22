codeunit 7026 "Service Line - Price" implements "Line With Price"
{
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        PriceSourceList: Codeunit "Price Source List";
        CurrPriceType: Enum "Price Type";
        PriceCalculated: Boolean;

    procedure GetTableNo(): Integer
    begin
        exit(Database::"Service Line")
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)
    begin
        ServiceLine := Line;
        CurrPriceType := PriceType;
        PriceCalculated := false;
        AddSources();
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Header: Variant; Line: Variant)
    begin
        ClearAll();
        ServiceHeader := Header;
        SetLine(PriceType, Line);
    end;

    procedure SetSources(var NewPriceSourceList: codeunit "Price Source List")
    begin
        PriceSourceList.Copy(NewPriceSourceList);
    end;

    procedure GetLine(var Line: Variant)
    begin
        Line := ServiceLine;
    end;

    procedure GetLine(var Header: Variant; var Line: Variant)
    begin
        Header := ServiceHeader;
        Line := ServiceLine;
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
                not (CalledByFieldNo in [ServiceLine.FieldNo(Quantity), ServiceLine.FieldNo("Variant Code")]);
    end;

    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := ServiceLine."Allow Line Disc." or not PriceCalculated;
    end;

    procedure Verify()
    begin
        ServiceLine.TestField("Qty. per Unit of Measure");
        if ServiceHeader."Currency Code" <> '' then
            ServiceHeader.TestField("Currency Factor");
    end;

    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean
    begin
        DtldPriceCalculationSetup.Init();
        DtldPriceCalculationSetup.Type := CurrPriceType;
        DtldPriceCalculationSetup.Method := ServiceLine."Price Calculation Method";
        DtldPriceCalculationSetup."Asset Type" := GetAssetType();
        DtldPriceCalculationSetup."Asset No." := ServiceLine."No.";
        exit(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var PriceCalculationBuffer: Record "Price Calculation Buffer"): Boolean;
    begin
        PriceCalculationBuffer."Price Type" := CurrPriceType;
        PriceCalculationBuffer."Asset Type" := GetAssetType();
        PriceCalculationBuffer."Asset No." := ServiceLine."No.";
        exit((PriceCalculationBuffer."Asset Type" <> PriceCalculationBuffer."Asset Type"::" ") and (PriceCalculationBuffer."Asset No." <> ''));
    end;

    procedure GetAssetType() AssetType: Enum "Price Asset Type";
    begin
        case ServiceLine.Type of
            ServiceLine.Type::Item:
                AssetType := AssetType::Item;
            ServiceLine.Type::"G/L Account":
                AssetType := AssetType::"G/L Account";
            ServiceLine.Type::Resource:
                AssetType := AssetType::Resource;
            ServiceLine.Type::Cost:
                AssetType := AssetType::"Service Cost";
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
        ServCost: Record "Service Cost";
    begin
        case PriceCalculationBuffer."Asset Type" of
            PriceCalculationBuffer."Asset Type"::Item:
                begin
                    PriceCalculationBuffer."Variant Code" := ServiceLine."Variant Code";

                    Item.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."Unit Price" := Item."Unit Price";
                end;
            PriceCalculationBuffer."Asset Type"::Resource:
                begin
                    PriceCalculationBuffer."Work Type Code" := ServiceLine."Work Type Code";

                    Resource.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."Unit Price" := Resource."Unit Price";
                end;
            PriceCalculationBuffer."Asset Type"::"Service Cost":
                begin
                    ServCost.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."Unit Price" := ServCost."Default Unit Price";
                end;
        end;
        PriceCalculationBuffer."Location Code" := ServiceLine."Location Code";
        PriceCalculationBuffer."Document Date" := GetDocumentDate();

        // Currency
        PriceCalculationBuffer.Validate("Currency Code", ServiceHeader."Currency Code");
        PriceCalculationBuffer."Currency Factor" := ServiceHeader."Currency Factor";

        // Tax
        PriceCalculationBuffer."Prices Including Tax" := ServiceHeader."Prices Including VAT";
        PriceCalculationBuffer."Tax %" := ServiceLine."VAT %";
        PriceCalculationBuffer."VAT Calculation Type" := ServiceLine."VAT Calculation Type";
        PriceCalculationBuffer."VAT Bus. Posting Group" := ServiceLine."VAT Bus. Posting Group";
        PriceCalculationBuffer."VAT Prod. Posting Group" := ServiceLine."VAT Prod. Posting Group";

        // UoM
        PriceCalculationBuffer.Quantity := Abs(ServiceLine.Quantity);
        PriceCalculationBuffer."Unit of Measure Code" := ServiceLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := ServiceLine."Qty. per Unit of Measure";
        // Discounts
        PriceCalculationBuffer."Line Discount %" := ServiceLine."Line Discount %";
        PriceCalculationBuffer."Allow Line Disc." := IsDiscountAllowed();
        PriceCalculationBuffer."Allow Invoice Disc." := ServiceLine."Allow Invoice Disc.";
    end;

    local procedure AddSources()
    var
        SourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Init();
        case ServiceLine.Type of
            ServiceLine.Type::Item:
                begin
                    PriceSourceList.Add(SourceType::Customer, ServiceHeader."Bill-to Customer No.");
                    PriceSourceList.Add(SourceType::Contact, ServiceHeader."Bill-to Contact No.");
                    PriceSourceList.Add(SourceType::"Customer Price Group", ServiceLine."Customer Price Group");
                    PriceSourceList.Add(SourceType::"Customer Disc. Group", ServiceLine."Customer Disc. Group");
                end;
            ServiceLine.Type::Resource:
                PriceSourceList.Add(SourceType::"All Customers");
        end;
    end;

    local procedure GetDocumentDate() DocumentDate: Date;
    begin
        if ServiceHeader."Document Type" in [ServiceHeader."Document Type"::Invoice, ServiceHeader."Document Type"::"Credit Memo"] then
            DocumentDate := ServiceHeader."Posting Date"
        else
            DocumentDate := ServiceHeader."Order Date";
        if DocumentDate = 0D then
            DocumentDate := WorkDate();
    end;

    procedure SetPrice(AmountType: Enum "Price Amount Type"; PriceListLine: Record "Price List Line")
    begin
        case AmountType of
            AmountType::Price:
                begin
                    ServiceLine."Unit Price" := PriceListLine."Unit Price";
                    if PriceListLine.IsRealLine() then
                        ServiceLine."Allow Line Disc." := PriceListLine."Allow Line Disc.";
                    ServiceLine."Allow Invoice Disc." := PriceListLine."Allow Invoice Disc.";
                    PriceCalculated := true;
                end;
            AmountType::Discount:
                case ServiceLine.Type of
                    ServiceLine.Type::Item, ServiceLine.Type::Resource:
                        ServiceLine."Line Discount %" := PriceListLine."Line Discount %";
                    ServiceLine.Type::Cost, ServiceLine.Type::"G/L Account":
                        begin
                            ServiceLine."Line Discount %" := 0;
                            ServiceLine."Line Discount Amount" := 0;
                            ServiceLine."Inv. Discount Amount" := 0;
                            ServiceLine."Inv. Disc. Amount to Invoice" := 0;
                        end;
                end;
        end;
    end;

    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
        case AmountType of
            AmountType::Discount:
                ServiceLine.Validate("Line Discount %");
            AmountType::Price:
                ServiceLine.Validate("Unit Price");
        end;
    end;

    procedure Update(AmountType: enum "Price Amount Type")
    begin
        if not IsDiscountAllowed() then
            ServiceLine."Line Discount %" := 0;
    end;
}