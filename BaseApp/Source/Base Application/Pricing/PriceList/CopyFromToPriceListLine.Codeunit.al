﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

#if not CLEAN23
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
#endif
using Microsoft.Pricing.Source;
using System.Telemetry;
using Microsoft.Pricing.Calculation;
#if not CLEAN23
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Pricing;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Pricing;
using Microsoft.Sales.Pricing;
using Microsoft.Utilities;
#endif

codeunit 7009 CopyFromToPriceListLine
{
    var
        GenerateHeader: Boolean;
        UseDefaultPriceLists: Boolean;
#if not CLEAN23
        NotMatchSalesLineDiscTypeErr: Label 'does not match sales line discount type.';
#endif
        PlaceHolderBracketTok: Label ' (%1)', Locked = true;
        PlaceHolderTok: Label ' %1', Locked = true;
        PlaceHolderRangeTok: Label ', %1 - %2', Locked = true;

    procedure SetGenerateHeader()
    begin
        SetGenerateHeader(false);
    end;

    procedure SetGenerateHeader(UseDefault: Boolean)
    begin
        GenerateHeader := true;
        UseDefaultPriceLists := UseDefault;
    end;

#if not CLEAN23
#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    procedure CopyFrom(var SalesPrice: Record "Sales Price"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
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
                PriceListLine."Price List Code" := '';
                PriceListLine.Validate("Source Type", ConvertToSourceType(SalesPrice));
                PriceListLine.Validate("Source No.", SalesPrice."Sales Code");
                if PriceListLine."Source No." = SalesPrice."Sales Code" then begin
                    PriceListLine."VAT Bus. Posting Gr. (Price)" := SalesPrice."VAT Bus. Posting Gr. (Price)";
                    PriceListLine."Starting Date" := SalesPrice."Starting Date";
                    PriceListLine."Ending Date" := SalesPrice."Ending Date";
                    PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
                    PriceListLine.Validate("Asset No.", SalesPrice."Item No.");
                    if PriceListLine."Asset No." = SalesPrice."Item No." then
                        if VerifySalesPriceConsistency(SalesPrice) then begin
                            PriceListLine.Validate("Variant Code", SalesPrice."Variant Code");
                            PriceListLine.Validate("Unit of Measure Code", SalesPrice."Unit of Measure Code");
                            PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
                            PriceListLine."Unit Price" := SalesPrice."Unit Price";
                            PriceListLine."Allow Invoice Disc." := SalesPrice."Allow Invoice Disc.";
                            PriceListLine."Allow Line Disc." := SalesPrice."Allow Line Disc.";
                            PriceListLine."Currency Code" := SalesPrice."Currency Code";
                            PriceListLine."Minimum Quantity" := SalesPrice."Minimum Quantity";
                            PriceListLine."Price Includes VAT" := SalesPrice."Price Includes VAT";
                            PriceListLine.Status := PriceListLine.Status::Active;
                            PriceListLine."Price Type" := PriceListLine."Price Type"::Sale;
                            OnCopyFromSalesPrice(SalesPrice, PriceListLine);
                            InsertPriceListLine(PriceListLine);
                        end;
                end;
            until SalesPrice.Next() = 0;
        SalesPrice := OrigSalesPrice;
    end;

    local procedure VerifySalesPriceConsistency(SalesPrice: Record "Sales Price"): Boolean;
    var
        Currency: Record Currency;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemUnitofMeasure: Record "Item Unit of Measure";
        UnitofMeasure: Record "Unit of Measure";
    begin
        if SalesPrice."Item No." = '' then
            exit(false);
        Item.SetLoadFields("No.");
        if not Item.Get(SalesPrice."Item No.") then
            exit(false);
        if SalesPrice."Variant Code" <> '' then
            if not ItemVariant.Get(SalesPrice."Item No.", SalesPrice."Variant Code") then
                exit(false);
        if SalesPrice."Unit of Measure Code" <> '' then begin
            if not UnitofMeasure.Get(SalesPrice."Unit of Measure Code") then
                exit(false);
            if not ItemUnitofMeasure.Get(SalesPrice."Item No.", SalesPrice."Unit of Measure Code") then
                exit(false);
        end;
        if SalesPrice."Currency Code" <> '' then
            if not Currency.Get(SalesPrice."Currency Code") then
                exit(false);
        exit(true);
    end;

#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    procedure CopyFrom(var SalesLineDiscount: Record "Sales Line Discount"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
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
                PriceListLine."Price List Code" := '';
                PriceListLine.Validate("Source Type", ConvertToSourceType(SalesLineDiscount));
                PriceListLine.Validate("Source No.", SalesLineDiscount."Sales Code");
                if PriceListLine."Source No." = SalesLineDiscount."Sales Code" then begin
                    PriceListLine."Starting Date" := SalesLineDiscount."Starting Date";
                    PriceListLine."Ending Date" := SalesLineDiscount."Ending Date";
                    case SalesLineDiscount.Type of
                        SalesLineDiscount.Type::Item:
                            PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
                        SalesLineDiscount.Type::"Item Disc. Group":
                            PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::"Item Discount Group");
                    end;
                    PriceListLine.Validate("Asset No.", SalesLineDiscount.Code);
                    if PriceListLine."Asset No." = SalesLineDiscount.Code then
                        if VerifySalesLineDiscConsistency(SalesLineDiscount) then begin
                            if SalesLineDiscount.Type = SalesLineDiscount.Type::Item then begin
                                PriceListLine.Validate("Variant Code", SalesLineDiscount."Variant Code");
                                PriceListLine.Validate("Unit of Measure Code", SalesLineDiscount."Unit of Measure Code");
                            end;
                            PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
                            PriceListLine."Line Discount %" := SalesLineDiscount."Line Discount %";
                            PriceListLine."Currency Code" := SalesLineDiscount."Currency Code";
                            PriceListLine."Minimum Quantity" := SalesLineDiscount."Minimum Quantity";
                            PriceListLine."Allow Invoice Disc." := false;
                            PriceListLine."Allow Line Disc." := false;
                            PriceListLine.Status := PriceListLine.Status::Active;
                            PriceListLine."Price Type" := PriceListLine."Price Type"::Sale;
                            OnCopyFromSalesLineDiscount(SalesLineDiscount, PriceListLine);
                            InsertPriceListLine(PriceListLine);
                        end;
                end;
            until SalesLineDiscount.Next() = 0;
        SalesLineDiscount := OrigSalesLineDiscount;
    end;

    local procedure VerifySalesLineDiscConsistency(SalesLineDiscount: Record "Sales Line Discount"): Boolean;
    var
        Currency: Record Currency;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemUnitofMeasure: Record "Item Unit of Measure";
        UnitofMeasure: Record "Unit of Measure";
    begin
        if SalesLineDiscount.Type = SalesLineDiscount.Type::Item then begin
            if SalesLineDiscount.Code = '' then
                exit(false);
            Item.SetLoadFields("No.");
            if not Item.Get(SalesLineDiscount.Code) then
                exit(false);
            if SalesLineDiscount."Variant Code" <> '' then
                if not ItemVariant.Get(SalesLineDiscount.Code, SalesLineDiscount."Variant Code") then
                    exit(false);
            if SalesLineDiscount."Unit of Measure Code" <> '' then begin
                if not UnitofMeasure.Get(SalesLineDiscount."Unit of Measure Code") then
                    exit(false);
                if not ItemUnitofMeasure.Get(SalesLineDiscount.Code, SalesLineDiscount."Unit of Measure Code") then
                    exit(false);
            end;
        end;
        if SalesLineDiscount."Currency Code" <> '' then
            if not Currency.Get(SalesLineDiscount."Currency Code") then
                exit(false);
        exit(true);
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

