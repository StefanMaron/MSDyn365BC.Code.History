table 7022 "Price Worksheet Line"
{
    fields
    {
        field(1; "Price List Code"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Price List Header";
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(3; "Source Type"; Enum "Price Source Type")
        {
            Caption = 'Applies-to Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Source Type"));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Source Type", "Source Type");
                CopyFrom(PriceSource);
                "Amount Type" := PriceSource.GetDefaultAmountType();
                if "Asset No." <> '' then begin
                    CopyTo(PriceAsset);
                    PriceAsset.ValidateAssetNo();
                    CopyFrom(PriceAsset);
                end;
            end;
        }
        field(4; "Source No."; Code[20])
        {
            Caption = 'Applies-to No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Source No."));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Source No.", "Source No.");
                CopyFrom(PriceSource);
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceSource);
                if PriceSource.LookupNo() then begin
                    TestHeadersValue(FieldNo("Source No."));
                    CopyFrom(PriceSource);
                end;
            end;
        }
        field(5; "Parent Source No."; Code[20])
        {
            Caption = 'Applies-to Parent No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Parent Source No."));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Parent Source No.", "Parent Source No.");
                CopyFrom(PriceSource);
            end;

            trigger OnLookup()
            var
                ParentPriceSource: Record "Price Source";
            begin
                CopyRecTo(PriceSource);
                if not PriceSource.IsParentSourceAllowed() then
                    exit;

                ParentPriceSource."Source Group" := "Source Group";
                ParentPriceSource."Source Type" := PriceSource.GetParentSourceType();
                if ParentPriceSource.LookupNo() then begin
                    "Parent Source No." := ParentPriceSource."Source No.";
                    "Source No." := '';
                    TestHeadersValue(FieldNo("Parent Source No."));
                end;
            end;
        }
        field(6; "Source ID"; Guid)
        {
            Caption = 'Applies-to ID';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Source ID"));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Source ID", "Source ID");
                CopyFrom(PriceSource);
            end;
        }
        field(7; "Asset Type"; Enum "Price Asset Type")
        {
            Caption = 'Product Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CopyRecTo(PriceAsset);
                PriceAsset.Validate("Asset Type", "Asset Type");
                CopyFrom(PriceAsset);

                InitHeaderDefaults();
                TestStatusDraft();

                if "Asset Type" = "Asset Type"::"Item Discount Group" then
                    Validate("Amount Type", "Amount Type"::Discount);
            end;
        }
        field(8; "Asset No."; Code[20])
        {
            Caption = 'Product No.';
            DataClassification = CustomerContent;
            NotBlank = true;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CopyRecTo(PriceAsset);
                PriceAsset.Validate("Asset No.", "Asset No.");
                CopyFrom(PriceAsset);
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupNo() then begin
                    TestStatusDraft();
                    CopyFrom(PriceAsset);
                end;
            end;
        }
        field(9; "Variant Code"; Code[10])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CopyRecTo(PriceAsset);
                PriceAsset.Validate("Variant Code", "Variant Code");
                CopyFrom(PriceAsset);
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupVariantCode() then begin
                    TestStatusDraft();
                    CopyFrom(PriceAsset);
                end;
            end;
        }
        field(10; "Currency Code"; Code[10])
        {
            DataClassification = CustomerContent;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" = xRec."Currency Code" then
                    exit;
                TestHeadersValue(FieldNo("Currency Code"));
            end;
        }
        field(11; "Work Type Code"; Code[10])
        {
            DataClassification = CustomerContent;
            TableRelation = "Work Type";
            trigger OnValidate()
            begin
                TestStatusDraft();
                CopyRecTo(PriceAsset);
                PriceAsset.Validate("Work Type Code", "Work Type Code");
                CopyFrom(PriceAsset);
            end;
        }
        field(12; "Starting Date"; Date)
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Starting Date"));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Starting Date", "Starting Date");
                CopyFrom(PriceSource);
            end;
        }
        field(13; "Ending Date"; Date)
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Ending Date"));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Ending Date", "Ending Date");
                CopyFrom(PriceSource);
            end;
        }
        field(14; "Minimum Quantity"; Decimal)
        {
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(15; "Unit of Measure Code"; Code[10])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CopyRecTo(PriceAsset);
                PriceAsset.Validate("Unit of Measure Code", "Unit of Measure Code");
                CopyFrom(PriceAsset);
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupUnitofMeasure() then begin
                    TestStatusDraft();
                    "Unit of Measure Code" := PriceAsset."Unit of Measure Code";
                end;
            end;
        }
        field(16; "Amount Type"; Enum "Price Amount Type")
        {
            Caption = 'Defines';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Amount Type" = xRec."Amount Type" then
                    exit;

                TestStatusDraft();
                VerifyAmountTypeForSourceType("Amount Type");
                if "Asset Type" = "Asset Type"::"Item Discount Group" then
                    TestField("Amount Type", "Amount Type"::Discount);

                case "Amount Type" of
                    "Amount Type"::Price:
                        begin
                            "Line Discount %" := 0;
                            GetValueFromHeader(FieldNo("Allow Invoice Disc."));
                            GetValueFromHeader(FieldNo("Allow Line Disc."));
                        end;
                    "Amount Type"::Discount:
                        begin
                            "Unit Price" := 0;
                            "Cost Factor" := 0;
                            "Allow Invoice Disc." := false;
                            "Allow Line Disc." := false;
                        end;
                end;
            end;
        }
        field(17; "Unit Price"; Decimal)
        {
            AccessByPermission = tabledata "Sales Price Access" = R;
            DataClassification = CustomerContent;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Unit Price"), "Amount Type"::Discount);
                if "Unit Price" <> 0 then
                    "Cost Factor" := 0;
            end;
        }
        field(18; "Cost Factor"; Decimal)
        {
            AccessByPermission = tabledata "Sales Price Access" = R;
            DataClassification = CustomerContent;
            Caption = 'Cost Factor';

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Cost Factor"), "Amount Type"::Discount);
                TestField("Source Group", "Source Group"::Job);
                if "Cost Factor" <> 0 then
                    "Unit Price" := 0;
            end;
        }
        field(19; "Unit Cost"; Decimal)
        {
            AccessByPermission = tabledata "Purchase Price Access" = R;
            DataClassification = CustomerContent;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckAmountType(FieldCaption("Unit Cost"), "Amount Type"::Discount);
            end;
        }
        field(20; "Line Discount %"; Decimal)
        {
            DataClassification = CustomerContent;
            AutoFormatType = 2;
            Caption = 'Line Discount %';
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Line Discount %"), "Amount Type"::Price);
            end;
        }
        field(21; "Allow Line Disc."; Boolean)
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Allow Line Disc."), "Amount Type"::Discount);
            end;
        }
        field(22; "Allow Invoice Disc."; Boolean)
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                CheckAmountType(FieldCaption("Allow Invoice Disc."), "Amount Type"::Discount);
            end;
        }
        field(23; "Price Includes VAT"; Boolean)
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Price Includes VAT"));
            end;
        }
        field(24; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("VAT Bus. Posting Gr. (Price)"));
            end;
        }
        field(25; "VAT Prod. Posting Group"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(26; "Asset ID"; Guid)
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                TestStatusDraft();
                CopyRecTo(PriceAsset);
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

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Price Type"));
            end;
        }
        field(29; Description; Text[100])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(30; Status; Enum "Price Status")
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo(Status));
            end;
        }
        field(31; "Direct Unit Cost"; Decimal)
        {
            AccessByPermission = tabledata "Purchase Price Access" = R;
            DataClassification = CustomerContent;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckAmountType(FieldCaption("Direct Unit Cost"), "Amount Type"::Discount);
            end;
        }
        field(32; "Source Group"; Enum "Price Source Group")
        {
            DataClassification = CustomerContent;
        }
        field(100; "Existing Line"; Boolean)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if not "Existing Line" then begin
                    "Price List Code" := '';
                    Status := Status::Draft;
                    "Line No." := 0;
                end;
            end;
        }
        field(101; "Existing Unit Price"; Decimal)
        {
            AccessByPermission = tabledata "Sales Price Access" = R;
            DataClassification = CustomerContent;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Existing Unit Price';
            Editable = false;
            BlankZero = true;
        }
        field(102; "Existing Direct Unit Cost"; Decimal)
        {
            AccessByPermission = tabledata "Purchase Price Access" = R;
            DataClassification = CustomerContent;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Existing Direct Unit Cost';
            Editable = false;
            BlankZero = true;
        }
        field(103; "Existing Unit Cost"; Decimal)
        {
            AccessByPermission = tabledata "Purchase Price Access" = R;
            DataClassification = CustomerContent;
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Existing Unit Cost';
            Editable = false;
            BlankZero = true;
        }
    }

    keys
    {
        key(PK; "Price List Code", "Existing Line", "Line No.")
        {
            Clustered = true;
        }
        key(Key1; "Price Type", "Source Group")
        {
        }
    }

    trigger OnInsert()
    var
        PriceListManagement: Codeunit "Price List Management";
    begin
        if "Price List Code" = '' then
            "Price List Code" := PriceListManagement.GetDefaultPriceListCode("Price Type", "Source Group", false);
    end;

    protected var
        PriceListHeader: Record "Price List Header";
        PriceAsset: Record "Price Asset";
        PriceSource: Record "Price Source";

    var
        IsNewRecord: Boolean;
        FieldNotAllowedForAmountTypeErr: Label 'Field %1 is not allowed in the price list line where %2 is %3.',
            Comment = '%1 - the field caption; %2 - Amount Type field caption; %3 - amount type value: Discount or Price';
        LineSourceTypeErr: Label 'cannot be set to %1 if the header''s source type is %2.', Comment = '%1 and %2 - the source type value.';

    procedure IsAssetItem(): Boolean;
    begin
        exit("Asset Type" = "Asset Type"::Item);
    end;

    procedure IsAssetResource(): Boolean;
    begin
        exit("Asset Type" in ["Asset Type"::Resource, "Asset Type"::"Resource Group"]);
    end;

    procedure IsEditable() Result: Boolean;
    begin
        Result := (Status = Status::Draft) or (Status = Status::Active) and IsAllowedEditingActivePrice();
    end;

    procedure IsHeaderActive() Result: Boolean;
    begin
        GetHeader();
        exit(PriceListHeader.Status = "Price Status"::Active);
    end;

    procedure IsLineToVerify() Result: Boolean;
    begin
        Result := (Status = Status::Draft) and IsHeaderActive();
    end;

    local procedure IsAllowedEditingActivePrice(): Boolean;
    var
        PriceListManagement: Codeunit "Price List Management";
    begin
        exit(PriceListManagement.IsAllowedEditingActivePrice("Price Type"));
    end;

    procedure IsUOMSupported(): Boolean;
    begin
        exit(IsAssetItem() or IsAssetResource());
    end;

    procedure IsAmountMandatory(AmountType: enum "Price Amount Type"): Boolean;
    begin
        case "Amount Type" of
            "Amount Type"::Any:
                exit(true)
            else
                exit(AmountType = "Amount Type");
        end;
    end;

    procedure IsAmountSupported(): Boolean;
    begin
        exit("Asset Type" <> "Asset Type"::"Item Discount Group");
    end;

    procedure IsRealLine(): Boolean;
    begin
        exit("Line No." <> 0);
    end;

    procedure IsSourceNoAllowed(): Boolean;
    var
        PriceSourceInterface: Interface "Price Source";
    begin
        PriceSourceInterface := "Source Type";
        exit(PriceSourceInterface.IsSourceNoAllowed());
    end;

    local procedure CheckAmountType(FldCaption: Text; AmountType: Enum "Price Amount Type")
    begin
        if "Amount Type" = AmountType then
            Error(FieldNotAllowedForAmountTypeErr, FldCaption, FieldCaption("Amount Type"), Format("Amount Type"));
    end;

    procedure CopyExistingPrices(PriceListLine: Record "Price List Line")
    begin
        "Existing Unit Price" := PriceListLine."Unit Price";
        "Existing Direct Unit Cost" := PriceListLine."Direct Unit Cost";
        "Existing Unit Cost" := PriceListLine."Unit Cost";
    end;

    procedure CopySourceFrom(PriceListHeader: Record "Price List Header")
    begin
        "Source Group" := PriceListHeader."Source Group";
        "Source Type" := PriceListHeader."Source Type";
        "Parent Source No." := PriceListHeader."Parent Source No.";
        "Source No." := PriceListHeader."Source No.";
        "Source ID" := PriceListHeader."Source ID";
    end;

    procedure CopyFrom(PriceListHeader: Record "Price List Header")
    begin
        "Price Type" := PriceListHeader."Price Type";
        Status := "Price Status"::Draft;
        if not PriceListHeader."Allow Updating Defaults" then begin
            CopySourceFrom(PriceListHeader);
            "Starting Date" := PriceListHeader."Starting Date";
            "Ending Date" := PriceListHeader."Ending Date";
            "Currency Code" := PriceListHeader."Currency Code";
        end;
        if PriceListHeader."Amount Type" <> "Price Amount Type"::Any then
            Validate("Amount Type", PriceListHeader."Amount Type");

        "Price Includes VAT" := PriceListHeader."Price Includes VAT";
        "VAT Bus. Posting Gr. (Price)" := PriceListHeader."VAT Bus. Posting Gr. (Price)";
        "Allow Invoice Disc." := PriceListHeader."Allow Invoice Disc.";
        "Allow Line Disc." := PriceListHeader."Allow Line Disc.";
        OnAfterCopyFromPriceListHeader(PriceListHeader);
    end;

    local procedure CopyFrom(PriceSource: Record "Price Source")
    begin
        "Price Type" := PriceSource."Price Type";
        "Source Group" := PriceSource."Source Group";
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

    procedure CopyFrom(PriceAsset: Record "Price Asset")
    begin
        "Price Type" := PriceAsset."Price Type";
        "Asset Type" := PriceAsset."Asset Type";
        "Asset No." := PriceAsset."Asset No.";
        "Asset ID" := PriceAsset."Asset ID";
        Description := PriceAsset.Description;
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

    procedure SetNewRecord(NewRecord: Boolean)
    begin
        IsNewRecord := NewRecord;
    end;

    local procedure CopyRecTo(var PriceAsset: Record "Price Asset")
    begin
        if IsNewRecord then
            CopyTo(PriceAsset)
        else
            xRec.CopyTo(PriceAsset);
    end;

    local procedure CopyRecTo(var PriceSource: Record "Price Source")
    begin
        if IsNewRecord then
            CopyTo(PriceSource)
        else
            xRec.CopyTo(PriceSource);
    end;

    procedure CopyTo(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset."Price Type" := "Price Type";
        PriceAsset."Asset Type" := "Asset Type";
        PriceAsset."Asset No." := "Asset No.";
        PriceAsset.Description := Description;
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
        PriceSource."Source Group" := "Source Group";
        PriceSource.Validate("Source Type", "Source Type");
        PriceSource."Parent Source No." := "Parent Source No.";
        PriceSource."Source No." := "Source No.";
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

    local procedure GetHeader(): Boolean;
    begin
        if "Price List Code" <> '' then begin
            if PriceListHeader.Code <> "Price List Code" then
                exit(PriceListHeader.Get("Price List Code"));
            exit(true);
        end;

        Clear(PriceListHeader);
    end;

    local procedure GetValueFromHeader(FieldId: Integer)
    begin
        if not GetHeader() then
            exit;
        case FieldId of
            FieldNo("Allow Invoice Disc."):
                "Allow Invoice Disc." := PriceListHeader."Allow Invoice Disc.";
            FieldNo("Allow Line Disc."):
                "Allow Line Disc." := PriceListHeader."Allow Line Disc.";
        end;
    end;

    local procedure InitHeaderDefaults()
    begin
        if GetHeader() then
            CopyFrom(PriceListHeader);

        OnAfterInitHeaderDefaults(PriceListHeader);
    end;

    local procedure IsSourceTypeSupported(): Boolean;
    var
        PriceSourceGroup: Interface "Price Source Group";
    begin
        PriceSourceGroup := PriceListHeader."Source Group";
        exit(PriceSourceGroup.IsSourceTypeSupported("Source Type"));
    end;

    local procedure TestHeadersValue(FieldId: Integer)
    var
        LineSourceTypeError: Text;
    begin
        if not GetHeader() then
            exit;

        TestStatusDraft();
        case FieldId of
            FieldNo("Source Group"):
                TestField("Source Group", PriceListHeader."Source Group");
            FieldNo(Status):
                TestField(Status, PriceListHeader.Status);
            FieldNo("Price Includes VAT"):
                TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
            FieldNo("VAT Bus. Posting Gr. (Price)"):
                TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");
        end;
        if not PriceListHeader."Allow Updating Defaults" then
            case FieldId of
                FieldNo("Currency Code"):
                    TestField("Currency Code", PriceListHeader."Currency Code");
                FieldNo("Starting Date"):
                    TestField("Starting Date", PriceListHeader."Starting Date");
                FieldNo("Ending Date"):
                    TestField("Ending Date", PriceListHeader."Ending Date");
                FieldNo("Source Type"):
                    if PriceListHeader."Source No." <> '' then
                        TestField("Source Type", PriceListHeader."Source Type")
                    else begin
                        LineSourceTypeError :=
                            StrSubstNo(LineSourceTypeErr, "Source Type", PriceListHeader."Source Type");
                        if "Source Type".AsInteger() < PriceListHeader."Source Type".AsInteger() then
                            FieldError("Source Type", LineSourceTypeError);
                        if not IsSourceTypeSupported() then
                            FieldError("Source Type", LineSourceTypeError);
                    end;
                FieldNo("Source No."):
                    if PriceListHeader."Source No." <> '' then
                        TestField("Source No.", PriceListHeader."Source No.");
                FieldNo("Source Id"):
                    if PriceListHeader."Source No." <> '' then
                        TestField("Source Id", PriceListHeader."Source Id");
                FieldNo("Parent Source No."):
                    if PriceListHeader."Parent Source No." <> '' then
                        TestField("Parent Source No.", PriceListHeader."Parent Source No.");
            end;
    end;

    local procedure TestStatusDraft()
    begin
        if not IsEditable() then
            TestField(Status, Status::Draft);
    end;

    procedure Verify(): Boolean;
    begin
        if "Asset Type" <> "Asset Type"::" " then
            if "Asset No." = '' then
                exit(false);
        exit(VerifySource());
    end;

    local procedure VerifyParentSource() Result: Boolean;
    var
        PriceSourceLocal: Record "Price Source";
        PriceSourceInterface: Interface "Price Source";
    begin
        CopyTo(PriceSourceLocal);
        PriceSourceInterface := "Source Type";
        Result := PriceSourceInterface.VerifyParent(PriceSourceLocal);
    end;

    local procedure VerifyAmountTypeForSourceType(AmountType: Enum "Price Amount Type")
    begin
        CopyTo(PriceSource);
        PriceSource.VerifyAmountTypeForSourceType(AmountType);
    end;

    local procedure VerifySource(): Boolean;
    begin
        if VerifyParentSource() then begin
            if "Parent Source No." = '' then
                exit(false);
        end else
            if "Parent Source No." <> '' then
                exit(false);

        if IsSourceNoAllowed() then begin
            if "Source No." = '' then
                exit(false)
        end else
            if "Source No." <> '' then
                exit(false);
        exit(true);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyFromPriceAsset(PriceAsset: Record "Price Asset")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyFromPriceListHeader(PriceListHeader: Record "Price List Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyFromPriceSource(PriceSource: Record "Price Source")
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

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitHeaderDefaults(PriceListHeader: Record "Price List Header")
    begin
    end;
}