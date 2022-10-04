table 135020 "Data Mig. Item Staging Table"
{
    ReplicateData = false;

    fields
    {
        field(1; "Item Key"; Code[10])
        {
        }
        field(2; "Item Description"; Text[50])
        {
        }
    }

    keys
    {
        key(Key1; "Item Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

