table 17443 "Timesheet Code"
{
    Caption = 'Timesheet Code';
    LookupPageID = "Timesheet Codes";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Digital Code"; Code[2])
        {
            Caption = 'Digital Code';
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

