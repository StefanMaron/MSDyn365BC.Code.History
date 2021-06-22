Codeunit 7009 CopyFromToPriceListLine
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
    ObsoleteTag = '16.0';

    var
        NotMatchSalesLineDiscTypeErr: Label 'does not match sales line discount type.';

    procedure CopyFrom(var SalesPrice: Record "Sales Price"; var PriceListLine: Record "Price List Line")
    var
        OrigSalesPrice: Record "Sales Price";
    begin
        OrigSalesPrice := SalesPrice;
        if SalesPrice.IsTemporary then begin
            PriceListLine.Reset();
            PriceListLine.DeleteAll();
        end;
        if SalesPrice.FindSet() then
            repeat
                PriceListLine.Init();
                if PriceListLine.IsTemporary then
                    PriceListLine."Line No." += 1
                else
                    PriceListLine."Line No." := 0;
                PriceListLine.Validate("Source Type", ConvertToSourceType(SalesPrice));
                PriceListLine.Validate("Source No.", SalesPrice."Sales Code");
                PriceListLine."VAT Bus. Posting Gr. (Price)" := SalesPrice."VAT Bus. Posting Gr. (Price)";
                PriceListLine."Starting Date" := SalesPrice."Starting Date";
                PriceListLine."Ending Date" := SalesPrice."Ending Date";
                PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
                PriceListLine.Validate("Asset No.", SalesPrice."Item No.");
                PriceListLine.Validate("Variant Code", SalesPrice."Variant Code");
                PriceListLine.Validate("Unit of Measure Code", SalesPrice."Unit of Measure Code");
                PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
                PriceListLine."Unit Price" := SalesPrice."Unit Price";
                PriceListLine."Allow Invoice Disc." := SalesPrice."Allow Invoice Disc.";
                PriceListLine."Allow Line Disc." := SalesPrice."Allow Line Disc.";
                PriceListLine."Currency Code" := SalesPrice."Currency Code";
                PriceListLine."Minimum Quantity" := SalesPrice."Minimum Quantity";
                PriceListLine."Price Includes VAT" := SalesPrice."Price Includes VAT";
                OnCopyFromSalesPrice(SalesPrice, PriceListLine);
                PriceListLine.Insert(true);
            until SalesPrice.Next() = 0;
        SalesPrice := OrigSalesPrice;
    end;

    procedure CopyFrom(var SalesLineDiscount: Record "Sales Line Discount"; var PriceListLine: Record "Price List Line")
    var
        OrigSalesLineDiscount: Record "Sales Line Discount";
    begin
        OrigSalesLineDiscount := SalesLineDiscount;
        if SalesLineDiscount.IsTemporary then begin
            PriceListLine.Reset();
            PriceListLine.DeleteAll();
        end;
        if SalesLineDiscount.FindSet() then
            repeat
                PriceListLine.Init();
                PriceListLine.Validate("Source Type", ConvertToSourceType(SalesLineDiscount));
                PriceListLine.Validate("Source No.", SalesLineDiscount."Sales Code");
                PriceListLine."Starting Date" := SalesLineDiscount."Starting Date";
                PriceListLine."Ending Date" := SalesLineDiscount."Ending Date";
                case SalesLineDiscount.Type of
                    SalesLineDiscount.Type::Item:
                        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
                    SalesLineDiscount.Type::"Item Disc. Group":
                        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::"Item Discount Group");
                end;
                PriceListLine.Validate("Asset No.", SalesLineDiscount.Code);
                PriceListLine.Validate("Variant Code", SalesLineDiscount."Variant Code");
                PriceListLine.Validate("Unit of Measure Code", SalesLineDiscount."Unit of Measure Code");
                PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
                PriceListLine."Line Discount %" := SalesLineDiscount."Line Discount %";
                PriceListLine."Currency Code" := SalesLineDiscount."Currency Code";
                PriceListLine."Minimum Quantity" := SalesLineDiscount."Minimum Quantity";
                PriceListLine."Allow Invoice Disc." := false;
                PriceListLine."Allow Line Disc." := false;
                OnCopyFromSalesLineDiscount(SalesLineDiscount, PriceListLine);
                PriceListLine.Insert(true);
            until SalesLineDiscount.Next() = 0;
        SalesLineDiscount := OrigSalesLineDiscount;
    end;

    local procedure ConvertToSourceType(SalesPrice: Record "Sales Price") SourceType: Enum "Price Source Type";
    begin
        case SalesPrice."Sales Type" of
            SalesPrice."Sales Type"::Customer:
                exit(SourceType::Customer);
            SalesPrice."Sales Type"::"Customer Price Group":
                exit(SourceType::"Customer Price Group");
            SalesPrice."Sales Type"::"All Customers":
                exit(SourceType::"All Customers");
            SalesPrice."Sales Type"::Campaign:
                exit(SourceType::Campaign);
        end;
    end;

    local procedure ConvertToSourceType(SalesLineDiscount: Record "Sales Line Discount") SourceType: Enum "Price Source Type";
    begin
        case SalesLineDiscount."Sales Type" of
            SalesLineDiscount."Sales Type"::Customer:
                exit(SourceType::Customer);
            SalesLineDiscount."Sales Type"::"Customer Disc. Group":
                exit(SourceType::"Customer Disc. Group");
            SalesLineDiscount."Sales Type"::"All Customers":
                exit(SourceType::"All Customers");
            SalesLineDiscount."Sales Type"::Campaign:
                exit(SourceType::Campaign);
        end;
    end;

    procedure CopyTo(var TempSalesPrice: Record "Sales Price" temporary; var PriceListLine: Record "Price List Line") Copied: Boolean;
    begin
        TempSalesPrice.Reset();
        TempSalesPrice.DeleteAll();
        if PriceListLine.FindSet() then
            repeat
                TempSalesPrice.Init();
                ConvertFromSourceType(PriceListLine."Source Type", TempSalesPrice);
                TempSalesPrice."Sales Code" := PriceListLine."Source No.";
                TempSalesPrice."VAT Bus. Posting Gr. (Price)" := PriceListLine."VAT Bus. Posting Gr. (Price)";
                TempSalesPrice."Starting Date" := PriceListLine."Starting Date";
                TempSalesPrice."Ending Date" := PriceListLine."Ending Date";
                TempSalesPrice."Item No." := PriceListLine."Asset No.";
                TempSalesPrice."Variant Code" := PriceListLine."Variant Code";
                TempSalesPrice."Unit of Measure Code" := PriceListLine."Unit of Measure Code";
                TempSalesPrice."Unit Price" := PriceListLine."Unit Price";
                TempSalesPrice."Allow Invoice Disc." := PriceListLine."Allow Invoice Disc.";
                TempSalesPrice."Allow Line Disc." := PriceListLine."Allow Line Disc.";
                TempSalesPrice."Currency Code" := PriceListLine."Currency Code";
                TempSalesPrice."Minimum Quantity" := PriceListLine."Minimum Quantity";
                TempSalesPrice."Price Includes VAT" := PriceListLine."Price Includes VAT";
                OnCopyToSalesPrice(TempSalesPrice, PriceListLine);
                if TempSalesPrice.Insert(true) then
                    Copied := true;
            until PriceListLine.Next() = 0;
    end;

    local procedure ConvertFromSourceType(SourceType: Enum "Price Source Type"; var SalesPrice: Record "Sales Price")
    begin
        case SourceType of
            SourceType::Customer:
                SalesPrice."Sales Type" := SalesPrice."Sales Type"::Customer;
            SourceType::"Customer Price Group":
                SalesPrice."Sales Type" := SalesPrice."Sales Type"::"Customer Price Group";
            SourceType::"All Customers":
                SalesPrice."Sales Type" := SalesPrice."Sales Type"::"All Customers";
            SourceType::Campaign:
                SalesPrice."Sales Type" := SalesPrice."Sales Type"::Campaign;
        end;
    end;

    procedure CopyTo(var TempSalesLineDiscount: Record "Sales Line Discount" temporary; var PriceListLine: Record "Price List Line") Copied: Boolean;
    begin
        TempSalesLineDiscount.Reset();
        TempSalesLineDiscount.DeleteAll();
        if PriceListLine.FindSet() then
            repeat
                TempSalesLineDiscount.Init();
                ConvertFromSourceType(PriceListLine."Source Type", TempSalesLineDiscount);
                TempSalesLineDiscount."Sales Code" := PriceListLine."Source No.";
                TempSalesLineDiscount."Starting Date" := PriceListLine."Starting Date";
                TempSalesLineDiscount."Ending Date" := PriceListLine."Ending Date";
                TempSalesLineDiscount.Type := ConvertAssetTypeToSalesDiscType(PriceListLine);
                TempSalesLineDiscount.Code := PriceListLine."Asset No.";
                TempSalesLineDiscount."Variant Code" := PriceListLine."Variant Code";
                TempSalesLineDiscount."Unit of Measure Code" := PriceListLine."Unit of Measure Code";
                TempSalesLineDiscount."Line Discount %" := PriceListLine."Line Discount %";
                TempSalesLineDiscount."Currency Code" := PriceListLine."Currency Code";
                TempSalesLineDiscount."Minimum Quantity" := PriceListLine."Minimum Quantity";
                OnCopyToSalesLineDiscount(TempSalesLineDiscount, PriceListLine);
                if TempSalesLineDiscount.Insert(true) then
                    Copied := true;
            until PriceListLine.Next() = 0;
    end;

    local procedure ConvertFromSourceType(SourceType: Enum "Price Source Type"; var SalesLineDiscount: Record "Sales Line Discount")
    begin
        case SourceType of
            SourceType::Customer:
                SalesLineDiscount."Sales Type" := SalesLineDiscount."Sales Type"::Customer;
            SourceType::"Customer Disc. Group":
                SalesLineDiscount."Sales Type" := SalesLineDiscount."Sales Type"::"Customer Disc. Group";
            SourceType::"All Customers":
                SalesLineDiscount."Sales Type" := SalesLineDiscount."Sales Type"::"All Customers";
            SourceType::Campaign:
                SalesLineDiscount."Sales Type" := SalesLineDiscount."Sales Type"::Campaign;
        end;
    end;

    local procedure ConvertAssetTypeToSalesDiscType(PriceListLine: Record "Price List Line") DiscType: Enum "Sales Line Discount Type";
    begin
        case PriceListLine."Asset Type" of
            PriceListLine."Asset Type"::Item:
                DiscType := DiscType::Item;
            PriceListLine."Asset Type"::"Item Discount Group":
                DiscType := DiscType::"Item Disc. Group";
            else
                PriceListLine.FieldError("Asset Type", NotMatchSalesLineDiscTypeErr);
        end;
    end;

    procedure CopyFrom(var JobItemPrice: Record "Job Item Price"; var PriceListLine: Record "Price List Line")
    var
        OrigJobItemPrice: Record "Job Item Price";
    begin
        OrigJobItemPrice := JobItemPrice;
        if JobItemPrice.IsTemporary then begin
            PriceListLine.Reset();
            PriceListLine.DeleteAll();
        end;
        if JobItemPrice.FindSet() then
            repeat
                PriceListLine.Init();
                if PriceListLine.IsTemporary then
                    PriceListLine."Line No." += 1
                else
                    PriceListLine."Line No." := 0;
                SetJobAsSource(JobItemPrice."Job No.", JobItemPrice."Job Task No.", PriceListLine);
                PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
                PriceListLine.Validate("Asset No.", JobItemPrice."Item No.");
                PriceListLine.Validate("Variant Code", JobItemPrice."Variant Code");
                PriceListLine.Validate("Unit of Measure Code", JobItemPrice."Unit of Measure Code");
                PriceListLine."Currency Code" := JobItemPrice."Currency Code";
                PriceListLine."Allow Invoice Disc." := false;
                if JobItemPrice."Apply Job Price" then begin
                    PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
                    PriceListLine."Unit Price" := JobItemPrice."Unit Price";
                    PriceListLine."Cost Factor" := JobItemPrice."Unit Cost Factor";
                end;
                PriceListLine."Allow Line Disc." := JobItemPrice."Apply Job Discount";
                PriceListLine.Insert(true);

                if JobItemPrice."Line Discount %" > 0 then begin
                    if PriceListLine.IsTemporary then
                        PriceListLine."Line No." += 1
                    else
                        PriceListLine."Line No." := 0;
                    PriceListLine."Unit Price" := 0;
                    PriceListLine."Cost Factor" := 0;
                    PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
                    PriceListLine."Line Discount %" := JobItemPrice."Line Discount %";
                    PriceListLine.Insert(true);
                end;
                OnCopyFromJobItemPrice(JobItemPrice, PriceListLine);
            until JobItemPrice.Next() = 0;
        JobItemPrice := OrigJobItemPrice;
    end;

    procedure CopyFrom(var JobGLAccountPrice: Record "Job G/L Account Price"; var PriceListLine: Record "Price List Line")
    var
        OrigJobGLAccountPrice: Record "Job G/L Account Price";
    begin
        OrigJobGLAccountPrice := JobGLAccountPrice;
        if JobGLAccountPrice.IsTemporary then begin
            PriceListLine.Reset();
            PriceListLine.DeleteAll();
        end;
        if JobGLAccountPrice.FindSet() then
            repeat
                PriceListLine.Init();
                if PriceListLine.IsTemporary then
                    PriceListLine."Line No." += 1
                else
                    PriceListLine."Line No." := 0;
                SetJobAsSource(JobGLAccountPrice."Job No.", JobGLAccountPrice."Job Task No.", PriceListLine);
                PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::"G/L Account");
                PriceListLine.Validate("Asset No.", JobGLAccountPrice."G/L Account No.");
                PriceListLine."Currency Code" := JobGLAccountPrice."Currency Code";
                PriceListLine."Line Discount %" := JobGLAccountPrice."Line Discount %";
                PriceListLine."Unit Cost" := JobGLAccountPrice."Unit Cost";
                PriceListLine."Unit Price" := JobGLAccountPrice."Unit Price";
                PriceListLine."Cost Factor" := JobGLAccountPrice."Unit Cost Factor";
                PriceListLine."Allow Invoice Disc." := false;
                PriceListLine."Allow Line Disc." := true;
                OnCopyFromJobGLAccountPrice(JobGLAccountPrice, PriceListLine);
                PriceListLine.Insert(true);
            until JobGLAccountPrice.Next() = 0;
        JobGLAccountPrice := OrigJobGLAccountPrice;
    end;

    procedure CopyFrom(var JobResourcePrice: Record "Job Resource Price"; var PriceListLine: Record "Price List Line")
    var
        OrigJobResourcePrice: Record "Job Resource Price";
    begin
        OrigJobResourcePrice := JobResourcePrice;
        if JobResourcePrice.IsTemporary then begin
            PriceListLine.Reset();
            PriceListLine.DeleteAll();
        end;
        if JobResourcePrice.FindSet() then
            repeat
                PriceListLine.Init();
                if PriceListLine.IsTemporary then
                    PriceListLine."Line No." += 1
                else
                    PriceListLine."Line No." := 0;
                SetJobAsSource(JobResourcePrice."Job No.", JobResourcePrice."Job Task No.", PriceListLine);
                case JobResourcePrice.Type of
                    JobResourcePrice.Type::All,
                    JobResourcePrice.Type::Resource:
                        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Resource);
                    JobResourcePrice.Type::"Group(Resource)":
                        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::"Resource Group");
                end;
                PriceListLine.Validate("Asset No.", JobResourcePrice.Code);
                PriceListLine."Work Type Code" := JobResourcePrice."Work Type Code";
                PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
                PriceListLine."Currency Code" := JobResourcePrice."Currency Code";
                PriceListLine."Allow Invoice Disc." := false;
                if JobResourcePrice."Apply Job Price" then begin
                    PriceListLine."Unit Price" := JobResourcePrice."Unit Price";
                    PriceListLine."Cost Factor" := JobResourcePrice."Unit Cost Factor";
                end;
                PriceListLine."Allow Line Disc." := JobResourcePrice."Apply Job Discount";
                PriceListLine.Insert(true);

                if JobResourcePrice."Line Discount %" > 0 then begin
                    if PriceListLine.IsTemporary then
                        PriceListLine."Line No." += 1
                    else
                        PriceListLine."Line No." := 0;
                    PriceListLine."Unit Price" := 0;
                    PriceListLine."Cost Factor" := 0;
                    PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
                    PriceListLine."Line Discount %" := JobResourcePrice."Line Discount %";
                    PriceListLine.Insert(true);
                end;
                OnCopyFromJobResourcePrice(JobResourcePrice, PriceListLine);
            until JobResourcePrice.Next() = 0;
        JobResourcePrice := OrigJobResourcePrice;
    end;

    local procedure SetJobAsSource(JobNo: Code[20]; JobTaskNo: Code[20]; var PriceListLine: Record "Price List Line")
    begin
        if JobTaskNo = '' then begin
            PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Job);
            PriceListLine.Validate("Source No.", JobNo);
        end else begin
            PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"Job Task");
            PriceListLine.Validate("Parent Source No.", JobNo);
            PriceListLine.Validate("Source No.", JobTaskNo);
        end;
    end;

    procedure CopyFrom(var ResourceCost: Record "Resource Cost"; var PriceListLine: Record "Price List Line")
    var
        OrigResourceCost: Record "Resource Cost";
    begin
        OrigResourceCost := ResourceCost;
        if ResourceCost.IsTemporary then begin
            PriceListLine.Reset();
            PriceListLine.DeleteAll();
        end;
        if ResourceCost.FindSet() then
            repeat
                PriceListLine.Init();
                if PriceListLine.IsTemporary then
                    PriceListLine."Line No." += 1
                else
                    PriceListLine."Line No." := 0;
                PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"All Vendors");
                case ResourceCost.Type of
                    ResourceCost.Type::All,
                    ResourceCost.Type::Resource:
                        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Resource);
                    ResourceCost.Type::"Group(Resource)":
                        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::"Resource Group");
                end;
                PriceListLine.Validate("Asset No.", ResourceCost.Code);
                PriceListLine."Work Type Code" := ResourceCost."Work Type Code";
                PriceListLine."Amount Type" := PriceListLine."Amount Type"::Cost;
                PriceListLine."Unit Cost" := ResourceCost."Direct Unit Cost";
                PriceListLine."Allow Invoice Disc." := false;
                PriceListLine."Allow Line Disc." := true;
                OnCopyFromResourceCost(ResourceCost, PriceListLine);
                PriceListLine.Insert(true);
            until ResourceCost.Next() = 0;
        ResourceCost := OrigResourceCost;
    end;

    procedure CopyFrom(var ResourcePrice: Record "Resource Price"; var PriceListLine: Record "Price List Line")
    var
        OrigResourcePrice: Record "Resource Price";
    begin
        OrigResourcePrice := ResourcePrice;
        if ResourcePrice.IsTemporary then begin
            PriceListLine.Reset();
            PriceListLine.DeleteAll();
        end;
        if ResourcePrice.FindSet() then
            repeat
                PriceListLine.Init();
                if PriceListLine.IsTemporary then
                    PriceListLine."Line No." += 1
                else
                    PriceListLine."Line No." := 0;
                PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"All Customers");
                case ResourcePrice.Type of
                    ResourcePrice.Type::All,
                    ResourcePrice.Type::Resource:
                        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Resource);
                    ResourcePrice.Type::"Group(Resource)":
                        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::"Resource Group");
                end;
                PriceListLine.Validate("Asset No.", ResourcePrice.Code);
                PriceListLine."Currency Code" := ResourcePrice."Currency Code";
                PriceListLine."Work Type Code" := ResourcePrice."Work Type Code";
                PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
                PriceListLine."Unit Price" := ResourcePrice."Unit Price";
                PriceListLine."Allow Invoice Disc." := false;
                PriceListLine."Allow Line Disc." := true;
                OnCopyFromResourcePrice(ResourcePrice, PriceListLine);
                PriceListLine.Insert(true);
            until ResourcePrice.Next() = 0;
        ResourcePrice := OrigResourcePrice;
    end;

    procedure CopyFrom(var PurchasePrice: Record "Purchase Price"; var PriceListLine: Record "Price List Line")
    var
        OrigPurchasePrice: Record "Purchase Price";
    begin
        OrigPurchasePrice := PurchasePrice;
        if PurchasePrice.IsTemporary then begin
            PriceListLine.Reset();
            PriceListLine.DeleteAll();
        end;
        if PurchasePrice.FindSet() then
            repeat
                PriceListLine.Init();
                if PriceListLine.IsTemporary then
                    PriceListLine."Line No." += 1
                else
                    PriceListLine."Line No." := 0;
                PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Vendor);
                PriceListLine.Validate("Source No.", PurchasePrice."Vendor No.");
                PriceListLine."Starting Date" := PurchasePrice."Starting Date";
                PriceListLine."Ending Date" := PurchasePrice."Ending Date";
                PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
                PriceListLine.Validate("Asset No.", PurchasePrice."Item No.");
                PriceListLine.Validate("Variant Code", PurchasePrice."Variant Code");
                PriceListLine.Validate("Unit of Measure Code", PurchasePrice."Unit of Measure Code");
                PriceListLine."Amount Type" := PriceListLine."Amount Type"::Cost;
                PriceListLine."Unit Cost" := PurchasePrice."Direct Unit Cost";
                PriceListLine."Currency Code" := PurchasePrice."Currency Code";
                PriceListLine."Minimum Quantity" := PurchasePrice."Minimum Quantity";
                PriceListLine."Allow Invoice Disc." := false;
                PriceListLine."Allow Line Disc." := true;
                OnCopyFromPurchasePrice(PurchasePrice, PriceListLine);
                PriceListLine.Insert(true);
            until PurchasePrice.Next() = 0;
        PurchasePrice := OrigPurchasePrice;
    end;

    procedure CopyFrom(var PurchaseLineDiscount: Record "Purchase Line Discount"; var PriceListLine: Record "Price List Line")
    var
        OrigPurchaseLineDiscount: Record "Purchase Line Discount";
    begin
        OrigPurchaseLineDiscount := PurchaseLineDiscount;
        if PurchaseLineDiscount.IsTemporary then begin
            PriceListLine.Reset();
            PriceListLine.DeleteAll();
        end;
        if PurchaseLineDiscount.FindSet() then
            repeat
                PriceListLine.Init();
                PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Vendor);
                PriceListLine.Validate("Source No.", PurchaseLineDiscount."Vendor No.");
                PriceListLine."Starting Date" := PurchaseLineDiscount."Starting Date";
                PriceListLine."Ending Date" := PurchaseLineDiscount."Ending Date";
                PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
                PriceListLine.Validate("Asset No.", PurchaseLineDiscount."Item No.");
                PriceListLine.Validate("Variant Code", PurchaseLineDiscount."Variant Code");
                PriceListLine.Validate("Unit of Measure Code", PurchaseLineDiscount."Unit of Measure Code");
                PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
                PriceListLine."Line Discount %" := PurchaseLineDiscount."Line Discount %";
                PriceListLine."Currency Code" := PurchaseLineDiscount."Currency Code";
                PriceListLine."Minimum Quantity" := PurchaseLineDiscount."Minimum Quantity";
                PriceListLine."Allow Invoice Disc." := false;
                PriceListLine."Allow Line Disc." := false;
                OnCopyFromPurchLineDiscount(PurchaseLineDiscount, PriceListLine);
                PriceListLine.Insert(true);
            until PurchaseLineDiscount.Next() = 0;
        PurchaseLineDiscount := OrigPurchaseLineDiscount;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromPurchLineDiscount(PurchaseLineDiscount: Record "Purchase Line Discount"; var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromPurchasePrice(PurchasePrice: Record "Purchase Price"; var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromResourceCost(ResourceCost: Record "Resource Cost"; var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromResourcePrice(ResourcePrice: Record "Resource Price"; var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromJobItemPrice(var JobItemPrice: Record "Job Item Price"; var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromJobGLAccountPrice(var JobGLAccountPrice: Record "Job G/L Account Price"; var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromJobResourcePrice(var JobResourcePrice: Record "Job Resource Price"; var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesPrice(var SalesPrice: Record "Sales Price"; var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyToSalesPrice(var SalesPrice: Record "Sales Price"; var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount"; var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyToSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount"; var PriceListLine: Record "Price List Line")
    begin
    end;

}