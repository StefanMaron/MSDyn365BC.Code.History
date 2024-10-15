table 10633 "SAFT Export Line"
{
    Caption = 'SAF-T Export Line';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; ID; Integer)
        {
        }
        field(2; "Line No."; Integer)
        {
        }
        field(3; "Task ID"; Guid)
        {
        }
        field(4; Progress; Integer)
        {
            ExtendedDatatype = Ratio;
        }
        field(5; Status; Option)
        {
            OptionMembers = "Not Started","In Progress",Failed,Completed;
        }
        field(6; "Master Data"; Boolean)
        {
        }
        field(7; Description; Text[250])
        {
        }
        field(8; "No. Of Retries"; Integer)
        {
            InitValue = 3;
        }
        field(10; "Starting Date"; Date)
        {
        }
        field(11; "Ending Date"; Date)
        {
        }
        field(20; "SAF-T File"; BLOB)
        {
        }
        field(21; "Server Instance ID"; Integer)
        {
        }
        field(22; "Session ID"; Integer)
        {
        }
        field(23; "Created Date/Time"; DateTime)
        {
        }
    }

    keys
    {
        key(Key1; ID, "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

