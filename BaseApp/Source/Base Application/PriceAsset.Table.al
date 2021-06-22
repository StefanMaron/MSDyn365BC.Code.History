table 7003 "Price Asset"
{
    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Asset Type"; Enum "Price Asset Type")
        {
            DataClassification = SystemMetadata;
            Caption = 'Asset Type';
            trigger OnValidate()
            begin
                InitAsset();
            end;
        }
        field(3; "Asset No."; Code[20])
        {
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
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Asset No."));
            trigger OnValidate()
            begin
                TestField("Asset Type", "Asset Type"::Item);
            end;
        }
        field(7; "Unit of Measure Code"; Code[10])
        {
            DataClassification = SystemMetadata;
            TableRelation = IF ("Asset Type" = CONST(Item)) "Item Unit of Measure".Code WHERE("Item No." = FIELD("Asset No."))
            ELSE
            IF ("Asset Type" = CONST(Resource)) "Resource Unit of Measure".Code WHERE("Resource No." = FIELD("Asset No."));
            trigger OnValidate()
            begin
                if not ("Asset Type" in ["Asset Type"::Item, "Asset Type"::Resource]) then
                    Error(AssetTypeForUOMErr);
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
        AssetTypeForUOMErr: Label 'Asset Type must be equal to Item or Resource.';

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
}