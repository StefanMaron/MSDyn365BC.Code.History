table 7003 "Price Asset"
{
    #pragma warning disable AS0034
    TableType = Temporary;
    #pragma warning restore AS0034

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Asset Type"; Enum "Price Asset Type")
        {
            Caption = 'Product Type';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                VerifyConsistentAssetType();
                InitAsset();
            end;
        }
        field(3; "Asset No."; Code[20])
        {
            Caption = 'Product No.';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if "Asset No." = '' then
                    InitAsset()
                else
                    ValidateAssetNo();
            end;
        }
        field(4; "Asset ID"; Guid)
        {
            Caption = 'Product Id';
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                if IsNullGuid("Asset ID") then
                    InitAsset()
                else begin
                    PriceAssetInterface := "Asset Type";
                    PriceAssetInterface.GetNo(Rec);
                end;
            end;
        }
        field(5; Level; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(6; "Variant Code"; Code[10])
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if "Variant Code" <> '' then begin
                    TestField("Asset Type", "Asset Type"::Item);
                    TestField("Asset No.");
                    ItemVariant.Get("Asset No.", "Variant Code");
                    Description := ItemVariant.Description;
                end;
            end;
        }
        field(7; "Unit of Measure Code"; Code[10])
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            var
                ItemUnitofMeasure: Record "Item Unit of Measure";
                ResourceUnitofMeasure: Record "Resource Unit of Measure";
            begin
                if "Unit of Measure Code" <> '' then
                    case "Asset Type" of
                        "Asset Type"::Item:
                            begin
                                TestField("Asset No.");
                                ItemUnitofMeasure.Get("Asset No.", "Unit of Measure Code");
                            end;
                        "Asset Type"::Resource:
                            begin
                                TestField("Asset No.");
                                ResourceUnitofMeasure.Get("Asset No.", "Unit of Measure Code");
                            end;
                        else
                            Error(AssetTypeForUOMErr);
                    end;
            end;
        }
        field(8; "Price Type"; Enum "Price Type")
        {
            DataClassification = SystemMetadata;
        }
        field(22; "Allow Invoice Disc."; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(23; "Price Includes VAT"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(24; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        field(25; "Work Type Code"; Code[10])
        {
            DataClassification = SystemMetadata;
            TableRelation = "Work Type";
            trigger OnValidate()
            var
                Resource: Record Resource;
                WorkType: Record "Work Type";
            begin
                TestField("Asset Type", "Asset Type"::Resource);
                TestField("Asset No.");

                if WorkType.Get("Work Type Code") and (WorkType."Unit of Measure Code" <> '') then
                    "Unit of Measure Code" := WorkType."Unit of Measure Code"
                else begin
                    Resource.Get("Asset No.");
                    "Unit of Measure Code" := Resource."Base Unit of Measure";
                end;
            end;
        }
        field(29; Description; Text[100])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
        }
    }

    var
        PriceAssetInterface: Interface "Price Asset";
        AssetTypeForUOMErr: Label 'Product Type must be equal to Item or Resource.';

    trigger OnInsert()
    begin
        "Entry No." := GetLastEntryNo() + 1;
    end;

    procedure NewEntry(AssetType: Enum "Price Asset Type"; NewLevel: Integer)
    begin
        Init();
        Level := NewLevel;
        Validate("Asset Type", AssetType);
    end;

    local procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure InitAsset()
    begin
        Clear("Asset ID");
        "Asset No." := '';
        Description := '';
        "Unit of Measure Code" := '';
    end;

    procedure IsAssetNoRequired(): Boolean;
    begin
        PriceAssetInterface := "Asset Type";
        exit(PriceAssetInterface.IsAssetNoRequired());
    end;

    procedure LookupNo() Result: Boolean;
    begin
        PriceAssetInterface := "Asset Type";
        Result := PriceAssetInterface.IsLookupOK(Rec);
    end;

    procedure LookupVariantCode() Result: Boolean;
    begin
        TestField("Asset Type", "Asset Type"::Item);
        TestField("Asset No.");
        PriceAssetInterface := "Asset Type";
        Result := PriceAssetInterface.IsLookupVariantOK(Rec);
    end;

    procedure LookupUnitofMeasure() Result: Boolean;
    begin
        PriceAssetInterface := "Asset Type";
        Result := PriceAssetInterface.IsLookupUnitOfMeasureOK(Rec);
    end;

    procedure FilterPriceLines(var PriceListLine: Record "Price List Line") Result: Boolean;
    begin
        PriceAssetInterface := "Asset Type";
        Result := PriceAssetInterface.FilterPriceLines(Rec, PriceListLine);
    end;

    procedure PutRelatedAssetsToList(var PriceAssetList: Codeunit "Price Asset List"): Integer;
    begin
        PriceAssetInterface := "Asset Type";
        PriceAssetInterface.PutRelatedAssetsToList(Rec, PriceAssetList);
        exit(PriceAssetList.Count());
    end;

    procedure FillFromBuffer(PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
        PriceAssetInterface := PriceCalculationBuffer."Asset Type";
        PriceAssetInterface.FillFromBuffer(Rec, PriceCalculationBuffer);
    end;

    procedure ValidateAssetNo()
    begin
        PriceAssetInterface := "Asset Type";
        PriceAssetInterface.GetId(Rec)
    end;

    // Could be a method in the Price Asset interface
    local procedure VerifyConsistentAssetType()
    begin
        if "Price Type" = "Price Type"::Purchase then
            if "Asset Type" = "Asset Type"::"Item Discount Group" then
                FieldError("Asset Type");
    end;
}