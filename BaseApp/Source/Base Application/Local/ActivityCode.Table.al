table 12124 "Activity Code"
{
    Caption = 'Activity Code';
    LookupPageID = 12124;

    fields
    {
        field(1; "Code"; Code[6])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