#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    procedure CopyTo(var TempSalesPrice: Record "Sales Price" temporary; var PriceListLine: Record "Price List Line") Copied: Boolean;
#pragma warning restore AS0072
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

#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    procedure CopyTo(var TempSalesLineDiscount: Record "Sales Line Discount" temporary; var PriceListLine: Record "Price List Line") Copied: Boolean;
#pragma warning restore AS0072
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
                if TempSalesLineDiscount.Type = TempSalesLineDiscount.Type::Item then begin
                    TempSalesLineDiscount."Variant Code" := PriceListLine."Variant Code";
                    TempSalesLineDiscount."Unit of Measure Code" := PriceListLine."Unit of Measure Code";
                end;
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

#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    procedure CopyFrom(var JobItemPrice: Record "Job Item Price"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
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
                PriceListLine."Price List Code" := '';
                PriceListLine."Price Type" := PriceListLine."Price Type"::Sale;
                if SetJobAsSource(JobItemPrice."Job No.", JobItemPrice."Job Task No.", PriceListLine) then begin
                    PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
                    PriceListLine.Validate("Asset No.", JobItemPrice."Item No.");
                    if PriceListLine."Asset No." = JobItemPrice."Item No." then
                        if VerifyJobItemPriceConsistency(JobItemPrice) then begin
                            PriceListLine.Validate("Variant Code", JobItemPrice."Variant Code");
                            PriceListLine.Validate("Unit of Measure Code", JobItemPrice."Unit of Measure Code");
                            PriceListLine."Currency Code" := JobItemPrice."Currency Code";
                            PriceListLine."Allow Invoice Disc." := false;
                            if JobItemPrice."Apply Job Price" then begin
                                PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
                                PriceListLine."Unit Price" := JobItemPrice."Unit Price";
                                PriceListLine."Cost Factor" := JobItemPrice."Unit Cost Factor";
                                PriceListLine."Allow Line Disc." := JobItemPrice."Apply Job Discount";
                                PriceListLine.Status := PriceListLine.Status::Active;
                                InsertPriceListLine(PriceListLine);
                            end;

                            if JobItemPrice."Apply Job Discount" then begin
                                PriceListLine."Price List Code" := '';
                                PriceListLine.Status := PriceListLine.Status::Draft;
                                PriceListLine.Validate("Amount Type", PriceListLine."Amount Type"::Discount);
                                PriceListLine."Unit Price" := 0;
                                PriceListLine."Cost Factor" := 0;
                                PriceListLine."Line Discount %" := JobItemPrice."Line Discount %";
                                PriceListLine.Status := PriceListLine.Status::Active;
                                InsertPriceListLine(PriceListLine);
                            end;
                            OnCopyFromJobItemPrice(JobItemPrice, PriceListLine);
                        end;
                end;
            until JobItemPrice.Next() = 0;
        JobItemPrice := OrigJobItemPrice;
    end;

    local procedure VerifyJobItemPriceConsistency(JobItemPrice: Record "Job Item Price"): Boolean;
    var
        Currency: Record Currency;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemUnitofMeasure: Record "Item Unit of Measure";
        UnitofMeasure: Record "Unit of Measure";
    begin
        if JobItemPrice."Item No." = '' then
            exit(false);
        Item.SetLoadFields("No.");
        if not Item.Get(JobItemPrice."Item No.") then
            exit(false);
        if JobItemPrice."Variant Code" <> '' then
            if not ItemVariant.Get(JobItemPrice."Item No.", JobItemPrice."Variant Code") then
                exit(false);
        if JobItemPrice."Unit of Measure Code" <> '' then begin
            if not UnitofMeasure.Get(JobItemPrice."Unit of Measure Code") then
                exit(false);
            if not ItemUnitofMeasure.Get(JobItemPrice."Item No.", JobItemPrice."Unit of Measure Code") then
                exit(false);
        end;
        if JobItemPrice."Currency Code" <> '' then
            if not Currency.Get(JobItemPrice."Currency Code") then
                exit(false);
        exit(true);
    end;

