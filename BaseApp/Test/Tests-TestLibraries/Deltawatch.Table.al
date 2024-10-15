table 130001 "Delta watch"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
        }
        field(2; TableNo; Integer)
        {
        }
        field(3; PositionNo; Text[250])
        {
        }
        field(4; FieldNo; Integer)
        {
        }
        field(5; Delta; Decimal)
        {
        }
        field(7; OriginalValue; Decimal)
        {
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

