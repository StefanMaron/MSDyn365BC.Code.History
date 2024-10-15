table 14952 "KLADR Region"
{
    Caption = 'KLADR Region';
    LookupPageID = "KLADR Regions";

    fields
    {
        field(1; "Code"; Code[2])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Address Name"; Text[50])
        {
            Caption = 'Address Name';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Name)
        {
        }
    }

    fieldgroups
    {
    }
}

