table 10534 "MTD-Payment"
{
    Caption = 'VAT Payment';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Pending;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(2; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(4; "Received Date"; Date)
        {
            Caption = 'Received Date';
        }
        field(5; Amount; Decimal)
        {
            Caption = 'Amount';
        }
    }

    keys
    {
        key(Key1; "Start Date", "End Date", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

