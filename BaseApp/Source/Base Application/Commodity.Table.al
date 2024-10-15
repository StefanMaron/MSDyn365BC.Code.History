table 31095 Commodity
{
    Caption = 'Commodity';
    DataCaptionFields = "Code";
    DrillDownPageID = Commodities;
    LookupPageID = Commodities;

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

