table 130403 "CAL Test Enabled Codeunit"
{
    Caption = 'CAL Test Enabled Codeunit';
    ReplicateData = false;

    fields
    {
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'No.';
        }
        field(2; "Test Codeunit ID"; Integer)
        {
            Caption = 'Test Codeunit ID';
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

