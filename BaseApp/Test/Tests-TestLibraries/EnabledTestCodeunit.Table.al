table 130201 "Enabled Test Codeunit"
{
    ReplicateData = false;

    fields
    {
        field(1; "No."; Integer)
        {
        }
        field(2; "Test Codeunit ID"; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

