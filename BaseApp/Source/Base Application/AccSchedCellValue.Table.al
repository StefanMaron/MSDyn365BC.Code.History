table 342 "Acc. Sched. Cell Value"
{
    Caption = 'Acc. Sched. Cell Value';

    fields
    {
        field(1; "Row No."; Integer)
        {
            Caption = 'Row No.';
        }
        field(2; "Column No."; Integer)
        {
            Caption = 'Column No.';
        }
        field(3; Value; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Value';
        }
        field(4; "Has Error"; Boolean)
        {
            Caption = 'Has Error';
        }
        field(5; "Period Error"; Boolean)
        {
            Caption = 'Period Error';
        }
        field(31080; "Schedule Name"; Code[10])
        {
            Caption = 'Schedule Name';
            TableRelation = "Acc. Schedule Name";
#if CLEAN19
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Field Schedule Name will be removed and this field should not be used.';
            ObsoleteTag = '19.0';
        }
    }

    keys
    {
#if not CLEAN19
        key(Key1; "Schedule Name", "Row No.", "Column No.")
        {
            Clustered = true;
            ObsoleteState = Pending;
            ObsoleteReason = 'Field Schedule Name will be removed from the primary key.';
            ObsoleteTag = '19.0';
        }
#else
        key(Key1; "Row No.", "Column No.")
        {
            Clustered = true;           
        }
#endif
    }

    fieldgroups
    {
    }
}

