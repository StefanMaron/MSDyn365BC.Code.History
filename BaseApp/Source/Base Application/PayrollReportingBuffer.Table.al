table 17470 "Payroll Reporting Buffer"
{
    // Usage for RSV-2014:
    //   Code1   = Person No.
    //   Code2   = Reporting Period Code: "0" - Total, "1" - First Month, "2" - Second Month, "3" - Third Month, "4" - Begin Balance
    //   Code3   = Tariff Code (Disability attribute): "01" - normal, "03" - disability
    //   Code4   = Special Condition Code  (RSV-2014 6.7-3)
    //   Amount1 = PF_BASE + PF_MI_NO_TAX  (RSV-2014 6.4-4)
    //   Amount2 = PF_BASE - PF_OVER       (RSV-2014 6.4-5)
    //   Amount3 = PF_OVER                 (RSV-2014 6.4-7)
    //   Amount4 = PF_INS_LIMIT            (RSV-2014 6.5)
    //   Amount5 = PF_SPECIAL1             (RSV-2014 6.7-4)
    //   Amount6 = PF_SPECIAL2             (RSV-2014 6.7-5)
    //   Amount7 = PF_BASE
    //   Amount8 = PF_INS
    //   Amount9 = TAX_FED_FMI

    Caption = 'Payroll Reporting Buffer';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Code 1"; Code[20])
        {
            Caption = 'Code 1';
            DataClassification = SystemMetadata;
        }
        field(3; "Code 2"; Code[20])
        {
            Caption = 'Code 2';
            DataClassification = SystemMetadata;
        }
        field(4; "Code 3"; Code[20])
        {
            Caption = 'Code 3';
            DataClassification = SystemMetadata;
        }
        field(5; "Code 4"; Code[20])
        {
            Caption = 'Code 4';
            DataClassification = SystemMetadata;
        }
        field(6; "Amount 1"; Decimal)
        {
            Caption = 'Amount 1';
            DataClassification = SystemMetadata;
        }
        field(7; "Amount 2"; Decimal)
        {
            Caption = 'Amount 2';
            DataClassification = SystemMetadata;
        }
        field(8; "Amount 3"; Decimal)
        {
            Caption = 'Amount 3';
            DataClassification = SystemMetadata;
        }
        field(9; "Amount 4"; Decimal)
        {
            Caption = 'Amount 4';
            DataClassification = SystemMetadata;
        }
        field(10; "Amount 5"; Decimal)
        {
            Caption = 'Amount 5';
            DataClassification = SystemMetadata;
        }
        field(11; "Amount 6"; Decimal)
        {
            Caption = 'Amount 6';
            DataClassification = SystemMetadata;
        }
        field(12; "Amount 7"; Decimal)
        {
            Caption = 'Amount 7';
            DataClassification = SystemMetadata;
        }
        field(13; "Amount 8"; Decimal)
        {
            Caption = 'Amount 8';
            DataClassification = SystemMetadata;
        }
        field(14; "Amount 9"; Decimal)
        {
            Caption = 'Amount 9';
            DataClassification = SystemMetadata;
        }
        field(20; "Pack No."; Integer)
        {
            Caption = 'Pack No.';
            DataClassification = SystemMetadata;
        }
        field(21; "File Name"; Text[250])
        {
            Caption = 'File Name';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Code 1", "Code 2", "Code 3", "Code 4")
        {
            SumIndexFields = "Amount 1", "Amount 2", "Amount 3", "Amount 4", "Amount 5", "Amount 6", "Amount 7", "Amount 8", "Amount 9";
        }
        key(Key3; "Pack No.")
        {
        }
    }

    fieldgroups
    {
    }
}

