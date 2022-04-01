table 9042 "Team Member Cue"
{
    Caption = 'Team Member Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Open Time Sheets"; Integer)
        {
            CalcFormula = Count("Time Sheet Header" WHERE("Open Exists" = FILTER(= true),
                                                           "Owner User ID" = FIELD("User ID Filter")));
            Caption = 'Open Time Sheets';
            FieldClass = FlowField;
        }
        field(3; "Submitted Time Sheets"; Integer)
        {
            CalcFormula = Count("Time Sheet Header" WHERE("Submitted Exists" = FILTER(= true),
                                                           "Owner User ID" = FIELD("User ID Filter")));
            Caption = 'Submitted Time Sheets';
            FieldClass = FlowField;
        }
        field(4; "Rejected Time Sheets"; Integer)
        {
            CalcFormula = Count("Time Sheet Header" WHERE("Rejected Exists" = FILTER(= true),
                                                           "Owner User ID" = FIELD("User ID Filter")));
            Caption = 'Rejected Time Sheets';
            FieldClass = FlowField;
        }
        field(5; "Approved Time Sheets"; Integer)
        {
            CalcFormula = Count("Time Sheet Header" WHERE("Approved Exists" = FILTER(= true),
                                                           "Owner User ID" = FIELD("User ID Filter")));
            Caption = 'Approved Time Sheets';
            FieldClass = FlowField;
        }
        field(7; "Time Sheets to Approve"; Integer)
        {
            CalcFormula = Count("Time Sheet Header" WHERE("Approver User ID" = FIELD("Approve ID Filter"),
                                                           "Submitted Exists" = CONST(true)));
            Caption = 'Time Sheets to Approve';
            FieldClass = FlowField;
        }
        field(28; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
        field(29; "Approve ID Filter"; Code[50])
        {
            Caption = 'Approve ID Filter';
            FieldClass = FlowFilter;
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

