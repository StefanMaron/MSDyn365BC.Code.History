table 12140 "VAT Identifier"
{
    Caption = 'VAT Identifier';
    DrillDownPageID = "VAT Identifier";
    LookupPageID = "VAT Identifier";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Subject to VAT Plafond"; Boolean)
        {
            Caption = 'Subject to VAT Plafond';
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
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }
}