#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    procedure CopyFrom(var JobGLAccountPrice: Record "Job G/L Account Price"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
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
                PriceListLine."Price List Code" := '';
                if SetJobAsSource(JobGLAccountPrice."Job No.", JobGLAccountPrice."Job Task No.", PriceListLine) then begin
                    PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::"G/L Account");
                    PriceListLine.Validate("Asset No.", JobGLAccountPrice."G/L Account No.");
                    if PriceListLine."Asset No." = JobGLAccountPrice."G/L Account No." then
                        if VerifyJobGLAccountPriceConsistency(JobGLAccountPrice) then begin
                            PriceListLine."Currency Code" := JobGLAccountPrice."Currency Code";
                            if JobGLAccountPrice."Line Discount %" <> 0 then begin
                                PriceListLine."Line Discount %" := JobGLAccountPrice."Line Discount %";
                                PriceListLine."Amount Type" := "Price Amount Type"::Any;
                            end;
                            PriceListLine."Unit Price" := JobGLAccountPrice."Unit Price";
                            PriceListLine."Cost Factor" := JobGLAccountPrice."Unit Cost Factor";
                            PriceListLine."Allow Invoice Disc." := false;
                            PriceListLine."Allow Line Disc." := true;
                            if (PriceListLine."Line Discount %" <> 0) or
                                (PriceListLine."Unit Price" <> 0) or (PriceListLine."Cost Factor" <> 0)
                            then begin
                                if PriceListLine."Line Discount %" = 0 then
                                    PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price
                                else
                                    if (PriceListLine."Unit Price" = 0) and (PriceListLine."Cost Factor" = 0) then begin
                                        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
                                        PriceListLine."Allow Line Disc." := false;
                                    end;
                                PriceListLine.Status := PriceListLine.Status::Active;
                                PriceListLine."Price Type" := PriceListLine."Price Type"::Sale;
                                OnCopyFromJobGLAccountPrice(JobGLAccountPrice, PriceListLine);
                                InsertPriceListLine(PriceListLine);
                            end;

                            if JobGLAccountPrice."Unit Cost" <> 0 then begin
                                PriceListLine."Price List Code" := '';
                                PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
                                PriceListLine."Line Discount %" := 0;
                                PriceListLine."Unit Price" := 0;
                                PriceListLine."Cost Factor" := 0;
                                PriceListLine."Allow Line Disc." := false;
                                PriceListLine."Unit Cost" := JobGLAccountPrice."Unit Cost";
                                PriceListLine."Price Type" := PriceListLine."Price Type"::Purchase;
                                OnCopyFromJobGLAccountPrice(JobGLAccountPrice, PriceListLine);
                                InsertPriceListLine(PriceListLine);
                            end;
                        end;
                end;
            until JobGLAccountPrice.Next() = 0;
        JobGLAccountPrice := OrigJobGLAccountPrice;
    end;

    local procedure VerifyJobGLAccountPriceConsistency(JobGLAccountPrice: Record "Job G/L Account Price"): Boolean;
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
    begin
        if JobGLAccountPrice."G/L Account No." = '' then
            exit(false);
        GLAccount.SetLoadFields("No.");
        if not GLAccount.Get(JobGLAccountPrice."G/L Account No.") then
            exit(false);
        if JobGLAccountPrice."Currency Code" <> '' then
            if not Currency.Get(JobGLAccountPrice."Currency Code") then
                exit(false);
        exit(true);
    end;

