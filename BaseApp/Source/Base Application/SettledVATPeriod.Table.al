table 10601 "Settled VAT Period"
{
    Caption = 'Settled VAT Period';

    fields
    {
        field(1; Year; Integer)
        {
            Caption = 'Year';
            MinValue = 1980;
        }
        field(2; "Period No."; Integer)
        {
            BlankZero = true;
            Caption = 'Period No.';
            MinValue = 1;
            TableRelation = "VAT Period"."Period No.";
        }
        field(3; "Settlement Date"; Date)
        {
            Caption = 'Settlement Date';
        }
        field(10; Closed; Boolean)
        {
            Caption = 'Closed';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; Year, "Period No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

