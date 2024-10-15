table 17462 "Payroll Document Buffer"
{
    Caption = 'Payroll Document Buffer';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            DataClassification = SystemMetadata;
            TableRelation = "Payroll Element";
        }
        field(3; "Payroll Posting Group"; Code[20])
        {
            Caption = 'Payroll Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Payroll Posting Group";
        }
        field(5; "Base Amount"; Decimal)
        {
            Caption = 'Base Amount';
            DataClassification = SystemMetadata;
        }
        field(6; "Tax Amount"; Decimal)
        {
            Caption = 'Tax Amount';
            DataClassification = SystemMetadata;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
        }
        field(17400; "Payroll Ledger Entry No."; Integer)
        {
            Caption = 'Payroll Ledger Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "Payroll Ledger Entry";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

