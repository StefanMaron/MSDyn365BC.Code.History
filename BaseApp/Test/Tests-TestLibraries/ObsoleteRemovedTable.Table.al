table 136604 "Obsolete Removed Table"
{
    ObsoleteReason = 'Removed table';
    ObsoleteState = Removed;

    fields
    {
        field(1; "Key"; Integer)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