#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    procedure CopyFrom(var JobResourcePrice: Record "Job Resource Price"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
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
                PriceListLine."Price List Code" := '';
                PriceListLine."Price Type" := PriceListLine."Price Type"::Sale;
                if SetJobAsSource(JobResourcePrice."Job No.", JobResourcePrice."Job Task No.", PriceListLine) then begin
                    case JobResourcePrice.Type of
                        JobResourcePrice.Type::All,
                        JobResourcePrice.Type::Resource:
                            PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Resource);
                        JobResourcePrice.Type::"Group(Resource)":
                            PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::"Resource Group");
                    end;
                    PriceListLine.Validate("Asset No.", JobResourcePrice.Code);
                    if PriceListLine."Asset No." = JobResourcePrice.Code then
                        if VerifyJobResourcePriceConsistency(JobResourcePrice) then begin
                            PriceListLine."Work Type Code" := JobResourcePrice."Work Type Code";
                            PriceListLine."Currency Code" := JobResourcePrice."Currency Code";
                            PriceListLine."Allow Invoice Disc." := false;
                            if JobResourcePrice."Apply Job Price" then begin
                                PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
                                PriceListLine."Unit Price" := JobResourcePrice."Unit Price";
                                PriceListLine."Cost Factor" := JobResourcePrice."Unit Cost Factor";
                                PriceListLine."Allow Line Disc." := JobResourcePrice."Apply Job Discount";
                                PriceListLine.Status := PriceListLine.Status::Active;
                                InsertPriceListLine(PriceListLine);
                            end;

                            if JobResourcePrice."Apply Job Discount" then begin
                                PriceListLine."Price List Code" := '';
                                PriceListLine.Status := PriceListLine.Status::Draft;
                                PriceListLine.Validate("Amount Type", PriceListLine."Amount Type"::Discount);
                                PriceListLine."Unit Price" := 0;
                                PriceListLine."Cost Factor" := 0;
                                PriceListLine."Line Discount %" := JobResourcePrice."Line Discount %";
                                PriceListLine.Status := PriceListLine.Status::Active;
                                InsertPriceListLine(PriceListLine);
                            end;
                            OnCopyFromJobResourcePrice(JobResourcePrice, PriceListLine);
                        end;
                end;
            until JobResourcePrice.Next() = 0;
        JobResourcePrice := OrigJobResourcePrice;
    end;

    local procedure VerifyJobResourcePriceConsistency(JobResourcePrice: Record "Job Resource Price"): Boolean;
    var
        Currency: Record Currency;
        Resource: Record Resource;
        WorkType: Record "Work Type";
    begin
        if JobResourcePrice.Type = JobResourcePrice.Type::Resource then begin
            if JobResourcePrice.Code = '' then
                exit(false);
            Resource.SetLoadFields("No.");
            if not Resource.Get(JobResourcePrice.Code) then
                exit(false);
        end;
        if JobResourcePrice."Currency Code" <> '' then
            if not Currency.Get(JobResourcePrice."Currency Code") then
                exit(false);
        if JobResourcePrice."Work Type Code" <> '' then
            if not WorkType.Get(JobResourcePrice."Work Type Code") then
                exit(false);
        exit(true);
    end;

    local procedure SetJobAsSource(JobNo: Code[20]; JobTaskNo: Code[20]; var PriceListLine: Record "Price List Line"): Boolean;
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        if JobNo <> '' then
            if not Job.Get(JobNo) then
                exit(false);
        if JobTaskNo <> '' then
            if not JobTask.Get(JobNo, JobTaskNo) then
                exit(false);

        if JobTaskNo = '' then begin
            PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Job);
            PriceListLine.Validate("Source No.", JobNo);
        end else begin
            PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"Job Task");
            PriceListLine.Validate("Parent Source No.", JobNo);
            PriceListLine.Validate("Source No.", JobTaskNo);
        end;
        exit(true);
    end;

