table 17454 "Element Buffer"
{
    Caption = 'Element Buffer';

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
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(4; "Amount 1"; Decimal)
        {
            Caption = 'Amount 1';
            DataClassification = SystemMetadata;
        }
        field(5; "Amount 2"; Decimal)
        {
            Caption = 'Amount 2';
            DataClassification = SystemMetadata;
        }
        field(6; "Account No. 1"; Code[20])
        {
            Caption = 'Account No. 1';
            DataClassification = SystemMetadata;
        }
        field(7; "Account No. 2"; Code[20])
        {
            Caption = 'Account No. 2';
            DataClassification = SystemMetadata;
        }
        field(8; "Number 1"; Integer)
        {
            Caption = 'Number 1';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; Description)
        {
        }
    }

    fieldgroups
    {
    }
}

