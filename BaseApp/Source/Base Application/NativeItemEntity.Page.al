page 2802 "Native - Item Entity"
{
    Caption = 'invoicingItems', Locked = true;
    DelayedInsert = true;
    ODataKeyFields = Id;
    PageType = List;
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
                    ToolTip = 'Specifies the ID of the base unit of measure.';

                    trigger OnValidate()
                    begin
                        ValidateUnitOfMeasure.SetRange(Id, BaseUnitOfMeasureId);
                        if not ValidateUnitOfMeasure.FindFirst then
                            Error(BaseUnitOfMeasureIdDoesNotMatchAUnitOfMeasureErr);

                        BaseUnitOfMeasureCode := ValidateUnitOfMeasure.Code;

                        RegisterFieldSet(FieldNo("Unit of Measure Id"));
                        RegisterFieldSet(FieldNo("Base Unit of Measure"));
                    end;
                }
                field(baseUnitOfMeasureIntStdCode; BaseUnitOfMeasureInternationalStandardCode)
                {
                    ApplicationArea = All;
                    Caption = 'BaseUnitOfMeasureInternationalStandardCode', Locked = true;
                    ToolTip = 'Specifies the international standard code of the base unit of measure.';

                    trigger OnValidate()
                    begin
                        if ValidateUnitOfMeasure."International Standard Code" <> '' then begin
                            if ValidateUnitOfMeasure."International Standard Code" <> BaseUnitOfMeasureInternationalStandardCode then
                                Error(BaseUnitOfMeasureValuesDontMatchErr);
                            exit;
                        end;

                        ValidateUnitOfMeasure.SetRange("International Standard Code", BaseUnitOfMeasureInternationalStandardCode);
                        if not ValidateUnitOfMeasure.FindFirst then
                            Error(BaseUnitOfMeasureIntStdCodeDoesNotMatchAUnitOfMeasureErr);
                        if ValidateUnitOfMeasure.Count > 1 then
                            Error(BaseUnitOfMeasureIntStdCodeMatchesManyUnitsOfMeasureErr);

                        BaseUnitOfMeasureCode := ValidateUnitOfMeasure.Code;

                        RegisterFieldSet(FieldNo("Unit of Measure Id"));
                        RegisterFieldSet(FieldNo("Base Unit of Measure"));
                    end;
                }
                field(baseUnitOfMeasureDescription; BaseUnitOfMeasureDescription)
                {
                    ApplicationArea = All;
                    Caption = 'BaseUnitOfMeasureDescription', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the international standard code of the base unit of measure.';
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
                field(taxGroupId; TaxGroupId)
                {
                    ApplicationArea = All;
                    Caption = 'TaxGroupId', Locked = true;
                    ToolTip = 'Specifies the ID of the tax group or VAT group.';

                    trigger OnValidate()
                    var
                        ValidateVATProdPostingGroup: Record "VAT Product Posting Group";
                        ValidateTaxGroup: Record "Tax Group";
                    begin
                        if TaxGroupId = BlankGUID then begin
                            TaxGroupCode := '';
                            "Tax Group Code" := '';
                            "Tax Group Id" := BlankGUID;
                            "VAT Prod. Posting Group" := '';
                            exit;
                        end;

                        if GeneralLedgerSetup.UseVat then begin
                            ValidateVATProdPostingGroup.SetRange(Id, TaxGroupId);
                            if not ValidateVATProdPostingGroup.FindFirst then
                                Error(VATGroupIdDoesNotMatchAVATGroupErr);

                            TaxGroupCode := ValidateVATProdPostingGroup.Code;
                            "VAT Prod. Posting Group" := TaxGroupCode;
                            RegisterFieldSet(FieldNo("VAT Prod. Posting Group"));
                        end else begin
                            ValidateTaxGroup.SetRange(Id, TaxGroupId);
                            if not ValidateTaxGroup.FindFirst then
                                Error(TaxGroupIdDoesNotMatchATaxGroupErr);

                            TaxGroupCode := ValidateTaxGroup.Code;
                            "Tax Group Code" := TaxGroupCode;
                            "Tax Group Id" := TaxGroupId;
                            RegisterFieldSet(FieldNo("Tax Group Code"));
                            RegisterFieldSet(FieldNo("Tax Group Id"));
                        end;
                    end;
                }
                field(taxGroupCode; TaxGroupCode)
                {
                    ApplicationArea = All;
                    Caption = 'TaxGroupCode', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the code of the tax group or VAT group.';
                }
                field(taxable; Taxable)
                {
                    ApplicationArea = All;
                    Caption = 'Taxable', Locked = true;
                    ToolTip = 'Specifies the tax group code for the tax-detail entry.';

                    trigger OnValidate()
                    var
                        GeneralLedgerSetup: Record "General Ledger Setup";
                        TaxGroup: Record "Tax Group";
                        NativeEDMTypes: Codeunit "Native - EDM Types";
                    begin
                        if GeneralLedgerSetup.UseVat then
                            exit;

                        if not NativeEDMTypes.GetTaxGroupFromTaxable(Taxable, TaxGroup) then
                            exit;

                        Validate("Tax Group Id", TaxGroup.Id);
                        RegisterFieldSet(FieldNo("Tax Group Id"));
                        RegisterFieldSet(FieldNo("Tax Group Code"));
                    end;
                }
                field(lastModifiedDateTime; "Last DateTime Modified")
                {
                    ApplicationArea = All;
                    Caption = 'LastModifiedDateTime', Locked = true;
                    Editable = false;
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
        Item: Record Item;
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        BaseUnitOfMeasureJSONText: Text;
    begin
        if "No." <> '' then
            if Item.Get("No.") then
                Error(ItemExistsErr);

        if TempFieldSet.Get(DATABASE::Item, FieldNo("Base Unit of Measure")) then
            BaseUnitOfMeasureJSONText := GraphCollectionMgtItem.ItemUnitOfMeasureToJSON(Rec, BaseUnitOfMeasureCode);

        GraphCollectionMgtItem.InsertItem(Rec, TempFieldSet, BaseUnitOfMeasureJSONText);
        SetCalculatedFields;
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Item: Record Item;
    begin
        if TempFieldSet.Get(DATABASE::Item, FieldNo("Base Unit of Measure")) then
            Validate("Base Unit of Measure", BaseUnitOfMeasureCode);

        Item.SetRange(Id, Id);
        Item.FindFirst;

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

    trigger OnOpenPage()
    begin
        BindSubscription(NativeAPILanguageHandler);
        SelectLatestVersion;
    end;

    var
        TempFieldSet: Record "Field" temporary;
        GeneralLedgerSetup: Record "General Ledger Setup";
        ValidateUnitOfMeasure: Record "Unit of Measure";
        NativeAPILanguageHandler: Codeunit "Native API - Language Handler";
        BlankGUID: Guid;
        BaseUnitOfMeasureId: Guid;
        TaxGroupId: Guid;
        TaxGroupCode: Code[20];
        BaseUnitOfMeasureInternationalStandardCode: Code[10];
        BaseUnitOfMeasureCode: Code[10];
        BaseUnitOfMeasureDescription: Text[50];
        InventoryValue: Decimal;
        Taxable: Boolean;
        BaseUnitOfMeasureValuesDontMatchErr: Label 'The base unit of measure values do not match to a specific Unit of Measure.';
        BaseUnitOfMeasureIdDoesNotMatchAUnitOfMeasureErr: Label 'The "baseUnitOfMeasureId" does not match to a Unit of Measure.', Locked = true;
        BaseUnitOfMeasureIntStdCodeDoesNotMatchAUnitOfMeasureErr: Label 'The "baseUnitOfMeasureIntStdCode" does not match to a Unit of Measure.', Locked = true;
        BaseUnitOfMeasureIntStdCodeMatchesManyUnitsOfMeasureErr: Label 'The "baseUnitOfMeasureIntStdCode" matches to many Units of Measure.', Locked = true;
        TaxGroupIdDoesNotMatchATaxGroupErr: Label 'The "taxGroupId" does not match a Tax Group.', Locked = true;
        VATGroupIdDoesNotMatchAVATGroupErr: Label 'The "taxGroupId" does not match a VAT Product Posting Group.', Locked = true;
        ItemExistsErr: Label 'The item already exists.', Locked = true;

    local procedure SetCalculatedFields()
    begin
        SetCalculatedUnitsOfMeasureFields;
        SetCalculatedTaxGroupFields;
        CalcFields(Inventory);
        InventoryValue := Inventory;
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(Id);
        Clear(BaseUnitOfMeasureId);
        Clear(BaseUnitOfMeasureInternationalStandardCode);
        Clear(BaseUnitOfMeasureCode);
        Clear(BaseUnitOfMeasureDescription);
        Clear(Taxable);
        Clear(TaxGroupCode);
        Clear(TaxGroupId);
        Clear(InventoryValue);
        TempFieldSet.DeleteAll();
    end;

    local procedure SetCalculatedUnitsOfMeasureFields()
    var
        UnitOfMeasure: Record "Unit of Measure";
        EmptyGuid: Guid;
    begin
        if UnitOfMeasure.Get("Base Unit of Measure") then begin
            BaseUnitOfMeasureId := UnitOfMeasure.Id;
            BaseUnitOfMeasureInternationalStandardCode := UnitOfMeasure."International Standard Code";
            BaseUnitOfMeasureCode := "Base Unit of Measure";
            BaseUnitOfMeasureDescription := UnitOfMeasure.Description;
            exit;
        end;

        BaseUnitOfMeasureId := EmptyGuid;
        BaseUnitOfMeasureInternationalStandardCode := '';
        BaseUnitOfMeasureCode := '';
        BaseUnitOfMeasureDescription := '';
    end;

    local procedure SetCalculatedTaxGroupFields()
    var
        TaxGroup: Record "Tax Group";
        TaxSetup: Record "Tax Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        EmptyGuid: Guid;
    begin
        if GeneralLedgerSetup.UseVat and VATProductPostingGroup.Get("VAT Prod. Posting Group") then begin
            TaxGroupCode := VATProductPostingGroup.Code;
            TaxGroupId := VATProductPostingGroup.Id;
            Taxable := true;
        end else
            if TaxGroup.Get("Tax Group Code") then begin
                "Tax Group Id" := TaxGroup.Id;
                TaxGroupId := "Tax Group Id";
                TaxGroupCode := "Tax Group Code";
                if TaxSetup.Get then
                    Taxable := "Tax Group Code" <> TaxSetup."Non-Taxable Tax Group Code"
                else
                    Taxable := false;
            end else begin
                TaxGroupId := EmptyGuid;
                TaxGroupCode := '';
                "Tax Group Id" := EmptyGuid;
                Taxable := false;
            end;
    end;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        if TempFieldSet.Get(DATABASE::Item, FieldNo) then
            exit;

        TempFieldSet.Init();
        TempFieldSet.TableNo := DATABASE::Item;
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;
}

