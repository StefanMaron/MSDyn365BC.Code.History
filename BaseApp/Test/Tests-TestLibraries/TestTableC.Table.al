table 132512 TestTableC
{
    ReplicateData = false;

    fields
    {
        field(1; IntegerField; Integer)
        {
            AutoIncrement = true;
        }
    }

    keys
    {
        key(Key1; IntegerField)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