#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    procedure CopyFrom(var ResourceCost: Record "Resource Cost"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
    var
        OrigResourceCost: Record "Resource Cost";
        TempResourceCost: Record "Resource Cost" temporary;
    begin
        OrigResourceCost := ResourceCost;
        if ResourceCost.IsTemporary then begin
            PriceListLine.Reset();
            PriceListLine.DeleteAll();
        end;
        ResourceCost.SetRange("Cost Type", ResourceCost."Cost Type"::Fixed);
        if ResourceCost.FindSet() then
            repeat
                PriceListLine.Init();
                PriceListLine."Price List Code" := '';
                PriceListLine."Price Type" := PriceListLine."Price Type"::Purchase;
                PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"All Vendors");
                PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
                case ResourceCost.Type of
                    ResourceCost.Type::All,
                    ResourceCost.Type::Resource:
                        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Resource);
                    ResourceCost.Type::"Group(Resource)":
                        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::"Resource Group");
                end;
                PriceListLine.Validate("Asset No.", ResourceCost.Code);
                if PriceListLine."Asset No." = ResourceCost.Code then
                    if VerifyResourceCostConsistency(ResourceCost) then begin
                        PriceListLine."Work Type Code" := ResourceCost."Work Type Code";
                        PriceListLine."Unit Cost" := ResourceCost."Unit Cost";
                        PriceListLine."Direct Unit Cost" := ResourceCost."Direct Unit Cost";
                        PriceListLine."Allow Invoice Disc." := false;
                        PriceListLine."Allow Line Disc." := true;
                        PriceListLine.Status := PriceListLine.Status::Active;
                        OnCopyFromResourceCost(ResourceCost, PriceListLine);
                        InsertPriceListLine(PriceListLine);
                        TempResourceCost := ResourceCost;
                        TempResourceCost.Insert();
                    end;
            until ResourceCost.Next() = 0;

        CopySpecialCostTypes(TempResourceCost, PriceListLine);

        ResourceCost := OrigResourceCost;
    end;

    local procedure VerifyResourceCostConsistency(ResourceCost: Record "Resource Cost"): Boolean;
    var
        Resource: Record Resource;
        WorkType: Record "Work Type";
    begin
        if ResourceCost.Type = ResourceCost.Type::Resource then begin
            if ResourceCost.Code = '' then
                exit(false);
            Resource.SetLoadFields("No.");
            if not Resource.Get(ResourceCost.Code) then
                exit(false);
        end;
        if ResourceCost."Work Type Code" <> '' then
            if not WorkType.Get(ResourceCost."Work Type Code") then
                exit(false);
        exit(true);
    end;

    local procedure CopySpecialCostTypes(var TempResourceCost: Record "Resource Cost" temporary; var PriceListLine: Record "Price List Line")
    var
        Resource: Record Resource;
        ResourceCost: Record "Resource Cost";
    begin
        ResourceCost.SetFilter("Cost Type", '<>%1', ResourceCost."Cost Type"::Fixed);
        if ResourceCost.FindSet() then
            repeat
                if FindResources(ResourceCost, Resource) then
                    CreatePriceLinePerResource(Resource, ResourceCost, TempResourceCost, PriceListLine);
            until ResourceCost.Next() = 0;
    end;

    local procedure FindResources(ResourceCost: Record "Resource Cost"; var Resource: Record Resource): Boolean
    begin
        case ResourceCost.Type of
            ResourceCost.Type::Resource:
                Resource.SetRange("No.", ResourceCost.Code);
            ResourceCost.Type::"Group(Resource)":
                Resource.SetRange("Resource Group No.", ResourceCost.Code);
            ResourceCost.Type::All:
                Resource.Reset();
        end;
        exit(Resource.FindSet());
    end;

    local procedure CreatePriceLinePerResource(var Resource: Record Resource; ResourceCost: Record "Resource Cost"; var TempResourceCost: Record "Resource Cost" temporary; var PriceListLine: Record "Price List Line")
    var
        NewResourceCost: Record "Resource Cost";
        ResourceFindCost: Codeunit "Resource-Find Cost";
    begin
        repeat
            if not IsDuplicateResourceCost(ResourceCost, TempResourceCost, Resource."No.") then begin
                NewResourceCost := ResourceCost;
                NewResourceCost.Type := ResourceCost.Type::Resource;
                NewResourceCost.Code := Resource."No.";
                ResourceFindCost.Run(NewResourceCost);
                TempResourceCost := NewResourceCost;
                if TempResourceCost.Insert() then begin
                    PriceListLine.Init();
                    PriceListLine."Price List Code" := '';
                    PriceListLine."Price Type" := PriceListLine."Price Type"::Purchase;
                    PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"All Vendors");
                    PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
                    PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Resource);
                    PriceListLine.Validate("Asset No.", Resource."No.");
                    if PriceListLine."Asset No." = Resource."No." then
                        if VerifyResourceCostConsistency(ResourceCost) then begin
                            PriceListLine."Work Type Code" := ResourceCost."Work Type Code";
                            PriceListLine."Unit Cost" := NewResourceCost."Unit Cost";
                            PriceListLine."Direct Unit Cost" := NewResourceCost."Direct Unit Cost";
                            PriceListLine."Allow Invoice Disc." := false;
                            PriceListLine."Allow Line Disc." := true;
                            PriceListLine.Status := PriceListLine.Status::Active;
                            OnCopyFromResourceCost(ResourceCost, PriceListLine);
                            InsertPriceListLine(PriceListLine);
                        end;
                end;
            end;
        until Resource.Next() = 0;
    end;

    local procedure IsDuplicateResourceCost(ResourceCost: Record "Resource Cost"; var TempResourceCost: Record "Resource Cost" temporary; ResourceNo: Code[20]): Boolean;
    begin
        if ResourceCost.Type = ResourceCost.Type::Resource then
            exit(false);
        exit(TempResourceCost.Get(TempResourceCost.Type::Resource, ResourceNo, ResourceCost."Work Type Code"));
    end;

