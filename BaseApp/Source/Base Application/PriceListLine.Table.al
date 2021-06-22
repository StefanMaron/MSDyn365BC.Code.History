table 7001 "Price List Line"
{
    fields
    {
        field(1; "Price List Code"; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(3; "Source Type"; Enum "Price Source Type")
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                if xRec."Source Type" = "Source Type" then
                    exit;

                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Source Type", "Source Type");
                CopyFrom(PriceSource);
                if "Asset No." <> '' then begin
                    CopyTo(PriceAsset);
                    PriceAsset.ValidateAssetNo();
                    CopyFrom(PriceAsset);
                end;
            end;
        }
        field(4; "Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Source No.", "Source No.");
                CopyFrom(PriceSource);
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceSource);
                if PriceSource.LookupNo() then
                    CopyFrom(PriceSource);
            end;
        }
        field(5; "Parent Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Parent Source No.", "Parent Source No.");
                CopyFrom(PriceSource);
            end;
        }
        field(6; "Source ID"; Guid)
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Source ID", "Source ID");
                CopyFrom(PriceSource);
            end;
        }
        field(7; "Asset Type"; Enum "Price Asset Type")
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                xRec.CopyTo(PriceAsset);
                PriceAsset.Validate("Asset Type", "Asset Type");
                CopyFrom(PriceAsset);
            end;
        }
        field(8; "Asset No."; Code[20])
        {
            DataClassification = CustomerContent;
            NotBlank = true;
            trigger OnValidate()
            begin
                xRec.CopyTo(PriceAsset);
                PriceAsset.Validate("Asset No.", "Asset No.");
                CopyFrom(PriceAsset);
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupNo() then
                    CopyFrom(PriceAsset);
            end;
        }
        field(9; "Variant Code"; Code[10])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                xRec.CopyTo(PriceAsset);
                PriceAsset.Validate("Variant Code", "Variant Code");
                CopyFrom(PriceAsset);
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupVariantCode() then
                    CopyFrom(PriceAsset);
            end;
        }
        field(10; "Currency Code"; Code[10])
        {
            DataClassification = CustomerContent;
            TableRelation = Currency;
        }
        field(11; "Work Type Code"; Code[10])
        {
            DataClassification = CustomerContent;
            TableRelation = "Work Type";
            trigger OnValidate()
            var
                WorkType: record "Work Type";
            begin
                if "Work Type Code" = '' then
                    "Unit of Measure Code" := ''
                else begin
                    WorkType.Get("Work Type Code");
                    "Unit of Measure Code" := WorkType."Unit of Measure Code";
                end;
            end;
        }
        field(12; "Starting Date"; Date)
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                VerifyDates();
            end;
        }
        field(13; "Ending Date"; Date)
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                VerifyDates();
            end;
        }
        field(14; "Minimum Quantity"; Decimal)
        {
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(15; "Unit of Measure Code"; Code[10])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                xRec.CopyTo(PriceAsset);
                PriceAsset.Validate("Unit of Measure Code", "Unit of Measure Code");
                CopyFrom(PriceAsset);
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupUnitofMeasure() then
                    "Unit of Measure Code" := PriceAsset."Unit of Measure Code";
            end;
        }
        field(16; "Amount Type"; Enum "Price Amount Type")
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Amount Type" <> xRec."Amount Type" then
                    exit;
                case "Amount Type" of
                    "Amount Type"::Price:
                        begin
                            "Unit Cost" := 0;
                            "Line Discount %" := 0;
                        end;
                    "Amount Type"::Cost:
                        begin
                            "Unit Price" := 0;
                            "Line Discount %" := 0;
                        end;
                    "Amount Type"::Discount:
                        begin
                            "Unit Cost" := 0;
                            "Unit Price" := 0;
                        end;
                end;
            end;
        }
        field(17; "Unit Price"; Decimal)
        {
            DataClassification = CustomerContent;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Source Type" in ["Source Type"::"All Jobs", "Source Type"::Job, "Source Type"::"Job Task"] then
                    "Cost Factor" := 0;
            end;
        }
        field(18; "Cost Factor"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Cost Factor';

            trigger OnValidate()
            begin
                if "Source Type" in ["Source Type"::"All Jobs", "Source Type"::Job, "Source Type"::"Job Task"] then
                    "Unit Price" := 0;
            end;
        }
        field(19; "Unit Cost"; Decimal)
        {
            DataClassification = CustomerContent;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            MinValue = 0;
        }
        field(20; "Line Discount %"; Decimal)
        {
            DataClassification = CustomerContent;
            AutoFormatType = 2;
            Caption = 'Line Discount %';
            MaxValue = 100;
            MinValue = 0;
        }
        field(21; "Allow Line Disc."; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(22; "Allow Invoice Disc."; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(23; "Price Includes VAT"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(24; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "VAT Business Posting Group";
        }
        field(25; "VAT Prod. Posting Group"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "VAT Product Posting Group";
        }
        field(26; "Asset ID"; Guid)
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                xRec.CopyTo(PriceAsset);
                PriceAsset.Validate("Asset ID", "Asset ID");
                CopyFrom(PriceAsset);
            end;
        }
        field(27; "Line Amount"; Decimal)
        {
            DataClassification = CustomerContent;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Line Amount';
            MinValue = 0;
            Editable = false;
        }
        field(28; "Price Type"; Enum "Price Type")
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Price List Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key1; "Asset Type", "Asset No.", "Source Type", "Source No.", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity")
        {
        }
        key(Key2; "Source Type", "Source No.", "Asset Type", "Asset No.", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity")
        {
        }
    }

    trigger OnInsert()
    begin
        if IsTemporary then
            "Line No." := "Line No." + 1
        else
            "Line No." := 0;
    end;

    protected var
        PriceAsset: Record "Price Asset";
        PriceSource: Record "Price Source";

    var
        StartingDateErr: Label 'Starting Date cannot be after Ending Date.';
        CampaignDateErr: Label 'If Source Type is Campaign, then you can only change Starting Date and Ending Date from the Campaign Card.';

    procedure IsRealLine(): Boolean;
    begin
        exit("Line No." <> 0);
    end;

    local procedure CopyFrom(PriceSource: Record "Price Source")
    begin
        "Price Type" := PriceSource."Price Type";
        "Source Type" := PriceSource."Source Type";
        "Source No." := PriceSource."Source No.";
        "Parent Source No." := PriceSource."Parent Source No.";
        "Source ID" := PriceSource."Source ID";

        "Currency Code" := PriceSource."Currency Code";
        "Price Includes VAT" := PriceSource."Price Includes VAT";
        "Allow Invoice Disc." := PriceSource."Allow Invoice Disc.";
        "Allow Line Disc." := PriceSource."Allow Line Disc.";
        "VAT Bus. Posting Gr. (Price)" := PriceSource."VAT Bus. Posting Gr. (Price)";
        "Starting Date" := PriceSource."Starting Date";
        "Ending Date" := PriceSource."Ending Date";
        OnAfterCopyFromPriceSource(PriceSource);
    end;

    local procedure CopyFrom(PriceAsset: Record "Price Asset")
    begin
        "Price Type" := PriceAsset."Price Type";
        "Asset Type" := PriceAsset."Asset Type";
        "Asset No." := PriceAsset."Asset No.";
        "Asset ID" := PriceAsset."Asset ID";
        "Unit of Measure Code" := PriceAsset."Unit of Measure Code";
        "Variant Code" := PriceAsset."Variant Code";
        "Work Type Code" := PriceAsset."Work Type Code";

        "Allow Invoice Disc." := PriceAsset."Allow Invoice Disc.";
        if "VAT Bus. Posting Gr. (Price)" = '' then begin
            "Price Includes VAT" := PriceAsset."Price Includes VAT";
            "VAT Bus. Posting Gr. (Price)" := PriceAsset."VAT Bus. Posting Gr. (Price)";
        end;
        OnAfterCopyFromPriceAsset(PriceAsset);
    end;

    procedure CopyTo(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset."Price Type" := "Price Type";
        PriceAsset."Asset Type" := "Asset Type";
        PriceAsset."Asset No." := "Asset No.";
        PriceAsset."Asset ID" := "Asset ID";
        PriceAsset."Unit of Measure Code" := "Unit of Measure Code";
        PriceAsset."Variant Code" := "Variant Code";
        PriceAsset."Work Type Code" := "Work Type Code";

        PriceAsset."Allow Invoice Disc." := "Allow Invoice Disc.";
        PriceAsset."Price Includes VAT" := "Price Includes VAT";
        PriceAsset."VAT Bus. Posting Gr. (Price)" := "VAT Bus. Posting Gr. (Price)";
        OnAfterCopyToPriceAsset(PriceAsset);
    end;

    procedure CopyTo(var PriceSource: Record "Price Source")
    begin
        PriceSource."Price Type" := "Price Type";
        PriceSource."Source Type" := "Source Type";
        PriceSource."Source No." := "Source No.";
        PriceSource."Parent Source No." := "Parent Source No.";
        PriceSource."Source ID" := "Source ID";

        PriceSource."Currency Code" := "Currency Code";
        PriceSource."Price Includes VAT" := "Price Includes VAT";
        PriceSource."Allow Invoice Disc." := "Allow Invoice Disc.";
        PriceSource."Allow Line Disc." := "Allow Line Disc.";
        PriceSource."VAT Bus. Posting Gr. (Price)" := "VAT Bus. Posting Gr. (Price)";
        PriceSource."Starting Date" := "Starting Date";
        PriceSource."Ending Date" := "Ending Date";
        OnAfterCopyToPriceSource(PriceSource);
    end;

    procedure CopyFilteredLinesToTemporaryBuffer(var TempPriceListLine: Record "Price List Line" temporary) Copied: Boolean;
    begin
        if FindSet() then
            repeat
                TempPriceListLine := Rec;
                if TempPriceListLine.Insert() then
                    Copied := true;
            until Next() = 0;
    end;

    local procedure VerifyDates()
    begin
        if (CurrFieldNo <> 0) and ("Source Type" = "Source Type"::Campaign) then
            Error(CampaignDateErr);
        if ("Ending Date" <> 0D) and ("Starting Date" <> 0D) and ("Ending Date" < "Starting Date") then
            Error(StartingDateErr);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyFromPriceSource(PriceSource: Record "Price Source")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyFromPriceAsset(PriceAsset: Record "Price Asset")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyToPriceAsset(var PriceAsset: Record "Price Asset")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyToPriceSource(var PriceSource: Record "Price Source")
    begin
    end;
}