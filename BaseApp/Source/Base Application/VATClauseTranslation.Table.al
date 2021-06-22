table 561 "VAT Clause Translation"
{
    Caption = 'VAT Clause Translation';
    DrillDownPageID = "VAT Clause Translations";
    LookupPageID = "VAT Clause Translations";

    fields
    {
        field(1; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(4; "Description 2"; Text[250])
        {
            Caption = 'Description 2';
        }
    }

    keys
    {
        key(Key1; "VAT Clause Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

