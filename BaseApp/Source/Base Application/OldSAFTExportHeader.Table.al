table 10632 "SAFT Export Header"
{
    Caption = 'SAF-T Export Header';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Mapping Range Code"; Code[20])
        {
        }
        field(3; "Starting Date"; Date)
        {
        }
        field(4; "Ending Date"; Date)
        {
        }
        field(5; "Parallel Processing"; Boolean)
        {
        }
        field(6; "Max No. Of Jobs"; Integer)
        {
            InitValue = 3;
            MinValue = 1;
        }
        field(7; "Split By Month"; Boolean)
        {
            InitValue = true;
        }
        field(8; "Earliest Start Date/Time"; DateTime)
        {
        }
        field(9; "Folder Path"; Text[250])
        {
        }
        field(10; Status; Option)
        {
            Editable = false;
            OptionMembers = "Not Started","In Progress",Failed,Completed;
        }
        field(11; "Header Comment"; Text[18])
        {
        }
        field(12; "Execution Start Date/Time"; DateTime)
        {
            Editable = false;
        }
        field(13; "Execution End Date/Time"; DateTime)
        {
            Editable = false;
        }
        field(14; "SAF-T File"; BLOB)
        {
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

