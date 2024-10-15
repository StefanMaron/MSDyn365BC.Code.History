table 15000002 "Payment Order Data"
{
    Caption = 'Payment Order Data';
    LookupPageID = "Payment Order Data";

    fields
    {
        field(1; "Payment Order No."; Integer)
        {
            Caption = 'Payment Order No.';
        }
        field(2; "Line No"; Integer)
        {
            Caption = 'Line No';
        }
        field(10; Data; Text[80])
        {
            Caption = 'Data';
        }
        field(11; "Empty Line"; Boolean)
        {
            Caption = 'Empty Line';
        }
    }

    keys
    {
        key(Key1; "Payment Order No.", "Line No")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

