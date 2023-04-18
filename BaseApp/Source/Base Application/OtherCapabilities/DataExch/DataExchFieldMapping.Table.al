table 1225 "Data Exch. Field Mapping"
{
    Caption = 'Data Exch. Field Mapping';

    fields
    {
        field(1; "Data Exch. Def Code"; Code[20])
        {
            Caption = 'Data Exch. Def Code';
            NotBlank = true;
            TableRelation = "Data Exch. Def".Code;
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = "Data Exch. Mapping"."Table ID";
        }
        field(3; "Column No."; Integer)
        {
            Caption = 'Column No.';
            NotBlank = true;
            TableRelation = "Data Exch. Column Def"."Column No." WHERE("Data Exch. Def Code" = FIELD("Data Exch. Def Code"),
                                                                        "Data Exch. Line Def Code" = FIELD("Data Exch. Line Def Code"));
        }
        field(4; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            TableRelation = Field."No." WHERE(TableNo = FIELD("Table ID"));
        }
        field(5; Optional; Boolean)
        {
            Caption = 'Optional';
        }
        field(6; "Use Default Value"; Boolean)
        {
            Caption = 'Use Default Value';

            trigger OnValidate()
            begin
                if not "Use Default Value" then
                    "Default Value" := '';
            end;
        }
        field(7; "Default Value"; Text[250])
        {
            Caption = 'Default Value';

            trigger OnValidate()
            begin
                Validate("Use Default Value", true);
            end;
        }
        field(8; "Data Exch. Line Def Code"; Code[20])
        {
            Caption = 'Data Exch. Line Def Code';
            NotBlank = true;
            TableRelation = "Data Exch. Line Def".Code WHERE("Data Exch. Def Code" = FIELD("Data Exch. Def Code"));
        }
        field(9; Multiplier; Decimal)
        {
            Caption = 'Multiplier';
            InitValue = 1;

            trigger OnValidate()
            begin
                if IsValidToUseMultiplier() and (Multiplier = 0) then
                    Error(ZeroNotAllowedErr);
            end;
        }
        field(10; "Target Table ID"; Integer)
        {
            Caption = 'Target Table ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(11; "Target Field ID"; Integer)
        {
            Caption = 'Target Field ID';
            TableRelation = Field."No." WHERE(TableNo = FIELD("Target Table ID"));

            trigger OnLookup()
            var
                "Field": Record "Field";
                FieldSelection: Codeunit "Field Selection";
            begin
                Field.SetRange(TableNo, "Target Table ID");
                if FieldSelection.Open(Field) then
                    Validate("Target Field ID", Field."No.");
            end;
        }
        field(12; "Target Table Caption"; Text[250])
        {
            CalcFormula = Lookup("Table Metadata".Caption WHERE(ID = FIELD("Target Table ID")));
            Caption = 'Target Table Caption';
            FieldClass = FlowField;
        }
        field(13; "Target Field Caption"; Text[30])
        {
            CalcFormula = Lookup(Field."Field Caption" WHERE(TableNo = FIELD("Target Table ID"),
                                                              "No." = FIELD("Target Field ID")));
            Caption = 'Target Field Caption';
            FieldClass = FlowField;
#if CLEAN20
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '20.0';
#endif
            ObsoleteReason = 'Redesigned to a new field "Target Table Field Calcucation"';
        }
        field(14; "Target Table Field Caption"; Text[80])
        {
            CalcFormula = Lookup(Field."Field Caption" WHERE(TableNo = FIELD("Target Table ID"),
                                                              "No." = FIELD("Target Field ID")));
            Caption = 'Target Field Caption';
            FieldClass = FlowField;
        }
        field(20; "Transformation Rule"; Code[20])
        {
            Caption = 'Transformation Rule';
            TableRelation = "Transformation Rule";
        }
        field(21; "Overwrite Value"; Boolean)
        {
            Caption = 'Overwrite Value';
        }
        field(30; Priority; Integer)
        {
            Caption = 'Priority';
        }

    }

    keys
    {
        key(Key1; "Data Exch. Def Code", "Data Exch. Line Def Code", "Table ID", "Column No.", "Field ID")
        {
            Clustered = true;
        }
        key(Key2; "Data Exch. Def Code", "Data Exch. Line Def Code", "Table ID", Priority)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Column No.");

        if IsValidToUseMultiplier() and (Multiplier = 0) then
            Validate(Multiplier, 1);
    end;

    trigger OnModify()
    begin
        if IsValidToUseMultiplier() and (Multiplier = 0) then
            Validate(Multiplier, 1);
    end;

    var
        ZeroNotAllowedErr: Label 'All numeric values are allowed except zero.';

    procedure InsertRec(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; TableId: Integer; ColumnNo: Integer; FieldId: Integer; NewOptional: Boolean; NewMultiplier: Decimal)
    begin
        Init();
        Validate("Data Exch. Def Code", DataExchDefCode);
        Validate("Data Exch. Line Def Code", DataExchLineDefCode);
        "Table ID" := TableId;
        "Column No." := ColumnNo;
        "Field ID" := FieldId;
        Validate(Optional, NewOptional);
        Validate(Multiplier, NewMultiplier);
        Insert();
    end;

    procedure FillSourceRecord("Field": Record "Field")
    begin
        SetRange("Field ID");
        Init();

        "Table ID" := Field.TableNo;
        "Field ID" := Field."No.";
    end;

    procedure GetColumnCaption(): Text
    var
        DataExchColDef: Record "Data Exch. Column Def";
    begin
        DataExchColDef.SetRange("Data Exch. Def Code", "Data Exch. Def Code");
        DataExchColDef.SetRange("Data Exch. Line Def Code", "Data Exch. Line Def Code");
        DataExchColDef.SetRange("Column No.", "Column No.");
        if DataExchColDef.FindFirst() then
            exit(DataExchColDef.Name);
        exit('');
    end;

    procedure GetFieldCaption(): Text
    var
        recRef: RecordRef;
        fieldRef: FieldRef;
    begin
        recRef.Open("Table ID");
        fieldRef := recRef.Field("Field ID");
        exit(fieldRef.Caption);
    end;

    local procedure IsValidToUseMultiplier(): Boolean
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchDef.Get("Data Exch. Def Code");
        if DataExchColumnDef.Get("Data Exch. Def Code", "Data Exch. Line Def Code", "Column No.") then
            exit(DataExchColumnDef."Data Type" = DataExchColumnDef."Data Type"::Decimal);
        exit(false);
    end;

    procedure GetPath(): Text
    var
        DataExchColDef: Record "Data Exch. Column Def";
    begin
        DataExchColDef.SetRange("Data Exch. Def Code", "Data Exch. Def Code");
        DataExchColDef.SetRange("Data Exch. Line Def Code", "Data Exch. Line Def Code");
        DataExchColDef.SetRange("Column No.", "Column No.");
        if DataExchColDef.FindFirst() then
            exit(DataExchColDef.Path);
        exit('');
    end;
}

