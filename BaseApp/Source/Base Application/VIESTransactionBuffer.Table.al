table 31060 "VIES Transaction Buffer"
{
    Caption = 'VIES Transaction Buffer';
#if CLEAN17
    ObsoleteState = Removed;
#else
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            DataClassification = SystemMetadata;
        }
        field(5; "EU Service"; Boolean)
        {
            Caption = 'EU Service';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Transaction No.", "EU Service")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

