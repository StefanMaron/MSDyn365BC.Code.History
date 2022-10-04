table 130060 "Reference data - field list"
{
    ReplicateData = false;

    fields
    {
        field(1; "Ref. file name"; Text[30])
        {
            NotBlank = true;
        }
        field(2; "Table ID"; Integer)
        {
            TableRelation = AllObj."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(3; "Table name"; Text[30])
        {
            CalcFormula = Lookup(AllObj."Object Name" WHERE("Object Type" = CONST(Table),
                                                             "Object ID" = FIELD("Table ID")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Field ID"; Integer)
        {
            TableRelation = Field."No." WHERE(TableNo = FIELD("Table ID"));
        }
        field(5; "Field name"; Text[30])
        {
            CalcFormula = Lookup(Field.FieldName WHERE(TableNo = FIELD("Table ID"),
                                                        "No." = FIELD("Field ID")));
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Ref. file name", "Table ID", "Field ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckForZeroValues;
    end;

    trigger OnModify()
    begin
        // CheckForZeroValues;
    end;

    var
        Text001: Label 'A value of ''0'' is not allowed for field ''%1''.';

    local procedure CheckForZeroValues()
    begin
        if "Table ID" = 0 then
            Error(Text001, FieldName("Table ID"));
        if "Field ID" = 0 then
            Error(Text001, FieldName("Field ID"));
    end;
}

