table 8400 "Record Set Definition"
{
    Caption = 'Record Set Definition';

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(2; "Set ID"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Set ID';
            InitValue = 1;
        }
        field(3; "Node ID"; Integer)
        {
            Caption = 'Node ID';
        }
        field(10; Value; RecordID)
        {
            CalcFormula = Lookup ("Record Set Tree".Value WHERE("Table No." = FIELD("Table No."),
                                                                "Node ID" = FIELD("Node ID")));
            Caption = 'Value';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Table No.", "Set ID", "Node ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

