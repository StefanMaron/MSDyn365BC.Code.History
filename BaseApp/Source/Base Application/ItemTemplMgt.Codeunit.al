codeunit 1336 "Item Templ. Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        VATPostingSetupErr: Label 'VAT Posting Setup does not exist. "VAT Bus. Posting Group" = %1, "VAT Prod. Posting Group" = %2.', Comment = '%1 - vat bus. posting group code; %2 - vat prod. posting group code';

    procedure CreateItemFromTemplate(var Item: Record Item; var IsHandled: Boolean) Result: Boolean
    var
        ItemTempl: Record "Item Templ.";
    begin
        IsHandled := false;
        OnBeforeCreateItemFromTemplate(Item, Result, IsHandled);
        if IsHandled then
            exit(Result);

        IsHandled := true;

        OnCreateItemFromTemplateOnBeforeSelectItemTemplate(Item, ItemTempl);
        if not SelectItemTemplate(ItemTempl) then
            exit(false);

        Item.Init();
        InitItemNo(Item, ItemTempl);
        Item.Insert(true);

        ApplyItemTemplate(Item, ItemTempl);

        exit(true);
    end;

    procedure ApplyItemTemplate(var Item: Record Item; ItemTempl: Record "Item Templ.")
    begin
        ApplyTemplate(Item, ItemTempl);
        InsertDimensions(Item."No.", ItemTempl.Code, Database::Item, Database::"Item Templ.");
    end;

    local procedure ApplyTemplate(var Item: Record Item; ItemTempl: Record "Item Templ.")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemRecRef: RecordRef;
        EmptyItemRecRef: RecordRef;
        ItemTemplRecRef: RecordRef;
        EmptyItemTemplRecRef: RecordRef;
        ItemFldRef: FieldRef;
        EmptyItemFldRef: FieldRef;
        ItemTemplFldRef: FieldRef;
        EmptyItemTemplFldRef: FieldRef;
        i: Integer;
        FieldExclusionList: List of [Integer];
    begin
        ItemRecRef.GetTable(Item);
        EmptyItemRecRef.Open(Database::Item);
        EmptyItemRecRef.Init();
        ItemTemplRecRef.GetTable(ItemTempl);
        EmptyItemTemplRecRef.Open(Database::"Item Templ.");
        EmptyItemTemplRecRef.Init();

        FillFieldExclusionList(FieldExclusionList);

        for i := 3 to ItemTemplRecRef.FieldCount do begin
            ItemTemplFldRef := ItemTemplRecRef.FieldIndex(i);
            if TemplateFieldCanBeProcessed(ItemTemplFldRef, FieldExclusionList) then begin
                ItemFldRef := ItemRecRef.Field(ItemTemplFldRef.Number);
                EmptyItemFldRef := EmptyItemRecRef.Field(ItemTemplFldRef.Number);
                EmptyItemTemplFldRef := EmptyItemTemplRecRef.Field(ItemTemplFldRef.Number);
                if (ItemFldRef.Value = EmptyItemFldRef.Value) and (ItemTemplFldRef.Value <> EmptyItemTemplFldRef.Value) then
                    ItemFldRef.Value := ItemTemplFldRef.Value;
            end;
        end;
        ItemRecRef.SetTable(Item);
        if ItemTempl."Base Unit of Measure" <> '' then
            Item.Validate("Base Unit of Measure", ItemTempl."Base Unit of Measure")
        else
            Item.Validate("Base Unit of Measure", GetUnitOfMeasureCode());
        if ItemTempl."Price Includes VAT" then begin
            SalesReceivablesSetup.Get();
            if not VATPostingSetup.Get(SalesReceivablesSetup."VAT Bus. Posting Gr. (Price)", ItemTempl."VAT Prod. Posting Group") then
                Error(VATPostingSetupErr, SalesReceivablesSetup."VAT Bus. Posting Gr. (Price)", ItemTempl."VAT Prod. Posting Group");
            Item.Validate("Price Includes VAT", ItemTempl."Price Includes VAT");
        end;
        OnApplyTemplateOnBeforeItemModify(Item, ItemTempl);
        Item.Modify(true);
    end;

    local procedure SelectItemTemplate(var ItemTempl: Record "Item Templ."): Boolean
    var
        SelectItemTemplList: Page "Select Item Templ. List";
    begin
        if ItemTempl.Count = 1 then begin
            ItemTempl.FindFirst();
            exit(true);
        end;

        if (ItemTempl.Count > 1) and GuiAllowed then begin
            SelectItemTemplList.SetTableView(ItemTempl);
            SelectItemTemplList.LookupMode(true);
            if SelectItemTemplList.RunModal() = Action::LookupOK then begin
                SelectItemTemplList.GetRecord(ItemTempl);
                exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure InsertDimensions(DestNo: Code[20]; SourceNo: Code[20]; DestTableId: Integer; SourceTableId: Integer)
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        SourceDefaultDimension.SetRange("Table ID", SourceTableId);
        SourceDefaultDimension.SetRange("No.", SourceNo);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", DestTableId);
                DestDefaultDimension.Validate("No.", DestNo);
                DestDefaultDimension.Validate("Dimension Code", SourceDefaultDimension."Dimension Code");
                DestDefaultDimension.Validate("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
                DestDefaultDimension.Validate("Value Posting", SourceDefaultDimension."Value Posting");
                if not DestDefaultDimension.Get(DestDefaultDimension."Table ID", DestDefaultDimension."No.", DestDefaultDimension."Dimension Code") then
                    DestDefaultDimension.Insert(true);
            until SourceDefaultDimension.Next() = 0;
    end;

    procedure ItemTemplatesAreNotEmpty(var IsHandled: Boolean): Boolean
    var
        ItemTempl: Record "Item Templ.";
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        if not TemplateFeatureMgt.IsEnabled() then
            exit(false);

        IsHandled := true;
        exit(not ItemTempl.IsEmpty);
    end;

    procedure InsertItemFromTemplate(var Item: Record Item) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnInsertItemFromTemplate(Item, Result, IsHandled);
    end;

    procedure TemplatesAreNotEmpty() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnTemplatesAreNotEmpty(Result, IsHandled);
    end;

    procedure IsEnabled() Result: Boolean
    var
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        Result := TemplateFeatureMgt.IsEnabled();

        OnAfterIsEnabled(Result);
    end;

    procedure UpdateItemFromTemplate(var Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        OnUpdateItemFromTemplate(Item, IsHandled);
    end;

    local procedure UpdateFromTemplate(var Item: Record Item; var IsHandled: Boolean)
    var
        ItemTempl: Record "Item Templ.";
    begin
        IsHandled := false;
        OnBeforeUpdateFromTemplate(Item, IsHandled);
        if IsHandled then
            exit;

        if not CanBeUpdatedFromTemplate(ItemTempl, IsHandled) then
            exit;

        ApplyItemTemplate(Item, ItemTempl);
    end;

    procedure UpdateItemsFromTemplate(var Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        OnUpdateItemsFromTemplate(Item, IsHandled);
    end;

    local procedure UpdateMultipleFromTemplate(var Item: Record Item; var IsHandled: Boolean)
    var
        ItemTempl: Record "Item Templ.";
    begin
        IsHandled := false;
        OnBeforeUpdateMultipleFromTemplate(Item, IsHandled);
        if IsHandled then
            exit;

        if not CanBeUpdatedFromTemplate(ItemTempl, IsHandled) then
            exit;

        if Item.FindSet() then
            repeat
                ApplyItemTemplate(Item, ItemTempl);
            until Item.Next() = 0;
    end;

    local procedure CanBeUpdatedFromTemplate(var ItemTempl: Record "Item Templ."; var IsHandled: Boolean): Boolean
    begin
        IsHandled := true;

        if not SelectItemTemplate(ItemTempl) then
            exit(false);

        exit(true);
    end;

    procedure SaveAsTemplate(Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        OnSaveAsTemplate(Item, IsHandled);
    end;

    procedure CreateTemplateFromItem(Item: Record Item; var IsHandled: Boolean)
    var
        ItemTempl: Record "Item Templ.";
    begin
        IsHandled := false;
        OnBeforeCreateTemplateFromItem(Item, IsHandled);
        if IsHandled then
            exit;

        IsHandled := true;

        InsertTemplateFromItem(ItemTempl, Item);
        InsertDimensions(ItemTempl.Code, Item."No.", Database::"Item Templ.", Database::Item);
        ItemTempl.Get(ItemTempl.Code);
        ShowItemTemplCard(ItemTempl);
    end;

    local procedure InsertTemplateFromItem(var ItemTempl: Record "Item Templ."; Item: Record Item)
    begin
        ItemTempl.Init();
        ItemTempl.Code := GetItemTemplCode();

        ItemTempl.Type := Item.Type;
        ItemTempl."Inventory Posting Group" := Item."Inventory Posting Group";
        ItemTempl."Item Disc. Group" := Item."Item Disc. Group";
        ItemTempl."Allow Invoice Disc." := Item."Allow Invoice Disc.";
        ItemTempl."Price/Profit Calculation" := Item."Price/Profit Calculation";
        ItemTempl."Profit %" := Item."Profit %";
        ItemTempl."Costing Method" := Item."Costing Method";
        ItemTempl."Indirect Cost %" := Item."Indirect Cost %";
        ItemTempl."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        ItemTempl."Automatic Ext. Texts" := Item."Automatic Ext. Texts";
        ItemTempl."Tax Group Code" := Item."Tax Group Code";
        ItemTempl."VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
        ItemTempl."Item Category Code" := Item."Item Category Code";
        ItemTempl."Service Item Group" := Item."Service Item Group";
        ItemTempl."Warehouse Class Code" := Item."Warehouse Class Code";
        ItemTempl."Item Tracking Code" := Item."Item Tracking Code";
        ItemTempl."Serial Nos." := Item."Serial Nos.";
        ItemTempl."Lot Nos." := Item."Lot Nos.";
        ItemTempl.Blocked := Item.Blocked;
        ItemTempl."Sales Blocked" := Item."Sales Blocked";
        ItemTempl."Purchasing Blocked" := Item."Purchasing Blocked";
        ItemTempl."Base Unit of Measure" := Item."Base Unit of Measure";
        ItemTempl."Price Includes VAT" := Item."Price Includes VAT";
        OnInsertTemplateFromItemOnBeforeItemTemplInsert(ItemTempl, Item);
        ItemTempl.Insert();
    end;

    local procedure GetItemTemplCode() ItemTemplCode: Code[20]
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
    begin
        if ItemTempl.FindLast() and (IncStr(ItemTempl.Code) <> '') then
            ItemTemplCode := ItemTempl.Code
        else
            ItemTemplCode := CopyStr(Item.TableCaption, 1, 4) + '000001';

        while ItemTempl.Get(ItemTemplCode) do
            ItemTemplCode := IncStr(ItemTemplCode);
    end;

    local procedure ShowItemTemplCard(ItemTempl: Record "Item Templ.")
    var
        ItemTemplCard: Page "Item Templ. Card";
    begin
        if not GuiAllowed then
            exit;

        Commit();
        ItemTemplCard.SetRecord(ItemTempl);
        ItemTemplCard.LookupMode := true;
        if ItemTemplCard.RunModal() = Action::LookupCancel then begin
            ItemTempl.Get(ItemTempl.Code);
            ItemTempl.Delete(true);
        end;
    end;

    procedure ShowTemplates()
    var
        IsHandled: Boolean;
    begin
        OnShowTemplates(IsHandled);
    end;

    local procedure ShowItemTemplList(var IsHandled: Boolean)
    begin
        IsHandled := true;
        Page.Run(Page::"Item Templ. List");
    end;

    local procedure InitItemNo(var Item: Record Item; ItemTempl: Record "Item Templ.")
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        if ItemTempl."No. Series" = '' then
            exit;

        NoSeriesManagement.InitSeries(ItemTempl."No. Series", '', 0D, Item."No.", Item."No. Series");
    end;

    local procedure GetUnitOfMeasureCode(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.SetRange("International Standard Code", 'EA');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        UnitOfMeasure.SetRange("International Standard Code");
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        exit('');
    end;

    local procedure TemplateFieldCanBeProcessed(TemplateFldRef: FieldRef; FieldExclusionList: List of [Integer]): Boolean
    begin
        exit(not (FieldExclusionList.Contains(TemplateFldRef.Number) or (TemplateFldRef.Number > 2000000000)));
    end;

    local procedure FillFieldExclusionList(var FieldExclusionList: List of [Integer])
    var
        ItemTempl: Record "Item Templ.";
    begin
        FieldExclusionList.Add(ItemTempl.FieldNo("Base Unit of Measure"));
        FieldExclusionList.Add(ItemTempl.FieldNo("No. Series"));
        FieldExclusionList.Add(ItemTempl.FieldNo("VAT Bus. Posting Gr. (Price)"));

        OnAfterFillFieldExclusionList(FieldExclusionList);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyTemplateOnBeforeItemModify(var Item: Record Item; ItemTempl: Record "Item Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateItemFromTemplateOnBeforeSelectItemTemplate(Item: Record Item; var ItemTempl: Record "Item Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemFromTemplate(var Item: Record Item; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTemplatesAreNotEmpty(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemFromTemplate(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemsFromTemplate(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveAsTemplate(Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowTemplates(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillFieldExclusionList(var FieldExclusionList: List of [Integer])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItemFromTemplate(var Item: Record Item; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateFromTemplate(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateMultipleFromTemplate(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTemplateFromItem(Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Templ. Mgt.", 'OnInsertItemFromTemplate', '', false, false)]
    local procedure OnInsertItemFromTemplateHandler(var Item: Record Item; var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := CreateItemFromTemplate(Item, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Templ. Mgt.", 'OnTemplatesAreNotEmpty', '', false, false)]
    local procedure OnTemplatesAreNotEmptyHandler(var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := ItemTemplatesAreNotEmpty(IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Templ. Mgt.", 'OnUpdateItemFromTemplate', '', false, false)]
    local procedure OnUpdateItemFromTemplateHandler(var Item: Record Item; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        UpdateFromTemplate(Item, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Templ. Mgt.", 'OnUpdateItemsFromTemplate', '', false, false)]
    local procedure OnUpdateItemsFromTemplateHandler(var Item: Record Item; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        UpdateMultipleFromTemplate(Item, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Templ. Mgt.", 'OnSaveAsTemplate', '', false, false)]
    local procedure OnSaveAsTemplateHandler(Item: Record Item; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        CreateTemplateFromItem(Item, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Templ. Mgt.", 'OnShowTemplates', '', false, false)]
    local procedure OnShowTemplatesHandler(var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        ShowItemTemplList(IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTemplateFromItemOnBeforeItemTemplInsert(var ItemTempl: Record "Item Templ."; Item: Record Item)
    begin
    end;
}