#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    procedure CopyFrom(var ResourcePrice: Record "Resource Price"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
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
                PriceListLine."Price List Code" := '';
                PriceListLine.Validate("Source Type", PriceListLine."Source Type"::"All Customers");
                case ResourcePrice.Type of
                    ResourcePrice.Type::All,
                    ResourcePrice.Type::Resource:
                        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Resource);
                    ResourcePrice.Type::"Group(Resource)":
                        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::"Resource Group");
                end;
                PriceListLine.Validate("Asset No.", ResourcePrice.Code);
                if PriceListLine."Asset No." = ResourcePrice.Code then
                    if VerifyResourcePriceConsistency(ResourcePrice) then begin
                        PriceListLine."Currency Code" := ResourcePrice."Currency Code";
                        PriceListLine."Work Type Code" := ResourcePrice."Work Type Code";
                        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
                        PriceListLine."Unit Price" := ResourcePrice."Unit Price";
                        PriceListLine."Allow Invoice Disc." := false;
                        PriceListLine."Allow Line Disc." := true;
                        PriceListLine.Status := PriceListLine.Status::Active;
                        PriceListLine."Price Type" := PriceListLine."Price Type"::Sale;
                        OnCopyFromResourcePrice(ResourcePrice, PriceListLine);
                        InsertPriceListLine(PriceListLine);
                    end;
            until ResourcePrice.Next() = 0;
        ResourcePrice := OrigResourcePrice;
    end;

    local procedure VerifyResourcePriceConsistency(ResourcePrice: Record "Resource Price"): Boolean;
    var
        Currency: Record Currency;
        Resource: Record Resource;
        WorkType: Record "Work Type";
    begin
        if ResourcePrice.Type = ResourcePrice.Type::Resource then begin
            if ResourcePrice.Code = '' then
                exit(false);
            Resource.SetLoadFields("No.");
            if not Resource.Get(ResourcePrice.Code) then
                exit(false);
        end;
        if ResourcePrice."Currency Code" <> '' then
            if not Currency.Get(ResourcePrice."Currency Code") then
                exit(false);
        if ResourcePrice."Work Type Code" <> '' then
            if not WorkType.Get(ResourcePrice."Work Type Code") then
                exit(false);
        exit(true);
    end;

#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    procedure CopyFrom(var PurchasePrice: Record "Purchase Price"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
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
                PriceListLine."Price List Code" := '';
                PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Vendor);
                PriceListLine.Validate("Source No.", PurchasePrice."Vendor No.");
                if PriceListLine."Source No." = PurchasePrice."Vendor No." then begin
                    PriceListLine."Starting Date" := PurchasePrice."Starting Date";
                    PriceListLine."Ending Date" := PurchasePrice."Ending Date";
                    PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
                    PriceListLine.Validate("Asset No.", PurchasePrice."Item No.");
                    if PriceListLine."Asset No." = PurchasePrice."Item No." then
                        if VerifyPurchPriceConsistency(PurchasePrice) then begin
                            PriceListLine.Validate("Variant Code", PurchasePrice."Variant Code");
                            PriceListLine.Validate("Unit of Measure Code", PurchasePrice."Unit of Measure Code");
                            PriceListLine."Amount Type" := PriceListLine."Amount Type"::Price;
                            PriceListLine."Direct Unit Cost" := PurchasePrice."Direct Unit Cost";
                            PriceListLine."Currency Code" := PurchasePrice."Currency Code";
                            PriceListLine."Minimum Quantity" := PurchasePrice."Minimum Quantity";
                            PriceListLine."Allow Invoice Disc." := false;
                            PriceListLine."Allow Line Disc." := true;
                            PriceListLine.Status := PriceListLine.Status::Active;
                            PriceListLine."Price Type" := PriceListLine."Price Type"::Purchase;
                            OnCopyFromPurchasePrice(PurchasePrice, PriceListLine);
                            InsertPriceListLine(PriceListLine);
                        end;
                end;
            until PurchasePrice.Next() = 0;
        PurchasePrice := OrigPurchasePrice;
    end;

    local procedure VerifyPurchPriceConsistency(PurchasePrice: Record "Purchase Price"): Boolean;
    var
        Currency: Record Currency;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemUnitofMeasure: Record "Item Unit of Measure";
        UnitofMeasure: Record "Unit of Measure";
    begin
        if PurchasePrice."Item No." = '' then
            exit(false);
        Item.SetLoadFields("No.");
        if not Item.Get(PurchasePrice."Item No.") then
            exit(false);
        if PurchasePrice."Variant Code" <> '' then
            if not ItemVariant.Get(PurchasePrice."Item No.", PurchasePrice."Variant Code") then
                exit(false);
        if PurchasePrice."Unit of Measure Code" <> '' then begin
            if not UnitofMeasure.Get(PurchasePrice."Unit of Measure Code") then
                exit(false);
            if not ItemUnitofMeasure.Get(PurchasePrice."Item No.", PurchasePrice."Unit of Measure Code") then
                exit(false);
        end;
        if PurchasePrice."Currency Code" <> '' then
            if not Currency.Get(PurchasePrice."Currency Code") then
                exit(false);
        exit(true);
    end;

