table 7001 "Price List Line"
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
            Caption = 'Assign-to Type';
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
            Caption = 'Assign-to No. (custom)';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Source No."));
                if not FieldLookedUp then begin
                    CopyRecTo(PriceSource);
                    PriceSource.Validate("Source No.", "Source No.");
                end;
                CopyFrom(PriceSource);
                "Assign-to No." := "Source No.";
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceSource);
                if PriceSource.LookupNo() then begin
                    FieldLookedUp := true;
                    Validate("Source No.", PriceSource."Source No.");
                    FieldLookedUp := false;
                end;
            end;
        }
        field(5; "Parent Source No."; Code[20])
        {
            Caption = 'Assign-to Parent No. (custom)';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestHeadersValue(FieldNo("Parent Source No."));
                CopyRecTo(PriceSource);
                PriceSource.Validate("Parent Source No.", "Parent Source No.");
                CopyFrom(PriceSource);
                "Assign-to Parent No." := "Parent Source No.";
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
                if ParentPriceSource.LookupNo() then
                    Validate("Parent Source No.", ParentPriceSource."Source No.");
            end;
        }
        field(6; "Source ID"; Guid)
        {
            Caption = 'Assign-to ID';
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
            InitValue = Item;

            trigger OnValidate()
            begin
                if "Asset Type" = "Asset Type"::" " then
                    "Asset Type" := "Asset Type"::Item;

                CopyRecTo(PriceAsset);
                PriceAsset.Validate("Asset Type", "Asset Type");
                CopyFrom(PriceAsset);

                InitHeaderDefaults();
                TestStatusDraft();
            end;
        }
        field(8; "Asset No."; Code[20])
        {
            Caption = 'Product No. (custom)';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                if not FieldLookedUp then begin
                    CopyRecTo(PriceAsset);
                    PriceAsset.Validate("Asset No.", "Asset No.");
                end;
                CopyFrom(PriceAsset);
                "Product No." := "Asset No.";
                "Variant Code Lookup" := "Variant Code";
                "Unit of Measure Code Lookup" := "Unit of Measure Code";
            end;

            trigger OnLookup()
            begin
                PriceCalculationMgt.FeatureCustomizedLookupUsage(Database::"Price List Line");
                CopyTo(PriceAsset);
                if PriceAsset.LookupNo() then begin
                    FieldLookedUp := true;
                    Validate("Asset No.", PriceAsset."Asset No.");
                    FieldLookedUp := false;
                end;
            end;
        }
        field(9; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code (custom)';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                if not FieldLookedUp then begin
                    CopyRecTo(PriceAsset);
                    PriceAsset.Validate("Variant Code", "Variant Code");
                end;
                CopyFrom(PriceAsset);
                "Variant Code Lookup" := "Variant Code";
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupVariantCode() then begin
                    FieldLookedUp := true;
                    Validate("Variant Code", PriceAsset."Variant Code");
                    FieldLookedUp := false;
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
            Caption = 'Unit of Measure Code (custom)';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
                if not FieldLookedUp then begin
                    CopyRecTo(PriceAsset);
                    PriceAsset.Validate("Unit of Measure Code", "Unit of Measure Code");
                end;
                CopyFrom(PriceAsset);
                UpdateUnitPriceByCostPlusPct();
                "Unit of Measure Code Lookup" := "Unit of Measure Code";
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupUnitofMeasure() then begin
                    FieldLookedUp := true;
                    Validate("Unit of Measure Code", PriceAsset."Unit of Measure Code");
                    FieldLookedUp := false;
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
                if PriceAsset."Amount Type" <> "Price Amount Type"::Any then
                    TestField("Amount Type", PriceAsset."Amount Type");

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
                Verify();
                if "Unit Price" <> 0 then
                    "Cost Factor" := 0;

                "Cost-plus %" := 0;
                "Discount Amount" := 0;
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
                Verify();
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
                TestStatusDraft();
                CheckAmountType(FieldCaption("Unit Cost"), "Amount Type"::Discount);
                Verify();
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
                Verify();
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
                TestStatusDraft();
                CheckAmountType(FieldCaption("Direct Unit Cost"), "Amount Type"::Discount);
                Verify();
            end;
        }
        field(32; "Source Group"; Enum "Price Source Group")
        {
            DataClassification = CustomerContent;
        }
        field(33; "Product No."; Code[20])
        {
            Caption = 'Product No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Asset Type" = CONST(Item)) Item where("No." = field("Product No."))
            ELSE
            IF ("Asset Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Asset Type" = CONST(Resource)) Resource
            ELSE
            IF ("Asset Type" = CONST("Resource Group")) "Resource Group"
            ELSE
            IF ("Asset Type" = CONST("Item Discount Group")) "Item Discount Group"
            ELSE
            IF ("Asset Type" = CONST("Service Cost")) "Service Cost";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                Validate("Asset No.", "Product No.");
            end;
        }
        field(34; "Assign-to No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = IF ("Source Type" = CONST(Campaign)) Campaign
            ELSE
            IF ("Source Type" = CONST(Contact)) Contact
            ELSE
            IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST("Customer Disc. Group")) "Customer Discount Group"
            ELSE
            IF ("Source Type" = CONST("Customer Price Group")) "Customer Price Group"
            ELSE
            IF ("Source Type" = CONST(Job)) Job
            ELSE
            IF ("Source Type" = CONST("Job Task")) "Job Task"."Job Task No." where("Job No." = field("Parent Source No."), "Job Task Type" = CONST(Posting))
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                Validate("Source No.", "Assign-to No.");
            end;
        }
        field(35; "Assign-to Parent No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = IF ("Source Type" = CONST("Job Task")) Job;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                Validate("Parent Source No.", "Assign-to Parent No.");
            end;
        }
        field(36; "Variant Code Lookup"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = IF ("Asset Type" = CONST(Item)) "Item Variant".Code WHERE("Item No." = FIELD("Asset No."));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                Validate("Variant Code", "Variant Code Lookup");
            end;
        }
        field(37; "Unit of Measure Code Lookup"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = IF ("Asset Type" = CONST(Item)) "Item Unit of Measure".Code WHERE("Item No." = FIELD("Asset No."))
            ELSE
            IF ("Asset Type" = CONST(Resource)) "Resource Unit of Measure".Code WHERE("Resource No." = FIELD("Asset No."))
            ELSE
            IF ("Asset Type" = CONST("Resource Group")) "Unit of Measure";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                Validate("Unit of Measure Code", "Unit of Measure Code Lookup");
            end;
        }
        field(28060; "Published Price"; Decimal)
        {
            CalcFormula = Lookup(Item."Unit Price" WHERE("No." = FIELD("Asset No.")));
            Caption = 'Published Price';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28061; Cost; Decimal)
        {
            CalcFormula = Lookup(Item."Unit Cost" WHERE("No." = FIELD("Asset No.")));
            Caption = 'Cost';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28062; "Cost-plus %"; Decimal)
        {
            Caption = 'Cost-plus %';
            DecimalPlaces = 0 : 1;
            MinValue = 0;

            trigger OnValidate()
            begin
                "Discount Amount" := 0;
                UpdateUnitPriceByCostPlusPct();
            end;
        }
        field(28063; "Discount Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Discount Amount';
            MinValue = 0;

            trigger OnValidate()
            begin
                "Cost-plus %" := 0;
                UpdateUnitPriceByCostPlusPct();
            end;
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
        key(Key3; Status, "Price Type", "Amount Type", "Currency Code", "Unit of Measure Code", "Source Type", "Source No.", "Asset Type", "Asset No.", "Variant Code", "Starting Date", "Ending Date", "Minimum Quantity")
        {
        }
        key(Key4; Status, "Price Type", "Amount Type", "Currency Code", "Unit of Measure Code", "Source Type", "Parent Source No.", "Source No.", "Asset Type", "Asset No.", "Work Type Code", "Starting Date", "Ending Date", "Minimum Quantity")
        {
        }
        key(Key5; "Product No.", "Asset No.")
        {
        }
    }

    trigger OnDelete()
    begin
        if (Status = Status::Active) and not IsEditable() then
            Error(CannotDeleteActivePriceListLineErr, "Price List Code", "Line No.");
    end;

    trigger OnInsert()
    begin
        if ("Price List Code" = '') and ("Price Type" = "Price Type"::Sale) and ("Amount Type" <> "Amount Type"::Discount) then begin
            if not ("Source Type" in ["Source Type"::Customer, "Source Type"::"Customer Price Group"]) then
                "Allow Line Disc." := true;
            if ("Source Type" <> "Source Type"::"Customer Price Group") and ("Asset Type" <> "Asset Type"::Item) then
                "Allow Invoice Disc." := true;
        end;
    end;

    protected var
        PriceListHeader: Record "Price List Header";
        PriceAsset: Record "Price Asset";
        PriceSource: Record "Price Source";

    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        IsNewRecord: Boolean;
        FieldLookedUp: Boolean;
        FieldNotAllowedForAmountTypeErr: Label 'Field %1 is not allowed in the price list line where %2 is %3.',
            Comment = '%1 - the field caption; %2 - Amount Type field caption; %3 - amount type value: Discount or Price';
        LineSourceTypeErr: Label 'cannot be set to %1 if the header''s source type is %2.', Comment = '%1 and %2 - the source type value.';
        CannotDeleteActivePriceListLineErr: Label 'You cannot delete the active price list line %1 %2.', Comment = '%1 - the price list code, %2 - line no';

    procedure SetNextLineNo()
    var
        PriceListLine: Record "Price List Line";
    begin
        "Line No." := 10000;
        PriceListLine.SetRange("Price List Code", "Price List Code");
        if PriceListLine.FindLast() then
            "Line No." += PriceListLine."Line No.";
    end;

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

    local procedure IsAllowedEditingActivePrice() Result: Boolean;
    var
        PriceListManagement: Codeunit "Price List Management";
    begin
        Result := PriceListManagement.IsAllowedEditingActivePrice("Price Type");
        OnAfterIsAllowedEditingActivePrice(Rec, Result);
    end;

    procedure IsUOMSupported() Result: Boolean;
    begin
        Result := IsAssetItem() or IsAssetResource();

        OnAfterIsUOMSupported(Rec, Result);
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

    procedure CopySourceFrom(PriceListHeader: Record "Price List Header")
    begin
        "Source Group" := PriceListHeader."Source Group";
        "Source Type" := PriceListHeader."Source Type";
        SetSourceNo(PriceListHeader."Parent Source No.", PriceListHeader."Source No.");
        "Source ID" := PriceListHeader."Source ID";
    end;

    procedure CopyFrom(PriceListHeader: Record "Price List Header")
    begin
        CopyFrom(PriceListHeader, false);
    end;

    procedure CopyFrom(PriceListHeader: Record "Price List Header"; ForceDefaults: Boolean)
    begin
        "Price Type" := PriceListHeader."Price Type";
        Status := "Price Status"::Draft;
        if not PriceListHeader."Allow Updating Defaults" or ForceDefaults then begin
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
        SetSourceNo(PriceSource."Parent Source No.", PriceSource."Source No.");
        "Source ID" := PriceSource."Source ID";

        if not GetHeader() or PriceListHeader."Allow Updating Defaults" then begin
            "Currency Code" := PriceSource."Currency Code";
            "Price Includes VAT" := PriceSource."Price Includes VAT";
            "Allow Invoice Disc." := PriceSource."Allow Invoice Disc.";
            "Allow Line Disc." := PriceSource."Allow Line Disc.";
            "VAT Bus. Posting Gr. (Price)" := PriceSource."VAT Bus. Posting Gr. (Price)";
            "Starting Date" := PriceSource."Starting Date";
            "Ending Date" := PriceSource."Ending Date";
        end;
        OnAfterCopyFromPriceSource(PriceSource);
    end;

    procedure CopyFrom(PriceAsset: Record "Price Asset")
    begin
        if PriceAsset."Amount Type" <> PriceAsset."Amount Type"::Any then
            "Amount Type" := PriceAsset."Amount Type";
        "Price Type" := PriceAsset."Price Type";
        "Asset Type" := PriceAsset."Asset Type";
        SetAssetNo(PriceAsset."Asset No.");
        "Asset ID" := PriceAsset."Asset ID";
        Description := PriceAsset.Description;
        "Unit of Measure Code" := PriceAsset."Unit of Measure Code";
        "Variant Code" := PriceAsset."Variant Code";
        "Work Type Code" := PriceAsset."Work Type Code";

        "Allow Invoice Disc." := PriceAsset."Allow Invoice Disc.";
        if not GetHeader() or PriceListHeader."Allow Updating Defaults" then
            if "VAT Bus. Posting Gr. (Price)" = '' then begin
                "Price Includes VAT" := PriceAsset."Price Includes VAT";
                "VAT Bus. Posting Gr. (Price)" := PriceAsset."VAT Bus. Posting Gr. (Price)";
            end;
        OnAfterCopyFromPriceAsset(PriceAsset, Rec);
    end;

    procedure CopyPriceFrom(PriceAsset: Record "Price Asset")
    begin
        case PriceAsset."Price Type" of
            PriceAsset."Price Type"::Sale:
                "Unit Price" := PriceAsset."Unit Price";
            PriceAsset."Price Type"::Purchase:
                begin
                    "Direct Unit Cost" := PriceAsset."Unit Price";
                    "Unit Cost" := PriceAsset."Unit Price 2";
                end;
        end;

        OnAfterCopyPriceFrom(Rec, PriceAsset);
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

    procedure CopyFilteredLinesToTemporaryBuffer(var TempPriceListLine: Record "Price List Line" temporary) Copied: Boolean;
    begin
        if FindSet() then
            repeat
                TempPriceListLine := Rec;
                OnCopyFilteredLinesToTemporaryBufferOnBeforeInsert(TempPriceListLine);
                if TempPriceListLine.Insert() then
                    Copied := true;
            until Next() = 0;
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

    internal procedure SetHeader(var NewPriceListHeader: Record "Price List Header")
    begin
        PriceListHeader := NewPriceListHeader;
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

    procedure SetAssetNo(AssetNo: Code[20])
    begin
        "Asset No." := AssetNo;
        "Product No." := AssetNo;
    end;

    local procedure SetSourceNo(ParentSourceNo: Code[20]; SourceNo: Code[20])
    begin
        "Parent Source No." := ParentSourceNo;
        "Source No." := SourceNo;

        "Assign-to Parent No." := ParentSourceNo;
        "Assign-to No." := SourceNo;
    end;

    procedure SyncDropDownLookupFields()
    begin
        "Assign-to Parent No." := "Parent Source No.";
        "Assign-to No." := "Source No.";
        "Product No." := "Asset No.";
        "Unit of Measure Code Lookup" := "Unit of Measure Code";
        "Variant Code Lookup" := "Variant Code";
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
        end;
        if not PriceListHeader."Allow Updating Defaults" then
            case FieldId of
                FieldNo("Price Includes VAT"):
                    TestField("Price Includes VAT", PriceListHeader."Price Includes VAT");
                FieldNo("VAT Bus. Posting Gr. (Price)"):
                    TestField("VAT Bus. Posting Gr. (Price)", PriceListHeader."VAT Bus. Posting Gr. (Price)");
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

    local procedure UpdateUnitPriceByCostPlusPct()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if "Asset Type" <> "Asset Type"::Item then
            exit;

        Item.Get("Asset No.");
        if "Cost-plus %" <> 0 then begin
            "Unit Price" := Item."Unit Cost" * (1 + "Cost-plus %" / 100);
            if "Unit of Measure Code" <> Item."Base Unit of Measure" then
                if ItemUnitOfMeasure.Get("Asset No.", "Unit of Measure Code") then
                    "Unit Price" := ItemUnitOfMeasure."Qty. per Unit of Measure" * "Unit Price";
        end else
            if "Unit of Measure Code" = Item."Base Unit of Measure" then
                "Unit Price" := Item."Unit Price" - "Discount Amount"
            else
                if ItemUnitOfMeasure.Get("Asset No.", "Unit of Measure Code") then
                    "Unit Price" := (ItemUnitOfMeasure."Qty. per Unit of Measure" * Item."Unit Price") - "Discount Amount";
    end;

    procedure Verify()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerify(Rec, IsHandled);
        if IsHandled then
            exit;

        VerifySource();
        TestField("Asset Type");

        OnAfterVerify(Rec);
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

    procedure VerifySource()
    begin
        if VerifyParentSource() then
            TestField("Parent Source No.")
        else
            TestField("Parent Source No.", '');

        if IsSourceNoAllowed() then
            TestField("Source No.")
        else
            TestField("Source No.", '');
    end;

    procedure UseCustomizedLookup(): Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PriceListLineSync: Codeunit "Price List Line Sync";
    begin
        if not PriceListLineSync.IsPriceListLineSynchronized() then begin
            if GuiAllowed() then
                PriceListLineSync.SendOutOfSyncNotification();
            exit(true);
        end;
        SalesReceivablesSetup.Get();
        exit(SalesReceivablesSetup."Use Customized Lookup");
    end;

    procedure RenameNo(LineType: Enum "Price Asset Type"; OldNo: Code[20]; NewNo: Code[20])
    begin
        Reset();
        SetRange("Asset Type", LineType);
        SetRange("Product No.", OldNo);
        if not Rec.IsEmpty() then
            ModifyAll("Product No.", NewNo, true);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyFromPriceAsset(PriceAsset: Record "Price Asset"; var riceListLine: Record "Price List Line")
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPriceFrom(var PriceListLine: Record "Price List Line"; PriceAsset: Record "Price Asset")
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsAllowedEditingActivePrice(PriceListLine: Record "Price List Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterIsUOMSupported(PriceListLine: Record "Price List Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVerify(var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerify(var PriceListLine: Record "Price List Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFilteredLinesToTemporaryBufferOnBeforeInsert(var TempPriceListLine: Record "Price List Line" temporary)
    begin
    end;
}