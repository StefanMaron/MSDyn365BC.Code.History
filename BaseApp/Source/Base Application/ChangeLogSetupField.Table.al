table 404 "Change Log Setup (Field)"
{
    Caption = 'Change Log Setup (Field)';
    ReplicateData = true;

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
            TableRelation = "Change Log Setup (Table)";
        }
        field(2; "Field No."; Integer)
        {
            Caption = 'Field No.';
            TableRelation = Field."No." WHERE(TableNo = FIELD("Table No."));
        }
        field(3; "Field Caption"; Text[100])
        {
            CalcFormula = Lookup (Field."Field Caption" WHERE(TableNo = FIELD("Table No."),
                                                              "No." = FIELD("Field No.")));
            Caption = 'Field Caption';
            FieldClass = FlowField;
        }
        field(4; "Log Insertion"; Boolean)
        {
            Caption = 'Log Insertion';
        }
        field(5; "Log Modification"; Boolean)
        {
            Caption = 'Log Modification';
        }
        field(6; "Log Deletion"; Boolean)
        {
            Caption = 'Log Deletion';
        }
    }

    keys
    {
        key(Key1; "Table No.", "Field No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

