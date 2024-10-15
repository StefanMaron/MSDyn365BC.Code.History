table 10629 "SAFT Export File"
{
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '17.0';
    ReplicateData = false;

    fields
    {
        field(1; "Export ID"; Integer)
        {
            Editable = false;
        }
        field(2; "File No."; Integer)
        {
        }
        field(3; "SAF-T File"; BLOB)
        {
        }
    }

    keys
    {
        key(Key1; "Export ID", "File No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

