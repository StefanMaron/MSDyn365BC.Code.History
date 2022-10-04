table 132510 TestTableA
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

