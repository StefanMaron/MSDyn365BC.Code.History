table 10634 "SAFT Media Resource"
{
    Caption = 'SAF-T Media Resource';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "Code"; Code[50])
        {
        }
        field(2; Blob; BLOB)
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

