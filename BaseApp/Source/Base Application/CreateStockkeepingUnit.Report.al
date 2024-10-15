report 5706 "Create Stockkeeping Unit"
{
    AdditionalSearchTerms = 'create sku';
    ApplicationArea = Warehouse;
    Caption = 'Create Stockkeeping Unit';
    ProcessingOnly = true;
    UsageCategory = Administration;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Inventory Posting Group", "Location Filter", "Variant Filter";

            trigger OnAfterGetRecord()
            var
                ItemVariant: Record "Item Variant";
            begin
                if SaveFilters then begin
                    LocationFilter := GetFilter("Location Filter");
                    VariantFilter := GetFilter("Variant Filter");
                    SaveFilters := false;
                end;
                SetFilter("Location Filter", LocationFilter);
                SetFilter("Variant Filter", VariantFilter);

                Location.SetFilter(Code, GetFilter("Location Filter"));

                OnItemOnAfterGetRecordOnAfterSetLocationFilter(Location, Item);

                if ReplacePreviousSKUs then begin
                    StockkeepingUnit.Reset;
                    StockkeepingUnit.SetRange("Item No.", "No.");
                    if GetFilter("Variant Filter") <> '' then
                        StockkeepingUnit.SetFilter("Variant Code", GetFilter("Variant Filter"));
                    if GetFilter("Location Filter") <> '' then
                        StockkeepingUnit.SetFilter("Location Code", GetFilter("Location Filter"));
                    StockkeepingUnit.DeleteAll;
                end;

                DialogWindow.Update(1, "No.");
                ItemVariant.SetRange("Item No.", "No.");
                ItemVariant.SetFilter(Code, GetFilter("Variant Filter"));
                case true of
                    (SKUCreationMethod = SKUCreationMethod::Location) or
                    ((SKUCreationMethod = SKUCreationMethod::"Location & Variant") and
                     (not ItemVariant.Find('-'))):
                        begin
                            if Location.Find('-') then
                                repeat
                                    DialogWindow.Update(2, Location.Code);
                                    SetRange("Location Filter", Location.Code);
                                    CreateSKUIfRequired(Item, Location.Code, '');
                                until Location.Next = 0;
                        end;
                    (SKUCreationMethod = SKUCreationMethod::Variant) or
                    ((SKUCreationMethod = SKUCreationMethod::"Location & Variant") and
                     (not Location.Find('-'))):
                        begin
                            if ItemVariant.Find('-') then
                                repeat
                                    DialogWindow.Update(3, ItemVariant.Code);
                                    SetRange("Variant Filter", ItemVariant.Code);
                                    CreateSKUIfRequired(Item, '', ItemVariant.Code);
                                until ItemVariant.Next = 0;
                        end;
                    (SKUCreationMethod = SKUCreationMethod::"Location & Variant"):
                        begin
                            if Location.Find('-') then
                                repeat
                                    DialogWindow.Update(2, Location.Code);
                                    SetRange("Location Filter", Location.Code);
                                    if ItemVariant.Find('-') then
                                        repeat
                                            DialogWindow.Update(3, ItemVariant.Code);
                                            SetRange("Variant Filter", ItemVariant.Code);
                                            CreateSKUIfRequired(Item, Location.Code, ItemVariant.Code);
                                        until ItemVariant.Next = 0;
                                until Location.Next = 0;
                        end;
                end;
            end;

            trigger OnPostDataItem()
            begin
                DialogWindow.Close;
            end;

            trigger OnPreDataItem()
            begin
                Location.SetRange("Use As In-Transit", false);

                DialogWindow.Open(
                  Text000 +
                  Text001 +
                  Text002);

                SaveFilters := true;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(SKUCreationMethod; SKUCreationMethod)
                    {
                        ApplicationArea = Location;
                        Caption = 'Create Per';
                        OptionCaption = 'Location,Variant,Location & Variant';
                        ToolTip = 'Specifies if you want to create stockkeeping units per location or per variant or per location combined with variant.';
                    }
                    field(ItemInInventoryOnly; ItemInInventoryOnly)
                    {
                        ApplicationArea = Location;
                        Caption = 'Item In Inventory Only';
                        ToolTip = 'Specifies if you only want the batch job to create stockkeeping units for items that are in your inventory (that is, for items where the value in the Inventory field is above 0).';
                    }
                    field(ReplacePreviousSKUs; ReplacePreviousSKUs)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Replace Previous SKUs';
                        ToolTip = 'Specifies if you want the batch job to replace all previous created stockkeeping units on the items you have included in the batch job.';
                    }
                    field(OnlyIfTemplateExists; OnlyIfTemplateExists)
                    {
                        Caption = 'For SKU Templates Only';
                        ToolTip = 'Specifies if the stockkeeping unit will be created only for the sku templates ';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            ReplacePreviousSKUs := false;
            OnlyIfTemplateExists := true; // NAVCZ
        end;
    }

    labels
    {
    }

    var
        Text000: Label 'Item No.       #1##################\';
        Text001: Label 'Location Code  #2########\';
        Text002: Label 'Variant Code   #3########\';
        StockkeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        DialogWindow: Dialog;
        SKUCreationMethod: Option Location,Variant,"Location & Variant";
        ItemInInventoryOnly: Boolean;
        ReplacePreviousSKUs: Boolean;
        SaveFilters: Boolean;
        LocationFilter: Code[1024];
        VariantFilter: Code[1024];
        OnlyIfTemplateExists: Boolean;

    procedure CreateSKUIfRequired(var Item2: Record Item; LocationCode: Code[10]; VariantCode: Code[10])
    var
        StockkeepingUnitTemplate: Record "Stockkeeping Unit Template";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateSKU(Item2, LocationCode, VariantCode, ItemInInventoryOnly, IsHandled);
        if IsHandled then
            exit;

        // NAVCZ
        if OnlyIfTemplateExists and
           (not StockkeepingUnitTemplate.Get(Item2."Item Category Code", LocationCode))
        then
            exit;
        // NAVCZ

        Item2.CalcFields(Inventory);
        if (ItemInInventoryOnly and (Item2.Inventory > 0)) or
           (not ItemInInventoryOnly)
        then
            if not StockkeepingUnit.Get(LocationCode, Item2."No.", VariantCode) then begin
                CreateSKU(Item2, LocationCode, VariantCode);

                // NAVCZ
                if StockkeepingUnitTemplate.Get(Item2."Item Category Code", StockkeepingUnit."Location Code") then
                    UpdateFromTemplate(StockkeepingUnit, StockkeepingUnitTemplate);
                // NAVCZ
            end;
    end;

    local procedure UpdateFromTemplate(var StockkeepingUnit: Record "Stockkeeping Unit"; StockkeepingUnitTemplate: Record "Stockkeeping Unit Template")
    begin
        // NAVCZ
        with StockkeepingUnitTemplate do begin
            if "Components at Location" <> '' then
                StockkeepingUnit.Validate("Components at Location", "Components at Location");
            if "Replenishment System" <> "Replenishment System"::"From Item Card" then
                StockkeepingUnit.Validate("Replenishment System", "Replenishment System");
            if "Reordering Policy" <> "Reordering Policy"::"From Item Card" then
                StockkeepingUnit.Validate("Reordering Policy", "Reordering Policy");
            if "Include Inventory" then
                StockkeepingUnit.Validate("Include Inventory", "Include Inventory");
            if "Transfer-from Code" <> '' then
                StockkeepingUnit.Validate("Transfer-from Code", "Transfer-from Code");
            if "Gen. Prod. Posting Group" <> '' then
                StockkeepingUnit.Validate("Gen. Prod. Posting Group", "Gen. Prod. Posting Group");
        end;

        StockkeepingUnit.Modify;
    end;

    procedure InitializeRequest(CreatePerOption: Option Location,Variant,"Location & Variant"; NewItemInInventoryOnly: Boolean; NewReplacePreviousSKUs: Boolean)
    begin
        SKUCreationMethod := CreatePerOption;
        ItemInInventoryOnly := NewItemInInventoryOnly;
        ReplacePreviousSKUs := NewReplacePreviousSKUs;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSKU(var Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; ItemInInventoryOnly: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStockkeepingUnitInsert(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    begin
    end;

    procedure CreateSKU(var Item2: Record Item; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        StockkeepingUnit.Init;
        StockkeepingUnit."Item No." := Item2."No.";
        StockkeepingUnit."Location Code" := LocationCode;
        StockkeepingUnit."Variant Code" := VariantCode;
        StockkeepingUnit.CopyFromItem(Item2);
        StockkeepingUnit."Last Date Modified" := WorkDate;
        StockkeepingUnit."Special Equipment Code" := Item2."Special Equipment Code";
        StockkeepingUnit."Put-away Template Code" := Item2."Put-away Template Code";
        StockkeepingUnit.SetHideValidationDialog(true);
        StockkeepingUnit.Validate("Phys Invt Counting Period Code", Item2."Phys Invt Counting Period Code");
        StockkeepingUnit."Put-away Unit of Measure Code" := Item2."Put-away Unit of Measure Code";
        StockkeepingUnit."Use Cross-Docking" := Item2."Use Cross-Docking";
        OnBeforeStockkeepingUnitInsert(StockkeepingUnit, Item2);
        StockkeepingUnit.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemOnAfterGetRecordOnAfterSetLocationFilter(var Location: Record Location; var Item: Record Item)
    begin
    end;
}

