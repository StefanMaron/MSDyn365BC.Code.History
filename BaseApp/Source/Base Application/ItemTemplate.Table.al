table 1301 "Item Template"
{
    Caption = 'Item Template';
    ReplicateData = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'This functionality will be replaced by other templates.';
    ObsoleteTag = '16.0';

    fields
    {
        field(1; "Key"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Key';
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;

            trigger OnValidate()
            var
                InventorySetup: Record "Inventory Setup";
            begin
                InventorySetup.Get();
                "Costing Method" := InventorySetup."Default Costing Method";
            end;
        }
        field(3; "Template Name"; Text[100])
        {
            Caption = 'Template Name';
            NotBlank = true;
        }
        field(8; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            TableRelation = "Unit of Measure";
        }
        field(10; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Inventory,Service,Non-Inventory';
            OptionMembers = Inventory,Service,"Non-Inventory";

            trigger OnValidate()
            begin
                if (Type = Type::Service) or (Type = Type::"Non-Inventory") then
                    Validate("Inventory Posting Group", '');
            end;
        }
        field(11; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(14; "Item Disc. Group"; Code[20])
        {
            Caption = 'Item Disc. Group';
            TableRelation = "Item Discount Group";
        }
        field(15; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            InitValue = true;
        }
        field(19; "Price/Profit Calculation"; Option)
        {
            Caption = 'Price/Profit Calculation';
            OptionCaption = 'Profit=Price-Cost,Price=Cost+Profit,No Relationship';
            OptionMembers = "Profit=Price-Cost","Price=Cost+Profit","No Relationship";
        }
        field(20; "Profit %"; Decimal)
        {
            Caption = 'Profit %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
        }
        field(21; "Costing Method"; Option)
        {
            Caption = 'Costing Method';
            OptionCaption = 'FIFO,LIFO,Specific,Average,Standard';
            OptionMembers = FIFO,LIFO,Specific,"Average",Standard;
        }
        field(28; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(87; "Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';
        }
        field(91; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(96; "Automatic Ext. Texts"; Boolean)
        {
            Caption = 'Automatic Ext. Texts';
        }
        field(98; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(99; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(5702; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(5900; "Service Item Group"; Code[10])
        {
            Caption = 'Service Item Group';
            TableRelation = "Service Item Group".Code;
        }
        field(7300; "Warehouse Class Code"; Code[10])
        {
            Caption = 'Warehouse Class Code';
            TableRelation = "Warehouse Class";
        }
    }

    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        if ConfigTemplateHeader.Get(Code) then begin
            ConfigTemplateManagement.DeleteRelatedTemplates(Code, DATABASE::"Default Dimension");
            ConfigTemplateHeader.Delete(true);
        end;
    end;

    trigger OnInsert()
    var
        FieldRefArray: array[17] of FieldRef;
        RecRef: RecordRef;
    begin
        TestField("Template Name");
        RecRef.GetTable(Rec);
        CreateFieldRefArray(FieldRefArray, RecRef);

        InsertConfigurationTemplateHeaderAndLines;
    end;

    trigger OnModify()
    var
        FieldRefArray: array[17] of FieldRef;
        RecRef: RecordRef;
    begin
        TestField(Code);
        TestField("Template Name");
        RecRef.GetTable(Rec);
        CreateFieldRefArray(FieldRefArray, RecRef);
        ConfigTemplateManagement.UpdateConfigTemplateAndLines(Code, "Template Name", DATABASE::Item, FieldRefArray);
    end;

    var
        ConfigTemplateManagement: Codeunit "Config. Template Management";

    procedure CreateFieldRefArray(var FieldRefArray: array[30] of FieldRef; RecRef: RecordRef)
    var
        I: Integer;
    begin
        I := 1;

        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo(Type)));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Base Unit of Measure")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Automatic Ext. Texts")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Gen. Prod. Posting Group")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("VAT Prod. Posting Group")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Inventory Posting Group")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Costing Method")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Indirect Cost %")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Price Includes VAT")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Profit %")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Price/Profit Calculation")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Allow Invoice Disc.")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Item Disc. Group")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Tax Group Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Warehouse Class Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Item Category Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Service Item Group")));

        OnAfterCreateFieldRefArray(FieldRefArray, RecRef, I);
    end;

    procedure AddToArray(var FieldRefArray: array[30] of FieldRef; var I: Integer; CurrFieldRef: FieldRef)
    begin
        FieldRefArray[I] := CurrFieldRef;
        I += 1;
    end;

    procedure InitializeTempRecordFromConfigTemplate(var TempItemTemplate: Record "Item Template" temporary; ConfigTemplateHeader: Record "Config. Template Header")
    var
        RecRef: RecordRef;
    begin
        TempItemTemplate.SetRange(Code, ConfigTemplateHeader.Code);
        TempItemTemplate.SetRange("Template Name", ConfigTemplateHeader.Description);
        if not TempItemTemplate.FindFirst then begin
            TempItemTemplate.Init();
            TempItemTemplate.Code := ConfigTemplateHeader.Code;
            TempItemTemplate."Template Name" := ConfigTemplateHeader.Description;
            TempItemTemplate.Insert();
        end;

        // Remove the filters added for the previous FINDFIRST
        TempItemTemplate.SetRange(Code);
        TempItemTemplate.SetRange("Template Name");

        RecRef.GetTable(TempItemTemplate);

        ConfigTemplateManagement.ApplyTemplateLinesWithoutValidation(ConfigTemplateHeader, RecRef);

        RecRef.SetTable(TempItemTemplate);
    end;

    procedure CreateConfigTemplateFromExistingItem(Item: Record Item; var TempItemTemplate: Record "Item Template" temporary)
    var
        DimensionsTemplate: Record "Dimensions Template";
        ConfigTemplateHeader: Record "Config. Template Header";
        RecRef: RecordRef;
        FieldRefArray: array[17] of FieldRef;
        NewTemplateCode: Code[10];
    begin
        RecRef.GetTable(Item);
        CreateFieldRefArray(FieldRefArray, RecRef);

        ConfigTemplateManagement.CreateConfigTemplateAndLines(NewTemplateCode, '', DATABASE::Item, FieldRefArray);
        DimensionsTemplate.CreateTemplatesFromExistingMasterRecord(Item."No.", NewTemplateCode, DATABASE::Item);
        ConfigTemplateHeader.Get(NewTemplateCode);
        OnCreateConfigTemplateFromExistingItemOnBeforeInitTempRec(Item, TempItemTemplate, ConfigTemplateHeader);
        InitializeTempRecordFromConfigTemplate(TempItemTemplate, ConfigTemplateHeader);
    end;

    procedure SaveAsTemplate(Item: Record Item)
    var
        TempItemTemplate: Record "Item Template" temporary;
        ItemTemplateCard: Page "Item Template Card";
    begin
        ItemTemplateCard.CreateFromItem(Item);
        ItemTemplateCard.SetRecord(TempItemTemplate);
        ItemTemplateCard.LookupMode := true;
        if ItemTemplateCard.RunModal = ACTION::LookupOK then;
    end;

    local procedure InsertConfigurationTemplateHeaderAndLines()
    var
        FieldRefArray: array[17] of FieldRef;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        CreateFieldRefArray(FieldRefArray, RecRef);
        ConfigTemplateManagement.CreateConfigTemplateAndLines(Code, "Template Name", DATABASE::Item, FieldRefArray);
    end;

    procedure NewItemFromTemplate(var Item: Record Item): Boolean
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: Page "Config Templates";
    begin
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Item);
        ConfigTemplateHeader.SetRange(Enabled, true);

        if ConfigTemplateHeader.Count = 1 then begin
            ConfigTemplateHeader.FindFirst;
            InsertItemFromTemplate(ConfigTemplateHeader, Item);
            exit(true);
        end;

        if (ConfigTemplateHeader.Count > 1) and GuiAllowed then begin
            ConfigTemplates.SetTableView(ConfigTemplateHeader);
            ConfigTemplates.LookupMode(true);
            ConfigTemplates.SetNewMode;
            if ConfigTemplates.RunModal = ACTION::LookupOK then begin
                ConfigTemplates.GetRecord(ConfigTemplateHeader);
                InsertItemFromTemplate(ConfigTemplateHeader, Item);
                exit(true);
            end;
        end;

        exit(false);
    end;

    procedure UpdateItemFromTemplate(var Item: Record Item)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        DimensionsTemplate: Record "Dimensions Template";
        ConfigTemplates: Page "Config Templates";
        ItemRecRef: RecordRef;
    begin
        if not GuiAllowed then
            exit;

        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Item);
        ConfigTemplateHeader.SetRange(Enabled, true);
        ConfigTemplates.SetTableView(ConfigTemplateHeader);
        ConfigTemplates.LookupMode(true);
        if ConfigTemplates.RunModal = ACTION::LookupOK then begin
            ConfigTemplates.GetRecord(ConfigTemplateHeader);
            ItemRecRef.GetTable(Item);
            ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, ItemRecRef);
            DimensionsTemplate.InsertDimensionsFromTemplates(ConfigTemplateHeader, Item."No.", DATABASE::Item);
            ItemRecRef.SetTable(Item);
            Item.Find;
        end;

        OnAfterUpdateItemFromTemplate(Rec, Item, ConfigTemplateHeader);
    end;

    procedure InsertItemFromTemplate(ConfigTemplateHeader: Record "Config. Template Header"; var Item: Record Item)
    var
        DimensionsTemplate: Record "Dimensions Template";
        UnitOfMeasure: Record "Unit of Measure";
        ConfigTemplateMgt: Codeunit "Config. Template Management";
        RecRef: RecordRef;
        FoundUoM: Boolean;
    begin
        InitItemNo(Item, ConfigTemplateHeader);
        Item.Insert(true);
        RecRef.GetTable(Item);
        ConfigTemplateMgt.UpdateRecord(ConfigTemplateHeader, RecRef);
        RecRef.SetTable(Item);

        if Item."Base Unit of Measure" = '' then begin
            UnitOfMeasure.SetRange("International Standard Code", 'EA'); // 'Each' ~= 'PCS'
            FoundUoM := UnitOfMeasure.FindFirst;
            if not FoundUoM then begin
                UnitOfMeasure.SetRange("International Standard Code");
                FoundUoM := UnitOfMeasure.FindFirst;
            end;
            if FoundUoM then begin
                Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
                Item.Modify(true);
            end;
        end;

        DimensionsTemplate.InsertDimensionsFromTemplates(ConfigTemplateHeader, Item."No.", DATABASE::Item);
        Item.Find;

        OnAfterInsertItemFromTemplate(Rec, Item, ConfigTemplateHeader);
    end;

    procedure UpdateItemsFromTemplate(var Item: Record Item)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        DimensionsTemplate: Record "Dimensions Template";
        ConfigTemplates: Page "Config Templates";
        FldRef: FieldRef;
        ItemRecRef: RecordRef;
    begin
        if GuiAllowed then begin
            ConfigTemplateHeader.SetRange("Table ID", DATABASE::Item);
            ConfigTemplateHeader.SetRange(Enabled, true);
            ConfigTemplates.SetTableView(ConfigTemplateHeader);
            ConfigTemplates.LookupMode(true);
            if ConfigTemplates.RunModal = ACTION::LookupOK then begin
                ConfigTemplates.GetRecord(ConfigTemplateHeader);
                ItemRecRef.GetTable(Item);
                if ItemRecRef.FindSet then
                    repeat
                        ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, ItemRecRef);
                        FldRef := ItemRecRef.Field(1);
                        DimensionsTemplate.InsertDimensionsFromTemplates(ConfigTemplateHeader, Format(FldRef.Value), DATABASE::Item);
                    until ItemRecRef.Next = 0;
                ItemRecRef.SetTable(Item);
            end;
        end;
    end;

    local procedure InitItemNo(var Item: Record Item; ConfigTemplateHeader: Record "Config. Template Header")
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitItemNo(Item, ConfigTemplateHeader, IsHandled);
        if IsHandled then
            exit;

        if ConfigTemplateHeader."Instance No. Series" = '' then
            exit;
        NoSeriesMgt.InitSeries(ConfigTemplateHeader."Instance No. Series", '', 0D, Item."No.", Item."No. Series");
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAfterCreateFieldRefArray(var FieldRefArray: array[30] of FieldRef; RecRef: RecordRef; var I: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertItemFromTemplate(var ItemTemplate: Record "Item Template"; var Item: Record Item; ConfigTemplateHeader: Record "Config. Template Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateItemFromTemplate(var ItemTemplate: Record "Item Template"; var Item: Record Item; ConfigTemplateHeader: Record "Config. Template Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitItemNo(var Item: Record Item; ConfigTemplateHeader: Record "Config. Template Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateConfigTemplateFromExistingItemOnBeforeInitTempRec(Item: Record Item; var TempItemTemplate: Record "Item Template" temporary; var ConfigTemplateHeader: Record "Config. Template Header")
    begin
    end;
}

