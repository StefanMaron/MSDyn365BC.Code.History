table 8625 "Config. Related Table"
{
    Caption = 'Config. Related Table';
    ReplicateData = false;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(2; "Relation Table ID"; Integer)
        {
            Caption = 'Relation Table ID';
            Editable = false;
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Table));
        }
        field(3; "Relation Table Name"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Name" WHERE("Object Type" = CONST(Table),
                                                                        "Object ID" = FIELD("Relation Table ID")));
            Caption = 'Relation Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Related Fields"; Integer)
        {
            CalcFormula = Count ("Config. Related Field" WHERE("Table ID" = FIELD("Table ID"),
                                                               "Relation Table ID" = FIELD("Relation Table ID")));
            Caption = 'Related Fields';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "In Worksheet"; Boolean)
        {
            BlankZero = true;
            CalcFormula = Exist ("Config. Line" WHERE("Table ID" = FIELD("Relation Table ID")));
            Caption = 'In Worksheet';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Table ID", "Relation Table ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ConfigRelatedField: Record "Config. Related Field";
    begin
        ConfigRelatedField.SetRange("Table ID", "Table ID");
        ConfigRelatedField.SetRange("Relation Table ID", "Relation Table ID");
        ConfigRelatedField.DeleteAll();
    end;
}

