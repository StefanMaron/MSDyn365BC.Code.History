table 31043 "SKP Code"
{
    Caption = 'SKP Code';
    LookupPageID = "SKP Codes";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[200])
        {
            Caption = 'Description';
        }
        field(3; "Depreciation Group"; Text[10])
        {
            Caption = 'Depreciation Group';
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

