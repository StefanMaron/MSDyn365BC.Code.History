table 10631 "SAFT Source Code"
{
    Caption = 'SAF-T Source Code';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "Code"; Code[9])
        {
        }
        field(2; Description; Text[100])
        {
        }
        field(3; "Includes No Source Code"; Boolean)
        {
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

