codeunit 730 "Copy Item"
{
    TableNo = Item;

    trigger OnRun()
    var
        CopyItemPage: Page "Copy Item";
        i: Integer;
    begin
        CopyItemPage.SetItem(Rec);
        if CopyItemPage.RunModal() <> ACTION::OK then
            exit;

        LockTable();

        CopyItemPage.GetParameters(CopyItemBuffer);
        InventorySetup.Get();
        SourceItem.Get(CopyItemBuffer."Source Item No.");

        for i := 1 to CopyItemBuffer."Number of Copies" do
            CopyItem(i);

        OnRunOnAfterItemCopied(CopyItemBuffer);

        ShowNotification(Rec);
    end;

    var
        SourceItem: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer" temporary;
        InventorySetup: Record "Inventory Setup";
        FirstItemNo: Code[20];
        LastItemNo: Code[20];
        TargetItemDoesNotExistErr: Label 'Target item number %1 already exists.', Comment = '%1 - item number.';
        ItemCopiedMsg: Label 'Item %1 was successfully copied.', Comment = '%1 - item number';
        ShowCreatedItemTxt: Label 'Show created item.';
        ShowCreatedItemsTxt: Label 'Show created items.';

    local procedure SetTargetItemNo(var TargetItem: Record Item; CopyCounter: Integer)
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        with TargetItem do begin
            if CopyItemBuffer."Target No. Series" <> '' then begin
                OnBeforeInitSeries(SourceItem, InventorySetup);
                InventorySetup.TestField("Item Nos.");
                "No." := '';
                NoSeriesMgt.InitSeries(
                  InventorySetup."Item Nos.", CopyItemBuffer."Target No. Series", 0D, "No.", CopyItemBuffer."Target No. Series");
                "No. Series" := CopyItemBuffer."Target No. Series";
            end else begin
                NoSeriesMgt.TestManual(InventorySetup."Item Nos.");

                if CopyCounter > 1 then
                    CopyItemBuffer."Target Item No." := IncStr(CopyItemBuffer."Target Item No.");
                "No." := CopyItemBuffer."Target Item No.";
            end;

            CheckExistingItem("No.");

            if CopyCounter = 1 then
                FirstItemNo := "No.";
            LastItemNo := "No.";
        end;
    end;

    local procedure InitTargetItem(var TargetItem: Record Item; CopyCounter: Integer)
    begin
        with TargetItem do begin
            TransferFields(SourceItem);

            SetTargetItemNo(TargetItem, CopyCounter);

            "Last Date Modified" := Today;
            "Created From Nonstock Item" := false;
        end;
    end;

    procedure CopyItem(CopyCounter: Integer)
    var
        TargetItem: Record Item;
    begin
        InitTargetItem(TargetItem, CopyCounter);

        if not (CopyItemBuffer."Sales Line Discounts" or CopyItemBuffer."Purchase Line Discounts") then
            TargetItem."Item Disc. Group" := '';

        CopyItemPicture(SourceItem, TargetItem);
        CopyItemUnisOfMeasure(SourceItem, TargetItem);
        CopyItemGlobalDimensions(SourceItem, TargetItem);
        TargetItem.Insert();

        CopyExtendedTexts(SourceItem."No.", TargetItem);
        CopyItemDimensions(SourceItem, TargetItem."No.");
        CopyItemVariants(SourceItem."No.", TargetItem."No.");
        CopyItemTranslations(SourceItem."No.", TargetItem."No.");
        CopyItemComments(SourceItem."No.", TargetItem."No.");
        CopyBOMComponents(SourceItem."No.", TargetItem."No.");
        CopyItemVendors(SourceItem."No.", TargetItem."No.");
        CopyTroubleshootingSetup(SourceItem."No.", TargetItem."No.");
        CopyItemResourceSkills(SourceItem."No.", TargetItem."No.");
        CopyItemSalesPrices(SourceItem."No.", TargetItem."No.");
        CopySalesLineDiscounts(SourceItem."No.", TargetItem."No.");
        CopyPurchasePrices(SourceItem."No.", TargetItem."No.");
        CopyPurchaseLineDiscounts(SourceItem."No.", TargetItem."No.");
        CopyItemAttributes(SourceItem."No.", TargetItem."No.");
        CopyItemCrossReferences(SourceItem."No.", TargetItem."No.");

        OnAfterCopyItem(CopyItemBuffer, SourceItem, TargetItem);
    end;

    local procedure CheckExistingItem(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then
            Error(TargetItemDoesNotExistErr, ItemNo);
    end;

    local procedure CopyItemPicture(FromItem: Record Item; var ToItem: Record Item)
    begin
        if CopyItemBuffer.Picture then
            ToItem.Picture := FromItem.Picture
        else
            Clear(ToItem.Picture);
    end;

    procedure CopyItemRelatedTable(TableId: Integer; FieldNo: Integer; FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        SourceRecRef: RecordRef;
        TargetRecRef: RecordRef;
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        SourceRecRef.Open(TableId);
        SourceFieldRef := SourceRecRef.Field(FieldNo);
        SourceFieldRef.SetRange(FromItemNo);
        if SourceRecRef.FindSet() then
            repeat
                TargetRecRef := SourceRecRef.Duplicate();
                TargetFieldRef := TargetRecRef.Field(FieldNo);
                TargetFieldRef.Value(ToItemNo);
                TargetRecRef.Insert();
            until SourceRecRef.Next() = 0;
    end;

    procedure CopyItemRelatedTableFromRecRef(var SourceRecRef: RecordRef; FieldNo: Integer; FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        TargetRecRef: RecordRef;
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        SourceFieldRef := SourceRecRef.Field(FieldNo);
        SourceFieldRef.SetRange(FromItemNo);
        if SourceRecRef.FindSet() then
            repeat
                TargetRecRef := SourceRecRef.Duplicate();
                TargetFieldRef := TargetRecRef.Field(FieldNo);
                TargetFieldRef.Value(ToItemNo);
                TargetRecRef.Insert();
            until SourceRecRef.Next() = 0;
    end;

    local procedure CopyItemComments(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        CommentLine: Record "Comment Line";
        RecRef: RecordRef;
    begin
        if not CopyItemBuffer.Comments then
            exit;

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Item);

        RecRef.GetTable(CommentLine);
        CopyItemRelatedTableFromRecRef(RecRef, CommentLine.FieldNo("No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemUnisOfMeasure(FromItem: Record Item; var ToItem: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RecRef: RecordRef;
    begin
        if CopyItemBuffer."Units of Measure" then begin
            ItemUnitOfMeasure.SetRange("Item No.", FromItem."No.");
            RecRef.GetTable(ItemUnitOfMeasure);
            CopyItemRelatedTableFromRecRef(RecRef, ItemUnitOfMeasure.FieldNo("Item No."), FromItem."No.", ToItem."No.");
        end else
            if CopyItemBuffer."General Item Information" then begin
                ToItem."Base Unit of Measure" := '';
                ToItem."Sales Unit of Measure" := '';
                ToItem."Purch. Unit of Measure" := '';
                ToItem."Put-away Unit of Measure Code" := '';
            end;
    end;

    local procedure CopyItemVariants(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ItemVariant: Record "Item Variant";
    begin
        if not CopyItemBuffer."Item Variants" then
            exit;

        CopyItemRelatedTable(DATABASE::"Item Variant", ItemVariant.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemTranslations(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ItemTranslation: Record "Item Translation";
        RecRef: RecordRef;
    begin
        if not CopyItemBuffer.Translations then
            exit;

        ItemTranslation.SetRange("Item No.", FromItemNo);
        if not CopyItemBuffer."Item Variants" then
            ItemTranslation.SetRange("Variant Code", '');

        RecRef.GetTable(ItemTranslation);
        CopyItemRelatedTableFromRecRef(RecRef, ItemTranslation.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyExtendedTexts(FromItemNo: Code[20]; var TargetItem: Record Item)
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        NewExtendedTextHeader: Record "Extended Text Header";
        NewExtendedTextLine: Record "Extended Text Line";
    begin
        if not CopyItemBuffer."Extended Texts" then
            exit;

        ExtendedTextHeader.SetRange("Table Name", ExtendedTextHeader."Table Name"::Item);
        ExtendedTextHeader.SetRange("No.", FromItemNo);
        if ExtendedTextHeader.FindSet() then
            repeat
                ExtendedTextLine.SetRange("Table Name", ExtendedTextHeader."Table Name");
                ExtendedTextLine.SetRange("No.", ExtendedTextHeader."No.");
                ExtendedTextLine.SetRange("Language Code", ExtendedTextHeader."Language Code");
                ExtendedTextLine.SetRange("Text No.", ExtendedTextHeader."Text No.");
                if ExtendedTextLine.FindSet() then
                    repeat
                        NewExtendedTextLine.TransferFields(ExtendedTextLine);
                        NewExtendedTextLine."No." := TargetItem."No.";
                        NewExtendedTextLine.Insert();
                    until ExtendedTextLine.Next() = 0;

                NewExtendedTextHeader.TransferFields(ExtendedTextHeader);
                NewExtendedTextHeader."No." := TargetItem."No.";
                NewExtendedTextHeader.Insert();
            until ExtendedTextHeader.Next() = 0;

        OnAfterCopyExtendedTexts(SourceItem, TargetItem);
    end;

    local procedure CopyBOMComponents(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
    begin
        if not CopyItemBuffer."BOM Components" then
            exit;

        CopyItemRelatedTable(DATABASE::"BOM Component", BOMComponent.FieldNo("Parent Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemVendors(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ItemVendor: Record "Item Vendor";
    begin
        if not CopyItemBuffer."Item Vendors" then
            exit;

        CopyItemRelatedTable(DATABASE::"Item Vendor", ItemVendor.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemDimensions(FromItem: Record Item; ToItemNo: Code[20])
    var
        DefaultDim: Record "Default Dimension";
        NewDefaultDim: Record "Default Dimension";
    begin
        if CopyItemBuffer.Dimensions then begin
            DefaultDim.SetRange("Table ID", DATABASE::Item);
            DefaultDim.SetRange("No.", FromItem."No.");
            if DefaultDim.FindSet() then
                repeat
                    NewDefaultDim.TransferFields(DefaultDim);
                    NewDefaultDim."No." := ToItemNo;
                    NewDefaultDim.Insert();
                until DefaultDim.Next() = 0;
        end;
    end;

    local procedure CopyItemGlobalDimensions(FromItem: Record Item; var ToItem: Record Item)
    begin
        if CopyItemBuffer.Dimensions then begin
            ToItem."Global Dimension 1 Code" := FromItem."Global Dimension 1 Code";
            ToItem."Global Dimension 2 Code" := FromItem."Global Dimension 2 Code";
        end else
            if CopyItemBuffer."General Item Information" then begin
                ToItem."Global Dimension 1 Code" := '';
                ToItem."Global Dimension 2 Code" := '';
            end;
    end;

    local procedure CopyTroubleshootingSetup(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        TroubleshootingSetup: Record "Troubleshooting Setup";
        RecRef: RecordRef;
    begin
        if not CopyItemBuffer.Troubleshooting then
            exit;

        TroubleshootingSetup.SetRange(Type, TroubleshootingSetup.Type::Item);

        RecRef.GetTable(TroubleshootingSetup);
        CopyItemRelatedTableFromRecRef(RecRef, TroubleshootingSetup.FieldNo("No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemResourceSkills(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ResourceSkill: Record "Resource Skill";
        RecRef: RecordRef;
    begin
        if not CopyItemBuffer."Resource Skills" then
            exit;

        ResourceSkill.SetRange(Type, ResourceSkill.Type::Item);

        RecRef.GetTable(ResourceSkill);
        CopyItemRelatedTableFromRecRef(RecRef, ResourceSkill.FieldNo("No."), FromItemNo, ToItemNo);
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    local procedure CopyItemSalesPrices(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        SalesPrice: Record "Sales Price";
    begin
        if not CopyItemBuffer."Sales Prices" then
            exit;

        CopyItemRelatedTable(DATABASE::"Sales Price", SalesPrice.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    local procedure CopySalesLineDiscounts(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        SalesLineDiscount: Record "Sales Line Discount";
        RecRef: RecordRef;
    begin
        if not CopyItemBuffer."Sales Line Discounts" then
            exit;

        SalesLineDiscount.SetRange(Type, SalesLineDiscount.Type::Item);

        RecRef.GetTable(SalesLineDiscount);
        CopyItemRelatedTableFromRecRef(RecRef, SalesLineDiscount.FieldNo(Code), FromItemNo, ToItemNo);
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    local procedure CopyPurchasePrices(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        PurchasePrice: Record "Purchase Price";
    begin
        if not CopyItemBuffer."Purchase Prices" then
            exit;

        CopyItemRelatedTable(DATABASE::"Purchase Price", PurchasePrice.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    local procedure CopyPurchaseLineDiscounts(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        PurchLineDiscount: Record "Purchase Line Discount";
    begin
        if not CopyItemBuffer."Purchase Line Discounts" then
            exit;

        CopyItemRelatedTable(DATABASE::"Purchase Line Discount", PurchLineDiscount.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemAttributes(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        RecRef: RecordRef;
    begin
        if not CopyItemBuffer.Attributes then
            exit;

        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);

        RecRef.GetTable(ItemAttributeValueMapping);
        CopyItemRelatedTableFromRecRef(RecRef, ItemAttributeValueMapping.FieldNo("No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemCrossReferences(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ItemCrossReference: Record "Item Cross Reference";
    begin
        if not CopyItemBuffer."Item Cross References" then
            exit;

        CopyItemRelatedTable(DATABASE::"Item Cross Reference", ItemCrossReference.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    local procedure ShowNotification(Item: Record Item)
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ItemCopiedNotification: Notification;
        ShowCreatedActionCaption: Text;
    begin
        ItemCopiedNotification.Id := CreateGuid();
        ItemCopiedNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        ItemCopiedNotification.SetData('FirstItemNo', FirstItemNo);
        ItemCopiedNotification.SetData('LastItemNo', LastItemNo);
        ItemCopiedNotification.Message(StrSubstNo(ItemCopiedMsg, Item."No."));
        if FirstItemNo = LastItemNo then
            ShowCreatedActionCaption := ShowCreatedItemTxt
        else
            ShowCreatedActionCaption := ShowCreatedItemsTxt;
        ItemCopiedNotification.AddAction(ShowCreatedActionCaption, CODEUNIT::"Copy Item", 'ShowCreatedItems');
        NotificationLifecycleMgt.SendNotification(ItemCopiedNotification, Item.RecordId);
    end;

    procedure ShowCreatedItems(var ItemCopiedNotification: Notification)
    var
        Item: Record Item;
    begin
        Item.SetRange(
          "No.",
          ItemCopiedNotification.GetData('FirstItemNo'),
          ItemCopiedNotification.GetData('LastItemNo'));
        if Item.FindFirst() then
            if Item.Count = 1 then
                PAGE.RunModal(PAGE::"Item Card", Item)
            else
                PAGE.RunModal(PAGE::"Item List", Item);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyExtendedTexts(var SourceItem: Record Item; var TargetItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItem(var CopyItemBuffer: Record "Copy Item Buffer"; SourceItem: Record Item; var TargetItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterItemCopied(var CopyItemBuffer: Record "Copy Item Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSeries(var Item: Record Item; var InventorySetup: Record "Inventory Setup")
    begin
    end;
}

