table 282 "Entry/Exit Point"
{
    Caption = 'Entry/Exit Point';
    DrillDownPageID = "Entry/Exit Points";
    LookupPageID = "Entry/Exit Points";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
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

