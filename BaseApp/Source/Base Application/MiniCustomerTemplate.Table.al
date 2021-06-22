table 1300 "Mini Customer Template"
{
    Caption = 'Mini Customer Template';
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
        field(11; "Document Sending Profile"; Code[20])
        {
            Caption = 'Document Sending Profile';
            TableRelation = "Document Sending Profile".Code;
        }
        field(20; "Credit Limit (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Credit Limit (LCY)';
        }
        field(21; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(23; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
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
        field(34; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
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
        field(42; "Print Statements"; Boolean)
        {
            Caption = 'Print Statements';
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
        field(104; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            TableRelation = "Reminder Terms";
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
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            InitValue = true;
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
        FieldRefArray: array[23] of FieldRef;
        RecRef: RecordRef;
    begin
        TestField("Template Name");
        RecRef.GetTable(Rec);
        CreateFieldRefArray(FieldRefArray, RecRef);

        InsertConfigurationTemplateHeaderAndLines;
    end;

    trigger OnModify()
    var
        FieldRefArray: array[23] of FieldRef;
        RecRef: RecordRef;
    begin
        TestField(Code);
        TestField("Template Name");
        RecRef.GetTable(Rec);
        CreateFieldRefArray(FieldRefArray, RecRef);
        ConfigTemplateManagement.UpdateConfigTemplateAndLines(Code, "Template Name", DATABASE::Customer, FieldRefArray);
    end;

    var
        PostCode: Record "Post Code";
        ConfigTemplateManagement: Codeunit "Config. Template Management";

    procedure CreateFieldRefArray(var FieldRefArray: array[23] of FieldRef; RecRef: RecordRef)
    var
        I: Integer;
    begin
        I := 1;

        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo(City)));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Document Sending Profile")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Credit Limit (LCY)")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Customer Posting Group")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Currency Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Customer Price Group")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Language Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Payment Terms Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Fin. Charge Terms Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Customer Disc. Group")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Country/Region Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Print Statements")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Payment Method Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Application Method")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Prices Including VAT")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Gen. Bus. Posting Group")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Post Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo(County)));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Reminder Terms Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("VAT Bus. Posting Group")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Block Payment Tolerance")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Allow Line Disc.")));
        AddToArray(FieldRefArray, I, RecRef.Field(FieldNo("Validate EU Vat Reg. No.")));
        OnAfterCreateFieldRefArray(FieldRefArray, RecRef);
    end;

    local procedure AddToArray(var FieldRefArray: array[24] of FieldRef; var I: Integer; CurrFieldRef: FieldRef)
    begin
        FieldRefArray[I] := CurrFieldRef;
        I += 1;
    end;

    procedure InitializeTempRecordFromConfigTemplate(var TempMiniCustomerTemplate: Record "Mini Customer Template" temporary; ConfigTemplateHeader: Record "Config. Template Header")
    var
        RecRef: RecordRef;
    begin
        TempMiniCustomerTemplate.Init();
        TempMiniCustomerTemplate.Code := ConfigTemplateHeader.Code;
        TempMiniCustomerTemplate."Template Name" := ConfigTemplateHeader.Description;
        TempMiniCustomerTemplate.Insert();

        RecRef.GetTable(TempMiniCustomerTemplate);

        ConfigTemplateManagement.ApplyTemplateLinesWithoutValidation(ConfigTemplateHeader, RecRef);

        RecRef.SetTable(TempMiniCustomerTemplate);
    end;

    procedure CreateConfigTemplateFromExistingCustomer(Customer: Record Customer; var TempMiniCustomerTemplate: Record "Mini Customer Template" temporary)
    var
        DimensionsTemplate: Record "Dimensions Template";
        ConfigTemplateHeader: Record "Config. Template Header";
        RecRef: RecordRef;
        FieldRefArray: array[23] of FieldRef;
        NewTemplateCode: Code[10];
    begin
        RecRef.GetTable(Customer);
        CreateFieldRefArray(FieldRefArray, RecRef);

        ConfigTemplateManagement.CreateConfigTemplateAndLines(NewTemplateCode, '', DATABASE::Customer, FieldRefArray);
        ConfigTemplateHeader.Get(NewTemplateCode);
        DimensionsTemplate.CreateTemplatesFromExistingMasterRecord(Customer."No.", NewTemplateCode, DATABASE::Customer);
        OnCreateConfigTemplateFromExistingCustomerOnBeforeInitTempRec(Customer, TempMiniCustomerTemplate, ConfigTemplateHeader);
        InitializeTempRecordFromConfigTemplate(TempMiniCustomerTemplate, ConfigTemplateHeader);
    end;

    procedure SaveAsTemplate(Customer: Record Customer)
    var
        TempMiniCustomerTemplate: Record "Mini Customer Template" temporary;
        CustTemplateCard: Page "Cust. Template Card";
    begin
        CustTemplateCard.CreateFromCust(Customer);
        CustTemplateCard.SetRecord(TempMiniCustomerTemplate);
        CustTemplateCard.LookupMode := true;
        if CustTemplateCard.RunModal = ACTION::LookupOK then;
    end;

    local procedure InsertConfigurationTemplateHeaderAndLines()
    var
        FieldRefArray: array[23] of FieldRef;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        CreateFieldRefArray(FieldRefArray, RecRef);
        ConfigTemplateManagement.CreateConfigTemplateAndLines(Code, "Template Name", DATABASE::Customer, FieldRefArray);
    end;

    procedure NewCustomerFromTemplate(var Customer: Record Customer): Boolean
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplates: Page "Config Templates";
    begin
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Customer);
        ConfigTemplateHeader.SetRange(Enabled, true);

        if ConfigTemplateHeader.Count = 1 then begin
            ConfigTemplateHeader.FindFirst;
            InsertCustomerFromTemplate(ConfigTemplateHeader, Customer);
            exit(true);
        end;

        if (ConfigTemplateHeader.Count > 1) and GuiAllowed then begin
            ConfigTemplates.SetTableView(ConfigTemplateHeader);
            ConfigTemplates.LookupMode(true);
            ConfigTemplates.SetNewMode;
            if ConfigTemplates.RunModal = ACTION::LookupOK then begin
                ConfigTemplates.GetRecord(ConfigTemplateHeader);
                InsertCustomerFromTemplate(ConfigTemplateHeader, Customer);
                exit(true);
            end;
        end;

        exit(false);
    end;

    procedure UpdateCustomerFromTemplate(var Customer: Record Customer)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        DimensionsTemplate: Record "Dimensions Template";
        ConfigTemplates: Page "Config Templates";
        CustomerRecRef: RecordRef;
    begin
        if GuiAllowed then begin
            ConfigTemplateHeader.SetRange("Table ID", DATABASE::Customer);
            ConfigTemplateHeader.SetRange(Enabled, true);
            ConfigTemplates.SetTableView(ConfigTemplateHeader);
            ConfigTemplates.LookupMode(true);
            if ConfigTemplates.RunModal = ACTION::LookupOK then begin
                ConfigTemplates.GetRecord(ConfigTemplateHeader);
                CustomerRecRef.GetTable(Customer);
                ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, CustomerRecRef);
                DimensionsTemplate.InsertDimensionsFromTemplates(ConfigTemplateHeader, Customer."No.", DATABASE::Customer);
                CustomerRecRef.SetTable(Customer);
                Customer.Find;
            end;
        end;
    end;

    procedure InsertCustomerFromTemplate(ConfigTemplateHeader: Record "Config. Template Header"; var Customer: Record Customer)
    var
        DimensionsTemplate: Record "Dimensions Template";
        ConfigTemplateMgt: Codeunit "Config. Template Management";
        RecRef: RecordRef;
    begin
        Customer.SetInsertFromTemplate(true);
        InitCustomerNo(Customer, ConfigTemplateHeader);
        Customer.Insert(true);
        RecRef.GetTable(Customer);
        ConfigTemplateMgt.UpdateRecord(ConfigTemplateHeader, RecRef);
        RecRef.SetTable(Customer);

        DimensionsTemplate.InsertDimensionsFromTemplates(ConfigTemplateHeader, Customer."No.", DATABASE::Customer);
        Customer.Find;
    end;

    procedure UpdateCustomersFromTemplate(var Customer: Record Customer)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        DimensionsTemplate: Record "Dimensions Template";
        ConfigTemplates: Page "Config Templates";
        FldRef: FieldRef;
        CustomerRecRef: RecordRef;
    begin
        if GuiAllowed then begin
            ConfigTemplateHeader.SetRange("Table ID", DATABASE::Customer);
            ConfigTemplateHeader.SetRange(Enabled, true);
            ConfigTemplates.SetTableView(ConfigTemplateHeader);
            ConfigTemplates.LookupMode(true);
            if ConfigTemplates.RunModal = ACTION::LookupOK then begin
                ConfigTemplates.GetRecord(ConfigTemplateHeader);
                CustomerRecRef.GetTable(Customer);
                if CustomerRecRef.FindSet then
                    repeat
                        ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, CustomerRecRef);
                        FldRef := CustomerRecRef.Field(1);
                        DimensionsTemplate.InsertDimensionsFromTemplates(ConfigTemplateHeader, Format(FldRef.Value), DATABASE::Customer);
                    until CustomerRecRef.Next = 0;
                CustomerRecRef.SetTable(Customer);
            end;
        end;
    end;

    local procedure InitCustomerNo(var Customer: Record Customer; ConfigTemplateHeader: Record "Config. Template Header")
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        if ConfigTemplateHeader."Instance No. Series" = '' then
            exit;
        NoSeriesMgt.InitSeries(ConfigTemplateHeader."Instance No. Series", '', 0D, Customer."No.", Customer."No. Series");
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAfterCreateFieldRefArray(var FieldRefArray: array[23] of FieldRef; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateConfigTemplateFromExistingCustomerOnBeforeInitTempRec(Customer: Record Customer; var TempMiniCustomerTemplate: Record "Mini Customer Template" temporary; var ConfigTemplateHeader: Record "Config. Template Header")
    begin
    end;
}