#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    procedure CopyFrom(var PurchaseLineDiscount: Record "Purchase Line Discount"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
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
                PriceListLine."Price List Code" := '';
                PriceListLine.Validate("Source Type", PriceListLine."Source Type"::Vendor);
                PriceListLine.Validate("Source No.", PurchaseLineDiscount."Vendor No.");
                if PriceListLine."Source No." = PurchaseLineDiscount."Vendor No." then begin
                    PriceListLine."Starting Date" := PurchaseLineDiscount."Starting Date";
                    PriceListLine."Ending Date" := PurchaseLineDiscount."Ending Date";
                    PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
                    PriceListLine.Validate("Asset No.", PurchaseLineDiscount."Item No.");
                    if PriceListLine."Asset No." = PurchaseLineDiscount."Item No." then
                        if VerifyPurchLineDiscConsistency(PurchaseLineDiscount) then begin
                            PriceListLine.Validate("Variant Code", PurchaseLineDiscount."Variant Code");
                            PriceListLine.Validate("Unit of Measure Code", PurchaseLineDiscount."Unit of Measure Code");
                            PriceListLine."Amount Type" := PriceListLine."Amount Type"::Discount;
                            PriceListLine."Line Discount %" := PurchaseLineDiscount."Line Discount %";
                            PriceListLine."Currency Code" := PurchaseLineDiscount."Currency Code";
                            PriceListLine."Minimum Quantity" := PurchaseLineDiscount."Minimum Quantity";
                            PriceListLine."Allow Invoice Disc." := false;
                            PriceListLine."Allow Line Disc." := false;
                            PriceListLine.Status := PriceListLine.Status::Active;
                            PriceListLine."Price Type" := PriceListLine."Price Type"::Purchase;
                            OnCopyFromPurchLineDiscount(PurchaseLineDiscount, PriceListLine);
                            InsertPriceListLine(PriceListLine);
                        end;
                end;
            until PurchaseLineDiscount.Next() = 0;
        PurchaseLineDiscount := OrigPurchaseLineDiscount;
    end;

    local procedure VerifyPurchLineDiscConsistency(PurchaseLineDiscount: Record "Purchase Line Discount"): Boolean;
    var
        Currency: Record Currency;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemUnitofMeasure: Record "Item Unit of Measure";
        UnitofMeasure: Record "Unit of Measure";
    begin
        if PurchaseLineDiscount."Item No." = '' then
            exit(false);
        Item.SetLoadFields("No.");
        if not Item.Get(PurchaseLineDiscount."Item No.") then
            exit(false);
        if PurchaseLineDiscount."Variant Code" <> '' then
            if not ItemVariant.Get(PurchaseLineDiscount."Item No.", PurchaseLineDiscount."Variant Code") then
                exit(false);
        if PurchaseLineDiscount."Unit of Measure Code" <> '' then begin
            if not UnitofMeasure.Get(PurchaseLineDiscount."Unit of Measure Code") then
                exit(false);
            if not ItemUnitofMeasure.Get(PurchaseLineDiscount."Item No.", PurchaseLineDiscount."Unit of Measure Code") then
                exit(false);
        end;
        if PurchaseLineDiscount."Currency Code" <> '' then
            if not Currency.Get(PurchaseLineDiscount."Currency Code") then
                exit(false);
        exit(true);
    end;

    local procedure InsertPriceListLine(var PriceListLine: Record "Price List Line")
    begin
        InitLineNo(PriceListLine);
        PriceListLine.Insert(true);
    end;
