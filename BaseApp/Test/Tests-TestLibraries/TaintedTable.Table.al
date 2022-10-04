table 130011 "Tainted Table"
{
    ReplicateData = false;

    fields
    {
        field(1; "Snapshot No."; Integer)
        {
            TableRelation = Snapshot."Snapshot No." WHERE("Snapshot No." = FIELD("Snapshot No."));
        }
        field(2; "Table No."; Integer)
        {
        }
        field(3; "Implicit Taint"; Boolean)
        {
        }
    }

    keys
    {
        key(Key1; "Snapshot No.", "Table No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

