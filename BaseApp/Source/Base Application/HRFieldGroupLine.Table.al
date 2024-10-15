table 17357 "HR Field Group Line"
{
    Caption = 'HR Field Group Line';

    fields
    {
        field(1; "Field Group Code"; Code[20])
        {
            Caption = 'Field Group Code';
            TableRelation = "HR Field Group";
        }
        field(2; "Table No."; Integer)
        {
            Caption = 'Table No.';
            TableRelation = AllObj."Object ID" WHERE("Object Type" = CONST(Table));

            trigger OnLookup()
            begin
                Validate("Table No.", LookUpTable("Table No."));
            end;

            trigger OnValidate()
            var
                AllObjWithCaption: Record AllObjWithCaption;
            begin
                AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, "Table No.");
                Validate("Table Name", AllObjWithCaption."Object Caption");

                if "Table No." <> xRec."Table No." then
                    Validate("Field No.", 0);
            end;
        }
        field(3; "Field No."; Integer)
        {
            Caption = 'Field No.';
            TableRelation = Field."No." WHERE(TableNo = FIELD("Table No."),
                                               Class = FILTER(Normal | FlowField));

            trigger OnLookup()
            var
                Field: Record "Field";
                FieldSelection: Codeunit "Field Selection";
            begin
                Field.SETRANGE(TableNo, "Table No.");
                if FieldSelection.Open(Field) then
                    Validate("Field No.", Field."No.");
            end;

            trigger OnValidate()
            begin
                CalcFields("Field Name");
                Validate("Field Report Caption", CopyStr("Table Name" + ': ' + "Field Name", 1, MaxStrLen("Field Report Caption")));
            end;
        }
        field(4; "Table Name"; Text[250])
        {
            Caption = 'Table Name';
            Editable = false;
        }
        field(5; "Field Name"; Text[30])
        {
            CalcFormula = Lookup (Field."Field Caption" WHERE(TableNo = FIELD("Table No."),
                                                              "No." = FIELD("Field No.")));
            Caption = 'Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Field Report Caption"; Text[250])
        {
            Caption = 'Field Report Caption';
        }
        field(7; "Field Print Order No."; Integer)
        {
            Caption = 'Field Print Order No.';
        }
    }

    keys
    {
        key(Key1; "Field Group Code", "Table No.", "Field No.")
        {
            Clustered = true;
        }
        key(Key2; "Field Group Code", "Field Print Order No.", "Table No.", "Field No.")
        {
        }
        key(Key3; "Table No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Table No.");
        TestField("Field No.");
    end;

    [Scope('OnPrem')]
    procedure LookUpTable(TableNo: Integer): Integer
    var
        AllObjWithCaption: Record AllObjWithCaption;
        Objects: Page Objects;
        TableFilter: Text;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);

        TableFilter := Format(DATABASE::Person) + '|';
        TableFilter += Format(DATABASE::Employee) + '|';
        TableFilter += Format(DATABASE::"Alternative Address") + '|';
        TableFilter += Format(DATABASE::"Employee Relative") + '|';
        TableFilter += Format(DATABASE::"Person Document") + '|';
        TableFilter += Format(DATABASE::"Person Medical Info") + '|';
        TableFilter += Format(DATABASE::"Employee Qualification") + '|';
        TableFilter += Format(DATABASE::"Misc. Article Information") + '|';
        TableFilter += Format(DATABASE::"Confidential Information") + '|';
        TableFilter += Format(DATABASE::"Employee Job Entry") + '|';
        TableFilter += Format(DATABASE::"Employee Ledger Entry");

        AllObjWithCaption.SetFilter("Object ID", TableFilter);

        Objects.SetTableView(AllObjWithCaption);
        Objects.Editable(false);
        Objects.LookupMode(true);
        if Objects.RunModal = ACTION::LookupOK then begin
            Objects.GetRecord(AllObjWithCaption);
            exit(AllObjWithCaption."Object ID");
        end;
        exit(TableNo);
    end;
}

