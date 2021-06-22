table 1303 "Mini Vendor Template"
{
    Caption = 'Mini Vendor Template';
    ReplicateData = true;

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
        }
        field(3; "Template Name"; Text[100])
        {
            Caption = 'Template Name';
            NotBlank = true;
        }
        field(7; City; Text[30])
        {
            Caption = 'City';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                PostCodeRec: Record "Post Code";
            begin
                if City <> '' then begin
                    PostCodeRec.SetFilter("Search City", City);

                    case PostCodeRec.Count of
                        0:
                            exit;
                        1:
                            PostCodeRec.FindFirst;
                        else
                            if PAGE.RunModal(PAGE::"Post Codes", PostCodeRec, PostCodeRec.Code) <> ACTION::LookupOK then
                                exit;
                    end;

                    "Post Code" := PostCodeRec.Code;
                    "Country/Region Code" := PostCodeRec."Country/Region Code";
                end;
            end;
        }
        field(21; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            TableRelation = "Vendor Posting Group";
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(24; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(27; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(28; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            TableRelation = "Finance Charge Terms";
        }
        field(33; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';
            TableRelation = Vendor;
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(47; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(80; "Application Method"; Option)
        {
            Caption = 'Application Method';
            OptionCaption = 'Manual,Apply to Oldest';
            OptionMembers = Manual,"Apply to Oldest";
        }
        field(82; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        field(88; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(91; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                PostCodeRec: Record "Post Code";
            begin
                if "Post Code" <> '' then begin
                    PostCodeRec.SetFilter(Code, "Post Code");

                    case PostCodeRec.Count of
                        0:
                            exit;
                        1:
                            PostCodeRec.FindFirst;
                        else
                            if PAGE.RunModal(PAGE::"Post Codes", PostCodeRec, PostCodeRec.Code) <> ACTION::LookupOK then
                                exit;
                    end;

                    City := PostCodeRec.City;
                    "Country/Region Code" := PostCodeRec."Country/Region Code";
                end;
            end;
        }
        field(92; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(110; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(116; "Block Payment Tolerance"; Boolean)
        {
            Caption = 'Block Payment Tolerance';
        }
        field(7602; "Validate EU Vat Reg. No."; Boolean)
        {
            Caption = 'Validate EU Vat Reg. No.';
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
        ConfigTemplateManagement.UpdateConfigTemplateAndLines(Code, "Template Name", DATABASE::Vendor, FieldRefArray);
    end;

    var
        PostCode: Record "Post Code";
        ConfigTemplateManagement: Codeunit "Config. Template Management";

    procedure CreateFieldRefArray(var FieldRefArray: array[17] of FieldRef; RecRef: RecordRef)
    var
        I: Integer;
    begin
        I := 1;

        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo(City)));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Vendor Posting Group")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Currency Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Language Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Payment Terms Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Fin. Charge Terms Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Invoice Disc. Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Country/Region Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Payment Method Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Application Method")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Prices Including VAT")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Gen. Bus. Posting Group")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Post Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo(County)));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("VAT Bus. Posting Group")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Block Payment Tolerance")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Validate EU Vat Reg. No.")));
        OnAfterCreateFieldRefArray(FieldRefArray, RecRef);
    end;

    local procedure AddToArray(var FieldRefArray: array[18] of FieldRef; var I: Integer; CurrFieldRef: FieldRef)
    begin
        FieldRefArray[I] := CurrFieldRef;
        I += 1;
    end;

    procedure InitializeTempRecordFromConfigTemplate(var TempMiniVendorTemplate: Record "Mini Vendor Template" temporary; ConfigTemplateHeader: Record "Config. Template Header")
    var
        RecRef: RecordRef;
    begin
        TempMiniVendorTemplate.Init;
        TempMiniVendorTemplate.Code := ConfigTemplateHeader.Code;
        TempMiniVendorTemplate."Template Name" := ConfigTemplateHeader.Description;
        TempMiniVendorTemplate.Insert;

        RecRef.GetTable(TempMiniVendorTemplate);

        ConfigTemplateManagement.ApplyTemplateLinesWithoutValidation(ConfigTemplateHeader, RecRef);

        RecRef.SetTable(TempMiniVendorTemplate);
    end;

    procedure CreateConfigTemplateFromExistingVendor(Vendor: Record Vendor; var TempMiniVendorTemplate: Record "Mini Vendor Template" temporary)
    var
        DimensionsTemplate: Record "Dimensions Template";
        ConfigTemplateHeader: Record "Config. Template Header";
        RecRef: RecordRef;
        FieldRefArray: array[17] of FieldRef;
        NewTemplateCode: Code[10];
    begin
        RecRef.GetTable(Vendor);
        CreateFieldRefArray(FieldRefArray, RecRef);

        ConfigTemplateManagement.CreateConfigTemplateAndLines(NewTemplateCode, '', DATABASE::Vendor, FieldRefArray);
        ConfigTemplateHeader.Get(NewTemplateCode);
        DimensionsTemplate.CreateTemplatesFromExistingMasterRecord(Vendor."No.", NewTemplateCode, DATABASE::Vendor);
        OnCreateConfigTemplateFromExistingVendorOnBeforeInitTempRec(Vendor, TempMiniVendorTemplate, ConfigTemplateHeader);
        InitializeTempRecordFromConfigTemplate(TempMiniVendorTemplate, ConfigTemplateHeader);
    end;

    procedure SaveAsTemplate(Vendor: Record Vendor)
    var
        TempMiniVendorTemplate: Record "Mini Vendor Template" temporary;
        VendorTemplateCard: Page "Vendor Template Card";
    begin
        VendorTemplateCard.CreateFromVend(Vendor);
        VendorTemplateCard.SetRecord(TempMiniVendorTemplate);
        VendorTemplateCard.LookupMode := true;
        if VendorTemplateCard.RunModal = ACTION::LookupOK then;
    end;

    local procedure InsertConfigurationTemplateHeaderAndLines()
    var
        FieldRefArray: array[17] of FieldRef;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        CreateFieldRefArray(FieldRefArray, RecRef);
        ConfigTemplateManagement.CreateConfigTemplateAndLines(Code, "Template Name", DATABASE::Vendor, FieldRefArray);
    end;

    procedure NewVendorFromTemplate(var Vendor: Record Vendor): Boolean
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: Page "Config Templates";
    begin
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Vendor);
        ConfigTemplateHeader.SetRange(Enabled, true);

        if ConfigTemplateHeader.Count = 1 then begin
            ConfigTemplateHeader.FindFirst;
            InsertVendorFromTemplate(ConfigTemplateHeader, Vendor);
            exit(true);
        end;

        if (ConfigTemplateHeader.Count > 1) and GuiAllowed then begin
            ConfigTemplates.SetTableView(ConfigTemplateHeader);
            ConfigTemplates.LookupMode(true);
            ConfigTemplates.SetNewMode;
            if ConfigTemplates.RunModal = ACTION::LookupOK then begin
                ConfigTemplates.GetRecord(ConfigTemplateHeader);
                InsertVendorFromTemplate(ConfigTemplateHeader, Vendor);
                exit(true);
            end;
        end;

        exit(false);
    end;

    procedure UpdateVendorFromTemplate(var Vendor: Record Vendor)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        DimensionsTemplate: Record "Dimensions Template";
        ConfigTemplates: Page "Config Templates";
        VendorRecRef: RecordRef;
    begin
        if GuiAllowed then begin
            ConfigTemplateHeader.SetRange("Table ID", DATABASE::Vendor);
            ConfigTemplateHeader.SetRange(Enabled, true);
            ConfigTemplates.SetTableView(ConfigTemplateHeader);
            ConfigTemplates.LookupMode(true);
            if ConfigTemplates.RunModal = ACTION::LookupOK then begin
                ConfigTemplates.GetRecord(ConfigTemplateHeader);
                VendorRecRef.GetTable(Vendor);
                ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, VendorRecRef);
                DimensionsTemplate.InsertDimensionsFromTemplates(ConfigTemplateHeader, Vendor."No.", DATABASE::Vendor);
                VendorRecRef.SetTable(Vendor);
                Vendor.Find;
            end;
        end;
    end;

    procedure InsertVendorFromTemplate(ConfigTemplateHeader: Record "Config. Template Header"; var Vendor: Record Vendor)
    var
        DimensionsTemplate: Record "Dimensions Template";
        ConfigTemplateMgt: Codeunit "Config. Template Management";
        RecRef: RecordRef;
    begin
        Vendor.SetInsertFromTemplate(true);
        InitVendorNo(Vendor, ConfigTemplateHeader);
        Vendor.Insert(true);
        RecRef.GetTable(Vendor);
        ConfigTemplateMgt.UpdateRecord(ConfigTemplateHeader, RecRef);
        RecRef.SetTable(Vendor);

        DimensionsTemplate.InsertDimensionsFromTemplates(ConfigTemplateHeader, Vendor."No.", DATABASE::Vendor);
        Vendor.Find;
    end;

    procedure UpdateVendorsFromTemplate(var Vendor: Record Vendor)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        DimensionsTemplate: Record "Dimensions Template";
        ConfigTemplates: Page "Config Templates";
        VendorRecRef: RecordRef;
    begin
        if GuiAllowed then begin
            ConfigTemplateHeader.SetRange("Table ID", DATABASE::Vendor);
            ConfigTemplateHeader.SetRange(Enabled, true);
            ConfigTemplates.SetTableView(ConfigTemplateHeader);
            ConfigTemplates.LookupMode(true);
            if ConfigTemplates.RunModal = ACTION::LookupOK then begin
                ConfigTemplates.GetRecord(ConfigTemplateHeader);
                VendorRecRef.GetTable(Vendor);
                if VendorRecRef.FindSet then
                    repeat
                        ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, VendorRecRef);
                        DimensionsTemplate.InsertDimensionsFromTemplates(ConfigTemplateHeader, Vendor."No.", DATABASE::Vendor);
                    until VendorRecRef.Next = 0;
                VendorRecRef.SetTable(Vendor);
            end;
        end;
    end;

    local procedure InitVendorNo(var Vendor: Record Vendor; ConfigTemplateHeader: Record "Config. Template Header")
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        if ConfigTemplateHeader."Instance No. Series" = '' then
            exit;
        NoSeriesMgt.InitSeries(ConfigTemplateHeader."Instance No. Series", '', 0D, Vendor."No.", Vendor."No. Series");
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAfterCreateFieldRefArray(var FieldRefArray: array[23] of FieldRef; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateConfigTemplateFromExistingVendorOnBeforeInitTempRec(Vendor: Record Vendor; var TempMiniVendorTemplate: Record "Mini Vendor Template" temporary; var ConfigTemplateHeader: Record "Config. Template Header")
    begin
    end;
}

