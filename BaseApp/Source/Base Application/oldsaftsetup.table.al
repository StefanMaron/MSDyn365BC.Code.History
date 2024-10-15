table 10620 "SAFT Setup"
{
    Caption = 'SAF-T Setup';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "Primary Key"; Integer)
        {
        }
        field(2; "Dimension No. Series Code"; Code[20])
        {
            TableRelation = "No. Series";
        }
        field(3; "Last Tax Code"; Integer)
        {
        }
        field(4; "Not Applicable VAT Code"; Code[10])
        {
            TableRelation = "VAT Code";
        }
        field(50; Initialized; Boolean)
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

