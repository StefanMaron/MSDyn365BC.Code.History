table 11798 "XML Export Buffer"
{
    Caption = 'XML Export Buffer';
#if CLEAN18
    ObsoleteState = Removed;
#else
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Became obsolete after refactoring. Use dictionary variable instead.';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "XML Tag"; Code[20])
        {
            Caption = 'XML Tag';
            DataClassification = SystemMetadata;
        }
        field(2; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "XML Tag")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
