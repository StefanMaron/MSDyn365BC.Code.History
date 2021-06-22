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
            ObsoleteTag = '15.0';
        }
        field(3; "Obsolete Field Pending"; Integer)
        {
            DataClassification = SystemMetadata;
            ObsoleteState = Pending;
            TableRelation = "Cust. Ledger Entry";
            ObsoleteTag = '15.0';
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
            ObsoleteTag = '15.0';
        }
        key(Key3; "Normal Field")
        {
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        key(Key4; "Obsolete Field Pending", "Normal Field")
        {
        }
    }

    fieldgroups
    {
    }
}