#endif

    procedure InitLineNo(var PriceListLine: Record "Price List Line")
    var
        PriceListManagement: Codeunit "Price List Management";
    begin
        if PriceListLine.IsTemporary then
            PriceListLine."Line No." += 10000
        else begin
            SetPriceListCode(PriceListLine);
            PriceListLine.SetNextLineNo();
            if GenerateHeader and UseDefaultPriceLists and (PriceListLine."Line No." > GetMaxPriceLineNo()) then begin
                PriceListLine."Price List Code" :=
                    PriceListManagement.DefineDefaultPriceList(PriceListLine."Price Type", PriceListLine."Source Group");
                PriceListLine.SetNextLineNo();
            end;
        end;
        OnAfterInitLineNo(PriceListLine);
    end;

    local procedure GetMaxPriceLineNo(): Integer;
    begin
        exit(1000000000)
    end;

    local procedure SetPriceListCode(var PriceListLine: Record "Price List Line")
    var
        PriceListHeader: Record "Price List Header";
        PriceListManagement: Codeunit "Price List Management";
    begin
        if GenerateHeader then
            if UseDefaultPriceLists then
                PriceListLine."Price List Code" :=
                    PriceListManagement.GetDefaultPriceListCode(
                        PriceListLine."Price Type", PriceListLine."Source Group", true)
            else begin
                if not FindHeader(PriceListLine, PriceListHeader) then
                    InsertHeader(PriceListLine, PriceListHeader);
                PriceListLine."Price List Code" := PriceListHeader.Code;

                if (PriceListLine."Amount Type" = "Price Amount Type"::Any) and
                    (PriceListHeader."Amount Type" <> "Price Amount Type"::Any)
                then begin
                    PriceListHeader."Amount Type" := "Price Amount Type"::Any;
                    PriceListHeader.Modify();
                end;
            end
    end;

    local procedure FindHeader(PriceListLine: Record "Price List Line"; var PriceListHeader: Record "Price List Header"): Boolean;
    begin
        PriceListHeader.SetRange("Price Type", PriceListLine."Price Type");
        PriceListHeader.SetRange("Source Type", PriceListLine."Source Type");
        PriceListHeader.SetRange("Parent Source No.", PriceListLine."Parent Source No.");
        PriceListHeader.SetRange("Source No.", PriceListLine."Source No.");
        PriceListHeader.SetRange("Starting Date", PriceListLine."Starting Date");
        PriceListHeader.SetRange("Ending Date", PriceListLine."Ending Date");
        PriceListHeader.SetRange("Currency Code", PriceListLine."Currency Code");
        PriceListHeader.SetRange("Amount Type", PriceListLine."Amount Type");
        OnBeforeFindHeader(PriceListLine, PriceListHeader);
        exit(PriceListHeader.FindFirst())
    end;

    local procedure InsertHeader(PriceListLine: Record "Price List Line"; var PriceListHeader: Record "Price List Header")
    var
        PriceSource: Record "Price Source";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        FeatureTelemetry.LogUptake('0000LLR', PriceCalculationMgt.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Used");

        PriceListLine.CopyTo(PriceSource);
        PriceListHeader.CopyFrom(PriceSource);
        GenerateDescription(PriceListHeader);
        PriceListHeader."Amount Type" := PriceListLine."Amount Type";
        PriceListHeader.Status := PriceListHeader.Status::Active;
        OnBeforeInsertHeader(PriceListLine, PriceListHeader);
        PriceListHeader.Insert(true);

        FeatureTelemetry.LogUsage('0000LLR', PriceCalculationMgt.GetFeatureTelemetryName(), 'Price List automatically activated');
    end;

    /// <summary>
    /// Generates the description for the header, e.g. 'Customer 10000, 01.01.2021 - 31.01.2021'
    /// </summary>
    /// <param name="PriceListHeader">the generated header</param>
    local procedure GenerateDescription(var PriceListHeader: Record "Price List Header")
    var
        Description: Text;
    begin
        Description := Format(PriceListHeader."Source Type");
        if PriceListHeader."Parent Source No." <> '' then
            Description += StrSubstNo(PlaceHolderBracketTok, PriceListHeader."Parent Source No.");
        if PriceListHeader."Source No." <> '' then
            Description += StrSubstNo(PlaceHolderTok, PriceListHeader."Source No.");
        if PriceListHeader."Starting Date" <> 0D then
            Description += StrSubstNo(PlaceHolderRangeTok, PriceListHeader."Starting Date", PriceListHeader."Ending Date");
        PriceListHeader.Description := CopyStr(Description, 1, MaxStrLen(PriceListHeader.Description));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitLineNo(var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindHeader(PriceListLine: Record "Price List Line"; var PriceListHeader: Record "Price List Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertHeader(PriceListLine: Record "Price List Line"; var PriceListHeader: Record "Price List Header")
    begin
    end;

#if not CLEAN23
    [IntegrationEvent(false, false)]
#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    local procedure OnCopyFromPurchLineDiscount(PurchaseLineDiscount: Record "Purchase Line Discount"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
    begin
    end;

    [IntegrationEvent(false, false)]
#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    local procedure OnCopyFromPurchasePrice(PurchasePrice: Record "Purchase Price"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
    begin
    end;

    [IntegrationEvent(false, false)]
#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    local procedure OnCopyFromResourceCost(ResourceCost: Record "Resource Cost"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
    begin
    end;

    [IntegrationEvent(false, false)]
#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    local procedure OnCopyFromResourcePrice(ResourcePrice: Record "Resource Price"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
    begin
    end;

    [IntegrationEvent(false, false)]
#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    local procedure OnCopyFromJobItemPrice(var JobItemPrice: Record "Job Item Price"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
    begin
    end;

    [IntegrationEvent(false, false)]
#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    local procedure OnCopyFromJobGLAccountPrice(var JobGLAccountPrice: Record "Job G/L Account Price"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
    begin
    end;

    [IntegrationEvent(false, false)]
#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    local procedure OnCopyFromJobResourcePrice(var JobResourcePrice: Record "Job Resource Price"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
    begin
    end;

    [IntegrationEvent(false, false)]
#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    local procedure OnCopyFromSalesPrice(var SalesPrice: Record "Sales Price"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
    begin
    end;

    [IntegrationEvent(false, false)]
#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    local procedure OnCopyToSalesPrice(var SalesPrice: Record "Sales Price"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
    begin
    end;

    [IntegrationEvent(false, false)]
#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    local procedure OnCopyFromSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
    begin
    end;

    [IntegrationEvent(false, false)]
#pragma warning disable AS0072
    [Obsolete('Will be removed along with the obsolete price tables.', '19.0')]
    local procedure OnCopyToSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount"; var PriceListLine: Record "Price List Line")
#pragma warning restore AS0072
    begin
    end;
#endif
}
