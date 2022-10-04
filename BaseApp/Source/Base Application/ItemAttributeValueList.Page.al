page 7504 "Item Attribute Value List"
{
    Caption = 'Item Attribute Values';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Item Attribute Value Selection";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Attribute Name"; Rec."Attribute Name")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = false;
                    Caption = 'Attribute';
                    TableRelation = "Item Attribute".Name WHERE(Blocked = CONST(false));
                    ToolTip = 'Specifies the item attribute.';

                    trigger OnValidate()
                    var
                        ItemAttributeValue: Record "Item Attribute Value";
                        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
                        ItemAttribute: Record "Item Attribute";
                    begin
                        OnBeforeCheckAttributeName(Rec, RelatedRecordCode);
                        if xRec."Attribute Name" <> '' then begin
                            xRec.FindItemAttributeByName(ItemAttribute);
                            DeleteItemAttributeValueMapping(ItemAttribute.ID);
                        end;

                        if not FindAttributeValue(ItemAttributeValue) then
                            InsertItemAttributeValue(ItemAttributeValue, Rec);

                        if ItemAttributeValue.Get(ItemAttributeValue."Attribute ID", ItemAttributeValue.ID) then begin
                            ItemAttributeValueMapping.Reset();
                            ItemAttributeValueMapping.Init();
                            ItemAttributeValueMapping."Table ID" := DATABASE::Item;
                            ItemAttributeValueMapping."No." := RelatedRecordCode;
                            ItemAttributeValueMapping."Item Attribute ID" := ItemAttributeValue."Attribute ID";
                            ItemAttributeValueMapping."Item Attribute Value ID" := ItemAttributeValue.ID;
                            OnBeforeItemAttributeValueMappingInsert(ItemAttributeValueMapping, ItemAttributeValue, Rec);
                            ItemAttributeValueMapping.Insert();
                        end;
                    end;
                }
                field(Value; Value)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Value';
                    TableRelation = IF ("Attribute Type" = CONST(Option)) "Item Attribute Value".Value WHERE("Attribute ID" = FIELD("Attribute ID"),
                                                                                                            Blocked = CONST(false));
                    ToolTip = 'Specifies the value of the item attribute.';

                    trigger OnValidate()
                    var
                        ItemAttributeValue: Record "Item Attribute Value";
                        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
                        ItemAttribute: Record "Item Attribute";
                    begin
                        if not FindAttributeValue(ItemAttributeValue) then
                            InsertItemAttributeValue(ItemAttributeValue, Rec);

                        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
                        ItemAttributeValueMapping.SetRange("No.", RelatedRecordCode);
                        ItemAttributeValueMapping.SetRange("Item Attribute ID", ItemAttributeValue."Attribute ID");
                        if ItemAttributeValueMapping.FindFirst() then begin
                            ItemAttributeValueMapping."Item Attribute Value ID" := ItemAttributeValue.ID;
                            OnBeforeItemAttributeValueMappingModify(ItemAttributeValueMapping, ItemAttributeValue, RelatedRecordCode);
                            ItemAttributeValueMapping.Modify();
                            OnAfterItemAttributeValueMappingModify(ItemAttributeValueMapping, Rec);
                        end;

                        ItemAttribute.Get("Attribute ID");
                        if ItemAttribute.Type <> ItemAttribute.Type::Option then
                            if FindAttributeValueFromRecord(ItemAttributeValue, xRec) then
                                if not ItemAttributeValue.HasBeenUsed() then
                                    ItemAttributeValue.Delete();
                    end;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnDeleteRecord(): Boolean
    begin
        DeleteItemAttributeValueMapping("Attribute ID");
    end;

    trigger OnOpenPage()
    begin
        CurrPage.Editable(true);
    end;

    protected var
        RelatedRecordCode: Code[20];

    procedure LoadAttributes(ItemNo: Code[20])
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        RelatedRecordCode := ItemNo;
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("No.", ItemNo);
        if ItemAttributeValueMapping.FindSet() then
            repeat
                ItemAttributeValue.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID");
                TempItemAttributeValue.TransferFields(ItemAttributeValue);
                OnLoadAttributesOnBeforeTempItemAttributeValueInsert(TempItemAttributeValue, ItemAttributeValueMapping, RelatedRecordCode);
                TempItemAttributeValue.Insert();
            until ItemAttributeValueMapping.Next() = 0;

        PopulateItemAttributeValueSelection(TempItemAttributeValue, DATABASE::Item, ItemNo);
    end;

    local procedure DeleteItemAttributeValueMapping(AttributeToDeleteID: Integer)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttribute: Record "Item Attribute";
    begin
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("No.", RelatedRecordCode);
        ItemAttributeValueMapping.SetRange("Item Attribute ID", AttributeToDeleteID);
        if ItemAttributeValueMapping.FindFirst() then begin
            ItemAttributeValueMapping.Delete();
            OnAfterItemAttributeValueMappingDelete(AttributeToDeleteID, RelatedRecordCode, Rec);
        end;

        ItemAttribute.Get(AttributeToDeleteID);
        ItemAttribute.RemoveUnusedArbitraryValues();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemAttributeValueMappingDelete(AttributeToDeleteID: Integer; RelatedRecordCode: Code[20]; ItemAttributeValueSelection: Record "Item Attribute Value Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemAttributeValueMappingModify(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; ItemAttributeValueSelection: Record "Item Attribute Value Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemAttributeValueMappingInsert(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; ItemAttributeValue: Record "Item Attribute Value"; ItemAttributeValueSelection: Record "Item Attribute Value Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemAttributeValueMappingModify(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; ItemAttributeValue: Record "Item Attribute Value"; RelatedRecordCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadAttributesOnBeforeTempItemAttributeValueInsert(var TempItemAttributeValue: Record "Item Attribute Value" temporary; ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; RelatedRecordCode: Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAttributeName(var ItemAttributeValueSelection: Record "Item Attribute Value Selection"; RelatedRecordCode: Code[20]);
    begin
    end;
}

