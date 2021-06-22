table 8616 "Config. Package Field"
{
    Caption = 'Config. Package Field';
    ReplicateData = false;

    fields
    {
        field(1; "Package Code"; Code[20])
        {
            Caption = 'Package Code';
            NotBlank = true;
            TableRelation = "Config. Package";
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(3; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            NotBlank = true;
            TableRelation = IF (Dimension = CONST(false)) Field."No." WHERE(TableNo = FIELD("Table ID"));
        }
        field(4; "Field Name"; Text[30])
        {
            Caption = 'Field Name';
        }
        field(5; "Field Caption"; Text[250])
        {
            Caption = 'Field Caption';
        }
        field(6; "Validate Field"; Boolean)
        {
            Caption = 'Validate Field';

            trigger OnValidate()
            begin
                if not Dimension then begin
                    if xRec."Validate Field" and not "Validate Field" and "Primary Key" then
                        Error(Text000, "Field Caption");
                    if "Validate Field" then
                        ThrowErrorIfFieldRemoved;
                    UpdateFieldErrors;
                end;
            end;
        }
        field(7; "Include Field"; Boolean)
        {
            Caption = 'Include Field';

            trigger OnValidate()
            begin
                if not Dimension then begin
                    if xRec."Include Field" and not "Include Field" and "Primary Key" then
                        Error(Text000, "Field Caption");
                    if "Include Field" then
                        ThrowErrorIfFieldRemoved;
                    "Validate Field" := "Include Field";
                    UpdateFieldErrors;
                end;
            end;
        }
        field(8; "Localize Field"; Boolean)
        {
            Caption = 'Localize Field';
        }
        field(9; "Relation Table ID"; Integer)
        {
            Caption = 'Relation Table ID';
            Editable = false;
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(10; "Relation Table Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Name" WHERE("Object Type" = CONST(Table),
                                                                        "Object ID" = FIELD("Relation Table ID")));
            Caption = 'Relation Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; Dimension; Boolean)
        {
            Caption = 'Dimension';
            Editable = false;
        }
        field(12; "Primary Key"; Boolean)
        {
            Caption = 'Primary Key';
            Editable = false;
        }
        field(13; "Processing Order"; Integer)
        {
            Caption = 'Processing Order';
        }
        field(14; "Create Missing Codes"; Boolean)
        {
            Caption = 'Create Missing Codes';

            trigger OnValidate()
            begin
                if "Create Missing Codes" then
                    TestField("Relation Table ID");
            end;
        }
        field(15; "Mapping Exists"; Boolean)
        {
            CalcFormula = Exist ("Config. Field Mapping" WHERE("Package Code" = FIELD("Package Code"),
                                                               "Table ID" = FIELD("Table ID"),
                                                               "Field ID" = FIELD("Field ID")));
            Caption = 'Mapping Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; AutoIncrement; Boolean)
        {
            Caption = 'AutoIncrement';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestField("Primary Key", false);
                TestFieldIsInteger;
            end;
        }
    }

    keys
    {
        key(Key1; "Package Code", "Table ID", "Field ID")
        {
            Clustered = true;
        }
        key(Key2; "Package Code", "Table ID", "Include Field")
        {
        }
        key(Key3; "Package Code", "Table ID", "Validate Field")
        {
        }
        key(Key4; "Package Code", "Table ID", "Processing Order")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeleteConfigFieldMapping;
    end;

    var
        Text000: Label '%1 is part of the primary key and must be included.';
        Text001: Label '%1 value ''%2'' does not exist.';
        Text002: Label 'Updating validation errors';
        MustBeIntegersErr: Label 'must be Integer or BigInteger';

    local procedure UpdateFieldErrors()
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageField: Record "Config. Package Field";
        TempConfigPackageTable: Record "Config. Package Table" temporary;
        ConfigPackageMgt: Codeunit "Config. Package Management";
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        ConfigProgressBar: Codeunit "Config. Progress Bar";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        if not Dimension then begin
            if "Include Field" then begin
                RecRef.Open("Table ID", true);
                FieldRef := RecRef.Field("Field ID");
            end;
            ConfigPackageData.SetRange("Package Code", "Package Code");
            ConfigPackageData.SetRange("Table ID", "Table ID");
            ConfigPackageData.SetRange("Field ID", "Field ID");
            if ConfigPackageData.FindSet then begin
                ConfigProgressBar.Init(ConfigPackageData.Count, 1, Text002);
                repeat
                    ConfigProgressBar.Update(ConfigPackageData.Value);
                    ConfigPackageMgt.CleanFieldError(ConfigPackageData);
                    if "Include Field" then begin
                        ConfigPackageMgt.FieldError(ConfigPackageData, ConfigValidateMgt.EvaluateValue(FieldRef, ConfigPackageData.Value, false), 0);
                        if "Validate Field" then begin
                            Clear(TempConfigPackageTable);
                            ConfigPackageField.Init();
                            ConfigPackageField.Reset();
                            ConfigPackageField.SetRange("Package Code", "Package Code");
                            ConfigPackageField.SetRange("Table ID", "Table ID");
                            ConfigPackageField.SetRange("Field ID", "Field ID");
                            if not ConfigPackageMgt.ValidateFieldRelation(ConfigPackageField, TempConfigPackageTable) then
                                ConfigPackageMgt.FieldError(ConfigPackageData, StrSubstNo(Text001, FieldRef.Caption, ConfigPackageData.Value), 0);
                        end;
                    end;
                until ConfigPackageData.Next = 0;
                ConfigProgressBar.Close;
            end;
        end;
    end;

    local procedure DeleteConfigFieldMapping()
    var
        ConfigFieldMapping: Record "Config. Field Mapping";
    begin
        ConfigFieldMapping.SetRange("Package Code", "Package Code");
        ConfigFieldMapping.SetRange("Table ID", "Table ID");
        ConfigFieldMapping.SetRange("Field ID", "Field ID");
        ConfigFieldMapping.DeleteAll();
    end;

    procedure GetRelationTablesID() Result: Text
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
    begin
        TableRelationsMetadata.SetRange("Table ID", "Table ID");
        TableRelationsMetadata.SetRange("Field No.", "Field ID");
        if TableRelationsMetadata.FindSet then
            repeat
                Result += Format(TableRelationsMetadata."Related Table ID") + '|';
            until TableRelationsMetadata.Next = 0;
        exit(DelChr(Result, '>', '|'));
    end;

    local procedure TestFieldIsInteger()
    var
        "Field": Record "Field";
    begin
        if Field.Get("Table ID", "Field ID") then
            if not (Field.Type in [Field.Type::BigInteger, Field.Type::Integer]) then
                Field.FieldError(Type, MustBeIntegersErr);
    end;

    local procedure ThrowErrorIfFieldRemoved()
    var
        "Field": Record "Field";
        TypeHelper: Codeunit "Type Helper";
    begin
        Field.Get("Table ID", "Field ID");
        TypeHelper.TestFieldIsNotObsolete(Field);
    end;
}

