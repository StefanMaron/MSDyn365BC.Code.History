codeunit 1336 "Item Templ. Mgt."
{
    trigger OnRun()
    begin
    end;

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

        ApplyTemplate(Item, ItemTempl);
        InsertDimensions(Item."No.", ItemTempl.Code);

        exit(true);
    end;

    local procedure ApplyTemplate(var Item: Record Item; ItemTempl: Record "Item Templ.")
    begin
        Item.Type := ItemTempl.Type;
        Item."Inventory Posting Group" := ItemTempl."Inventory Posting Group";
        Item."Item Disc. Group" := ItemTempl."Item Disc. Group";
        Item."Allow Invoice Disc." := ItemTempl."Allow Invoice Disc.";
        Item."Price/Profit Calculation" := ItemTempl."Price/Profit Calculation";
        Item."Profit %" := ItemTempl."Profit %";
        Item."Costing Method" := ItemTempl."Costing Method";
        Item."Indirect Cost %" := ItemTempl."Indirect Cost %";
        Item."Price Includes VAT" := ItemTempl."Price Includes VAT";
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
        Item.Modify(true);
    end;

    local procedure SelectItemTemplate(var ItemTempl: Record "Item Templ."): Boolean
    var
        ItemTemplList: Page "Item Templ. List";
    begin
        if ItemTempl.Count = 1 then begin
            ItemTempl.FindFirst();
            exit(true);
        end;

        if (ItemTempl.Count > 1) and GuiAllowed then begin
            ItemTemplList.LookupMode(true);
            if ItemTemplList.RunModal() = Action::LookupOK then begin
                ItemTemplList.GetRecord(ItemTempl);
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

    local procedure IsEnabled() Result: Boolean
    var
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        Result := TemplateFeatureMgt.IsEnabled();

        OnAfterIsEnabled(Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean)
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
}