table 139173 "Test Table with large field"
{
    ReplicateData = false;

    fields
    {
        field(1; PK; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(2; Description; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; PK)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

