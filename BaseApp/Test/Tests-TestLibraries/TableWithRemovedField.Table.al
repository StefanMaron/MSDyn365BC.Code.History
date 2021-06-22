table 136603 "Table With Removed Field"
{

    fields
    {
        field(1; "Key"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Obsolete Field Removed"; Integer)
        {
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            TableRelation = "G/L Entry";
        }
        field(3; "Obsolete Field Pending"; Integer)
        {
            DataClassification = SystemMetadata;
            ObsoleteState = Pending;
            TableRelation = "Cust. Ledger Entry";
        }
        field(4; "Normal Field"; Integer)
        {
            DataClassification = SystemMetadata;
            TableRelation = "Vendor Ledger Entry";
        }
    }

    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
        key(Key2; "Obsolete Field Pending", "Key")
        {
            ObsoleteState = Pending;
        }
        key(Key3; "Normal Field")
        {
            ObsoleteState = Removed;
        }
        key(Key4; "Obsolete Field Pending", "Normal Field")
        {
        }
    }

    fieldgroups
    {
    }
}

