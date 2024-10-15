table 11701 "Constant Symbol"
{
    Caption = 'Constant Symbol';
    LookupPageID = "Constant Symbols";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            CharAllowed = '09';
            NotBlank = true;
            Numeric = true;
        }
        field(2; Description; Text[50])
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

