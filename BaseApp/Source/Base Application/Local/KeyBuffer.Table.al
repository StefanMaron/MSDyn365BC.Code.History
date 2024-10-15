table 11015 "Key Buffer"
{
    Caption = 'Key Buffer';

    fields
    {
        field(1; "Table No"; Integer)
        {
            Caption = 'Table No';
        }
        field(2; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(3; "Key"; Text[250])
        {
            Caption = 'Key';
        }
    }

    keys
    {
        key(Key1; "Table No", "Field No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

