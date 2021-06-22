codeunit 7007 "Price Asset List"
{
    var
        TempPriceAsset: Record "Price Asset" temporary;
        CurrentLevel: Integer;

    procedure Init()
    begin
        CurrentLevel := 0;
        TempPriceAsset.Reset();
        TempPriceAsset.DeleteAll();
    end;

    procedure Count(): Integer;
    begin
        TempPriceAsset.Reset();
        exit(TempPriceAsset.Count());
    end;

    procedure GetMinMaxLevel(var Level: array[2] of Integer)
    var
        LocalTempPriceAsset: Record "Price Asset" temporary;
    begin
        LocalTempPriceAsset.Copy(TempPriceAsset, true);
        LocalTempPriceAsset.Reset();
        if LocalTempPriceAsset.IsEmpty then begin
            Level[2] := Level[1] - 1;
            exit;
        end;

        LocalTempPriceAsset.SetCurrentKey(Level);
        LocalTempPriceAsset.FindFirst();
        Level[1] := LocalTempPriceAsset.Level;
        LocalTempPriceAsset.FindLast();
        Level[2] := LocalTempPriceAsset.Level;
    end;

    procedure IncLevel()
    begin
        CurrentLevel += 1;
    end;

    procedure SetLevel(Level: Integer)
    begin
        CurrentLevel := Level;
    end;

    procedure Add(AssetType: Enum "Price Asset Type"; AssetNo: Code[20])
    begin
        if AssetNo = '' then
            exit;
        TempPriceAsset.NewEntry(AssetType, CurrentLevel);
        TempPriceAsset.Validate("Asset No.", AssetNo);
        AppendRelatedAssets();
        InsertAsset();
    end;

    procedure Add(AssetType: Enum "Price Asset Type"; AssetId: Guid)
    begin
        if IsNullGuid(AssetId) then
            exit;
        TempPriceAsset.NewEntry(AssetType, CurrentLevel);
        TempPriceAsset.Validate("Asset ID", AssetId);
        AppendRelatedAssets();
        InsertAsset();
    end;

    procedure Add(AssetType: Enum "Price Asset Type")
    begin
        TempPriceAsset.NewEntry(AssetType, CurrentLevel);
        AppendRelatedAssets();
        InsertAsset();
    end;

    procedure Add(PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
        TempPriceAsset.Level := CurrentLevel;
        TempPriceAsset.FillFromBuffer(PriceCalculationBuffer);
        AppendRelatedAssets();
        InsertAsset();
    end;

    local procedure AppendRelatedAssets()
    var
        PriceAssetList: Codeunit "Price Asset List";
    begin
        TempPriceAsset.PutRelatedAssetsToList(PriceAssetList);
        Append(PriceAssetList);
    end;

    local procedure InsertAsset()
    begin
        OnAddOnBeforeInsert(TempPriceAsset);
        TempPriceAsset.Insert(true);
    end;

    procedure GetValue(AssetType: Enum "Price Asset Type") Result: Code[20];
    var
        LocalTempPriceAsset: Record "Price Asset" temporary;
        PriceAssetInterface: Interface "Price Asset";
    begin
        LocalTempPriceAsset.Copy(TempPriceAsset, true);
        LocalTempPriceAsset.Reset();
        LocalTempPriceAsset.SetRange("Asset Type", AssetType);
        If LocalTempPriceAsset.FindFirst() then begin
            PriceAssetInterface := LocalTempPriceAsset."Asset Type";
            Result := LocalTempPriceAsset."Asset No.";
        end;
        OnAfterGetValue(AssetType, Result);
    end;

    procedure Copy(var FromPriceAssetList: Codeunit "Price Asset List")
    begin
        Init();
        FromPriceAssetList.GetList(TempPriceAsset);
    end;

    procedure Append(var FromPriceAssetList: Codeunit "Price Asset List")
    var
        FromTempPriceAsset: Record "Price Asset" temporary;
        ToTempPriceAsset: Record "Price Asset" temporary;
        Level: Array[2] of Integer;
        CurrLevel: Integer;
    begin
        ToTempPriceAsset.Copy(TempPriceAsset, true);
        FromPriceAssetList.GetMinMaxLevel(Level);
        for CurrLevel := Level[2] downto Level[1] do
            if FromPriceAssetList.First(FromTempPriceAsset, CurrLevel) then
                repeat
                    ToTempPriceAsset.TransferFields(FromTempPriceAsset, false);
                    ToTempPriceAsset.Insert(true);
                until not FromPriceAssetList.Next(FromTempPriceAsset);
    end;

    procedure GetList(var ToTempPriceAsset: Record "Price Asset" temporary): Boolean
    begin
        if ToTempPriceAsset.IsTemporary then
            ToTempPriceAsset.Copy(TempPriceAsset, true);
        exit(not ToTempPriceAsset.IsEmpty())
    end;

    procedure First(var PriceAsset: Record "Price Asset"; AtLevel: Integer): Boolean;
    begin
        TempPriceAsset.Reset();
        TempPriceAsset.SetCurrentKey(Level);
        TempPriceAsset.SetRange(Level, AtLevel);
        exit(GetRecordIfFound(TempPriceAsset.FindSet(), PriceAsset))
    end;

    procedure Next(var PriceAsset: Record "Price Asset"): Boolean;
    begin
        exit(GetRecordIfFound(TempPriceAsset.Next() > 0, PriceAsset))
    end;

    local procedure GetRecordIfFound(Found: Boolean; var PriceAsset: Record "Price Asset"): Boolean
    begin
        if Found then begin
            PriceAsset := TempPriceAsset;
            CurrentLevel := TempPriceAsset.Level;
        end else
            Clear(PriceAsset);
        exit(Found)
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAddOnBeforeInsert(var PriceAsset: Record "Price Asset")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetValue(AssetType: Enum "Price Asset Type"; var Result: Code[20])
    begin
    end;
}