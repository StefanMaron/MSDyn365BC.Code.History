table 132511 TestTableB
{
    ReplicateData = false;
    DataClassification = CustomerContent;

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

