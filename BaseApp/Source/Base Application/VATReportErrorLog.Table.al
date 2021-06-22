table 745 "VAT Report Error Log"
{
    Caption = 'VAT Report Error Log';
    ReplicateData = true;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

