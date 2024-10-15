table 17463 "Payroll AE Buffer"
{
    Caption = 'Payroll AE Buffer';

    fields
    {
        field(1; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            DataClassification = SystemMetadata;
            TableRelation = "Payroll Period";
        }
        field(2; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            DataClassification = SystemMetadata;
            TableRelation = "Payroll Element";
        }
        field(3; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(4; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Period Code", "Element Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

