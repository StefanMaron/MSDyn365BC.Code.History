table 2000006 "Export Check Error Log"
{
    Caption = 'Export Check Error Log';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(21; "Error Message"; Text[250])
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

