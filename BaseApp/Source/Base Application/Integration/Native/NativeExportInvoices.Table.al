table 2822 "Native - Export Invoices"
{
    Caption = 'Native - Export Invoices';
    ReplicateData = false;
#if not CLEAN20
    ObsoleteState = Pending;
    ObsoleteTag = '17.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
#endif
    ObsoleteReason = 'These objects will be removed';

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(3; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(4; "E-mail"; Text[80])
        {
            Caption = 'E-mail';
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

