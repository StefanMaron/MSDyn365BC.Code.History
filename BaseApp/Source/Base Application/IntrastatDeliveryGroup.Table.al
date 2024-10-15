table 31064 "Intrastat Delivery Group"
{
    Caption = 'Intrastat Delivery Group';
    DrillDownPageID = "Intrastat Delivery Group";
    LookupPageID = "Intrastat Delivery Group";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
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

