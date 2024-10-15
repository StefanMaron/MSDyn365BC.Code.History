table 27008 "CFDI Subject to Tax"
{
    DrillDownPageID = "CFDI Subjects to Tax";
    LookupPageID = "CFDI Subjects to Tax";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
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

