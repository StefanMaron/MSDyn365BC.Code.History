codeunit 5825 "Marketing Text"
{
    procedure EditMarketingText(ItemNo: Code[20])
    var
        TempEntityText: Record "Entity Text" temporary;
        EntityTextRec: Record "Entity Text";
        Item: Record Item;
        EntityText: Codeunit "Entity Text";
        PageId: Integer;
    begin
        if not Item.Get(ItemNo) then
            exit;

        if not EntityTextRec.Get(CompanyName(), Database::Item, Item.SystemId, Enum::"Entity Text Scenario"::"Marketing Text") then begin
            EntityTextRec.Init();
            EntityTextRec.Company := CopyStr(CompanyName(), 1, MaxStrLen(EntityTextRec.Company));
            EntityTextRec."Source Table Id" := Database::Item;
            EntityTextRec."Source System Id" := Item.SystemId;
            EntityTextRec.Scenario := Enum::"Entity Text Scenario"::"Marketing Text";
            EntityTextRec.Insert();
            Commit();
        end;

        EntityTextRec.CalcFields(Text);
        TempEntityText.TransferFields(EntityTextRec, true);
        TempEntityText.Insert();

        PageId := Page::"Edit Marketing Text";
        if EntityText.CanSuggest() then
            PageId := Page::"Review Marketing Text";

        if Page.RunModal(PageId, TempEntityText) <> Action::LookupOK then
            exit;

        TempEntityText.CalcFields(Text);
        EntityTextRec.TransferFields(TempEntityText, false);
        EntityTextRec.Modify();
    end;

    internal procedure GetItemRecordFactCount(var Facts: Dictionary of [Text, Text]): Integer
    var
        ItemRecordFacts: Integer;
    begin
        ItemRecordFacts := 0;
        if Facts.ContainsKey(ProductNameTxt) then
            ItemRecordFacts += 1;

        if Facts.ContainsKey(ItemCategoryTxt) then
            ItemRecordFacts += 1;

        exit(ItemRecordFacts);
    end;

    local procedure AddItemAttributeFacts(ItemNo: Code[20]; var Facts: Dictionary of [Text, Text])
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
        ItemAttributeValueMapping.SetRange("No.", ItemNo);

        if ItemAttributeValueMapping.FindSet() then
            repeat
                if ItemAttribute.Get(ItemAttributeValueMapping."Item Attribute ID") and (not ItemAttribute.Blocked) then
                    if ItemAttributeValue.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID") then
                        if ItemAttributeValue.Value.Trim() <> '' then
                            if ItemAttribute.Type in [ItemAttribute.Type::Integer, ItemAttribute.Type::Decimal] then
                                Facts.Add(ItemAttribute.Name, ItemAttributeValue.Value + ' ' + ItemAttribute."Unit of Measure")
                            else
                                Facts.Add(ItemAttribute.Name, ItemAttributeValue.Value);
            until ItemAttributeValueMapping.Next() = 0;
    end;

    local procedure BuildFacts(Item: Record Item; var Facts: Dictionary of [Text, Text])
    var
        ItemCategory: Record "Item Category";
    begin
        Facts.Add(ProductNameTxt, Item.Description);

        if ItemCategory.Get(Item."Item Category Code") then
            if ItemCategory.Description <> '' then
                Facts.Add(ItemCategoryTxt, ItemCategory.Description)
            else
                Facts.Add(ItemCategoryTxt, ItemCategory.Code);

        AddItemAttributeFacts(Item."No.", Facts);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Entity Text", 'OnRequestEntityContext', '', true, true)]
    local procedure OnRequestEntityContext(SourceTableId: Integer; SourceSystemId: Guid; SourceScenario: Enum "Entity Text Scenario"; var Facts: Dictionary of [Text, Text]; var TextTone: Enum "Entity Text Tone"; var TextFormat: Enum "Entity Text Format"; var Handled: Boolean)
    var
        Item: Record Item;
    begin
        if Handled then
            exit;

        if SourceScenario <> SourceScenario::"Marketing Text" then
            exit;

        if SourceTableId <> Database::Item then
            exit;

        if IsNullGuid(SourceSystemId) then
            Error(NoItemDescriptionErr); // The item is not inserted yet

        if not Item.GetBySystemId(SourceSystemId) then begin
            Session.LogMessage('0000JXY', TelemetrySystemIdNotFoundTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
            exit;
        end;

        if Item.Description = '' then
            Error(NoItemDescriptionErr);

        BuildFacts(Item, Facts);

        if Facts.Count() < 2 then
            Error(NotEnoughInfoErr);

        TextTone := TextTone::Inspiring;

        TextFormat := TextFormat::TaglineParagraph;
        if Facts.Count() < 4 then // If there are less than 4 facts generate a tagline
            TextFormat := TextFormat::Tagline;

        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Entity Text", 'OnEditEntityText', '', true, true)]
    local procedure OnEditEntityText(var TempEntityText: Record "Entity Text" temporary; var Action: Action; var Handled: Boolean)
    var
        Item: Record Item;
        EntityText: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
    begin
        if Handled then
            exit;

        if TempEntityText.Scenario <> TempEntityText.Scenario::"Marketing Text" then
            exit;

        if TempEntityText."Source Table Id" <> Database::Item then
            exit;

        if not Item.GetBySystemId(TempEntityText."Source System Id") then begin
            Session.LogMessage('0000JXZ', TelemetrySystemIdNotFoundTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
            exit;
        end;

        BuildFacts(Item, Facts);
        if (Facts.Count() > 1) and EntityText.CanSuggest() then
            Action := Page.RunModal(Page::"Review Marketing Text", TempEntityText)
        else
            Action := Page.RunModal(Page::"Edit Marketing Text", TempEntityText);

        Handled := true;
    end;

    var
        NoItemDescriptionErr: Label 'Please provide a description for the item.';
        NotEnoughInfoErr: Label 'Copilot doesn''t have enough information to generate a suggestion.\Consider assigning an item category or item attributes so Copilot knows more about the item.';
        TelemetryCategoryLbl: Label 'Marketing Text', Locked = true;
        TelemetrySystemIdNotFoundTxt: Label 'Entity Text was requested for an item that does not exist', Locked = true;
        ProductNameTxt: Label 'Product Name', Locked = true;
        ItemCategoryTxt: Label 'Item Category', Locked = true;
}