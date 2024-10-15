table 17316 "Tax Calc. Buffer Entry"
{
    Caption = 'Tax Calc. Buffer Entry';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
        }
        field(3; "Tax Factor"; Decimal)
        {
            Caption = 'Tax Factor';
            DataClassification = SystemMetadata;
            DecimalPlaces = 5 : 5;
        }
        field(4; "Tax Amount"; Decimal)
        {
            Caption = 'Tax Amount';
            DataClassification = SystemMetadata;
            DecimalPlaces = 2 :;
        }
    }

    keys
    {
        key(Key1; "Entry No.", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

