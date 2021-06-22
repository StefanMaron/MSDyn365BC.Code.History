table 5370 "CRM Synch. Job Status Cue"
{
    Caption = 'CRM Synch. Job Status Cue';

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; "Failed Synch. Jobs"; Integer)
        {
            CalcFormula = Count ("Job Queue Entry" WHERE("Object ID to Run" = FIELD("Object ID to Run"),
                                                         Status = CONST(Error),
                                                         "Last Ready State" = FIELD("Date Filter")));
            Caption = 'Failed Synch. Jobs';
            FieldClass = FlowField;
        }
        field(6; "Date Filter"; DateTime)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(7; "Reset Date"; DateTime)
        {
            Caption = 'Reset Date';
        }
        field(8; "Object ID to Run"; Integer)
        {
            Caption = 'Object ID to Run';
            FieldClass = FlowFilter;
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

