table 1505 "Workflow - Table Relation"
{
    Caption = 'Workflow - Table Relation';
    ReplicateData = true;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(2; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            TableRelation = Field."No." WHERE(TableNo = FIELD("Table ID"));
        }
        field(3; "Related Table ID"; Integer)
        {
            Caption = 'Related Table ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(4; "Related Field ID"; Integer)
        {
            Caption = 'Related Field ID';
            TableRelation = Field."No." WHERE(TableNo = FIELD("Related Table ID"));
        }
        field(5; "Table Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Table),
                                                                           "Object ID" = FIELD("Table ID")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Field Caption"; Text[250])
        {
            CalcFormula = Lookup (Field."Field Caption" WHERE(TableNo = FIELD("Table ID"),
                                                              "No." = FIELD("Field ID")));
            Caption = 'Field Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Related Table Caption"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Table),
                                                                           "Object ID" = FIELD("Related Table ID")));
            Caption = 'Related Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Related Field Caption"; Text[250])
        {
            CalcFormula = Lookup (Field."Field Caption" WHERE(TableNo = FIELD("Related Table ID"),
                                                              "No." = FIELD("Related Field ID")));
            Caption = 'Related Field Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Table ID", "Field ID", "Related Table ID", "Related Field ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

