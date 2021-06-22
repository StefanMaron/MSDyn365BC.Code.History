codeunit 1389 "Template Feature Event Handler"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Required to keep working old and new templates functionality together. This codeunit will be removed with other functionality related to the "old" templates.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
    end;

    local procedure CreateVendorFromConfigTemplate(var Vendor: Record Vendor; var IsHandled: Boolean): Boolean
    var
        MiniVendorTemplate: Record "Mini Vendor Template";
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        if TemplateFeatureMgt.IsEnabled() then
            exit(false);

        IsHandled := true;
        exit(MiniVendorTemplate.NewVendorFromTemplate(Vendor));
    end;

    local procedure VendorConfigTemplatesAreNotEmpty(var IsHandled: Boolean): Boolean
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        if TemplateFeatureMgt.IsEnabled() then
            exit(false);

        IsHandled := true;

        ConfigTemplateHeader.SetRange("Table ID", Database::Vendor);
        ConfigTemplateHeader.SetRange(Enabled, true);
        exit(not ConfigTemplateHeader.IsEmpty);
    end;

    local procedure CreateCustomerFromConfigTemplate(var Customer: Record Customer; var IsHandled: Boolean): Boolean
    var
        MiniCustomerTemplate: Record "Mini Customer Template";
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        if TemplateFeatureMgt.IsEnabled() then
            exit(false);

        IsHandled := true;
        exit(MiniCustomerTemplate.NewCustomerFromTemplate(Customer));
    end;

    local procedure CustomerConfigTemplatesAreNotEmpty(var IsHandled: Boolean): Boolean
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        if TemplateFeatureMgt.IsEnabled() then
            exit(false);

        IsHandled := true;

        ConfigTemplateHeader.SetRange("Table ID", Database::Customer);
        ConfigTemplateHeader.SetRange(Enabled, true);
        exit(not ConfigTemplateHeader.IsEmpty);
    end;

    local procedure CreateItemFromConfigTemplate(var Item: Record Item; var IsHandled: Boolean): Boolean
    var
        ItemTemplate: Record "Item Template";
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        if TemplateFeatureMgt.IsEnabled() then
            exit(false);

        IsHandled := true;
        exit(ItemTemplate.NewItemFromTemplate(Item));
    end;

    local procedure ItemConfigTemplatesAreNotEmpty(var IsHandled: Boolean): Boolean
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        if TemplateFeatureMgt.IsEnabled() then
            exit(false);

        IsHandled := true;

        ConfigTemplateHeader.SetRange("Table ID", Database::Item);
        ConfigTemplateHeader.SetRange(Enabled, true);
        exit(not ConfigTemplateHeader.IsEmpty);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnInsertVendorFromTemplate', '', false, false)]
    local procedure OnInsertVendorFromTemplateHandler(var Vendor: Record Vendor; var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := CreateVendorFromConfigTemplate(Vendor, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnTemplatesAreNotEmpty', '', false, false)]
    local procedure OnTemplatesAreNotEmptyVendorHandled(var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := VendorConfigTemplatesAreNotEmpty(IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnInsertCustomerFromTemplate', '', false, false)]
    local procedure OnInsertCustomerFromTemplateHandler(var Customer: Record Customer; var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := CreateCustomerFromConfigTemplate(Customer, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnTemplatesAreNotEmpty', '', false, false)]
    local procedure OnTemplatesAreNotEmptyCustomerHandled(var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := CustomerConfigTemplatesAreNotEmpty(IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Templ. Mgt.", 'OnInsertItemFromTemplate', '', false, false)]
    local procedure OnInsertItemFromTemplateHandler(var Item: Record Item; var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := CreateItemFromConfigTemplate(Item, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Templ. Mgt.", 'OnTemplatesAreNotEmpty', '', false, false)]
    local procedure OnTemplatesAreNotEmptyItemHandled(var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := ItemConfigTemplatesAreNotEmpty(IsHandled);
    end;
}