table 11783 "Multiple Interest Rate"
{
    Caption = 'Multiple Interest Rate';
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ObsoleteReason = 'Replaced by Finance Charge Interest Rate';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Finance Charge Code"; Code[10])
        {
            Caption = 'Finance Charge Code';
            TableRelation = "Finance Charge Terms".Code;
        }
        field(2; "Valid from Date"; Date)
        {
            Caption = 'Valid from Date';
        }
        field(3; "Interest Rate"; Decimal)
        {
            Caption = 'Interest Rate';
            MaxValue = 100;
            MinValue = 0;
        }
        field(5; "Interest Period (Days)"; Integer)
        {
            Caption = 'Interest Period (Days)';
        }
        field(11700; "Use Due Date Interest Rate"; Boolean)
        {
            Caption = 'Use Due Date Interest Rate';
        }
    }

    keys
    {
        key(Key1; "Finance Charge Code", "Valid from Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

