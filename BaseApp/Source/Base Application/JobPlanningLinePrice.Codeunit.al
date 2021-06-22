codeunit 7024 "Job Planning Line - Price" implements "Line With Price"
{
    var
        JobPlanningLine: Record "Job Planning Line";
        PriceSourceList: Codeunit "Price Source List";
        CurrPriceType: Enum "Price Type";
        PriceCalculated: Boolean;
        DiscountIsAllowed: Boolean;
        IsSKU: Boolean;

    procedure GetTableNo(): Integer
    begin
        exit(Database::"Job Planning Line")
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        ClearAll();
        JobPlanningLine := Line;
        CurrPriceType := PriceType;
        PriceCalculated := false;
        DiscountIsAllowed := true;
        if JobPlanningLine.Type = JobPlanningLine.Type::Item then
            IsSKU := StockkeepingUnit.Get(JobPlanningLine."Location Code", JobPlanningLine."No.", JobPlanningLine."Variant Code");
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
        Line := JobPlanningLine;
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
                        not (CalledByFieldNo in [JobPlanningLine.FieldNo(Quantity), JobPlanningLine.FieldNo("Location Code"), JobPlanningLine.FieldNo("Variant Code")]);
                AmountType::Cost:
                    Result :=
                        Result or
                        not ((CalledByFieldNo = JobPlanningLine.FieldNo(Quantity)) or
                            ((CalledByFieldNo = JobPlanningLine.FieldNo("Variant Code")) and not IsSKU))
            end;
    end;

    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := DiscountIsAllowed or not PriceCalculated;
    end;

    procedure Verify()
    begin
        JobPlanningLine.TestField("Qty. per Unit of Measure");
        if JobPlanningLine."Currency Code" <> '' then
            JobPlanningLine.TestField("Currency Factor");
    end;

    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean
    begin
        DtldPriceCalculationSetup.Init();
        DtldPriceCalculationSetup.Type := CurrPriceType;
        DtldPriceCalculationSetup.Method := JobPlanningLine."Price Calculation Method";
        DtldPriceCalculationSetup."Asset Type" := GetAssetType();
        DtldPriceCalculationSetup."Asset No." := JobPlanningLine."No.";
        exit(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var PriceCalculationBuffer: Record "Price Calculation Buffer"): Boolean;
    begin
        PriceCalculationBuffer."Price Type" := CurrPriceType;
        PriceCalculationBuffer."Asset Type" := GetAssetType();
        PriceCalculationBuffer."Asset No." := JobPlanningLine."No.";
        exit((PriceCalculationBuffer."Asset Type" <> PriceCalculationBuffer."Asset Type"::" ") and (PriceCalculationBuffer."Asset No." <> ''));
    end;

    procedure GetAssetType() AssetType: Enum "Price Asset Type";
    begin
        case JobPlanningLine.Type of
            JobPlanningLine.Type::Item:
                AssetType := AssetType::Item;
            JobPlanningLine.Type::Resource:
                AssetType := AssetType::Resource;
            JobPlanningLine.Type::"G/L Account":
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
    var
        Item: Record Item;
        Resource: Record Resource;
    begin
        PriceCalculationBuffer."Location Code" := JobPlanningLine."Location Code";
        case PriceCalculationBuffer."Asset Type" of
            PriceCalculationBuffer."Asset Type"::Item:
                begin
                    Item.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
                    PriceCalculationBuffer."Variant Code" := JobPlanningLine."Variant Code";
                    PriceCalculationBuffer."Is SKU" := IsSKU;
                end;
            PriceCalculationBuffer."Asset Type"::Resource:
                begin
                    Resource.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."VAT Prod. Posting Group" := Resource."VAT Prod. Posting Group";
                    PriceCalculationBuffer."Work Type Code" := JobPlanningLine."Work Type Code";
                end;
        end;
        PriceCalculationBuffer."Document Date" := JobPlanningLine."Planning Date";
        PriceCalculationBuffer.Validate("Currency Code", JobPlanningLine."Currency Code");
        PriceCalculationBuffer."Currency Factor" := JobPlanningLine."Currency Factor";

        // Tax
        PriceCalculationBuffer."Prices Including Tax" := false;
        // UoM
        PriceCalculationBuffer.Quantity := Abs(JobPlanningLine.Quantity);
        PriceCalculationBuffer."Unit of Measure Code" := JobPlanningLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := JobPlanningLine."Qty. per Unit of Measure";
        // Discounts
        PriceCalculationBuffer."Allow Line Disc." := IsDiscountAllowed();
        PriceCalculationBuffer."Allow Invoice Disc." := false;
    end;

    local procedure AddSources()
    var
        Job: Record Job;
        SourceType: Enum "Price Source Type";
    begin
        Job.Get(JobPlanningLine."Job No.");
        PriceSourceList.Init();
        case CurrPriceType of
            CurrPriceType::Sale:
                begin
                    PriceSourceList.Add(SourceType::"All Customers");
                    PriceSourceList.Add(SourceType::Customer, Job."Bill-to Customer No.");
                    PriceSourceList.Add(SourceType::Contact, Job."Bill-to Contact No.");
                    PriceSourceList.Add(SourceType::"Customer Price Group", JobPlanningLine."Customer Price Group");
                    PriceSourceList.Add(SourceType::"Customer Disc. Group", Job."Customer Disc. Group");
                end;
            CurrPriceType::Purchase:
                PriceSourceList.Add(SourceType::"All Vendors");
        end;
        PriceSourceList.IncLevel();
        PriceSourceList.Add(SourceType::"All Jobs");
        PriceSourceList.IncLevel();
        PriceSourceList.Add(SourceType::Job, JobPlanningLine."Job No.");
        if JobPlanningLine."Job Task No." <> '' then begin
            PriceSourceList.IncLevel();
            PriceSourceList.Add(SourceType::"Job Task", JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        end;
    end;

    procedure SetPrice(AmountType: enum "Price Amount Type"; PriceListLine: Record "Price List Line")
    begin
        case AmountType of
            AmountType::Price:
                begin
                    JobPlanningLine."Unit Price" := PriceListLine."Unit Price";
                    JobPlanningLine."Cost Factor" := PriceListLine."Cost Factor";
                    if PriceListLine.IsRealLine() then
                        DiscountIsAllowed := PriceListLine."Allow Line Disc.";
                    PriceCalculated := true;
                end;
            AmountType::Discount:
                JobPlanningLine."Line Discount %" := PriceListLine."Line Discount %";
            AmountType::Cost:
                case JobPlanningLine.Type of
                    JobPlanningLine.Type::Item,
                    JobPlanningLine.Type::Resource:
                        JobPlanningLine."Direct Unit Cost (LCY)" := PriceListLine."Unit Cost";
                    JobPlanningLine.Type::"G/L Account":
                        JobPlanningLine."Unit Cost" := PriceListLine."Unit Cost";
                end;
        end;
    end;

    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
        case AmountType of
            AmountType::Price:
                JobPlanningLine.Validate("Unit Price");
            AmountType::Discount:
                JobPlanningLine.Validate("Line Discount %");
            AmountType::Cost:
                JobPlanningLine.Validate("Unit Cost");
        end;
    end;

    procedure Update(AmountType: enum "Price Amount Type")
    begin
        if not IsDiscountAllowed() then
            JobPlanningLine."Line Discount %" := 0;
    end;
}