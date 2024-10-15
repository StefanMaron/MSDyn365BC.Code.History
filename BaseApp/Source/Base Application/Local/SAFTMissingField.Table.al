table 10628 "SAFT Missing Field"
{
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '17.0';
    ReplicateData = false;

    fields
    {
        field(1; "Table No."; Integer)
        {
        }
        field(2; "Field No."; Integer)
        {
        }
        field(3; "Record ID"; RecordID)
        {
        }
        field(4; "Group No."; Integer)
        {
        }
        field(5; "Field Caption"; Text[250])
        {
        }
    }

    keys
    {
        key(Key1; "Table No.", "Field No.")
        {
            Clustered = true;
        }
        key(Key2; "Table No.", "Group No.")
        {
        }
    }

    fieldgroups
    {
    }
}

