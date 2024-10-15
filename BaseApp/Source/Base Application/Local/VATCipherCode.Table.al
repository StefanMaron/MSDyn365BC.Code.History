table 11017 "VAT Cipher Code"
{
    Caption = 'VAT Cipher Code';
    DrillDownPageID = "VAT Cipher Codes";
    LookupPageID = "VAT Cipher Codes";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
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

