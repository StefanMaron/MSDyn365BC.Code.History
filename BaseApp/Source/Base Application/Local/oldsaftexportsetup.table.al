table 10623 "SAFT Export Setup"
{
    Caption = 'SAF-T Export Setup';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
        }
        field(2; "Mapping Range Code"; Code[20])
        {
        }
        field(3; "Header Comment"; Text[17])
        {
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

