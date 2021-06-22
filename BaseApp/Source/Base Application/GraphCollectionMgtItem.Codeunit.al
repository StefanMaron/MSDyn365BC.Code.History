codeunit 5470 "Graph Collection Mgt - Item"
{

    trigger OnRun()
    begin
    end;

    var
        ItemUOMDescriptionTxt: Label 'Graph CDM - Unit of Measure complex type on Item Entity page', Locked = true;
        ItemUOMConversionsDescriptionTxt: Label 'Graph CDM - Unit of Measure Conversions complex type on Item Entity page', Locked = true;
        ValueMustBeEqualErr: Label 'Conversions must be specified with %1 with value %2.', Locked = true;
        BaseUnitOfMeasureCannotHaveConversionsErr: Label 'Base Unit Of Measure must be specified on the item first.', Locked = true;
        TypeHelper: Codeunit "Type Helper";

    [Scope('Cloud')]
    procedure InsertItemFromSalesDocument(var Item: Record Item; var TempFieldSet: Record "Field" temporary; UnitOfMeasureJSON: Text)
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
        ItemModified: Boolean;
    begin
        If IsNullGuid(Item.SystemId) then
            Item.Insert(true)
        else
            Item.Insert(true, true);

        UpdateOrCreateItemUnitOfMeasureFromSalesDocument(UnitOfMeasureJSON, Item, TempFieldSet, ItemModified);

        RecRef.GetTable(Item);
        GraphMgtGeneralTools.ProcessNewRecordFromAPI(RecRef, TempFieldSet, Item."Last DateTime Modified");
        RecRef.SetTable(Item);

        Item.Modify(true);
    end;

    [Scope('Cloud')]
    procedure InsertItem(var Item: Record Item; var TempFieldSet: Record "Field" temporary; BaseUnitOfMeasureJSON: Text)
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        RecRef: RecordRef;
    begin
        If IsNullGuid(Item.SystemId) then
            Item.Insert(true)
        else
            Item.Insert(true, true);

        ProcessComplexTypes(
          Item,
          BaseUnitOfMeasureJSON
          );

        RecRef.GetTable(Item);
        GraphMgtGeneralTools.ProcessNewRecordFromAPI(RecRef, TempFieldSet, Item."Last DateTime Modified");
        RecRef.SetTable(Item);

        Item.Modify(true);
    end;

    procedure ProcessComplexTypes(var Item: Record Item; BaseUOMJSON: Text)
    begin
        UpdateUnitOfMeasure(BaseUOMJSON, Item.FieldNo("Base Unit of Measure"), Item);
    end;

    procedure ItemUnitOfMeasureToJSON(var Item: Record Item; UnitOfMeasureCode: Code[10]): Text
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        ItemUOMConversionJObject: DotNet JObject;
        UnitOfMeasureJSON: Text;
    begin
        UnitOfMeasureJSON := GraphMgtComplexTypes.GetUnitOfMeasureJSON(UnitOfMeasureCode);

        if UnitOfMeasureCode = Item."Base Unit of Measure" then
            exit(UnitOfMeasureJSON);

        if not ItemUnitOfMeasure.Get(Item."No.", UnitOfMeasureCode) then
            exit(UnitOfMeasureJSON);

        JSONManagement.InitializeObject(UnitOfMeasureJSON);
        JSONManagement.GetJSONObject(JsonObject);

        ItemUOMConversionJObject := ItemUOMConversionJObject.JObject;
        JSONManagement.AddJPropertyToJObject(
          ItemUOMConversionJObject, UOMConversionComplexTypeToUnitOfMeasure, Item."Base Unit of Measure");
        JSONManagement.AddJPropertyToJObject(
          ItemUOMConversionJObject, UOMConversionComplexTypeFromToConversionRate, ItemUnitOfMeasure."Qty. per Unit of Measure");
        JSONManagement.AddJObjectToJObject(JsonObject, UOMConversionComplexTypeName, ItemUOMConversionJObject);
        exit(JSONManagement.WriteObjectToString);
    end;

    procedure UpdateIntegrationRecords(OnlyItemsWithoutId: Boolean)
    var
        Item: Record Item;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        ItemRecordRef: RecordRef;
    begin
        ItemRecordRef.Open(DATABASE::Item);
        GraphMgtGeneralTools.UpdateIntegrationRecords(ItemRecordRef, Item.FieldNo(Id), OnlyItemsWithoutId);
    end;

    procedure UpdateOrCreateItemUnitOfMeasureFromSalesDocument(UnitOfMeasureJSONString: Text; var Item: Record Item; var TempFieldSet: Record "Field" temporary; var ItemModified: Boolean)
    var
        UnitOfMeasure: Record "Unit of Measure";
        TempUnitOfMeasure: Record "Unit of Measure" temporary;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        TempItemUnitOfMeasure: Record "Item Unit of Measure" temporary;
        ExpectedBaseUOMCode: Code[10];
        HasUOMConversions: Boolean;
    begin
        if UnitOfMeasureJSONString = '' then
            exit;

        ParseJSONToUnitOfMeasure(UnitOfMeasureJSONString, TempUnitOfMeasure);
        HasUOMConversions :=
          ParseJSONToItemUnitOfMeasure(UnitOfMeasureJSONString, Item, TempItemUnitOfMeasure, TempUnitOfMeasure, ExpectedBaseUOMCode);

        if HasUOMConversions then begin
            VerifyBaseUOMIsSet(Item, ExpectedBaseUOMCode);
            if not UnitOfMeasure.Get(ExpectedBaseUOMCode) then begin
                UnitOfMeasure.Code := ExpectedBaseUOMCode;
                UnitOfMeasure.Insert();
            end;

            if Item."Base Unit of Measure" = '' then begin
                Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
                RegisterFieldSet(TempFieldSet, Item.FieldNo("Unit of Measure Id"));
                RegisterFieldSet(TempFieldSet, Item.FieldNo("Base Unit of Measure"));
                ItemModified := true;
            end;

            InsertOrUpdateItemUnitOfMeasureRecord(ItemUnitOfMeasure, TempItemUnitOfMeasure);
        end else begin
            InsertOrUpdateUnitOfMeasureRecord(UnitOfMeasure, TempUnitOfMeasure);

            if Item."Base Unit of Measure" = '' then begin
                Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
                RegisterFieldSet(TempFieldSet, Item.FieldNo("Unit of Measure Id"));
                RegisterFieldSet(TempFieldSet, Item.FieldNo("Base Unit of Measure"));
                ItemModified := true;
            end else begin
                // Create on the fly if it does not exist
                if ItemUnitOfMeasure.Get(Item."No.", UnitOfMeasure.Code) then
                    exit;

                ItemUnitOfMeasure."Item No." := Item."No.";
                ItemUnitOfMeasure.Code := UnitOfMeasure.Code;
                ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
                ItemUnitOfMeasure.Insert(true);
            end;
        end;
    end;

    procedure UpdateUnitOfMeasure(UnitOfMeasureJSONString: Text; UnitOfMeasureFieldNo: Integer; var Item: Record Item)
    var
        UnitOfMeasure: Record "Unit of Measure";
        TempUnitOfMeasure: Record "Unit of Measure" temporary;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        TempItemUnitOfMeasure: Record "Item Unit of Measure" temporary;
        ItemRecordRef: RecordRef;
        UnitOfMeasureFieldRef: FieldRef;
        PreviousUnitOfMeasureJSONString: Text;
        PreviousUOMCode: Code[10];
        HasUOMConversions: Boolean;
        BaseUnitOfMeasureCode: Code[20];
    begin
        if UnitOfMeasureJSONString = '' then
            exit;

        ItemRecordRef.GetTable(Item);
        UnitOfMeasureFieldRef := ItemRecordRef.Field(UnitOfMeasureFieldNo);

        if UnitOfMeasureJSONString = 'null' then begin
            UnitOfMeasureFieldRef.Validate('');
            ItemRecordRef.SetTable(Item);
            exit;
        end;

        PreviousUOMCode := UnitOfMeasureFieldRef.Value;
        PreviousUnitOfMeasureJSONString := ItemUnitOfMeasureToJSON(Item, PreviousUOMCode);

        if UnitOfMeasureJSONString = PreviousUnitOfMeasureJSONString then
            exit;

        ParseJSONToUnitOfMeasure(UnitOfMeasureJSONString, TempUnitOfMeasure);
        HasUOMConversions :=
          ParseJSONToItemUnitOfMeasure(UnitOfMeasureJSONString, Item, TempItemUnitOfMeasure, TempUnitOfMeasure, BaseUnitOfMeasureCode);
        if HasUOMConversions and (UnitOfMeasureFieldNo = Item.FieldNo("Base Unit of Measure")) then
            Error(BaseUnitOfMeasureCannotHaveConversionsErr);

        InsertOrUpdateUnitOfMeasureRecord(UnitOfMeasure, TempUnitOfMeasure);

        if HasUOMConversions then
            InsertOrUpdateItemUnitOfMeasureRecord(ItemUnitOfMeasure, TempItemUnitOfMeasure);

        if PreviousUOMCode <> UnitOfMeasure.Code then
            UnitOfMeasureFieldRef.Validate(UnitOfMeasure.Code);

        ItemRecordRef.SetTable(Item);
    end;

    local procedure InsertOrUpdateUnitOfMeasureRecord(var UnitOfMeasure: Record "Unit of Measure"; var TempUnitOfMeasure: Record "Unit of Measure" temporary)
    var
        Modify: Boolean;
    begin
        if TempUnitOfMeasure.Code = '' then
            exit;

        if not UnitOfMeasure.Get(TempUnitOfMeasure.Code) then begin
            UnitOfMeasure.TransferFields(TempUnitOfMeasure, true);
            UnitOfMeasure.Insert(true);
            exit;
        end;

        if not (TempUnitOfMeasure.Description in [UnitOfMeasure.Description, '']) then begin
            UnitOfMeasure.Validate(Description, TempUnitOfMeasure.Description);
            Modify := true;
        end;

        if not (TempUnitOfMeasure.Symbol in [UnitOfMeasure.Symbol, '']) then begin
            UnitOfMeasure.Validate(Symbol, TempUnitOfMeasure.Symbol);
            Modify := true;
        end;

        if Modify then
            UnitOfMeasure.Modify(true);
    end;

    local procedure InsertOrUpdateItemUnitOfMeasureRecord(var ItemUnitOfMeasure: Record "Item Unit of Measure"; var TempItemUnitOfMeasure: Record "Item Unit of Measure" temporary)
    begin
        if not ItemUnitOfMeasure.Get(TempItemUnitOfMeasure."Item No.", TempItemUnitOfMeasure.Code) then begin
            ItemUnitOfMeasure.TransferFields(TempItemUnitOfMeasure, true);
            ItemUnitOfMeasure.Insert(true);
        end else begin
            if TempItemUnitOfMeasure."Qty. per Unit of Measure" = ItemUnitOfMeasure."Qty. per Unit of Measure" then
                exit;

            ItemUnitOfMeasure.Validate("Qty. per Unit of Measure", TempItemUnitOfMeasure."Qty. per Unit of Measure");
            ItemUnitOfMeasure.Modify(true);
        end;
    end;

    procedure ParseJSONToUnitOfMeasure(UnitOfMeasureJSONString: Text; var UnitOfMeasure: Record "Unit of Measure")
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        UnitCode: Text;
    begin
        JSONManagement.InitializeObject(UnitOfMeasureJSONString);
        JSONManagement.GetJSONObject(JsonObject);

        GraphMgtGeneralTools.GetMandatoryStringPropertyFromJObject(JsonObject, UOMComplexTypeUnitCode, UnitCode);
        UnitOfMeasure.Code := CopyStr(UnitCode, 1, MaxStrLen(UnitOfMeasure.Code));
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, UOMComplexTypeUnitName, UnitOfMeasure.Description);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, UOMComplexTypeSymbol, UnitOfMeasure.Symbol);
    end;

    local procedure ParseJSONToItemUnitOfMeasure(UnitOfMeasureJSONString: Text; var Item: Record Item; var TempItemUnitOfMeasure: Record "Item Unit of Measure" temporary; var UnitOfMeasure: Record "Unit of Measure"; var BaseUnitOfMeasureCode: Code[20]): Boolean
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        ConversionsTxt: Text;
        FromToConversionRateTxt: Text;
        BaseUnitOfMeasureTxt: Text;
    begin
        JSONManagement.InitializeObject(UnitOfMeasureJSONString);
        JSONManagement.GetJSONObject(JsonObject);

        if not JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, UOMConversionComplexTypeName, ConversionsTxt) then
            exit(false);

        if ConversionsTxt = '' then
            exit(false);

        if ConversionsTxt = 'null' then
            exit(false);

        JSONManagement.InitializeObject(ConversionsTxt);
        JSONManagement.GetJSONObject(JsonObject);

        GraphMgtGeneralTools.GetMandatoryStringPropertyFromJObject(
          JsonObject, UOMConversionComplexTypeToUnitOfMeasure, BaseUnitOfMeasureTxt);
        BaseUnitOfMeasureCode := CopyStr(BaseUnitOfMeasureTxt, 1, 20);

        GraphMgtGeneralTools.GetMandatoryStringPropertyFromJObject(
          JsonObject, UOMConversionComplexTypeFromToConversionRate, FromToConversionRateTxt);
        Evaluate(TempItemUnitOfMeasure."Qty. per Unit of Measure", FromToConversionRateTxt);
        TempItemUnitOfMeasure."Item No." := Item."No.";
        TempItemUnitOfMeasure.Code := UnitOfMeasure.Code;
        TempItemUnitOfMeasure.Insert();

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure WriteItemEDMComplexTypes()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        GraphMgtGeneralTools.InsertOrUpdateODataType('ITEM-UOM', ItemUOMDescriptionTxt, GetItemUOMEDM('ITEM-UOM-CONVERSION'));
        GraphMgtGeneralTools.InsertOrUpdateODataType('ITEM-UOM-CONVERSION', ItemUOMConversionsDescriptionTxt, GetItemUOMConversionEDM);
    end;

    local procedure GetItemUOMEDM(UOMConversionDefinitionCode: Code[50]): Text
    var
        DummyUnitOfMeasure: Record "Unit of Measure";
    begin
        exit(
          '<ComplexType Name="unitOfMeasureType">' +
          StrSubstNo('<Property Name="%1" Type="Edm.String" Nullable="true" MaxLength="%2" />',
            UOMComplexTypeUnitCode, MaxStrLen(DummyUnitOfMeasure.Code)) +
          StrSubstNo('<Property Name="%1" Type="Edm.String" Nullable="true" MaxLength="%2" />',
            UOMComplexTypeUnitName, MaxStrLen(DummyUnitOfMeasure.Description)) +
          StrSubstNo('<Property Name="%1" Type="Edm.String" Nullable="true" MaxLength="%2" />',
            UOMComplexTypeSymbol, MaxStrLen(DummyUnitOfMeasure.Symbol)) +
          StrSubstNo('<Property Name="%1" Type="%2" Nullable="true" />',
            UOMConversionComplexTypeName, UOMConversionDefinitionCode) +
          '</ComplexType>');
    end;

    local procedure GetItemUOMConversionEDM(): Text
    var
        DummyItem: Record Item;
    begin
        exit(
          '<ComplexType Name="itemUnitOfMeasureConversionType">' +
          StrSubstNo('<Property Name="%1" Type="Edm.String" Nullable="true" MaxLength="%2" />',
            UOMConversionComplexTypeToUnitOfMeasure, MaxStrLen(DummyItem."Base Unit of Measure")) +
          StrSubstNo('<Property Name="%1" Type="Edm.Decimal" Nullable="true" />',
            UOMConversionComplexTypeFromToConversionRate) +
          '</ComplexType>');
    end;

    local procedure EnableItemODataWebService()
    begin
        WriteItemEDMComplexTypes;
        UpdateIntegrationRecords(false);
    end;

    procedure SetLastDateTimeModified()
    var
        Item: Record Item;
        DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset;
        CombinedDateTime: DateTime;
    begin
        Item.SetRange("Last DateTime Modified", 0DT);
        if not Item.FindSet then
            exit;

        repeat
            CombinedDateTime := CreateDateTime(Item."Last Date Modified", Item."Last Time Modified");
            Item."Last DateTime Modified" := DotNet_DateTimeOffset.ConvertToUtcDateTime(CombinedDateTime);
            Item.Modify();
        until Item.Next = 0;
    end;

    local procedure RegisterFieldSet(var TempFieldSet: Record "Field" temporary; FieldNo: Integer)
    begin
        if TypeHelper.GetField(DATABASE::Item, FieldNo, TempFieldSet) then
            exit;

        TempFieldSet.Init();
        TempFieldSet.TableNo := DATABASE::Item;
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;

    procedure UOMComplexTypeUnitCode(): Text
    begin
        exit('code');
    end;

    procedure UOMComplexTypeUnitName(): Text
    begin
        exit('displayName');
    end;

    procedure UOMComplexTypeSymbol(): Text
    begin
        exit('symbol');
    end;

    procedure UOMConversionComplexTypeName(): Text
    begin
        exit('unitConversion');
    end;

    procedure UOMConversionComplexTypeToUnitOfMeasure(): Text
    begin
        exit('toUnitOfMeasure');
    end;

    procedure UOMConversionComplexTypeFromToConversionRate(): Text
    begin
        exit('fromToConversionRate');
    end;

    local procedure VerifyBaseUOMIsSet(var Item: Record Item; BaseUnitOfMeasure: Code[20])
    begin
        if Item."Base Unit of Measure" = '' then
            exit;

        if Item."Base Unit of Measure" <> UpperCase(BaseUnitOfMeasure) then
            Error(ValueMustBeEqualErr, UOMConversionComplexTypeToUnitOfMeasure, Item."Base Unit of Measure");
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        EnableItemODataWebService;
        UpdateIntegrationRecords(false);
        UpdateIds;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5150, 'OnUpdateRelatedRecordIdFields', '', false, false)]
    local procedure HandleUpdateRelatedRecordIdFields(var RecRef: RecordRef)
    var
        Item: Record Item;
        TempField: Record "Field" temporary;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        UpdatedRecRef: RecordRef;
    begin
        if not (RecRef.Number = DATABASE::Item) then
            exit;

        if RecRef.IsTemporary then
            exit;

        RecRef.SetTable(Item);
        Item.UpdateReferencedIds;

        UpdatedRecRef.GetTable(Item);
        Item.GetReferencedIds(TempField);
        GraphMgtGeneralTools.TransferRelatedRecordIntegrationIDs(RecRef, UpdatedRecRef, TempField);
    end;

    procedure UpdateIds()
    var
        Item: Record Item;
    begin
        if not Item.FindSet(true, false) then
            exit;

        repeat
            Item.UpdateReferencedIds;
            Item.Modify(false);
        until Item.Next = 0;
    end;
}

