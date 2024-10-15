table 12202 "VAT Transaction Nature"
{
    Caption = 'VAT Transaction Nature';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "VAT Transaction Nature";
    LookupPageID = "VAT Transaction Nature";

    fields
    {
        field(1; "Code"; Code[4])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[250])
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

