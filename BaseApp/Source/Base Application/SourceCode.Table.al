table 230 "Source Code"
{
    Caption = 'Source Code';
    LookupPageID = "Source Codes";

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
        field(10810; Simulation; Boolean)
        {
            Caption = 'Simulation';
            ObsoleteReason = 'Discontinued feature';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
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
        fieldgroup(Brick; "Code", Description)
        {
        }
    }
}

