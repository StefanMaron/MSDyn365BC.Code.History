codeunit 1336 "Item Templ. Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        VATPostingSetupErr: Label 'VAT Posting Setup does not exist. "VAT Bus. Posting Group" = %1, "VAT Prod. Posting Group" = %2.', Comment = '%1 - vat bus. posting group code; %2 - vat prod. posting group code';

    procedure CreateItemFromTemplate(var Item: Record Item; var IsHandled: Boolean): Boolean
    var
        ItemTempl: Record "Item Templ.";
    begin
        if not IsEnabled() then
            exit(false);

        IsHandled := true;

        if not SelectItemTemplate(ItemTempl) then
            exit(false);

        Item.Init();
        Item.Insert(true);

        ApplyItemTemplate(Item, ItemTempl);

        exit(true);
    end;

    procedure ApplyItemTemplate(var Item: Record Item; ItemTempl: Record "Item Templ.")
    begin
        ApplyTemplate(Item, ItemTempl);
        InsertDimensions(Item."No.", ItemTempl.Code);
    end;

    local procedure ApplyTemplate(var Item: Record Item; ItemTempl: Record "Item Templ.")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Item.Type := ItemTempl.Type;
        Item."Inventory Posting Group" := ItemTempl."Inventory Posting Group";
        Item."Item Disc. Group" := ItemTempl."Item Disc. Group";
        Item."Allow Invoice Disc." := ItemTempl."Allow Invoice Disc.";
        Item."Price/Profit Calculation" := ItemTempl."Price/Profit Calculation";
        Item."Profit %" := ItemTempl."Profit %";
        Item."Costing Method" := ItemTempl."Costing Method";
        Item."Indirect Cost %" := ItemTempl."Indirect Cost %";
        Item."Gen. Prod. Posting Group" := ItemTempl."Gen. Prod. Posting Group";
        Item."Automatic Ext. Texts" := ItemTempl."Automatic Ext. Texts";
        Item."Tax Group Code" := ItemTempl."Tax Group Code";
        Item."VAT Prod. Posting Group" := ItemTempl."VAT Prod. Posting Group";
        Item."Item Category Code" := ItemTempl."Item Category Code";
        Item."Service Item Group" := ItemTempl."Service Item Group";
        Item."Warehouse Class Code" := ItemTempl."Warehouse Class Code";
        Item.Blocked := ItemTempl.Blocked;
        Item."Sales Blocked" := ItemTempl."Sales Blocked";
        Item."Purchasing Blocked" := ItemTempl."Purchasing Blocked";
        Item.Validate("Base Unit of Measure", ItemTempl."Base Unit of Measure");
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

    local procedure InsertDimensions(ItemNo: Code[20]; ItemTemplCode: Code[20])
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        SourceDefaultDimension.SetRange("Table ID", Database::"Item Templ.");
        SourceDefaultDimension.SetRange("No.", ItemTemplCode);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", Database::Item);
                DestDefaultDimension.Validate("No.", ItemNo);
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
        if not CanBeUpdatedFromTemplate(ItemTempl, IsHandled) then
            exit;

        if Item.FindSet() then
            repeat
                ApplyItemTemplate(Item, ItemTempl);
            until Item.Next() = 0;
    end;

    local procedure CanBeUpdatedFromTemplate(var ItemTempl: Record "Item Templ."; var IsHandled: Boolean): Boolean
    begin
        if not IsEnabled() then
            exit(false);

        IsHandled := true;

        if not SelectItemTemplate(ItemTempl) then
            exit(false);

        exit(true);
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
}