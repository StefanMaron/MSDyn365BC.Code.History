page 5470 "Item Entity"
{
    Caption = 'items', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'item';
    EntitySetName = 'items';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                    Editable = false;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Number', Locked = true;
                }
                field(displayName; Description)
                {
                    ApplicationArea = All;
                    Caption = 'DisplayName', Locked = true;
                    ToolTip = 'Specifies the Description for the Item.';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Description));
                    end;
                }
                field(type; Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type', Locked = true;
                    ToolTip = 'Specifies the Type for the Item. Possible values are Inventory and Service.';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Type));
                    end;
                }
                field(itemCategoryId; "Item Category Id")
                {
                    ApplicationArea = All;
                    Caption = 'ItemCategoryId', Locked = true;

                    trigger OnValidate()
                    begin
                        if "Item Category Id" = BlankGUID then
                            "Item Category Code" := ''
                        else begin
                            ItemCategory.SetRange(Id, "Item Category Id");
                            if not ItemCategory.FindFirst then
                                Error(ItemCategoryIdDoesNotMatchAnItemCategoryGroupErr);

                            "Item Category Code" := ItemCategory.Code;
                        end;

                        RegisterFieldSet(FieldNo("Item Category Code"));
                        RegisterFieldSet(FieldNo("Item Category Id"));
                    end;
                }
                field(itemCategoryCode; "Item Category Code")
                {
                    ApplicationArea = All;
                    Caption = 'ItemCategoryCode', Locked = true;

                    trigger OnValidate()
                    begin
                        if ItemCategory.Code <> '' then begin
                            if ItemCategory.Code <> "Item Category Code" then
                                Error(ItemCategoriesValuesDontMatchErr);
                            exit;
                        end;

                        if "Item Category Code" = '' then
                            "Item Category Id" := BlankGUID
                        else begin
                            if not ItemCategory.Get("Item Category Code") then
                                Error(ItemCategoryCodeDoesNotMatchATaxGroupErr);

                            "Item Category Id" := ItemCategory.Id;
                        end;
                    end;
                }
                field(blocked; Blocked)
                {
                    ApplicationArea = All;
                    Caption = 'Blocked', Locked = true;
                    ToolTip = 'Specifies whether the item is blocked.';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Blocked));
                    end;
                }
                field(baseUnitOfMeasureId; BaseUnitOfMeasureId)
                {
                    ApplicationArea = All;
                    Caption = 'BaseUnitOfMeasureId', Locked = true;

                    trigger OnValidate()
                    begin
                        if BaseUnitOfMeasureId = BlankGUID then
                            BaseUnitOfMeasureCode := ''
                        else begin
                            ValidateUnitOfMeasure.SetRange(Id, BaseUnitOfMeasureId);
                            if not ValidateUnitOfMeasure.FindFirst then
                                Error(UnitOfMeasureIdDoesNotMatchAUnitOfMeasureErr);

                            BaseUnitOfMeasureCode := ValidateUnitOfMeasure.Code;
                        end;

                        RegisterFieldSet(FieldNo("Unit of Measure Id"));
                        RegisterFieldSet(FieldNo("Base Unit of Measure"));
                    end;
                }
                field(baseUnitOfMeasure; BaseUnitOfMeasureJSONText)
                {
                    ApplicationArea = All;
                    Caption = 'BaseUnitOfMeasure', Locked = true;
                    ODataEDMType = 'ITEM-UOM';
                    ToolTip = 'Specifies the Base Unit of Measure.';

                    trigger OnValidate()
                    var
                        UnitOfMeasureFromJSON: Record "Unit of Measure";
                    begin
                        RegisterFieldSet(FieldNo("Unit of Measure Id"));
                        RegisterFieldSet(FieldNo("Base Unit of Measure"));

                        if BaseUnitOfMeasureJSONText = 'null' then
                            exit;

                        GraphCollectionMgtItem.ParseJSONToUnitOfMeasure(BaseUnitOfMeasureJSONText, UnitOfMeasureFromJSON);

                        if (ValidateUnitOfMeasure.Code <> '') and
                           (ValidateUnitOfMeasure.Code <> UnitOfMeasureFromJSON.Code)
                        then
                            Error(UnitOfMeasureValuesDontMatchErr);
                    end;
                }
                field(gtin; GTIN)
                {
                    ApplicationArea = All;
                    Caption = 'GTIN', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(GTIN));
                    end;
                }
                field(inventory; InventoryValue)
                {
                    ApplicationArea = All;
                    Caption = 'Inventory', Locked = true;
                    ToolTip = 'Specifies the inventory for the item.';

                    trigger OnValidate()
                    begin
                        Validate(Inventory, InventoryValue);
                        RegisterFieldSet(FieldNo(Inventory));
                    end;
                }
                field(unitPrice; "Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'UnitPrice', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Unit Price"));
                    end;
                }
                field(priceIncludesTax; "Price Includes VAT")
                {
                    ApplicationArea = All;
                    Caption = 'PriceIncludesTax', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Price Includes VAT"));
                    end;
                }
                field(unitCost; "Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'UnitCost', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Unit Cost"));
                    end;
                }
                field(taxGroupId; "Tax Group Id")
                {
                    ApplicationArea = All;
                    Caption = 'TaxGroupId', Locked = true;
                    ToolTip = 'Specifies the ID of the tax group.';

                    trigger OnValidate()
                    begin
                        if "Tax Group Id" = BlankGUID then
                            "Tax Group Code" := ''
                        else begin
                            TaxGroup.SetRange(Id, "Tax Group Id");
                            if not TaxGroup.FindFirst then
                                Error(TaxGroupIdDoesNotMatchATaxGroupErr);

                            "Tax Group Code" := TaxGroup.Code;
                        end;

                        RegisterFieldSet(FieldNo("Tax Group Code"));
                        RegisterFieldSet(FieldNo("Tax Group Id"));
                    end;
                }
                field(taxGroupCode; "Tax Group Code")
                {
                    ApplicationArea = All;
                    Caption = 'TaxGroupCode', Locked = true;

                    trigger OnValidate()
                    begin
                        if TaxGroup.Code <> '' then begin
                            if TaxGroup.Code <> "Tax Group Code" then
                                Error(TaxGroupValuesDontMatchErr);
                            exit;
                        end;

                        if "Tax Group Code" = '' then
                            "Tax Group Id" := BlankGUID
                        else begin
                            if not TaxGroup.Get("Tax Group Code") then
                                Error(TaxGroupCodeDoesNotMatchATaxGroupErr);

                            "Tax Group Id" := TaxGroup.Id;
                        end;

                        RegisterFieldSet(FieldNo("Tax Group Code"));
                        RegisterFieldSet(FieldNo("Tax Group Id"));
                    end;
                }
                field(lastModifiedDateTime; "Last DateTime Modified")
                {
                    ApplicationArea = All;
                    Caption = 'LastModifiedDateTime', Locked = true;
                    Editable = false;
                }
                part(picture; "Picture Entity")
                {
                    ApplicationArea = All;
                    Caption = 'picture';
                    EntityName = 'picture';
                    EntitySetName = 'picture';
                    SubPageLink = Id = FIELD(Id);
                }
                part(defaultDimensions; "Default Dimension Entity")
                {
                    ApplicationArea = All;
                    Caption = 'Default Dimensions', Locked = true;
                    EntityName = 'defaultDimensions';
                    EntitySetName = 'defaultDimensions';
                    SubPageLink = ParentId = FIELD(Id);
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
    begin
        if TempFieldSet.Get(DATABASE::Item, FieldNo("Base Unit of Measure")) then
            if BaseUnitOfMeasureJSONText = '' then
                BaseUnitOfMeasureJSONText := GraphCollectionMgtItem.ItemUnitOfMeasureToJSON(Rec, BaseUnitOfMeasureCode);

        GraphCollectionMgtItem.InsertItem(Rec, TempFieldSet, BaseUnitOfMeasureJSONText);

        SetCalculatedFields;
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Item: Record Item;
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
    begin
        if TempFieldSet.Get(DATABASE::Item, FieldNo("Base Unit of Measure")) then
            Validate("Base Unit of Measure", BaseUnitOfMeasureCode);

        Item.SetRange(Id, Id);
        Item.FindFirst;

        GraphCollectionMgtItem.ProcessComplexTypes(
          Rec,
          BaseUnitOfMeasureJSONText
          );

        if "No." = Item."No." then
            Modify(true)
        else begin
            Item.TransferFields(Rec, false);
            Item.Rename("No.");
            TransferFields(Item, true);
        end;

        SetCalculatedFields;

        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields;
    end;

    var
        TempFieldSet: Record "Field" temporary;
        ValidateUnitOfMeasure: Record "Unit of Measure";
        ItemCategory: Record "Item Category";
        TaxGroup: Record "Tax Group";
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        BaseUnitOfMeasureCode: Code[10];
        BaseUnitOfMeasureJSONText: Text;
        InventoryValue: Decimal;
        UnitOfMeasureValuesDontMatchErr: Label 'The unit of measure values do not match to a specific Unit of Measure.', Locked = true;
        UnitOfMeasureIdDoesNotMatchAUnitOfMeasureErr: Label 'The "unitOfMeasureId" does not match to a Unit of Measure.', Locked = true;
        BaseUnitOfMeasureId: Guid;
        BlankGUID: Guid;
        TaxGroupValuesDontMatchErr: Label 'The tax group values do not match to a specific Tax Group.', Locked = true;
        TaxGroupIdDoesNotMatchATaxGroupErr: Label 'The "taxGroupId" does not match to a Tax Group.', Locked = true;
        TaxGroupCodeDoesNotMatchATaxGroupErr: Label 'The "taxGroupCode" does not match to a Tax Group.', Locked = true;
        ItemCategoryIdDoesNotMatchAnItemCategoryGroupErr: Label 'The "itemCategoryId" does not match to a specific ItemCategory group.', Locked = true;
        ItemCategoriesValuesDontMatchErr: Label 'The item categories values do not match to a specific item category.';
        ItemCategoryCodeDoesNotMatchATaxGroupErr: Label 'The "itemCategoryCode" does not match to a Item Category.', Locked = true;

    local procedure SetCalculatedFields()
    var
        UnitOfMeasure: Record "Unit of Measure";
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
    begin
        // UOM
        BaseUnitOfMeasureJSONText := GraphCollectionMgtItem.ItemUnitOfMeasureToJSON(Rec, "Base Unit of Measure");
        BaseUnitOfMeasureCode := "Base Unit of Measure";
        if UnitOfMeasure.Get(BaseUnitOfMeasureCode) then
            BaseUnitOfMeasureId := UnitOfMeasure.Id
        else
            BaseUnitOfMeasureId := BlankGUID;

        // Inventory
        CalcFields(Inventory);
        InventoryValue := Inventory;
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(Id);
        Clear(BaseUnitOfMeasureId);
        Clear(BaseUnitOfMeasureCode);
        Clear(BaseUnitOfMeasureJSONText);
        Clear(InventoryValue);
        TempFieldSet.DeleteAll;
    end;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        if TempFieldSet.Get(DATABASE::Item, FieldNo) then
            exit;

        TempFieldSet.Init;
        TempFieldSet.TableNo := DATABASE::Item;
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;
}

