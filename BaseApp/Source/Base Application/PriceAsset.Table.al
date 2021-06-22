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
                if "Asset Type" = xRec."Asset Type" then
                    exit;
                InitAsset();
            end;
        }
        field(3; "Asset No."; Code[20])
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                if "Asset No." = xRec."Asset No." then
                    exit;
                if "Asset No." = '' then
                    InitAsset()
                else begin
                    PriceAssetInterface := "Asset Type";
                    PriceAssetInterface.GetId(Rec)
                end;
            end;
        }
        field(4; "Asset ID"; Guid)
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                if "Asset ID" = xRec."Asset ID" then
                    exit;
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
        }
        field(7; "Unit of Measure Code"; Code[10])
        {
            DataClassification = SystemMetadata;
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
}